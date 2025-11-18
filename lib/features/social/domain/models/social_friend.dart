// G:\flutter-app\lib\features\social\domain\models\social_friend.dart
class SocialFriend {
  final String id;
  final String name;
  final String? avatar;
  final bool isOnline;
  final String? lastSeen;

  /// Thời gian tin nhắn cuối cùng (timestamp, ví dụ: seconds hoặc milliseconds)
  /// Dùng để sort đoạn chat mới nhất lên trên. Có thể null nếu backend chưa trả.
  final int? lastMessageTime;

  SocialFriend({
    required this.id,
    required this.name,
    this.avatar,
    this.isOnline = false,
    this.lastSeen,
    this.lastMessageTime,
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

    // 👇 cố gắng đọc thời gian tin nhắn cuối nếu backend có trả
    // (không có thì sẽ là null, app vẫn chạy bình thường)
    dynamic lastMsgTimeRaw = j['last_message_time'] ??
        j['last_msg_time'] ??
        j['last_message']?['time'];

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
      lastMessageTime: lastMessageTime,
    );
  }
}
