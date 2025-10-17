import 'package:dio/dio.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';

import 'social_service_interface.dart';

class SocialService implements SocialServiceInterface {
  final SocialRepository socialRepository;
  SocialService({required this.socialRepository});

  //Feeds
  @override
  Future<List<SocialPost>> getNewsFeed(
      {int limit = 10, String? afterPostId}) async {
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
  Future<void> reactToPost({required String postId, required String reaction}) async {
    final resp = await socialRepository.reactToPost(postId: postId, reaction: reaction);
    if (!(resp.isSuccess && resp.response?.statusCode == 200)) {
      ApiChecker.checkApi(resp);
    }
  }

  //Stories
  @override
  Future<List<SocialStory>> getStories({int limit = 10, int offset = 0}) async {
    final resp =
        await socialRepository.fetchStories(limit: limit, offset: offset);
    if (resp.isSuccess &&
        resp.response != null &&
        resp.response!.statusCode == 200) {
      return socialRepository.parseStories(resp.response!);
    }
    ApiChecker.checkApi(resp);
    return [];
  }
}
