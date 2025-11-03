import 'package:http/http.dart' as http;
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/constants/wowonder_api.dart';

class SocialNotificationsService {
  Future<http.Response> fetchNotifications(String accessToken) async {
    final url = Uri.parse(
      '${AppConstants.socialBaseUrl}${WowonderAPI.taskNotification}?access_token=$accessToken',
    );

    final res = await http.post(url, body: {
      'server_key': AppConstants.socialServerKey,
      'type': 'get',
    });
    return res;
  }

  /// 🗑️ Xoá thông báo
  Future<http.Response> deleteNotification(
      String accessToken, String id) async {
    final url = Uri.parse(
      '${AppConstants.socialBaseUrl}${WowonderAPI.taskNotification}?access_token=$accessToken',
    );

    var request = http.MultipartRequest('POST', url)
      ..fields.addAll({
        'server_key': AppConstants.socialServerKey,
        'id': id,
        'type': 'delete',
      });

    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }
 }
