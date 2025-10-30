import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/exception/api_error_handler.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_comment.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_group.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_feed_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user_profile.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_group_join_request.dart';

bool _isImageUrl(String url) {
  final u = url.toLowerCase();
  return u.endsWith('.png') ||
      u.endsWith('.jpg') ||
      u.endsWith('.jpeg') ||
      u.endsWith('.gif') ||
      u.endsWith('.webp');
}

class SocialRepository {
  final DioClient dioClient;
  final SharedPreferences sharedPreferences;
  SocialRepository({
    required this.dioClient,
    required this.sharedPreferences,
  });

  String? _getSocialAccessToken() {
    return sharedPreferences.getString(AppConstants.socialAccessToken);
  }

  String? _getSocialUserId() {
    return sharedPreferences.getString(AppConstants.socialUserId);
  }

  String? _absoluteUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return trimmed;
    }
    final base = AppConstants.socialBaseUrl.endsWith('/')
        ? AppConstants.socialBaseUrl
            .substring(0, AppConstants.socialBaseUrl.length - 1)
        : AppConstants.socialBaseUrl;
    if (trimmed.startsWith('/')) {
      return '$base$trimmed';
    }
    return '$base/$trimmed';
  }

  String? _normalizeMediaUrl(dynamic raw) {
    final normalized = _normalizeString(raw);
    if (normalized == null) return null;
    return _absoluteUrl(normalized) ?? normalized;
  }

  String? _normalizeString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (str.isEmpty) return null;
    final lower = str.toLowerCase();
    if (lower == 'null' || lower == 'undefined') return null;
    return str;
  }

  String? _extractProductSlug(Map product) {
    const keys = [
      'slug',
      'product_slug',
      'slug_url',
      'slug_name',
      'slug_en',
      'slug_bn',
      'slug_ar',
      'slug_vi',
    ];
    for (final key in keys) {
      final normalized = _normalizeString(product[key]);
      if (normalized != null) return normalized;
    }
    return null;
  }

  //Feeds
  Future<ApiResponseModel<Response>> fetchNewsFeed({
    int limit = 10,
    String? afterPostId,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialPostsUri}?access_token=$token';

      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'type': 'get_news_feed',
        'limit': limit.toString(),
        if (afterPostId != null && afterPostId.isNotEmpty)
          'after_post_id': afterPostId,
      });

      final Response res = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );

      return ApiResponseModel.withSuccess(res);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> fetchGroupFeed({
    required String groupId,
    int limit = 10,
    String? afterPostId,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialPostsUri}?access_token=$token';

      final Map<String, dynamic> payload = {
        'server_key': AppConstants.socialServerKey,
        'type': 'get_group_posts',
        'group_id': groupId,
        'id': groupId,
        'limit': limit.toString(),
      };
      if (afterPostId != null && afterPostId.isNotEmpty) {
        payload['after_post_id'] = afterPostId;
      }

      final form = FormData.fromMap(payload);
      final Response res = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );

      return ApiResponseModel.withSuccess(res);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  SocialFeedPage parseNewsFeed(Response res) {
    final data = res.data;
    final list = <SocialPost>[];
    String? lastId;

    if (data is Map) {
      final posts = (data['data'] ?? data['posts'] ?? data['news_feed']);
      if (posts is List) {
        for (final raw in posts) {
          if (raw is! Map) continue;
          final SocialPost? post =
              _mapToSocialPost(Map<String, dynamic>.from(raw));
          if (post != null) {
            list.add(post);
            lastId = post.id;
          }
        }
      }
    }
    return SocialFeedPage(posts: list, lastId: lastId);
  }

  //thêm
  // THÊM vào class SocialRepository
  Future<ApiResponseModel<Response>> fetchUserProfile({
    String? targetUserId, // null = lấy của mình
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token?.isNotEmpty != true) {
        return ApiResponseModel.withError('Missing Social access_token');
      }

      final String? userId = targetUserId ?? _getSocialUserId();

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialGetUserDataUri}?access_token=$token';

      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'user_id': userId,
        'fetch': 'user_data,followers,following,liked_pages',
        'send_notify': '1',
      });

      final res = await dioClient.post(
        url,
        data: form,
        options: Options(
          contentType: Headers.multipartFormDataContentType,
        ),
      );

      return ApiResponseModel.withSuccess(res);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  // THÊM vào class SocialRepository
  Future<ApiResponseModel<Response>> fetchUserPosts({
    required String targetUserId,
    int limit = 10,
    String? afterPostId,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String userIdToLoad = targetUserId.isNotEmpty
          ? targetUserId
          : (_getSocialUserId() ?? '');

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialPostsUri}?access_token=$token';

      final formMap = <String, dynamic>{
        'server_key': AppConstants.socialServerKey,
        'type': 'get_user_posts',
        'id': userIdToLoad,
        'limit': limit.toString(),
      };

      if (afterPostId != null && afterPostId.isNotEmpty) {
        formMap['after_post_id'] = afterPostId;
      }

      final form = FormData.fromMap(formMap);

      final Response res = await dioClient.post(
        url,
        data: form,
        options: Options(
          contentType: Headers.multipartFormDataContentType,
        ),
      );

      return ApiResponseModel.withSuccess(res);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }
  // THÊM vào class SocialRepository
  SocialUserProfile? parseUserProfile(Response res) {
    final data = res.data;
    if (data is! Map) return null;

    // Lấy block user_data từ response
    Map? raw;
    if (data['user_data'] is Map) {
      raw = data['user_data'] as Map;
    } else if (data['data'] is Map) {
      raw = data['data'] as Map;
    }
    if (raw == null) return null;

    final map = Map<String, dynamic>.from(raw);

    // Helpers cục bộ
    String? _cleanStr(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      if (s.isEmpty || s == '0' || s == '0000-00-00') return null;
      return s;
    }

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

    // id
    final String id = (map['user_id'] ?? map['id'] ?? '').toString();
    if (id.isEmpty) return null;

    // tên cơ bản
    String? firstName = _cleanStr(map['first_name'] ?? map['fname']);
    String? lastName  = _cleanStr(map['last_name'] ?? map['lname']);
    String? userName  = _cleanStr(map['username'] ?? map['user_name']);

    // displayName ưu tiên: name -> first+last -> username
    String? displayName = _cleanStr(map['name']);
    if (displayName == null || displayName.isEmpty) {
      final combined = [
        if (firstName != null && firstName.isNotEmpty) firstName,
        if (lastName  != null && lastName.isNotEmpty) lastName,
      ].join(' ').trim();

      if (combined.isNotEmpty) {
        displayName = combined;
      } else if (userName != null && userName.isNotEmpty) {
        displayName = userName;
      }
    }

    // avatar & cover
    final avatarRaw = (map['avatar_full'] ??
        map['avatar_original'] ??
        map['avatar'] ??
        '').toString();
    final coverRaw = (map['cover_full'] ??
        map['cover_original'] ??
        map['cover'] ??
        '').toString();

    final String? avatarUrl = _absoluteUrl(avatarRaw);
    final String? coverUrl  = _absoluteUrl(coverRaw);

    // details block (đếm follower/following/post...)
    final details = (map['details'] is Map)
        ? Map<String, dynamic>.from(map['details'])
        : <String, dynamic>{};

    final int followersCount = _toInt(
      details['followers_count'] ?? map['followers'],
    );
    final int followingCount = _toInt(
      details['following_count'] ?? map['following'],
    );
    final int postsCount = _toInt(
      details['post_count'] ?? map['posts_count'] ?? map['posts'],
    );
    final int friendsCount = _toInt(
      details['mutual_friends_count'],
    );

    // xác thực
    final bool isVerified = _toBool(map['is_verified'] ?? map['verified']);

    // mô tả cá nhân / giới thiệu
    final String? about = _cleanStr(map['about']);

    // thêm các field mở rộng
    final String? work = _cleanStr(
      map['working'] ?? map['currently_working'],
    );
    final String? education = _cleanStr(map['school']);
    final String? city = _cleanStr(map['city']);
    // country_id là mã số, mình nhét tạm vào country cho UI hiển thị, bạn có thể đổi sau
    final String? country = _cleanStr(map['country_id']);
    final String? website = _cleanStr(map['website']);
    final String? birthday = _cleanStr(map['birthday']);
    final String? relationshipStatus = _cleanStr(
      map['relationship_id'],
    );

    final String? genderText = _cleanStr(map['gender_text']);
    final String? lastSeenText = _cleanStr(map['lastseen_time_text']);

    final bool isFollowing = _toBool(map['is_following']);
    final bool isFollowingMe = _toBool(map['is_following_me']);

    return SocialUserProfile(
      id: id,
      displayName: displayName,
      firstName: firstName,
      lastName: lastName,
      userName: userName,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
      followersCount: followersCount,
      followingCount: followingCount,
      postsCount: postsCount,
      friendsCount: friendsCount,
      isVerified: isVerified,
      about: about,
      work: work,
      education: education,
      city: city,
      country: country,
      website: website,
      birthday: birthday,
      relationshipStatus: relationshipStatus,
      genderText: genderText,
      lastSeenText: lastSeenText,
      isFollowing: isFollowing,
      isFollowingMe: isFollowingMe,
    );
  }



  //Stories
  Future<ApiResponseModel<Response>> fetchStories({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final token = sharedPreferences.getString(AppConstants.socialAccessToken);
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialGetStoriesUri}?access_token=$token';

      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'limit': limit.toString(),
        'offset': offset.toString(),
      });

      final Response res = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );

      return ApiResponseModel.withSuccess(res);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  List<SocialStory> parseStories(Response res) {
    final data = res.data;
    final list = <SocialStory>[];

    if (data is Map) {
      final stories = (data['stories'] ?? data['data']);
      if (stories is List) {
        for (final it in stories) {
          if (it is Map) {
            list.add(SocialStory.fromJson(Map<String, dynamic>.from(it)));
          }
        }
      }
    }
    return list;
  }

  Future<ApiResponseModel<Response>> createStory({
    required String filePath,
    required String fileType,
    String? coverPath,
    String? storyTitle,
    String? storyDescription,
    String? highlightHash,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialCreateStoryUri}?access_token=$token';

      final Map<String, dynamic> formMap = {
        'server_key': AppConstants.socialServerKey,
        'file_type': fileType,
        'file': await MultipartFile.fromFile(
          filePath,
          filename: _fileNameFromPath(filePath),
        ),
        if (coverPath != null && coverPath.isNotEmpty)
          'cover': await MultipartFile.fromFile(
            coverPath,
            filename: _fileNameFromPath(coverPath),
          ),
        if (storyTitle != null && storyTitle.trim().isNotEmpty)
          'story_title': storyTitle.trim(),
        if (storyDescription != null && storyDescription.trim().isNotEmpty)
          'story_description': storyDescription.trim(),
        if (highlightHash != null && highlightHash.trim().isNotEmpty)
          'highlight_hash': highlightHash.trim(),
      };

      final Response res = await dioClient.post(
        url,
        data: FormData.fromMap(formMap),
        options: Options(contentType: 'multipart/form-data'),
      );

      return ApiResponseModel.withSuccess(res);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> fetchUserStories({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialGetUserStoriesUri}?access_token=$token';

      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'limit': limit.toString(),
        'offset': offset.toString(),
      });

      final Response res = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );

      return ApiResponseModel.withSuccess(res);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> fetchStoryById({
    required String id,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialGetStoryByIdUri}?access_token=$token';

      final Response res = await dioClient.post(
        url,
        data: FormData.fromMap({
          'server_key': AppConstants.socialServerKey,
          'id': id,
        }),
        options: Options(contentType: 'multipart/form-data'),
      );

      return ApiResponseModel.withSuccess(res);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> fetchStoryViews({
    required String storyId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialGetStoryViewsUri}?access_token=$token';

      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'story_id': storyId,
        'limit': limit.toString(),
        'offset': offset.toString(),
      });

      final Response res = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );

      return ApiResponseModel.withSuccess(res);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> fetchStoryReactions({
    required String storyId,
    String? reactionFilter,
    int? limit,
    int? offset,
  }) async {
    try {
      final String? token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialGetStoryReactionsUri}?access_token=$token';

      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'type': 'story',
        'id': storyId,
        if (reactionFilter != null && reactionFilter.isNotEmpty)
          'reaction': reactionFilter,
        if (limit != null) 'limit': '$limit',
        if (offset != null) 'offset': '$offset',
      });

      final Response res = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(res);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  SocialStory? parseStoryDetail(Response res) {
    final data = res.data;
    if (data is Map) {
      final dynamic storyData =
          data['story'] ?? data['story_data'] ?? data['data'];
      if (storyData is Map) {
        final map = Map<String, dynamic>.from(storyData);
        return SocialStory.fromJson(map);
      }
      if (storyData is List && storyData.isNotEmpty) {
        final first = storyData.first;
        if (first is Map) {
          return SocialStory.fromJson(Map<String, dynamic>.from(first));
        }
      }
    }
    return null;
  }

  SocialStoryViewersPage parseStoryViews(
    Response res, {
    int currentOffset = 0,
    int limit = 20,
  }) {
    final Map<String, SocialStoryViewer> aggregated =
        <String, SocialStoryViewer>{};
    final Map<String, List<_ViewerReactionEntry>> reactionBuckets =
        <String, List<_ViewerReactionEntry>>{};
    const int maxReactionsPerViewer = 6;
    int reactionSequence = 0;

    void _registerReaction(
      String key,
      String label, {
      int? rowId,
      DateTime? timestamp,
    }) {
      if (label.isEmpty) return;
      final List<_ViewerReactionEntry> bucket =
          reactionBuckets.putIfAbsent(key, () => <_ViewerReactionEntry>[]);
      reactionSequence++;
      final double orderKey = rowId != null
          ? rowId.toDouble()
          : (timestamp != null
              ? timestamp.millisecondsSinceEpoch.toDouble()
              : reactionSequence.toDouble());
      bucket.add(_ViewerReactionEntry(
        label: label,
        orderKey: orderKey,
        sequence: reactionSequence,
      ));
      bucket.sort((a, b) {
        final int cmp = b.orderKey.compareTo(a.orderKey);
        if (cmp != 0) return cmp;
        return b.sequence.compareTo(a.sequence);
      });
      if (bucket.length > maxReactionsPerViewer) {
        bucket.removeRange(maxReactionsPerViewer, bucket.length);
      }
    }

    void mergeViewer(
      SocialStoryViewer viewer, {
      int? rowId,
      DateTime? reactionTime,
    }) {
      final String key = viewer.userId.isNotEmpty ? viewer.userId : viewer.id;
      if (key.isEmpty) return;

      final List<String> labels = viewer.reactions.isNotEmpty
          ? List<String>.from(viewer.reactions)
          : (viewer.reaction.isNotEmpty
              ? <String>[viewer.reaction]
              : const <String>[]);

      if (labels.isNotEmpty) {
        final DateTime? stamp = reactionTime ?? viewer.viewedAt;
        for (int i = 0; i < labels.length; i++) {
          final String label = labels[i];
          final int? orderId = rowId != null ? rowId + i : null;
          _registerReaction(
            key,
            label,
            rowId: orderId,
            timestamp: stamp,
          );
        }
      }

      final List<_ViewerReactionEntry> bucket =
          reactionBuckets.putIfAbsent(key, () => <_ViewerReactionEntry>[]);
      final List<String> snapshot =
          bucket.map((entry) => entry.label).toList(growable: false);

      final SocialStoryViewer? existing = aggregated[key];
      if (existing == null) {
        final int? resolvedCount = viewer.reactionCount ??
            (snapshot.isNotEmpty ? snapshot.length : null);
        aggregated[key] = viewer.copyWith(
          reactions: snapshot,
          reactionCount: resolvedCount,
          reaction: snapshot.isNotEmpty ? snapshot.first : viewer.reaction,
        );
        return;
      }

      DateTime? viewedAt = existing.viewedAt;
      if (viewer.viewedAt != null &&
          (viewedAt == null || viewer.viewedAt!.isAfter(viewedAt))) {
        viewedAt = viewer.viewedAt;
      }

      final String? resolvedName =
          (existing.name?.isNotEmpty ?? false) ? existing.name : viewer.name;
      final String? resolvedAvatar = (existing.avatar?.isNotEmpty ?? false)
          ? existing.avatar
          : viewer.avatar;

      final int? resolvedCount = viewer.reactionCount ??
          existing.reactionCount ??
          (snapshot.isNotEmpty ? snapshot.length : existing.reactionCount);

      aggregated[key] = existing.copyWith(
        name: resolvedName,
        avatar: resolvedAvatar,
        isVerified: existing.isVerified || viewer.isVerified,
        viewedAt: viewedAt,
        reactions: snapshot,
        reactionCount: resolvedCount,
        reaction: snapshot.isNotEmpty ? snapshot.first : existing.reaction,
      );
    }

    String? _normalizedReactionKey(String? key) {
      if (key == null) return null;
      final String value = key.trim();
      if (value.isEmpty) return null;
      switch (value.toLowerCase()) {
        case '1':
        case 'like':
          return 'Like';
        case '2':
        case 'love':
          return 'Love';
        case '3':
        case 'haha':
          return 'HaHa';
        case '4':
        case 'wow':
          return 'Wow';
        case '5':
        case 'sad':
          return 'Sad';
        case '6':
        case 'angry':
          return 'Angry';
        default:
          return null;
      }
    }

    bool _looksLikeViewerMap(Map<String, dynamic> map) {
      if (map.containsKey('user_id') ||
          map.containsKey('username') ||
          map.containsKey('name')) {
        return true;
      }
      if (map['user'] is Map<String, dynamic>) return true;
      if (map['user_data'] is Map<String, dynamic>) return true;
      return false;
    }

    int? _parseIntValue(dynamic raw) {
      if (raw == null) return null;
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw);
      return null;
    }

    DateTime? _parseTimestamp(dynamic raw) {
      final int? seconds = _parseIntValue(raw);
      if (seconds == null || seconds <= 0) return null;
      if (seconds > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(seconds, isUtc: true)
            .toLocal();
      }
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true)
          .toLocal();
    }

    void addViewer(dynamic raw, [String? reactionFallback]) {
      if (raw == null) return;
      if (raw is Map<String, dynamic>) {
        final Map<String, dynamic> payload = Map<String, dynamic>.from(raw);
        payload.putIfAbsent('reaction', () => reactionFallback);
        final int? reactionRowId = _parseIntValue(
          payload['row_id'] ??
              payload['reaction_id'] ??
              payload['story_reaction_id'] ??
              payload['story_react_id'] ??
              payload['view_id'],
        );
        final DateTime? reactionStamp = _parseTimestamp(
          payload['reaction_time'] ??
              payload['time'] ??
              payload['view_time'] ??
              payload['seen'],
        );
        mergeViewer(
          SocialStoryViewer.fromJson(payload),
          rowId: reactionRowId,
          reactionTime: reactionStamp,
        );
      } else if (raw is Map) {
        final Map<String, dynamic> payload = Map<String, dynamic>.from(raw);
        payload.putIfAbsent('reaction', () => reactionFallback);
        final int? reactionRowId = _parseIntValue(
          payload['row_id'] ??
              payload['reaction_id'] ??
              payload['story_reaction_id'] ??
              payload['story_react_id'] ??
              payload['view_id'],
        );
        final DateTime? reactionStamp = _parseTimestamp(
          payload['reaction_time'] ??
              payload['time'] ??
              payload['view_time'] ??
              payload['seen'],
        );
        mergeViewer(
          SocialStoryViewer.fromJson(payload),
          rowId: reactionRowId,
          reactionTime: reactionStamp,
        );
      }
    }

    void process(dynamic container, {String? reactionHint, int depth = 0}) {
      if (container == null || depth > 6) return;

      if (container is List) {
        for (final dynamic entry in container) {
          process(entry, reactionHint: reactionHint, depth: depth + 1);
        }
        return;
      }

      if (container is Map) {
        final Map<String, dynamic> map = container is Map<String, dynamic>
            ? container
            : Map<String, dynamic>.from(container);

        if (_looksLikeViewerMap(map)) {
          addViewer(map, reactionHint);
          return;
        }

        for (final MapEntry<String, dynamic> entry in map.entries) {
          final String key = entry.key;
          final String? nextReaction =
              _normalizedReactionKey(key) ?? reactionHint;
          process(entry.value, reactionHint: nextReaction, depth: depth + 1);
        }
        return;
      }
    }

    final dynamic root = res.data;
    if (root != null) {
      process(root);
    }

    final List<SocialStoryViewer> viewers = aggregated.values.toList()
      ..sort((a, b) {
        final DateTime aTime =
            a.viewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bTime =
            b.viewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

    int? _extractTotal(dynamic source) {
      if (source == null) return null;
      if (source is num) return source.toInt();
      if (source is String) return int.tryParse(source);
      if (source is Map) {
        for (final String key in const <String>[
          'total',
          'count',
          'total_count',
          'total_views',
          'views_total'
        ]) {
          final int? value = _extractTotal(source[key]);
          if (value != null) return value;
        }
      }
      return null;
    }

    int? totalRaw;
    if (root is Map) {
      totalRaw = _extractTotal(root);
      if (totalRaw == null && root['data'] is Map) {
        totalRaw = _extractTotal(root['data']);
      }
    }

    final int total = totalRaw != null && totalRaw >= viewers.length
        ? totalRaw
        : viewers.length;
    final int nextOffset = currentOffset + viewers.length;

    return SocialStoryViewersPage(
      viewers: viewers,
      total: total,
      hasMore: false,
      nextOffset: nextOffset,
    );
  }

  Future<ApiResponseModel<Response>> reactToPost({
    required String postId,
    required String
        reaction, // '' = unreact, hoặc: Like/Love/HaHa/Wow/Sad/Angry
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialReactUri}?access_token=$token';

      String _mapReactionToId(String r) {
        switch (r) {
          case 'Like':
            return '1';
          case 'Love':
            return '2';
          case 'HaHa':
            return '3';
          case 'Wow':
            return '4';
          case 'Sad':
            return '5';
          case 'Angry':
            return '6';
          default:
            return '1';
        }
      }

      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'post_id': postId,
        'action': 'reaction',
        'reaction': reaction.isEmpty ? '1' : _mapReactionToId(reaction),
      });

      final resp = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(resp);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  // Post details
  Future<ApiResponseModel<Response>> fetchPostData({
    required String postId,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }
      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialGetPostDataUri}?access_token=$token';
      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'fetch': 'post_data',
        'post_id': postId,
        'add_view': '1',
      });
      final res = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(res);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> createPost({
    String? text,
    List<String>? imagePaths,
    String? videoPath,
    String? videoThumbnailPath,
    int privacy = 0,
    String? backgroundColorId,
    String? groupId,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }
      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialCreatePostUri}?access_token=$token';

      final Map<String, dynamic> fields = {
        'server_key': AppConstants.socialServerKey,
        'postPrivacy': '$privacy',
      };

      final String? trimmedText = text?.trim();
      if (trimmedText != null && trimmedText.isNotEmpty) {
        fields['postText'] = trimmedText;
      }

      if (backgroundColorId != null && backgroundColorId.isNotEmpty) {
        fields['post_color'] = backgroundColorId;
      }

      if (groupId != null && groupId.trim().isNotEmpty) {
        fields['group_id'] = groupId.trim();
      }

      final List<String> images = imagePaths ?? const [];
      if (images.isNotEmpty) {
        final List<MultipartFile> files = [];
        for (final path in images) {
          final p = path.trim();
          if (p.isEmpty) continue;
          files.add(await MultipartFile.fromFile(p));
        }
        if (files.isNotEmpty) {
          fields['postPhotos[]'] = files;
        }
      }

      if (videoPath != null && videoPath.isNotEmpty) {
        fields['postVideo'] = await MultipartFile.fromFile(videoPath);
        if (videoThumbnailPath != null && videoThumbnailPath.isNotEmpty) {
          fields['video_thumb'] =
              await MultipartFile.fromFile(videoThumbnailPath);
        }
      }

      final form = FormData.fromMap(fields);
      final res = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(res);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> sharePostOnTimeline({
    required String postId,
    String? text,
  }) async {
    try {
      final token = _getSocialAccessToken();
      final userId = _getSocialUserId();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError('Missing Social access_token');
      }
      if (userId == null || userId.isEmpty) {
        return ApiResponseModel.withError('Missing social user_id');
      }
      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialPostsUri}?access_token=$token';
      final Map<String, dynamic> payload = {
        'server_key': AppConstants.socialServerKey,
        'type': 'share_post_on_timeline',
        'id': postId,
        'user_id': userId,
      };
      final String? trimmed = text?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        payload['text'] = trimmed;
      }
      final form = FormData.fromMap(payload);
      final res = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(res);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  SocialPost? _mapToSocialPost(
    Map<String, dynamic> raw, {
    bool includeSharedInfo = true,
  }) {
    final map = Map<String, dynamic>.from(raw);
    final String id = (map['post_id'] ?? map['id'] ?? '').toString();
    if (id.isEmpty) return null;


    final String text =
        (map['postText_API'] ?? map['postText'] ?? '').toString();
    final String timeText =
        (map['post_time'] ?? map['time_text'] ?? '').toString();

    final Map pub =
        (map['publisher'] is Map) ? map['publisher'] as Map : const {};
    final String userName = (pub['name'] ?? pub['username'] ?? '').toString();
    final String? userAvatar = _normalizeMediaUrl(pub['avatar']);
    final String publisherId = (pub['user_id'] ??
        pub['id'] ??
        map['publisher_id'] ??
        map['user_id'] ??
        '')
        .toString();

    final List pm =
        (map['photo_multi'] is List) ? map['photo_multi'] as List : const [];
    final List<String> multiImages = <String>[];
    for (final item in pm.whereType<Map>()) {
      final String raw = (item['image'] ?? '').toString();
      if (raw.isEmpty || !_isImageUrl(raw)) continue;
      final String? resolved = _normalizeMediaUrl(raw);
      if (resolved != null) {
        multiImages.add(resolved);
      }
    }
    final String singleFull = (map['postFile_full'] ?? '').toString();
    final String? singleResolved =
        singleFull.isNotEmpty ? _normalizeMediaUrl(singleFull) : null;
    final List<String> imageUrls = <String>[
      ...multiImages,
      if (singleFull.isNotEmpty && _isImageUrl(singleFull))
        singleResolved ?? singleFull,
    ];

    final String fileUrlRaw =
        (map['postFile'] ?? map['postFile_full'] ?? '').toString();
    final String? fileUrl = _normalizeMediaUrl(fileUrlRaw);
    final String fileName = (map['postFileName'] ?? '').toString();

    String? videoUrl, audioUrl;
    if (fileUrl != null && fileUrl.isNotEmpty) {
      final u = fileUrl.toLowerCase();
      if (u.endsWith('.mp4') || u.endsWith('.mov') || u.endsWith('.m4v')) {
        videoUrl = fileUrl;
      } else if (u.endsWith('.mp3') || u.contains('/sounds/')) {
        audioUrl = fileUrl;
      }
    }

    final Map<String, dynamic> rx =
        _extractReactionMap(map['reaction'] ?? map['reactions']);
    final int reactionCount = _reactionCountFromMap(rx);
    final String myReaction = _reactionLabelFromMap(rx);
    final Map<String, int> reactionBreakdown = _reactionBreakdownFromMap(rx);

    final int commentCount = _resolveCount(<dynamic>[
      map['post_comments'],
      map['comments_count'],
      map['comment_count'],
      map['comments_num'],
      map['comments'],
      map['get_post_comments'],
    ]);

    final int shareCount = _resolveCount(<dynamic>[
      map['post_share'],
      map['postShare'],
      map['share_count'],
      map['shared_count'],
      map['shares_count'],
      map['shares'],
      map['post_shares'],
      map['shared'],
    ]);

    final bool groupAdmin = _isTruthy(map['group_admin']);
    Map<String, dynamic>? groupMap;
    final dynamic groupRaw = map['group_recipient'] ??
        map['group_data'] ??
        map['group'] ??
        map['group_info'];
    if (groupRaw is Map && groupRaw.isNotEmpty) {
      groupMap = Map<String, dynamic>.from(groupRaw);
    }

    String? groupId = _normalizeString(map['group_id']);
    if (groupId == null || groupId.isEmpty || groupId == '0') {
      final String? fallbackId = groupMap != null
          ? _normalizeString(groupMap['group_id'] ?? groupMap['id'])
          : null;
      if (fallbackId != null && fallbackId.isNotEmpty && fallbackId != '0') {
        groupId = fallbackId;
      } else {
        groupId = null;
      }
    }

    final String? groupTitle = groupMap != null
        ? _normalizeString(groupMap['group_title'] ?? groupMap['title'])
        : null;
    final String? groupName = groupMap != null
        ? _normalizeString(groupMap['group_name'] ?? groupMap['name'])
        : null;
    final String? groupUrl = groupMap != null
        ? _normalizeString(groupMap['url'] ?? groupMap['group_url'])
        : null;
    final String? groupAvatar = groupMap != null
        ? _normalizeMediaUrl(groupMap['avatar'] ?? groupMap['avatar_org'])
        : null;
    final String? groupCover = groupMap != null
        ? _normalizeMediaUrl(groupMap['cover'] ?? groupMap['cover_full'])
        : null;
    final bool isGroupPost = groupId != null &&
        groupId.isNotEmpty &&
        (groupMap != null ||
            _isTruthy(map['group_recipient_exists']) ||
            _isTruthy(map['is_group_post']));

    final Map product =
        (map['product'] is Map) ? map['product'] as Map : const {};
    final bool hasProduct = product.isNotEmpty;
    final String productName = (product['name'] ?? '').toString();
    final List pImgsRaw =
        (product['images'] is List) ? product['images'] as List : const [];
    final List<String> productImages = <String>[];
    for (final img in pImgsRaw) {
      String raw = '';
      if (img is Map) {
        raw = (img['image'] ?? img['src'] ?? '').toString();
      } else {
        raw = img.toString();
      }
      if (raw.isEmpty) continue;
      final String? resolved = _normalizeMediaUrl(raw);
      if (resolved != null) {
        productImages.add(resolved);
      }
    }
    final double? productPrice = product['price'] is num
        ? (product['price'] as num).toDouble()
        : double.tryParse((product['price'] ?? '').toString());
    final String? productCurrency = _normalizeString(product['currency']);
    final String? productDescription = _normalizeString(
      product['description_api'] ??
          product['description'] ??
          product['short_description'] ??
          product['desc'],
    );
    final dynamic productIdRaw = product['ecommer_prod_id'] ??
        product['ecommerce_prod_id'] ??
        product['product_id'] ??
        product['id'];
    final int? ecommerceProductId = () {
      if (productIdRaw == null) return null;
      if (productIdRaw is int) return productIdRaw;
      if (productIdRaw is num) return productIdRaw.toInt();
      return int.tryParse(productIdRaw.toString());
    }();
    final String? productSlug = _extractProductSlug(product);

    final String? postType = (map['postType']?.toString().isNotEmpty ?? false)
        ? map['postType'].toString()
        : null;

    SocialPost? sharedPost;
    if (includeSharedInfo) {
      final sharedRaw = map['shared_info'];
      if (sharedRaw is Map && sharedRaw.isNotEmpty) {
        sharedPost = _mapToSocialPost(
          Map<String, dynamic>.from(sharedRaw),
          includeSharedInfo: false,
        );
      }
    }

    return SocialPost(
      id: id,
      publisherId: publisherId.isNotEmpty ? publisherId : null,
      userName: userName.isNotEmpty ? userName : null,
      userAvatar: userAvatar,
      text: text.isNotEmpty ? text : null,
      timeText: timeText.isNotEmpty ? timeText : null,
      imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
      imageUrls: imageUrls,
      fileUrl: fileUrl,
      fileName: fileName.isNotEmpty ? fileName : null,
      videoUrl: videoUrl,
      audioUrl: audioUrl,
      postType: postType,
      sharedPost: sharedPost,
      isGroupPost: isGroupPost,
      isGroupAdmin: groupAdmin,
      groupId: groupId,
      groupName: groupName ?? groupTitle,
      groupTitle: groupTitle ?? groupName,
      groupUrl: groupUrl,
      groupAvatar: groupAvatar,
      groupCover: groupCover,
      reactionCount: reactionCount,
      myReaction: myReaction,
      reactionBreakdown: reactionBreakdown,
      commentCount: commentCount,
      shareCount: shareCount,
      hasProduct: hasProduct,
      productTitle: productName.isNotEmpty ? productName : null,
      productImages: productImages.isNotEmpty ? productImages : null,
      productPrice: productPrice,
      productCurrency: productCurrency,
      productDescription: productDescription,
      ecommerceProductId: ecommerceProductId,
      productSlug: productSlug,
      pollOptions: (map['options'] is List)
          ? List<Map<String, dynamic>>.from(map['options'])
          : null,
    );
  }

  //profile
  Future<ApiResponseModel<Response>> fetchCurrentUserProfile() async {
    try {
      final token = _getSocialAccessToken();
      final userId = _getSocialUserId();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }
      if (userId == null || userId.isEmpty) {
        return ApiResponseModel.withError(
            'The social network account does not exist');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialGetUserDataUri}?access_token=$token';

      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'fetch': 'user_data',
        'user_id': userId,
      });

      final res = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(res);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  SocialPost? parsePostData(Response res) {
    final data = res.data;
    Map? m;
    if (data is Map) {
      if (data['post_data'] is Map) {
        m = data['post_data'] as Map;
      } else if (data['data'] is List && (data['data'] as List).isNotEmpty) {
        final first = (data['data'] as List).first;
        if (first is Map) m = first;
      } else if (data['data'] is Map) {
        m = data['data'] as Map;
      }
    }
    if (m == null) return null;
    return _mapToSocialPost(Map<String, dynamic>.from(m));
  }

  List<SocialComment> parsePostComments(Response res) {
    final list = <SocialComment>[];
    final data = res.data;
    List? comments;
    if (data is Map) {
      final pd = data['post_data'];
      if (pd is Map && pd['get_post_comments'] is List) {
        comments = pd['get_post_comments'] as List;
      } else if (data['get_post_comments'] is List) {
        comments = data['get_post_comments'] as List;
      } else if (data['comments'] is List) {
        comments = data['comments'] as List;
      } else if (data['data'] is List) {
        comments = data['data'] as List;
      }
    }
    if (comments != null) {
      for (final c in comments) {
        if (c is Map) {
          final m = Map<String, dynamic>.from(c);
          final String id = (m['id'] ?? m['comment_id'] ?? '').toString();
          final String text = (m['text'] ?? m['comment'] ?? '').toString();
          final Map pub =
              (m['publisher'] is Map) ? m['publisher'] as Map : const {};
          final String userName =
              (pub['name'] ?? pub['username'] ?? '').toString();
          final String userAvatar = (pub['avatar'] ?? '').toString();

          final String timeText =
              (m['time_text'] ?? m['time'] ?? '').toString();
          final String cFile =
              (m['c_file'] ?? m['file'] ?? m['image'] ?? m['image_url'] ?? '')
                  .toString();
          final String record = (m['record'] ?? m['audio'] ?? '').toString();
          // createdAt: KHAI BÁO DUY NHẤT (đã bỏ bản trùng)
          final DateTime? createdAt =
              _parseCommentDate(m['time'] ?? m['comment_time'] ?? '');
          final int? repliesCount = (m['replies_count'] != null)
              ? int.tryParse('${m['replies_count']}')
              : null;

          final Map<String, dynamic> reactionMap = _extractReactionMap(
            m['reaction'] ?? m['comment_reaction'] ?? m['reactions'],
          );
          int reactionCount = _reactionCountFromMap(reactionMap);
          if (reactionCount == 0) {
            final likes =
                int.tryParse('${m['comment_likes'] ?? m['likes'] ?? ''}') ?? 0;
            final wonders =
                int.tryParse('${m['comment_wonders'] ?? m['wonders'] ?? ''}') ??
                    0;
            reactionCount = likes + wonders;
          }
          String myReaction = _reactionLabelFromMap(reactionMap);
          if (myReaction.isEmpty) {
            if (_isTruthy(m['is_comment_liked'])) {
              myReaction = 'Like';
            } else if (_isTruthy(m['is_comment_wondered'])) {
              myReaction = 'Wow';
            }
          }

          if (id.isEmpty) continue;
          list.add(SocialComment(
            id: id,
            text: text.isNotEmpty ? text : null,
            userName: userName.isNotEmpty ? userName : null,
            userAvatar: userAvatar.isNotEmpty ? userAvatar : null,
            timeText: timeText.isNotEmpty ? timeText : null,
            repliesCount: repliesCount,
            imageUrl: cFile.isNotEmpty ? cFile : null,
            audioUrl: record.isNotEmpty ? record : null,
            reactionCount: reactionCount,
            myReaction: myReaction,
            createdAt: createdAt,
          ));
        }
      }
    }
    return list;
  }

  List<SocialComment> parseCommentReplies(Response res) {
    final list = <SocialComment>[];
    final data = res.data;
    List? replies;
    if (data is Map) {
      if (data['replies'] is List) {
        replies = data['replies'] as List;
      } else if (data['data'] is List) {
        replies = data['data'] as List;
      }
    }
    if (replies != null) {
      for (final c in replies) {
        if (c is Map) {
          final m = Map<String, dynamic>.from(c);
          final String id = (m['id'] ?? m['comment_id'] ?? '').toString();
          final String text = (m['text'] ?? m['comment'] ?? '').toString();
          final Map pub =
              (m['publisher'] is Map) ? m['publisher'] as Map : const {};
          final String userName =
              (pub['name'] ?? pub['username'] ?? '').toString();
          final String userAvatar = (pub['avatar'] ?? '').toString();
          final String timeText =
              (m['time_text'] ?? m['time'] ?? '').toString();
          final String cFile =
              (m['c_file'] ?? m['file'] ?? m['image'] ?? m['image_url'] ?? '')
                  .toString();
          final String record = (m['record'] ?? m['audio'] ?? '').toString();

          // BỔ SUNG createdAt CHO REPLIES (trước đây thiếu)
          final DateTime? createdAt =
              _parseCommentDate(m['time'] ?? m['comment_time'] ?? '');

          final Map<String, dynamic> reactionMap = _extractReactionMap(
            m['reaction'] ?? m['comment_reaction'] ?? m['reactions'],
          );
          int reactionCount = _reactionCountFromMap(reactionMap);
          if (reactionCount == 0) {
            final likes =
                int.tryParse('${m['comment_likes'] ?? m['likes'] ?? ''}') ?? 0;
            final wonders =
                int.tryParse('${m['comment_wonders'] ?? m['wonders'] ?? ''}') ??
                    0;
            reactionCount = likes + wonders;
          }
          String myReaction = _reactionLabelFromMap(reactionMap);
          if (myReaction.isEmpty && _isTruthy(m['is_comment_liked'])) {
            myReaction = 'Like';
          }

          if (id.isEmpty) continue;
          list.add(SocialComment(
            id: id,
            text: text.isNotEmpty ? text : null,
            userName: userName.isNotEmpty ? userName : null,
            userAvatar: userAvatar.isNotEmpty ? userAvatar : null,
            timeText: timeText.isNotEmpty ? timeText : null,
            imageUrl: cFile.isNotEmpty ? cFile : null,
            audioUrl: record.isNotEmpty ? record : null,
            reactionCount: reactionCount,
            myReaction: myReaction,
            createdAt: createdAt, // giờ đã có biến
          ));
        }
      }
    }
    return list;
  }

  Future<ApiResponseModel<Response>> fetchCommentReplies({
    required String commentId,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }
      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialCommentsUri}?access_token=$token';
      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'type': 'fetch_comments_reply',
        'comment_id': commentId,
      });
      final res = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(res);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> fetchComments({
    required String postId,
    int? limit,
    int? offset,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }
      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialCommentsUri}?access_token=$token';
      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'type': 'fetch_comments',
        'post_id': postId,
        if (limit != null) 'limit': '$limit',
        if (offset != null) 'offset': '$offset',
      });
      final res = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(res);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> createComment({
    required String postId,
    required String text,
    String? imagePath,
    String? audioPath,
    String? imageUrl,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }
      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialCommentsUri}?access_token=$token';
      final Map<String, dynamic> fields = {
        'server_key': AppConstants.socialServerKey,
        'type': 'create',
        'post_id': postId,
        'text': text,
      };
      if (imageUrl != null && imageUrl.isNotEmpty) {
        fields['image_url'] = imageUrl;
      }
      if (imagePath != null && imagePath.isNotEmpty) {
        fields['image'] = await MultipartFile.fromFile(imagePath);
      }
      if (audioPath != null && audioPath.isNotEmpty) {
        fields['audio'] = await MultipartFile.fromFile(audioPath);
      }
      final form = FormData.fromMap(fields);
      final res = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(res);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> createReply({
    required String commentId,
    required String text,
    String? imagePath,
    String? audioPath,
    String? imageUrl,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }
      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialCommentsUri}?access_token=$token';
      final Map<String, dynamic> fields = {
        'server_key': AppConstants.socialServerKey,
        'type': 'create_reply',
        'comment_id': commentId,
        'text': text,
      };
      if (imagePath != null && imagePath.isNotEmpty) {
        fields['image'] = await MultipartFile.fromFile(imagePath);
      }
      if (audioPath != null && audioPath.isNotEmpty) {
        fields['audio'] = await MultipartFile.fromFile(audioPath);
      }
      if (imageUrl != null && imageUrl.isNotEmpty) {
        fields['image_url'] = imageUrl;
      }
      final form = FormData.fromMap(fields);
      final res = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(res);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> reactToComment({
    required String commentId,
    required String reaction,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }
      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialCommentsUri}?access_token=$token';
      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'type': 'reaction_comment',
        'comment_id': commentId,
        'reaction': reaction.isEmpty ? '0' : _mapReactionLabelToId(reaction),
      });
      final resp = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(resp);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> reactToStory({
    required String storyId,
    required String reaction,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialReactStoryUri}?access_token=$token';

      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'id': storyId,
        'reaction': reaction.isEmpty ? '0' : _mapReactionLabelToId(reaction),
      });

      final resp = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(resp);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> reactToReply({
    required String replyId,
    required String reaction,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }
      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialCommentsUri}?access_token=$token';
      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'type': 'reaction_reply',
        'reply_id': replyId,
        'reaction': reaction.isEmpty ? '0' : _mapReactionLabelToId(reaction),
      });
      final resp = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(resp);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }







  Future<ApiResponseModel<Response>> reactToPostWithAction({
    required String postId,
    required String reaction,
    required String action, // 'reaction' or 'dislike'
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialReactUri}?access_token=$token';

      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'post_id': postId,
        'action': action,
        'reaction': reaction.isEmpty ? '1' : _mapReactionLabelToId(reaction),
      });

      final resp = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(resp);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  // Groups
  Future<ApiResponseModel<Response>> createGroup({
    required String groupName,
    required String groupTitle,
    required String category,
    String? about,
    String? groupSubCategory,
    Map<String, dynamic>? customFields,
    String? privacy,
    String? joinPrivacy,
    String? avatarPath,
    String? coverPath,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialCreateGroupUri}?access_token=$token';

      final Map<String, dynamic> fields = <String, dynamic>{
        'server_key': AppConstants.socialServerKey,
        'group_name': groupName,
        'group_title': groupTitle,
        'category': category,
        if (about != null && about.trim().isNotEmpty) 'about': about.trim(),
        if (groupSubCategory != null && groupSubCategory.trim().isNotEmpty)
          'group_sub_category': groupSubCategory.trim(),
        if (privacy != null && privacy.trim().isNotEmpty)
          'privacy': privacy.trim(),
        if (joinPrivacy != null && joinPrivacy.trim().isNotEmpty)
          'join_privacy': joinPrivacy.trim(),
      };

      if (customFields != null && customFields.isNotEmpty) {
        for (final MapEntry<String, dynamic> entry in customFields.entries) {
          final key = entry.key.trim();
          if (key.isEmpty) continue;
          final value = entry.value;
          if (value == null) continue;
          fields[key] = value;
        }
      }

      if (avatarPath != null && avatarPath.isNotEmpty) {
        fields['avatar'] = await MultipartFile.fromFile(avatarPath);
      }
      if (coverPath != null && coverPath.isNotEmpty) {
        fields['cover'] = await MultipartFile.fromFile(coverPath);
      }

      final form = FormData.fromMap(fields);
      final Response resp = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(resp);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> updateGroup({
    required String groupId,
    String? groupTitle,
    String? about,
    String? category,
    String? groupSubCategory,
    Map<String, dynamic>? customFields,
    String? privacy,
    String? joinPrivacy,
    String? avatarPath,
    String? coverPath,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialUpdateGroupUri}?access_token=$token';

      final Map<String, dynamic> fields = <String, dynamic>{
        'server_key': AppConstants.socialServerKey,
        'group_id': groupId,
      };

      void addIfNotEmpty(String key, String? value) {
        if (value != null && value.trim().isNotEmpty) {
          fields[key] = value.trim();
        }
      }

      addIfNotEmpty('group_title', groupTitle);
      addIfNotEmpty('about', about);
      addIfNotEmpty('category', category);
      addIfNotEmpty('group_sub_category', groupSubCategory);
      addIfNotEmpty('privacy', privacy);
      addIfNotEmpty('join_privacy', joinPrivacy);

      if (customFields != null && customFields.isNotEmpty) {
        for (final MapEntry<String, dynamic> entry in customFields.entries) {
          final key = entry.key.trim();
          if (key.isEmpty) continue;
          final value = entry.value;
          if (value == null) continue;
          fields[key] = value;
        }
      }

      if (avatarPath != null && avatarPath.isNotEmpty) {
        fields['avatar'] = await MultipartFile.fromFile(avatarPath);
      }
      if (coverPath != null && coverPath.isNotEmpty) {
        fields['cover'] = await MultipartFile.fromFile(coverPath);
      }

      final form = FormData.fromMap(fields);
      final Response resp = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(resp);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> joinGroup({
    required String groupId,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialJoinGroupUri}?access_token=$token';
      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'group_id': groupId,
      });
      final Response resp = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(resp);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> fetchMyGroups({
    required String type,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialGetMyGroupsUri}?access_token=$token';

      final Map<String, dynamic> payload = {
        'server_key': AppConstants.socialServerKey,
        'type': type,
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      final String? userId = _getSocialUserId();
      if (userId != null && userId.isNotEmpty) {
        payload['user_id'] = userId;
      }
      final form = FormData.fromMap(payload);
      final Response resp = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(resp);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> deleteGroupMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialDeleteGroupMemberUri}?access_token=$token';
      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'group_id': groupId,
        'user_id': userId,
      });
      final Response resp = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(resp);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> reportGroup({
    required String groupId,
    required String text,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialReportGroupUri}?access_token=$token';
      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'group_id': groupId,
        'text': text,
      });
      final Response resp = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(resp);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> deleteGroup({
    required String groupId,
    required String password,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialDeleteGroupUri}?access_token=$token';
      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'group_id': groupId,
        'password': password,
      });
      final Response resp = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(resp);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> fetchGroupJoinRequests({
    required String groupId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialGroupsUri}?access_token=$token';
      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'type': 'get_requests',
        'group_id': groupId,
        'limit': limit.toString(),
        'offset': offset.toString(),
      });
      final Response resp = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(resp);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> respondGroupJoinRequest({
    required String groupId,
    required String userId,
    String? requestId,
    required bool accept,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialGroupsUri}?access_token=$token';
      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'type': accept ? 'accept_request' : 'delete_request',
        'group_id': groupId,
        'user_id': userId,
        if (requestId != null && requestId.isNotEmpty) 'request_id': requestId,
      });
      final Response resp = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(resp);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> fetchCommunityGroups({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialGetCommunityUri}?access_token=$token';

      final Map<String, dynamic> payload = {
        'server_key': AppConstants.socialServerKey,
        'fetch': 'groups',
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      final String? userId = _getSocialUserId();
      if (userId != null && userId.isNotEmpty) {
        payload['user_id'] = userId;
      }
      final form = FormData.fromMap(payload);
      final Response resp = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(resp);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> searchSocial({
    String searchKey = '',
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialSearch}?access_token=$token';

      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'search_key': searchKey,
      });

      final Response resp = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(resp);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> fetchGroupMembers({
    required String groupId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialGetGroupMembersUri}?access_token=$token';
      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'group_id': groupId,
        'limit': limit.toString(),
        'offset': offset.toString(),
      });
      final Response resp = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(resp);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> fetchNotInGroupMembers({
    required String groupId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialGetNotInGroupMembersUri}?access_token=$token';
      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'group_id': groupId,
        'limit': limit.toString(),
        'offset': offset.toString(),
      });
      final Response resp = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(resp);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> inviteGroupMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialNotificationsUri}?access_token=$token';
      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'type': 'create',
        'recipient_id': userId,
        'type_name': 'invited_you_to_the_group',
        'group_id': groupId,
      });
      final Response resp = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(resp);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> fetchGroupData({
    required String groupId,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialGetGroupDataUri}?access_token=$token';

      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'group_id': groupId,
      });

      final Response resp = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );

      return ApiResponseModel.withSuccess(resp);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<ApiResponseModel<Response>> makeGroupAdmin({
    required String groupId,
    required String userId,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
            'Please log in to your social network account');
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialMakeGroupAdminUri}?access_token=$token';
      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'group_id': groupId,
        'user_id': userId,
      });
      final Response resp = await dioClient.post(
        url,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponseModel.withSuccess(resp);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  SocialGroup? parseGroup(Response res) {
    final data = res.data;
    if (data is Map) {
      final Map? direct = data['group_data'] as Map?;
      if (direct != null) {
        final group = _parseGroupMap(direct);
        if (group != null) return group;
      }
      if (data['data'] is Map) {
        final inner = data['data'] as Map;
        final Map? groupMap =
            inner['group_data'] as Map? ?? inner['group'] as Map?;
        if (groupMap != null) {
          final group = _parseGroupMap(groupMap);
          if (group != null) return group;
        }
      }
      if (data['data'] is List) {
        final list = data['data'] as List;
        for (final item in list) {
          if (item is Map) {
            final group = _parseGroupMap(item);
            if (group != null) return group;
          }
        }
      }
    } else if (data is List) {
      for (final item in data) {
        if (item is Map) {
          final group = _parseGroupMap(item);
          if (group != null) return group;
        }
      }
    }
    return null;
  }

  List<SocialGroup> parseGroups(Response res) {
    final List<SocialGroup> result = <SocialGroup>[];
    final dynamic data = res.data;
    final Iterable<dynamic> candidates = _extractListCandidates(data);
    for (final dynamic item in candidates) {
      if (item is Map) {
        final group = _parseGroupMap(item);
        if (group != null) {
          result.add(group);
        }
      }
    }
    return result;
  }

  List<SocialUser> parseGroupMembers(Response res) {
    final List<SocialUser> members = <SocialUser>[];
    final Iterable<dynamic> candidates = _extractListCandidates(res.data);
    for (final dynamic item in candidates) {
      final SocialUser? user = _parseUser(item);
      if (user != null) {
        members.add(user);
      }
    }
    return members;
  }

  List<SocialGroupJoinRequest> parseGroupJoinRequests(Response res) {
    final List<SocialGroupJoinRequest> requests = <SocialGroupJoinRequest>[];
    final Iterable<dynamic> candidates = _extractListCandidates(res.data);
    for (final dynamic raw in candidates) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      String? requestId =
          _normalizeString(map['id'] ?? map['request_id'] ?? map['requestId']);
      final dynamic userRaw = map['user_data'] ?? map['user'] ?? map['member'];
      SocialUser? user = _parseUser(userRaw ?? map);
      if (user == null && userRaw is Map) {
        user = _parseUser(userRaw);
      }
      if (user == null) continue;
      final String key =
          (requestId != null && requestId.isNotEmpty) ? requestId : user.id;
      if (requestId != null && requestId.isEmpty) {
        requestId = null;
      }
      requests.add(
        SocialGroupJoinRequest(
          key: key,
          requestId: requestId,
          user: user,
        ),
      );
    }
    return requests;
  }

  Iterable<dynamic> _extractListCandidates(dynamic data) {
    if (data is List) {
      return data;
    }
    if (data is Map) {
      final List<dynamic> keys = <dynamic>[
        data['data'],
        data['groups'],
        data['my_groups'],
        data['joined_groups'],
        data['suggestions'],
        data['community'],
        data['items'],
        data['result'],
        data['users'],
        data['members'],
      ];

      for (final dynamic value in keys) {
        if (value is List) {
          return value;
        }
      }

      for (final dynamic value in keys) {
        if (value is Map) {
          final Iterable<dynamic> nested = _extractListCandidates(value);
          if (nested.isNotEmpty) {
            return nested;
          }
        }
      }
    }
    return const <dynamic>[];
  }

  SocialGroup? _parseGroupMap(Map raw) {
    if (raw.isEmpty) return null;
    final map = Map<String, dynamic>.from(raw);

    final String? id =
        _normalizeString(map['group_id'] ?? map['id'] ?? map['groupid']);
    final String? name = _normalizeString(
        map['group_name'] ?? map['name'] ?? map['group_title']);
    if (id == null || id.isEmpty || name == null || name.isEmpty) {
      return null;
    }

    String? title = _normalizeString(map['group_title'] ?? map['title']);
    title ??= name;

    final String? about =
        _normalizeString(map['about'] ?? map['group_description']);
    final String? description = _normalizeString(
        map['description'] ?? map['group_description'] ?? map['about']);
    final String? category =
        _normalizeString(map['category'] ?? map['group_category']);
    final String? subCategory =
        _normalizeString(map['group_sub_category'] ?? map['sub_category']);
    final String? privacy = _normalizeString(map['privacy']);
    final String? joinPrivacy =
        _normalizeString(map['join_privacy'] ?? map['joinPrivacy']);

    final String? avatar =
        _normalizeMediaUrl(map['avatar_full'] ?? map['avatar'] ?? map['icon']);
    final String? cover = _normalizeMediaUrl(
        map['cover_full'] ?? map['cover'] ?? map['cover_image']);

    final int memberCount = _coerceInt(map['members_count'] ??
            map['members'] ??
            map['members_num'] ??
            map['member_count']) ??
        0;
    final int pendingCount = _coerceInt(
            map['pending_users'] ?? map['pending_count'] ?? map['pending']) ??
        0;
    final int joinRequestStatus = _coerceInt(
          map['is_group_joined'] ??
              map['group_join_status'] ??
              map['join_status'],
        ) ??
        0;

    final dynamic joinedRaw =
        map['is_joined'] ?? map['joined'] ?? map['is_member'];
    final bool isJoined = joinRequestStatus == 1 || _isTruthy(joinedRaw);
    final bool isOwner =
        _isTruthy(map['is_owner'] ?? map['owner'] ?? map['is_creator']);
    final bool adminFlag =
        _isTruthy(map['is_admin'] ?? map['admin'] ?? map['is_moderator']);
    final bool isAdmin = adminFlag || isOwner;
    final bool requiresApproval = _isTruthy(map['requires_approval']) ||
        ((joinPrivacy ?? '').toLowerCase().contains('approve')) ||
        (joinPrivacy == '2');

    final SocialUser? owner = _parseUser(
      map['owner'] ??
          map['user_data'] ??
          map['creator'] ??
          map['admin'] ??
          map['publisher'],
    );

    final Map<String, dynamic> custom = <String, dynamic>{};
    map.forEach((key, value) {
      if (key.startsWith('fid_')) {
        custom[key] = value;
      }
    });

    final DateTime? createdAt = _epochToDateTime(_coerceInt(
      map['time'] ?? map['created_at'] ?? map['creation_date'],
    ));
    final DateTime? updatedAt = _epochToDateTime(_coerceInt(
      map['updated_at'] ?? map['update_time'],
    ));

    final String? status =
        _normalizeString(map['status'] ?? map['group_type'] ?? map['state']);
    final String? url = _absoluteUrl(
        _normalizeString(map['url'] ?? map['group_url'] ?? map['link']));

    return SocialGroup(
      id: id,
      name: name,
      title: title,
      about: about,
      description: description,
      category: category,
      subCategory: subCategory,
      privacy: privacy,
      joinPrivacy: joinPrivacy,
      avatarUrl: avatar,
      coverUrl: cover,
      memberCount: memberCount,
      pendingCount: pendingCount,
      isJoined: isJoined,
      isAdmin: isAdmin,
      isOwner: isOwner,
      requiresApproval: requiresApproval,
      joinRequestStatus: joinRequestStatus,
      owner: owner,
      customFields: custom,
      createdAt: createdAt,
      updatedAt: updatedAt,
      status: status,
      url: url,
    );
  }

  SocialUser? _parseUser(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final String? id =
        _normalizeString(map['user_id'] ?? map['id'] ?? map['userId']);
    if (id == null || id.isEmpty) return null;

    String? firstName =
        _normalizeString(map['first_name'] ?? map['fname'] ?? map['firstName']);
    String? lastName =
        _normalizeString(map['last_name'] ?? map['lname'] ?? map['lastName']);
    String? displayName = _normalizeString(map['name'] ??
        map['full_name'] ??
        map['fullname'] ??
        map['display_name']);
    final String? userName =
        _normalizeString(map['username'] ?? map['user_name']);

    if (displayName == null || displayName.isEmpty) {
      final buffer = <String>[
        if (firstName != null && firstName.isNotEmpty) firstName,
        if (lastName != null && lastName.isNotEmpty) lastName,
      ];
      final joined = buffer.join(' ').trim();
      if (joined.isNotEmpty) {
        displayName = joined;
      } else if (userName != null && userName.isNotEmpty) {
        displayName = userName;
      } else {
        displayName = id;
      }
    }

    final String? avatar = _normalizeMediaUrl(
        map['avatar_full'] ?? map['avatar'] ?? map['profile_picture']);
    final String? cover = _normalizeMediaUrl(
        map['cover_full'] ?? map['cover'] ?? map['cover_image']);
    final bool isAdmin =
        _isTruthy(map['is_admin'] ?? map['admin'] ?? map['is_moderator']);
    final bool isOwner =
        _isTruthy(map['is_owner'] ?? map['owner'] ?? map['is_creator']);

    return SocialUser(
      id: id,
      displayName: displayName,
      firstName: firstName,
      lastName: lastName,
      userName: userName,
      avatarUrl: avatar,
      coverUrl: cover,
      isAdmin: isAdmin,
      isOwner: isOwner,
    );
  }

  DateTime? _epochToDateTime(int? value) {
    if (value == null || value <= 0) return null;
    // Treat values > 10^12 as milliseconds.
    if (value > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true).toLocal();
    }
    return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true)
        .toLocal();
  }

  SocialUser? parseCurrentUser(Response res) {
    final data = res.data;
    Map? raw;
    if (data is Map) {
      if (data['user_data'] is Map) {
        raw = data['user_data'] as Map;
      } else if (data['data'] is Map) {
        raw = data['data'] as Map;
      } else if (data['data'] is List) {
        final list = data['data'] as List;
        if (list.isNotEmpty && list.first is Map) {
          raw = list.first as Map;
        }
      }
    }
    if (raw == null) return null;

    final map = Map<String, dynamic>.from(raw);
    final String id = (map['user_id'] ?? map['id'] ?? '').toString();
    if (id.isEmpty) return null;

    String? firstName =
        (map['first_name'] ?? map['fname'] ?? '').toString().trim();
    if (firstName.isEmpty) firstName = null;
    String? lastName =
        (map['last_name'] ?? map['lname'] ?? '').toString().trim();
    if (lastName.isEmpty) lastName = null;

    String? displayName = (map['name'] ?? '').toString().trim();
    if (displayName.isEmpty) displayName = null;
    final String? userName =
        (map['username'] ?? map['user_name'] ?? '').toString().trim().isEmpty
            ? null
            : (map['username'] ?? map['user_name']).toString();

    if (displayName == null) {
      final buffer = [
        if (firstName != null) firstName,
        if (lastName != null) lastName,
      ];
      final joined = buffer.join(' ').trim();
      if (joined.isNotEmpty) {
        displayName = joined;
      } else if (userName != null && userName.isNotEmpty) {
        displayName = userName;
      }
    }

    final avatarRaw =
        (map['avatar_full'] ?? map['avatar_original'] ?? map['avatar'] ?? '')
            .toString();
    final coverRaw =
        (map['cover_full'] ?? map['cover_original'] ?? map['cover'] ?? '')
            .toString();
    final String? avatar = _absoluteUrl(avatarRaw);
    final String? cover = _absoluteUrl(coverRaw);

    return SocialUser(
      id: id,
      displayName: displayName,
      firstName: firstName,
      lastName: lastName,
      userName: userName,
      avatarUrl: avatar,
      coverUrl: cover,
    );
  }

  //map public
   SocialPost? mapToSocialPost(Map<String, dynamic> raw) {
    return _mapToSocialPost(Map<String, dynamic>.from(raw));
  }
  DateTime? _parseCommentDate(dynamic raw) {
    if (raw == null) return null;
    final String str = raw.toString().trim();
    if (str.isEmpty) return null;
    final int? numeric = int.tryParse(str);
    if (numeric != null) {
      if (numeric > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(numeric, isUtc: true)
            .toLocal();
      }
      return DateTime.fromMillisecondsSinceEpoch(numeric * 1000, isUtc: true)
          .toLocal();
    }
    return DateTime.tryParse(str)?.toLocal();
  }

  Map<String, dynamic> _extractReactionMap(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }

  Map<String, int> _reactionBreakdownFromMap(Map<String, dynamic> rx) {
    if (rx.isEmpty) return const <String, int>{};
    final Map<String, int> normalized = <String, int>{};
    const labels = ['Like', 'Love', 'HaHa', 'Wow', 'Sad', 'Angry'];
    for (final label in labels) {
      final dynamic raw = _reactionValue(rx, label);
      final int? count = _coerceInt(raw);
      if (count != null && count > 0) {
        normalized[label] = count;
      }
    }
    if (normalized.isEmpty) return const <String, int>{};
    return Map<String, int>.unmodifiable(normalized);
  }

  dynamic _reactionValue(Map<String, dynamic> rx, String label) {
    final List<String> keys = <String>[
      label,
      label.toLowerCase(),
      label.toUpperCase(),
    ];
    final String idKey = _mapReactionLabelToId(label);
    if (idKey.isNotEmpty && !keys.contains(idKey)) {
      keys.add(idKey);
    }
    for (final key in keys) {
      if (rx.containsKey(key)) return rx[key];
    }
    return null;
  }

  int _reactionCountFromMap(Map<String, dynamic> rx) {
    if (rx.isEmpty) return 0;
    if (rx['count'] != null) {
      return int.tryParse('${rx['count']}') ?? 0;
    }
    const keys = ['Like', 'Love', 'HaHa', 'Wow', 'Sad', 'Angry'];
    int sum = 0;
    for (final k in keys) {
      final v = rx[k];
      if (v is int) {
        sum += v;
      } else if (v != null) {
        sum += int.tryParse('$v') ?? 0;
      }
    }
    return sum;
  }

  String _reactionLabelFromMap(Map<String, dynamic> rx) {
    if (rx.isEmpty) return '';
    String? label;
    final type = rx['type'] ?? rx['my_reaction'] ?? rx['current_user_reaction'];
    if (type != null && '$type'.isNotEmpty) {
      label = '$type';
    } else {
      final reacted = rx['is_reacted'];
      if (_isTruthy(reacted)) {
        label = 'Like';
      }
    }
    return _normalizeReactionLabel(label ?? '');
  }

  int _resolveCount(List<dynamic> candidates) {
    int maxValue = 0;
    for (final candidate in candidates) {
      if (candidate == null) continue;
      int? value;
      if (candidate is List) {
        value = candidate.length;
      } else {
        value = _coerceInt(candidate);
      }
      if (value != null && value > maxValue) {
        maxValue = value;
      }
    }
    return maxValue;
  }

  int? _coerceInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      final normalized = trimmed.replaceAll(RegExp(r'[^0-9\-]'), '');
      if (normalized.isEmpty) return null;
      return int.tryParse(normalized);
    }
    return null;
  }

  String _normalizeReactionLabel(String reaction) {
    final trimmed = reaction.trim();
    if (trimmed.isEmpty) return '';
    switch (trimmed) {
      case '1':
      case 'like':
      case 'LIKE':
        return 'Like';
      case '2':
      case 'love':
      case 'LOVE':
        return 'Love';
      case '3':
      case 'haha':
      case 'HAHA':
        return 'HaHa';
      case '4':
      case 'wow':
      case 'WOW':
        return 'Wow';
      case '5':
      case 'sad':
      case 'SAD':
        return 'Sad';
      case '6':
      case 'angry':
      case 'ANGRY':
        return 'Angry';
      default:
        return trimmed;
    }
  }

  String _mapReactionLabelToId(String reaction) {
    switch (reaction) {
      case 'Like':
        return '1';
      case 'Love':
        return '2';
      case 'HaHa':
        return '3';
      case 'Wow':
        return '4';
      case 'Sad':
        return '5';
      case 'Angry':
        return '6';
      default:
        return '1';
    }
  }

  String _fileNameFromPath(String path) {
    if (path.isEmpty) {
      return 'story_${DateTime.now().millisecondsSinceEpoch}';
    }
    final segments = path.split(RegExp(r'[\\/]'));
    if (segments.isEmpty) {
      return 'story_${DateTime.now().millisecondsSinceEpoch}';
    }
    final last =
        segments.lastWhere((element) => element.isNotEmpty, orElse: () => '');
    if (last.isEmpty) {
      return 'story_${DateTime.now().millisecondsSinceEpoch}';
    }
    return last;
  }

  bool _isTruthy(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value.toString().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes';
  }
}

class _ViewerReactionEntry {
  final String label;
  final double orderKey;
  final int sequence;

  const _ViewerReactionEntry({
    required this.label,
    required this.orderKey,
    required this.sequence,
  });
}
