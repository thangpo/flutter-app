import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_group.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_group_join_request.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_feed_page.dart';

enum SocialGroupQueryType {
  myGroups,
  joinedGroups,
  discover,
}

abstract class SocialGroupServiceInterface {
  Future<List<SocialGroup>> getGroups({
    required SocialGroupQueryType type,
    int limit,
    int offset,
  });

  Future<SocialGroup> createGroup({
    required String groupName,
    required String groupTitle,
    required String category,
    String? about,
    String? groupSubCategory,
    Map<String, dynamic>? customFields,
    String? privacy,
    String? joinPrivacy,
    String? avatarPath,
    String? coverPath,
  });

  Future<SocialGroup> updateGroup({
    required String groupId,
    String? groupTitle,
    String? about,
    String? category,
    String? groupSubCategory,
    Map<String, dynamic>? customFields,
    String? privacy,
    String? joinPrivacy,
    String? avatarPath,
    String? coverPath,
  });

  Future<SocialGroup?> joinGroup({required String groupId});

  Future<List<SocialUser>> getGroupMembers({
    required String groupId,
    int limit,
    int offset,
  });

  Future<List<SocialGroupJoinRequest>> getGroupJoinRequests({
    required String groupId,
    int limit,
    int offset,
  });

  Future<void> inviteGroupMember({
    required String groupId,
    required String userId,
  });

  Future<void> removeGroupMember({
    required String groupId,
    required String userId,
  });

  Future<void> reportGroup({
    required String groupId,
    required String text,
  });

  Future<void> deleteGroup({
    required String groupId,
    required String password,
  });

  Future<void> respondToJoinRequest({
    required String groupId,
    required String userId,
    String? requestId,
    required bool accept,
  });

  Future<List<SocialUser>> getGroupNonMembers({
    required String groupId,
    int limit,
    int offset,
  });

  Future<void> makeGroupAdmin({
    required String groupId,
    required String userId,
  });

  Future<SocialFeedPage> getGroupFeed({
    required String groupId,
    int limit,
    String? afterPostId,
  });

  Future<SocialGroup?> getGroupById({required String groupId});
}
