import 'package:dio/dio.dart';

import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_get_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_page_repository.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_page_service_interface.dart';

class SocialPageService implements SocialPageServiceInterface {
  final SocialPageRepository socialPageRepository;

  SocialPageService({required this.socialPageRepository});
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
}
