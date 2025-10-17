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
    String? id,
    String? text,
    String? userName,
    String? userAvatar,
    String? timeText,
    List<String>? imageUrls,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
    String? videoUrl,
    String? audioUrl,
    String? postType,
    int? reactionCount,
    String? myReaction,
    bool? hasProduct,
    String? productTitle,
    List<String>? productImages,
    double? productPrice,
    String? productCurrency,
    List<Map<String, dynamic>>? pollOptions,
  }) {
    return SocialPost(
      id: id ?? this.id,
      text: text ?? this.text,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      timeText: timeText ?? this.timeText,
      imageUrls: imageUrls ?? this.imageUrls,
      imageUrl: imageUrl ?? this.imageUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      videoUrl: videoUrl ?? this.videoUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      postType: postType ?? this.postType,
      reactionCount: reactionCount ?? this.reactionCount,
      myReaction: myReaction ?? this.myReaction,
      hasProduct: hasProduct ?? this.hasProduct,
      productTitle: productTitle ?? this.productTitle,
      productImages: productImages ?? this.productImages,
      productPrice: productPrice ?? this.productPrice,
      productCurrency: productCurrency ?? this.productCurrency,
      pollOptions: pollOptions ?? this.pollOptions,
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
