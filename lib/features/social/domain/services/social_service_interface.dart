import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';

abstract class SocialServiceInterface {
  Future<List<SocialPost>> getNewsFeed({int limit, String? afterPostId});
  Future<List<SocialStory>> getStories({int limit, int offset});
}
