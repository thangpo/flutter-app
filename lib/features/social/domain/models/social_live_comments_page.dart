import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_comment.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';

class SocialLiveCommentsPage {
  final List<SocialComment> comments;
  final String? nextOffset;
  final String? resourceId;
  final String? sid;
  final List<String> fileList;
  final int? viewerCount;
  final bool? isLive;
  final String? statusWord;
  final List<SocialUser> joinedUsers;
  final List<SocialUser> leftUsers;

  const SocialLiveCommentsPage({
    required this.comments,
    this.nextOffset,
    this.resourceId,
    this.sid,
    this.fileList = const <String>[],
    this.viewerCount,
    this.isLive,
    this.statusWord,
    this.joinedUsers = const <SocialUser>[],
    this.leftUsers = const <SocialUser>[],
  });

  SocialLiveCommentsPage copyWith({
    List<SocialComment>? comments,
    String? nextOffset,
    String? resourceId,
    String? sid,
    List<String>? fileList,
    int? viewerCount,
    bool? isLive,
    String? statusWord,
    List<SocialUser>? joinedUsers,
    List<SocialUser>? leftUsers,
  }) {
    return SocialLiveCommentsPage(
      comments: comments ?? this.comments,
      nextOffset: nextOffset ?? this.nextOffset,
      resourceId: resourceId ?? this.resourceId,
      sid: sid ?? this.sid,
      fileList: fileList ?? this.fileList,
      viewerCount: viewerCount ?? this.viewerCount,
      isLive: isLive ?? this.isLive,
      statusWord: statusWord ?? this.statusWord,
      joinedUsers: joinedUsers ?? this.joinedUsers,
      leftUsers: leftUsers ?? this.leftUsers,
    );
  }
}
