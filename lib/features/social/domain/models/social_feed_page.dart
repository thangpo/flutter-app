import 'social_post.dart';

class SocialFeedPage {
  final List<SocialPost> posts;
  final String? lastId;

  const SocialFeedPage({
    required this.posts,
    required this.lastId,
  });
}
