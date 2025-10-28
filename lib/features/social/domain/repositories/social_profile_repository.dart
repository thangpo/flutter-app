import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/exception/api_error_handler.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class SocialProfileRepository {
  final DioClient dioClient;
  final SharedPreferences sharedPreferences;

  SocialProfileRepository({
    required this.dioClient,
    required this.sharedPreferences,
  });

  String? _getSocialAccessToken() {
    return sharedPreferences.getString(AppConstants.socialAccessToken);
  }

  String? _getSocialUserId() {
    return sharedPreferences.getString(AppConstants.socialUserId);
  }

  Future<ApiResponseModel<Response>> fetchUserProfile() async {
    try {
      final token = _getSocialAccessToken();
      if (token?.isNotEmpty != true) {
        return ApiResponseModel.withError('Missing Social access_token');
      }

      final String? userId = _getSocialUserId();

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
        'type':'get_user_posts',
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
}
