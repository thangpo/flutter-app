import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_get_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_page_repository.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_page_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_page_mess.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_page_chat.dart';


class SocialPageService implements SocialPageServiceInterface {
  final SocialPageRepository socialPageRepository;
  final SocialController socialController;

  SocialPageService(
      {required this.socialPageRepository, required this.socialController});

  // ───────────────── GET RECOMMENDED PAGES ─────────────────
  @override
  Future<List<SocialGetPage>> getRecommendedPages({int limit = 20}) async {
    final ApiResponseModel<Response> resp =
    await socialPageRepository.fetchRecommendedPages(limit: limit);

    if (resp.isSuccess && resp.response != null) {
      final dynamic data = resp.response!.data;

      // Giữ đúng style như SocialGroupService:
      final int status =
          int.tryParse('${data?['api_status'] ?? data?['status'] ?? 200}') ??
              200;

      if (status == 200) {
        // Dùng hàm parse trong repository
        return socialPageRepository.parseRecommendedPages(resp.response!);
      }

      // Lấy message lỗi từ API nếu có
      final String message = (data?['errors']?['error_text'] ??
          data?['message'] ??
          'Failed to load recommended pages')
          .toString();
      throw Exception(message);
    }

    // Dùng ApiChecker giống bên Group
    ApiChecker.checkApi(resp);
    return <SocialGetPage>[]; // trong trường hợp checkApi không throw
  }

  // ───────────────── GET PAGE DETAIL ─────────────────
  @override
  Future<SocialGetPage> getPageDetail({
    String? pageId,
    String? pageName,
  }) async {
    final ApiResponseModel<Response> resp =
    await socialPageRepository.fetchPageDetail(
      pageId: pageId,
      pageName: pageName,
    );

    if (resp.isSuccess && resp.response != null) {
      dynamic data = resp.response!.data;

      // backend đôi khi trả string json
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {
          throw Exception('Invalid page detail response');
        }
      }

      if (data is! Map) {
        throw Exception('Invalid page detail response');
      }

      final Map<String, dynamic> map = Map<String, dynamic>.from(data as Map);

      final int status =
          int.tryParse('${map['api_status'] ?? map['status'] ?? 200}') ?? 200;

      if (status == 200) {
        Map<String, dynamic>? pageMap;

        if (map['page_data'] is Map) {
          pageMap = Map<String, dynamic>.from(map['page_data'] as Map);
        } else if (map['data'] is Map) {
          pageMap = Map<String, dynamic>.from(map['data'] as Map);
        } else if (map['page'] is Map) {
          pageMap = Map<String, dynamic>.from(map['page'] as Map);
        }

        if (pageMap == null) {
          throw Exception('Page detail: missing page data');
        }

        final SocialGetPage? page =
        socialPageRepository.parseSinglePageFromMap(pageMap);

        if (page == null) {
          throw Exception('Page detail: parse failed');
        }

        return page;
      }

      final String message = (map['errors']?['error_text'] ??
          map['message'] ??
          'Failed to load page detail')
          .toString();
      throw Exception(message);
    }

    ApiChecker.checkApi(resp);
    throw Exception('Failed to load page detail');
  }

  // ───────────────── GET MY PAGES ─────────────────
  @override
  Future<List<SocialGetPage>> getMyPages({int limit = 20}) async {
    final ApiResponseModel<Response> resp =
    await socialPageRepository.getMyPage(limit: limit);

    if (resp.isSuccess && resp.response != null) {
      final dynamic data = resp.response!.data;

      final int status =
          int.tryParse('${data?['api_status'] ?? data?['status'] ?? 200}') ??
              200;

      if (status == 200) {
        // JSON getMyPage cùng format với recommended → có thể tái dùng parser
        return socialPageRepository.parseMyPages(resp.response!);
      }

      final String message = (data?['errors']?['error_text'] ??
          data?['message'] ??
          'Failed to load your pages')
          .toString();
      throw Exception(message);
    }

    ApiChecker.checkApi(resp);
    return <SocialGetPage>[];
  }

  @override
  Future<List<SocialGetPage>> getLikedPages({
    int limit = 20,
    required String userId,
  }) async {
    final ApiResponseModel<Response> resp =
    await socialPageRepository.getLikedPages(
      limit: limit,
      userId: userId,
    );

    if (resp.isSuccess && resp.response != null) {
      final dynamic data = resp.response!.data;
      print('DEBUG LIKED PAGES RESPONSE: ${data.toString()}');

      final int status =
          int.tryParse('${data?['api_status'] ?? data?['status'] ?? 200}') ?? 200;

      if (status == 200) {
        // parse như cũ
        final pages = socialPageRepository.parseMyPages(resp.response!);

        // 🔥 VÌ ĐÂY LÀ API "LIKED PAGES" → 100% LÀ PAGE ĐÃ LIKE
        return pages
            .map(
              (p) => p.copyWith(isLiked: true),
        )
            .toList();
      }

      final String message = (data?['errors']?['error_text'] ??
          data?['message'] ??
          'Failed to load liked pages')
          .toString();
      throw Exception(message);
    }

    ApiChecker.checkApi(resp);
    return <SocialGetPage>[];
  }


  bool _parseLikeStatus(dynamic raw) {
    if (raw == null) return false;

    if (raw is bool) return raw;

    if (raw is num) return raw != 0;

    final s = raw.toString().toLowerCase().trim();
    // hỗ trợ nhiều kiểu backend có thể trả
    return s == 'liked' || s == '1' || s == 'true';
  }
  //───────────────── Like page ─────────────────
  @override
  Future<bool> toggleLikePage({required String pageId}) async {
    final ApiResponseModel<Response> resp =
    await socialPageRepository.likePage(pageId: pageId);

    if (resp.isSuccess && resp.response != null) {
      final dynamic data = resp.response!.data;
      print('DEBUG LIKE PAGE RESPONSE: $data');

      final int status =
          int.tryParse('${data?['api_status'] ?? data?['status'] ?? 400}') ?? 400;

      if (status == 200) {
        // 👉 Chỉ cần biết là gọi API thành công
        return true;
      }

      final String message = (data?['errors']?['error_text'] ??
          data?['message'] ??
          'Failed to like/unlike page')
          .toString();
      throw Exception(message);
    }

    ApiChecker.checkApi(resp);
    // request lỗi
    return false;
  }
  // ───────────────── DELETE PAGE ─────────────────
  @override
  Future<bool> deletePage({
    required String pageId,
    required String password,
  }) async {
    final ApiResponseModel<Response> resp =
    await socialPageRepository.deletePage(
      pageId: pageId,
      password: password,
    );

    if (resp.isSuccess && resp.response != null) {
      dynamic data = resp.response!.data;

      // Backend đôi khi trả string → decode JSON
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {
          // nếu không decode được thì xử lý như bên dưới
        }
      }

      if (data is Map) {
        final int status =
            int.tryParse('${data['api_status'] ?? data['status'] ?? 400}') ??
                400;

        if (status == 200) {
          // xoá thành công
          return true;
        }

        final String message = (data['errors']?['error_text'] ??
            data['message'] ??
            'Failed to delete page')
            .toString();
        throw Exception(message);
      }

      // data không phải Map → coi như lỗi
      throw Exception('Invalid delete page response');
    }

    // request fail / lỗi HTTP
    ApiChecker.checkApi(resp);
    return false;
  }




  // ───────────────── GET ARTICLE CATEGORIES ─────────────────
  @override
  Future<List<SocialArticleCategory>> getArticleCategories() async {
    final ApiResponseModel<Response> resp =
    await socialPageRepository.fetchArticleCategories();

    if (resp.isSuccess && resp.response != null) {
      final dynamic data = resp.response!.data;

      final int status =
          int.tryParse('${data?['api_status'] ?? data?['status'] ?? 200}') ??
              200;

      if (status == 200) {
        // Dùng parser trong repository
        return socialPageRepository.parseArticleCategories(resp.response!);
      }

      final String message = (data?['errors']?['error_text'] ??
          data?['message'] ??
          'Failed to load article categories')
          .toString();
      throw Exception(message);
    }

    ApiChecker.checkApi(resp);
    return <SocialArticleCategory>[];
  }

  // ───────────────── CREATE PAGE ─────────────────
  @override
  Future<SocialGetPage> createPage({
    required String pageName,
    required String pageTitle,
    required int categoryId,
    String? description,
  }) async {
    final ApiResponseModel<Response> resp =
    await socialPageRepository.createPage(
      pageName: pageName,
      pageTitle: pageTitle,
      categoryId: categoryId,
      description: description,
    );

    if (resp.isSuccess && resp.response != null) {
      dynamic data = resp.response!.data;

      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {
          throw Exception('Invalid create page response');
        }
      }

      final int status =
          int.tryParse('${data?['api_status'] ?? data?['status'] ?? 200}') ??
              200;

      if (status == 200) {
        Map<String, dynamic>? pageMap;

        if (data is Map<String, dynamic>) {
          if (data['page_data'] is Map) {
            pageMap = Map<String, dynamic>.from(
              data['page_data'] as Map<dynamic, dynamic>,
            );
          } else if (data['data'] is Map) {
            pageMap = Map<String, dynamic>.from(
              data['data'] as Map<dynamic, dynamic>,
            );
          }
        }

        if (pageMap != null) {
          final SocialGetPage? page =
          socialPageRepository.parseSinglePageFromMap(pageMap);
          if (page != null) {
            return page;
          }
        }

        throw Exception('Page created but response format is not recognized');
      }

      final String message = (data?['errors']?['error_text'] ??
          data?['message'] ??
          'Failed to create page')
          .toString();
      throw Exception(message);
    }

    ApiChecker.checkApi(resp);
    throw Exception('Failed to create page');
  }

  @override
  Future<SocialGetPage?> updatePage({
    required int pageId,
    String? pageName,
    String? pageTitle,
    String? description,
    int? categoryId,
    File? avatar,
    File? cover,
    Map<String, dynamic>? extraFields,
  }) async {
    final ApiResponseModel<Response> resp =
    await socialPageRepository.updatePage(
      pageId: pageId,
      pageName: pageName,
      pageTitle: pageTitle,
      description: description,
      categoryId: categoryId,
      avatar: avatar,
      cover: cover,
      extraFields: extraFields,
    );

    return _tryParsePageFromUpdateResponse(
      resp,
      defaultErrorText: 'Failed to update page',
    );
  }

  // ───────────────── UPDATE PAGE (dùng payload từ EditPageScreen) ─────────────────
  @override
  Future<SocialGetPage?> updatePageFromPayload(
      Map<String, dynamic> payload,) async {
    final ApiResponseModel<Response> resp =
    await socialPageRepository.updatePageFromPayload(payload);

    return _tryParsePageFromUpdateResponse(
      resp,
      defaultErrorText: 'Failed to update page',
    );
  }

  /// Helper parse response update-page.
  ///
  /// - Nếu `status != 200` và message **không** chứa "Your page was updated"
  ///   → ném Exception (thật sự lỗi).
  /// - Nếu `status == 200` nhưng không có `page_data` / `data`
  ///   → coi là **success**, trả `null`.
  /// - Nếu message / error_text chứa "Your page was updated"
  ///   → coi là **success**, trả `null` (tránh Exception: Your page was updated).
  SocialGetPage? _tryParsePageFromUpdateResponse(
      ApiResponseModel<Response> resp, {
        required String defaultErrorText,
      }) {
    if (!resp.isSuccess || resp.response == null) {
      ApiChecker.checkApi(resp);
      throw Exception(defaultErrorText);
    }

    dynamic data = resp.response!.data;

    // Nếu là string thì thử decode JSON
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        // nếu không decode được, phía dưới sẽ xử lý tiếp
      }
    }

    // Nếu hoàn toàn không phải Map (ví dụ trả về plain text)
    if (data is! Map) {
      final String text = data.toString();
      final String lower = text.toLowerCase();
      if (lower.contains('your page was updated')) {
        // 👉 backend trả text "Your page was updated" nhưng không phải JSON
        // => coi là update thành công nhưng không có page_data
        return null;
      }
      throw Exception('Invalid update page response');
    }

    final Map<String, dynamic> map = data as Map<String, dynamic>;

    final int status =
        int.tryParse('${map['api_status'] ?? map['status'] ?? 200}') ?? 200;

    final String rawErrorText =
    (map['errors']?['error_text'] ?? map['message'] ?? '').toString();
    final String normalizedError = rawErrorText.toLowerCase();

    // ====== CASE: status != 200 ======
    if (status != 200) {
      // 👉 Trường hợp đặc biệt: WoWonder nhiều khi trả "Your page was updated"
      // trong errors.error_text nhưng status lại != 200.
      if (normalizedError.contains('your page was updated')) {
        // coi là THÀNH CÔNG, không ném lỗi
        return null;
      }

      final String message =
      rawErrorText.isNotEmpty ? rawErrorText : defaultErrorText;
      throw Exception(message);
    }

    // ====== CASE: status == 200 (success) ======
    Map<String, dynamic>? pageMap;

    if (map['page_data'] is Map) {
      pageMap = Map<String, dynamic>.from(
        map['page_data'] as Map<dynamic, dynamic>,
      );
    } else if (map['data'] is Map) {
      pageMap = Map<String, dynamic>.from(
        map['data'] as Map<dynamic, dynamic>,
      );
    }

    // Không có page_data → vẫn coi là success
    if (pageMap == null) {
      return null;
    }

    final SocialGetPage? page =
    socialPageRepository.parseSinglePageFromMap(pageMap);

    // parse lỗi → coi là success nhưng không có page
    return page;
  }



  @override
  Future<List<SocialPost>> getPagePosts({
    required int pageId,
    int limit = 10,
    int? afterPostId,
  }) async {
    final ApiResponseModel<Response> resp =
    await socialPageRepository.getPagePosts(
      pageId: pageId,
      afterPostId: afterPostId,
      limit: limit,
    );

    if (resp.isSuccess && resp.response != null) {
      dynamic data = resp.response!.data;

      // Nếu backend trả string thì decode JSON
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {
          throw Exception('Invalid page posts response');
        }
      }

      if (data is! Map) {
        throw Exception('Invalid page posts response');
      }
      final Map<String, dynamic> map = data as Map<String, dynamic>;

      final int status =
          int.tryParse('${map['api_status'] ?? map['status'] ?? 200}') ?? 200;

      if (status == 200) {
        // tuỳ backend: thường là 'data' hoặc 'posts'
        final List<dynamic> list =
        (map['data'] ?? map['posts'] ?? const <dynamic>[])
        as List<dynamic>;

        final List<SocialPost> posts = <SocialPost>[];

        for (final dynamic item in list) {
          if (item is! Map) continue;
          try {
            // 👉 DÙNG HÀM MAP RIÊNG, KHÔNG GỌI fromJson NỮA
            posts.add(
              _mapJsonToSocialPost(
                Map<String, dynamic>.from(item as Map),
              ),
            );
          } catch (e, st) {
            // optional: log nếu cần debug
            // print('PARSE PAGE POST ERROR: $e\n$st');
          }
        }

        return posts;
      }

      final String message = (map['errors']?['error_text'] ??
          map['message'] ??
          'Failed to load page posts')
          .toString();
      throw Exception(message);
    }

    ApiChecker.checkApi(resp);
    return <SocialPost>[];
  }


  SocialPost _mapJsonToSocialPost(Map<String, dynamic> j) {
    final Map pub =
    (j['publisher'] is Map) ? j['publisher'] as Map : const {};

    // Lấy list ảnh
    final List<String> imageUrls = <String>[];
    if (j['photo_multi'] is List) {
      for (final dynamic item in (j['photo_multi'] as List)) {
        if (item is Map && item['image'] != null) {
          final String url = item['image'].toString();
          if (url.isNotEmpty) imageUrls.add(url);
        }
      }
    } else if (j['postFile'] != null &&
        j['postFile'].toString().isNotEmpty) {
      imageUrls.add(j['postFile'].toString());
    }

    // ------------ REACTION MỚI ------------
    final dynamic rawReaction = j['reaction'];

    // mặc định
    int reactionCount =
        int.tryParse('${j['reaction_count'] ?? j['reactors'] ?? 0}') ?? 0;
    String myReaction = '';
    Map<String, int> reactionBreakdown = const <String, int>{};

    if (rawReaction is Map) {
      // nếu backend có field count trong reaction thì ưu tiên
      final dynamic rawCount = rawReaction['count'] ?? rawReaction['all'];
      if (rawCount != null) {
        reactionCount = int.tryParse('$rawCount') ?? reactionCount;
      }

      // đã react hay chưa
      final bool isReacted =
          rawReaction['is_reacted'] == 1 ||
              rawReaction['is_react'] == 1 ||
              rawReaction['is_reacted'] == true;

      if (isReacted) {
        final dynamic typeVal = rawReaction['type'];
        final String typeStr = typeVal?.toString() ?? '';

        // tuỳ backend: có thể trả '1'..'6' hoặc 'Like' / 'Love'
        myReaction = _mapReactionType(typeStr);
      }

      // breakdown theo id reaction nếu bạn cần
      int _toInt(dynamic v) => int.tryParse('$v') ?? 0;

      reactionBreakdown = <String, int>{
        'Like': _toInt(rawReaction['1']),
        'Love': _toInt(rawReaction['2']),
        'HaHa': _toInt(rawReaction['3']),
        'Wow': _toInt(rawReaction['4']),
        'Sad': _toInt(rawReaction['5']),
        'Angry': _toInt(rawReaction['6']),
      }..removeWhere((_, value) => value == 0);
    } else if (rawReaction is String) {
      // trường hợp API nào đó đã trả sẵn 'Like', 'Love'...
      myReaction = rawReaction;
    }

    // ------------ COMMENT / SHARE ------------
    final int commentCount =
        int.tryParse('${j['post_comments'] ?? j['comments'] ?? 0}') ?? 0;
    final int shareCount =
        int.tryParse('${j['post_shares'] ?? j['shares'] ?? 0}') ?? 0;

    // Page id: ưu tiên field page_id, fallback từ publisher khi có
    String? _resolvePageId() {
      final String? raw = j['page_id']?.toString();
      final String? norm = raw?.trim();
      if (norm != null && norm.isNotEmpty && norm != '0') return norm;

      final String? pubPage = pub['page_id']?.toString() ?? pub['id']?.toString();
      final String? normPub = pubPage?.trim();
      if (normPub != null && normPub.isNotEmpty && normPub != '0') return normPub;
      return null;
    }

    return SocialPost(
      id: (j['post_id'] ?? j['id'] ?? '').toString(),
      publisherId: (pub['user_id'] ?? pub['id'] ?? '').toString(),
      text: j['postText']?.toString(),
      rawText: j['Orginaltext']?.toString() ?? j['postText']?.toString(),
      userName: (pub['name'] ?? pub['username'] ?? '').toString(),
      userAvatar: pub['avatar']?.toString(),
      timeText: j['time_text']?.toString(),
      pageId: _resolvePageId(),
      postType: j['postType']?.toString(),
      imageUrls: imageUrls,
      imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
      fileUrl: j['postFile']?.toString(),

      reactionCount: reactionCount,
      myReaction: myReaction,
      reactionBreakdown: reactionBreakdown,

      commentCount: commentCount,
      shareCount: shareCount,

      hasProduct: false,
    );
  }


  /// ───────────────── PAGE CHAT: SEND MESSAGE ─────────────────
  @override
    /// PAGE CHAT: SEND MESSAGE
  @override
  Future<List<SocialPageMessage>> sendPageMessage({
    required String pageId,
    required String recipientId, // receiver id
    required String text,
    required String messageHashId,
    MultipartFile? file,
    MultipartFile? voiceFile,
    String? voiceDuration,
    String? gif,
    String? imageUrl,
    String? lng,
    String? lat,
  }) async {
    final ApiResponseModel<Response> resp =
        await socialPageRepository.sendMessageToPage(
      pageId: pageId,
      recipientId: recipientId,
      text: text,
      messageHashId: messageHashId,
      file: file,
      voiceFile: voiceFile,
      voiceDuration: voiceDuration,
      gif: gif,
      imageUrl: imageUrl,
      lng: lng,
      lat: lat,
    );

    if (resp.isSuccess && resp.response != null) {
      final messages = socialPageRepository.parsePageMessages(resp.response!);
      if (messages.isNotEmpty) {
        return messages;
      }

      final dynamic data = resp.response!.data;
      final String message = (data?['errors']?['error_text'] ??
              data?['message'] ??
              'Failed to send page message')
          .toString();
      return <SocialPageMessage>[];
    }

    return <SocialPageMessage>[];
  }

/// ───────────────── PAGE CHAT: FETCH MESSAGES ─────────────────
  @override
  Future<List<SocialPageMessage>> getPageMessages({
    required String pageId,
    required String recipientId,  // recipientId là người nhận tin nhắn
    int? afterMessageId,
    int? beforeMessageId,
    int limit = 20,
  }) async {
    final ApiResponseModel<Response> resp =
    await socialPageRepository.fetchPageMessages(
      pageId: pageId,
      recipientId: recipientId,  // Truyền recipientId là người nhận tin nhắn
      after: afterMessageId,
      before: beforeMessageId,
      limit: limit,
    );

    if (resp.isSuccess && resp.response != null) {
      final messages = socialPageRepository.parsePageMessages(resp.response!);
      return messages;
    }

    ApiChecker.checkApi(resp);
    return <SocialPageMessage>[];  // fallback nếu checkApi không throw
  }


  /// Parse response page_chat -> List<SocialPageMessage>
  List<SocialPageMessage> _parsePageMessages(Response res) {
    final List<SocialPageMessage> result = <SocialPageMessage>[];
    dynamic data = res.data;

    // Trường hợp API trả JSON dạng String
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        return result;
      }
    }

    if (data is! Map) return result;
    final Map<String, dynamic> map = data as Map<String, dynamic>;

    final int status =
        int.tryParse('${map['api_status'] ?? map['status'] ?? 200}') ?? 200;
    if (status != 200) return result;

    final List<dynamic> list = map['data'] as List<dynamic>? ?? const <dynamic>[];

    for (final dynamic item in list) {
      if (item is! Map) continue;
      try {
        result.add(
          SocialPageMessage.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        );
      } catch (_) {
        // parse lỗi thì bỏ qua phần tử đó
      }
    }

    return result;
  }


  /// Map type backend -> tên reaction trong app
  String _mapReactionType(String typeStr) {
    switch (typeStr) {
      case '1':
        return 'Like';
      case '2':
        return 'Love';
      case '3':
        return 'HaHa';
      case '4':
        return 'Wow';
      case '5':
        return 'Sad';
      case '6':
        return 'Angry';
      default:
      // Nếu backend đã trả 'Like', 'Love' sẵn thì dùng luôn
        return typeStr;
    }
  }
  //chat page
  @override
  Future<List<PageChatThread>> getPageChatList({
    int limit = 50,
    int offset = 0,
  }) async {
    final resp = await socialPageRepository.fetchPageChatList(
      limit: limit,
      offset: offset,
    );

    if (resp.isSuccess && resp.response != null) {
      return socialPageRepository.parsePageChatList(resp.response!);
    }

    ApiChecker.checkApi(resp);
    return <PageChatThread>[];
  }

  @override
  Future<PageUserBrief?> getUserDataById({required String userId}) async {
    final resp = await socialPageRepository.fetchUserDataById(userId: userId);

    if (resp.isSuccess && resp.response != null) {
      try {
        final data = resp.response!.data;
        Map<String, dynamic>? userMap;
        if (data is Map && data['user_data'] is Map) {
          userMap = Map<String, dynamic>.from(data['user_data'] as Map);
        }
        if (userMap == null) return null;
        final String name = (userMap['name'] ?? userMap['username'] ?? '')
            .toString();
        final String avatar = (userMap['avatar'] ?? '').toString();
        return PageUserBrief(
          id: (userMap['user_id'] ?? userId).toString(),
          name: name,
          avatar: avatar,
        );
      } catch (_) {
        return null;
      }
    }

    ApiChecker.checkApi(resp);
    return null;
  }


}
