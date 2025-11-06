import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_story_viewer_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_post_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/group_chat_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/profile_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/notification/screens/notification_screen.dart';

Future<void> handlePushNavigation(RemoteMessage message) async {
  // 1) Log thô + pretty
  debugPrint('🔔 handlePushNavigation() RAW: ${message.data}');
  try {
    debugPrint(const JsonEncoder.withIndent('  ').convert(message.data));
  } catch (_) {}

  // 2) Merge extra_data nếu server gửi dạng chuỗi JSON
  final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);
  final extraRaw = data['extra_data'];
  if (extraRaw is String && extraRaw.trim().isNotEmpty) {
    try {
      final extra = json.decode(extraRaw);
      if (extra is Map<String, dynamic>) {
        data.addAll(extra);
        debugPrint('🧩 Merged extra_data -> ${const JsonEncoder.withIndent("  ").convert(data)}');
      }
    } catch (e) {
      debugPrint('⚠️ extra_data not JSON: $e');
    }
  }

  final type       = (data['type'] ?? '').toString();
  final postId     = (data['post_id'] ?? data['postId'] ?? '').toString();
  final storyId    = (data['story_id'] ?? data['storyId'] ?? '').toString();
  final notifierId = (data['notifier_id'] ?? data['notifierId'] ?? '').toString();
  final groupId    = (data['group_id'] ?? data['groupId'] ?? '').toString();
  final url        = (data['url'] ?? '').toString();
  final text       = (data['text'] ?? '').toString();

  debugPrint('✅ Parsed: type=$type | post=$postId | story=$storyId | group=$groupId | url=$url');

  // 3) Đảm bảo navigator đã sẵn sàng (tránh push quá sớm khi app vừa mở bằng notif)
  Future<void> safePush(Widget page) async {
    if (navigatorKey.currentState == null) {
      debugPrint('⏳ navigatorKey chưa sẵn — chờ frame đầu rồi push');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => page));
      });
    } else {
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => page));
    }
  }

  // 4) Điều hướng
  // Story
  if (type == 'viewed_story' || (storyId.isNotEmpty && storyId != '0')) {
    debugPrint('➡️ NAV: StoryViewer id=$storyId');
    await safePush(
      SocialStoryViewerScreen(
        stories: [
          SocialStory(
            id: storyId,
            userId: notifierId,
            userName: data['name']?.toString() ?? '',
            userAvatar: data['avatar']?.toString() ?? '',
            items: [ SocialStoryItem(id: storyId, mediaUrl: '', description: '') ],
          ),
        ],
      ),
    );
    return;
  }

  // Post / Comment / Reaction / Share
  if (type == 'comment' || type == 'comment_reply' || type == 'reaction' || type == 'shared_your_post') {
    if (postId.isNotEmpty && postId != '0') {
      debugPrint('➡️ NAV: SocialPostDetail id=$postId');
      await safePush(
        SocialPostDetailScreen(
          post: SocialPost(
            id: postId,
            text: text,
            imageUrls: const [],
            reactionCount: 0,
            myReaction: '',
          ),
        ),
      );
      return;
    }
  }

  // Group chat
  if (type == 'group_chat' || type == 'invited_you_to_the_group' || type == 'joined_group') {
    if (groupId.isNotEmpty && groupId != '0') {
      debugPrint('➡️ NAV: GroupChat id=$groupId');
      await safePush(GroupChatScreen(groupId: groupId));
      return;
    }
  }

  // Follow / Profile
  if (type == 'followed' || type == 'following') {
    if (notifierId.isNotEmpty) {
      debugPrint('➡️ NAV: Profile id=$notifierId');
      await safePush(ProfileScreen(targetUserId: notifierId));
      return;
    }
  }

  // Mặc định: danh sách thông báo
  debugPrint('➡️ NAV: NotificationScreen (default)');
  await safePush(const NotificationScreen(fromNotification: true));
}
