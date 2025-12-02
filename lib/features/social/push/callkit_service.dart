// lib/features/social/push/callkit_service.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';

import 'package:flutter_sixvalley_ecommerce/helper/app_globals.dart'
    show navigatorKey;
import '../controllers/call_controller.dart';
import '../screens/call_screen.dart';

class CallkitService {
  CallkitService._();
  static final CallkitService I = CallkitService._();

  bool _inited = false;

  /// Đánh dấu các event đã xử lý để tránh lặp
  final Set<String> _handled = <String>{};
  final Set<int> _handledServerIds = <int>{};

  /// Đánh dấu các cuộc gọi đã accept (để setCallConnected 1 lần)
  final Set<String> _accepted = <String>{};

  /// Hàng đợi action khi chưa có BuildContext (ví dụ accept từ nền)
  final List<Future<void> Function(BuildContext)> _pendingActions = [];

  Future<void> init() async {
    if (_inited) return;
    _inited = true;
    try {
      // Tuỳ phiên bản plugin/OS, có thể cần xin quyền. Tránh crash khác bản nên để try/catch.
      // try { await FlutterCallkitIncoming.requestNotificationPermission(const NotificationSettingsAndroid()); } catch (_) {}
      // try { await FlutterCallkitIncoming.requestPermissionAndroid(); } catch (_) {}

      FlutterCallkitIncoming.onEvent.listen(_onEvent, onError: (_) {});
    } catch (_) {
      // noop
    }
  }

  /// Hiển thị màn hình cuộc gọi đến (CallKit / ConnectionService)
  Future<void> showIncomingCall(Map<String, dynamic> data) async {
    await init();

    // id hệ thống (string) — KHÔNG phải call_id server
    final systemId = _makeSystemIdFromServerId(data['call_id']);

    // metadata hiển thị
    final callerName =
        (data['caller_name'] ?? data['name'] ?? 'Cuộc gọi đến').toString();
    final avatar = (data['caller_avatar'] ?? data['avatar'] ?? '').toString();
    final media = (data['media'] ?? data['media_type'] ?? 'audio').toString();
    final isVideo = media == 'video';

    final params = CallKitParams(
      id: systemId,
      nameCaller: callerName,
      appName: 'VNShop247',
      avatar: avatar,
      handle: callerName, // nếu có số điện thoại thì gán số ở đây
      type: isVideo ? 1 : 0,
      // duration=0: để native tự timeout -> sẽ có ACTION_CALL_TIMEOUT
      duration: 0,
      textAccept: 'Nghe',
      textDecline: 'Từ chối',
      extra: Map<String, dynamic>.from(data), // giữ payload gốc để đọc call_id
      android: const AndroidParams(
        isCustomNotification: true,
        isShowFullLockedScreen: true,
        isShowCallID: true,
        // 'system_ringtone_default' hoặc path asset raw của bạn
        ringtonePath: 'system_ringtone_default',
        incomingCallNotificationChannelName: 'incoming_calls',
        missedCallNotificationChannelName: 'missed_calls',
      ),
      ios: IOSParams(
        handleType: 'generic',
        supportsVideo: isVideo,
      ),
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Cuộc gọi nhỡ',
        callbackText: 'Gọi lại',
      ),
    );

    try {
      await FlutterCallkitIncoming.showCallkitIncoming(params);
    } catch (_) {
      // noop
    }
  }

  // =========================
  // Event handler
  // =========================
  Future<void> _onEvent(CallEvent? event) async {
    if (event == null) return;

    final evt = '${event.event}'.trim();

    // id hệ thống (string) của callkit
    final systemId =
        (event.body['id'] ?? event.body['event']?['id'] ?? '').toString();

    // lấy extra (payload gốc) để suy ra call_id server, media, avatar, v.v.
    final Map<dynamic, dynamic>? extraDyn =
        event.body['extra'] as Map<dynamic, dynamic>?;
    final extra = extraDyn == null
        ? <String, dynamic>{}
        : extraDyn.map((k, v) => MapEntry(k.toString(), v));

    final int serverCallId = int.tryParse('${extra['call_id'] ?? ''}') ?? 0;
    final String media =
        (extra['media'] ?? extra['media_type'] ?? 'audio').toString();
    final String? peerName = extra['caller_name']?.toString();
    final String? peerAvatar = extra['caller_avatar']?.toString();

    switch (evt) {
      case 'ACTION_CALL_INCOMING':
        debugPrint(
            '[CallKit] incoming shown: systemId=$systemId serverId=$serverCallId');
        break;

      case 'ACTION_CALL_CLICK':
        debugPrint('[CallKit] click notification: systemId=$systemId');
        break;

      case 'ACTION_CALL_ACCEPT':
        if (systemId.isNotEmpty) _accepted.add(systemId);
        await _answer(serverCallId, media, peerName, peerAvatar);
        try {
          await FlutterCallkitIncoming.setCallConnected(systemId);
        } catch (_) {}
        break;

      case 'ACTION_CALL_DECLINE':
        await _endOrDecline(serverCallId, media, reason: 'decline');
        try {
          await FlutterCallkitIncoming.endCall(systemId);
        } catch (_) {}
        break;

      case 'ACTION_CALL_ENDED':
        await _endOrDecline(serverCallId, media, reason: 'end');
        try {
          await FlutterCallkitIncoming.endCall(systemId);
        } catch (_) {}
        break;

      case 'ACTION_CALL_TIMEOUT':
        await _endOrDecline(serverCallId, media, reason: 'timeout');
        try {
          await FlutterCallkitIncoming.endCall(systemId);
        } catch (_) {}
        break;

      case 'ACTION_DID_UPDATE_DEVICE_PUSH_TOKEN_VOIP':
        debugPrint(
            '[CallKit] VoIP token updated (native handled in AppDelegate).');
        break;

      default:
        // mute/hold/… nếu cần thì map thêm
        break;
    }
  }

  // =========================
  // Helpers & public APIs
  // =========================

  /// Cho listener kiểm tra call_id đã xử lý qua CallKit
  bool isServerCallHandled(int id) => _handledServerIds.contains(id);

  /// Flush hàng đợi action (vd: accept CallKit khi chưa có context)
  Future<void> flushPendingActions() async {
    if (_pendingActions.isEmpty) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    final actions =
        List<Future<void> Function(BuildContext)>.from(_pendingActions);
    _pendingActions.clear();
    for (final act in actions) {
      try {
        await act(ctx);
      } catch (_) {}
    }
  }

  String _makeSystemIdFromServerId(dynamic callId) {
    // Nếu server gửi call_id là số: tái sử dụng (string). Nếu không: random ổn định
    final s = (callId == null) ? '' : callId.toString().trim();
    if (s.isNotEmpty && int.tryParse(s) != null) return s;
    return (callId?.hashCode ?? Random().nextInt(1 << 31)).abs().toString();
  }

  void _withController(
      Future<void> Function(CallController cc, BuildContext ctx) fn) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      // Queue lại khi chưa có context (vd: accept từ CallKit trong background)
      _pendingActions.add((readyCtx) async {
        try {
          final cc = readyCtx.read<CallController>();
          await fn(cc, readyCtx);
        } catch (_) {}
      });
      return;
    }
    try {
      final cc = ctx.read<CallController>();
      fn(cc, ctx);
    } catch (_) {}
  }

  Future<void> _answer(int serverCallId, String media, String? peerName,
      String? peerAvatar) async {
    if (serverCallId <= 0) return;
    final key = 'ans:$serverCallId';
    if (_handled.contains(key)) return;
    _handled.add(key);
    _handledServerIds.add(serverCallId);

    _withController((cc, ctx) async {
      if (!cc.isCallHandled(serverCallId)) {
        cc.attachCall(
            callId: serverCallId, mediaType: media, initialStatus: 'answered');
      }
      try {
        await cc.action('answer');
      } catch (_) {}

      _openCallScreen(
        ctx,
        serverCallId,
        media,
        peerName: peerName,
        peerAvatar: peerAvatar,
      );
    });
  }

  Future<void> _endOrDecline(int serverCallId, String media,
      {required String reason}) async {
    if (serverCallId <= 0) return;
    final key = 'end:$reason:$serverCallId';
    if (_handled.contains(key)) return;
    _handled.add(key);

    _withController((cc, _) async {
      if (!cc.isCallHandled(serverCallId)) {
        cc.attachCall(
          callId: serverCallId,
          mediaType: media,
          initialStatus: reason == 'decline' ? 'declined' : 'ended',
        );
      }
      try {
        if (reason == 'decline') {
          await cc.action('decline');
        } else {
          await cc.action('end');
        }
      } catch (_) {}
    });
  }

  void _openCallScreen(
    BuildContext ctx,
    int callId,
    String mediaType, {
    String? peerName,
    String? peerAvatar,
  }) {
    // Nếu dùng UI in-call native hoàn toàn, có thể bỏ navigation này.
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
