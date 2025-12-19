import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

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

    final token = await _getValidToken(userId: userId);
    if (token == null || token.isEmpty) {
      debugPrint('[ZEGO] Không lấy được token từ server, bỏ qua init.');
      return;
    }

    _userId = userId;
    _userName = userName;

    await ZegoUIKitPrebuiltCallInvitationService().init(
      appID: ZegoCallConfig.appID,
      appSign: '', // AppSign nằm ở server, client chỉ dùng token
      token: token,
      userID: userId,
      userName: userName,
      plugins: [ZegoUIKitSignalingPlugin()],
      requireConfig: (ZegoCallInvitationData data) {
        final isVideo = data.type == ZegoCallType.videoCall;
        final isGroup = data.invitees.length > 1;
        return isGroup
            ? (isVideo
                ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
                : ZegoUIKitPrebuiltCallConfig.groupVoiceCall())
            : (isVideo
                ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall());
      },
    );

    _inited = true;
    debugPrint('[ZEGO] Call invitation service inited for user=$userId');
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
    final cachedToken = prefs.getString(_prefTokenKey);
    final expireAt = prefs.getInt(_prefExpireKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (cachedToken != null && cachedToken.isNotEmpty && expireAt > now + 60) {
      return cachedToken;
    }

    final accessToken = prefs.getString(AppConstants.socialAccessToken) ?? '';
    if (accessToken.isEmpty) {
      debugPrint('[ZEGO] Không có social access_token để xin token');
      return null;
    }

    try {
      final res = await _tokenRepo.fetchToken(
        accessToken: accessToken,
        userId: userId,
      );
      await prefs.setString(_prefTokenKey, res.token);
      await prefs.setInt(_prefExpireKey, res.expireAt);
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
  }) async {
    if (!_inited) {
      await tryInitFromPrefs();
    }
    if (!_inited) return false;

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
        'is_video': isVideoCall,
      }),
    );
  }

  Future<bool> startGroup({
    required List<ZegoCallUser> invitees,
    required bool isVideoCall,
    String? callID,
    Map<String, dynamic>? customData,
  }) async {
    if (!_inited) {
      await tryInitFromPrefs();
    }
    if (!_inited) return false;

    final data = <String, dynamic>{
      'scope': 'social',
      'mode': 'group',
      'is_video': isVideoCall,
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
