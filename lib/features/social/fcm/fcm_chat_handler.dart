// lib/features/social/fcm/fcm_chat_handler.dart
import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';

/// ------------------------------------------------------------
/// REALTIME CHAT HANDLER for WoWonder 1-1 chat
/// ------------------------------------------------------------
/// - Không dùng polling
/// - Chỉ nhận FCM của tin nhắn mới / event chat
/// - ChatScreen lắng nghe stream để reload tin nhắn
/// ------------------------------------------------------------

class FcmChatEvent {
  /// Id người đối thoại (thường là sender_id)
  final String peerId;

  /// Id tin nhắn / event mới
  final String messageId;

  /// Nội dung text (nếu có) – có thể là JSON (call_invite)
  final String? text;

  /// Toàn bộ payload data dạng JSON string
  final String? rawData;

  FcmChatEvent({
    required this.peerId,
    required this.messageId,
    this.text,
    this.rawData,
  });
}

class FcmChatHandler {
  /// STREAM phát realtime event
  static final StreamController<FcmChatEvent> _controller =
      StreamController<FcmChatEvent>.broadcast();

  static Stream<FcmChatEvent> get messagesStream => _controller.stream;

  /// ------------------------------------------------------------
  /// GỌI TRONG main.dart SAU khi Firebase.initializeApp()
  /// ------------------------------------------------------------
  static void initialize() {
    // 1. App đang mở → onMessage
    FirebaseMessaging.onMessage.listen((m) {
      _tryHandle(m, source: "onMessage");
    });

    // 2. App background → mở từ noti
    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      _tryHandle(m, source: "onMessageOpenedApp");
    });

    // 3. App bị kill → mở lên
    FirebaseMessaging.instance.getInitialMessage().then((m) {
      if (m != null) {
        _tryHandle(m, source: "getInitialMessage");
      }
    });
  }

  /// ------------------------------------------------------------
  /// Parse FCM message và bắn event realtime
  /// ------------------------------------------------------------
  static void _tryHandle(RemoteMessage msg, {String? source}) {
    try {
      final data = msg.data;
      if (data.isEmpty) return;

      // Debug (nếu cần)
      // print("🔥 [FcmChatHandler][$source] data = $data");

      // Hỗ trợ cả key cũ (from_id) lẫn key mới (sender_id)
      final senderRaw = (data['sender_id'] ?? data['from_id']);
      if (senderRaw == null || senderRaw.toString().isEmpty) {
        return;
      }
      final peerId = senderRaw.toString();

      // Lấy message_id (bắt buộc)
      final msgIdRaw = (data['message_id'] ?? data['id']);
      if (msgIdRaw == null || msgIdRaw.toString().isEmpty) {
        return;
      }
      final messageId = msgIdRaw.toString();

      // Text có thể là nội dung chat, hoặc JSON call_invite
      final text = data['text']?.toString();

      final evt = FcmChatEvent(
        peerId: peerId,
        messageId: messageId,
        text: text,
        rawData: jsonEncode(data),
      );

      _controller.add(evt);
    } catch (e) {
      print("❌ FCM Chat parse error: $e");
    }
  }
}
