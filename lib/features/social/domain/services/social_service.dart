import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_comment.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';

import 'social_service_interface.dart';

class SocialService implements SocialServiceInterface {
  final SocialRepository socialRepository;
  SocialService({required this.socialRepository});

  // Feeds
  @override
  Future<List<SocialPost>> getNewsFeed({int limit = 10, String? afterPostId}) async {
    final resp = await socialRepository.fetchNewsFeed(
      limit: limit,
      afterPostId: afterPostId,
    );
    if (resp.isSuccess && resp.response != null && resp.response!.statusCode == 200) {
      final page = socialRepository.parseNewsFeed(resp.response!);
      return page.posts;
    }
    ApiChecker.checkApi(resp);
    return [];
  }

  // Stories
  @override
  Future<List<SocialStory>> getStories({int limit = 10, int offset = 0}) async {
    final resp = await socialRepository.fetchStories(limit: limit, offset: offset);
    if (resp.isSuccess && resp.response != null && resp.response!.statusCode == 200) {
      return socialRepository.parseStories(resp.response!);
    }
    ApiChecker.checkApi(resp);
    return [];
  }

  @override
  Future<void> reactToPost({
    required String postId,
    required String reaction,
    String action = 'reaction',
  }) async {
    final resp = await socialRepository.reactToPostWithAction(
      postId: postId,
      reaction: reaction,
      action: action,
    );

    if (resp.isSuccess && resp.response != null) {
      final data = resp.response!.data;
      final status = int.tryParse('${data?['api_status'] ?? 200}') ?? 200;
      if (status != 200) {
        final msg = (data?['errors']?['error_text'] ?? 'Reaction failed').toString();
        throw Exception(msg);
      }
      return;
    }

    ApiChecker.checkApi(resp);
    throw Exception('Reaction failed');
  }

  @override
  Future<SocialPost?> getPostById({required String postId}) async {
    final resp = await socialRepository.fetchPostData(postId: postId);
    if (resp.isSuccess && resp.response != null) {
      final data = resp.response!.data;
      final status = int.tryParse('${data?['api_status'] ?? 200}') ?? 200;
      if (status == 200) {
        return socialRepository.parsePostData(resp.response!);
      }
      final msg = (data?['errors']?['error_text'] ?? 'Load post failed').toString();
      throw Exception(msg);
    }
    ApiChecker.checkApi(resp);
    return null;
  }

  @override
  Future<List<SocialComment>> getPostComments({required String postId, int? limit, int? offset}) async {
    final resp = await socialRepository.fetchComments(postId: postId, limit: limit, offset: offset);
    if (resp.isSuccess && resp.response != null) {
      final data = resp.response!.data;
      final status = int.tryParse('${data?['api_status'] ?? 200}') ?? 200;
      if (status == 200) {
        return socialRepository.parsePostComments(resp.response!);
      }
      final msg = (data?['errors']?['error_text'] ?? 'Load comments failed').toString();
      throw Exception(msg);
    }
    ApiChecker.checkApi(resp);
    return [];
  }

  @override
  Future<List<SocialComment>> getCommentReplies({required String commentId}) async {
    final resp = await socialRepository.fetchCommentReplies(commentId: commentId);
    if (resp.isSuccess && resp.response != null) {
      final data = resp.response!.data;
      final status = int.tryParse('${data?['api_status'] ?? 200}') ?? 200;
      if (status == 200) {
        return socialRepository.parseCommentReplies(resp.response!);
      }
      final msg = (data?['errors']?['error_text'] ?? 'Load replies failed').toString();
      throw Exception(msg);
    }
    ApiChecker.checkApi(resp);
    return [];
  }

  @override
  Future<void> createComment({
    required String postId,
    required String text,
    String? imagePath,
    String? audioPath,
    String? imageUrl,
  }) async {
    final resp = await socialRepository.createComment(
      postId: postId,
      text: text,
      imagePath: imagePath,
      audioPath: audioPath,
      imageUrl: imageUrl,
    );
    if (resp.isSuccess && resp.response != null) {
      final data = resp.response!.data;
      final status = int.tryParse('${data?['api_status'] ?? 200}') ?? 200;
      if (status == 200) return;
      final msg = (data?['errors']?['error_text'] ?? 'Create comment failed').toString();
      throw Exception(msg);
    }
    ApiChecker.checkApi(resp);
    throw Exception('Create comment failed');
  }

  @override
  Future<void> createReply({
    required String commentId,
    required String text,
    String? imagePath,
  }) async {
    final resp = await socialRepository.createReply(commentId: commentId, text: text, imagePath: imagePath);
    if (resp.isSuccess && resp.response != null) {
      final data = resp.response!.data;
      final status = int.tryParse('${data?['api_status'] ?? 200}') ?? 200;
      if (status == 200) return;
      final msg = (data?['errors']?['error_text'] ?? 'Create reply failed').toString();
      throw Exception(msg);
    }
    ApiChecker.checkApi(resp);
    throw Exception('Create reply failed');
  }
}


