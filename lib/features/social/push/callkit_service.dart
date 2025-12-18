// lib/features/social/push/callkit_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_sixvalley_ecommerce/helper/app_exit_guard.dart';

import 'package:flutter_sixvalley_ecommerce/helper/app_globals.dart'
    show navigatorKey;
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../controllers/call_controller.dart';
import '../controllers/group_call_controller.dart';
import '../screens/call_screen.dart';
import '../screens/group_call_screen.dart';
import 'remote_rtc_log.dart';

class CallkitService {
  CallkitService._();
  static final CallkitService I = CallkitService._();

  bool _inited = false;
  // Map server call_id -> system UUID đã dùng để show CallKit
  final Map<int, String> _systemIds = {};
  final Map<String, String> _groupSystemIds = {};
  static const _storageKeyPrefix = 'callkit_map_'; // lưu mapping để recovery cold start

  /// Đánh dấu các event đã xử lý để tránh lặp
  final Set<String> _handled = <String>{};
  final Set<int> _handledServerIds = <int>{};
  final Set<String> _handledGroupKeys = <String>{};
  final Set<String> _endedGroupKeys = <String>{};
  final Set<String> _endedGroupIds = <String>{}; // đánh dấu group đã dập (dù callId rỗng)

  // Nhóm vừa end trong vài giây gần đây (debounce foreground)
  final Map<String, DateTime> _recentlyEndedGroup = {};
  bool _wasGroupRecentlyEndedLocal(String gid, {int seconds = 8}) {
    final t = _recentlyEndedGroup[gid];
    if (t == null) return false;
    return DateTime.now().difference(t).inSeconds < seconds;
  }

  /// Đánh dấu các cuộc gọi đã accept (để setCallConnected 1 lần)
  final Set<String> _accepted = <String>{};
  final Set<int> _trackingRinging = <int>{};
  final Map<int, String> _ringingMedia = <int, String>{}; // callId -> media
  final Map<String, String> _ringingGroupMedia = <String, String>{};
  final Map<String, String?> _ringingGroupName = <String, String?>{};
  final Map<String, DateTime> _groupIncomingAt = <String, DateTime>{};

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
    final ctx = navigatorKey.currentContext ??
        navigatorKey.currentState?.overlay?.context;
    if (ctx != null) {
      try {
        final cc = ctx.read<CallController>();
        final activeId = cc.activeCallId;
        final activeStatus = cc.callStatus;
        final isActive =
            activeId != null && activeStatus != 'ended' && activeStatus != 'declined';

        // Nếu đang ở trong một cuộc gọi (caller/callee), đừng show CallKit mới:
        // - serverId trùng call hiện tại
        // - hoặc thiếu call_id (serverId <= 0) nhưng vẫn đang có cuộc gọi
        if (isActive &&
            (serverId <= 0 || (activeId != null && activeId == serverId))) {
          debugPrint(
              '[CallKit] skip incoming (active call=$activeId status=$activeStatus)');
          return;
        }
      } catch (_) {}
    }

    // id h? th?ng (string) d�ng d? show CallKit
    final systemId = _makeSystemUuidFromServerId(data['call_id']);
    if (serverId > 0) {
      _systemIds[serverId] = systemId;
      _persistSystemId(serverId, systemId);
    }

    // B?t theo d�i ringing s?m d? b?t k?p end/decline
    final mediaEarly = _extractMedia(data);
    if (serverId > 0) {
      _trackRinging(serverId, mediaEarly);
    }
    // metadata hi?n th?
    final callerName =
        (data['caller_name'] ?? data['name'] ?? 'Cuộc gọi đến').toString();
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
      // Đặt timeout hiển thị đủ dài để tránh ACTION_CALL_TIMEOUT tức thì
      duration: 60000, // ms
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

    // ghi log server nếu là group (payload có group_id)
    final gidForLog = _extractGroupId(data);
    if (gidForLog.isNotEmpty) {
      _sendGroupDebugLog('show_incoming_group_call', {
        'call_id': serverId,
        'group_id': gidForLog,
        'media': media,
        'system_id': systemId,
      });
    }
  }

  /// Hiện CallKit cho cuộc gọi nhóm (iOS)
  Future<void> showIncomingGroupCall(Map<String, dynamic> data) async {
    await init();

    final serverId = int.tryParse('${data['call_id'] ?? ''}') ?? 0;
    final groupId = _extractGroupId(data);
    if (groupId.isEmpty) return;
    if (_wasGroupRecentlyEndedLocal(groupId)) {
      _sendGroupDebugLog('SKIP_SHOW_RECENTLY_ENDED_LOCAL', {'group_id': groupId});
      // Dập nếu SDK đã lỡ hiện (phòng hộ)
      await endGroupCall(groupId, serverId);
      return;
    }

    if (await _isSelfCall(data)) return;

    final key = _groupKey(groupId, serverId);
    if (_endedGroupKeys.contains(key)) {
      // Đã kết thúc trước đó (push call_group_end) -> bỏ qua
      return;
    }
    if (_endedGroupIds.contains(groupId)) {
      // Group đã bị dập toàn bộ -> đảm bảo tắt CallKit nếu SDK vẫn bắn incoming
      await endGroupCall(groupId, serverId);
      return;
    }
    if (serverId > 0 && _handledGroupKeys.contains(key)) {
      return;
    }

    final ctx = navigatorKey.currentContext ??
        navigatorKey.currentState?.overlay?.context;
    if (ctx != null) {
      try {
        final gc = ctx.read<GroupCallController>();
        final activeId = gc.currentCallId;
        final activeStatus = gc.status;
        final active = activeId != null &&
            activeStatus != CallStatus.ended &&
            activeStatus != CallStatus.idle;
        if (active && activeId == serverId) return;
      } catch (_) {}
    }

    final systemId = _makeSystemUuidFromServerId('$groupId|$serverId');
    if (key.isNotEmpty) {
      _groupSystemIds[key] = systemId;
    }

    final media = _extractMedia(data);
    _ringingGroupMedia[key] = media;
    _ringingGroupName[key] = data['group_name']?.toString();

    final groupTitle = (data['group_name']?.toString().isNotEmpty ?? false)
        ? data['group_name'].toString()
        : 'Cuộc gọi nhóm';
    final avatar = (data['caller_avatar'] ?? data['avatar'] ?? '').toString();
    final isVideo = media == 'video';

    final params = CallKitParams(
      id: systemId,
      nameCaller: groupTitle,
      appName: 'VNShop247',
      avatar: avatar,
      handle: groupTitle,
      type: isVideo ? 1 : 0,
      // Đặt timeout hiển thị đủ dài để tránh Event.actionCallTimeout tức thì
      duration: 60000, // ms
      textAccept: 'Nghe',
      textDecline: 'Từ chối',
      extra: {
        ...Map<String, dynamic>.from(data),
        'group_id': groupId,
        'group_name': groupTitle,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowFullLockedScreen: true,
        isShowCallID: true,
        ringtonePath: 'system_ringtone_default',
        incomingCallNotificationChannelName: 'incoming_calls',
        missedCallNotificationChannelName: 'missed_calls',
      ),
      ios: IOSParams(
        handleType: 'generic',
        supportsVideo: isVideo,
      ),
      missedCallNotification: NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: groupTitle,
        callbackText: 'Gọi lại',
      ),
    );

    try {
      await FlutterCallkitIncoming.showCallkitIncoming(params);
    } catch (_) {}
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
    int serverCallId = int.tryParse(rawCallId) ?? 0;
    final String media = _extractMedia(extra);
    final String? peerName = extra['caller_name']?.toString();
    final String? peerAvatar = extra['caller_avatar']?.toString();
    String groupId = _extractGroupId(extra);
    final String? groupName = extra['group_name']?.toString();

    // Một số event CallKit (nhất là khi app bị kill) mất call_id/group_id trong extra.
    // Thử khôi phục dựa vào systemId đã lưu khi showIncomingGroupCall.
    if ((groupId.isEmpty || serverCallId <= 0) && systemId.isNotEmpty) {
      final match = _groupSystemIds.entries.firstWhere(
        (e) => e.value.toLowerCase() == systemId.toLowerCase(),
        orElse: () => const MapEntry('', ''),
      );
      if (match.key.isNotEmpty) {
        final parts = match.key.split('|');
        if (parts.isNotEmpty && groupId.isEmpty) {
          groupId = parts.first;
        }
        if (parts.length > 1 && serverCallId <= 0) {
          serverCallId = int.tryParse(parts.last) ?? serverCallId;
        }
      }
    }
    // Cold start Android: systemId có nhưng call_id trống -> đọc mapping persist
    if (serverCallId <= 0 && systemId.isNotEmpty) {
      final recovered = await _recoverCallId(systemId);
      if (recovered > 0) {
        serverCallId = recovered;
        _systemIds[recovered] = systemId;
      }
    }
    // Cold start Android: systemId có nhưng call_id trống -> đọc mapping persist
    if (serverCallId <= 0 && systemId.isNotEmpty) {
      final recovered = await _recoverCallId(systemId);
      if (recovered > 0) {
        serverCallId = recovered;
        _systemIds[recovered] = systemId;
      }
    }

    unawaited(RemoteRtcLog.send(
      event: 'callkit_event',
      callId: serverCallId,
      details: {
        'evt': evt,
        'systemId': systemId,
        'media': media,
        'group': groupId,
      },
    ));

    if (groupId.isNotEmpty) {
      await _handleGroupEvent(
        evt: evt,
        systemId: systemId,
        serverCallId: serverCallId,
        groupId: groupId,
        media: media,
        groupName: groupName,
        extra: extra,
      );
      // log CallKit event nhóm
      _sendGroupDebugLog('callkit_group_event', {
        'evt': evt,
        'system_id': systemId,
        'call_id': serverCallId,
        'group_id': groupId,
        'media': media,
      });
      return;
    }

    switch (evt) {
      case 'ACTION_CALL_INCOMING':
      case 'Event.actionCallIncoming':
        if (groupId.isNotEmpty && _wasGroupRecentlyEndedLocal(groupId)) {
          _sendGroupDebugLog('SKIP_EVT_INCOMING_RECENTLY_ENDED_LOCAL', {
            'group_id': groupId,
            'call_id': serverCallId,
          });
          if (systemId.isNotEmpty) {
            unawaited(FlutterCallkitIncoming.endCall(systemId));
          }
          return;
        }
        debugPrint(
            '[CallKit] incoming shown: systemId=$systemId serverId=$serverCallId');
        // Nếu thiết bị đang ở trong call (caller/callee) thì bỏ qua incoming mới
        try {
          final ctx =
              navigatorKey.currentState?.overlay?.context ?? navigatorKey.currentContext;
          final cc = ctx?.read<CallController>();
          final activeId = cc?.activeCallId;
          final activeStatus = cc?.callStatus;
          final isActive = activeId != null &&
              activeStatus != 'ended' &&
              activeStatus != 'declined' &&
              activeStatus != 'ringing';

          final sameCall = isActive && serverCallId > 0 && activeId == serverCallId;
          final strayNoId = isActive && serverCallId <= 0;

          if (sameCall || strayNoId) {
            debugPrint('[CallKit] ignore incoming (already in call) activeId=$activeId');
            if (systemId.isNotEmpty) {
              unawaited(FlutterCallkitIncoming.endCall(systemId));
            }
            return;
          }
        } catch (_) {}

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

  bool isGroupCallHandled(String groupId, int callId) =>
      _handledGroupKeys.contains(_groupKey(groupId, callId));

  /// Đánh dấu call_id đã được xử lý trên thiết bị này (vd: caller tự khởi tạo).
  void markServerCallHandled(int serverCallId) {
    if (serverCallId <= 0) return;
    _handledServerIds.add(serverCallId);
  }

  void markGroupCallHandled(String groupId, int callId) {
    if (groupId.isEmpty || callId <= 0) return;
    _handledGroupKeys.add(_groupKey(groupId, callId));
  }

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

        final systemId = (map['id'] ?? '').toString();

        // iOS 18 fallback: coi như "đã nhận" nếu (a) CallKit gửi event ACCEPT trước đó
        // và _accepted có chứa systemId, hoặc (b) map có state/answered thủ công.
        final accepted =
            map['accepted'] == true ||
            map['isAccepted'] == true ||
            map['hasConnected'] == true ||
            _accepted.contains(systemId) ||
            (map['answered'] == true) ||
            ((map['state']?.toString().toLowerCase() ?? '') == 'answered');

        // Lấy serverCallId (có thể mất trên iOS 18). Thử thêm các đường suy ngược.
        int serverCallId = int.tryParse(
              '${extra['call_id'] ?? extra['callId'] ?? extra['id'] ?? ''}',
            ) ?? 0;

        if (serverCallId <= 0) {
          // 1) Tra ngược từ bảng _systemIds (1-1)
          final found = _systemIds.entries.firstWhere(
            (e) => e.value.toLowerCase() == systemId.toLowerCase(),
            orElse: () => const MapEntry(-1, ''),
          );
          if (found.key > 0) serverCallId = found.key;

          // 2) Thử đọc lại từ activeCalls() theo systemId (đề phòng extra mất)
          if (serverCallId <= 0 && systemId.isNotEmpty) {
            try {
              final list = await FlutterCallkitIncoming.activeCalls();
              for (final item in list) {
                if (item is Map && '${item['id']}'.toLowerCase() == systemId.toLowerCase()) {
                  final extraDyn2 = item['extra'] as Map<dynamic, dynamic>?;
                  final extra2 = extraDyn2 == null
                      ? <String, dynamic>{}
                      : extraDyn2.map((k, v) => MapEntry(k.toString(), v));
                  final rawId = '${extra2['call_id'] ?? extra2['callId'] ?? extra2['id'] ?? ''}'.trim();
                  final n = int.tryParse(rawId) ?? 0;
                  if (n > 0) {
                    serverCallId = n;
                    break;
                  }
                }
              }
            } catch (_) {}
          }
        }

        // Nếu accepted bị thiếu trên iOS 18 nhưng ta đã suy ra được serverCallId → vẫn route.
        if ((!accepted) && serverCallId <= 0) continue;
        if (_handledServerIds.contains(serverCallId)) continue;

        final media = _extractMedia(extra);
        final peerName = extra['caller_name']?.toString();
        final peerAvatar = extra['caller_avatar']?.toString();
        final gid = _extractGroupId(extra);

        if (gid.isNotEmpty) {
          _trackGroupRinging(
            gid,
            serverCallId,
            media,
            groupName: extra['group_name']?.toString(),
            systemId: map['id']?.toString(),
          );
          await _answerGroup(
            serverCallId,
            gid,
            media,
            extra['group_name']?.toString(),
          );
        } else {
          _trackRinging(serverCallId, media); // d?m b?o poll state
          await _answer(serverCallId, media, peerName, peerAvatar);
        }
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

  /// Kết thúc CallKit cuộc gọi nhóm (dùng cho push call_group_end)
  Future<void> endGroupCall(String groupId, int callId) async {
    if (groupId.isEmpty && callId <= 0) return;
    final key = _groupKey(groupId, callId <= 0 ? 0 : callId);
    _endedGroupKeys.add(key);
    _endedGroupIds.add(groupId);
    _recentlyEndedGroup[groupId] = DateTime.now();
    _handledGroupKeys.add(key);
    _ringingGroupMedia.remove(key);
    _ringingGroupName.remove(key);
    _groupIncomingAt.remove(key);

    // Nếu callId không rõ, cố gắng tìm tất cả systemId thuộc groupId để dập
    final keysToEnd = <String>{key};
    if (callId <= 0 && groupId.isNotEmpty) {
      _groupSystemIds.forEach((k, v) {
        if (k.startsWith('$groupId|')) {
          keysToEnd.add(k);
        }
      });
    }

    for (final k in keysToEnd) {
      final sysId = _groupSystemIds[k] ?? _makeSystemUuidFromServerId(k);
      try {
        await FlutterCallkitIncoming.endCall(sysId);
      } catch (_) {}
    }
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (_) {}
  }

  /// Push 'call_group_end' cần dập CallKit và thoát GroupCallScreen nếu đang mở.
  Future<void> handleRemoteGroupEnded(String groupId, int callId) async {
    _sendGroupDebugLog('push_group_end_received', {
      'group_id': groupId,
      'call_id': callId,
    });
    await endGroupCall(groupId, callId);

    _withGroupController((gc, ctx) async {
      final matchesCall =
          (callId > 0 && gc.currentCallId == callId) ||
              (callId <= 0 && gc.currentCallId != null);
      final matchesGroup =
          groupId.isNotEmpty && (gc.currentGroupId == groupId);
      final hasCurrent =
          gc.currentCallId != null || (gc.currentGroupId?.isNotEmpty ?? false);
      if (!hasCurrent || (!matchesCall && !matchesGroup)) {
        // Fallback: vẫn pop UI nếu đang mở CallScreen/GroupCallScreen bị kẹt
        _popAnyCallScreenIfMounted(ctx);
        _sendGroupDebugLog('push_group_end_pop_fallback', {
          'group_id': groupId,
          'call_id': callId,
          'has_current': hasCurrent ? 1 : 0,
          'matches_call': matchesCall ? 1 : 0,
          'matches_group': matchesGroup ? 1 : 0,
        });
        return;
      }

      gc.handleRemoteEnded(
        callId: callId > 0 ? callId : null,
        groupId: groupId.isNotEmpty ? groupId : null,
      );
      _sendGroupDebugLog('push_group_end_handled', {
        'group_id': groupId,
        'call_id': callId,
      });
      _popAnyCallScreenIfMounted(ctx);
    });
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

  Future<void> _persistSystemId(int callId, String systemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_storageKeyPrefix + systemId, callId);
    } catch (_) {
      // ignore
    }
  }

  Future<int> _recoverCallId(String systemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_storageKeyPrefix + systemId) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Fallback: lấy cuộc gọi ringing mới nhất cho user hiện tại (type=inbox)
  Future<Map<String, dynamic>> _fetchLatestIncomingCall() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.socialAccessToken);
      if (token == null || token.isEmpty) return {};

      final uri = Uri.parse(
        '${AppConstants.socialBaseUrl}/api/webrtc?type=inbox&access_token=$token&since=${DateTime.now().millisecondsSinceEpoch ~/ 1000 - 300}',
      );
      final resp = await http.post(uri, body: {
        'server_key': AppConstants.socialServerKey,
      }).timeout(const Duration(seconds: 6));

      if (resp.statusCode != 200) return {};
      final json = jsonDecode(resp.body);
      final incoming = json['incoming'];
      if (incoming is Map && incoming['id'] != null) {
        return {
          'call_id': int.tryParse('${incoming['id']}') ?? 0,
          'media': (incoming['media_type'] ?? '').toString(),
        };
      }
    } catch (_) {
      // ignore
    }
    return {};
  }

  String _extractGroupId(Map<dynamic, dynamic>? data) {
    if (data == null) return '';
    final raw = data['group_id'] ??
        data['groupId'] ??
        data['groupID'] ??
        data['gid'] ??
        '';
    return raw.toString();
  }

  String _groupKey(String groupId, int callId) => '$groupId|$callId';

  void _withGroupController(
    Future<void> Function(GroupCallController gc, BuildContext ctx) fn,
  ) {
    final ctx = navigatorKey.currentState?.overlay?.context ??
        navigatorKey.currentContext;
    if (ctx == null) {
      _sendGroupDebugLog('group_ctx_null_queue', {});
      _pendingActions.add((readyCtx) async {
        try {
          final gc = readyCtx.read<GroupCallController>();
          await fn(gc, readyCtx);
        } catch (_) {}
      });
      Future.microtask(() => flushPendingActions());
      return;
    }
    try {
      final gc = ctx.read<GroupCallController>();
      unawaited(fn(gc, ctx));
    } catch (_) {
      _pendingActions.add((readyCtx) async {
        try {
          final gc = readyCtx.read<GroupCallController>();
          await fn(gc, readyCtx);
        } catch (_) {}
      });
      Future.microtask(() => flushPendingActions());
    }
  }

  void _withController(
    Future<void> Function(CallController cc, BuildContext ctx) fn,
  ) {
    final ctx = navigatorKey.currentState?.overlay?.context ??
        navigatorKey.currentContext;
    if (ctx == null) {
      // Queue lại khi chưa có context (vd: accept từ CallKit trong background)
      unawaited(RemoteRtcLog.send(
        event: 'ctx_null_queue',
        details: {'src': 'withController'},
      ));
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
      unawaited(RemoteRtcLog.send(
        event: 'provider_missing_queue',
        details: {'src': 'withController'},
      ));
      _pendingActions.add((readyCtx) async {
        try {
          final cc = readyCtx.read<CallController>();
          await fn(cc, readyCtx);
        } catch (_) {}
      });
      Future.microtask(() => flushPendingActions());
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

  void _trackGroupRinging(String groupId, int callId, String mediaType,
      {String? groupName, String? systemId}) {
    if (groupId.isEmpty || callId <= 0) return;
    final key = _groupKey(groupId, callId);
    _ringingGroupMedia[key] = mediaType;
    _ringingGroupName[key] = groupName;
    if (systemId != null && systemId.isNotEmpty) {
      _groupSystemIds[key] = systemId;
    }
    _groupIncomingAt[key] = DateTime.now();

    _withGroupController((gc, _) async {
      if (gc.currentCallId != callId) {
        gc.currentCallId = callId;
        gc.status = CallStatus.ringing;
        gc.notifyListeners();
      }
    });
    Future.microtask(() => flushPendingActions());
  }

  Future<void> _handleGroupEvent({
    required String evt,
    required String systemId,
    required int serverCallId,
    required String groupId,
    required String media,
    String? groupName,
    Map<String, dynamic>? extra,
  }) async {
    final key = _groupKey(groupId, serverCallId);

    switch (evt) {
      case 'ACTION_CALL_INCOMING':
      case 'Event.actionCallIncoming':
        _trackGroupRinging(
          groupId,
          serverCallId,
          media,
          groupName: groupName,
          systemId: systemId.isNotEmpty ? systemId : null,
        );
        _sendGroupDebugLog('group_evt_incoming', {
          'evt': evt,
          'system_id': systemId,
          'call_id': serverCallId,
          'group_id': groupId,
          'media': media,
        });
        return;

      case 'ACTION_CALL_INCOMING':
      case 'Event.actionCallIncoming':
      case 'ACTION_CALL_TIMEOUT':
      case 'Event.actionCallTimeout':
      case 'ACTION_CALL_ENDED':
      case 'Event.actionCallEnded':
      case 'ACTION_CALL_DECLINE':
      case 'Event.actionCallDecline':
        {
          final key = _groupKey(groupId, serverCallId);
          if (_endedGroupKeys.contains(key) || _endedGroupIds.contains(groupId)) {
            _sendGroupDebugLog('CALLKIT_IGNORE_ENDED', {
              'evt': evt,
              'call_id': serverCallId,
              'group_id': groupId,
              'system_id': systemId,
            });
            await endGroupCall(groupId, serverCallId);
            return;
          }
          if (evt.contains('TIMEOUT') || evt.contains('DECLINE') || evt.contains('ENDED')) {
            // không cần xử lý thêm; chỉ để CallKit tự đóng
            return;
          }
          return;
        }

      case 'ACTION_CALL_ACCEPT':
      case 'Event.actionCallAccept':
      case 'ACTION_CALL_START':
      case 'Event.actionCallStart':
        {
          int cid = serverCallId;
          String gid = groupId;
          if (cid <= 0 && systemId.isNotEmpty) {
            final found = _groupSystemIds.entries.firstWhere(
              (e) => e.value.toLowerCase() == systemId.toLowerCase(),
              orElse: () => const MapEntry('', ''),
            );
            if (found.key.isNotEmpty) {
              final parts = found.key.split('|');
              if (parts.isNotEmpty) gid = parts.first;
              if (parts.length > 1) {
                cid = int.tryParse(parts.last) ?? cid;
              }
            }
          }
          if (cid <= 0 && extra != null && extra.isNotEmpty) {
            final raw =
                '${extra['call_id'] ?? extra['callId'] ?? extra['id'] ?? ''}'.trim();
            cid = int.tryParse(raw) ?? cid;
          }
          final preferred = _ringingGroupMedia[key];
          final mediaFixed =
              (media == 'audio' && preferred == 'video') ? 'video' : media;
          if (_endedGroupKeys.contains(_groupKey(gid, cid)) ||
              _endedGroupIds.contains(gid)) {
            _sendGroupDebugLog('CALLKIT_IGNORE_ENDED', {
              'evt': evt,
              'call_id': cid,
              'group_id': gid,
              'system_id': systemId,
            });
            await endGroupCall(gid, cid);
            return;
          }
          await _answerGroup(
            cid,
            gid,
            mediaFixed,
            groupName ?? _ringingGroupName[key],
          );
          _sendGroupDebugLog('group_evt_answer', {
            'evt': evt,
            'system_id': systemId,
            'call_id': cid,
            'group_id': gid,
            'media': mediaFixed,
          });
          await flushPendingActions();
          await recoverActiveCalls();
          if (systemId.isNotEmpty) {
            try {
              await FlutterCallkitIncoming.setCallConnected(systemId);
            } catch (_) {}
          }
          return;
        }

      case 'ACTION_CALL_DECLINE':
      case 'Event.actionCallDecline':
        await _endOrDeclineGroup(
          serverCallId,
          groupId,
          media,
          reason: 'decline',
        );
        if (systemId.isNotEmpty) {
          try {
            await FlutterCallkitIncoming.endCall(systemId);
          } catch (_) {}
        }
        await flushPendingActions();
        return;

      case 'ACTION_CALL_ENDED':
      case 'Event.actionCallEnded':
      case 'ACTION_CALL_TIMEOUT':
        // Bỏ qua timeout quá sớm (CallKit đôi khi tự gửi ngay sau incoming)
        final incomingAt = _groupIncomingAt[key];
        if (evt.contains('TIMEOUT') &&
            incomingAt != null &&
            DateTime.now().difference(incomingAt) <
                const Duration(seconds: 2)) {
          _sendGroupDebugLog('group_evt_timeout_ignored', {
            'call_id': serverCallId,
            'group_id': groupId,
            'media': media,
            'system_id': systemId,
            'reason': 'timeout_too_early',
          });
          return;
        }
        await _endOrDeclineGroup(
          serverCallId,
          groupId,
          media,
          reason: evt.contains('TIMEOUT') ? 'timeout' : 'end',
        );
        if (systemId.isNotEmpty) {
          try {
            await FlutterCallkitIncoming.endCall(systemId);
          } catch (_) {}
        }
        await flushPendingActions();
        return;

      default:
        return;
    }
  }
  Future<void> _answer(int serverCallId, String media, String? peerName,
      String? peerAvatar) async {
    if (serverCallId <= 0) {
      // Thử hỏi server lấy cuộc gọi ringing mới nhất
      final latest = await _fetchLatestIncomingCall();
      unawaited(RemoteRtcLog.send(
        event: 'answer_recover_inbox',
        callId: latest['call_id'] ?? 0,
        details: {'media': latest['media'], 'had_media': media},
      ));
      serverCallId = latest['call_id'] ?? 0;
      media = media.isEmpty ? (latest['media'] ?? media) : media;
    }
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

  Future<void> _answerGroup(
      int serverCallId, String groupId, String media, String? groupName) async {
    if (serverCallId <= 0 || groupId.isEmpty) {
      debugPrint('[CallKit] Skip group answer: missing call_id/group_id');
      return;
    }

    final key = 'g-ans:' + _groupKey(groupId, serverCallId);
    if (_endedGroupKeys.contains(_groupKey(groupId, serverCallId))) return;
    if (_handled.contains(key)) return;
    _handled.add(key);
    _handledGroupKeys.add(_groupKey(groupId, serverCallId));

    _withGroupController((gc, ctx) async {
      if (gc.currentCallId != serverCallId) {
        gc.currentCallId = serverCallId;
      }
      gc.currentGroupId = groupId;
      gc.status = CallStatus.ongoing;
      gc.notifyListeners();

      _openGroupCallScreen(
        ctx,
        groupId,
        media,
        serverCallId,
        groupName: groupName,
      );

      unawaited(() async {
        try {
          await gc.attachAndJoin(callId: serverCallId, groupId: groupId);
        } catch (_) {}
      }());
    });
  }

  Future<void> _endOrDeclineGroup(
    int serverCallId,
    String groupId,
    String media, {
    required String reason,
  }) async {
    if (serverCallId <= 0 || groupId.isEmpty) return;
    final key = 'g-' + reason + ':' + _groupKey(groupId, serverCallId);
    if (_handled.contains(key)) return;
    _handled.add(key);
    _endedGroupKeys.add(_groupKey(groupId, serverCallId));
    _ringingGroupMedia.remove(_groupKey(groupId, serverCallId));
    _ringingGroupName.remove(_groupKey(groupId, serverCallId));
    _groupIncomingAt.remove(_groupKey(groupId, serverCallId));

    _withGroupController((gc, ctx) async {
      try {
        if (gc.isCreator) {
          await gc.endRoom(serverCallId);
        } else {
          await gc.leaveRoom(serverCallId);
        }
      } catch (_) {}
      if (gc.currentCallId == serverCallId) {
        gc.currentCallId = null;
        gc.status = CallStatus.idle;
        gc.notifyListeners();
      }
      _popAnyCallScreenIfMounted(ctx);
    });

    _sendGroupDebugLog('group_evt_end_decline', {
      'call_id': serverCallId,
      'group_id': groupId,
      'media': media,
      'reason': reason,
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

  void _openGroupCallScreen(
    BuildContext ctx,
    String groupId,
    String mediaType,
    int callId, {
    String? groupName,
  }) {
    if (_routingToCall) return;
    _routingToCall = true;

    final route = MaterialPageRoute(
      settings: const RouteSettings(name: 'GroupCallScreen'),
      builder: (_) => GroupCallScreen(
        groupId: groupId,
        mediaType: mediaType,
        callId: callId,
        groupName: groupName,
      ),
    );

    Future<void> pushRoute() async {
      try {
        final nav = Navigator.of(ctx, rootNavigator: true);
        await nav.push(route);
      } catch (e) {
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

    pushRoute().catchError((err) {
      _sendGroupDebugLog('open_group_screen_error', {
        'call_id': callId,
        'group_id': groupId,
        'err': '$err',
      });
      Future.delayed(const Duration(milliseconds: 250), () async {
        try {
          final nav = navigatorKey.currentState;
          if (nav != null) {
            await nav.push(route);
          }
        } catch (e) {
          _sendGroupDebugLog('open_group_screen_retry_error', {
            'call_id': callId,
            'group_id': groupId,
            'err': '$e',
          });
        } finally {
          _routingToCall = false;
        }
      });
    });
  }

  Future<void> _sendGroupDebugLog(String tag, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.socialAccessToken);
      final base = AppConstants.socialBaseUrl.endsWith('/')
          ? AppConstants.socialBaseUrl.substring(
              0, AppConstants.socialBaseUrl.length - 1)
          : AppConstants.socialBaseUrl;
      final uri = Uri.parse(
        token != null && token.isNotEmpty
            ? '$base/api/webrtc_group?access_token=$token'
            : '$base/api/webrtc_group',
      );
      final body = <String, String>{
        'action': 'client_log',
        'server_key': AppConstants.socialServerKey,
        'message': tag,
        // WoWonder router vẫn nhận type, nhưng endpoint /webrtc_group đã cố định
        'type': 'webrtc_group',
        if (token != null && token.isNotEmpty) 'access_token': token,
        if (token != null && token.isNotEmpty) 's': token,
      };
      data.forEach((k, v) {
        if (v == null) return;
        body['details[$k]'] = v.toString();
      });
      await http.post(uri, body: body).timeout(const Duration(seconds: 5));
    } catch (_) {
      // best-effort logging
    }
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
      } catch (e) {
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

    pushRoute().catchError((err) {
      unawaited(RemoteRtcLog.send(
        event: 'open_call_screen_error',
        callId: callId,
        details: {'err': '$err'},
      ));
      // Retry once shortly after (cold start, context vừa ready)
      Future.delayed(const Duration(milliseconds: 250), () async {
        try {
          final nav = navigatorKey.currentState;
          if (nav != null) {
            await nav.push(route);
          }
        } catch (e) {
          unawaited(RemoteRtcLog.send(
            event: 'open_call_screen_retry_error',
            callId: callId,
            details: {'err': '$e'},
          ));
        } finally {
          _routingToCall = false;
        }
      });
    });
  }

  void _popAnyCallScreenIfMounted(BuildContext ctx) {
    try {
      // Tránh hiển thị sheet thoát app ngay sau khi pop CallScreen (callee end).
      AppExitGuard.suppressFor(const Duration(seconds: 2));
      Navigator.of(ctx, rootNavigator: true).popUntil(
        (route) {
          final name = route.settings.name;
          return name != 'CallScreen' && name != 'GroupCallScreen';
        },
      );
    } catch (_) {}
  }
}
