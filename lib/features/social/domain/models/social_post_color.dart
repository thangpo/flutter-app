class SocialPostColor {
  final String id;
  final String? color1;
  final String? color2;
  final String? textColor;
  final String? imageUrl;

  const SocialPostColor({
    required this.id,
    this.color1,
    this.color2,
    this.textColor,
    this.imageUrl,
  });

  factory SocialPostColor.fromJson(Map<String, dynamic> json) {
    final dynamic idValue = json['id'] ?? json['color_id'];
    final String id = (idValue ?? '').toString();
    return SocialPostColor(
      id: id,
      color1: json['color_1']?.toString(),
      color2: json['color_2']?.toString(),
      textColor: json['text_color']?.toString(),
      imageUrl: json['image']?.toString(),
    );
  }
}
