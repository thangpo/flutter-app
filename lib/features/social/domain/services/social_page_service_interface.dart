import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_get_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_page_mess.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_page_chat.dart';

class PageUserBrief {
  final String id;
  final String name;
  final String avatar;

  const PageUserBrief({
    required this.id,
    required this.name,
    required this.avatar,
  });
}


abstract class SocialPageServiceInterface {
  /// Lấy danh sách Page gợi ý
  Future<List<SocialGetPage>> getRecommendedPages({
    int limit,
  });

  /// Lấy page của tôi
  Future<List<SocialGetPage>> getMyPages({int limit = 20});

  /// Liked pages
  Future<List<SocialGetPage>> getLikedPages({
    int limit,
    required String userId,
  });

  /// Like / Unlike page
  Future<bool> toggleLikePage({required String pageId});

  /// Danh mục bài viết
  Future<List<SocialArticleCategory>> getArticleCategories();

  /// Tạo Page
  Future<SocialGetPage> createPage({
    required String pageName,
    required String pageTitle,
    required int categoryId,
    String? description,
  });

  /// Update Page (cách cũ)
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

  /// Update Page (payload từ UI)
  Future<SocialGetPage?> updatePageFromPayload(
      Map<String, dynamic> payload,
      );

  /// Lấy bài viết của Page
  Future<List<SocialPost>> getPagePosts({
    required int pageId,
    int limit,
    int? afterPostId,
  });

  Future<SocialGetPage> getPageDetail({
    String? pageId,
    String? pageName,
  });

  // ────────────────────────────────────────────────
  // 🔥 PAGE CHAT
  // ────────────────────────────────────────────────

  /// Gửi tin nhắn đến Page (owner)
  Future<List<SocialPageMessage>> sendPageMessage({
    required String pageId,
    required String recipientId,
    required String text,
    required String messageHashId,
    MultipartFile? file,
    MultipartFile? voiceFile,
    String? voiceDuration,
    String? gif,
    String? imageUrl,
    String? lng,
    String? lat,
  });

  /// Lấy lịch sử chat (fetch old/new message)
  Future<List<SocialPageMessage>> getPageMessages({
    required String pageId,
    required String recipientId,
    int? afterMessageId,
    int? beforeMessageId,
    int limit,
  });
  Future<List<PageChatThread>> getPageChatList({
    int limit,
    int offset,
  });
  Future<PageUserBrief?> getUserDataById({required String userId});
  Future<bool> deletePage({
    required String pageId,
    required String password,
  });

}
