import 'package:flutter_sixvalley_ecommerce/features/social/utils/wowonder_text.dart';

class SocialFriend {
  final String id;
  final String name;
  final String? avatar;
  final bool isOnline;
  final String? lastSeen;
  final String? lastMessageText;
  final int? lastMessageTime;

  /// ⚠️ CHỈ LÀ GIÁ TRỊ KHỞI TẠO – UI SẼ OVERRIDE
  final bool hasUnread;

  SocialFriend({
    required this.id,
    required this.name,
    this.avatar,
    this.isOnline = false,
    this.lastSeen,
    this.lastMessageText,
    this.lastMessageTime,
    this.hasUnread = false,
  });

  factory SocialFriend.fromWowonder(Map<String, dynamic> j) {
    final id = (j['user_id'] ?? j['id'] ?? '').toString();
    final name =
    (j['name'] ?? j['username'] ?? j['user_name'] ?? '').toString();
    final avatar =
    (j['avatar'] ?? j['avatar_url'] ?? j['profile_picture'])?.toString();

    final lastseenRaw = j['lastseen'] ?? j['last_seen'] ?? 0;
    final bool isOnline =
        (lastseenRaw is num && lastseenRaw == 0) ||
            j['is_online'] == true ||
            j['is_online'] == 1;

    final String? lastSeenText =
    (j['lastseen_time_text'] ?? j['last_seen_text'])?.toString();

    int unreadCount = 0;
    final unreadRaw = j['unread'] ?? j['unread_count'];
    if (unreadRaw is num) {
      unreadCount = unreadRaw.toInt();
    } else if (unreadRaw is String) {
      unreadCount = int.tryParse(unreadRaw) ?? 0;
    }
    final bool hasUnread = unreadCount > 0;

    String? lastMessageText;
    final lastMsgRaw = j['last_message'];
    Map<String, dynamic>? lastMsgMap;

    if (lastMsgRaw is Map<String, dynamic>) {
      lastMsgMap = Map<String, dynamic>.from(lastMsgRaw);
      final display =
      (lastMsgMap['display_text'] ?? '').toString().trim();
      if (display.isNotEmpty) {
        lastMessageText = display;
      } else {
        final pick = pickWoWonderText(lastMsgMap);
        if (pick.isNotEmpty) lastMessageText = pick;
      }
    } else if (lastMsgRaw is List && lastMsgRaw.isNotEmpty) {
      final first = lastMsgRaw.first;
      if (first is Map) {
        lastMsgMap = Map<String, dynamic>.from(first);
        final pick = pickWoWonderText(lastMsgMap);
        if (pick.isNotEmpty) lastMessageText = pick;
      }
    } else if (lastMsgRaw is String && lastMsgRaw.trim().isNotEmpty) {
      lastMessageText = lastMsgRaw.trim();
    }

    if (lastMessageText == null || lastMessageText.isEmpty) {
      final raw =
          j['last_message_text'] ?? j['last_msg'] ?? j['lastMessage'];
      if (raw is String && raw.trim().isNotEmpty) {
        lastMessageText = raw.trim();
      }
    }

    dynamic lastMsgTimeRaw = j['last_message_time'] ??
        j['last_msg_time'] ??
        lastMsgMap?['time'] ??
        lastMsgMap?['timestamp'];

    int? lastMessageTime;
    if (lastMsgTimeRaw is num) {
      lastMessageTime = lastMsgTimeRaw.toInt();
    } else if (lastMsgTimeRaw is String) {
      lastMessageTime = int.tryParse(lastMsgTimeRaw);
    }

    return SocialFriend(
      id: id,
      name: name,
      avatar: avatar,
      isOnline: isOnline,
      lastSeen: lastSeenText,
      lastMessageText: lastMessageText,
      lastMessageTime: lastMessageTime,
      hasUnread: hasUnread,
    );
  }

  SocialFriend copyWith({
    bool? hasUnread,
    String? lastMessageText,
    int? lastMessageTime,
  }) {
    return SocialFriend(
      id: id,
      name: name,
      avatar: avatar,
      isOnline: isOnline,
      lastSeen: lastSeen,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      hasUnread: hasUnread ?? this.hasUnread,
    );
  }
}
