class SocialStory {
  final String id;
  final String? thumbUrl;
  final String? mediaUrl;
  final String? userName;
  final String? userAvatar;

  SocialStory({
    required this.id,
    this.thumbUrl,
    this.mediaUrl,
    this.userName,
    this.userAvatar,
  });

  factory SocialStory.fromJson(Map<String, dynamic> j) {
    // Cấu trúc WoWonder thường trả: story_id, thumbnail, media, user_data{ name/username, avatar }
    final user = (j['user_data'] is Map) ? (j['user_data'] as Map) : const {};
    return SocialStory(
      id: (j['story_id'] ?? j['id'] ?? '').toString(),
      thumbUrl: j['thumbnail']?.toString(),
      mediaUrl: j['media']?.toString(),
      userName: (user['name'] ?? user['username'] ?? '').toString(),
      userAvatar: user['avatar']?.toString(),
    );
  }
}
