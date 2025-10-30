import 'package:dio/dio.dart';

import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_group.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_group_join_request.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_feed_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_repository.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';

import 'social_group_service_interface.dart';

class SocialGroupService implements SocialGroupServiceInterface {
  final SocialRepository socialRepository;
  SocialGroupService({required this.socialRepository});

  @override
  Future<List<SocialGroup>> getGroups({
    required SocialGroupQueryType type,
    int limit = 20,
    int offset = 0,
  }) async {
    ApiResponseModel<Response> resp;
    switch (type) {
      case SocialGroupQueryType.myGroups:
        resp = await socialRepository.fetchMyGroups(
          type: 'my_groups',
          limit: limit,
          offset: offset,
        );
        break;
      case SocialGroupQueryType.joinedGroups:
        resp = await socialRepository.fetchMyGroups(
          type: 'joined_groups',
          limit: limit,
          offset: offset,
        );
        break;
      case SocialGroupQueryType.discover:
        resp = await socialRepository.fetchCommunityGroups(
          limit: limit,
          offset: offset,
        );
        break;
    }

    if (resp.isSuccess && resp.response != null) {
      final dynamic data = resp.response!.data;
      final int status =
          int.tryParse('${data?['api_status'] ?? data?['status'] ?? 200}') ??
              200;
      if (status == 200) {
        return socialRepository.parseGroups(resp.response!);
      }
      final String message = (data?['errors']?['error_text'] ??
              data?['message'] ??
              'Failed to load groups')
          .toString();
      throw Exception(message);
    }
    ApiChecker.checkApi(resp);
    return <SocialGroup>[];
  }

  @override
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
  }) async {
    final resp = await socialRepository.createGroup(
      groupName: groupName,
      groupTitle: groupTitle,
      category: category,
      about: about,
      groupSubCategory: groupSubCategory,
      customFields: customFields,
      privacy: privacy,
      joinPrivacy: joinPrivacy,
      avatarPath: avatarPath,
      coverPath: coverPath,
    );

    if (resp.isSuccess && resp.response != null) {
      final dynamic data = resp.response!.data;
      final int status =
          int.tryParse('${data?['api_status'] ?? data?['status'] ?? 200}') ??
              200;
      if (status == 200) {
        final SocialGroup? group = socialRepository.parseGroup(resp.response!);
        if (group != null) return group;
        final List<SocialGroup> groups =
            socialRepository.parseGroups(resp.response!);
        if (groups.isNotEmpty) return groups.first;
        throw Exception('Create group failed: Missing group data.');
      }
      final String message = (data?['errors']?['error_text'] ??
              data?['message'] ??
              'Create group failed')
          .toString();
      throw Exception(message);
    }
    ApiChecker.checkApi(resp);
    throw Exception('Create group failed');
  }

  @override
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
  }) async {
    final resp = await socialRepository.updateGroup(
      groupId: groupId,
      groupTitle: groupTitle,
      about: about,
      category: category,
      groupSubCategory: groupSubCategory,
      customFields: customFields,
      privacy: privacy,
      joinPrivacy: joinPrivacy,
      avatarPath: avatarPath,
      coverPath: coverPath,
    );

    if (resp.isSuccess && resp.response != null) {
      final dynamic data = resp.response!.data;
      final int status =
          int.tryParse('${data?['api_status'] ?? data?['status'] ?? 200}') ??
              200;
      if (status == 200) {
        final SocialGroup? group = socialRepository.parseGroup(resp.response!);
        if (group != null) return group;
        final List<SocialGroup> groups =
            socialRepository.parseGroups(resp.response!);
        if (groups.isNotEmpty) return groups.first;
        return SocialGroup(
          id: groupId,
          name: groupTitle ?? groupId,
          title: groupTitle,
          about: about,
          category: category,
          subCategory: groupSubCategory,
          privacy: privacy,
          joinPrivacy: joinPrivacy,
          customFields: customFields ?? const <String, dynamic>{},
        );
      }
      final String message = (data?['errors']?['error_text'] ??
              data?['message'] ??
              'Update group failed')
          .toString();
      throw Exception(message);
    }
    ApiChecker.checkApi(resp);
    throw Exception('Update group failed');
  }

  @override
  Future<SocialGroup?> joinGroup({required String groupId}) async {
    final resp = await socialRepository.joinGroup(groupId: groupId);
    if (resp.isSuccess && resp.response != null) {
      final dynamic data = resp.response!.data;
      final int status =
          int.tryParse('${data?['api_status'] ?? data?['status'] ?? 200}') ??
              200;
      if (status == 200) {
        final SocialGroup? group = socialRepository.parseGroup(resp.response!);
        if (group != null) return group;
        final List<SocialGroup> groups =
            socialRepository.parseGroups(resp.response!);
        if (groups.isNotEmpty) return groups.first;
        return null;
      }
      final String message = (data?['errors']?['error_text'] ??
              data?['message'] ??
              'Join group failed')
          .toString();
      throw Exception(message);
    }
    ApiChecker.checkApi(resp);
    throw Exception('Join group failed');
  }

  @override
  Future<List<SocialUser>> getGroupMembers({
    required String groupId,
    int limit = 20,
    int offset = 0,
  }) async {
    final resp = await socialRepository.fetchGroupMembers(
      groupId: groupId,
      limit: limit,
      offset: offset,
    );
    if (resp.isSuccess && resp.response != null) {
      final dynamic data = resp.response!.data;
      final int status =
          int.tryParse('${data?['api_status'] ?? data?['status'] ?? 200}') ??
              200;
      if (status == 200) {
        return socialRepository.parseGroupMembers(resp.response!);
      }
      final String message = (data?['errors']?['error_text'] ??
              data?['message'] ??
              'Failed to load group members')
          .toString();
      throw Exception(message);
    }
    ApiChecker.checkApi(resp);
    return <SocialUser>[];
  }

  @override
  Future<List<SocialGroupJoinRequest>> getGroupJoinRequests({
    required String groupId,
    int limit = 20,
    int offset = 0,
  }) async {
    final resp = await socialRepository.fetchGroupJoinRequests(
      groupId: groupId,
      limit: limit,
      offset: offset,
    );
    if (resp.isSuccess && resp.response != null) {
      final dynamic data = resp.response!.data;
      final int status =
          int.tryParse('${data?['api_status'] ?? data?['status'] ?? 200}') ??
              200;
      if (status == 200) {
        return socialRepository.parseGroupJoinRequests(resp.response!);
      }
      final String message = (data?['errors']?['error_text'] ??
              data?['message'] ??
              'Failed to load join requests')
          .toString();
      throw Exception(message);
    }
    ApiChecker.checkApi(resp);
    return <SocialGroupJoinRequest>[];
  }

  @override
  Future<void> inviteGroupMember({
    required String groupId,
    required String userId,
  }) async {
    final resp = await socialRepository.inviteGroupMember(
      groupId: groupId,
      userId: userId,
    );
    if (resp.isSuccess && resp.response != null) {
      final dynamic data = resp.response!.data;
      final int status =
          int.tryParse('${data?['api_status'] ?? data?['status'] ?? 200}') ??
              200;
      if (status == 200) {
        return;
      }
      final String message = (data?['errors']?['error_text'] ??
              data?['message'] ??
              'Failed to send invite')
          .toString();
      throw Exception(message);
    }
    ApiChecker.checkApi(resp);
    throw Exception('Failed to send invite');
  }

  @override
  Future<void> removeGroupMember({
    required String groupId,
    required String userId,
  }) async {
    final resp = await socialRepository.deleteGroupMember(
      groupId: groupId,
      userId: userId,
    );
    if (resp.isSuccess && resp.response != null) {
      final dynamic data = resp.response!.data;
      final int status =
          int.tryParse('${data?['api_status'] ?? data?['status'] ?? 200}') ??
              200;
      if (status == 200) {
        return;
      }
      final String message = (data?['errors']?['error_text'] ??
              data?['message'] ??
              'Failed to remove member')
          .toString();
      throw Exception(message);
    }
    ApiChecker.checkApi(resp);
    throw Exception('Failed to remove member');
  }

  @override
  Future<void> reportGroup({
    required String groupId,
    required String text,
  }) async {
    final resp = await socialRepository.reportGroup(
      groupId: groupId,
      text: text,
    );
    if (resp.isSuccess && resp.response != null) {
      final dynamic data = resp.response!.data;
      final int status =
          int.tryParse('${data?['api_status'] ?? data?['status'] ?? 200}') ??
              200;
      if (status == 200) {
        return;
      }
      final String message = (data?['errors']?['error_text'] ??
              data?['message'] ??
              'Failed to report group')
          .toString();
      throw Exception(message);
    }
    ApiChecker.checkApi(resp);
    throw Exception('Failed to report group');
  }

  @override
  Future<void> deleteGroup({
    required String groupId,
    required String password,
  }) async {
    final resp = await socialRepository.deleteGroup(
      groupId: groupId,
      password: password,
    );
    if (resp.isSuccess && resp.response != null) {
      final dynamic data = resp.response!.data;
      final int status =
          int.tryParse('${data?['api_status'] ?? data?['status'] ?? 200}') ??
              200;
      if (status == 200) {
        return;
      }
      final String message = (data?['errors']?['error_text'] ??
              data?['message'] ??
              'Failed to delete group')
          .toString();
      throw Exception(message);
    }
    ApiChecker.checkApi(resp);
    throw Exception('Failed to delete group');
  }

  @override
  Future<void> respondToJoinRequest({
    required String groupId,
    required String userId,
    String? requestId,
    required bool accept,
  }) async {
    final resp = await socialRepository.respondGroupJoinRequest(
      groupId: groupId,
      userId: userId,
      requestId: requestId,
      accept: accept,
    );
    if (resp.isSuccess && resp.response != null) {
      final dynamic data = resp.response!.data;
      final int status =
          int.tryParse('${data?['api_status'] ?? data?['status'] ?? 200}') ??
              200;
      if (status == 200) {
        return;
      }
      final String message = (data?['errors']?['error_text'] ??
              data?['message'] ??
              'Failed to update join request')
          .toString();
      throw Exception(message);
    }
    ApiChecker.checkApi(resp);
    throw Exception('Failed to update join request');
  }

  @override
  Future<List<SocialUser>> getGroupNonMembers({
    required String groupId,
    int limit = 20,
    int offset = 0,
  }) async {
    final resp = await socialRepository.fetchNotInGroupMembers(
      groupId: groupId,
      limit: limit,
      offset: offset,
    );
    if (resp.isSuccess && resp.response != null) {
      final dynamic data = resp.response!.data;
      final int status =
          int.tryParse('${data?['api_status'] ?? data?['status'] ?? 200}') ??
              200;
      if (status == 200) {
        return socialRepository.parseGroupMembers(resp.response!);
      }
      final String message = (data?['errors']?['error_text'] ??
              data?['message'] ??
              'Failed to load group suggestions')
          .toString();
      throw Exception(message);
    }
    ApiChecker.checkApi(resp);
    return <SocialUser>[];
  }

  @override
  Future<void> makeGroupAdmin({
    required String groupId,
    required String userId,
  }) async {
    final resp = await socialRepository.makeGroupAdmin(
      groupId: groupId,
      userId: userId,
    );
    if (resp.isSuccess && resp.response != null) {
      final dynamic data = resp.response!.data;
      final int status =
          int.tryParse('${data?['api_status'] ?? data?['status'] ?? 200}') ??
              200;
      if (status == 200) {
        return;
      }
      final String message = (data?['errors']?['error_text'] ??
              data?['message'] ??
              'Failed to update member role')
          .toString();
      throw Exception(message);
    }
    ApiChecker.checkApi(resp);
    throw Exception('Failed to update member role');
  }

  @override
  Future<SocialFeedPage> getGroupFeed({
    required String groupId,
    int limit = 10,
    String? afterPostId,
  }) async {
    final resp = await socialRepository.fetchGroupFeed(
      groupId: groupId,
      limit: limit,
      afterPostId: afterPostId,
    );
    if (resp.isSuccess && resp.response != null) {
      final dynamic data = resp.response!.data;
      final int status =
          int.tryParse('${data?['api_status'] ?? data?['status'] ?? 200}') ??
              200;
      if (status == 200) {
        return socialRepository.parseNewsFeed(resp.response!);
      }
      final String message = (data?['errors']?['error_text'] ??
              data?['message'] ??
              'Failed to load group feed')
          .toString();
      throw Exception(message);
    }
    ApiChecker.checkApi(resp);
    return SocialFeedPage(posts: <SocialPost>[], lastId: null);
  }

  @override
  Future<SocialGroup?> getGroupById({required String groupId}) async {
    final resp = await socialRepository.fetchGroupData(groupId: groupId);
    if (resp.isSuccess && resp.response != null) {
      final dynamic data = resp.response!.data;
      final int status =
          int.tryParse('${data?['api_status'] ?? data?['status'] ?? 200}') ??
              200;
      if (status == 200) {
        final SocialGroup? group = socialRepository.parseGroup(resp.response!);
        if (group != null) return group;
        final List<SocialGroup> groups =
            socialRepository.parseGroups(resp.response!);
        if (groups.isNotEmpty) return groups.first;
        return null;
      }
      final String message = (data?['errors']?['error_text'] ??
              data?['message'] ??
              'Failed to load group information')
          .toString();
      throw Exception(message);
    }
    ApiChecker.checkApi(resp);
    return null;
  }
}
