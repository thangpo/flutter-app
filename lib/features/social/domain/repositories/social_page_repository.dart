import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
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
  SocialGetPage? parseSinglePageFromMap(Map raw) {
    return _parseGetPageMap(raw);
  }


  //lấy page của tôi
  Future<ApiResponseModel<Response>> getMyPage({
    int limit = 100,
    String type = 'my_pages'
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
        'type': type
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
  Future<ApiResponseModel<Response>> getLikedPages({
    required String userId,
    int limit = 100,
    String type = 'liked_pages'
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
        'user_id': userId,
        'limit': limit.toString(),
        'type': type
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

  Future<ApiResponseModel<Response>> likePage({
    required String pageId,
  }) async {
    try {
      final String? token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
          'Please log in to your social network account',
        );
      }

      // https://social.vnshop247.com/api/like-page?access_token=...
      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialLikePage}?access_token=$token';

      final formData = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'page_id': pageId,
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
  Future<ApiResponseModel<Response>> createPage({
    required String pageName,
    required String pageTitle,
    required int categoryId,
    String? description,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
          'Please log in to your social network account',
        );
      }

      // TODO: định nghĩa AppConstants.socialCreatePage = '/api/create-page';
      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialCreatePage}?access_token=$token';

      final form = FormData.fromMap({
        'server_key': AppConstants.socialServerKey,
        'page_name': pageName,
        'page_title': pageTitle,
        'page_category': categoryId.toString(),
        if (description != null && description.trim().isNotEmpty)
          'page_description': description.trim(),
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
  Future<ApiResponseModel<Response>> updatePage({
    required int pageId,
    String? pageName,
    String? pageTitle,
    String? description,
    int? categoryId,
    File? avatar,
    File? cover,
    Map<String, dynamic>? extraFields,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'page_id': pageId.toString(),
    };

    if (pageName != null && pageName.trim().isNotEmpty) {
      payload['page_name'] = pageName.trim();
    }
    if (pageTitle != null && pageTitle.trim().isNotEmpty) {
      payload['page_title'] = pageTitle.trim();
    }
    if (description != null && description.trim().isNotEmpty) {
      // theo doc: page_description
      payload['page_description'] = description.trim();
    }
    if (categoryId != null) {
      payload['page_category'] = categoryId.toString();
    }
    if (avatar != null) {
      payload['avatar'] = avatar;
    }
    if (cover != null) {
      payload['cover'] = cover;
    }
    if (extraFields != null && extraFields.isNotEmpty) {
      payload.addAll(extraFields);
    }

    return updatePageFromPayload(payload);
  }

  /// Hàm generic: nhận payload Map<String, dynamic> (giống payload pop từ EditPageScreen)
  ///
  /// payload ví dụ:
  /// {
  ///   'page_id': '123',        // BẮT BUỘC
  ///   'page_name': 'abc',
  ///   'page_title': 'ABC',
  ///   'page_description': '...',
  ///   'avatar': File,
  ///   'cover': File,
  ///   ...
  /// }
  Future<ApiResponseModel<Response>> updatePageFromPayload(
      Map<String, dynamic> payload) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
          'Please log in to your social network account',
        );
      }

      if (!payload.containsKey('page_id')) {
        return ApiResponseModel.withError('page_id is required');
      }

      // TODO: định nghĩa trong AppConstants:
      // static const String socialUpdatePage = '/api/update-page-data';
      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialUpdateDatePage}?access_token=$token';

      // Build form data
      final Map<String, dynamic> formMap = <String, dynamic>{
        'server_key': AppConstants.socialServerKey,
      };

      payload.forEach((key, value) {
        if (value == null) return;

        if (value is File) {
          formMap[key] = MultipartFile.fromFileSync(
            value.path,
            filename: p.basename(value.path),
          );
        } else {
          formMap[key] = value;
        }
      });

      final formData = FormData.fromMap(formMap);

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

  /// Parse response của update-page -> SocialGetPage
  ///
  /// WoWonder thường trả:
  /// {
  ///   "api_status": 200,
  ///   "page_data": { ... page fields ... }
  /// }
  ///
  /// Hoặc 1 số bản có thể trả "data" thay vì "page_data".
  SocialGetPage? parseUpdatedPage(Response res) {
    dynamic data = res.data;

    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        return null;
      }
    }

    if (data is! Map) return null;
    final Map<String, dynamic> map = data as Map<String, dynamic>;

    final int status = (map['api_status'] as num?)?.toInt() ?? 0;
    if (status != 200) return null;

    final dynamic rawPage = map['page_data'] ?? map['data'];
    if (rawPage is! Map) return null;

    return _parseGetPageMap(rawPage);
  }
  Future<ApiResponseModel<Response>> getPagePosts({
    required int pageId,
    int? afterPostId,
    int limit = 10,
  }) async {
    try {
      final token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
          'Please log in to your social network account',
        );
      }

      // https://social.vnshop247.com/api/posts?access_token=...
      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialPostsUri}?access_token=$token';

      final Map<String, dynamic> formMap = <String, dynamic>{
        'server_key': AppConstants.socialServerKey,
        'type': 'get_page_posts',        // <-- đúng như Postman
        'id': pageId.toString(),         // id của page
        'limit': limit.toString(),
      };

      if (afterPostId != null && afterPostId > 0) {
        formMap['after_post_id'] = afterPostId.toString();
      }

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
  Future<ApiResponseModel<Response>> sendMessageToPage({
    required String pageId,
    required String recipientId,
    required String text,
    required String messageHashId,
    MultipartFile? file,     // optional
    String? gif,             // optional
    String? imageUrl,        // optional
    String? lng,             // optional
    String? lat,             // optional
  }) async {
    try {
      // Lấy access_token social
      final String? token = _getSocialAccessToken();
      if (token == null || token.isEmpty) {
        return ApiResponseModel.withError(
          'Bạn chưa đăng nhập tài khoản social.',
        );
      }

      // URL: base + /api/page_chat + access_token
      final String url =
          '${AppConstants.socialBaseUrl}${AppConstants.socialSendMessPage}?access_token=$token';

      // Body giống Postman: server_key, type, page_id, recipient_id, text, message_hash_id, ...
      final Map<String, dynamic> body = <String, dynamic>{
        'server_key': AppConstants.socialServerKey,
        'type': 'send',
        'page_id': pageId,
        'recipient_id': recipientId,
        'text': text,
        'message_hash_id': messageHashId,
      };

      if (file != null) body['file'] = file;
      if (gif != null && gif.isNotEmpty) body['gif'] = gif;
      if (imageUrl != null && imageUrl.isNotEmpty) body['image_url'] = imageUrl;
      if (lng != null && lng.isNotEmpty) body['lng'] = lng;
      if (lat != null && lat.isNotEmpty) body['lat'] = lat;

      final FormData formData = FormData.fromMap(body);

      final Response response = await dioClient.post(
        url,
        data: formData,
      );

      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }
}
