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

      final uri = Uri.parse(
          '${AppConstants.socialBaseUrl}/api/v2/endpoints/webrtc.php?type=client_log');
      await http.post(uri, body: {
        'server_key': AppConstants.socialServerKey,
        'access_token': token,
        'call_id': callId?.toString() ?? '',
        'event': event,
        'details': jsonEncode(details ?? const <String, dynamic>{}),
      });
    } catch (_) {
      // swallow errors to avoid breaking UX
    }
  }
}
