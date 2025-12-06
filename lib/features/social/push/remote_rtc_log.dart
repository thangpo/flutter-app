// lib/features/social/push/remote_rtc_log.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

/// Gửi log về server (webrtc.php?type=client_log) khi không xem được console TestFlight.
class RemoteRtcLog {
  static Future<void> send({
    required String event,
    int? callId,
    Map<String, dynamic>? details,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.socialAccessToken) ?? '';
      if (token.isEmpty) return;

      // API routing chuẩn: /api/webrtc?access_token=... ; type=client_log trong form-data
      final uri = Uri.parse(
          '${AppConstants.socialBaseUrl}/api/webrtc?access_token=$token');

      // Gửi kiểu multipart/form-data giống pushkit.php
      final req = http.MultipartRequest('POST', uri)
        ..fields['server_key'] = AppConstants.socialServerKey
        ..fields['type'] = 'client_log'
        ..fields['call_id'] = callId?.toString() ?? ''
        ..fields['event'] = event
        ..fields['details'] =
            jsonEncode(details ?? const <String, dynamic>{});

      await req.send();
    } catch (_) {
      // swallow errors to avoid breaking UX
    }
  }
}
