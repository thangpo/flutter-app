import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:zego_uikit/zego_uikit.dart';

import '../../../utill/app_constants.dart';
import 'zego_call_config.dart';
import 'zego_token_repository.dart';

class ZegoCallService {
  ZegoCallService._();

  static final ZegoCallService I = ZegoCallService._();

  static const _prefTokenKey = 'zego_call_token';
  static const _prefExpireKey = 'zego_call_token_expire_at';

  final ZegoTokenRepository _tokenRepo = ZegoTokenRepository();

  bool _inited = false;
  String? _userId;
  String? _userName;
  final Map<String, _CallProfile> _profiles = {}; // userId/groupId -> info

  bool get isInited => _inited;
  String? get userId => _userId;
  String? get userName => _userName;

  Future<void> initIfPossible({
    required String userId,
    required String userName,
  }) async {
    if (_inited && _userId == userId) return;

    if (ZegoCallConfig.appID <= 0) {
      debugPrint('[ZEGO] Missing ZEGO_APP_ID, skip init call service.');
      return;
    }

    debugPrint('[ZEGO] Init requested for user=$userId appID=${ZegoCallConfig.appID}');

    final token = await _getValidToken(userId: userId);
    if (token == null || token.isEmpty) {
      debugPrint('[ZEGO] Không lấy được token từ server, bỏ qua init.');
      return;
    }

    _userId = userId;
    _userName = userName;

    try {
      await ZegoUIKitPrebuiltCallInvitationService().init(
        appID: ZegoCallConfig.appID,
        appSign: '', // AppSign nằm ở server, client chỉ dùng token
        token: token,
        userID: userId,
        userName: userName,
        plugins: [ZegoUIKitSignalingPlugin()],
        requireConfig: (ZegoCallInvitationData data) {
          _ingestCustomProfiles(data);
          final isVideo = data.type == ZegoCallType.videoCall;
          final isGroup = data.invitees.length > 1;
          final config = isGroup
            ? (isVideo
                ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
                : ZegoUIKitPrebuiltCallConfig.groupVoiceCall())
            : (isVideo
                ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall());
          _applyAvatarAndText(config, data);
          return config;
        },
      );
    } catch (e) {
      debugPrint('[ZEGO] Lỗi init service: $e');
      return;
    }

    _inited = true;
    debugPrint('[ZEGO] Call invitation service inited for user=$userId');
  }

  Future<String?> _myAvatarFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.socialUserAvatar);
  }

  void _setProfile(String id, String? name, String? avatar) {
    if (id.isEmpty) return;
    _profiles[id] = _CallProfile(id: id, name: name ?? id, avatar: avatar);
  }

  void _ingestCustomProfiles(ZegoCallInvitationData data) {
    Map<String, dynamic>? parsed;
    try {
      if (data.customData is String && (data.customData as String).isNotEmpty) {
        parsed = jsonDecode(data.customData as String);
      } else if (data.customData is Map) {
        parsed = Map<String, dynamic>.from(data.customData as Map);
      }
    } catch (_) {}

    if (parsed != null) {
      final callerId = data.inviter?.id ?? '';
      final callerName = parsed['caller_name']?.toString();
      final callerAvatar = parsed['caller_avatar']?.toString();
      if (callerId.isNotEmpty) {
        _setProfile(callerId, callerName, callerAvatar);
      }
      final peerId = parsed['peer_id']?.toString();
      final peerAvatar = parsed['peer_avatar']?.toString();
      final peerName = parsed['peer_name']?.toString();
      if (peerId != null && peerId.isNotEmpty) {
        _setProfile(peerId, peerName ?? peerId, peerAvatar);
      }
      final groupId = parsed['group_id']?.toString();
      if (groupId != null && groupId.isNotEmpty) {
        _setProfile(
          groupId,
          parsed['group_name']?.toString() ?? groupId,
          parsed['group_avatar']?.toString(),
        );
      }
    }
  }

  void _applyAvatarAndText(
    ZegoUIKitPrebuiltCallConfig config,
    ZegoCallInvitationData data,
  ) {
    config.avatarBuilder =
        (BuildContext context, Size size, ZegoUIKitUser? user, Map extraInfo) {
      final uid = user?.id ?? '';
      final p = _profiles[uid];
      if (p != null && (p.avatar?.isNotEmpty ?? false)) {
        return CircleAvatar(
          radius: size.width / 2,
          backgroundImage: NetworkImage(p.avatar!),
        );
      }
      if (p != null) {
        final initial = (p.name ?? p.id).isNotEmpty
            ? (p.name ?? p.id)[0].toUpperCase()
            : '?';
        return CircleAvatar(
          radius: size.width / 2,
          child: Text(initial),
        );
      }
      if ((user?.id ?? '').isNotEmpty) {
        return CircleAvatar(
          radius: size.width / 2,
          child: Text(user!.id.substring(0, 1).toUpperCase()),
        );
      }
      return const SizedBox.shrink();
    };

    // translationText của prebuilt không có setter cho title gọi, bỏ qua.
  }
  Future<void> uninit() async {
    if (!_inited) return;
    ZegoUIKitPrebuiltCallInvitationService().uninit();
    _inited = false;
    _userId = null;
    _userName = null;
    debugPrint('[ZEGO] Call invitation service uninited');
  }

  Future<void> tryInitFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(AppConstants.socialUserId);
    if (userId == null || userId.isEmpty) return;

    await initIfPossible(userId: userId, userName: userId);
  }

  Future<String?> _getValidToken({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(AppConstants.socialAccessToken) ?? '';
    if (accessToken.isEmpty) {
      debugPrint('[ZEGO] Không có social access_token để xin token');
      return null;
    }

    try {
      debugPrint(
        '[ZEGO] Fetch token từ server: userId=$userId, access_token=${accessToken.substring(0, 6)}..., endpoint=${AppConstants.socialGenerateZegoTokenUri}',
      );
      final res = await _tokenRepo.fetchToken(
        accessToken: accessToken,
        userId: userId,
      );
      await prefs.setString(_prefTokenKey, res.token);
      await prefs.setInt(_prefExpireKey, res.expireAt);
      debugPrint(
        '[ZEGO] Lấy token mới thành công, expireAt=${res.expireAt}, len=${res.token.length}',
      );
      return res.token;
    } catch (e) {
      debugPrint('[ZEGO] Lỗi fetch token: $e');
      return null;
    }
  }

  String newOneOnOneCallId(String peerId) {
    final me = _userId ?? '0';
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'c1_${me}_${peerId}_$ts';
  }

  String newGroupCallId(String groupId) {
    final me = _userId ?? '0';
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'cg_${groupId}_${me}_$ts';
  }

  Future<bool> startOneOnOne({
    required String peerId,
    required String peerName,
    required bool isVideoCall,
    String? callID,
    String? peerAvatar,
  }) async {
    if (!_inited) {
      await tryInitFromPrefs();
    }
    if (!_inited) return false;

    _setProfile(peerId, peerName, peerAvatar);
    // lưu luôn profile của mình để callee hiển thị
    _setProfile(_userId ?? '', _userName, await _myAvatarFromPrefs());

    return ZegoUIKitPrebuiltCallInvitationService().send(
      invitees: [ZegoCallUser(peerId, peerName)],
      isVideoCall: isVideoCall,
      callID: callID,
      resourceID: ZegoCallConfig.callResourceID.isEmpty
          ? null
          : ZegoCallConfig.callResourceID,
      customData: jsonEncode({
        'scope': 'social',
        'mode': 'one_on_one',
        'peer_id': peerId,
        'peer_name': peerName,
        'is_video': isVideoCall,
        'peer_avatar': peerAvatar ?? '',
        'caller_name': _userName ?? _userId ?? '',
        'caller_avatar': await _myAvatarFromPrefs(),
      }),
    );
  }

  Future<bool> startGroup({
    required List<ZegoCallUser> invitees,
    required bool isVideoCall,
    required String groupId,
    String? callID,
    Map<String, dynamic>? customData,
    String? callerName,
    String? callerAvatar,
    String? groupName,
    String? groupAvatar,
  }) async {
    _setProfile(groupId, groupName, groupAvatar);

    if (!_inited) {
      await tryInitFromPrefs();
    }
    if (!_inited) return false;

    final data = <String, dynamic>{
      'scope': 'social',
      'mode': 'group',
      'is_video': isVideoCall,
      'caller_name': callerName ?? _userName ?? _userId ?? '',
      'caller_avatar': callerAvatar ?? await _myAvatarFromPrefs(),
      'group_name': groupName ?? '',
      'group_avatar': groupAvatar ?? '',
      if (customData != null) ...customData,
    };

    return ZegoUIKitPrebuiltCallInvitationService().send(
      invitees: invitees,
      isVideoCall: isVideoCall,
      callID: callID,
      resourceID: ZegoCallConfig.callResourceID.isEmpty
          ? null
          : ZegoCallConfig.callResourceID,
      customData: jsonEncode(data),
    );
  }
}

class _CallProfile {
  final String id;
  final String? name;
  final String? avatar;

  _CallProfile({required this.id, this.name, this.avatar});
}
