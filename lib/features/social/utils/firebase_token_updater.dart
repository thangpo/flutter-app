// lib/core/utils/firebase_token_updater.dart
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/domain/repositories/auth_repository.dart';

class FirebaseTokenUpdater {
  static Future<void> update() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(AppConstants.socialAccessToken);
      if (accessToken == null || accessToken.isEmpty) {
        log('⚠️ Missing access_token, skip update_fcm_token');
        return;
      }

      final fcmToken = await FirebaseMessaging.instance.getToken();
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
    } catch (e, st) {
      log('❌ Error updating FCM token: $e\n$st');
    }
  }
}
