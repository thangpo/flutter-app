// lib/features/social/push/call_invite_stream_listener.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter_sixvalley_ecommerce/helper/app_globals.dart'
    show navigatorKey;

import '../controllers/call_controller.dart';
import '../controllers/group_call_controller.dart';
import '../domain/models/call_invite.dart';
import '../fcm/fcm_chat_handler.dart';
import '../screens/incoming_call_screen.dart';
import '../screens/group_call_screen.dart';
import '../screens/group_incoming_call_screen.dart';

/// Listen FCM foreground để mở UI nghe/từ chối ngay (1-1 & group).
class CallInviteForegroundListener {
  CallInviteForegroundListener._();

  static StreamSubscription? _chatSub;
  static StreamSubscription? _fcmSub;
  static final Set<int> _handledCallIds = <int>{};
  static final Set<String> _handledGroupCalls = <String>{}; // callId|groupId
  static bool _routing = false;

  static void _log(String tag, dynamic data) {
    debugPrint('[CALL-LISTENER][$tag] ${data is String ? data : jsonEncode(data)}');
  }

  /// Gọi sau khi navigatorKey + Providers sẵn (thường sau MultiProvider).
  static void start() {
    _chatSub ??= FcmChatHandler.messagesStream.listen(_handleChatEvent);
    _fcmSub ??= FirebaseMessaging.onMessage.listen(_handleFcmDirect);
  }

  // =====================================================
  // ============== 1. CHAT STREAM (socket) ==============
  // =====================================================
  static Future<void> _handleChatEvent(FcmChatEvent evt) async {
    final raw = evt.text ?? '';
    if (raw.isEmpty) return;

    final normalized = _normalizeCallPayload(raw);
    if (!normalized.contains('call_invite')) return;

    // Thử bắt group call từ payload chat (call_invite_group hoặc có group_id)
    final grpPayload = _parseGroupInviteFromText(normalized, const {});
    if (grpPayload != null) {
      _log('chat_group_payload', grpPayload);
      _openGroupFromData(grpPayload);
      // fallback: nếu thiếu call_id, thử inbox group
      final gid = _extractGroupId(grpPayload);
      if ((grpPayload['call_id'] ?? 0) == 0 && gid.isNotEmpty) {
        _probeGroupInbox(gid);
      }
      return;
    }

    final inv =
        CallInvite.tryParse(normalized) ?? _parseLooseCallInvite(normalized);
    if (inv == null || inv.isExpired()) return;
    if (!_handledCallIds.add(inv.callId)) return;

    _openIncoming(inv);
  }

  // =====================================================
  // ============== 2. FCM DIRECT (onMessage) ============
  // =====================================================
  static Future<void> _handleFcmDirect(RemoteMessage msg) async {
    final data = msg.data;
    if (data.isEmpty) return;

    final type = (data['type'] ?? '').toString();
    final isGroupFlag = _isTrue(data['is_group']);

    final raw = data['text']?.toString() ?? '';
    _log('fcm_onMessage', {'type': type, 'is_group': isGroupFlag, 'data': data, 'text': raw});

    final callerName =
        data['sender_name']?.toString() ?? data['caller_name']?.toString();
    final callerAvatar =
        data['sender_avatar']?.toString() ?? data['caller_avatar']?.toString();

    // ----------- GROUP CALL -----------
    if (data.containsKey('group_id') &&
        (type == 'call_invite_group' ||
            type == 'call_invite' || // PHP backend đang gửi type=call_invite + is_group
            isGroupFlag ||
            data.containsKey('call_id'))) {
      final gid = _extractGroupId(data);
      final cid = int.tryParse('${data['call_id'] ?? ''}') ?? 0;
      _log('fcm_group_detected', {'gid': gid, 'cid': cid, 'type': type});
      if (cid <= 0 && gid.isNotEmpty) {
        // fallback: call_id missing -> ping inbox to fetch latest ringing call
        await _probeGroupInbox(gid);
      } else {
        _openGroupFromData(data);
      }
      return;
    }
    // type=chat_message nhưng text chứa payload group call
    if (raw.isNotEmpty) {
      final normalized = _normalizeCallPayload(raw);
      final groupPayload = _parseGroupInviteFromText(normalized, data);
      if (groupPayload != null) {
        _openGroupFromData(groupPayload);
        // fallback: nếu thiếu call_id -> ping inbox group để lấy call hiện tại
        final gid = _extractGroupId(groupPayload);
        if ((groupPayload['call_id'] ?? 0) == 0 && gid.isNotEmpty) {
          _probeGroupInbox(gid);
        }
        return;
      }
    }

    // ----------- 1-1 CALL -----------

    // Wo_RegisterMessage gửi type=chat_message nhưng text là payload call
    if (raw.isNotEmpty) {
      final normalized = _normalizeCallPayload(raw);
      if (normalized.contains('call_invite')) {
        final inv =
            CallInvite.tryParse(normalized) ?? _parseLooseCallInvite(normalized);
        if (inv != null && !inv.isExpired()) {
          if (_handledCallIds.add(inv.callId)) {
            _openIncoming(
              inv,
              callerName: callerName,
              callerAvatar: callerAvatar,
            );
          }
          return;
        }
      }
    }

    // Fallback: type=call_invite + call_id + media ở root
    final mediaRaw = _extractMedia(data);
    final looksLikeCallInvite = type == 'call_invite' ||
        (data.containsKey('call_id') &&
            mediaRaw != null &&
            !data.containsKey('group_id'));
    if (!looksLikeCallInvite) return;

    final callId = int.tryParse('${data['call_id'] ?? ''}') ?? 0;
    if (callId <= 0) return;
    final ts = int.tryParse('${data['ts'] ?? 0}') ??
        DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final inv = CallInvite(
      callId: callId,
      media: mediaRaw ?? 'audio',
      issuedAt: DateTime.fromMillisecondsSinceEpoch(ts * 1000),
    );
    if (inv.isExpired()) return;
    if (!_handledCallIds.add(inv.callId)) return;

    _openIncoming(
      inv,
      callerName: callerName,
      callerAvatar: callerAvatar,
    );
  }

  // =====================================================
  // ============== PARSER PAYLOAD CALL (TEXT) ===========
  // =====================================================

  /// Text kiểu:
  ///   {"type":"call_invite","call_id":173,"media":"video","ts":1763955418}
  /// hoặc tương tự -> rút ra call_id, media, ts bằng cách cắt chuỗi.
  static CallInvite? _parseLooseCallInvite(String raw) {
    if (!raw.contains('call_invite')) return null;

    String? callIdStr = _extractValue(raw, 'call_id');
    String? mediaStr = _extractValue(raw, 'media') ??
        _extractValue(raw, 'media_type') ??
        _extractValue(raw, 'call_type') ??
        _extractValue(raw, 'type_two') ??
        _extractValue(raw, 'call_media');
    String? tsStr = _extractValue(raw, 'ts');

    final callId = int.tryParse(callIdStr ?? '');
    if (callId == null || callId <= 0) return null;

    final media = (mediaStr == 'video') ? 'video' : 'audio';
    final ts = int.tryParse(tsStr ?? '');
    final issuedAt = (ts != null && ts > 0)
        ? DateTime.fromMillisecondsSinceEpoch(ts * 1000)
        : DateTime.now();

    return CallInvite(
      callId: callId,
      media: media,
      issuedAt: issuedAt,
    );
  }

  /// Cắt value của 1 key trong chuỗi kiểu {'key':'value', "key2":123}
  static String? _extractValue(String raw, String key) {
    // tìm 'key' hoặc "key"
    int idx = raw.indexOf("'$key'");
    if (idx == -1) {
      idx = raw.indexOf('"$key"');
      if (idx == -1) return null;
    }

    int colon = raw.indexOf(':', idx);
    if (colon == -1) return null;

    // nhảy qua dấu ':' và khoảng trắng
    int i = colon + 1;
    while (i < raw.length &&
        (raw[i] == ' ' || raw[i] == '\t' || raw[i] == '\n' || raw[i] == '\r')) {
      i++;
    }
    if (i >= raw.length) return null;

    // Nếu có nháy -> lấy từ sau nháy đến nháy tiếp theo
    if (raw[i] == "'" || raw[i] == '"') {
      final quote = raw[i];
      final start = i + 1;
      final end = raw.indexOf(quote, start);
      if (end == -1) return null;
      return raw.substring(start, end);
    }

    // Không có nháy -> đọc đến dấu phẩy, đóng ngoặc hoặc space
    final start = i;
    int end = start;
    while (end < raw.length &&
        raw[end] != ',' &&
        raw[end] != '}' &&
        raw[end] != ' ' &&
        raw[end] != '\t' &&
        raw[end] != '\n' &&
        raw[end] != '\r') {
      end++;
    }
    if (end <= start) return null;
    return raw.substring(start, end);
  }

  /// Chuẩn hóa payload call_invite (HTML-escaped, backslash-escaped)
  static String _normalizeCallPayload(String raw) {
    var s = raw;
    s = s.replaceAll('\\&quot;', '"').replaceAll('&quot;', '"');
    s = s.replaceAll('&amp;', '&');
    return s;
  }

  /// Chuẩn hóa media từ payload (media | call_type | type_two | call_media)
  static String? _extractMedia(Map<String, dynamic> data) {
    final raw = (data['media'] ??
            data['media_type'] ?? // backend đôi khi dùng media_type
            data['call_type'] ??
            data['type_two'] ??
            data['call_media'])
        ?.toString()
        .toLowerCase();
    if (raw == 'video' || raw == 'audio') return raw;
    return null;
  }

  static String _extractGroupId(Map<String, dynamic> data) {
    final v = data['group_id'] ??
        data['groupId'] ??
        data['groupID'] ??
        data['gid'];
    return (v ?? '').toString();
  }

  static bool _isTrue(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes';
  }

  /// Khi payload group không có call_id, thử ping inbox để lấy call mới nhất của group
  static Future<void> _probeGroupInbox(String groupId) async {
    if (_routing) return;
    final nav = navigatorKey.currentState;
    final ctx = nav?.overlay?.context ?? navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    try {
      final gc = ctx.read<GroupCallController>();
      var handled = false;
      _log('probe_inbox_start', groupId);
      // Gắn onIncoming tạm thời để mở UI
      gc.onIncoming = (call) {
        handled = true;
        final cid = int.tryParse('${call['call_id'] ?? call['id'] ?? ''}') ?? 0;
        if (cid <= 0) return;
        gc.stopWatchingInbox();
        gc.onIncoming = null;
        _log('probe_inbox_hit', {'gid': groupId, 'cid': cid, 'call': call});
        _openGroupFromData({
          'call_id': cid,
          'group_id': groupId,
          'media': call['media'] ?? 'audio',
          'group_name': call['group_name'] ?? call['name'],
        });
      };
      gc.watchGroupInbox(groupId, autoOpen: false);
      await gc.forceCheckInbox();
      // Cleanup watchdog để tránh polling mãi nếu không có call
      Future.delayed(const Duration(seconds: 10), () {
        if (!handled) {
          _log('probe_inbox_timeout', groupId);
          gc.stopWatchingInbox();
          gc.onIncoming = null;
        }
      });
    } catch (_) {
      // ignore
    }
  }

  /// Parse group invite từ text (JSON hoặc loang) + fallback data map
  static Map<String, dynamic>? _parseGroupInviteFromText(
      String text, Map<String, dynamic> data) {
    Map<String, dynamic>? m;
    try {
      if (text.trim().startsWith('{') && text.trim().endsWith('}')) {
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) {
          m = decoded;
        } else if (decoded is Map) {
            m = decoded.map((k, v) => MapEntry(k.toString(), v));
        }
      }
    } catch (_) {}

    m ??= {};
    // merge data root để lấy group_name/call_type nếu text thiếu
    m.addAll(data);

    final callId = int.tryParse('${m['call_id'] ?? m['id'] ?? ''}') ?? 0;
    final groupId = _extractGroupId(m);
    if (groupId.isEmpty) return null;

    final media = _extractMedia(m) ?? 'audio';
    final groupName = m['group_name']?.toString();

    return {
      'call_id': callId,
      'group_id': groupId,
      'media': media,
      if (groupName != null) 'group_name': groupName,
    };
  }

  // =====================================================
  // ================= GROUP CALL HELPERS ================
  // =====================================================
  static void _openGroupFromData(Map<String, dynamic> data) {
    final callId = int.tryParse('${data['call_id'] ?? ''}') ?? 0;
    final groupId = '${data['group_id'] ?? ''}';
    if (groupId.isEmpty) return;
    if (callId <= 0) {
      // fallback: missing call_id -> probe inbox to fetch active call
      _log('open_group_missing_call', data);
      _probeGroupInbox(groupId);
      return;
    }

    final media = _extractMedia(data) ?? 'audio';
    final name = data['group_name']?.toString();

    final key = '$callId|$groupId';
    if (!_handledGroupCalls.add(key)) return;

    _log('open_group_ui', {'call_id': callId, 'group_id': groupId, 'media': media});

    _openGroupIncoming(
      callId: callId,
      groupId: groupId,
      media: media,
      groupName: name,
    );
  }

  // =====================================================
  // ================= OPEN UI: 1-1 ======================
  // =====================================================
  static void _openIncoming(
    CallInvite inv, {
    String? callerName,
    String? callerAvatar,
  }) {
    if (_routing) return;

    final nav = navigatorKey.currentState;
    final ctx = nav?.overlay?.context ?? navigatorKey.currentContext;

    if (nav == null || ctx == null || !ctx.mounted) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openIncoming(
          inv,
          callerName: callerName,
          callerAvatar: callerAvatar,
        ),
      );
      return;
    }

    _routing = true;

    try {
      final cc = ctx.read<CallController>();
      // Bỏ qua nếu đã được CallKit / logic khác attach & set trạng thái != ringing (đã nhận hoặc kết thúc)
      if (cc.isCallHandled(inv.callId) ||
          (cc.activeCallId == inv.callId && cc.callStatus != 'ringing')) {
        _routing = false;
        return;
      }
      cc.attachCall(
        callId: inv.callId,
        mediaType: inv.mediaType,
        initialStatus: 'ringing',
      );
    } catch (_) {}

    nav
        .push(
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          callId: inv.callId,
          mediaType: inv.mediaType,
          callerName: callerName,
          callerAvatar: callerAvatar,
        ),
      ),
    )
        .whenComplete(() {
      _routing = false;
    });
  }

  // =====================================================
  // ================= OPEN UI: GROUP ====================
  // =====================================================
  static void _openGroupIncoming({
    required int callId,
    required String groupId,
    required String media,
    String? groupName,
  }) {
    if (_routing) return;

    final nav = navigatorKey.currentState;
    final ctx = nav?.overlay?.context ?? navigatorKey.currentContext;

    if (nav == null || ctx == null || !ctx.mounted) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openGroupIncoming(
          callId: callId,
          groupId: groupId,
          media: media,
          groupName: groupName,
        ),
      );
      return;
    }

    _routing = true;

    try {
      final gc = ctx.read<GroupCallController>();
      gc.currentCallId = callId;
      gc.status = CallStatus.ringing;
    } catch (_) {}

    nav
        .push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => GroupIncomingCallScreen(
          groupId: groupId,
          callId: callId,
          media: media,
          groupName: groupName,
        ),
      ),
    )
        .whenComplete(() {
      _routing = false;
    });
  }
}
