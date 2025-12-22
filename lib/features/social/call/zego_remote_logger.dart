import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utill/app_constants.dart';

/// Đẩy log sự kiện Zego lên server (đi qua API với server_key + access_token).
class ZegoRemoteLogger {
  ZegoRemoteLogger._();

  static final ZegoRemoteLogger I = ZegoRemoteLogger._();

  Future<void> log(String event, Map<String, dynamic> payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken =
          prefs.getString(AppConstants.socialAccessToken) ?? '';
      if (accessToken.isEmpty) return;

      final uri = Uri.parse(
        '${AppConstants.socialBaseUrl}${AppConstants.socialZegoDebugLogUri}'
        '?access_token=${Uri.encodeQueryComponent(accessToken)}',
      );

      final body = <String, String>{
        'event': event,
        'ts': DateTime.now().toIso8601String(),
        'server_key': AppConstants.socialServerKey,
      };
      payload.forEach((key, value) {
        body[key] = value?.toString() ?? '';
      });

      await http.post(uri, body: body).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Không chặn luồng nếu log thất bại.
    }
  }
}
