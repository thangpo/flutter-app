class SocialUserShort {
  final int id;
  final String name;
  final String avatar;

  SocialUserShort({
    required this.id,
    required this.name,
    required this.avatar,
  });

  factory SocialUserShort.fromJson(Map<String, dynamic> json) {
    return SocialUserShort(
      id: int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      name: (json['name'] ?? json['username'] ?? '').toString(),
      avatar: (json['avatar'] ?? json['avatar_url'] ?? '').toString(),
    );
  }
}

class SocialPageReplyMessage {
  final int id;
  final int fromId;
  final int toId;
  final int pageId;
  final String text;
  final String media;
  final String stickers;
  final double? lng;
  final double? lat;
  final int time;
  final String timeText;
  final String position; // left | right
  final String type;     // left_text, right_image,...
  final String fileSize;
  final String displayText;
  final SocialUserShort? user;

  SocialPageReplyMessage({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.pageId,
    required this.text,
    required this.media,
    required this.stickers,
    required this.lng,
    required this.lat,
    required this.time,
    required this.timeText,
    required this.position,
    required this.type,
    required this.fileSize,
    required this.displayText,

    this.user,
  });

  factory SocialPageReplyMessage.fromJson(Map<String, dynamic> json) {
    return SocialPageReplyMessage(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      fromId: int.tryParse(json['from_id']?.toString() ?? '') ?? 0,
      toId: int.tryParse(json['to_id']?.toString() ?? '') ?? 0,
      pageId: int.tryParse(json['page_id']?.toString() ?? '') ?? 0,
      text: (json['text'] ?? '').toString(),
      media: (json['media'] ?? '').toString(),
      stickers: (json['stickers'] ?? '').toString(),
      lng: json['lng'] != null
          ? double.tryParse(json['lng'].toString())
          : null,
      lat: json['lat'] != null
          ? double.tryParse(json['lat'].toString())
          : null,
      time: int.tryParse(json['time']?.toString() ?? '') ?? 0,
      timeText: (json['time_text'] ?? '').toString(),
      position: (json['position'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      fileSize: (json['file_size'] ?? '').toString(),
      displayText: (json['display_text'] ?? json['text'] ?? '').toString(),

      user: json['messageUser'] is Map<String, dynamic>
          ? SocialUserShort.fromJson(
        json['messageUser'] as Map<String, dynamic>,
      )
          : null,
    );
  }
}

class SocialPageMessage {
  final int id;
  final int fromId;
  final int toId;
  final int pageId;
  final String text;
  final String media;
  final String stickers;
  final double? lng;
  final double? lat;
  final int time;
  final String timeText;
  final String position; // left | right
  final String type;     // left_text, right_image,...
  final String fileSize;
  final String messageHashId;
  final String displayText;
  final SocialUserShort? user;
  final SocialPageReplyMessage? reply;

  SocialPageMessage({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.pageId,
    required this.text,
    required this.media,
    required this.stickers,
    required this.lng,
    required this.lat,
    required this.time,
    required this.timeText,
    required this.position,
    required this.type,
    required this.fileSize,
    required this.messageHashId,
    required this.displayText,

    this.user,
    this.reply,
  });

  factory SocialPageMessage.fromJson(Map<String, dynamic> json) {
    return SocialPageMessage(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      fromId: int.tryParse(json['from_id']?.toString() ?? '') ?? 0,
      toId: int.tryParse(json['to_id']?.toString() ?? '') ?? 0,
      pageId: int.tryParse(json['page_id']?.toString() ?? '') ?? 0,
      text: (json['text'] ?? '').toString(),
      media: (json['media'] ?? '').toString(),
      stickers: (json['stickers'] ?? '').toString(),
      lng: json['lng'] != null
          ? double.tryParse(json['lng'].toString())
          : null,
      lat: json['lat'] != null
          ? double.tryParse(json['lat'].toString())
          : null,
      time: int.tryParse(json['time']?.toString() ?? '') ?? 0,
      timeText: (json['time_text'] ?? '').toString(),
      position: (json['position'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      fileSize: (json['file_size'] ?? '').toString(),
      messageHashId: (json['message_hash_id'] ?? '').toString(),
      displayText: (json['display_text'] ?? json['text'] ?? '').toString(),

      user: json['user_data'] is Map<String, dynamic>
          ? SocialUserShort.fromJson(
        json['user_data'] as Map<String, dynamic>,
      )
          : null,
      reply: json['reply'] is Map<String, dynamic>
          ? SocialPageReplyMessage.fromJson(
        json['reply'] as Map<String, dynamic>,
      )
          : null,
    );
  }
}
