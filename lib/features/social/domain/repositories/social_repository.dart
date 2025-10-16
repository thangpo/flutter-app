import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/exception/api_error_handler.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';

bool _isImageUrl(String url) {
  final u = url.toLowerCase();
  return u.endsWith('.png') || u.endsWith('.jpg') || u.endsWith('.jpeg') || u.endsWith('.gif') || u.endsWith('.webp');
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

          final String text = (m['postText_API'] ?? m['postText'] ?? '').toString();
          final String timeText = (m['post_time'] ?? m['time_text'] ?? '').toString();

          // publisher
          final Map pub = (m['publisher'] is Map) ? m['publisher'] as Map : const {};
          final String userName = (pub['name'] ?? pub['username'] ?? '').toString();
          final String userAvatar = (pub['avatar'] ?? '').toString();

          // multi-image
          final List pm = (m['photo_multi'] is List) ? m['photo_multi'] as List : const [];
          final List<String> multiImages = [
            ...pm.whereType<Map>()
                .map((x) => (x['image'] ?? '').toString())
                .where((s) => s.isNotEmpty),
          ];

          // single image
          final String singleFull = (m['postFile_full'] ?? '').toString();
          final List<String> imageUrls = multiImages.where(_isImageUrl).toList(growable:false)
                 + (singleFull.isNotEmpty && _isImageUrl(singleFull) ? [singleFull] : <String>[]);

          // file
          final String fileUrl = (m['postFile'] ?? m['postFile_full'] ?? '').toString();
          final String fileName = (m['postFileName'] ?? '').toString();

          // detect media type
          String? videoUrl, audioUrl;
          if (fileUrl.isNotEmpty) {
            final u = fileUrl.toLowerCase();
            if (u.endsWith('.mp4') || u.endsWith('.mov') || u.endsWith('.m4v')) {
              videoUrl = fileUrl;
            } else if (u.endsWith('.mp3') || u.contains('/sounds/')) {
              audioUrl = fileUrl;
            }
          }

          // product
          final Map product = (m['product'] is Map) ? m['product'] as Map : const {};
          final bool hasProduct = product.isNotEmpty;
          final String productName = (product['name'] ?? '').toString();
          final List pImgsRaw = (product['images'] is List) ? product['images'] as List : const [];
          final List<String> productImages = [
            ...pImgsRaw.whereType<Map>()
                .map((x) => (x['image'] ?? '').toString())
                .where((s) => s.isNotEmpty),
          ];
          final double? productPrice = product['price'] is num
              ? (product['price'] as num).toDouble()
              : double.tryParse((product['price'] ?? '').toString());
          final String? productCurrency = (product['currency'] ?? '').toString().isNotEmpty
              ? product['currency'].toString()
              : null;

          final String? postType = (m['postType']?.toString().isNotEmpty ?? false)
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
              hasProduct: hasProduct,
              productTitle: productName.isNotEmpty ? productName : null,
              productImages: productImages.isNotEmpty ? productImages : null,
              productPrice: productPrice,
              productCurrency: productCurrency,
              pollOptions: (m['options'] is List) ? List<Map<String,dynamic>>.from(m['options']) : null,
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
}
