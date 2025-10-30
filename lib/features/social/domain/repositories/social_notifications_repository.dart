import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class SocialNotificationsRepository {
  Future<List<Map<String, dynamic>>> getNotifications(
      String accessToken) async {
    try {
      if (kDebugMode) debugPrint('🔑 Access Token: $accessToken');

      final url = Uri.parse(
        '${AppConstants.socialBaseUrl}/api/notifications?access_token=$accessToken',
      );

      final request = http.MultipartRequest('POST', url)
        ..fields.addAll({
          'server_key': AppConstants.socialServerKey,
          'type': 'get',
        });

      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      final data = jsonDecode(res.body);

      // ✅ Chuyển đổi về int an toàn
      final status = data['api_status'].toString();
      if (status != '200') {
        if (kDebugMode) {
          debugPrint('⚠️ API Error: ${data['errors'] ?? 'Unknown'}');
        }
        return [];
      }

      // ✅ Lấy danh sách thông báo (nếu có)
      final notifications = data['notifications'];
      if (notifications is List) {
        return List<Map<String, dynamic>>.from(notifications);
      } else {
        return [];
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('❌ getNotifications() failed: $e\n$stack');
      }
      return [];
    }
  }

  Future<Map<String, dynamic>?> deleteNotification(
      String accessToken, String id) async {
    try {
      final url = Uri.parse(
        '${AppConstants.socialBaseUrl}/api/notifications?access_token=$accessToken',
      );

      final request = http.MultipartRequest('POST', url)
        ..fields.addAll({
          'server_key': AppConstants.socialServerKey,
          'id': id,
          'type': 'delete',
        });

      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        debugPrint('🗑 Delete Status: ${res.statusCode}');
        debugPrint('🗑 Delete Body: ${res.body}');
      }

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('❌ deleteNotification() failed: $e\n$stack');
      }
      return null; // ✅ đúng kiểu trả về Map<String, dynamic>?
    }
  }
}
