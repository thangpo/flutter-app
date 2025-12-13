import 'dart:convert';

import 'package:flutter/material.dart';

class SocialStory {
  final String id;
  final String? userId;
  final String? userName;
  final String? userAvatar;
  final List<SocialStoryItem> items;
  final bool isAd;
  final Map<String, dynamic>? adPayload;

  /// Convenience preview thumbnail (falls back to media when needed).
  final String? thumbUrl;

  /// Convenience preview media (image/video) URL from the first item.
  final String? mediaUrl;

  const SocialStory({
    required this.id,
    this.userId,
    this.userName,
    this.userAvatar,
    this.thumbUrl,
    this.mediaUrl,
    this.items = const <SocialStoryItem>[],
    this.isAd = false,
    this.adPayload,
  });

  bool get hasItems => items.isNotEmpty;
  SocialStoryItem? get firstItem => hasItems ? items.first : null;

  SocialStory copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    List<SocialStoryItem>? items,
    String? thumbUrl,
    String? mediaUrl,
    bool? isAd,
    Map<String, dynamic>? adPayload,
  }) {
    return SocialStory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      items: items ?? this.items,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      isAd: isAd ?? this.isAd,
      adPayload: adPayload ?? this.adPayload,
    );
  }

  factory SocialStory.fromJson(Map<String, dynamic> raw) {
    final Map<String, dynamic> json = Map<String, dynamic>.from(raw);

    final List<SocialStoryItem> parsedItems = <SocialStoryItem>[];
    final dynamic storiesField = json['stories'];
    if (storiesField is List) {
      for (final dynamic entry in storiesField) {
        if (entry is Map<String, dynamic>) {
          parsedItems.add(SocialStoryItem.fromJson(entry));
        }
      }
    } else {
      parsedItems.add(SocialStoryItem.fromJson(json));
    }

    SocialStoryItem? first = parsedItems.isNotEmpty ? parsedItems.first : null;

    Map<String, dynamic> userData = <String, dynamic>{};
    if (json['user_data'] is Map<String, dynamic>) {
      userData = Map<String, dynamic>.from(json['user_data']);
    } else if (first?.userData != null) {
      userData = Map<String, dynamic>.from(first!.userData!);
    }

    // Merge top-level fields that WoWonder returns alongside the grouped stories.
    void mergeUserField(String key, {String? alias}) {
      final value = json[key] ?? (alias != null ? json[alias] : null);
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      final current = userData[key];
      if (current == null || (current is String && current.isEmpty)) {
        userData[key] = value;
      }
    }

    mergeUserField('user_id');
    mergeUserField('username');
    mergeUserField('name');
    mergeUserField('first_name');
    mergeUserField('last_name');
    mergeUserField('avatar');
    mergeUserField('cover');

    final dynamic fallbackUserId =
        json['user_id'] ?? json['owner_id'] ?? userData['user_id'];
    final String? resolvedUserId =
        (userData['user_id'] ?? fallbackUserId)?.toString();

    first ??= parsedItems.isNotEmpty ? parsedItems.first : null;
    final String resolvedId =
        (first?.id ?? json['story_id'] ?? json['id'] ?? resolvedUserId ?? '')
            .toString();

    return SocialStory(
      id: resolvedId,
      userId: resolvedUserId,
      userName: (userData['name'] ??
              userData['username'] ??
              userData['first_name'] ??
              '')
          .toString(),
      userAvatar: userData['avatar']?.toString(),
      thumbUrl: first?.thumbUrl,
      mediaUrl: first?.mediaUrl,
      items: parsedItems,
      isAd: _parseBool(json['is_ad']),
      adPayload: json['ad_payload'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['ad_payload'])
          : null,
    );
  }
}

class SocialStoryItem {
  final String id;
  final String? userId;
  final Map<String, dynamic>? userData;
  final String? description;
  final DateTime? postedAt;
  final DateTime? expireAt;
  final String? mediaUrl;
  final String? thumbUrl;
  final bool isVideo;
  final bool isViewed;
  final int? viewCount;
  final SocialStoryReaction? reaction;
  final List<SocialStoryOverlay> overlays;
  static const Object _undefined = Object();

  const SocialStoryItem({
    required this.id,
    this.userId,
    this.userData,
    this.description,
    this.postedAt,
    this.expireAt,
    this.mediaUrl,
    this.thumbUrl,
    this.isVideo = false,
    this.isViewed = false,
    this.viewCount,
    this.reaction,
    this.overlays = const <SocialStoryOverlay>[],
  });

  SocialStoryItem copyWith({
    String? id,
    String? userId,
    Map<String, dynamic>? userData,
    String? description,
    DateTime? postedAt,
    DateTime? expireAt,
    String? mediaUrl,
    String? thumbUrl,
    bool? isVideo,
    bool? isViewed,
    int? viewCount,
    Object? reaction = _undefined,
    List<SocialStoryOverlay>? overlays,
  }) {
    return SocialStoryItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userData: userData ?? this.userData,
      description: description ?? this.description,
      postedAt: postedAt ?? this.postedAt,
      expireAt: expireAt ?? this.expireAt,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      isVideo: isVideo ?? this.isVideo,
      isViewed: isViewed ?? this.isViewed,
      viewCount: viewCount ?? this.viewCount,
      reaction: identical(reaction, _undefined)
          ? this.reaction
          : reaction as SocialStoryReaction?,
      overlays: overlays ?? this.overlays,
    );
  }

  factory SocialStoryItem.fromJson(Map<String, dynamic> raw) {
    final Map<String, dynamic> json = Map<String, dynamic>.from(raw);
    final Map<String, dynamic>? user = json['user_data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['user_data'])
        : null;

    final int? postedTs = _parseTimestamp(json['posted']);
    final int? expireTs = _parseTimestamp(json['expire']);

    final _MediaInfo media = _extractMedia(json);
    final SocialStoryReaction? reaction =
        json['reaction'] is Map<String, dynamic>
            ? SocialStoryReaction.fromJson(
                Map<String, dynamic>.from(json['reaction']))
            : null;
    final List<SocialStoryOverlay> overlays =
        _parseOverlays(json['overlay_meta']);

    return SocialStoryItem(
      id: (json['story_id'] ?? json['id'] ?? '').toString(),
      userId:
          (json['user_id'] ?? user?['user_id'] ?? user?['id'] ?? '').toString(),
      userData: user,
      description: (json['description'] ?? json['title'] ?? '').toString(),
      postedAt: postedTs != null
          ? DateTime.fromMillisecondsSinceEpoch(postedTs * 1000)
          : null,
      expireAt: expireTs != null
          ? DateTime.fromMillisecondsSinceEpoch(expireTs * 1000)
          : null,
      mediaUrl: media.mediaUrl,
      thumbUrl: media.thumbUrl,
      isVideo: media.isVideo,
      isViewed: _parseBool(json['is_viewed']),
      viewCount: _parseInt(json['view_count']),
      reaction: reaction,
      overlays: overlays,
    );
  }
}

class SocialStoryOverlay {
  final String type;
  final String text;
  final double x;
  final double y;
  final double width;
  final double height;
  final double fontScale;
  final double rotation;
  final String align;
  final bool hasBackground;
  final Color color;

  const SocialStoryOverlay({
    required this.type,
    required this.text,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.fontScale,
    required this.rotation,
    required this.align,
    required this.hasBackground,
    required this.color,
  });

  factory SocialStoryOverlay.fromJson(Map<String, dynamic> json) {
    final String rawColor = (json['color'] ?? '').toString();
    return SocialStoryOverlay(
      type: (json['type'] ?? 'text').toString(),
      text: (json['text'] ?? '').toString(),
      x: _parseDouble(json['x']) ?? 0.5,
      y: _parseDouble(json['y']) ?? 0.5,
      width: _parseDouble(json['w']) ?? 0.6,
      height: _parseDouble(json['h']) ?? 0.2,
      fontScale: _parseDouble(json['font_scale']) ?? 0.05,
      rotation: _parseDouble(json['rotation']) ?? 0,
      align: (json['align'] ?? 'center').toString(),
      hasBackground: _parseBool(json['has_bg']),
      color: _parseColor(rawColor) ?? Colors.white,
    );
  }
}

List<SocialStoryOverlay> _parseOverlays(dynamic raw) {
  if (raw == null) return const <SocialStoryOverlay>[];
  List<dynamic>? list;
  if (raw is String && raw.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) list = decoded;
    } catch (_) {}
  } else if (raw is List) {
    list = raw;
  }
  if (list == null) return const <SocialStoryOverlay>[];
  final List<SocialStoryOverlay> overlays = <SocialStoryOverlay>[];
  for (final dynamic entry in list) {
    if (entry is Map<String, dynamic>) {
      overlays.add(SocialStoryOverlay.fromJson(entry));
    } else if (entry is Map) {
      overlays.add(SocialStoryOverlay.fromJson(
          Map<String, dynamic>.from(entry as Map<Object?, Object?>)));
    }
  }
  return overlays;
}

Color? _parseColor(String? value) {
  if (value == null || value.isEmpty) return null;
  String v = value;
  if (v.startsWith('#')) v = v.substring(1);
  if (v.length == 6) v = 'FF$v';
  final int? intValue = int.tryParse(v, radix: 16);
  if (intValue == null) return null;
  return Color(intValue);
}

class SocialStoryReaction {
  final bool isReacted;
  final String? type;
  final int? count;

  const SocialStoryReaction({
    required this.isReacted,
    this.type,
    this.count,
  });

  SocialStoryReaction copyWith({
    bool? isReacted,
    String? type,
    int? count,
  }) {
    return SocialStoryReaction(
      isReacted: isReacted ?? this.isReacted,
      type: type ?? this.type,
      count: count ?? this.count,
    );
  }

  factory SocialStoryReaction.fromJson(Map<String, dynamic> json) {
    return SocialStoryReaction(
      isReacted: _parseBool(json['is_reacted']),
      type: normalizeSocialReaction(json['type']),
      count: _parseInt(json['count']),
    );
  }
}

class SocialStoryViewer {
  final String id;
  final String userId;
  final String? name;
  final String? avatar;
  final bool isVerified;
  final String reaction;
  final int? reactionCount;
  final List<String> reactions;
  final DateTime? viewedAt;

  const SocialStoryViewer({
    required this.id,
    required this.userId,
    this.name,
    this.avatar,
    this.isVerified = false,
    this.reaction = '',
    this.reactionCount,
    this.reactions = const <String>[],
    this.viewedAt,
  });

  SocialStoryViewer copyWith({
    String? id,
    String? userId,
    String? name,
    String? avatar,
    bool? isVerified,
    String? reaction,
    int? reactionCount,
    List<String>? reactions,
    DateTime? viewedAt,
  }) {
    final List<String> resolvedReactions = reactions ?? this.reactions;
    final String resolvedReaction = reaction ??
        (resolvedReactions.isNotEmpty ? resolvedReactions.last : this.reaction);
    final int? resolvedReactionCount = reactionCount ??
        (resolvedReactions.isNotEmpty
            ? resolvedReactions.length
            : this.reactionCount);
    return SocialStoryViewer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      isVerified: isVerified ?? this.isVerified,
      reaction: resolvedReaction,
      reactionCount: resolvedReactionCount,
      reactions: resolvedReactions,
      viewedAt: viewedAt ?? this.viewedAt,
    );
  }

  factory SocialStoryViewer.fromJson(Map<String, dynamic> raw) {
    final Map<String, dynamic> json = Map<String, dynamic>.from(raw);
    final Map<String, dynamic>? user = json['user_data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['user_data'])
        : (json['user'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(json['user'])
            : null);

    final String rawUserId =
        (json['user_id'] ?? user?['user_id'] ?? user?['id'] ?? '').toString();
    final String resolvedUserId = rawUserId.isNotEmpty ? rawUserId : '';

    final String rawId =
        (json['id'] ?? json['view_id'] ?? json['story_view_id'] ?? '')
            .toString();
    final String resolvedId = rawId.isNotEmpty
        ? rawId
        : (resolvedUserId.isNotEmpty ? resolvedUserId : '');

    final String? reactionRaw = _extractReactionType(
      json['reaction'] ??
          json['story_reaction'] ??
          json['reaction_type'] ??
          json['type'],
    );

    final List<String> reactionList = <String>[];
    final dynamic rawReactions = json['reactions'] ?? json['reaction_list'];
    if (rawReactions is Iterable) {
      for (final dynamic entry in rawReactions) {
        final String normalized = normalizeSocialReaction(entry);
        if (normalized.isNotEmpty) {
          reactionList.add(normalized);
        }
      }
    }

    final String normalizedReaction = normalizeSocialReaction(reactionRaw);
    if (normalizedReaction.isNotEmpty && reactionList.isEmpty) {
      reactionList.add(normalizedReaction);
    }

    final int? reactionCount =
        _parseInt(json['reaction_count'] ?? json['count'] ?? json['reactions']);

    final int? viewTs =
        _parseTimestamp(json['time'] ?? json['view_time'] ?? json['seen']);
    final DateTime? viewedAt = viewTs != null
        ? DateTime.fromMillisecondsSinceEpoch(viewTs * 1000)
        : null;

    return SocialStoryViewer(
      id: resolvedId,
      userId: resolvedUserId,
      name: (json['name'] ??
              json['username'] ??
              user?['name'] ??
              user?['username'] ??
              '')
          .toString(),
      avatar: user?['avatar']?.toString(),
      isVerified: _parseBool(user?['verified']),
      reaction:
          reactionList.isNotEmpty ? reactionList.last : normalizedReaction,
      reactionCount: reactionCount ??
          (reactionList.isNotEmpty ? reactionList.length : null),
      reactions: reactionList,
      viewedAt: viewedAt,
    );
  }
}

class SocialStoryViewersPage {
  final List<SocialStoryViewer> viewers;
  final int total;
  final bool hasMore;
  final int nextOffset;

  const SocialStoryViewersPage({
    this.viewers = const <SocialStoryViewer>[],
    this.total = 0,
    this.hasMore = false,
    this.nextOffset = 0,
  });

  SocialStoryViewersPage copyWith({
    List<SocialStoryViewer>? viewers,
    int? total,
    bool? hasMore,
    int? nextOffset,
  }) {
    return SocialStoryViewersPage(
      viewers: viewers ?? this.viewers,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      nextOffset: nextOffset ?? this.nextOffset,
    );
  }
}

String normalizeSocialReaction(dynamic reaction) {
  final String? raw = _extractReactionType(reaction);
  if (raw == null) return '';
  final String value = raw.trim();
  if (value.isEmpty) return '';
  switch (value.toLowerCase()) {
    case '1':
    case 'like':
      return 'Like';
    case '2':
    case 'love':
      return 'Love';
    case '3':
    case 'haha':
      return 'HaHa';
    case '4':
    case 'wow':
      return 'Wow';
    case '5':
    case 'sad':
      return 'Sad';
    case '6':
    case 'angry':
      return 'Angry';
    default:
      return value;
  }
}

String? _extractReactionType(dynamic raw) {
  if (raw == null) return null;
  if (raw is SocialStoryReaction) {
    return raw.type;
  }
  if (raw is Map<String, dynamic>) {
    return raw['type']?.toString() ??
        raw['reaction']?.toString() ??
        raw['reaction_type']?.toString() ??
        raw['name']?.toString();
  }
  if (raw is Iterable) {
    for (final dynamic item in raw) {
      final String? value = _extractReactionType(item);
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
  return raw.toString();
}

class _MediaInfo {
  final String? mediaUrl;
  final String? thumbUrl;
  final bool isVideo;

  const _MediaInfo({this.mediaUrl, this.thumbUrl, this.isVideo = false});
}

_MediaInfo _extractMedia(Map<String, dynamic> json) {
  String? mediaUrl = json['media']?.toString();
  String? thumbUrl = json['thumbnail']?.toString();
  bool isVideo = false;

  final dynamic images = json['images'];
  if ((mediaUrl == null || mediaUrl.isEmpty) && images is List) {
    for (final dynamic image in images) {
      if (image is String && image.isNotEmpty) {
        mediaUrl = image;
        if (thumbUrl == null || thumbUrl.isEmpty) {
          thumbUrl = image;
        }
        break;
      } else if (image is Map<String, dynamic>) {
        final String? url = image['image']?.toString() ??
            image['src']?.toString() ??
            image['url']?.toString();
        if (url != null && url.isNotEmpty) {
          mediaUrl = url;
          if (thumbUrl == null || thumbUrl.isEmpty) {
            thumbUrl = image['thumbnail']?.toString() ?? url;
          }
          break;
        }
      }
    }
  }

  final dynamic videos = json['videos'];
  if (videos is List && videos.isNotEmpty) {
    final dynamic first = videos.first;
    String? videoUrl;
    String? videoThumb;
    if (first is Map<String, dynamic>) {
      videoUrl = first['video_src']?.toString() ??
          first['filename']?.toString() ??
          first['video']?.toString();
      videoThumb = first['thumbnail']?.toString();
    } else if (first is String) {
      videoUrl = first;
    }
    if (videoUrl != null && videoUrl.isNotEmpty) {
      mediaUrl = videoUrl;
      isVideo = true;
      if (videoThumb != null && videoThumb.isNotEmpty) {
        thumbUrl = videoThumb;
      }
    }
  }

  if ((thumbUrl == null || thumbUrl.isEmpty) && mediaUrl != null) {
    thumbUrl = mediaUrl;
  }

  return _MediaInfo(mediaUrl: mediaUrl, thumbUrl: thumbUrl, isVideo: isVideo);
}

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    return value == '1' || value.toLowerCase() == 'true';
  }
  return false;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

int? _parseTimestamp(dynamic value) {
  final int? ts = _parseInt(value);
  return ts;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
