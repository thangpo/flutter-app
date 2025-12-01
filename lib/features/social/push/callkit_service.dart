// lib/features/social/push/callkit_service.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/helper/app_globals.dart' show navigatorKey;
import '../controllers/call_controller.dart';
import '../screens/call_screen.dart';

class CallkitService {
  CallkitService._();
  static final CallkitService I = CallkitService._();

  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    _inited = true;
    try {
      FlutterCallkitIncoming.onEvent.listen(_onEvent);
    } catch (_) {}
  }

  Future<void> showIncomingCall(Map<String, dynamic> data) async {
    await init();
    final callId = (int.tryParse('${data['call_id']}') ??
            data['call_id']?.hashCode ??
            Random().nextInt(1 << 31))
        .abs()
        .toString();
    final name =
        (data['caller_name'] ?? data['name'] ?? 'Cuộc gọi đến').toString();
    final avatar = (data['caller_avatar'] ?? data['avatar'] ?? '').toString();
    final media = (data['media'] ?? data['media_type'] ?? 'audio').toString();
    final isVideo = media == 'video';

    final params = CallKitParams(
      id: callId,
      nameCaller: name,
      appName: 'VNShop247',
      avatar: avatar,
      handle: name,
      type: isVideo ? 1 : 0,
      duration: 0,
      textAccept: 'Nghe',
      textDecline: 'Từ chối',
      extra: data,
      android: const AndroidParams(
        isCustomNotification: true,
        isShowFullLockedScreen: true,
        isShowCallID: true,
        ringtonePath: 'system_ringtone_default',
      ),
      ios: IOSParams(
        handleType: 'generic',
        supportsVideo: isVideo,
      ),
      missedCallNotification: const NotificationParams(),
    );
    try {
      await FlutterCallkitIncoming.showCallkitIncoming(params);
    } catch (_) {}
  }

  Future<void> _onEvent(CallEvent? event) async {
    if (event == null) return;
    final name = '${event.event}';
    final extra = event.body['extra'] as Map<dynamic, dynamic>?;
    final rawId = extra?['call_id'] ?? event.body['id'];
    final callId = int.tryParse('$rawId') ?? 0;
    final media =
        (extra?['media'] ?? extra?['media_type'] ?? 'audio').toString();

    if (name == 'ACTION_CALL_ACCEPT') {
      _withController((cc, ctx) async {
        if (callId > 0 && !cc.isCallHandled(callId)) {
          cc.attachCall(
              callId: callId, mediaType: media, initialStatus: 'answered');
        }
        try {
          await cc.action('answer');
        } catch (_) {}
        _openCallScreen(ctx, callId, media,
            peerName: extra?['caller_name']?.toString(),
            peerAvatar: extra?['caller_avatar']?.toString());
      });
    } else if (name == 'ACTION_CALL_DECLINE' ||
        name == 'ACTION_CALL_ENDED' ||
        name == 'ACTION_CALL_TIMEOUT') {
      _withController((cc, _) async {
        if (callId > 0 && !cc.isCallHandled(callId)) {
          cc.attachCall(
              callId: callId, mediaType: media, initialStatus: 'ended');
        }
        try {
          await cc.action('decline');
        } catch (_) {}
      });
    }
  }

  void _withController(
      Future<void> Function(CallController cc, BuildContext ctx) fn) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    try {
      final cc = ctx.read<CallController>();
      fn(cc, ctx);
    } catch (_) {}
  }

  void _openCallScreen(BuildContext ctx, int callId, String mediaType,
      {String? peerName, String? peerAvatar}) {
    Navigator.of(ctx).push(MaterialPageRoute(
      builder: (_) => CallScreen(
        isCaller: false,
        callId: callId,
        mediaType: mediaType,
        peerName: peerName,
        peerAvatar: peerAvatar,
      ),
    ));
  }
}
