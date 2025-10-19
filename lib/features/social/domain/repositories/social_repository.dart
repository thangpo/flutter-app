import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/exception/api_error_handler.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_comment.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';
import 'package:http/http.dart' as http;

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

  //Feeds
  Future<ApiResponseModel<Response>> fetchNewsFeed({
    int limit = 10,
    String? afterPostId,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError('Missing Social access_token');
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

          // reaction
          // --- REACTION PARSING (đảm bảo có số và type) ---
          final Map rx = (m['reaction'] is Map)
              ? m['reaction'] as Map
              : (m['reactions'] is Map ? m['reactions'] as Map : const {});

          int _rxCount(Map rx) {
            // Nếu có 'count' dùng luôn
            if (rx['count'] != null) {
              return int.tryParse('${rx['count']}') ?? 0;
            }
            // WoWonder hay trả từng loại: Like/Love/HaHa/Wow/Sad/Angry
            const keys = ['Like', 'Love', 'HaHa', 'Wow', 'Sad', 'Angry'];
            int sum = 0;
            for (final k in keys) {
              final v = rx[k];
              if (v is int)
                sum += v;
              else if (v != null) sum += int.tryParse('$v') ?? 0;
            }
            return sum;
          }

          String _rxMine(Map rx) {
            final t = (rx['type'] ?? '').toString();
            if (t.isNotEmpty) return t;
            // Fallback nếu server chỉ trả is_reacted (1/0)
            final isReacted = rx['is_reacted'] == true ||
                rx['is_reacted'] == 1 ||
                rx['is_reacted']?.toString() == '1';
            return isReacted ? 'Like' : '';
          }

          final int reactionCount = _rxCount(rx);
          String myReaction = _rxMine(rx);
          // Normalize WoWonder numeric reaction codes to labels
          switch (myReaction) {
            case '1':
              myReaction = 'Like';
              break;
            case '2':
              myReaction = 'Love';
              break;
            case '3':
              myReaction = 'HaHa';
              break;
            case '4':
              myReaction = 'Wow';
              break;
            case '5':
              myReaction = 'Sad';
              break;
            case '6':
              myReaction = 'Angry';
              break;
          }

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
          final String? productCurrency =
              (product['currency'] ?? '').toString().isNotEmpty
                  ? product['currency'].toString()
                  : null;

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
              hasProduct: hasProduct,
              productTitle: productName.isNotEmpty ? productName : null,
              productImages: productImages.isNotEmpty ? productImages : null,
              productPrice: productPrice,
              productCurrency: productCurrency,
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
        return ApiResponseModel.withError('Missing Social access_token');
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
      // Theo collection: có thể là data.stories hoặc data.data
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

  Future<ApiResponseModel<Response>> reactToPost({
    required String postId,
    required String
        reaction, // '' = unreact, hoặc: Like/Love/HaHa/Wow/Sad/Angry
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError('Missing Social access_token');
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
        // Per API: always use action=reaction
        'action': 'reaction',
        // Reaction must be numeric string (1..6). Default to 1 if empty.
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
        return ApiResponseModel.withError('Missing Social access_token');
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
    final String text = (map['postText_API'] ?? map['postText'] ?? '').toString();
    final String timeText = (map['post_time'] ?? map['time_text'] ?? '').toString();

    final Map pub = (map['publisher'] is Map) ? map['publisher'] as Map : const {};
    final String userName = (pub['name'] ?? pub['username'] ?? '').toString();
    final String userAvatar = (pub['avatar'] ?? '').toString();

    final List pm = (map['photo_multi'] is List) ? map['photo_multi'] as List : const [];
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

    final String fileUrl = (map['postFile'] ?? map['postFile_full'] ?? '').toString();
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

    final Map rx = (map['reaction'] is Map)
        ? map['reaction'] as Map
        : (map['reactions'] is Map ? map['reactions'] as Map : const {});

    int _rxCount(Map rx) {
      if (rx['count'] != null) return int.tryParse('${rx['count']}') ?? 0;
      const keys = ['Like', 'Love', 'HaHa', 'Wow', 'Sad', 'Angry'];
      int sum = 0;
      for (final k in keys) {
        final v = rx[k];
        if (v is int) sum += v; else if (v != null) sum += int.tryParse('$v') ?? 0;
      }
      return sum;
    }

    String _rxMine(Map rx) {
      final t = (rx['type'] ?? '').toString();
      if (t.isNotEmpty) return t;
      final isReacted = rx['is_reacted'] == true || rx['is_reacted'] == 1 || rx['is_reacted']?.toString() == '1';
      return isReacted ? 'Like' : '';
    }

    int reactionCount = _rxCount(rx);
    String myReaction = _rxMine(rx);
    switch (myReaction) {
      case '1':
        myReaction = 'Like';
        break;
      case '2':
        myReaction = 'Love';
        break;
      case '3':
        myReaction = 'HaHa';
        break;
      case '4':
        myReaction = 'Wow';
        break;
      case '5':
        myReaction = 'Sad';
        break;
      case '6':
        myReaction = 'Angry';
        break;
    }

    final Map product = (map['product'] is Map) ? map['product'] as Map : const {};
    final bool hasProduct = product.isNotEmpty;
    final String productName = (product['name'] ?? '').toString();
    final List pImgsRaw = (product['images'] is List) ? product['images'] as List : const [];
    final List<String> productImages = [
      ...pImgsRaw
          .whereType<Map>()
          .map((x) => (x['image'] ?? '').toString())
          .where((s) => s.isNotEmpty),
    ];
    final double? productPrice = product['price'] is num
        ? (product['price'] as num).toDouble()
        : double.tryParse((product['price'] ?? '').toString());
    final String? productCurrency =
        (product['currency'] ?? '').toString().isNotEmpty ? product['currency'].toString() : null;

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
      hasProduct: hasProduct,
      productTitle: productName.isNotEmpty ? productName : null,
      productImages: productImages.isNotEmpty ? productImages : null,
      productPrice: productPrice,
      productCurrency: productCurrency,
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
          final Map pub = (m['publisher'] is Map) ? m['publisher'] as Map : const {};
          final String userName = (pub['name'] ?? pub['username'] ?? '').toString();
          final String userAvatar = (pub['avatar'] ?? '').toString();
          final String timeText = (m['time_text'] ?? m['time'] ?? '').toString();
          final String cFile = (m['c_file'] ?? m['file'] ?? m['image'] ?? m['image_url'] ?? '').toString();
          final String record = (m['record'] ?? m['audio'] ?? '').toString();
          final int? repliesCount = (m['replies_count'] != null)
              ? int.tryParse('${m['replies_count']}')
              : null;
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
          final Map pub = (m['publisher'] is Map) ? m['publisher'] as Map : const {};
          final String userName = (pub['name'] ?? pub['username'] ?? '').toString();
          final String userAvatar = (pub['avatar'] ?? '').toString();
          final String timeText = (m['time_text'] ?? m['time'] ?? '').toString();
          final String cFile = (m['c_file'] ?? m['file'] ?? m['image'] ?? m['image_url'] ?? '').toString();
          final String record = (m['record'] ?? m['audio'] ?? '').toString();
          if (id.isEmpty) continue;
          list.add(SocialComment(
            id: id,
            text: text.isNotEmpty ? text : null,
            userName: userName.isNotEmpty ? userName : null,
            userAvatar: userAvatar.isNotEmpty ? userAvatar : null,
            timeText: timeText.isNotEmpty ? timeText : null,
            imageUrl: cFile.isNotEmpty ? cFile : null,
            audioUrl: record.isNotEmpty ? record : null,
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
        return ApiResponseModel.withError('Missing Social access_token');
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
        return ApiResponseModel.withError('Missing Social access_token');
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
        return ApiResponseModel.withError('Missing Social access_token');
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
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError('Missing Social access_token');
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
  Future<ApiResponseModel<Response>> reactToPostWithAction({
    required String postId,
    required String reaction,
    required String action, // 'reaction' or 'dislike'
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError('Missing Social access_token');
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
        'action': action,
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
}
