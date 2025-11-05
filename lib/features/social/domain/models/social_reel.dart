// lib/features/social/domain/models/social_reel.dart
// import 'package:collection/collection.dart';

class SocialReel {
  final String id;           // post_id / media_id / id
  final String userId;       // user_id / publisher_id / owner_id
  final String? caption;     // caption / text / description
  final String videoUrl;     // video / video_src / postFile / file / filename
  final String? thumbUrl;    // thumbnail / postFileThumb / image / cover
  final int? width;          // video_width / width
  final int? height;         // video_height / height
  final Duration? duration;  // duration (sec or "HH:mm:ss")
  final DateTime? createdAt; // time / created_at / post_time (epoch or iso)

  const SocialReel({
    required this.id,
    required this.userId,
    required this.videoUrl,
    this.caption,
    this.thumbUrl,
    this.width,
    this.height,
    this.duration,
    this.createdAt,
  });

  SocialReel copyWith({
    String? id,
    String? userId,
    String? caption,
    String? videoUrl,
    String? thumbUrl,
    int? width,
    int? height,
    Duration? duration,
    DateTime? createdAt,
  }) {
    return SocialReel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      caption: caption ?? this.caption,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      width: width ?? this.width,
      height: height ?? this.height,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ------- Parse helpers -------
  static String _absUrl(String? url, String baseUrl) {
    if (url == null || url.trim().isEmpty) return '';
    final u = url.trim();
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    final b = baseUrl.replaceAll(RegExp(r'/$'), '');
    final p = u.startsWith('/') ? u.substring(1) : u;
    return '$b/$p';
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    final s = v.toString().trim();
    final n = int.tryParse(s);
    return n;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is int) {
      // epoch seconds or ms
      if (v > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(v);
      return DateTime.fromMillisecondsSinceEpoch(v * 1000);
    }
    final s = v.toString().trim();
    // epoch string
    final asInt = int.tryParse(s);
    if (asInt != null) {
      return _parseDate(asInt);
    }
    // iso
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return null;
    }
  }

  static Duration? _parseDuration(dynamic v) {
    if (v == null) return null;
    if (v is int) return Duration(seconds: v);
    final s = v.toString().trim();
    // "HH:mm:ss" | "mm:ss"
    if (s.contains(':')) {
      final parts = s.split(':').map((e) => e.trim()).toList();
      int h = 0, m = 0, sec = 0;
      if (parts.length == 3) {
        h = int.tryParse(parts[0]) ?? 0;
        m = int.tryParse(parts[1]) ?? 0;
        sec = int.tryParse(parts[2]) ?? 0;
      } else if (parts.length == 2) {
        m = int.tryParse(parts[0]) ?? 0;
        sec = int.tryParse(parts[1]) ?? 0;
      }
      return Duration(hours: h, minutes: m, seconds: sec);
    }
    final asInt = int.tryParse(s);
    return asInt != null ? Duration(seconds: asInt) : null;
  }

  // ------- fromJson (chịu nhiều format của WoWonder/album) -------
  factory SocialReel.fromJson(Map<String, dynamic> m, {required String baseUrl}) {
    // id
    final id = (m['id'] ?? m['post_id'] ?? m['media_id'] ?? m['video_id'] ?? '')
        .toString();

    // userId
    final userId = (m['user_id'] ??
        m['publisher_id'] ??
        m['owner_id'] ??
        (m['publisher'] is Map ? m['publisher']['user_id'] : null) ??
        '')
        .toString();

    // caption
    final caption = (m['caption'] ??
        m['text'] ??
        m['description'] ??
        (m['postText'] ?? m['post_text']))
        ?.toString();

    // video url candidates
    final candidatesVideo = <String?>[
      m['video_src']?.toString(),
      m['video']?.toString(),
      m['postFile']?.toString(),
      m['file']?.toString(),
      m['filename']?.toString(),
      m['source']?.toString(),
      (m['media'] is Map ? m['media']['video']?.toString() : null),
    ];
    final rawVideo = candidatesVideo.firstWhere(
          (e) => e != null && e.toString().trim().isNotEmpty,
      orElse: () => '',
    )!;
    final videoUrl = _absUrl(rawVideo, baseUrl);

    // thumb url candidates
    final candidatesThumb = <String?>[
      m['thumbnail']?.toString(),
      m['postFileThumb']?.toString(),
      m['image']?.toString(),
      m['cover']?.toString(),
      (m['media'] is Map ? m['media']['thumbnail']?.toString() : null),
      // Trước đây dùng firstWhereOrNull ở đây -> thay bằng loop thuần:
      (() {
        final imgs = m['images'];
        if (imgs is List) {
          for (final e in imgs) {
            if (e is Map) {
              final s = e['image']?.toString();
              if (s != null && s.trim().isNotEmpty) return s;
            }
          }
        }
        return null;
      })(),
    ];
    final rawThumb = candidatesThumb.firstWhere(
          (e) => e != null && e.toString().trim().isNotEmpty,
      orElse: () => '',
    )!;
    final thumbUrl = rawThumb.isEmpty ? null : _absUrl(rawThumb, baseUrl);

    // width/height
    final width = _asInt(m['video_width'] ?? m['width']);
    final height = _asInt(m['video_height'] ?? m['height']);

    // duration
    final duration = _parseDuration(m['duration']);

    // createdAt
    final createdAt = _parseDate(m['time'] ?? m['created_at'] ?? m['post_time']);

    if (id.isEmpty || userId.isEmpty || videoUrl.isEmpty) {
      // Không đủ dữ liệu để coi như một reel hợp lệ
      throw StateError('Invalid reel item: $m');
    }

    return SocialReel(
      id: id,
      userId: userId,
      caption: caption,
      videoUrl: videoUrl,
      thumbUrl: thumbUrl,
      width: width,
      height: height,
      duration: duration,
      createdAt: createdAt,
    );
  }

  // ------- parse từ response getAlbumUser(type: 'videos') -------
  static List<SocialReel> parseFromGetAlbums(
      dynamic raw, {
        required String baseUrl,
      }) {
    final List list = () {
      if (raw is List) return raw;
      if (raw is Map<String, dynamic>) {
        // Một số API trả {status, data:[...]} hoặc {videos:[...]} hoặc {albums:[...]}
        if (raw['data'] is List) return raw['data'] as List;
        if (raw['videos'] is List) return raw['videos'] as List;
        if (raw['albums'] is List) return raw['albums'] as List;
        if (raw['results'] is List) return raw['results'] as List;
      }
      return const [];
    }();

    final result = <SocialReel>[];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        try {
          result.add(SocialReel.fromJson(item, baseUrl: baseUrl));
        } catch (_) {
          // bỏ qua item lỗi format
        }
      }
    }
    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'caption': caption,
      'video_url': videoUrl,
      'thumb_url': thumbUrl,
      'width': width,
      'height': height,
      'duration': duration?.inSeconds,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'SocialReel(id:$id, userId:$userId, video:$videoUrl, thumb:$thumbUrl)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SocialReel &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}
