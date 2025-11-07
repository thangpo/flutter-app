import 'dart:convert';
import 'package:flutter/foundation.dart';

class SocialNotification {
  final String id;
  final String notifierId;
  final String recipientId;
  final String postId;
  final String replyId;
  final String commentId;
  final String pageId;
  final String groupId;
  final String groupChatId;
  final String eventId;
  final String threadId;
  final String blogId;
  final String? storyId;

  final String type;
  final String type2;
  final String text;
  final String url;
  final String fullLink;
  String seen;
  final String time;
  final String timeText;

  // thông tin notifier (gộp sẵn để tiện dùng)
  final String name;
  final String avatar;

   SocialNotification({
    required this.id,
    required this.notifierId,
    required this.recipientId,
    required this.postId,
    required this.replyId,
    required this.commentId,
    required this.pageId,
    required this.groupId,
    required this.groupChatId,
    required this.eventId,
    required this.threadId,
    required this.blogId,
    required this.storyId, // nullable nhưng required trong ctor để từ factory truyền vào
    required this.type,
    required this.type2,
    required this.text,
    required this.url,
    required this.fullLink,
    required this.seen,
    required this.time,
    required this.timeText,
    required this.name,
    required this.avatar,
  });

  factory SocialNotification.fromJson(Map<String, dynamic> json) {
    final notifier = (json['notifier'] as Map?) ?? const {};
    String _s(dynamic v) => v?.toString() ?? '';

    return SocialNotification(
      id: _s(json['id']),
      notifierId: _s(json['notifier_id']),
      recipientId: _s(json['recipient_id']),
      postId: _s(json['post_id']),
      replyId: _s(json['reply_id']),
      commentId: _s(json['comment_id']),
      pageId: _s(json['page_id']),
      groupId: _s(json['group_id']),
      groupChatId: _s(json['group_chat_id']),
      eventId: _s(json['event_id']),
      threadId: _s(json['thread_id']),
      blogId: _s(json['blog_id']),

      /// ✅ lấy đúng "story_id" từ API (có thể rỗng)
      storyId: json['story_id']?.toString().isNotEmpty == true
          ? json['story_id'].toString()
          : null,

      type: _s(json['type']),
      type2: _s(json['type2']),
      text: _s(json['text']),
      url: _s(json['url']),
      fullLink: _s(json['full_link']),
      seen: _s(json['seen']),
      time: _s(json['time']),
      timeText: _s(json['time_text']),

      name: _s(notifier['name']),
      avatar: _s(notifier['avatar']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'notifier_id': notifierId,
    'recipient_id': recipientId,
    'post_id': postId,
    'reply_id': replyId,
    'comment_id': commentId,
    'page_id': pageId,
    'group_id': groupId,
    'group_chat_id': groupChatId,
    'event_id': eventId,
    'thread_id': threadId,
    'blog_id': blogId,
    'story_id': storyId, // có thể null

    'type': type,
    'type2': type2,
    'text': text,
    'url': url,
    'full_link': fullLink,
    'seen': seen,
    'time': time,
    'time_text': timeText,
    'notifier': {
      'name': name,
      'avatar': avatar,
    },
  };

  SocialNotification copyWith({
    String? id,
    String? notifierId,
    String? recipientId,
    String? postId,
    String? replyId,
    String? commentId,
    String? pageId,
    String? groupId,
    String? groupChatId,
    String? eventId,
    String? threadId,
    String? blogId,
    String? storyId, // nullable
    String? type,
    String? type2,
    String? text,
    String? url,
    String? fullLink,
    String? seen,
    String? time,
    String? timeText,
    String? name,
    String? avatar,
  }) {
    return SocialNotification(
      id: id ?? this.id,
      notifierId: notifierId ?? this.notifierId,
      recipientId: recipientId ?? this.recipientId,
      postId: postId ?? this.postId,
      replyId: replyId ?? this.replyId,
      commentId: commentId ?? this.commentId,
      pageId: pageId ?? this.pageId,
      groupId: groupId ?? this.groupId,
      groupChatId: groupChatId ?? this.groupChatId,
      eventId: eventId ?? this.eventId,
      threadId: threadId ?? this.threadId,
      blogId: blogId ?? this.blogId,
      storyId: storyId ?? this.storyId,
      type: type ?? this.type,
      type2: type2 ?? this.type2,
      text: text ?? this.text,
      url: url ?? this.url,
      fullLink: fullLink ?? this.fullLink,
      seen: seen ?? this.seen,
      time: time ?? this.time,
      timeText: timeText ?? this.timeText,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
    );
  }
  @override
  String toString() => jsonEncode({
    'id': id,
    'type': type,
    'type2': type2,
    'url': url,
    'notifierId': notifierId,
    'storyId': storyId,
    'name': name,
    'avatar': avatar,
    'timeText': timeText,
    'seen': seen,
    'post_id': postId
  });

}
