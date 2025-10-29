class SocialUserProfile {
  final String id;

  // Tên / hiển thị
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? userName;

  // Ảnh
  final String? avatarUrl;
  final String? coverUrl;

  // Thống kê
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final int friendsCount; // mutual_friends_count trong API

  // Trạng thái xác thực
  final bool isVerified;

  // Thông tin mô tả cá nhân
  final String? about;
  final String? work;                // working / currently_working
  final String? education;           // school
  final String? city;                // city
  final String? country;             // country_id (tạm để dạng string id)
  final String? website;             // website
  final String? birthday;            // birthday (chuỗi yyyy-mm-dd hoặc "0000-00-00")
  final String? relationshipStatus;  // relationship_id (chuỗi mã)

  // Thêm info để hiển thị trong header
  final String? genderText;          // "Nam giới"
  final String? lastSeenText;        // "3 m", "2h trước", ...
  final bool isFollowing;            // mình có follow người này không
  final bool isFollowingMe;          // họ có follow mình không

  const SocialUserProfile({
    required this.id,
    this.displayName,
    this.firstName,
    this.lastName,
    this.userName,
    this.avatarUrl,
    this.coverUrl,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.friendsCount = 0,
    this.isVerified = false,
    this.about,
    this.work,
    this.education,
    this.city,
    this.country,
    this.website,
    this.birthday,
    this.relationshipStatus,
    this.genderText,
    this.lastSeenText,
    this.isFollowing = false,
    this.isFollowingMe = false,
  });

  factory SocialUserProfile.fromJson(Map<String, dynamic> json) {
    // helpers cục bộ dùng để ép kiểu an toàn
    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) {
        final parsed = int.tryParse(v);
        if (parsed != null) return parsed;
      }
      return 0;
    }

    bool _toBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().trim().toLowerCase();
      return s == '1' || s == 'true';
    }

    String? _toCleanString(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      if (s.isEmpty ||
          s == '0' ||
          s == '0000-00-00') {
        return null;
      }
      return s;
    }

    return SocialUserProfile(
      id: json['id']?.toString() ??
          json['user_id']?.toString() ??
          '',

      // tên / hiển thị
      displayName: _toCleanString(
          json['displayName'] ??
              json['name']
      ) ??
          _toCleanString(
              [
                if (_toCleanString(json['firstName']) != null)
                  _toCleanString(json['firstName']),
                if (_toCleanString(json['lastName']) != null)
                  _toCleanString(json['lastName']),
              ].whereType<String>().join(' ')
          ) ??
          _toCleanString(json['username']) ??
          _toCleanString(json['userName']),

      firstName: _toCleanString(
          json['firstName'] ?? json['first_name']),
      lastName: _toCleanString(
          json['lastName'] ?? json['last_name']),
      userName: _toCleanString(
          json['userName'] ?? json['username'] ?? json['user_name']),

      // avatar / cover
      avatarUrl: _toCleanString(
          json['avatarUrl'] ?? json['avatar_full'] ?? json['avatar']),
      coverUrl: _toCleanString(
          json['coverUrl'] ?? json['cover_full'] ?? json['cover']),

      // stats
      followersCount: _toInt(
          json['followersCount'] ??
              json['followers_count'] ??
              json['followers'] ??
              (json['details'] is Map
                  ? (json['details']['followers_count'])
                  : null)),
      followingCount: _toInt(
          json['followingCount'] ??
              json['following_count'] ??
              json['following'] ??
              (json['details'] is Map
                  ? (json['details']['following_count'])
                  : null)),
      postsCount: _toInt(
          json['postsCount'] ??
              json['post_count'] ??
              json['posts'] ??
              (json['details'] is Map
                  ? (json['details']['post_count'])
                  : null)),
      friendsCount: _toInt(
          json['friendsCount'] ??
              json['mutual_friends_count'] ??
              (json['details'] is Map
                  ? (json['details']['mutual_friends_count'])
                  : null)),

      // verify
      isVerified: _toBool(
        json['isVerified'] ??
            json['is_verified'] ??
            json['verified'],
      ),

      // profile info
      about: _toCleanString(json['about']),
      work: _toCleanString(
        json['work'] ??
            json['working'] ??
            json['currently_working'],
      ),
      education: _toCleanString(
        json['education'] ??
            json['school'],
      ),
      city: _toCleanString(json['city']),
      country: _toCleanString(
        json['country'] ??
            json['country_id'],
      ),
      website: _toCleanString(json['website']),
      birthday: _toCleanString(json['birthday']),
      relationshipStatus: _toCleanString(
        json['relationshipStatus'] ??
            json['relationship_id'],
      ),

      // extra info cho header
      genderText: _toCleanString(
        json['genderText'] ??
            json['gender_text'],
      ),
      lastSeenText: _toCleanString(
        json['lastSeenText'] ??
            json['lastseen_time_text'],
      ),
      isFollowing: _toBool(
        json['isFollowing'] ??
            json['is_following'],
      ),
      isFollowingMe: _toBool(
        json['isFollowingMe'] ??
            json['is_following_me'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,

      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'userName': userName,

      'avatarUrl': avatarUrl,
      'coverUrl': coverUrl,

      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'friendsCount': friendsCount,

      'isVerified': isVerified,

      'about': about,
      'work': work,
      'education': education,
      'city': city,
      'country': country,
      'website': website,
      'birthday': birthday,
      'relationshipStatus': relationshipStatus,

      'genderText': genderText,
      'lastSeenText': lastSeenText,
      'isFollowing': isFollowing,
      'isFollowingMe': isFollowingMe,
    };
  }
}
