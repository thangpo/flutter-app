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
  final int friendsCount;

  // Trạng thái xác thực
  final bool isVerified;

  // Thông tin mô tả cá nhân
  final String? about;
  final String? work;               // working / currently_working
  final String? education;          // school
  final String? address;            // <--- MỚI (thay cho city/country ở UI)
  final String? city;               // (giữ để tương thích, không dùng ở UI)
  final String? country;            // (giữ để tương thích, không dùng ở UI)
  final String? website;
  final String? birthday;           // yyyy-mm-dd hoặc "0000-00-00"
  final String? relationshipStatus; // relationship_id (chuỗi mã)

  // Thêm info hiển thị
  final String? genderText;
  final String? lastSeenText;
  final bool isFollowing;
  final bool isFollowingMe;

  // Trạng thái block user (NEW)
  final bool isBlocked;

  // ===== Trường phục vụ cập nhật (KHÔNG lấy từ API, KHÔNG lưu local) =====
  final String? currentPassword;    // <-- NEW: chỉ dùng khi đổi mật khẩu
  final String? newPassword;        // <-- NEW: chỉ dùng khi đổi mật khẩu

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
    this.address,
    this.city,
    this.country,
    this.website,
    this.birthday,
    this.relationshipStatus,
    this.genderText,
    this.lastSeenText,
    this.isFollowing = false,
    this.isFollowingMe = false,
    this.currentPassword,           // <-- NEW
    this.newPassword,               // <-- NEW
    this.isBlocked = false,         // <-- NEW
  });

  factory SocialUserProfile.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
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
      if (s.isEmpty || s == '0' || s == '0000-00-00') return null;
      return s;
    }

    // --- NEW: parse trạng thái block từ nhiều key có thể xuất hiện ---
    bool _toBlocked(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().trim().toLowerCase();
      if (s == '1' || s == 'true' || s == 'blocked' || s == 'block') return true;
      if (s == '0' || s == 'false' || s == 'un-blocked' || s == 'unblocked') return false;
      return false;
    }

    return SocialUserProfile(
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? '',

      // hiển thị
      displayName: _toCleanString(json['displayName'] ?? json['name']) ??
          _toCleanString([
            _toCleanString(json['firstName'] ?? json['first_name']),
            _toCleanString(json['lastName']  ?? json['last_name']),
          ].whereType<String>().join(' ')) ??
          _toCleanString(json['username']) ??
          _toCleanString(json['userName']),
      firstName: _toCleanString(json['firstName'] ?? json['first_name']),
      lastName : _toCleanString(json['lastName']  ?? json['last_name']),
      userName : _toCleanString(json['userName']  ?? json['username'] ?? json['user_name']),

      // ảnh
      avatarUrl: _toCleanString(json['avatarUrl'] ?? json['avatar_full'] ?? json['avatar']),
      coverUrl : _toCleanString(json['coverUrl']  ?? json['cover_full']  ?? json['cover']),

      // stats
      followersCount: _toInt(json['followersCount'] ?? json['followers_count'] ?? json['followers'] ?? (json['details'] is Map ? (json['details']['followers_count']) : null)),
      followingCount: _toInt(json['followingCount'] ?? json['following_count'] ?? json['following'] ?? (json['details'] is Map ? (json['details']['following_count']) : null)),
      postsCount    : _toInt(json['postsCount']    ?? json['post_count']     ?? json['posts']     ?? (json['details'] is Map ? (json['details']['post_count']) : null)),
      friendsCount  : _toInt(json['friendsCount']  ?? json['mutual_friends_count'] ?? (json['details'] is Map ? (json['details']['mutual_friends_count']) : null)),

      // verify
      isVerified: _toBool(json['isVerified'] ?? json['is_verified'] ?? json['verified']),

      // profile info
      about      : _toCleanString(json['about']),
      work       : _toCleanString(json['work'] ?? json['working'] ?? json['currently_working']),
      education  : _toCleanString(json['education'] ?? json['school']),
      address    : _toCleanString(json['address'] ?? json['location']),
      city       : _toCleanString(json['city']),
      country    : _toCleanString(json['country'] ?? json['country_id']),
      website    : _toCleanString(json['website']),
      birthday   : _toCleanString(json['birthday']),
      relationshipStatus: _toCleanString(json['relationshipStatus'] ?? json['relationship_id']),

      // header info
      genderText     : _toCleanString(json['genderText'] ?? json['gender_text']),
      lastSeenText   : _toCleanString(json['lastSeenText'] ?? json['lastseen_time_text']),
      isFollowing    : _toBool(json['isFollowing'] ?? json['is_following']),
      isFollowingMe  : _toBool(json['isFollowingMe'] ?? json['is_following_me']),

      // mật khẩu KHÔNG lấy từ server
      currentPassword: null,
      newPassword    : null,

      // --- NEW: block status ---
      isBlocked: _toBlocked(
        json['isBlocked'] ??
            json['is_blocked'] ??
            json['blocked'] ??
            json['block_status'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id'              : id,
      'displayName'     : displayName,
      'firstName'       : firstName,
      'lastName'        : lastName,
      'userName'        : userName,
      'avatarUrl'       : avatarUrl,
      'coverUrl'        : coverUrl,
      'followersCount'  : followersCount,
      'followingCount'  : followingCount,
      'postsCount'      : postsCount,
      'friendsCount'    : friendsCount,
      'isVerified'      : isVerified,
      'about'           : about,
      'work'            : work,
      'education'       : education,
      'address'         : address,
      'city'            : city,
      'country'         : country,
      'website'         : website,
      'birthday'        : birthday,
      'relationshipStatus': relationshipStatus,
      'genderText'      : genderText,
      'lastSeenText'    : lastSeenText,
      'isFollowing'     : isFollowing,
      'isFollowingMe'   : isFollowingMe,
      // NEW: serialize trạng thái block (dùng nội bộ)
      'isBlocked'       : isBlocked,
      // CHÚ Ý: Không serialize currentPassword/newPassword để tránh lưu trữ nhạy cảm
    };
  }

  // copyWith
  SocialUserProfile copyWith({
    String? id,
    String? displayName,
    String? firstName,
    String? lastName,
    String? userName,
    String? avatarUrl,
    String? coverUrl,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    int? friendsCount,
    bool? isVerified,
    String? about,
    String? work,
    String? education,
    String? address,
    String? city,
    String? country,
    String? website,
    String? birthday,
    String? relationshipStatus,
    String? genderText,
    String? lastSeenText,
    bool? isFollowing,
    bool? isFollowingMe,
    String? currentPassword,   // <-- NEW
    String? newPassword,       // <-- NEW
    bool? isBlocked,           // <-- NEW
  }) {
    return SocialUserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      firstName  : firstName  ?? this.firstName,
      lastName   : lastName   ?? this.lastName,
      userName   : userName   ?? this.userName,
      avatarUrl  : avatarUrl  ?? this.avatarUrl,
      coverUrl   : coverUrl   ?? this.coverUrl,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount    : postsCount     ?? this.postsCount,
      friendsCount  : friendsCount   ?? this.friendsCount,
      isVerified    : isVerified     ?? this.isVerified,
      about     : about     ?? this.about,
      work      : work      ?? this.work,
      education : education ?? this.education,
      address   : address   ?? this.address,
      city      : city      ?? this.city,
      country   : country   ?? this.country,
      website   : website   ?? this.website,
      birthday  : birthday  ?? this.birthday,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
      genderText: genderText ?? this.genderText,
      lastSeenText: lastSeenText ?? this.lastSeenText,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollowingMe: isFollowingMe ?? this.isFollowingMe,
      currentPassword: currentPassword ?? this.currentPassword, // <-- NEW
      newPassword    : newPassword    ?? this.newPassword,      // <-- NEW
      isBlocked      : isBlocked      ?? this.isBlocked,        // <-- NEW
    );
  }
}
