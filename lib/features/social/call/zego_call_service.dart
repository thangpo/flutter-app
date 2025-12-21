import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:zego_uikit/zego_uikit.dart';

import '../../../utill/app_constants.dart';
import 'zego_call_config.dart';
import 'zego_remote_logger.dart';
import 'zego_token_repository.dart';

class ZegoCallService {
  ZegoCallService._();

  static final ZegoCallService I = ZegoCallService._();

  static const _prefTokenKey = 'zego_call_token';
  static const _prefExpireKey = 'zego_call_token_expire_at';

  final ZegoTokenRepository _tokenRepo = ZegoTokenRepository();
  final ZegoRemoteLogger _remoteLogger = ZegoRemoteLogger.I;

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

    debugPrint(
        '[ZEGO] Init requested for user=$userId appID=${ZegoCallConfig.appID}');
    unawaited(_remoteLogger.log('init_requested', {
      'user_id': userId,
      'user_name': userName,
    }));

    final token = await _getValidToken(userId: userId);
    if (token == null || token.isEmpty) {
      debugPrint('[ZEGO] Không lấy được token từ server, bỏ qua init.');
      return;
    }

    final isProd = kReleaseMode || kProfileMode;
    final notificationConfig = ZegoCallInvitationNotificationConfig(
      iOSNotificationConfig: ZegoCallIOSNotificationConfig(
        appName: AppConstants.appName,
        isSandboxEnvironment: !isProd,
      ),
      androidNotificationConfig: ZegoCallAndroidNotificationConfig(
        callIDVisibility: true,
        showOnLockedScreen: true,
        showOnFullScreen: true,
        callChannel: ZegoCallAndroidNotificationChannelConfig(
          channelID: 'zego_incoming_call',
          channelName: 'Incoming Calls',
          icon: 'notification_icon',
          sound: '',
          vibrate: true,
        ),
        missedCallChannel: ZegoCallAndroidNotificationChannelConfig(
          channelID: 'zego_missed_call',
          channelName: 'Missed Calls',
          icon: 'notification_icon',
          sound: '',
          vibrate: false,
        ),
      ),
    );

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
        invitationEvents: ZegoUIKitPrebuiltCallInvitationEvents(
          onIncomingCallAcceptButtonPressed: () {
            unawaited(_remoteLogger.log('incoming_accept_pressed', {
              'user_id': userId,
            }));
            // Đảm bảo mở UI cuộc gọi đã accept (offline) sau khi bấm Nghe từ CallKit.
            unawaited(
              _enterAcceptedOfflineCallWithLog(source: 'accept_button'),
            );
          },
          onIncomingCallReceived: (
            String callID,
            ZegoCallUser caller,
            ZegoCallInvitationType callType,
            List<ZegoCallUser> callees,
            String customData,
          ) {
            unawaited(_remoteLogger.log('incoming_received', {
              'call_id': callID,
              'caller_id': caller.id,
              'call_type': callType.name,
              'callees': callees.map((e) => e.id).toList(),
            }));
            // Backup: khi app vừa được wake từ push, thử mở UI nếu đã có accept.
            unawaited(
              _enterAcceptedOfflineCallWithLog(source: 'incoming_received'),
            );
          },
        ),
        config: ZegoCallInvitationConfig(
          offline: ZegoCallInvitationOfflineConfig(
            autoEnterAcceptedOfflineCall: false,
          ),
        ),
        notificationConfig: notificationConfig,
        requireConfig: (ZegoCallInvitationData data) {
          _ingestCustomProfiles(data);
          final isVideo = data.type == ZegoCallInvitationType.videoCall;
          final isGroup = data.invitees.length > 1;
          final config = isGroup
              ? (isVideo
                  ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
                  : ZegoUIKitPrebuiltCallConfig.groupVoiceCall())
              : (isVideo
                  ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                  : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall());
          unawaited(_remoteLogger.log('require_config', {
            'call_id': data.callID,
            'invitation_id': data.invitationID,
            'is_group': isGroup,
            'is_video': isVideo,
            'invitees': data.invitees.map((e) => e.id).toList(),
            'inviter': data.inviter?.id ?? '',
          }));
          _applyAvatarAndText(config, data);
          return config;
        },
      );
    } catch (e) {
      debugPrint('[ZEGO] Lỗi init service: $e');
      unawaited(_remoteLogger.log('init_failed', {
        'user_id': userId,
        'error': e.toString(),
      }));
      return;
    }

    _inited = true;
    debugPrint('[ZEGO] Call invitation service inited for user=$userId');
    unawaited(_remoteLogger.log('init_success', {
      'user_id': userId,
      'user_name': userName,
    }));

    // Extra attempt: khi app được mở lại từ CallKit (cold start) cố gắng vào UI gọi.
    Future.delayed(const Duration(milliseconds: 600), () {
      try {
        ZegoUIKitPrebuiltCallInvitationService().enterAcceptedOfflineCall();
        unawaited(_remoteLogger.log('enter_offline_after_init', {
          'user_id': userId,
        }));
      } catch (_) {}
    });
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
      if (data.customData.isNotEmpty) {
        parsed = jsonDecode(data.customData);
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

  String? _parsedGroupId(ZegoCallInvitationData data) {
    try {
      if (data.customData.isNotEmpty) {
        final parsed = jsonDecode(data.customData);
        if (parsed is Map && parsed['group_id'] != null) {
          return parsed['group_id'].toString();
        }
      }
    } catch (_) {}
    return null;
  }

  void _applyAvatarAndText(
    ZegoUIKitPrebuiltCallConfig config,
    ZegoCallInvitationData data,
  ) {
    final groupId = _parsedGroupId(data);
    final groupProfile = groupId != null ? _profiles[groupId] : null;

    config.audioVideoView.foregroundBuilder =
        (BuildContext context, Size size, ZegoUIKitUser? user, Map extraInfo) {
      final uid = user?.id ?? '';
      final p = _profiles[uid];
      final name = p?.name ?? uid;
      final widgets = <Widget>[];

      widgets.add(Positioned(
        right: 8,
        bottom: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ));

      if (groupProfile != null && groupProfile.name != null) {
        widgets.add(Positioned(
          left: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              groupProfile.name!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ));
      }

      return Stack(children: widgets);
    };

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

    final display = prefs.getString(AppConstants.socialUserName) ?? userId;
    unawaited(_remoteLogger.log('init_from_prefs', {
      'user_id': userId,
      'user_name': display,
    }));
    await initIfPossible(userId: userId, userName: display);
  }

  /// Cho phép cache thủ công profile (vd: thành viên nhóm) trước khi gọi.
  void cacheProfile(String id, {String? name, String? avatar}) {
    _setProfile(id, name, avatar);
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
      unawaited(_remoteLogger.log('token_fetch', {
        'user_id': userId,
      }));
      final res = await _tokenRepo.fetchToken(
        accessToken: accessToken,
        userId: userId,
      );
      await prefs.setString(_prefTokenKey, res.token);
      await prefs.setInt(_prefExpireKey, res.expireAt);
      debugPrint(
        '[ZEGO] Lấy token mới thành công, expireAt=${res.expireAt}, len=${res.token.length}',
      );
      unawaited(_remoteLogger.log('token_success', {
        'user_id': userId,
        'expire_at': res.expireAt,
      }));
      return res.token;
    } catch (e) {
      debugPrint('[ZEGO] Lỗi fetch token: $e');
      unawaited(_remoteLogger.log('token_failed', {
        'user_id': userId,
        'error': e.toString(),
      }));
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

  Future<void> _enterAcceptedOfflineCallWithLog(
      {required String source}) async {
    try {
      ZegoUIKitPrebuiltCallInvitationService().enterAcceptedOfflineCall();
      unawaited(_remoteLogger.log('enter_offline_call', {
        'source': source,
        'user_id': _userId ?? '',
        'inited': _inited,
      }));
    } catch (e) {
      unawaited(_remoteLogger.log('enter_offline_call_failed', {
        'source': source,
        'user_id': _userId ?? '',
        'inited': _inited,
        'error': e.toString(),
      }));
    }
  }

  /// Gọi sau khi navigator đã sẵn sàng (post-frame) để chắc chắn vào màn hình gọi.
  /// ✅ FIX: cold start cần đảm bảo init xong mới enter + retry vài nhịp
  Future<void> ensureEnterAcceptedOfflineCall(
      {String source = 'post_frame'}) async {
    const int maxAttempts = 12; // ~ 12 * 250ms = 3s
    for (int i = 0; i < maxAttempts; i++) {
      try {
        if (!_inited) {
          await tryInitFromPrefs(); // ✅ quan trọng
        }
        if (_inited) {
          await _enterAcceptedOfflineCallWithLog(source: '$source#${i + 1}');
          return;
        }
      } catch (e) {
        unawaited(_remoteLogger.log('ensure_enter_offline_call_err', {
          'source': source,
          'attempt': i + 1,
          'error': e.toString(),
        }));
      }
      await Future.delayed(const Duration(milliseconds: 250));
    }

    unawaited(_remoteLogger.log('ensure_enter_offline_call_giveup', {
      'source': source,
      'user_id': _userId ?? '',
      'inited': _inited,
    }));
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
      // Dùng tên/ảnh nhóm làm "caller" để CallKit/popup hiển thị nhóm thay vì host.
      'caller_name': groupName?.isNotEmpty == true
          ? groupName
          : (callerName ?? _userName ?? _userId ?? ''),
      'caller_avatar': groupAvatar?.isNotEmpty == true
          ? groupAvatar
          : (callerAvatar ?? await _myAvatarFromPrefs()),
      'group_id': groupId,
      'group_name': groupName ?? '',
      'group_avatar': groupAvatar ?? '',
      if (customData != null) ...customData,
    };

    return ZegoUIKitPrebuiltCallInvitationService().send(
      invitees: invitees,
      isVideoCall: isVideoCall,
      callID: callID ?? newGroupCallId(groupId),
      resourceID: ZegoCallConfig.callResourceID.isEmpty
          ? null
          : ZegoCallConfig.callResourceID,
      customData: jsonEncode(data),
      notificationTitle: groupName ?? 'Cuộc gọi nhóm',
      notificationMessage:
          isVideoCall ? 'Cuộc gọi video nhóm' : 'Cuộc gọi thoại nhóm',
    );
  }
}

class _CallProfile {
  final String id;
  final String? name;
  final String? avatar;

  _CallProfile({required this.id, this.name, this.avatar});
}
