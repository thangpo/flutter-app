class SocialPost {
  final String id;
  final String? text;
  final String? imageUrl;
  final String? userName;
  final String? userAvatar;
  final String? timeText;
  final List<String> imageUrls; // hỗ trợ multi-image & ảnh đơn
  final String? postType;

  SocialPost({
    required this.id,
    this.text,
    this.imageUrl,
    this.userName,
    this.userAvatar,
    this.timeText,
    this.imageUrls = const [],
    this.postType,
  });

  factory SocialPost.fromJson(Map<String, dynamic> j) {
    final publisher =
        (j['publisher'] is Map) ? (j['publisher'] as Map) : const {};
    return SocialPost(
      id: (j['post_id'] ?? '').toString(),
      text: j['postText']?.toString(),
      imageUrl: j['postFile']?.toString(),
      userName: (publisher['name'] ?? publisher['username'] ?? '').toString(),
      userAvatar: publisher['avatar']?.toString(),
      timeText: j['time_text']?.toString(),
    );
  }
}
