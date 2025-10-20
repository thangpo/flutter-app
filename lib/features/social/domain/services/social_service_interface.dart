import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_comment.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';

abstract class SocialServiceInterface {
  Future<List<SocialPost>> getNewsFeed({int limit, String? afterPostId});
  Future<List<SocialStory>> getStories({int limit, int offset});
  Future<void> reactToPost({
    required String postId,
    required String reaction,
    String action = 'reaction',
  });
  Future<void> reactToComment({
    required String commentId,
    required String reaction,
  });
  Future<void> reactToReply({
    required String replyId,
    required String reaction,
  });
  Future<SocialPost?> getPostById({required String postId});
  Future<List<SocialComment>> getPostComments(
      {required String postId, int? limit, int? offset});
  Future<List<SocialComment>> getCommentReplies({required String commentId});
  Future<void> createComment({
    required String postId,
    required String text,
    String? imagePath,
    String? audioPath,
    String? imageUrl,
  });
  Future<void> createReply({
    required String commentId,
    required String text,
    String? imagePath,
    String? audioPath,
    String? imageUrl,
  });
  Future<SocialPost> createPost({
    String? text,
    List<String>? imagePaths,
    String? videoPath,
    String? videoThumbnailPath,
    int privacy = 0,
    String? backgroundColorId,
  });
}
