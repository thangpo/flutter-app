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
    this.hasProduct = false,
    this.productTitle,
    this.productImages,
    this.productPrice,        // product.price (số)
    this.productCurrency,
    this.pollOptions,
  });

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
