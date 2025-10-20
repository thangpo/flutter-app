class SocialUser {
  final String id;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? userName;
  final String? avatarUrl;
  final String? coverUrl;

  const SocialUser({
    required this.id,
    this.displayName,
    this.firstName,
    this.lastName,
    this.userName,
    this.avatarUrl,
    this.coverUrl,
  });

  SocialUser copyWith({
    String? id,
    String? displayName,
    String? firstName,
    String? lastName,
    String? userName,
    String? avatarUrl,
    String? coverUrl,
  }) {
    return SocialUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
    );
  }
}
//
