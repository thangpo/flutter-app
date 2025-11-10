class SocialChannel {
  final String id;
  final String name;
  final String? title;
  final String? username;
  final String? description;
  final String? category;
  final String? avatarUrl;
  final String? coverUrl;
  final String? url;
  final bool isVerified;
  final bool isOwner;
  final bool isSubscribed;
  final int subscriberCount;

  const SocialChannel({
    required this.id,
    required this.name,
    this.title,
    this.username,
    this.description,
    this.category,
    this.avatarUrl,
    this.coverUrl,
    this.url,
    this.isVerified = false,
    this.isOwner = false,
    this.isSubscribed = false,
    this.subscriberCount = 0,
  });

  SocialChannel copyWith({
    String? id,
    String? name,
    String? title,
    String? username,
    String? description,
    String? category,
    String? avatarUrl,
    String? coverUrl,
    String? url,
    bool? isVerified,
    bool? isOwner,
    bool? isSubscribed,
    int? subscriberCount,
  }) {
    return SocialChannel(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      username: username ?? this.username,
      description: description ?? this.description,
      category: category ?? this.category,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      url: url ?? this.url,
      isVerified: isVerified ?? this.isVerified,
      isOwner: isOwner ?? this.isOwner,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      subscriberCount: subscriberCount ?? this.subscriberCount,
    );
  }
}
