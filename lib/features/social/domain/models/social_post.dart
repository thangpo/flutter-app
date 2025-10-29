class SocialPost {
  final String id;
  final String? text;
  final String? userName;
  final String? userAvatar;
  final String? timeText;
  // Media
  final List<String> imageUrls; // multi or single image
  final String? imageUrl; // convenience: first image
  final String? fileUrl; // postFile (pdf/mp3/mp4/others)
  final String? fileName;
  final String? videoUrl;
  final String? audioUrl;
  final String? postType;
  final SocialPost? sharedPost;

  // Group
  final bool isGroupPost;
  final bool isGroupAdmin;
  final String? groupId;
  final String? groupName;
  final String? groupTitle;
  final String? groupUrl;
  final String? groupAvatar;
  final String? groupCover;

  // Reactions
  final int reactionCount; // tổng số phản ứng
  final String myReaction; // '', 'Like', 'Love', 'HaHa', 'Wow', 'Sad', 'Angry'
  final Map<String, int> reactionBreakdown; // đếm theo từng loại reaction

  // Meta
  final int commentCount;
  final int shareCount;

  // Product
  final bool hasProduct;
  final String? productTitle; // product.name
  final List<String>? productImages;
  final double? productPrice;
  final String? productCurrency;
  final String? productDescription;
  final int? ecommerceProductId;
  final String? productSlug;

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
    this.sharedPost,
    this.isGroupPost = false,
    this.isGroupAdmin = false,
    this.groupId,
    this.groupName,
    this.groupTitle,
    this.groupUrl,
    this.groupAvatar,
    this.groupCover,
    required this.reactionCount,
    required this.myReaction,
    this.reactionBreakdown = const <String, int>{},
    this.commentCount = 0,
    this.shareCount = 0,
    this.hasProduct = false,
    this.productTitle,
    this.productImages,
    this.productPrice, // product.price (số)
    this.productCurrency,
    this.productDescription,
    this.ecommerceProductId,
    this.productSlug,
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
    SocialPost? sharedPost,
    bool? isGroupPost,
    bool? isGroupAdmin,
    String? groupId,
    String? groupName,
    String? groupTitle,
    String? groupUrl,
    String? groupAvatar,
    String? groupCover,
    int? reactionCount,
    String? myReaction,
    Map<String, int>? reactionBreakdown,
    int? commentCount,
    int? shareCount,
    bool? hasProduct,
    String? productTitle,
    List<String>? productImages,
    double? productPrice,
    String? productCurrency,
    String? productDescription,
    int? ecommerceProductId,
    String? productSlug,
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
      sharedPost: sharedPost ?? this.sharedPost,
      isGroupPost: isGroupPost ?? this.isGroupPost,
      isGroupAdmin: isGroupAdmin ?? this.isGroupAdmin,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupTitle: groupTitle ?? this.groupTitle,
      groupUrl: groupUrl ?? this.groupUrl,
      groupAvatar: groupAvatar ?? this.groupAvatar,
      groupCover: groupCover ?? this.groupCover,
      reactionCount: reactionCount ?? this.reactionCount,
      myReaction: myReaction ?? this.myReaction,
      reactionBreakdown: reactionBreakdown ?? this.reactionBreakdown,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      hasProduct: hasProduct ?? this.hasProduct,
      productTitle: productTitle ?? this.productTitle,
      productImages: productImages ?? this.productImages,
      productPrice: productPrice ?? this.productPrice,
      productCurrency: productCurrency ?? this.productCurrency,
      productDescription: productDescription ?? this.productDescription,
      ecommerceProductId: ecommerceProductId ?? this.ecommerceProductId,
      productSlug: productSlug ?? this.productSlug,
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
