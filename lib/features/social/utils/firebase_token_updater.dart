// lib/core/utils/firebase_token_updater.dart
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class FirebaseTokenUpdater {
  static Future<void> update() async {
    try {
      // 🔹 Lấy user_id lưu trong SharedPreferences (đăng nhập WoWonder)
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('social_user_id');

      // 🔹 Lấy token Firebase hiện tại
      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (userId == null || fcmToken == null) {
        log('⚠️ Missing userId or FCM token, skipping update');
        return;
      }

      // 🔹 Gửi POST request đến API update_fcm_token
      final dio = Dio();
      final resp = await dio.post(
        '${AppConstants.socialBaseUrl}/${AppConstants.socialApiUpdateFcmTokenUri}',
        data: FormData.fromMap({
          'user_id': userId,
          'firebase_device_token': fcmToken,
        }),
      );

      if (resp.statusCode == 200) {
        log('✅ FCM token updated for user_id=$userId');
      } else {
        log('⚠️ Failed to update token: ${resp.statusCode} ${resp.data}');
      }
    } catch (e) {
      log('❌ Error updating FCM token: $e');
    }
  }
}
