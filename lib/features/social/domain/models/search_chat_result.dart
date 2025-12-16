import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_page_chat.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_friend.dart';

/// Kết quả trả về từ API chat?type=search_chat
class SearchChatResult {
  final List<SocialFriend> friends;
  final List<ChatGroupHit> groups;
  final List<PageChatThread> pages;

  const SearchChatResult({
    this.friends = const [],
    this.groups = const [],
    this.pages = const [],
  });

  factory SearchChatResult.fromJson(Map<String, dynamic> json) {
    final friendsJson = json['friends'] as List? ?? const [];
    final groupsJson = json['groups'] as List? ?? const [];
    final pagesJson = json['pages'] as List? ?? const [];

    return SearchChatResult(
      friends: friendsJson
          .whereType<Map>()
          .map((e) => SocialFriend.fromWowonder(Map<String, dynamic>.from(e)))
          .toList(),
      groups: groupsJson
          .whereType<Map>()
          .map((e) => ChatGroupHit.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      pages: pagesJson
          .whereType<Map>()
          .map((e) => PageChatThread.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

/// Nhóm chat tối giản
class ChatGroupHit {
  final String groupId;
  final String name;
  final String? avatar;
  final Map<String, dynamic>? mute;

  ChatGroupHit({
    required this.groupId,
    required this.name,
    this.avatar,
    this.mute,
  });

  factory ChatGroupHit.fromJson(Map<String, dynamic> json) {
    return ChatGroupHit(
      groupId: (json['group_id'] ?? '').toString(),
      name: (json['group_name'] ?? '').toString(),
      avatar: json['avatar']?.toString(),
      mute: json['mute'] is Map ? Map<String, dynamic>.from(json['mute']) : null,
    );
  }
}
