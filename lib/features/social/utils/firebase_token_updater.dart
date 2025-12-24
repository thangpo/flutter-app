// lib/core/utils/firebase_token_updater.dart
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/call/zpns_push_registrar.dart';

class FirebaseTokenUpdater {
  static Future<void> update() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(AppConstants.socialAccessToken);
      if (accessToken == null || accessToken.isEmpty) {
        log('⚠️ Missing access_token, skip update_fcm_token');
        return;
      }

      final fcmToken = await _getFcmTokenSafe();
      if (fcmToken == null || fcmToken.isEmpty) {
        log('⚠️ Missing FCM token, skip');
        return;
      }
      final url = Uri.parse(
        '${AppConstants.socialBaseUrl}/${AppConstants.socialApiUpdateFcmTokenUri}?access_token=$accessToken',
      );

      // ✅ multipart/form-data như curl --form
      final req = http.MultipartRequest('POST', url)
        ..fields['server_key'] = AppConstants.socialServerKey
        ..fields['firebase_device_token'] = fcmToken;

      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();
      log('update_fcm_token => ${streamed.statusCode}');
      log('response => $body');

      // Sau khi có FCM token + social access_token, đăng ký push ZPNs (offline call).
      // Không chờ kết quả để tránh chặn luồng.
      // ignore: discarded_futures
      ZpnsPushRegistrar.registerIfNeeded();
    } catch (e, st) {
      log('❌ Error updating FCM token: $e\n$st');
    }
  }

  static Future<String?> _getFcmTokenSafe() async {
    final messaging = FirebaseMessaging.instance;
    if (Platform.isIOS) {
      // iOS cần APNS token trước khi có FCM token
      final apnsToken = await messaging.getAPNSToken();
      if (apnsToken == null) {
        log('⚠️ APNS token chưa sẵn sàng, đợi onTokenRefresh...');
        try {
          // onTokenRefresh sẽ bắn ngay khi APNS/FCM sẵn sàng
          return await messaging.onTokenRefresh.first
              .timeout(const Duration(seconds: 8));
        } catch (e) {
          log('⚠️ Chưa lấy được token sau khi chờ: $e');
          return null;
        }
      }
    }

    try {
      return await messaging.getToken();
    } catch (e) {
      log('⚠️ Lỗi lấy FCM token: $e');
      return null;
    }
  }
}
