import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_comment.dart';

class SocialLiveCommentsPage {
  final List<SocialComment> comments;
  final String? nextOffset;
  final String? resourceId;
  final String? sid;
  final List<String> fileList;
  final int? viewerCount;
  final bool? isLive;
  final String? statusWord;

  const SocialLiveCommentsPage({
    required this.comments,
    this.nextOffset,
    this.resourceId,
    this.sid,
    this.fileList = const <String>[],
    this.viewerCount,
    this.isLive,
    this.statusWord,
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
    );
  }
}
