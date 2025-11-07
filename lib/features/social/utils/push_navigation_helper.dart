import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart' show navigatorKey;
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_post_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/profile_screen.dart';

/// ========================= CONFIG =========================

/// Những type dẫn tới mở chi tiết bài viết
const Set<String> _postTypes = {
  'reaction',
  'comment',
  'shared_your_post',
};

/// Những action dạng "open_*" dẫn tới mở chi tiết bài viết
const Set<String> _postOpenActions = {
  'open_reaction',
  'open_comment',
  'open_post',
  'open_like',
  'open_share',
};

/// Những type/action dẫn tới mở profile người dùng
const Set<String> _profileTypes = {'following'};
const Set<String> _profileOpenActions = {'open_following'};

/// Cooldown chống double navigate
bool _routing = false;

/// ========================= PUBLIC APIS =========================

Future<void> handlePushNavigation(RemoteMessage message) async {
  try {
    final data = message.data;
    debugPrint('🔔 handlePushNavigation() data=$data');
    await _routeFromDataMap(data);
  } catch (e, st) {
    debugPrint('❌ handlePushNavigation error: $e\n$st');
  }
}

/// Dùng khi tap local notification (payload đã decode sẵn thành Map)
Future<void> handlePushNavigationFromMap(Map<String, dynamic> data) async {
  try {
    debugPrint('🔔 handlePushNavigationFromMap() data=$data');
    await _routeFromDataMap(data);
  } catch (e, st) {
    debugPrint('❌ handlePushNavigationFromMap error: $e\n$st');
  }
}

/// ========================= CORE ROUTER =========================

Future<void> _routeFromDataMap(Map<String, dynamic> data) async {
  // 1) Hợp nhất 'detail' (nếu có) vào top-level
  final merged = _mergeWithDetail(data);

  // 2) Chuẩn hoá field
  final String type = _str(merged['type']);
  final String action = _actionType(merged['action']);
  final String postId = _pickFirstNonEmpty([
    _str(merged['post_id']),
    _str(merged['postId']),
    _str((merged['post'] is Map) ? (merged['post']['id']) : ''),
  ]);
  final String userId = _pickFirstNonEmpty([
    _str(merged['notifier_id']),
    _str((merged['notifier'] is Map) ? (merged['notifier']['user_id']) : ''),
    _str(merged['user_id']),
  ]);

  debugPrint('✅ parsed: type=$type | action=$action | postId=$postId | userId=$userId');

  // 3) Quyết định route
  if (_shouldOpenPost(type: type, action: action, postId: postId)) {
    await _openPostDetail(postId);
    return;
  }

  if (_shouldOpenProfile(type: type, action: action)) {
    await _openProfile(userId: userId);
    return;
  }

  debugPrint('ℹ️ Không khớp route nào, bỏ qua.');
}

/// ========================= DECISIONS =========================

bool _shouldOpenPost({
  required String type,
  required String action,
  required String postId,
}) {
  if (postId.isEmpty) return false;
  if (_postTypes.contains(type)) return true;
  if (_postOpenActions.contains(action)) return true;
  return false;
}

bool _shouldOpenProfile({
  required String type,
  required String action,
}) {
  return _profileTypes.contains(type) || _profileOpenActions.contains(action);
}

/// ========================= NAV HELPERS =========================

Future<void> _openPostDetail(String postId) async {
  await _pushOnce(() {
    debugPrint('🧭 NAV → SocialPostDetailScreen(postId=$postId)');
    return MaterialPageRoute(
      builder: (_) => SocialPostDetailScreen(
        post: SocialPost(
          id: postId, // nếu cần int: int.parse(postId)
          reactionCount: 0,
          myReaction: '',
        ),
      ),
    );
  });
}

Future<void> _openProfile({required String userId}) async {
  if (userId.trim().isEmpty) {
    debugPrint('❗ Không có userId để mở ProfileScreen');
    return;
  }
  await _pushOnce(() {
    debugPrint('🧭 NAV → ProfileScreen(targetUserId=$userId)');
    return MaterialPageRoute(
      builder: (_) => ProfileScreen(targetUserId: userId),
    );
  });
}

/// Chỉ cho phép push 1 lần trong 600ms, tự đợi navigator sẵn sàng.
Future<void> _pushOnce(MaterialPageRoute Function() builder) async {
  if (_routing) {
    debugPrint('⏸️ Bỏ qua: đang routing');
    return;
  }
  _routing = true;

  // Đợi navigator sẵn (app có thể vừa từ background/terminated lên)
  for (int i = 0; i < 20 && navigatorKey.currentState == null; i++) {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  final nav = navigatorKey.currentState;
  if (nav == null) {
    debugPrint('❗ navigator chưa sẵn sàng, bỏ qua push');
    _cooldown();
    return;
  }

  nav.push(builder());
  _cooldown();
}

void _cooldown() {
  Future.delayed(const Duration(milliseconds: 600), () {
    _routing = false;
  });
}

/// ========================= MAP / STRING HELPERS =========================

Map<String, dynamic> _mergeWithDetail(Map<String, dynamic> data) {
  final base = data.map((k, v) => MapEntry(k.toString(), v));
  final detail = _parseDetail(base['detail']);
  return <String, dynamic>{}
    ..addAll(base)
    ..addAll(detail);
}

Map<String, dynamic> _parseDetail(dynamic raw) {
  try {
    if (raw == null) return const {};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String && raw.trim().isNotEmpty) {
      final m = jsonDecode(raw);
      if (m is Map<String, dynamic>) return m;
    }
  } catch (_) {}
  return const {};
}

String _actionType(dynamic action) {
  if (action is Map && action['type'] != null) return _str(action['type']);
  return _str(action);
}

String _str(dynamic v) => (v ?? '').toString();

String _pickFirstNonEmpty(List<String> candidates) {
  for (final s in candidates) {
    if (s.trim().isNotEmpty) return s.trim();
  }
  return '';
}
