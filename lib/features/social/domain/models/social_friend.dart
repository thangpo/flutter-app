class SocialFriend {
  final String id;
  final String name;
  final String? avatar;
  final bool isOnline;
  final String? lastSeen;

  SocialFriend({
    required this.id,
    required this.name,
    this.avatar,
    this.isOnline = false,
    this.lastSeen,
  });

  /// Parse theo cấu trúc trả về phổ biến của WoWonder
  factory SocialFriend.fromWowonder(Map<String, dynamic> j) {
    final id = (j['user_id'] ?? j['id'] ?? '').toString();
    final name =
        (j['name'] ?? j['username'] ?? j['user_name'] ?? '').toString();
    final avatar =
        (j['avatar'] ?? j['avatar_url'] ?? j['profile_picture'])?.toString();

    // WoWonder: lastseen == 0 nghĩa là đang online, một số bản có 'is_online'
    final lastseenRaw = j['lastseen'] ?? j['last_seen'] ?? 0;
    final isOnline =
        (lastseenRaw is num && lastseenRaw == 0) || (j['is_online'] == true);

    final lastSeenText =
        (j['lastseen_time_text'] ?? j['last_seen_text'])?.toString();

    return SocialFriend(
      id: id,
      name: name,
      avatar: avatar,
      isOnline: isOnline,
      lastSeen: lastSeenText,
    );
  }
}
