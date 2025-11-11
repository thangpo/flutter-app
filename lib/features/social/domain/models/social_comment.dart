class SocialComment {
  final String id;
  final String? userId;
  final String? text;
  final String? userName;
  final String? userAvatar;
  final String? timeText;
  final int? repliesCount;
  final String? imageUrl;
  final String? audioUrl;
  final int reactionCount;
  final String myReaction;
  final DateTime? createdAt;

  const SocialComment({
    required this.id,
    this.userId,
    this.text,
    this.userName,
    this.userAvatar,
    this.timeText,
    this.repliesCount,
    this.imageUrl,
    this.audioUrl,
    this.reactionCount = 0,
    this.myReaction = '',
    this.createdAt,
  });

  SocialComment copyWith({
    String? id,
    String? userId,
    String? text,
    String? userName,
    String? userAvatar,
    String? timeText,
    int? repliesCount,
    String? imageUrl,
    String? audioUrl,
    int? reactionCount,
    String? myReaction,
    DateTime? createdAt,
  }) {
    return SocialComment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      text: text ?? this.text,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      timeText: timeText ?? this.timeText,
      repliesCount: repliesCount ?? this.repliesCount,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      reactionCount: reactionCount ?? this.reactionCount,
      myReaction: myReaction ?? this.myReaction,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
