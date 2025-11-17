import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_get_page.dart';
abstract class SocialPageServiceInterface {
  /// Lấy danh sách Page gợi ý cho user hiện tại
  Future<List<SocialGetPage>> getRecommendedPages({
    int limit,
  });
  Future<List<SocialGetPage>> getMyPages({
    int limit = 20,
  });
  Future<List<SocialArticleCategory>> getArticleCategories();
}