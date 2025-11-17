class SocialGetPage {
  final int pageId;
  final int ownerUserId;
  final String username;
  final String name;           // page_title / name hiển thị
  final String pageName;       // page_name (slug)
  final String? description;   // page_description / about
  final String avatarUrl;
  final String coverUrl;
  final String url;
  final String category;
  final String? subCategory;

  final int usersPost;
  final int likesCount;
  final double rating;
  final bool isVerified;
  final bool isPageOwner;
  final bool isLiked;
  final bool isReported;

  final String? registered;    // "9/2025"
  final String? type;          // "page"

  // Social links
  final String? website;
  final String? facebook;
  final String? instagram;
  final String? youtube;

  const SocialGetPage({
    required this.pageId,
    required this.ownerUserId,
    required this.username,
    required this.name,
    required this.pageName,
    this.description,
    required this.avatarUrl,
    required this.coverUrl,
    required this.url,
    required this.category,
    this.subCategory,
    required this.usersPost,
    required this.likesCount,
    required this.rating,
    required this.isVerified,
    required this.isPageOwner,
    required this.isLiked,
    required this.isReported,
    this.registered,
    this.type,
    this.website,
    this.facebook,
    this.instagram,
    this.youtube,
  });

  factory SocialGetPage.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    bool _toBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().toLowerCase();
      return s == '1' || s == 'true';
    }

    return SocialGetPage(
      pageId: _toInt(json['page_id']),
      ownerUserId: _toInt(json['user_id']),
      username: (json['username'] ?? '') as String,
      name: (json['name'] ?? json['page_title'] ?? '') as String,
      pageName: (json['page_name'] ?? '') as String,
      description: (json['about'] ?? json['page_description']) as String?,
      avatarUrl: (json['avatar'] ?? '') as String,
      coverUrl: (json['cover'] ?? '') as String,
      url: (json['url'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      subCategory: json['page_sub_category'] as String?,
      usersPost: _toInt(json['users_post']),
      likesCount: _toInt(json['likes']),
      rating: _toDouble(json['rating']),
      isVerified: _toBool(json['is_verified'] ?? json['verified']),
      isPageOwner: _toBool(json['is_page_onwer']),
      isLiked: _toBool(json['is_liked']),
      isReported: _toBool(json['is_reported']),
      registered: json['registered'] as String?,
      type: json['type'] as String?,
      website: json['website'] as String?,
      facebook: json['facebook'] as String?,
      instagram: json['instgram'] as String?, // API sai chính tả
      youtube: json['youtube'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page_id': pageId,
      'user_id': ownerUserId,
      'username': username,
      'name': name,
      'page_name': pageName,
      'about': description,
      'avatar': avatarUrl,
      'cover': coverUrl,
      'url': url,
      'category': category,
      'page_sub_category': subCategory,
      'users_post': usersPost,
      'likes': likesCount,
      'rating': rating,
      'is_verified': isVerified ? 1 : 0,
      'is_page_onwer': isPageOwner ? 1 : 0,
      'is_liked': isLiked ? 1 : 0,
      'is_reported': isReported,
      'registered': registered,
      'type': type,
      'website': website,
      'facebook': facebook,
      'instgram': instagram,
      'youtube': youtube,
    };
  }

  static List<SocialGetPage> listFromJson(List<dynamic> data) {
    return data
        .map((e) => SocialGetPage.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
class SocialArticleCategory {
  final int id;
  final String name;

  const SocialArticleCategory({
    required this.id,
    required this.name,
  });

  factory SocialArticleCategory.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return SocialArticleCategory(
      id: _toInt(json['id']),
      name: (json['name'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
    };
  }

  static List<SocialArticleCategory> listFromJson(List<dynamic> list) {
    return list
        .map((e) => SocialArticleCategory.fromJson(
      e as Map<String, dynamic>,
    ))
        .toList();
  }
}
