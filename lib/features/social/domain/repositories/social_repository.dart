import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/exception/api_error_handler.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';

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
    final List<SocialPost> list = [];
    String? lastId;

    if (data is Map) {
      // Hỗ trợ đủ 3 kiểu key: data / posts / news_feed
      dynamic container = data['data'];
      if (container == null) container = data['posts'];
      if (container == null) container = data['news_feed'];

      // Nếu 'data' bản nào đó lại là Map { data: [...] }
      if (container is Map && container['data'] is List) {
        container = container['data'];
      }

      final posts = (container is List) ? container : const [];

      if (posts is List) {
        for (final it in posts) {
          if (it is Map) {
            // ---- PARSE MỖI POST Ở TRONG LOOP ----
            final Map<String, dynamic> m = Map<String, dynamic>.from(it);

            // text ưu tiên postText_API -> postText
            final String text =
                (m['postText_API'] ?? m['postText'] ?? '').toString();

            // thời gian
            final String timeText = (m['post_time'] ?? '').toString();

            // publisher
            final Map pub =
                (m['publisher'] is Map) ? m['publisher'] as Map : const {};
            final String userName =
                (pub['name'] ?? pub['username'] ?? '').toString();
            final String userAvatar = (pub['avatar'] ?? '').toString();

            // ảnh đơn (đường dẫn full)
            final String singleFull = (m['postFile_full'] ?? '').toString();

            // multi-image
            final List multi = (m['photo_multi'] is List)
                ? (m['photo_multi'] as List)
                : const [];
            final List<String> multiImages = [
              ...multi
                  .whereType<Map>()
                  .map((x) => (x['image'] ?? '').toString())
                  .where((s) => s.isNotEmpty),
            ];

            // gộp ảnh: ưu tiên multi; nếu không có thì dùng đơn
            final List<String> imageUrls = multiImages.isNotEmpty
                ? multiImages
                : (singleFull.isNotEmpty ? [singleFull] : <String>[]);

            // post type
            final String? postType =
                (m['postType']?.toString().isNotEmpty ?? false)
                    ? m['postType'].toString()
                    : null;

            // id (phục vụ phân trang)
            final String id = (m['post_id'] ?? m['id'] ?? '').toString();

            final post = SocialPost(
              id: id,
              userName: userName.isNotEmpty ? userName : null,
              userAvatar: userAvatar.isNotEmpty ? userAvatar : null,
              text: text.isNotEmpty ? text : null,
              timeText: timeText.isNotEmpty ? timeText : null,
              imageUrl: imageUrls.isNotEmpty
                  ? imageUrls.first
                  : null, // giữ tương thích
              imageUrls: imageUrls, // dùng UI mới
              postType: postType,
            );
            list.add(post);
            lastId = id; // để load more (after_post_id)
          }
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
}
