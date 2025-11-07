import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_sixvalley_ecommerce/push_notification/navigation/app_navigator.dart';

// Social deps
import 'package:flutter_sixvalley_ecommerce/di_container.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_post_detail_screen.dart';

/// Chặn double-routing khi listener bắn 2 lần.
class NotificationRouter {
  static bool _isRouting = false;

  /// Hàm chính: gọi ở onMessageOpenedApp / getInitialMessage
  static Future<void> route(RemoteMessage msg) async {
    try {
      final data = msg.data;
      debugPrint('🔔 Router RAW: $data');

      // Nhánh Social (WoWonder) – luôn có api_status hoặc detail
      if (data.containsKey('api_status') || data.containsKey('detail')) {
        final detail = _decodeDetail(data['detail']);
        debugPrint('🧩 detail: $detail');

        final String type     = '${detail['type'] ?? data['type'] ?? ''}';
        final String action   = '${detail['action']?['type'] ?? ''}';
        final String postId  = '${detail['post_id'] ?? ''}';
        debugPrint('✅ parsed: type=$type action=$action postId=$postId');

        // Tình huống phổ biến: reaction → mở màn chi tiết bài viết
        if ((action == 'open_reaction' || type == 'reaction') &&
            postId != '') {
          await _guard(() => _openPostDetail(postId));
          return;
        }

        // TODO: Bạn có thể bổ sung các case khác ở đây (comment, share, group…)
        debugPrint('ℹ️ Social notif: không có action tương ứng – bỏ qua.');
        return;
      }

      // Các loại notif khác của app (order/wallet/…) có thể map tại đây nếu cần
      debugPrint('ℹ️ Non-social notif: hiện tại không route.');
    } catch (e, st) {
      debugPrint('❌ NotificationRouter.route error: $e\n$st');
    }
  }

  /// Prefetch post rồi mới mở màn hình → tránh vào trang mà phải “load mãi”.
  static Future<void> _openPostDetail(String postId) async {
    try {
      // Cho DI & widget tree kịp sẵn sàng
      await Future.delayed(const Duration(milliseconds: 50));

      final socialService = sl<SocialServiceInterface>();
      SocialPost? full;
      try {
        full = await socialService
            .getPostById(postId: postId)
            .timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('⚠️ getPostById($postId) fail: $e');
      }

      final post = full ??
          SocialPost(
            id: postId,
            text: '',
            imageUrls: const [],
            reactionCount: 0,
            myReaction: '',
          );

      debugPrint('🧭 push SocialPostDetailScreen(postId=$postId)');
      await AppNavigator.pushPage(SocialPostDetailScreen(post: post));
      debugPrint('✅ pushed SocialPostDetailScreen');
    } catch (e, st) {
      debugPrint('❌ _openPostDetail error: $e\n$st');
    }
  }

  /// Giải mã field "detail" (có thể là String JSON hoặc Map).
  static Map<String, dynamic> _decodeDetail(dynamic raw) {
    try {
      if (raw == null) return const {};
      if (raw is Map<String, dynamic>) return raw;
      if (raw is String && raw.trim().isNotEmpty) {
        final m = jsonDecode(raw);
        if (m is Map<String, dynamic>) return m;
      }
      return const {};
    } catch (_) {
      return const {};
    }
  }

  /// Guard giúp chặn double navigate trong một khoảng ngắn.
  static Future<void> _guard(Future<void> Function() job) async {
    if (_isRouting) {
      debugPrint('⏸️ skip: routing is in progress');
      return;
    }
    _isRouting = true;
    try {
      await job();
    } finally {
      Future.delayed(const Duration(milliseconds: 600), () {
        _isRouting = false;
      });
    }
  }
}
