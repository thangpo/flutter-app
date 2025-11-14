import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart' show navigatorKey;
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_post_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/profile_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_story_viewer_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_group_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_groups_screen.dart';

/// ========================= CONFIG =========================

// Các loại mở bài viết
const Set<String> _postTypes = {
  'reaction',
  'comment',
  'comment_reply',
  'comment_mention',
  'post_mention',
  'shared_your_post',
  'share_post',
};
const Set<String> _postOpenActions = {
  'open_reaction',
  'open_comment',
  'open_post',
  'open_like',
  'open_share',
  'open_comment_reply',
  'open_comment_mention',
  'open_post_mention',
};

// Mở profile người dùng
const Set<String> _profileTypes = {
  'following',
  'visited_profile',
  'accepted_request',
};
const Set<String> _profileOpenActions = {
  'open_following',
  'open_profile',
  'open_visited_profile',
};

// Mở story
const Set<String> _storyTypes = {
  'viewed_story',
};
const Set<String> _storyOpenActions = {
  'open_story',
  'open_viewed_story',
};
// Mở group
const Set<String> _groupTypes = {
  'invited_you_to_the_group',
  'joined_group',
  'requested_to_join_group',
  'accepted_join_request',
  'group_admin',
};
const Set<String> _groupOpenActions = {
  'open_group',
  'open_group_invite',
  'open_group_request',
};

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
  // 1️⃣ Gộp 'payload' vào top-level
  final merged = _mergeWithPayload(data);

  // 2️⃣ Chuẩn hoá field
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
  final String storyId = _pickFirstNonEmpty([
    _str(merged['story_id']),
    _str(merged['storyId']),
    _str((merged['story'] is Map) ? (merged['story']['id']) : ''),
  ]);
  final String groupId = _pickFirstNonEmpty([
    _str(merged['group_id']),
    _str(merged['groupId']),
    _str((merged['group'] is Map) ? (merged['group']['id']) : ''),
  ]);

  debugPrint(
    '✅ parsed: type=$type | action=$action | postId=$postId | userId=$userId | storyId=$storyId',
  );

  // 3️⃣ Điều hướng theo loạic
  if (_shouldOpenStory(type: type, action: action, storyId: storyId)) {
    await _openStory(storyId, userId);
    return;
  }

  if (_shouldOpenPost(type: type, action: action, postId: postId)) {
    await _openPostPayload(postId);
    return;
  }

  if (_shouldOpenProfile(type: type, action: action)) {
    await _openProfile(userId: userId);
    return;
  }
  if (_shouldOpenGroup(type: type, action: action, groupId: groupId)) {
    await _openGroupPayload(groupId);
    return;
  }
// 🟡 fallback riêng cho thông báo group_admin không có group_id
  if (type == 'group_admin' && (groupId.isEmpty || groupId == '0')) {
    await _openGroupList();
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
  return _postTypes.contains(type) || _postOpenActions.contains(action);
}

bool _shouldOpenProfile({
  required String type,
  required String action,
}) {
  return _profileTypes.contains(type) || _profileOpenActions.contains(action);
}

bool _shouldOpenStory({
  required String type,
  required String action,
  required String storyId,
}) {
  if (storyId.isEmpty) return false;
  return _storyTypes.contains(type) || _storyOpenActions.contains(action);
}

bool _shouldOpenGroup({
  required String type,
  required String action,
  required String groupId,
}) {
  if (groupId.isEmpty || groupId == '0' || groupId == 'null') return false;
  return _groupTypes.contains(type) || _groupOpenActions.contains(action);
}


/// ========================= NAV HELPERS =========================

Future<void> _openPostPayload(String postId) async {
  await _pushOnce(() {
    return MaterialPageRoute(
      builder: (_) => SocialPostDetailScreen(
        post: SocialPost(
          id: postId,
          reactionCount: 0,
          myReaction: '',
        ),
      ),
    );
  });
}

Future<void> _openProfile({required String userId}) async {
  if (userId.trim().isEmpty) {
    return;
  }
  await _pushOnce(() {
    return MaterialPageRoute(
      builder: (_) => ProfileScreen(targetUserId: userId),
    );
  });
}

Future<void> _openStory(String storyId, String userId) async {
  await _pushOnce(() {
    debugPrint('🧭 NAV → SocialStoryViewerScreen(storyId=$storyId)');
    return MaterialPageRoute(
      builder: (_) => SocialStoryViewerScreen(
        stories: [
          SocialStory(
            id: storyId,
            userId: userId,
            userName: '',
            userAvatar: '',
            items: [
              SocialStoryItem(
                id: storyId,
                mediaUrl: '',
                description: '',
              ),
            ],
          ),
        ],
      ),
    );
  });
}

Future<void> _openGroupPayload(String groupId) async {
  await _pushOnce(() {
    return MaterialPageRoute(
      builder: (_) => SocialGroupDetailScreen(groupId: groupId),
    );
  });
}

Future<void> _openGroupList() async {
  await _pushOnce(() {
    return MaterialPageRoute(
      builder: (_) => const SocialGroupsScreen(),
    );
  });
}

/// ========================= SAFE NAVIGATION =========================

Future<void> _pushOnce(MaterialPageRoute Function() builder) async {
  if (_routing) return;
  _routing = true;

  for (int i = 0; i < 20 && navigatorKey.currentState == null; i++) {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  final nav = navigatorKey.currentState;
  if (nav == null) {
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

Map<String, dynamic> _mergeWithPayload(Map<String, dynamic> data) {
  final base = data.map((k, v) => MapEntry(k.toString(), v));
  final payload = _parsePayload(base['payload']);
  return <String, dynamic>{}
    ..addAll(base)
    ..addAll(payload);
}

Map<String, dynamic> _parsePayload(dynamic raw) {
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

String _pickFirstNonEmpty(List<String> list) {
  for (final s in list) {
    if (s.trim().isNotEmpty) return s.trim();
  }
  return '';
}
