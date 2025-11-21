class SocialEventUser {
  final String? userId;
  final String? username;
  final String? name;
  final String? avatar;
  final String? cover;
  final String? url;

  SocialEventUser({
    this.userId,
    this.username,
    this.name,
    this.avatar,
    this.cover,
    this.url,
  });

  factory SocialEventUser.fromJson(Map<String, dynamic> json) {
    return SocialEventUser(
      userId: json['user_id']?.toString(),
      username: json['username'],
      name: json['name'],
      avatar: json['avatar'],
      cover: json['cover'],
      url: json['url'],
    );
  }
}
