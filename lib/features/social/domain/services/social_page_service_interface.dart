import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_get_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'dart:io';

abstract class SocialPageServiceInterface {
  /// Lấy danh sách Page gợi ý cho user hiện tại
  Future<List<SocialGetPage>> getRecommendedPages({
    int limit,
  });
  Future<List<SocialGetPage>> getMyPages({
    int limit = 20,
  });
  Future<List<SocialArticleCategory>> getArticleCategories();
  Future<SocialGetPage> createPage({
    required String pageName,
    required String pageTitle,
    required int categoryId,
    String? description,
  });
  Future<List<SocialGetPage>> getLikedPages({int limit = 20, required String userId});
  Future<bool> toggleLikePage({required String pageId});

  /// Update page dùng luôn payload (map) từ EditPageScreen pop ra
  ///
  /// payload ví dụ:
  /// {
  ///   'page_id': '123',
  ///   'page_name': 'abc',
  ///   'page_title': 'Title',
  ///   'page_description': '...',
  ///   'avatar': File,
  ///   'cover': File,
  ///   ...
  /// }
  /// UPDATE: có thể ko trả về page_data → dùng SocialGetPage? (nullable)
  Future<SocialGetPage?> updatePage({
    required int pageId,
    String? pageName,
    String? pageTitle,
    String? description,
    int? categoryId,
    File? avatar,
    File? cover,
    Map<String, dynamic>? extraFields,
  });

  /// UPDATE dùng payload Map (từ EditPageScreen pop ra)
  Future<SocialGetPage?> updatePageFromPayload(
      Map<String, dynamic> payload,
      );
  Future<List<SocialPost>> getPagePosts({
    required int pageId,
    int limit = 10,
    int? afterPostId,
  });
}