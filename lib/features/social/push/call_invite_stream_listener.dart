// lib/features/social/push/call_invite_stream_listener.dart
import 'dart:async';

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

/// ===========================================
/// CallInviteForegroundListener
/// - Lắng nghe:
///   1) Stream chat (FcmChatHandler.messagesStream)
///   2) FirebaseMessaging.onMessage (direct)
/// - Khi detect call_invite:
///   → attachCall + mở IncomingCallScreen / GroupCallScreen
/// - Có cơ chế chống trùng (callId, groupId)
///   để tránh mở UI 2 lần.
/// ===========================================
class CallInviteForegroundListener {
  CallInviteForegroundListener._();

  static StreamSubscription? _chatSub;
  static StreamSubscription? _fcmSub;

  static final Set<int> _handledCallIds = <int>{};
  static final Set<String> _handledGroupCalls =
      <String>{}; // key: callId|groupId

  static bool _routing = false;

  /// Gọi hàm này sau khi app đã khởi tạo navigatorKey + Provider
  /// (thường sau MultiProvider trong main.dart)
  static void start() {
    // 1) Chat socket / custom FCM stream (tin nhắn chat)
    if (_chatSub == null) {
      _chatSub = FcmChatHandler.messagesStream.listen(_handleChatEvent);
    }

    // 2) FCM trực tiếp (push của FirebaseMessaging.onMessage)
    if (_fcmSub == null) {
      _fcmSub = FirebaseMessaging.onMessage.listen(_handleFcmDirect);
    }
  }

  // =====================================================
  // ============== 1. CHAT STREAM (socket) ==============
  // =====================================================
  static Future<void> _handleChatEvent(FcmChatEvent evt) async {
    final raw = evt.text ?? '';
    if (raw.isEmpty) return;

    // tin chat thường thì bỏ, chỉ xử lý khi có call_invite
    if (!raw.contains('call_invite')) return;

    final inv = _parseLooseCallInvite(raw);
    if (inv == null || inv.isExpired()) return;

    if (!_handledCallIds.add(inv.callId)) return;

    _openIncoming(inv);
  }

  // =====================================================
  // ============== 2. FCM TRỰC TIẾP (onMessage) =========
  // =====================================================
  static Future<void> _handleFcmDirect(RemoteMessage msg) async {
    final data = msg.data;
    if (data.isEmpty) return;

    final type = (data['type'] ?? '').toString();

    // ----------- GROUP CALL -----------
    final hasGroup = data.containsKey('group_id');
    if (hasGroup &&
        (type == 'call_invite_group' || data.containsKey('call_id'))) {
      _openGroupFromData(data);
      return;
    }

    // ----------- 1-1 CALL -----------
    final raw = data['text']?.toString() ?? '';
    final callerName =
        data['sender_name']?.toString() ?? data['caller_name']?.toString();
    final callerAvatar =
        data['sender_avatar']?.toString() ?? data['caller_avatar']?.toString();

    // Trường hợp Wo_RegisterMessage gửi type = chat_message
    // nhưng text là payload call
    if (raw.isNotEmpty && raw.contains('call_invite')) {
      final inv = _parseLooseCallInvite(raw);
      if (inv != null && !inv.isExpired()) {
        if (!_handledCallIds.add(inv.callId)) return;
        _openIncoming(
          inv,
          callerName: callerName,
          callerAvatar: callerAvatar,
        );
        return;
      }
    }

    // Fallback: nếu server gửi type = call_invite + call_id + media ở root
    final mediaRaw = _extractMedia(data);
    final looksLikeCallInvite = type == 'call_invite' ||
        (data.containsKey('call_id') && mediaRaw != null && !data.containsKey('group_id'));
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
  // ============== PARSER PAYLOAD CALL (TỪ TEXT) ========
  // =====================================================

  /// Text kiểu:
  ///   {'type':'call_invite','call_id':'173','media':'video','ts':1763955418}
  /// hoặc tương tự -> rút ra call_id, media, ts bằng cách cắt chuỗi.
  static CallInvite? _parseLooseCallInvite(String raw) {
    if (!raw.contains('call_invite')) return null;

    String? callIdStr = _extractValue(raw, 'call_id');
    String? mediaStr = _extractValue(raw, 'media');
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
    // Tìm 'key' hoặc "key"
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

  /// Chuẩn hóa media từ payload (media | call_type | type_two | call_media)
  static String? _extractMedia(Map<String, dynamic> data) {
    final raw = (data['media'] ??
            data['call_type'] ??
            data['type_two'] ??
            data['call_media'])
        ?.toString()
        .toLowerCase();
    if (raw == 'video' || raw == 'audio') return raw;
    return null;
  }

  // =====================================================
  // ================= GROUP CALL HELPERS ================
  // =====================================================
  static void _openGroupFromData(Map<String, dynamic> data) {
    final callId = int.tryParse('${data['call_id'] ?? ''}') ?? 0;
    final groupId = '${data['group_id'] ?? ''}';
    if (callId <= 0 || groupId.isEmpty) return;

    final media = _extractMedia(data) ?? 'audio';
    final name = data['group_name']?.toString();

    final key = '$callId|$groupId';
    if (!_handledGroupCalls.add(key)) return;

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
      // navigator chưa sẵn sàng -> đợi frame sau
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
      ctx.read<CallController>().attachCall(
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
      // Warm up controller state if needed
      final gc = ctx.read<GroupCallController>();
      gc.currentCallId = callId;
      gc.status = CallStatus.ringing;
    } catch (_) {}

    nav
        .push(
      MaterialPageRoute(
        builder: (_) => GroupCallScreen(
          groupId: groupId,
          mediaType: media,
          callId: callId,
          groupName: groupName,
        ),
      ),
    )
        .whenComplete(() {
      _routing = false;
    });
  }
}
