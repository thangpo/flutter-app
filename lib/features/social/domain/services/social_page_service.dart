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
}
