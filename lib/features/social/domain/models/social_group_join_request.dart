import 'social_user.dart';

class SocialGroupJoinRequest {
  final String key;
  final String? requestId;
  final SocialUser user;

  const SocialGroupJoinRequest({
    required this.key,
    required this.user,
    this.requestId,
  });

  String get userId => user.id;
}
