import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_get_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_page_repository.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_page_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
class SocialPageService implements SocialPageServiceInterface {
  final SocialPageRepository socialPageRepository;
  final SocialController socialController;

  SocialPageService({required this.socialPageRepository,required this.socialController});

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
    required String userId, // <-- 1. THÊM THAM SỐ NÀY
  }) async {
    // 2. GỌI HÀM MỚI (getLikedPages) TRONG REPO, KHÔNG GỌI getMyPage
    final ApiResponseModel<Response> resp =
    await socialPageRepository.getLikedPages(
      limit: limit,
      userId: userId, // <-- 3. TRUYỀN USER ID XUỐNG
    );

    if (resp.isSuccess && resp.response != null) {
      final dynamic data = resp.response!.data;
      print('DEBUG LIKED PAGES RESPONSE: ${data.toString()}');
      final int status =
          int.tryParse('${data?['api_status'] ?? data?['status'] ?? 200}') ?? 200;

      if (status == 200) {
        return socialPageRepository.parseMyPages(resp.response!);
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
      Map<String, dynamic> payload,
      ) async {
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
}

