// lib/features/social/fcm/fcm_chat_handler.dart
import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';

/// ------------------------------------------------------------
/// REALTIME CHAT HANDLER for WoWonder 1-1 chat
/// ------------------------------------------------------------
/// - Không dùng polling
/// - Chỉ nhận FCM của tin nhắn mới
/// - ChatScreen lắng nghe stream để reload tin nhắn
/// ------------------------------------------------------------

class FcmChatEvent {
  final String peerId; // người gửi / người chat với mình
  final String messageId; // id tin nhắn mới
  final String? text; // nội dung tin
  final String? rawData; // toàn payload

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

      // Chỉ xử lý loại tin WoWonder gửi khi chat 1-1
      // Thường có `message_id`, `from_id`, `to_id`
      if (!data.containsKey("from_id")) return;
      if (!data.containsKey("message_id")) return;

      final fromId = data["from_id"].toString();
      final msgId = data["message_id"].toString();
      final text = data["text"]?.toString();

      final evt = FcmChatEvent(
        peerId: fromId,
        messageId: msgId,
        text: text,
        rawData: jsonEncode(data),
      );

      _controller.add(evt);
    } catch (e) {
      print("FCM Chat parse error: $e");
    }
  }
}
