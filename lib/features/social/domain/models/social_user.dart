class SocialUser {
  final String id;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? userName;
  final String? avatarUrl;
  final String? coverUrl;
  final bool isAdmin;
  final bool isOwner;

  const SocialUser({
    required this.id,
    this.displayName,
    this.firstName,
    this.lastName,
    this.userName,
    this.avatarUrl,
    this.coverUrl,
    this.isAdmin = false,
    this.isOwner = false,
  });

  SocialUser copyWith({
    String? id,
    String? displayName,
    String? firstName,
    String? lastName,
    String? userName,
    String? avatarUrl,
    String? coverUrl,
    bool? isAdmin,
    bool? isOwner,
  }) {
    return SocialUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      isAdmin: isAdmin ?? this.isAdmin,
      isOwner: isOwner ?? this.isOwner,
    );
  }
}
//
