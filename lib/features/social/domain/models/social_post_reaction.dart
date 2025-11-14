import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';

class SocialPostReaction {
  final String id;
  final SocialUser user;
  final String reaction;
  final String? rowId;
  final DateTime? reactedAt;
  final int? mutualFriendsCount;

  const SocialPostReaction({
    required this.id,
    required this.user,
    required this.reaction,
    this.rowId,
    this.reactedAt,
    this.mutualFriendsCount,
  });

  SocialPostReaction copyWith({
    String? id,
    SocialUser? user,
    String? reaction,
    String? rowId,
    DateTime? reactedAt,
    int? mutualFriendsCount,
  }) {
    return SocialPostReaction(
      id: id ?? this.id,
      user: user ?? this.user,
      reaction: reaction ?? this.reaction,
      rowId: rowId ?? this.rowId,
      reactedAt: reactedAt ?? this.reactedAt,
      mutualFriendsCount: mutualFriendsCount ?? this.mutualFriendsCount,
    );
  }
}

