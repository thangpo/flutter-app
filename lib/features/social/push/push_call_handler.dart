// lib/features/social/push/push_call_handler.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart' show navigatorKey;

import '../screens/incoming_call_screen.dart';
import '../controllers/call_controller.dart';

/// ===============================
///  SocialCallPushHandler
///  - Xử lý FCM data `type=call_invite`
///  - Foreground: nhảy thẳng IncomingCallScreen
///  - Background/terminated: hiện full-screen notif (tap → mở screen)
/// ===============================
class SocialCallPushHandler {
  SocialCallPushHandler._();
  static final SocialCallPushHandler I = SocialCallPushHandler._();

  final FlutterLocalNotificationsPlugin _lnp =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'calls';
  static const String _channelName = 'Incoming Calls';
  static const String _channelDesc = 'Full-screen incoming call notifications';

  /// Khởi tạo Local Notifications + callback click/Actions
  Future<void> initLocalNotifications() async {
    // Android init settings
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS: không cần full-screen (CallKit là case khác)
    const iosInit = DarwinInitializationSettings();

    await _lnp.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotifResponse,
      onDidReceiveBackgroundNotificationResponse: _onNotifResponseBackground,
    );

    // Tạo call channel với fullScreenIntent
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await _lnp
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Đăng ký lắng nghe FCM khi app foreground.
  /// Gọi hàm này sau khi Firebase.init xong (trong main.dart).
  void bindForegroundListener() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  /// Foreground: nhận call_invite → attachCall + mở IncomingCallScreen
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final data = message.data;
    if (data['type'] != 'call_invite') return;

    final callId = int.tryParse('${data['call_id']}') ?? 0;
    if (callId <= 0) return;

    final media = (data['media'] == 'video') ? 'video' : 'audio';
    final callerName = data['caller_name'];
    final callerAvatar = data['caller_avatar'];

    // Nếu có context hiện tại → điều hướng ngay
    final ctx = navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      try {
        ctx.read<CallController>().attachCall(
              callId: callId,
              mediaType: media,
              initialStatus: 'ringing',
            );
      } catch (_) {}
      _openIncomingScreen(
        callId: callId,
        media: media,
        callerName: callerName,
        callerAvatar: callerAvatar,
      );
      return;
    }

    // Fallback: show full-screen notif
    await showIncomingCallNotification(data);
  }

  /// Hiển thị full-screen notification (Android)
  Future<void> showIncomingCallNotification(Map<String, dynamic> data) async {
    final callId =
        int.tryParse('${data['call_id']}') ?? DateTime.now().millisecond;
    final callerName = (data['caller_name'] ?? 'Cuộc gọi đến').toString();

    final payload = jsonEncode(data);

    final android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      usesChronometer: true,
      actions: const [
        // Sau (hợp lệ với v19.5.0)
        AndroidNotificationAction(
          'accept_call',
          'Nghe',
          // gợi ý: mở UI app khi bấm
          showsUserInterface: true,
          cancelNotification: true,
        ),

        AndroidNotificationAction(
          'decline_call',
          'Từ chối',
          // “Destructive” chỉ là style, Android plugin không có flag này.
          // Giữ hành vi: bấm là tắt notif.
          cancelNotification: true,
        ),
      ],
    );

    const ios = DarwinNotificationDetails(
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _lnp.show(
      callId,
      'Cuộc gọi đến',
      callerName,
      NotificationDetails(android: android, iOS: ios),
      payload: payload,
    );
  }

  /// Khi user TAP notif hoặc bấm action (foreground)
  Future<void> _onNotifResponse(NotificationResponse resp) async {
    final payloadStr = resp.payload ?? '{}';
    Map<String, dynamic> data;
    try {
      data = jsonDecode(payloadStr) as Map<String, dynamic>;
    } catch (_) {
      data = {};
    }
    await _handleNotificationAction(resp.actionId, data);
  }

  /// Khi user TAP notif hoặc bấm action (background isolate)
  @pragma('vm:entry-point')
  static Future<void> _onNotifResponseBackground(
      NotificationResponse resp) async {
    // background isolate: init Firebase tối thiểu để tránh crash
    try {
      await Firebase.initializeApp();
    } catch (_) {}
    final handler = SocialCallPushHandler.I;
    final payloadStr = resp.payload ?? '{}';
    Map<String, dynamic> data;
    try {
      data = jsonDecode(payloadStr) as Map<String, dynamic>;
    } catch (_) {
      data = {};
    }
    await handler._handleNotificationAction(resp.actionId, data);
  }

  /// Xử lý action ACCEPT/DECLINE hoặc tap body
  Future<void> _handleNotificationAction(
      String? actionId, Map<String, dynamic> data) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final callId = int.tryParse('${data['call_id']}') ?? 0;
    final media = (data['media'] == 'video') ? 'video' : 'audio';
    final callerName = data['caller_name'];
    final callerAvatar = data['caller_avatar'];

    // Mở app nếu đang background/terminated
    // (trên Android, plugin đã đưa app foreground khi tap notif/action)
    final ctx = navigatorKey.currentContext;

    if (ctx != null && ctx.mounted) {
      final cc = ctx.read<CallController>();
      try {
        cc.attachCall(callId: callId, mediaType: media);
      } catch (_) {}

      if (actionId == 'DECLINE') {
        try {
          await cc.action('decline');
        } catch (_) {}
        return;
      }

      // ACCEPT hoặc tap vào body
      _openIncomingScreen(
        callId: callId,
        media: media,
        callerName: callerName,
        callerAvatar: callerAvatar,
      );
    } else {
      // Không có context: chỉ đẩy screen sau một frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx2 = navigatorKey.currentContext;
        if (ctx2 == null || !ctx2.mounted) return;
        final cc = ctx2.read<CallController>();
        try {
          cc.attachCall(callId: callId, mediaType: media);
        } catch (_) {}

        if (actionId == 'DECLINE') {
          cc.action('decline');
          return;
        }
        _openIncomingScreen(
          callId: callId,
          media: media,
          callerName: callerName,
          callerAvatar: callerAvatar,
        );
      });
    }
  }

  void _openIncomingScreen({
    required int callId,
    required String media,
    String? callerName,
    String? callerAvatar,
  }) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          callId: callId,
          mediaType: media,
          callerName: callerName,
          callerAvatar: callerAvatar,
        ),
      ),
    );
  }
}

/// ===============================
///  FCM background handler
///  (bắt data-only khi app background/terminated)
/// ===============================
@pragma('vm:entry-point')
Future<void> socialCallFirebaseBgHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  final data = message.data;
  if (data['type'] != 'call_invite') return;

  // Không điều hướng ở background isolate → chỉ hiện full-screen notif
  await SocialCallPushHandler.I.showIncomingCallNotification(data);
}
