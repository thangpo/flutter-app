import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/exception/api_error_handler.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_comment.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';

bool _isImageUrl(String url) {
  final u = url.toLowerCase();
  return u.endsWith('.png') ||
      u.endsWith('.jpg') ||
      u.endsWith('.jpeg') ||
      u.endsWith('.gif') ||
      u.endsWith('.webp');
}

class SocialFeedPage {
  final List<SocialPost> posts;
  final String? lastId;
  SocialFeedPage({required this.posts, required this.lastId});
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
        return ApiResponseModel.withError('Please log in to your social network account');
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

  SocialFeedPage parseNewsFeed(Response res) {
    final data = res.data;
    final list = <SocialPost>[];
    String? lastId;

    if (data is Map) {
      final posts = (data['data'] ?? data['posts'] ?? data['news_feed']);
      if (posts is List) {
        for (final raw in posts) {
          if (raw is! Map) continue;
          final m = Map<String, dynamic>.from(raw);

          final String id = (m['post_id'] ?? m['id'] ?? '').toString();
          if (id.isEmpty) continue;

          final String text =
              (m['postText_API'] ?? m['postText'] ?? '').toString();
          final String timeText =
              (m['post_time'] ?? m['time_text'] ?? '').toString();

          // publisher
          final Map pub =
              (m['publisher'] is Map) ? m['publisher'] as Map : const {};
          final String userName =
              (pub['name'] ?? pub['username'] ?? '').toString();
          final String userAvatar = (pub['avatar'] ?? '').toString();

          // multi-image
          final List pm =
              (m['photo_multi'] is List) ? m['photo_multi'] as List : const [];
          final List<String> multiImages = [
            ...pm
                .whereType<Map>()
                .map((x) => (x['image'] ?? '').toString())
                .where((s) => s.isNotEmpty),
          ];

          // single image
          final String singleFull = (m['postFile_full'] ?? '').toString();
          final List<String> imageUrls =
              multiImages.where(_isImageUrl).toList(growable: false) +
                  (singleFull.isNotEmpty && _isImageUrl(singleFull)
                      ? [singleFull]
                      : <String>[]);

          // file
          final String fileUrl =
              (m['postFile'] ?? m['postFile_full'] ?? '').toString();
          final String fileName = (m['postFileName'] ?? '').toString();

          // detect media type
          String? videoUrl, audioUrl;
          if (fileUrl.isNotEmpty) {
            final u = fileUrl.toLowerCase();
            if (u.endsWith('.mp4') ||
                u.endsWith('.mov') ||
                u.endsWith('.m4v')) {
              videoUrl = fileUrl;
            } else if (u.endsWith('.mp3') || u.contains('/sounds/')) {
              audioUrl = fileUrl;
            }
          }

          final Map<String, dynamic> rx =
              _extractReactionMap(m['reaction'] ?? m['reactions']);
          final int reactionCount = _reactionCountFromMap(rx);
          final String myReaction = _reactionLabelFromMap(rx);
          final Map<String, int> reactionBreakdown =
              _reactionBreakdownFromMap(rx);

          final int commentCount = _resolveCount(<dynamic>[
            m['post_comments'],
            m['comments_count'],
            m['comment_count'],
            m['comments_num'],
            m['comments'],
            m['get_post_comments'],
          ]);

          final int shareCount = _resolveCount(<dynamic>[
            m['post_shares'],
            m['shares'],
            m['share_count'],
            m['post_share'],
            m['shared'],
          ]);

          // product
          final Map product =
              (m['product'] is Map) ? m['product'] as Map : const {};
          final bool hasProduct = product.isNotEmpty;
          final String productName = (product['name'] ?? '').toString();
          final List pImgsRaw = (product['images'] is List)
              ? product['images'] as List
              : const [];
          final List<String> productImages = [
            ...pImgsRaw
                .whereType<Map>()
                .map((x) => (x['image'] ?? '').toString())
                .where((s) => s.isNotEmpty),
          ];
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

          final String? postType =
              (m['postType']?.toString().isNotEmpty ?? false)
                  ? m['postType'].toString()
                  : null;

          list.add(
            SocialPost(
              id: id,
              userName: userName.isNotEmpty ? userName : null,
              userAvatar: userAvatar.isNotEmpty ? userAvatar : null,
              text: text.isNotEmpty ? text : null,
              timeText: timeText.isNotEmpty ? timeText : null,
              imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
              imageUrls: imageUrls,
              fileUrl: fileUrl.isNotEmpty ? fileUrl : null,
              fileName: fileName.isNotEmpty ? fileName : null,
              videoUrl: videoUrl,
              audioUrl: audioUrl,
              postType: postType,
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
              pollOptions: (m['options'] is List)
                  ? List<Map<String, dynamic>>.from(m['options'])
                  : null,
            ),
          );
          lastId = id;
        }
      }
    }
    return SocialFeedPage(posts: list, lastId: lastId);
  }

  //Stories
  Future<ApiResponseModel<Response>> fetchStories({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final token = sharedPreferences.getString(AppConstants.socialAccessToken);
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError('Please log in to your social network account');
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
        return ApiResponseModel.withError('Please log in to your social network account');
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
        return ApiResponseModel.withError('Please log in to your social network account');
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
        return ApiResponseModel.withError('Please log in to your social network account');
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
        return ApiResponseModel.withError('Please log in to your social network account');
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
        return ApiResponseModel.withError('Please log in to your social network account');
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
        return ApiResponseModel.withError('Please log in to your social network account');
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
        return ApiResponseModel.withError('Please log in to your social network account');
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
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError('Please log in to your social network account');
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

  Future<ApiResponseModel<Response>> fetchCurrentUserProfile() async {
    try {
      final token = _getSocialAccessToken();
      final userId = _getSocialUserId();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError('Please log in to your social network account');
      }
      if (userId == null || userId.isEmpty) {
        return ApiResponseModel.withError('The social network account does not exist');
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

    final map = Map<String, dynamic>.from(m);

    final String id = (map['post_id'] ?? map['id'] ?? '').toString();
    if (id.isEmpty) return null;
    final String text =
        (map['postText_API'] ?? map['postText'] ?? '').toString();
    final String timeText =
        (map['post_time'] ?? map['time_text'] ?? '').toString();

    final Map pub =
        (map['publisher'] is Map) ? map['publisher'] as Map : const {};
    final String userName = (pub['name'] ?? pub['username'] ?? '').toString();
    final String userAvatar = (pub['avatar'] ?? '').toString();

    final List pm =
        (map['photo_multi'] is List) ? map['photo_multi'] as List : const [];
    final List<String> multiImages = [
      ...pm
          .whereType<Map>()
          .map((x) => (x['image'] ?? '').toString())
          .where((s) => s.isNotEmpty),
    ];
    final String singleFull = (map['postFile_full'] ?? '').toString();
    final List<String> imageUrls =
        multiImages.where(_isImageUrl).toList(growable: false) +
            (singleFull.isNotEmpty && _isImageUrl(singleFull)
                ? [singleFull]
                : <String>[]);

    final String fileUrl =
        (map['postFile'] ?? map['postFile_full'] ?? '').toString();
    final String fileName = (map['postFileName'] ?? '').toString();

    String? videoUrl, audioUrl;
    if (fileUrl.isNotEmpty) {
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
      map['post_shares'],
      map['shares'],
      map['share_count'],
      map['post_share'],
      map['shared'],
    ]);

    final Map product =
        (map['product'] is Map) ? map['product'] as Map : const {};
    final bool hasProduct = product.isNotEmpty;
    final String productName = (product['name'] ?? '').toString();
    final List pImgsRaw =
        (product['images'] is List) ? product['images'] as List : const [];
    final List<String> productImages = [
      ...pImgsRaw
          .whereType<Map>()
          .map((x) => (x['image'] ?? '').toString())
          .where((s) => s.isNotEmpty),
    ];
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

    return SocialPost(
      id: id,
      userName: userName.isNotEmpty ? userName : null,
      userAvatar: userAvatar.isNotEmpty ? userAvatar : null,
      text: text.isNotEmpty ? text : null,
      timeText: timeText.isNotEmpty ? timeText : null,
      imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
      imageUrls: imageUrls,
      fileUrl: fileUrl.isNotEmpty ? fileUrl : null,
      fileName: fileName.isNotEmpty ? fileName : null,
      videoUrl: videoUrl,
      audioUrl: audioUrl,
      postType: postType,
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
        return ApiResponseModel.withError('Please log in to your social network account');
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
        return ApiResponseModel.withError('Please log in to your social network account');
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
        return ApiResponseModel.withError('Please log in to your social network account');
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
        return ApiResponseModel.withError('Please log in to your social network account');
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
        return ApiResponseModel.withError('Please log in to your social network account');
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
        return ApiResponseModel.withError('Please log in to your social network account');
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
        return ApiResponseModel.withError('Please log in to your social network account');
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
        return ApiResponseModel.withError('Please log in to your social network account');
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
    for (final candidate in candidates) {
      if (candidate == null) continue;
      if (candidate is List) {
        return candidate.length;
      }
      final int? parsed = _coerceInt(candidate);
      if (parsed != null) return parsed;
    }
    return 0;
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
