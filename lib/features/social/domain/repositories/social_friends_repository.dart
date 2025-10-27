import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_friends_service.dart';

class SocialFriendsRepository {
  Future<List<Map<String, dynamic>>> fetchFriends({
    required String token,
    String? userId,
  }) {
    return SocialFriendsService.getFollowersAndFollowing(
      accessToken: token,
      userId: userId,
    );
  }
}
