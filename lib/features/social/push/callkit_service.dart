// lib/features/social/push/callkit_service.dart
import 'dart:async';
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
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/call_controller.dart';
import '../screens/call_screen.dart';
import 'remote_rtc_log.dart';

class CallkitService {
  CallkitService._();
  static final CallkitService I = CallkitService._();

  bool _inited = false;
  // Map server call_id -> system UUID đã dùng để show CallKit
  final Map<int, String> _systemIds = {};

  /// Đánh dấu các event đã xử lý để tránh lặp
  final Set<String> _handled = <String>{};
  final Set<int> _handledServerIds = <int>{};

  /// Đánh dấu các cuộc gọi đã accept (để setCallConnected 1 lần)
  final Set<String> _accepted = <String>{};
  final Set<int> _trackingRinging = <int>{};
  final Map<int, String> _ringingMedia = <int, String>{}; // callId -> media

  /// Hàng đợi action khi chưa có BuildContext (ví dụ accept từ nền)
  final List<Future<void> Function(BuildContext)> _pendingActions = [];

  bool _routingToCall = false;

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
    /// Hi?n CallKit/ConnectionService incoming
  Future<void> showIncomingCall(Map<String, dynamic> data) async {
    await init();

    final serverId = int.tryParse('${data['call_id'] ?? ''}') ?? 0;

    if (await _isSelfCall(data)) {
      unawaited(RemoteRtcLog.send(
        event: 'callkit_skip_self_call',
        callId: serverId,
      ));
      return;
    }

    // B? qua n?u call_id n�y d� du?c x? l� ho?c dang active tr�n client
    if (serverId > 0 && _handledServerIds.contains(serverId)) {
      return;
    }
    final ctx = navigatorKey.currentContext ?? navigatorKey.currentState?.overlay?.context;
    if (serverId > 0 && ctx != null) {
      try {
        final cc = ctx.read<CallController>();
        if (cc.activeCallId == serverId &&
            cc.callStatus != 'ended' &&
            cc.callStatus != 'declined') {
          return;
        }
      } catch (_) {}
    }

    // id h? th?ng (string) d�ng d? show CallKit
    final systemId = _makeSystemUuidFromServerId(data['call_id']);
    if (serverId > 0) _systemIds[serverId] = systemId;

    // B?t theo d�i ringing s?m d? b?t k?p end/decline
    final mediaEarly = _extractMedia(data);
    if (serverId > 0) {
      _trackRinging(serverId, mediaEarly);
    }
    // metadata hi?n th?
    final callerName =
        (data['caller_name'] ?? data['name'] ?? 'Cu?c g?i d?n').toString();
    final avatar = (data['caller_avatar'] ?? data['avatar'] ?? '').toString();
    final media = mediaEarly;
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
    // id hệ thống (string) của callkit
    final dynamic nestedEvent = event.body['event'];
    final systemId = (event.body['id'] ??
            (nestedEvent is Map ? nestedEvent['id'] : '') ??
            '')
        .toString();

    // lấy extra (payload gốc) để suy ra call_id server, media, avatar, v.v.
    final Map<dynamic, dynamic>? extraDyn =
        event.body['extra'] as Map<dynamic, dynamic>?;
    final extra = extraDyn == null
        ? <String, dynamic>{}
        : extraDyn.map((k, v) => MapEntry(k.toString(), v));

    final rawCallId =
        '${extra['call_id'] ?? extra['callId'] ?? extra['id'] ?? ''}'.trim();
    final int serverCallId = int.tryParse(rawCallId) ?? 0;
    final String media = _extractMedia(extra);
    final String? peerName = extra['caller_name']?.toString();
    final String? peerAvatar = extra['caller_avatar']?.toString();

    unawaited(RemoteRtcLog.send(
      event: 'callkit_event',
      callId: serverCallId,
      details: {
        'evt': evt,
        'systemId': systemId,
        'media': media,
      },
    ));

    switch (evt) {
      case 'ACTION_CALL_INCOMING':
      case 'Event.actionCallIncoming':
        debugPrint(
            '[CallKit] incoming shown: systemId=$systemId serverId=$serverCallId');
        _trackRinging(serverCallId, media);
        break;

      case 'ACTION_CALL_CLICK':
        debugPrint('[CallKit] click notification: systemId=$systemId');
        break;

      case 'ACTION_CALL_ACCEPT':
      case 'Event.actionCallAccept':
        {
          if (systemId.isNotEmpty) _accepted.add(systemId);

          // Fallback: nếu thiếu call_id trong extra → suy ngược từ _systemIds hoặc activeCalls
          var sId = serverCallId;
          if (sId <= 0 && systemId.isNotEmpty) {
            final found = _systemIds.entries.firstWhere(
              (e) => e.value.toLowerCase() == systemId.toLowerCase(),
              orElse: () => const MapEntry(-1, ''),
            );
            if (found.key > 0) sId = found.key;
          }
          if (sId <= 0) {
            try {
              final list = await FlutterCallkitIncoming.activeCalls();
              for (final item in list) {
                if (item is Map &&
                    '${item['id']}'.toLowerCase() == systemId.toLowerCase()) {
                  final extraDyn2 = item['extra'] as Map<dynamic, dynamic>?;
                  final extra2 = extraDyn2 == null
                      ? <String, dynamic>{}
                      : extraDyn2.map((k, v) => MapEntry(k.toString(), v));
                  final raw =
                      '${extra2['call_id'] ?? extra2['callId'] ?? extra2['id'] ?? ''}'
                          .trim();
                  final n = int.tryParse(raw) ?? 0;
                  if (n > 0) {
                    sId = n;
                    break;
                  }
                }
              }
            } catch (_) {}
          }

          await _answer(sId, media, peerName, peerAvatar);
          await flushPendingActions();
          await recoverActiveCalls();
          try {
            await FlutterCallkitIncoming.setCallConnected(systemId);
          } catch (_) {}
          break;
        }
      case 'ACTION_CALL_START':
      case 'Event.actionCallStart':
        {
          if (systemId.isNotEmpty) _accepted.add(systemId);

          var sId = serverCallId;
          if (sId <= 0 && systemId.isNotEmpty) {
            final found = _systemIds.entries.firstWhere(
              (e) => e.value.toLowerCase() == systemId.toLowerCase(),
              orElse: () => const MapEntry(-1, ''),
            );
            if (found.key > 0) sId = found.key;
          }
          if (sId <= 0) {
            try {
              final list = await FlutterCallkitIncoming.activeCalls();
              for (final item in list) {
                if (item is Map &&
                    '${item['id']}'.toLowerCase() == systemId.toLowerCase()) {
                  final extraDyn2 = item['extra'] as Map<dynamic, dynamic>?;
                  final extra2 = extraDyn2 == null
                      ? <String, dynamic>{}
                      : extraDyn2.map((k, v) => MapEntry(k.toString(), v));
                  final raw =
                      '${extra2['call_id'] ?? extra2['callId'] ?? extra2['id'] ?? ''}'
                          .trim();
                  final n = int.tryParse(raw) ?? 0;
                  if (n > 0) {
                    sId = n;
                    break;
                  }
                }
              }
            } catch (_) {}
          }

          await _answer(sId, media, peerName, peerAvatar);
          await flushPendingActions();
          await recoverActiveCalls();
          try {
            await FlutterCallkitIncoming.setCallConnected(systemId);
          } catch (_) {}
          break;
        }
      case 'ACTION_CALL_DECLINE':
      case 'Event.actionCallDecline':
        await _endOrDecline(serverCallId, media, reason: 'decline');
        if (systemId.isNotEmpty) {
          try {
            await FlutterCallkitIncoming.endCall(systemId);
          } catch (_) {}
        }
        await flushPendingActions();
        break;
      case 'ACTION_CALL_ENDED':
      case 'Event.actionCallEnded':
        await _endOrDecline(serverCallId, media, reason: 'end');
        if (systemId.isNotEmpty) {
          try {
            await FlutterCallkitIncoming.endCall(systemId);
          } catch (_) {}
        }
        if (serverCallId > 0) {
          // Vợt cuối đảm bảo tắt theo serverId
          unawaited(endCallForServerId(serverCallId));
        }
        await flushPendingActions();
        break;
      case 'ACTION_CALL_TIMEOUT':
        await _endOrDecline(serverCallId, media, reason: 'timeout');
        if (systemId.isNotEmpty) {
          try {
            await FlutterCallkitIncoming.endCall(systemId);
          } catch (_) {}
        }
        if (serverCallId > 0) {
          unawaited(endCallForServerId(serverCallId));
        }
        await flushPendingActions();
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

  /// Chuẩn hóa media từ payload CallKit (server có thể dùng nhiều key khác nhau)
  String _extractMedia(Map<dynamic, dynamic>? data) {
    if (data == null) return 'audio';
    final media = (data['media'] ??
            data['media_type'] ??
            data['call_type'] ??
            data['type_two'] ??
            data['call_media'])
        ?.toString()
        .toLowerCase();
    return media == 'video' ? 'video' : 'audio';
  }

  Future<bool> _isSelfCall(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final myId = prefs.getString(AppConstants.socialUserId);
      final callerId = (data['caller_id'] ??
              data['from_id'] ??
              data['sender_id'] ??
              data['user_id'])
          ?.toString();
      if (myId != null &&
          myId.isNotEmpty &&
          callerId != null &&
          callerId.isNotEmpty &&
          callerId == myId) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Flush hàng đợi action (vd: accept CallKit khi chưa có context)
  Future<void> flushPendingActions() async {
    if (_pendingActions.isEmpty) return;
    final ctx = navigatorKey.currentState?.overlay?.context ??
        navigatorKey.currentContext;
    if (ctx == null) {
      // Thử lại ở frame kế nếu chưa có context
      Future.microtask(() => flushPendingActions());
      return;
    }
    final actions =
        List<Future<void> Function(BuildContext)>.from(_pendingActions);
    _pendingActions.clear();
    for (final act in actions) {
      try {
        await act(ctx);
      } catch (_) {}
    }
  }

  /// Đồng bộ cuộc gọi đang active trên CallKit phòng khi event ANSWER bị hụt (cold start).
  Future<void> recoverActiveCalls() async {
    try {
      final raw = await FlutterCallkitIncoming.activeCalls();
      if (raw is! List) return;
      for (final item in raw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final extraDyn = map['extra'] as Map<dynamic, dynamic>?;
        final extra = extraDyn == null
            ? <String, dynamic>{}
            : extraDyn.map((k, v) => MapEntry(k.toString(), v));

        final accepted = map['accepted'] == true ||
            map['isAccepted'] == true ||
            map['hasConnected'] == true;

        final serverCallId = int.tryParse(
              '${extra['call_id'] ?? extra['callId'] ?? extra['id'] ?? ''}',
            ) ??
            0;
        if (!accepted || serverCallId <= 0) continue;
        if (_handledServerIds.contains(serverCallId)) continue;

        final media = _extractMedia(extra);
        final peerName = extra['caller_name']?.toString();
        final peerAvatar = extra['caller_avatar']?.toString();

        _trackRinging(serverCallId, media); // đảm bảo poll state
        await _answer(serverCallId, media, peerName, peerAvatar);
      }
    } catch (_) {
      // noop
    }
  }

  Future<void> endCallForServerId(int serverCallId) async {
    if (serverCallId <= 0) return;
    final systemId =
        _systemIds[serverCallId] ?? _makeSystemUuidFromServerId(serverCallId);
    try {
      await FlutterCallkitIncoming.endCall(systemId);
    } catch (_) {}
  }

  String _makeSystemUuidFromServerId(dynamic callId) {
    final raw = (callId == null) ? '' : callId.toString().trim();
    final uuidRegex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    if (uuidRegex.hasMatch(raw)) return raw.toLowerCase();

    final bytes = List<int>.filled(16, 0);
    final codes = raw.codeUnits;
    final codesToUse = codes.isEmpty ? 'callkit-empty'.codeUnits : codes;
    for (var i = 0; i < codesToUse.length; i++) {
      bytes[i % 16] = (bytes[i % 16] + codesToUse[i] + i) & 0xff;
    }
    return _bytesToUuid(bytes);
  }

  String _bytesToUuid(List<int> b) {
    String two(int n) => n.toRadixString(16).padLeft(2, '0');
    final hex = b.map(two).join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }

  void _withController(
    Future<void> Function(CallController cc, BuildContext ctx) fn,
  ) {
    final ctx = navigatorKey.currentState?.overlay?.context ??
        navigatorKey.currentContext;
    if (ctx == null) {
      // Queue lại khi chưa có context (vd: accept từ CallKit trong background)
      _pendingActions.add((readyCtx) async {
        try {
          final cc = readyCtx.read<CallController>();
          await fn(cc, readyCtx);
        } catch (_) {}
      });
      // Kích hoạt flush sớm
      Future.microtask(() => flushPendingActions());
      return;
    }
    try {
      final cc = ctx.read<CallController>();
      unawaited(fn(cc, ctx));
    } catch (_) {
      // Nếu provider chưa sẵn (race), queue lại để thử sau frame kế tiếp
      _pendingActions.add((readyCtx) async {
        try {
          final cc = readyCtx.read<CallController>();
          await fn(cc, readyCtx);
        } catch (_) {}
      });
    }
  }

  void _trackRinging(int serverCallId, String mediaType) {
    if (serverCallId <= 0) return;
    _ringingMedia[serverCallId] = mediaType;
    if (!_trackingRinging.add(serverCallId)) return;

    _withController((cc, ctx) async {
      // attach ringing để bật polling và nhận trạng thái end/decline từ server
      if (cc.activeCallId != serverCallId) {
        cc.attachCall(
          callId: serverCallId,
          mediaType: mediaType,
          initialStatus: 'ringing',
        );
      }

      void listener() {
        final st = cc.callStatus;
        if (st == 'ended' || st == 'declined') {
          // Dừng CallKit khi caller đã kết thúc hoặc callee từ chối qua server
          unawaited(endCallForServerId(serverCallId));
          // “Vợt” UI: đảm bảo caller/callee thoát màn nếu còn mở
          _popAnyCallScreenIfMounted(ctx);
          cc.removeListener(listener);
          _trackingRinging.remove(serverCallId);
          _ringingMedia.remove(serverCallId);
        }
      }

      cc.addListener(listener);
    });

    // Đảm bảo pending actions được đẩy nếu chưa có context ngay
    Future.microtask(() => flushPendingActions());
  }

  Future<void> _answer(int serverCallId, String media, String? peerName,
      String? peerAvatar) async {
    if (serverCallId <= 0) {
      debugPrint('[CallKit] Skip answer: missing call_id in extra');
      return;
    }

    final preferredMedia = _ringingMedia[serverCallId];
    final mediaFixed =
        (media == 'audio' && preferredMedia == 'video') ? 'video' : media;

    final key = 'ans:$serverCallId';
    if (_handled.contains(key)) return;
    _handled.add(key);
    _handledServerIds.add(serverCallId);

    unawaited(RemoteRtcLog.send(
      event: 'answer_start',
      callId: serverCallId,
      details: {'media': mediaFixed},
    ));

    _withController((cc, ctx) async {
      if (!cc.isCallHandled(serverCallId)) {
        cc.attachCall(
          callId: serverCallId,
          mediaType: mediaFixed,
          initialStatus: 'answered',
        );
      }

      // Show UI immediately; avoid waiting for network action('answer')
      _openCallScreen(
        ctx,
        serverCallId,
        mediaFixed,
        peerName: peerName,
        peerAvatar: peerAvatar,
      );

      // Send answer to server in background to reduce UI delay
      unawaited(() async {
        try {
          await cc.action('answer');
          await RemoteRtcLog.send(
            event: 'answer_action_sent',
            callId: serverCallId,
          );
        } catch (_) {}
      }());
    });
  }

  Future<void> _endOrDecline(int serverCallId, String media,
      {required String reason}) async {
    if (serverCallId <= 0) return;
    final key = 'end:$reason:$serverCallId';
    if (_handled.contains(key)) return;
    _handled.add(key);
    _ringingMedia.remove(serverCallId);

    unawaited(RemoteRtcLog.send(
      event: 'end_or_decline',
      callId: serverCallId,
      details: {'reason': reason, 'media': media},
    ));

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

      // Đảm bảo UI caller/callee thoát màn hình call nếu vẫn đang mở
      try {
        final ctx = navigatorKey.currentState?.overlay?.context ??
            navigatorKey.currentContext;
        if (ctx != null) {
          _popAnyCallScreenIfMounted(ctx);
        } else {
          _pendingActions.add((readyCtx) async {
            _popAnyCallScreenIfMounted(readyCtx);
          });
        }
      } catch (_) {}
    });

    // Push CallKit đóng ngay nếu có id
    if (reason == 'decline' || reason == 'end') {
      unawaited(endCallForServerId(serverCallId));
    }

    // Đảm bảo hành động queued được xử lý
    Future.microtask(() => flushPendingActions());
  }

  void _openCallScreen(
    BuildContext ctx,
    int callId,
    String mediaType, {
    String? peerName,
    String? peerAvatar,
  }) {
    if (_routingToCall) return;
    _routingToCall = true;

    final route = MaterialPageRoute(
      settings: const RouteSettings(name: 'CallScreen'),
      builder: (_) => CallScreen(
        isCaller: false,
        callId: callId,
        mediaType: mediaType,
        peerName: peerName,
        peerAvatar: peerAvatar,
      ),
    );

    Future<void> pushRoute() async {
      try {
        final nav = Navigator.of(ctx, rootNavigator: true);
        await nav.push(route);
      } catch (_) {
        final nav = navigatorKey.currentState;
        if (nav != null) {
          await nav.push(route);
        } else {
          rethrow;
        }
      } finally {
        _routingToCall = false;
      }
    }

    pushRoute().catchError((_) {
      // Retry once shortly after (cold start, context vừa ready)
      Future.delayed(const Duration(milliseconds: 250), () async {
        try {
          final nav = navigatorKey.currentState;
          if (nav != null) {
            await nav.push(route);
          }
        } catch (_) {} finally {
          _routingToCall = false;
        }
      });
    });
  }

  void _popAnyCallScreenIfMounted(BuildContext ctx) {
    try {
      Navigator.of(ctx, rootNavigator: true).popUntil(
        (route) => route.settings.name != 'CallScreen',
      );
    } catch (_) {}
  }
}



