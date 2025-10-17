class SocialPost {
  final String id;
  final String? text;
  final String? userName;
  final String? userAvatar;
  final String? timeText;
  // Media
  final List<String> imageUrls;      // multi or single image
  final String? imageUrl;            // convenience: first image
  final String? fileUrl;             // postFile (pdf/mp3/mp4/others)
  final String? fileName;
  final String? videoUrl;
  final String? audioUrl;
  final String? postType;

  // Reactions
  final int reactionCount; // tổng số phản ứng
  final String myReaction; // '', 'Like', 'Love', 'HaHa', 'Wow', 'Sad', 'Angry'

  // Product
  final bool hasProduct;
  final String? productTitle;// product.name
  final List<String>? productImages;
  final double? productPrice;
  final String? productCurrency;

  // Poll
  final List<Map<String, dynamic>>? pollOptions; // each: {text, percentage_num}

  const SocialPost({
    required this.id,
    this.text,
    this.userName,
    this.userAvatar,
    this.timeText,
    this.imageUrls = const <String>[],
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    this.videoUrl,
    this.audioUrl,
    this.postType,
    required this.reactionCount,
    required this.myReaction,
    this.hasProduct = false,
    this.productTitle,
    this.productImages,
    this.productPrice,        // product.price (số)
    this.productCurrency,
    this.pollOptions,
  });

  SocialPost copyWith({
    int? reactionCount,
    String? myReaction,
    // nếu bạn muốn copy các field khác, thêm vào tại đây
  }) {
    return SocialPost(
      id: id,
      text: text,
      userName: userName,
      userAvatar: userAvatar,
      timeText: timeText,
      imageUrls: imageUrls,
      imageUrl: imageUrl,
      fileUrl: fileUrl,
      fileName: fileName,
      videoUrl: videoUrl,
      audioUrl: audioUrl,
      postType: postType,
      // Reactions
      reactionCount: reactionCount ?? this.reactionCount,
      myReaction: myReaction ?? this.myReaction,
      // Product/Poll… nếu có các tham số bắt buộc khác trong constructor, truyền lại ở đây
    );
  }

// factory SocialPost.fromJson(Map<String, dynamic> j) {
  //   final publisher =
  //       (j['publisher'] is Map) ? (j['publisher'] as Map) : const {};
  //   return SocialPost(
  //     id: (j['post_id'] ?? '').toString(),
  //     text: j['postText']?.toString(),
  //     imageUrl: j['postFile']?.toString(),
  //     userName: (publisher['name'] ?? publisher['username'] ?? '').toString(),
  //     userAvatar: publisher['avatar']?.toString(),
  //     timeText: j['time_text']?.toString(),
  //   );
  // }
}
