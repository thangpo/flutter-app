import 'package:flutter_sixvalley_ecommerce/features/social/utils/wowonder_text.dart';

class SocialFriend {
  final String id;
  final String name;
  final String? avatar;
  final bool isOnline;
  final String? lastSeen;
  final String? lastMessageText;

  /// Timestamp of the latest message (seconds or milliseconds depending on backend).
  /// Used for sorting so the freshest threads stay on top.
  final int? lastMessageTime;

  SocialFriend({
    required this.id,
    required this.name,
    this.avatar,
    this.isOnline = false,
    this.lastSeen,
    this.lastMessageText,
    this.lastMessageTime,
  });

  /// Parse with common WoWonder style payloads.
  factory SocialFriend.fromWowonder(Map<String, dynamic> j) {
    final id = (j['user_id'] ?? j['id'] ?? '').toString();
    final name =
        (j['name'] ?? j['username'] ?? j['user_name'] ?? '').toString();
    final avatar =
        (j['avatar'] ?? j['avatar_url'] ?? j['profile_picture'])?.toString();

    // WoWonder: lastseen == 0 => online. Some payloads send is_online instead.
    final lastseenRaw = j['lastseen'] ?? j['last_seen'] ?? 0;
    final isOnline =
        (lastseenRaw is num && lastseenRaw == 0) || (j['is_online'] == true);

    final lastSeenText =
        (j['lastseen_time_text'] ?? j['last_seen_text'])?.toString();

    // Extract latest message text/preview
    String? lastMessageText;
    final lastMsgRaw = j['last_message'];
    Map<String, dynamic>? lastMsgMap;
    if (lastMsgRaw is Map<String, dynamic>) {
      lastMsgMap = Map<String, dynamic>.from(lastMsgRaw);
      final display = (lastMsgMap['display_text'] ?? '').toString().trim();
      if (display.isNotEmpty) {
        lastMessageText = display;
      } else {
        final pick = pickWoWonderText(lastMsgMap);
        if (pick.isNotEmpty) {
          lastMessageText = pick;
        }
      }
    } else if (lastMsgRaw is List && lastMsgRaw.isNotEmpty) {
      final first = lastMsgRaw.first;
      if (first is Map) {
        lastMsgMap = Map<String, dynamic>.from(first as Map);
        final pick = pickWoWonderText(lastMsgMap);
        if (pick.isNotEmpty) lastMessageText = pick;
      }
    } else if (lastMsgRaw is String && lastMsgRaw.trim().isNotEmpty) {
      lastMessageText = lastMsgRaw.trim();
    }

    // Some payloads expose a flat text field instead of a nested map.
    if (lastMessageText == null || lastMessageText.isEmpty) {
      final raw = j['last_message_text'] ?? j['last_msg'] ?? j['lastMessage'];
      if (raw is String && raw.trim().isNotEmpty) {
        lastMessageText = raw.trim();
      }
    }

    // Extract latest message timestamp
    dynamic lastMsgTimeRaw = j['last_message_time'] ??
        j['last_msg_time'] ??
        lastMsgMap?['time'] ??
        lastMsgMap?['time_text'];

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
    );
  }
}
