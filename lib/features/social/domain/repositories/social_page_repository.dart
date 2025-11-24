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
  import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_page_chat.dart';
  import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_page_mess.dart';
  import 'package:flutter_sixvalley_ecommerce/features/social/utils/wowonder_text.dart';
  import 'package:encrypt/encrypt.dart' as enc;


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
    // Tìm hàm _hydratePageMessage cũ và thay bằng hàm này:



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

    String decryptWoWonder(String base64Text, String timeStr) {
      try {
        if (base64Text.isEmpty || timeStr.isEmpty) return base64Text;

        final keyStr = timeStr.padRight(16, '0').substring(0, 16);
        final key = enc.Key.fromUtf8(keyStr);
        final iv = enc.IV.fromUtf8(keyStr);

        final encrypter = enc.Encrypter(
          enc.AES(key, mode: enc.AESMode.cbc, padding: 'PKCS7'),
        );

        return encrypter.decrypt(
          enc.Encrypted.fromBase64(base64Text),
          iv: iv,
        );
      } catch (_) {
        return base64Text;
      }
    }

    void _hydratePageMessage(Map<String, dynamic> m) {
      // --- 1) DECRYPT TEXT ---
      final rawText = '${m["text"] ?? ""}';
      final rawTime = '${m["time"] ?? ""}';

      if (rawText.isNotEmpty && rawTime.isNotEmpty) {
        final decrypted = decryptWoWonder(rawText, rawTime);
        m["text"] = decrypted;
      }

      // --- 2) DECRYPT REPLY ---
      if (m["reply"] is Map) {
        final r = Map<String, dynamic>.from(m["reply"]);
        final rText = '${r["text"] ?? ""}';
        final rTime = '${r["time"] ?? ""}';

        if (rText.isNotEmpty && rTime.isNotEmpty) {
          r["text"] = decryptWoWonder(rText, rTime);
        }

        m["reply"] = r;
      }

      // --- 3) HYDRATE display_text ---
      m['display_text'] = pickWoWonderText(m);

      if (m['reply'] is Map) {
        final r = Map<String, dynamic>.from(m['reply']);
        r['display_text'] = pickWoWonderText(r);
        m['reply'] = r;
      }

      // --- 4) MEDIA LOGIC ---
      String media = '';
      if (m['media'] != null && '${m['media']}'.isNotEmpty) {
        media = '${m['media']}';
      } else if (m['mediaFileName'] != null && '${m['mediaFileName']}'.isNotEmpty) {
        media = '${m['mediaFileName']}';
      } else if (m['mediaFileNames'] != null && '${m['mediaFileNames']}'.isNotEmpty) {
        media = '${m['mediaFileNames']}';
      }

      if (media.isNotEmpty) {
        final ext = p.extension(media).toLowerCase();
        final isImage = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext);
        final isVideo = ['.mp4', '.mov', '.m4v', '.webm', '.qt'].contains(ext);
        final isAudio = ['.m4a', '.aac', '.mp3', '.wav', '.ogg'].contains(ext);

        m['media_ext'] = ext;
        m['media_url'] = _absoluteUrl(media);
        m['is_image'] = isImage;
        m['is_video'] = isVideo;
        m['is_audio'] = isAudio;

        if (isImage || isVideo || isAudio) {
          m['text'] = "";
          m['display_text'] = "";
        }
      }
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
          return ApiResponseModel.withError('Bạn chưa đăng nhập tài khoản social.');
        }

        // URL: base + /api/page_chat + access_token
        final String url =
            '${AppConstants.socialBaseUrl}${AppConstants.socialSendMessPage}?access_token=$token';

        // Log URL và token để kiểm tra
        print('Sending request to URL: $url');
        print('Using token: $token');

        // Body: server_key, type, page_id, recipient_id, message_hash_id, ...
        final Map<String, dynamic> body = <String, dynamic>{
          'server_key': AppConstants.socialServerKey,
          'type': 'send',
          'page_id': pageId,
          'recipient_id': recipientId,
          'message_hash_id': messageHashId,
        };

        // Log request body để kiểm tra
        print('Request body: ${jsonEncode(body)}');

        // Kiểm tra và log text nếu có
        if (text.trim().isNotEmpty) {
          body['text'] = text;
          print("Text to be sent: $text");
        } else {
          print("Text is empty or invalid");
          return ApiResponseModel.withError("Text cannot be empty");
        }

        // Log các tham số optional nếu có
        if (file != null) {
          body['file'] = file;
          print("File attached: ${file.filename}");
        }

        if (gif != null && gif.isNotEmpty) {
          body['gif'] = gif;
          print("GIF attached: $gif");
        }

        if (imageUrl != null && imageUrl.isNotEmpty) {
          body['image_url'] = imageUrl;
          print("Image URL attached: $imageUrl");
        }

        if (lng != null && lng.isNotEmpty) {
          body['lng'] = lng;
          print("Longitude attached: $lng");
        }

        if (lat != null && lat.isNotEmpty) {
          body['lat'] = lat;
          print("Latitude attached: $lat");
        }

        // Log final body data
        print("Final body to be sent: ${jsonEncode(body)}");

        final FormData formData = FormData.fromMap(body);

        // Gửi yêu cầu POST đến API
        final Response response = await dioClient.post(
          url,
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        );

        // Log response status code và body
        print('Response status code: ${response.statusCode}');
        print('Response body: ${jsonEncode(response.data)}');

        // Kiểm tra và trả về phản hồi thành công
        if (response.statusCode == 200 && response.data['api_status'] == 200) {
          return ApiResponseModel.withSuccess(response);
        } else {
          // Log API status và message nếu không thành công
          final String apiStatus = response.data['api_status'].toString();
          final String errorMessage = response.data['errors']?['error_text'] ??
              response.data['message'] ??
              'Unknown error';
          print("API Error: Status: $apiStatus, Message: $errorMessage");
          return ApiResponseModel.withError('Failed to send message: $errorMessage');
        }
      } catch (e) {
        // Log lỗi chi tiết
        print('Error while sending message: $e');
        return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
      }
    }



    Future<ApiResponseModel<Response>> fetchPageMessages({
      required String pageId,
      required String recipientId,
      int? after,
      int? before,
      int limit = 20,
    }) async {
      try {
        final String? token = _getSocialAccessToken();
        if (token == null || token.isEmpty) {
          return ApiResponseModel.withError('Bạn chưa đăng nhập tài khoản social.');
        }

        final String url =
            '${AppConstants.socialBaseUrl}${AppConstants.socialGetChatPage}?access_token=$token';

        final Map<String, dynamic> body = <String, dynamic>{
          'server_key': AppConstants.socialServerKey,
          'type': 'fetch',
          'page_id': pageId,
          'recipient_id': recipientId,
          'limit': limit.toString(),
        };

        if (after != null) body['after'] = after.toString();
        if (before != null) body['before'] = before.toString();

        final Response response = await dioClient.post(
          url,
          data: FormData.fromMap(body),
          options: Options(contentType: 'multipart/form-data'),
        );

        return ApiResponseModel.withSuccess(response);
      } catch (e) {
        return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
      }
    }

    // Trong SocialPageRepository

    // Future<ApiResponseModel<Response>> fetchPageChat({
    //   required String pageId,
    //   required String recipientId,
    //   int limit = 20,
    //   int? afterMessageId,     // lấy tin mới hơn
    //   int? beforeMessageId,    // lấy tin cũ hơn
    // }) async {
    //   try {
    //     final String? token = _getSocialAccessToken();
    //     if (token == null || token.isEmpty) {
    //       return ApiResponseModel.withError("Bạn chưa đăng nhập Social!");
    //     }
    //
    //     final String url =
    //         '${AppConstants.socialBaseUrl}${AppConstants.socialGetChatPage}?access_token=$token';
    //
    //     final form = FormData.fromMap({
    //       'server_key': AppConstants.socialServerKey,
    //       'type': 'fetch',
    //       'page_id': pageId,
    //       'recipient_id': recipientId,
    //       'limit': limit.toString(),
    //       if (afterMessageId != null) 'after': afterMessageId.toString(),
    //       if (beforeMessageId != null) 'before': beforeMessageId.toString(),
    //     });
    //
    //     final Response res = await dioClient.post(
    //       url,
    //       data: form,
    //       options: Options(contentType: 'multipart/form-data'),
    //     );
    //
    //     return ApiResponseModel.withSuccess(res);
    //   } catch (e) {
    //     return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    //   }
    // }
    // --------------------------------------------------------------
  // PARSE PAGE MESSAGES (dùng chung cho fetch + send)
  // --------------------------------------------------------------
    List<SocialPageMessage> parsePageMessages(Response res) {
      final List<SocialPageMessage> result = [];

      dynamic data = res.data;

      // Trường hợp API trả string
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {
          return result;
        }
      }

      if (data is! Map) return result;

      final int status =
          int.tryParse('${data['api_status'] ?? data['status'] ?? 200}') ?? 200;
      if (status != 200) return result;

      final List<dynamic> list = data['data'] ?? [];

      for (final dynamic it in list) {
        if (it is Map<String, dynamic>) {

          // 🔥🔥 Quan trọng để remove Base64 🔥🔥
          _hydratePageMessage(it);

          try {
            result.add(SocialPageMessage.fromJson(it));
          } catch (_) {}
        }
      }

      return result;
    }


    List<SocialPageMessage> parsePageChat(Response res) {
      final List<SocialPageMessage> messages = [];

      dynamic data = res.data;

      // Nếu backend trả string → decode
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {
          return messages;
        }
      }

      if (data is! Map) return messages;

      if (data['api_status'] != 200) return messages;

      final List raw = data['data'] ?? [];

      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          _hydratePageMessage(item);
          messages.add(SocialPageMessage.fromJson(item));

        }
      }

      return messages;
    }

    // void _hydratePageMessage(Map<String, dynamic> m) {
    //   m['display_text'] = pickWoWonderText(m);
    //
    //   // nếu có reply → decode luôn reply
    //   if (m['reply'] is Map) {
    //     final r = Map<String, dynamic>.from(m['reply']);
    //     r['display_text'] = pickWoWonderText(r);
    //     m['reply'] = r;
    //   }
    // }


    Future<ApiResponseModel<Response>> fetchPageChatList({
      int limit = 50,
      int offset = 0,
    }) async {
      try {
        final token = _getSocialAccessToken();
        if (token == null) {
          return ApiResponseModel.withError("Bạn chưa đăng nhập Social!");
        }

        final String url =
            '${AppConstants.socialBaseUrl}${AppConstants.socialGetPageChatList}?access_token=$token';

        final form = FormData.fromMap({
          'server_key': AppConstants.socialServerKey,
          'type': 'get_list',
          'limit': limit.toString(),
          'offset': offset.toString(),
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
    List<PageChatThread> parsePageChatList(Response res) {
      final List<PageChatThread> list = [];

      dynamic data = res.data;

      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {
          return list;
        }
      }

      if (data is! Map) return list;

      if (data['api_status'] != 200) return list;

      final List<dynamic> rows = data['data'] ?? [];

      for (var x in rows) {
        if (x is Map<String, dynamic>) {
          list.add(PageChatThread.fromJson(x));
        }
      }
      return list;
    }
  }
