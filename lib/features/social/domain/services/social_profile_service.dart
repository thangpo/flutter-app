import 'package:dio/dio.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_profile_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

/// Gói thông tin tổng hợp của 1 user khi load profile
class SocialProfileBundle {
  final SocialUser? user;
  final List<SocialUser> followers;
  final List<SocialUser> following;
  final List<dynamic> likedPages;

  const SocialProfileBundle({
    required this.user,
    required this.followers,
    required this.following,
    required this.likedPages,
  });
}

/// Kết quả phân trang post
class SocialFeedPage {
  final List<SocialPost> posts;
  final String? lastId; // id cuối cùng trong page -> dùng để loadMore

  const SocialFeedPage({
    required this.posts,
    required this.lastId,
  });
}

class SocialProfileService {
  final SocialProfileRepository socialRepository;
  SocialProfileService({required this.socialRepository});

  // ===== Helpers nội bộ =====

  String? _absoluteUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return trimmed;
    }

    // build lại URL tuyệt đối từ socialBaseUrl
    final base = AppConstants.socialBaseUrl.endsWith('/')
        ? AppConstants.socialBaseUrl.substring(
      0,
      AppConstants.socialBaseUrl.length - 1,
    )
        : AppConstants.socialBaseUrl;

    if (trimmed.startsWith('/')) {
      return '$base$trimmed';
    }
    return '$base/$trimmed';
  }

  int _toIntSafe(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is String) {
      final parsed = int.tryParse(v);
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  double? _toDoubleSafe(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) {
      final parsed = double.tryParse(v);
      return parsed;
    }
    return null;
  }

  Map<String, dynamic> _normalizeUserMap(Map<String, dynamic> raw) {
    // chuẩn hoá avatar/cover thành URL tuyệt đối
    final user = Map<String, dynamic>.from(raw);

    if (user['avatar'] != null) {
      user['avatar'] = _absoluteUrl(user['avatar']?.toString());
    }
    if (user['profile_picture'] != null) {
      user['profile_picture'] =
          _absoluteUrl(user['profile_picture']?.toString());
    }
    if (user['cover'] != null) {
      user['cover'] = _absoluteUrl(user['cover']?.toString());
    }
    if (user['cover_picture'] != null) {
      user['cover_picture'] =
          _absoluteUrl(user['cover_picture']?.toString());
    }

    return user;
  }

  SocialUser _mapToSocialUser(Map<String, dynamic> raw) {
    final data = Map<String, dynamic>.from(raw);

    final firstName = data['first_name']?.toString();
    final lastName = data['last_name']?.toString();

    final displayName = (() {
      // ưu tiên 'name'
      if (data['name'] != null && data['name'].toString().isNotEmpty) {
        return data['name'].toString();
      }
      // fallback ghép first + last
      final combined = [
        firstName ?? '',
        lastName ?? '',
      ].join(' ').trim();
      if (combined.isNotEmpty) return combined;
      // fallback username
      if (data['username'] != null) {
        return data['username'].toString();
      }
      return null;
    })();

    return SocialUser(
      id: data['user_id']?.toString() ?? data['id']?.toString() ?? '',
      displayName: displayName,
      firstName: firstName,
      lastName: lastName,
      userName: data['username']?.toString(),
      avatarUrl: (data['avatar'] ?? data['profile_picture'])?.toString(),
      coverUrl: (data['cover'] ?? data['cover_picture'])?.toString(),
    );
  }

  SocialPost? _mapToSocialPost(Map<String, dynamic> raw) {
    final data = Map<String, dynamic>.from(raw);

    // ----- publisher / người đăng -----
    Map<String, dynamic> pub = {};
    if (data['publisher'] is Map<String, dynamic>) {
      pub = _normalizeUserMap(Map<String, dynamic>.from(data['publisher']));
    }

    final publisherName = (pub['name'] ??
        pub['username'] ??
        [
          pub['first_name'] ?? '',
          pub['last_name'] ?? '',
        ].join(' ').trim())
        .toString();

    final publisherAvatar =
    (pub['avatar'] ?? pub['profile_picture'])?.toString();

    // ----- chuẩn hoá file đính kèm -----
    if (data['postFile'] != null) {
      data['postFile'] = _absoluteUrl(data['postFile']?.toString());
    }
    if (data['postFile_full'] != null) {
      data['postFile_full'] =
          _absoluteUrl(data['postFile_full']?.toString());
    }

    final postFileType = data['postFile_type']?.toString();
    final postFile = data['postFile']?.toString();
    final postFileFull = data['postFile_full']?.toString();
    final postFileName = data['postFileName']?.toString();

    // ----- hình ảnh đa ảnh -----
    final List<String> imageUrls = [];
    // nếu backend đã chuẩn hoá sẵn
    if (data['photo_multi_normalized'] is List) {
      for (final item in (data['photo_multi_normalized'] as List)) {
        final absUrl = _absoluteUrl(item.toString()) ?? item.toString();
        imageUrls.add(absUrl);
      }
    } else if (data['photo_multi'] is List) {
      for (final item in (data['photo_multi'] as List)) {
        if (item is String) {
          imageUrls.add(_absoluteUrl(item) ?? item);
        } else if (item is Map<String, dynamic>) {
          final imgRaw = item['image']?.toString();
          if (imgRaw != null) {
            imageUrls.add(_absoluteUrl(imgRaw) ?? imgRaw);
          }
        }
      }
    }

    // nếu postFileType là ảnh thì cũng add vào imageUrls
    if (postFileType == 'image' || postFileType == 'photo') {
      final imgCandidate = postFileFull ?? postFile;
      if (imgCandidate != null && imgCandidate.isNotEmpty) {
        final absUrl = _absoluteUrl(imgCandidate) ?? imgCandidate;
        if (!imageUrls.contains(absUrl)) {
          imageUrls.add(absUrl);
        }
      }
    }

    final String? firstImage =
    imageUrls.isNotEmpty ? imageUrls.first : null;

    // ----- phân loại media khác -----
    String? videoUrl;
    String? audioUrl;
    String? fileUrl;
    if (postFileType == 'video') {
      final v = postFileFull ?? postFile;
      videoUrl = (v != null) ? (_absoluteUrl(v) ?? v) : null;
    } else if (postFileType == 'audio') {
      final a = postFileFull ?? postFile;
      audioUrl = (a != null) ? (_absoluteUrl(a) ?? a) : null;
    } else {
      final f = postFileFull ?? postFile;
      fileUrl = (f != null) ? (_absoluteUrl(f) ?? f) : null;
    }

    // ----- reaction / like -----
    final int reactionCount = _toIntSafe(
      data['reaction_count'] ??
          data['post_likes'] ??
          data['post_likes_count'],
      fallback: 0,
    );

    final Map<String, int> reactionBreakdown = {};
    String myReaction = '';

    if (data['reaction'] is Map<String, dynamic>) {
      final r = data['reaction'] as Map<String, dynamic>;
      for (final k in ['Like', 'Love', 'HaHa', 'Wow', 'Sad', 'Angry']) {
        reactionBreakdown[k] = _toIntSafe(r[k], fallback: 0);
      }
      if (r['type'] != null && r['type'].toString().isNotEmpty) {
        myReaction = r['type'].toString();
      } else if (r['is_reacted'] == true && r['type'] == null) {
        myReaction = 'Like';
      }
    } else {
      if (data['is_liked'] == true) {
        myReaction = 'Like';
      }
    }

    final int commentCount = _toIntSafe(
      data['post_comments'] ?? data['comments_count'],
      fallback: 0,
    );
    final int shareCount = _toIntSafe(
      data['post_shares'] ?? data['shares_count'],
      fallback: 0,
    );

    // ----- poll -----
    List<Map<String, dynamic>>? pollOptions;
    if (data['poll_options'] is List) {
      pollOptions = (data['poll_options'] as List)
          .whereType<Map<String, dynamic>>()
          .map((opt) {
        return {
          'text': opt['text'] ?? opt['option'] ?? '',
          'percentage_num':
          opt['percentage_num'] ?? opt['percentage'] ?? 0,
        };
      }).toList();
    } else if (data['poll'] is Map<String, dynamic>) {
      final pollMap = data['poll'] as Map<String, dynamic>;
      if (pollMap['options'] is List) {
        pollOptions = (pollMap['options'] as List)
            .whereType<Map<String, dynamic>>()
            .map((opt) {
          return {
            'text': opt['text'] ?? opt['option'] ?? '',
            'percentage_num':
            opt['percentage_num'] ?? opt['percentage'] ?? 0,
          };
        }).toList();
      }
    }

    // ----- product info -----
    bool hasProduct = false;
    String? productTitle;
    List<String>? productImages;
    double? productPrice;
    String? productCurrency;
    String? productDescription;
    int? ecommerceProductId;
    String? productSlug;

    if (data['product'] is Map<String, dynamic>) {
      final p = data['product'] as Map<String, dynamic>;
      hasProduct = true;

      productTitle = p['name']?.toString();
      productDescription = p['description']?.toString();
      productCurrency = p['currency']?.toString();
      productPrice = _toDoubleSafe(p['price'] ?? p['product_price']);
      ecommerceProductId =
          _toIntSafe(p['id'] ?? p['product_id'], fallback: 0);
      productSlug = p['slug']?.toString();

      if (p['images'] is List) {
        productImages = (p['images'] as List)
            .map((e) => _absoluteUrl(e.toString()) ?? e.toString())
            .toList();
      } else if (p['image'] != null) {
        final img = p['image'].toString();
        productImages = [
          _absoluteUrl(img) ?? img,
        ];
      }
    } else {
      // fallback kiểu khác
      if (data['product_id'] != null || data['product_title'] != null) {
        hasProduct = true;
        ecommerceProductId =
            _toIntSafe(data['product_id'], fallback: 0);
        productTitle = data['product_title']?.toString();
        productDescription =
            data['product_description']?.toString();
        productSlug = data['product_slug']?.toString();
        productCurrency = data['product_currency']?.toString();
        productPrice = _toDoubleSafe(data['product_price']);

        if (data['product_images'] is List) {
          productImages = (data['product_images'] as List)
              .map((e) => _absoluteUrl(e.toString()) ?? e.toString())
              .toList();
        }
      }
    }

    // ----- shared / repost -----
    SocialPost? sharedPost;
    if (data['shared_info'] is Map<String, dynamic>) {
      sharedPost = _mapToSocialPost(
        Map<String, dynamic>.from(data['shared_info']),
      );
    } else if (data['shared_post'] is Map<String, dynamic>) {
      sharedPost = _mapToSocialPost(
        Map<String, dynamic>.from(data['shared_post']),
      );
    }

    // ----- postType -----
    final postType = data['postType']?.toString() ??
        data['post_type']?.toString() ??
        postFileType;

    // build SocialPost model
    return SocialPost(
      id: (data['post_id'] ?? data['id'] ?? '').toString(),
      text: data['postText']?.toString() ?? data['text']?.toString(),
      userName: publisherName,
      userAvatar: publisherAvatar,
      timeText: data['time_text']?.toString(),

      imageUrls: imageUrls,
      imageUrl: firstImage,
      fileUrl: fileUrl,
      fileName: postFileName,
      videoUrl: videoUrl,
      audioUrl: audioUrl,
      postType: postType,
      sharedPost: sharedPost,

      reactionCount: reactionCount,
      myReaction: myReaction,
      reactionBreakdown: reactionBreakdown,
      commentCount: commentCount,
      shareCount: shareCount,

      hasProduct: hasProduct,
      productTitle: productTitle,
      productImages: productImages,
      productPrice: productPrice,
      productCurrency: productCurrency,
      productDescription: productDescription,
      ecommerceProductId: ecommerceProductId,
      productSlug: productSlug,

      pollOptions: pollOptions,
    );
  }

  // ======= PUBLIC METHODS =======

  /// Lấy thông tin profile hiện tại của user đăng nhập
  /// + followers
  /// + following
  /// + liked pages
  Future<SocialProfileBundle> getCurrentUserProfile() async {
    final apiRes = await socialRepository.fetchUserProfile();

    // lỗi token / network / status code != 200
    if (apiRes.isSuccess != true ||
        apiRes.response == null ||
        apiRes.response is! Response ||
        apiRes.response!.statusCode != 200) {
      return const SocialProfileBundle(
        user: null,
        followers: [],
        following: [],
        likedPages: [],
      );
    }

    final Response res = apiRes.response!;
    final body = res.data;

    if (body is! Map<String, dynamic>) {
      return const SocialProfileBundle(
        user: null,
        followers: [],
        following: [],
        likedPages: [],
      );
    }

    // user_data
    SocialUser? userModel;
    if (body['user_data'] is Map<String, dynamic>) {
      final normalizedUser = _normalizeUserMap(
        Map<String, dynamic>.from(body['user_data']),
      );
      userModel = _mapToSocialUser(normalizedUser);
    }

    // followers
    final List<SocialUser> followersList = [];
    if (body['followers'] is List) {
      for (final f in (body['followers'] as List)) {
        if (f is! Map<String, dynamic>) continue;
        final normalizedFollower = _normalizeUserMap(
          Map<String, dynamic>.from(f),
        );
        followersList.add(_mapToSocialUser(normalizedFollower));
      }
    }

    // following
    final List<SocialUser> followingList = [];
    if (body['following'] is List) {
      for (final f in (body['following'] as List)) {
        if (f is! Map<String, dynamic>) continue;
        final normalizedFollowing = _normalizeUserMap(
          Map<String, dynamic>.from(f),
        );
        followingList.add(_mapToSocialUser(normalizedFollowing));
      }
    }

    // liked pages
    final likedPagesRaw =
    (body['liked_pages'] is List) ? body['liked_pages'] as List : <dynamic>[];

    return SocialProfileBundle(
      user: userModel,
      followers: followersList,
      following: followingList,
      likedPages: likedPagesRaw,
    );
  }

  /// Lấy danh sách post của user, có phân trang
  Future<SocialFeedPage> getUserPosts({
    required String targetUserId,
    int limit = 10,
    String? afterPostId,
  }) async {
    final apiRes = await socialRepository.fetchUserPosts(
      targetUserId: targetUserId,
      limit: limit,
      afterPostId: afterPostId,
    );

    if (apiRes.isSuccess != true ||
        apiRes.response == null ||
        apiRes.response is! Response ||
        apiRes.response!.statusCode != 200) {
      return const SocialFeedPage(posts: [], lastId: null);
    }

    final Response res = apiRes.response!;
    final body = res.data;

    final postsResult = <SocialPost>[];
    String? lastId;

    if (body is Map<String, dynamic>) {
      // backend đôi khi trả 'posts_data', đôi khi 'data', đôi khi 'posts'
      final rawPosts = body['posts_data'] ?? body['data'] ?? body['posts'];

      if (rawPosts is List) {
        for (final raw in rawPosts) {
          if (raw is! Map<String, dynamic>) continue;
          final post = _mapToSocialPost(Map<String, dynamic>.from(raw));
          if (post != null) {
            postsResult.add(post);
            lastId = post.id; // id cuối cùng để phân trang tiếp
          }
        }
      }
    }

    return SocialFeedPage(
      posts: postsResult,
      lastId: lastId,
    );
  }
}
