class SocialPage {
  final String id;
  final String name;
  final String? title;
  final String? username;
  final String? about;
  final String? description;
  final String? category;
  final String? subCategory;
  final String? avatarUrl;
  final String? coverUrl;
  final String? url;
  final bool isVerified;
  final bool isOwner;
  final bool isAdmin;
  final bool isLiked;

  const SocialPage({
    required this.id,
    required this.name,
    this.title,
    this.username,
    this.about,
    this.description,
    this.category,
    this.subCategory,
    this.avatarUrl,
    this.coverUrl,
    this.url,
    this.isVerified = false,
    this.isOwner = false,
    this.isAdmin = false,
    this.isLiked = false,
  });

  SocialPage copyWith({
    String? id,
    String? name,
    String? title,
    String? username,
    String? about,
    String? description,
    String? category,
    String? subCategory,
    String? avatarUrl,
    String? coverUrl,
    String? url,
    bool? isVerified,
    bool? isOwner,
    bool? isAdmin,
    bool? isLiked,
  }) {
    return SocialPage(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      username: username ?? this.username,
      about: about ?? this.about,
      description: description ?? this.description,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      url: url ?? this.url,
      isVerified: isVerified ?? this.isVerified,
      isOwner: isOwner ?? this.isOwner,
      isAdmin: isAdmin ?? this.isAdmin,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
