class SocialUser {
  final String id;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? userName;
  final String? avatarUrl;
  final String? coverUrl;
  final String? genderText;
  final String? birthday;
  final int? followersCount;
  final String? about;
  final bool isAdmin;
  final bool isOwner;
  final bool isFriend;
  final bool isFollowing;

  const SocialUser({
    required this.id,
    this.displayName,
    this.firstName,
    this.lastName,
    this.userName,
    this.avatarUrl,
    this.coverUrl,
    this.genderText,
    this.birthday,
    this.followersCount,
    this.about,
    this.isAdmin = false,
    this.isOwner = false,
    this.isFriend = false,
    this.isFollowing = false,
  });

  SocialUser copyWith({
    String? id,
    String? displayName,
    String? firstName,
    String? lastName,
    String? userName,
    String? avatarUrl,
    String? coverUrl,
    String? genderText,
    String? birthday,
    int? followersCount,
    String? about,
    bool? isAdmin,
    bool? isOwner,
    bool? isFriend,
    bool? isFollowing,
  }) {
    return SocialUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      genderText: genderText ?? this.genderText,
      birthday: birthday ?? this.birthday,
      followersCount: followersCount ?? this.followersCount,
      about: about ?? this.about,
      isAdmin: isAdmin ?? this.isAdmin,
      isOwner: isOwner ?? this.isOwner,
      isFriend: isFriend ?? this.isFriend,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}
//
