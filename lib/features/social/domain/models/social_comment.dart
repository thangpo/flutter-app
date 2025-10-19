class SocialComment {
  final String id;
  final String? text;
  final String? userName;
  final String? userAvatar;
  final String? timeText;
  final int? repliesCount;
  final String? imageUrl;
  final String? audioUrl;

  const SocialComment({
    required this.id,
    this.text,
    this.userName,
    this.userAvatar,
    this.timeText,
    this.repliesCount,
    this.imageUrl,
    this.audioUrl,
  });
}
