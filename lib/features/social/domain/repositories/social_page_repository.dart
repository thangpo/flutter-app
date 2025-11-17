import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/exception/api_error_handler.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_get_page.dart';

class SocialPageRepository {
  final DioClient dioClient;
  final SharedPreferences sharedPreferences;

  SocialPageRepository({
    required this.dioClient,
    required this.sharedPreferences,
  });

  String? _getSocialAccessToken() {
    return sharedPreferences.getString(AppConstants.socialAccessToken);
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

  String? _normalizeMediaUrl(dynamic raw) {
    final normalized = _normalizeString(raw);
    if (normalized == null) return null;
    return _absoluteUrl(normalized) ?? normalized;
  }

  List<SocialGetPage> _parsePagesFromResponse(Response res) {
    final List<SocialGetPage> result = <SocialGetPage>[];
    dynamic data = res.data;

    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        return result;
      }
    }

    if (data is! Map) return result;
    final int status = (data['api_status'] as num?)?.toInt() ?? 0;
    if (status != 200) return result;

    final List<dynamic> list = data['data'] as List<dynamic>? ?? const [];
    for (final dynamic item in list) {
      if (item is! Map) continue;
      final SocialGetPage? page = _parseGetPageMap(item);
      if (page != null) result.add(page);
    }
    return result;
  }


  /// 1) Gọi API lấy page gợi ý
  Future<ApiResponseModel<Response>> fetchRecommendedPages({
    int limit = 10,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
          'Please log in to your social network account',
        );
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialFetchRecommendPage}?access_token=$token';

      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'type': 'pages',
        'limit': limit.toString(),
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

  /// 2) Parse Response -> List<SocialGetPage>
  List<SocialGetPage> parseRecommendedPages(Response res) {
    return _parsePagesFromResponse(res);
  }

// parse my pages
  List<SocialGetPage> parseMyPages(Response res) {
    return _parsePagesFromResponse(res);
  }


  /// 3) Helper parse từng page map -> SocialGetPage
  SocialGetPage? _parseGetPageMap(Map raw) {
    final Map<String, dynamic> map =
    raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw);

    // Chuẩn hoá URL avatar / cover / avatar_org trước khi từ Json
    map['avatar'] = _normalizeMediaUrl(
      map['avatar'] ?? map['avatar_org'],
    );
    map['cover'] = _normalizeMediaUrl(map['cover']);
    map['avatar_org'] = _normalizeMediaUrl(map['avatar_org']);

    try {
      return SocialGetPage.fromJson(map);
    } catch (_) {
      // Nếu parse lỗi thì bỏ qua để không crash
      return null;
    }
  }

  //lấy page của tôi
  Future<ApiResponseModel<Response>> getMyPage({
    int limit = 100,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
          'Please log in to your social network account',
        );
      }

      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialGetMyPage}?access_token=$token';

      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,

        'limit': limit.toString(),
        'type': 'my_pages',
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
  Future<ApiResponseModel<Response>> fetchArticleCategories() async {
    try {
      final String? token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
          'Please log in to your social network account',
        );
      }

      // https://social.vnshop247.com/api/get_category?access_token=...
      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialGetCategory}?access_token=$token';

      final formData = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
      });

      final Response res = await dioClient.post(
        url,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return ApiResponseModel.withSuccess(res);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  /// Parse Response -> List<SocialArticleCategory>
  List<SocialArticleCategory> parseArticleCategories(Response res) {
    final List<SocialArticleCategory> result = <SocialArticleCategory>[];

    dynamic data = res.data;

    // Trường hợp API trả JSON dạng string
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        return result;
      }
    }

    if (data is! Map) return result;
    final Map<String, dynamic> map = data as Map<String, dynamic>;

    final int status = (map['api_status'] as num?)?.toInt() ?? 0;
    if (status != 200) return result;

    final List<dynamic> list = map['categories'] as List<dynamic>? ?? const [];
    return SocialArticleCategory.listFromJson(list);
  }
}
