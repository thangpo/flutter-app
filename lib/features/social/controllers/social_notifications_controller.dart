import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import '../domain/repositories/social_notifications_repository.dart';
import '../domain/models/social_notification.dart';

class SocialNotificationsController extends ChangeNotifier {
  final SocialNotificationsRepository repo;

  SocialNotificationsController({required this.repo});
  Map<String, dynamic>? _currentDetail;

  bool _loading = false;
  String? _error;
  String? _accessToken;
  List<SocialNotification> _notifications = [];
  Map<String, dynamic>? get currentDetail => _currentDetail;

  bool get loading => _loading;
  String? get error => _error;
  List<SocialNotification> get notifications => _notifications;

  Future<void> getNotifications() async {
    _setLoading(true);
    try {
      await _ensureAccessToken();
      final data = await repo.getNotifications(_accessToken!);
      _notifications = data;

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
  Future<void> getNotificationDetail(String id) async {
    try {
      await _ensureAccessToken();
      final data= await repo.getNotificationDetail(_accessToken!, id);
      if (data != null && data['api_status'] == 200) {
        final detail = data['detail'];
        _currentDetail = detail;
        // ✅ Cập nhật local list
        final idx = _notifications.indexWhere((e) => e.id == id);
        if (idx != -1) {
          _notifications[idx].seen = detail['seen'].toString();
          notifyListeners();
        }
      } else {
        _error = data?['errors']?.toString() ?? 'Error getting detail';
      }
    } catch (e) {
      debugPrint('Mark as seen failed: $e');
    }
  }
  Future<String?> deleteNotification(String id) async {
    try {
      await _ensureAccessToken();
      final result = await repo.deleteNotification(_accessToken!, id);
      if (result?['api_status'].toString() == '200') {
        _notifications.removeWhere((n) => n.id == id);
        notifyListeners();
        return result?['message_data'] ?? 'Đã xoá thông báo';
      } else {
        throw Exception(result?['errors'] ?? 'Delete failed');
      }
    } catch (e) {
      return 'Lỗi khi xoá thông báo: $e';
    }
  }

  Future<void> _ensureAccessToken() async {
    if (_accessToken == null) {
      final sp = await SharedPreferences.getInstance();
      _accessToken = sp.getString(AppConstants.socialAccessToken);
      if (_accessToken == null) throw Exception('Access token not found');
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  Future<void> refresh() async {
    _accessToken = null;
    await getNotifications();
  }
  void reset() {
    _notifications = [];
    _accessToken = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}

