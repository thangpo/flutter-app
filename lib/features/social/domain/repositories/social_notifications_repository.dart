import 'dart:convert';
import '../models/social_notification.dart';
import '../services/social_notification_service.dart';

class SocialNotificationsRepository {
  final SocialNotificationsService service = SocialNotificationsService();

  /// 🔹 Lấy danh sách thông báo
  Future<List<SocialNotification>> getNotifications(String accessToken) async {
    final res = await service.fetchNotifications(accessToken);
    final Map<String, dynamic> data = jsonDecode(res.body) as Map<String, dynamic>;

    // WoWonder thường dùng api_status = 200/400
    final apiStatus = data['api_status'] ?? data['status'];
    if (apiStatus == 400) {
      final err = data['errors']?.toString() ?? 'Lỗi API';
      throw Exception(err);
    }

    final List list = (data['notifications'] as List?) ?? const [];
    return list
        .map((e) => SocialNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }


  /// 🗑️ Xoá thông báo
  Future<Map<String, dynamic>?> deleteNotification(
      String accessToken, String id) async {
    final res = await service.deleteNotification(accessToken, id);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

}
