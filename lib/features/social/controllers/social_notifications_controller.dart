import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import '../domain/repositories/social_notifications_repository.dart';

class SocialNotificationsController extends ChangeNotifier {
  final SocialNotificationsRepository repo;

  String? _accessToken;
  bool loading = false;
  String? error;
  List<Map<String, dynamic>> notifications = [];

  SocialNotificationsController({required this.repo});

  /// 🔹 Load danh sách thông báo từ API
  Future<void> getNotifications() async {
    try {
      loading = true;
      error = null;
      notifyListeners();

      final sp = await SharedPreferences.getInstance();
      _accessToken ??= sp.getString(AppConstants.socialAccessToken);

      final list = await repo.getNotifications(_accessToken!);
      notifications = list;

    } catch (e, stack) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> deleteNotification(String id) async {
    try {
      final sp = await SharedPreferences.getInstance();
      _accessToken ??= sp.getString(AppConstants.socialAccessToken);
      if (_accessToken == null) throw Exception('Access token not found');

      final result = await repo.deleteNotification(_accessToken!, id);
      if (result == null) throw Exception('No response');

      final status = result['api_status'].toString();
      final message = result['message_data'] ?? 'Đã xoá thông báo';

      if (status == '200') {
        notifications.removeWhere((n) => n['id'].toString() == id);
        notifyListeners();
        if (kDebugMode) debugPrint('✅ $message');
        return message; // ✅ trả về message thật
      } else {
        throw Exception(result['errors'] ?? 'Delete failed');
      }
    } catch (e, stack) {
      if (kDebugMode) debugPrint('❌ deleteNotification() error: $e\n$stack');
      return 'Lỗi khi xoá thông báo'; // ✅ vẫn trả về message lỗi
    }
  }

  /// 🔁 Hàm refresh (gọi lại API và reset token nếu cần)
  Future<void> refresh() async {
    try {
      _accessToken = null; // ép lấy lại token từ SharedPreferences
      await getNotifications();        // gọi lại load()
    } catch (e) {
      return;
    }
  }
}
