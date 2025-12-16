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
  final Map<String, dynamic> raw;
  final String? lastMessageText;
  final int? lastMessageTime;
  final int? unread;

  ChatGroupHit({
    required this.groupId,
    required this.name,
    this.avatar,
    this.mute,
    this.raw = const {},
    this.lastMessageText,
    this.lastMessageTime,
    this.unread,
  });

  factory ChatGroupHit.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(json);

    int? parseInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    String? parsePreview(Map<String, dynamic> m) {
      final lm = m['last_message'];
      if (lm is Map) {
        final mm = Map<String, dynamic>.from(lm);
        final display = (mm['display_text'] ?? mm['text'] ?? '').toString();
        if (display.trim().isNotEmpty) return display.trim();
      }
      final raw = m['last_message_text'] ?? m['last_text'] ?? m['last_msg'];
      if (raw is String && raw.trim().isNotEmpty) return raw.trim();
      return null;
    }

    int? parseTime(Map<String, dynamic> m) {
      final fields = [
        m['last_message_time'],
        m['last_time'],
        m['time'],
      ];
      for (final f in fields) {
        final n = parseInt(f);
        if (n != null && n > 0) return n;
      }
      final lm = m['last_message'];
      if (lm is Map) {
        return parseInt(lm['time']);
      }
      return null;
    }

    final preview = parsePreview(map);
    final time = parseTime(map);
    final unread = parseInt(
          map['unread'] ?? map['unread_count'] ?? map['count_unread'],
        ) ??
        0;

    return ChatGroupHit(
      groupId: (json['group_id'] ?? '').toString(),
      name: (json['group_name'] ?? '').toString(),
      avatar: json['avatar']?.toString(),
      mute: json['mute'] is Map ? Map<String, dynamic>.from(json['mute']) : null,
      raw: map,
      lastMessageText: preview,
      lastMessageTime: time,
      unread: unread,
    );
  }
}
