import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_comment.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_feed_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_group.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user_profile.dart';


abstract class SocialServiceInterface {
  Future<List<SocialPost>> getNewsFeed({int limit, String? afterPostId});
  Future<List<SocialStory>> getStories({int limit, int offset});
  Future<List<SocialStory>> getMyStories({int limit, int offset});
  Future<SocialStory?> createStory({
    required String fileType,
    required String filePath,
    String? coverPath,
    String? storyTitle,
    String? storyDescription,
    String? highlightHash,
  });
  Future<void> reactToPost({
    required String postId,
    required String reaction,
    String action = 'reaction',
  });
  Future<String> performPostAction({
    required String postId,
    required String action,
    Map<String, dynamic>? extraFields,
  });
  Future<String> hidePost({required String postId});
  Future<void> reactToStory({
    required String storyId,
    required String reaction,
  });
  Future<SocialStoryViewersPage> getStoryViews({
    required String storyId,
    int limit,
    int offset,
  });
  Future<SocialStory?> getStoryById({required String storyId});
  Future<void> reactToComment({
    required String commentId,
    required String reaction,
  });
  Future<void> reactToReply({
    required String replyId,
    required String reaction,
  });
  Future<SocialUser?> getCurrentUser();
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
    String? groupId,
  });
  Future<SocialPost> sharePost({required String postId, String? text});
  Future<SocialFeedPage> getGroupFeed({
    required String groupId,
    int limit,
    String? afterPostId,
  });
  Future<List<SocialPost>> getSavedPosts({
    int limit,
    String? afterPostId,
  });
  Future<List<SocialGroup>> searchGroups({String keyword = ''});
  Future<List<SocialGroup>> getMyGroups({
    required String type,
    int limit,
    int offset,
  });

  //30/10 follow profile user
  // tên, kiểu trả về và named param phải khớp y hệt với Service
  Future<bool> toggleFollow({required String targetUserId});
  Future<SocialUserProfile> updateDataUser({
    required String? displayName, // vẫn giữ kiểu required String?
    String? firstName,            // <-- mới
    String? lastName,             // <-- mới
    String? about,
    String? genderText,           // 'Nam' | 'Nữ' | 'Khác' -> map về male/female/other ở repo
    String? birthdayIso,          // yyyy-MM-dd
    String? address,
    String? website,
    String? relationshipText,
    String? currentPassword,      // <-- mới (đổi mật khẩu)
    String? newPassword,          // <-- mới (đổi mật khẩu)
    String? avatarFilePath,
    String? coverFilePath,
    String? ecomToken,
  });



}
