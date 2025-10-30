import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_comment.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_feed_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_group.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user_profile.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:dio/dio.dart';

import 'social_service_interface.dart';

/// Gói thông tin tổng hợp của 1 user khi load profile
class SocialProfileBundle {
  final SocialUserProfile? user;
  final List<SocialUser> followers;
  final List<SocialUser> following;
  final List<dynamic> likedPages;

  const SocialProfileBundle({
    required this.user,
    required this.followers,
    required this.following,
    required this.likedPages,
  });
}

class SocialService implements SocialServiceInterface {
  final SocialRepository socialRepository;
  SocialService({required this.socialRepository});

  // ========== PRIVATE HELPERS ==========
  String? _absoluteUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return trimmed;
    }

    final base = AppConstants.socialBaseUrl.endsWith('/')
        ? AppConstants.socialBaseUrl.substring(
            0,
            AppConstants.socialBaseUrl.length - 1,
          )
        : AppConstants.socialBaseUrl;

    if (trimmed.startsWith('/')) {
      return '$base$trimmed';
    }
    return '$base/$trimmed';
  }

  Map<String, dynamic> _normalizeUserMap(Map<String, dynamic> raw) {
    final user = Map<String, dynamic>.from(raw);

    if (user['avatar'] != null) {
      user['avatar'] = _absoluteUrl(user['avatar']?.toString());
    }
    if (user['profile_picture'] != null) {
      user['profile_picture'] =
          _absoluteUrl(user['profile_picture']?.toString());
    }
    if (user['cover'] != null) {
      user['cover'] = _absoluteUrl(user['cover']?.toString());
    }
    if (user['cover_picture'] != null) {
      user['cover_picture'] = _absoluteUrl(user['cover_picture']?.toString());
    }

    return user;
  }

  SocialUser _mapToSocialUser(Map<String, dynamic> raw) {
    final data = Map<String, dynamic>.from(raw);

    final firstName = data['first_name']?.toString();
    final lastName = data['last_name']?.toString();

    final displayName = (() {
      if (data['name'] != null && data['name'].toString().isNotEmpty) {
        return data['name'].toString();
      }
      final combined = [
        firstName ?? '',
        lastName ?? '',
      ].join(' ').trim();
      if (combined.isNotEmpty) return combined;
      if (data['username'] != null) {
        return data['username'].toString();
      }
      return null;
    })();

    return SocialUser(
      id: data['user_id']?.toString() ?? data['id']?.toString() ?? '',
      displayName: displayName,
      firstName: firstName,
      lastName: lastName,
      userName: data['username']?.toString(),
      avatarUrl: (data['avatar'] ?? data['profile_picture'])?.toString(),
      coverUrl: (data['cover'] ?? data['cover_picture'])?.toString(),
    );
  }

  // ========== FEEDS ==========
  @override
  Future<List<SocialPost>> getNewsFeed({
    int limit = 10,
    String? afterPostId,
  }) async {
    final resp = await socialRepository.fetchNewsFeed(
      limit: limit,
      afterPostId: afterPostId,
    );
    if (resp.isSuccess &&
        resp.response != null &&
        resp.response!.statusCode == 200) {
      final page = socialRepository.parseNewsFeed(resp.response!);
      return page.posts;
    }
    ApiChecker.checkApi(resp);
    return [];
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
    if (resp.isSuccess &&
        resp.response != null &&
        resp.response!.statusCode == 200) {
      return socialRepository.parseNewsFeed(resp.response!);
    }
    ApiChecker.checkApi(resp);
    return const SocialFeedPage(posts: <SocialPost>[], lastId: null);
  }

  @override
  Future<List<SocialGroup>> searchGroups({String keyword = ''}) async {
    final resp = await socialRepository.searchSocial(searchKey: keyword);
    if (resp.isSuccess && resp.response != null) {
      final dynamic data = resp.response!.data;
      final int status = int.tryParse(
            '${data is Map ? (data['api_status'] ?? 200) : 200}',
          ) ??
          200;
      if (status == 200) {
        final groups = socialRepository.parseGroups(resp.response!);
        return groups.where((group) => !group.isJoined).toList();
      }
      if (data is Map) {
        final dynamic errors = data['errors'];
        final dynamic errorText = errors is Map ? errors['error_text'] : null;
        final dynamic message = errorText ?? data['message'];
        throw Exception((message ?? 'Search groups failed').toString());
      }
      throw Exception('Search groups failed');
    }
    ApiChecker.checkApi(resp);
    return [];
  }

  @override
  Future<List<SocialGroup>> getMyGroups({
    required String type,
    int limit = 20,
    int offset = 0,
  }) async {
    final resp = await socialRepository.fetchMyGroups(
      type: type,
      limit: limit,
      offset: offset,
    );
    if (resp.isSuccess && resp.response != null) {
      final dynamic data = resp.response!.data;
      final int status =
          int.tryParse('${data is Map ? (data['api_status'] ?? 200) : 200}') ??
              200;
      if (status == 200) {
        return socialRepository.parseGroups(resp.response!);
      }
      if (data is Map) {
        final dynamic errors = data['errors'];
        final dynamic errorText = errors is Map ? errors['error_text'] : null;
        final dynamic message = errorText ?? data['message'];
        throw Exception((message ?? 'Fetch groups failed').toString());
      }
      throw Exception('Fetch groups failed');
    }
    ApiChecker.checkApi(resp);
    return [];
  }

  // Stories
  @override
  Future<List<SocialStory>> getStories({
    int limit = 10,
    int offset = 0,
  }) async {
    final resp = await socialRepository.fetchStories(
      limit: limit,
      offset: offset,
    );
    if (resp.isSuccess &&
        resp.response != null &&
        resp.response!.statusCode == 200) {
      return socialRepository.parseStories(resp.response!);
    }
    ApiChecker.checkApi(resp);
    return [];
  }

  @override
  Future<List<SocialStory>> getMyStories({
    int limit = 10,
    int offset = 0,
  }) async {
    final resp = await socialRepository.fetchUserStories(
      limit: limit,
      offset: offset,
    );
    if (resp.isSuccess &&
        resp.response != null &&
        resp.response!.statusCode == 200) {
      return socialRepository.parseStories(resp.response!);
    }
    ApiChecker.checkApi(resp);
    return [];
  }

  @override
  Future<SocialStory?> createStory({
    required String fileType,
    required String filePath,
    String? coverPath,
    String? storyTitle,
    String? storyDescription,
    String? highlightHash,
  }) async {
    final resp = await socialRepository.createStory(
      filePath: filePath,
      fileType: fileType,
      coverPath: coverPath,
      storyTitle: storyTitle,
      storyDescription: storyDescription,
      highlightHash: highlightHash,
    );

    if (resp.isSuccess && resp.response != null) {
      final data = resp.response!.data;
      final status = int.tryParse('${data?['api_status'] ?? 200}') ?? 200;

      if (status == 200) {
        final dynamic storyIdRaw = data?['story_id'] ?? data?['id'];
        if (storyIdRaw != null && '$storyIdRaw'.isNotEmpty) {
          final detailResp = await socialRepository.fetchStoryById(
            id: '$storyIdRaw',
          );
          if (detailResp.isSuccess && detailResp.response != null) {
            final detailData = detailResp.response!.data;
            final detailStatus =
                int.tryParse('${detailData?['api_status'] ?? 200}') ?? 200;
            if (detailStatus == 200) {
              final SocialStory? story =
                  socialRepository.parseStoryDetail(detailResp.response!);
              if (story != null) {
                return story;
              }
            }
          }
        }
        final SocialStory? inline =
            socialRepository.parseStoryDetail(resp.response!);
        return inline;
      }

      final msg = (data?['errors']?['error_text'] ??
              data?['message'] ??
              'Create story failed')
          .toString();
      throw Exception(msg);
    }

    ApiChecker.checkApi(resp);
    throw Exception('Create story failed');
  }

  @override
  Future<SocialStoryViewersPage> getStoryViews({
    required String storyId,
    int limit = 20,
    int offset = 0,
  }) async {
    final resp = await socialRepository.fetchStoryViews(
      storyId: storyId,
      limit: limit,
      offset: offset,
    );

    if (resp.isSuccess && resp.response != null) {
      final data = resp.response!.data;
      final status = int.tryParse('${data?['api_status'] ?? 200}') ?? 200;
      if (status == 200) {
        final SocialStoryViewersPage viewsPage =
            socialRepository.parseStoryViews(
          resp.response!,
          currentOffset: offset,
          limit: limit,
        );

        SocialStoryViewersPage reactionsPage = const SocialStoryViewersPage();
        try {
          final int reactionLimit = offset + limit;
          final respReactions = await socialRepository.fetchStoryReactions(
            storyId: storyId,
            reactionFilter: '1,2,3,4,5,6',
            limit: reactionLimit > 0 ? reactionLimit : limit,
            offset: 0,
          );
          if (respReactions.isSuccess && respReactions.response != null) {
            final dynamic reactionsData = respReactions.response!.data;
            final int reactionsStatus =
                int.tryParse('${reactionsData?['api_status'] ?? 200}') ?? 200;
            if (reactionsStatus == 200) {
              reactionsPage = socialRepository.parseStoryViews(
                respReactions.response!,
                currentOffset: 0,
                limit: reactionLimit > 0 ? reactionLimit : limit,
              );
            }
          }
        } catch (_) {}

        if (reactionsPage.viewers.isEmpty) {
          return viewsPage;
        }

        String viewerKeyFor(SocialStoryViewer viewer) {
          if (viewer.userId.isNotEmpty) return viewer.userId;
          if (viewer.id.isNotEmpty) return viewer.id;
          return '${viewer.hashCode}';
        }

        List<String> extractedReactions(SocialStoryViewer viewer) {
          if (viewer.reactions.isNotEmpty) return viewer.reactions;
          if (viewer.reaction.isNotEmpty) {
            return <String>[normalizeSocialReaction(viewer.reaction)];
          }
          return const <String>[];
        }

        final Map<String, SocialStoryViewer> reactionLookup =
            <String, SocialStoryViewer>{
          for (final SocialStoryViewer viewer in reactionsPage.viewers)
            viewerKeyFor(viewer): viewer,
        };

        final List<SocialStoryViewer> mergedViewers = <SocialStoryViewer>[];

        for (final SocialStoryViewer viewer in viewsPage.viewers) {
          final String key = viewerKeyFor(viewer);
          final SocialStoryViewer? reaction = reactionLookup.remove(key);
          if (reaction != null) {
            final List<String> reactionsList = extractedReactions(reaction);
            mergedViewers.add(
              viewer.copyWith(
                name: (viewer.name?.isNotEmpty ?? false)
                    ? viewer.name
                    : reaction.name,
                avatar: (viewer.avatar?.isNotEmpty ?? false)
                    ? viewer.avatar
                    : reaction.avatar,
                isVerified: viewer.isVerified || reaction.isVerified,
                viewedAt: viewer.viewedAt ?? reaction.viewedAt,
                reactions: reactionsList,
                reactionCount: reaction.reactionCount ??
                    (reactionsList.isNotEmpty ? reactionsList.length : null),
                reaction: reactionsList.isNotEmpty
                    ? reactionsList.last
                    : reaction.reaction,
              ),
            );
          } else {
            mergedViewers.add(viewer);
          }
        }

        if (offset == 0 && reactionLookup.isNotEmpty) {
          mergedViewers.addAll(
            reactionLookup.values.map((reaction) {
              final List<String> reactionsList = extractedReactions(reaction);
              return reaction.copyWith(
                reactions: reactionsList,
                reaction: reactionsList.isNotEmpty
                    ? reactionsList.last
                    : reaction.reaction,
                reactionCount: reaction.reactionCount ??
                    (reactionsList.isNotEmpty ? reactionsList.length : null),
              );
            }),
          );
        }

        mergedViewers.sort((a, b) {
          final DateTime aTime =
              a.viewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final DateTime bTime =
              b.viewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });

        final int mergedTotal = mergedViewers.length > viewsPage.total
            ? mergedViewers.length
            : viewsPage.total;

        return viewsPage.copyWith(
          viewers: mergedViewers,
          total: mergedTotal,
        );
      }
      final msg =
          (data?['errors']?['error_text'] ?? 'Load story viewers failed')
              .toString();
      throw Exception(msg);
    }

    ApiChecker.checkApi(resp);
    throw Exception('Load story viewers failed');
  }

  // ========== REACTIONS ==========
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
        final msg =
            (data?['errors']?['error_text'] ?? 'Reaction failed').toString();
        throw Exception(msg);
      }
      return;
    }

    ApiChecker.checkApi(resp);
    throw Exception('Reaction failed');
  }

  @override
  Future<void> reactToStory({
    required String storyId,
    required String reaction,
  }) async {
    final resp = await socialRepository.reactToStory(
      storyId: storyId,
      reaction: reaction,
    );

    if (resp.isSuccess && resp.response != null) {
      final data = resp.response!.data;
      final status = int.tryParse('${data?['api_status'] ?? 200}') ?? 200;
      if (status == 200) return;
      final msg =
          (data?['errors']?['error_text'] ?? 'Reaction failed').toString();
      throw Exception(msg);
    }

    ApiChecker.checkApi(resp);
    throw Exception('Reaction failed');
  }

  @override
  Future<void> reactToComment({
    required String commentId,
    required String reaction,
  }) async {
    final resp = await socialRepository.reactToComment(
      commentId: commentId,
      reaction: reaction,
    );

    if (resp.isSuccess && resp.response != null) {
      final data = resp.response!.data;
      final status = int.tryParse('${data?['api_status'] ?? 200}') ?? 200;
      if (status == 200) return;
      final msg =
          (data?['errors']?['error_text'] ?? 'Reaction failed').toString();
      throw Exception(msg);
    }

    ApiChecker.checkApi(resp);
    throw Exception('Reaction failed');
  }

  @override
  Future<void> reactToReply({
    required String replyId,
    required String reaction,
  }) async {
    final resp = await socialRepository.reactToReply(
      replyId: replyId,
      reaction: reaction,
    );

    if (resp.isSuccess && resp.response != null) {
      final data = resp.response!.data;
      final status = int.tryParse('${data?['api_status'] ?? 200}') ?? 200;
      if (status == 200) return;
      final msg =
          (data?['errors']?['error_text'] ?? 'Reaction failed').toString();
      throw Exception(msg);
    }

    ApiChecker.checkApi(resp);
    throw Exception('Reaction failed');
  }

  // ========== USER PROFILE ==========
  @override
  Future<SocialUser?> getCurrentUser() async {
    final resp = await socialRepository.fetchCurrentUserProfile();
    if (resp.isSuccess && resp.response != null) {
      final data = resp.response!.data;
      final status = int.tryParse('${data?['api_status'] ?? 200}') ?? 200;
      if (status == 200) {
        return socialRepository.parseCurrentUser(resp.response!);
      }
      final msg =
          (data?['errors']?['error_text'] ?? 'Load profile failed').toString();
      throw Exception(msg);
    }
    ApiChecker.checkApi(resp);
    return null;
  }

  /// Lấy thông tin profile đầy đủ của user (followers, following, liked_pages)
  Future<SocialProfileBundle> getUserProfile({String? targetUserId}) async {
    final apiRes = await socialRepository.fetchUserProfile(
      targetUserId: targetUserId,
    );

    // fallback rỗng nếu lỗi API
    if (apiRes.isSuccess != true ||
        apiRes.response == null ||
        apiRes.response is! Response ||
        apiRes.response!.statusCode != 200) {
      return const SocialProfileBundle(
        user: null,
        followers: [],
        following: [],
        likedPages: [],
      );
    }

    final Response res = apiRes.response!;
    final body = res.data;

    // 1. user chính (header profile)
    // parseUserProfile(res) trả về SocialUserProfile?
    final SocialUserProfile? profileHeader =
        socialRepository.parseUserProfile(res);

    // 2. followers / following (danh sách rút gọn)
    final List<SocialUser> followersList = [];
    final List<SocialUser> followingList = [];
    List<dynamic> likedPagesRaw = const [];

    if (body is Map<String, dynamic>) {
      // followers
      if (body['followers'] is List) {
        for (final f in (body['followers'] as List)) {
          if (f is! Map<String, dynamic>) continue;
          final normalizedFollower = _normalizeUserMap(
            Map<String, dynamic>.from(f),
          );
          followersList.add(_mapToSocialUser(normalizedFollower));
        }
      }

      // following
      if (body['following'] is List) {
        for (final f in (body['following'] as List)) {
          if (f is! Map<String, dynamic>) continue;
          final normalizedFollowing = _normalizeUserMap(
            Map<String, dynamic>.from(f),
          );
          followingList.add(_mapToSocialUser(normalizedFollowing));
        }
      }

      // liked_pages
      if (body['liked_pages'] is List) {
        likedPagesRaw = body['liked_pages'] as List;
      }
    }

    // 3. trả bundle
    return SocialProfileBundle(
      user: profileHeader, // <- giờ đúng kiểu SocialUserProfile?
      followers: followersList, // List<SocialUser>
      following: followingList, // List<SocialUser>
      likedPages: likedPagesRaw,
    );
  }

  /// Lấy danh sách post của user, có phân trang
  Future<SocialFeedPage> getUserPosts({
    required String targetUserId,
    int limit = 10,
    String? afterPostId,
  }) async {
    final apiRes = await socialRepository.fetchUserPosts(
      targetUserId: targetUserId,
      limit: limit,
      afterPostId: afterPostId,
    );

    if (apiRes.isSuccess != true ||
        apiRes.response == null ||
        apiRes.response is! Response ||
        apiRes.response!.statusCode != 200) {
      return const SocialFeedPage(posts: [], lastId: null);
    }

    final Response res = apiRes.response!;
    final body = res.data;

    final postsResult = <SocialPost>[];
    String? lastId;

    if (body is Map<String, dynamic>) {
      final rawPosts = body['posts_data'] ?? body['data'] ?? body['posts'];

      if (rawPosts is List) {
        for (final raw in rawPosts) {
          if (raw is! Map<String, dynamic>) continue;
          final post = socialRepository.mapToSocialPost(
            Map<String, dynamic>.from(raw),
          );
          if (post != null) {
            postsResult.add(post);
            lastId = post.id;
          }
        }
      }
    }

    return SocialFeedPage(
      posts: postsResult,
      lastId: lastId,
    );
  }

  // ========== POSTS ==========
  @override
  Future<SocialPost?> getPostById({required String postId}) async {
    final resp = await socialRepository.fetchPostData(postId: postId);
    if (resp.isSuccess && resp.response != null) {
      final data = resp.response!.data;
      final status = int.tryParse('${data?['api_status'] ?? 200}') ?? 200;
      if (status == 200) {
        return socialRepository.parsePostData(resp.response!);
      }
      final msg =
          (data?['errors']?['error_text'] ?? 'Load post failed').toString();
      throw Exception(msg);
    }
    ApiChecker.checkApi(resp);
    return null;
  }

  @override
  Future<SocialPost> createPost({
    String? text,
    List<String>? imagePaths,
    String? videoPath,
    String? videoThumbnailPath,
    int privacy = 0,
    String? backgroundColorId,
    String? groupId,
  }) async {
    final resp = await socialRepository.createPost(
      text: text,
      imagePaths: imagePaths,
      videoPath: videoPath,
      videoThumbnailPath: videoThumbnailPath,
      privacy: privacy,
      backgroundColorId: backgroundColorId,
    );
    if (resp.isSuccess && resp.response != null) {
      final data = resp.response!.data;
      final status = int.tryParse('${data?['api_status'] ?? 200}') ?? 200;
      if (status == 200) {
        final SocialPost? post = socialRepository.parsePostData(resp.response!);
        if (post != null) return post;
        throw Exception('Create post failed: Missing post data.');
      }
      final msg = (data?['errors']?['error_text'] ??
              data?['message'] ??
              'Create post failed')
          .toString();
      throw Exception(msg);
    }
    ApiChecker.checkApi(resp);
    throw Exception('Create post failed');
  }

  @override
  Future<SocialPost> sharePost({required String postId, String? text}) async {
    final resp = await socialRepository.sharePostOnTimeline(
      postId: postId,
      text: text,
    );
    if (resp.isSuccess && resp.response != null) {
      final data = resp.response!.data;
      final status = int.tryParse('${data?['api_status'] ?? 200}') ?? 200;
      if (status == 200) {
        final SocialPost? post = socialRepository.parsePostData(resp.response!);
        if (post != null) return post;
        throw Exception('Share failed: Missing post data.');
      }
      final msg =
          (data?['errors']?['error_text'] ?? 'Share post failed').toString();
      throw Exception(msg);
    }
    ApiChecker.checkApi(resp);
    throw Exception('Share post failed');
  }

  // ========== COMMENTS ==========
  @override
  Future<List<SocialComment>> getPostComments({
    required String postId,
    int? limit,
    int? offset,
  }) async {
    final resp = await socialRepository.fetchComments(
      postId: postId,
      limit: limit,
      offset: offset,
    );
    if (resp.isSuccess && resp.response != null) {
      final data = resp.response!.data;
      final status = int.tryParse('${data?['api_status'] ?? 200}') ?? 200;
      if (status == 200) {
        return socialRepository.parsePostComments(resp.response!);
      }
      final msg =
          (data?['errors']?['error_text'] ?? 'Load comments failed').toString();
      throw Exception(msg);
    }
    ApiChecker.checkApi(resp);
    return [];
  }

  @override
  Future<List<SocialComment>> getCommentReplies({
    required String commentId,
  }) async {
    final resp = await socialRepository.fetchCommentReplies(
      commentId: commentId,
    );
    if (resp.isSuccess && resp.response != null) {
      final data = resp.response!.data;
      final status = int.tryParse('${data?['api_status'] ?? 200}') ?? 200;
      if (status == 200) {
        return socialRepository.parseCommentReplies(resp.response!);
      }
      final msg =
          (data?['errors']?['error_text'] ?? 'Load replies failed').toString();
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
      final msg = (data?['errors']?['error_text'] ?? 'Create comment failed')
          .toString();
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
    String? audioPath,
    String? imageUrl,
  }) async {
    final resp = await socialRepository.createReply(
      commentId: commentId,
      text: text,
      imagePath: imagePath,
      audioPath: audioPath,
      imageUrl: imageUrl,
    );
    if (resp.isSuccess && resp.response != null) {
      final data = resp.response!.data;
      final status = int.tryParse('${data?['api_status'] ?? 200}') ?? 200;
      if (status == 200) return;
      final msg =
          (data?['errors']?['error_text'] ?? 'Create reply failed').toString();
      throw Exception(msg);
    }
    ApiChecker.checkApi(resp);
    throw Exception('Create reply failed');
  }
}
