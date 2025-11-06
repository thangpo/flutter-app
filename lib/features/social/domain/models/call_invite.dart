// lib/features/social/domain/models/call_invite.dart
import 'dart:convert';

class CallInvite {
  final int callId;

  /// 'audio' | 'video'
  final String media;
  final DateTime issuedAt;

  // Alias tương thích chỗ gọi cũ
  String get mediaType => media;

  CallInvite({
    required this.callId,
    required this.media,
    required this.issuedAt,
  });

  /// Chuẩn hoá ts: tự nhận biết giây vs mili-giây
  static DateTime _issuedFromTs(int ts) {
    if (ts <= 0) return DateTime.now();
    final ms = ts >= 1000000000000 ? ts : ts * 1000; // >= 1e12 => milliseconds
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// ---------- Build ----------
  /// JSON payload (khuyên dùng)
  /// {"type":"call_invite","call_id":123,"media":"video","ts":1762330000}
  static String build(int callId, String media) {
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return jsonEncode({
      'type': 'call_invite',
      'call_id': callId,
      'media': media, // 'audio' | 'video'
      'ts': nowSec,
    });
  }

  /// Pipe payload (tương thích định dạng cũ / rút gọn)
  /// "__CALL_INVITE__|<callId>|<media>|<ts>"
  static String buildPipe(int callId, String media) {
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return '__CALL_INVITE__|$callId|$media|$nowSec';
  }

  /// ---------- Parse ----------
  /// Hỗ trợ:
  /// 1) JSON: {"type":"call_invite","call_id":...,"media": "...","ts": ...}
  ///    (kể cả bị HTML-escape &quot;)
  /// 2) Pipe: "__CALL_INVITE__|<callId>|<media>|<ts>" hoặc "CALL|<id>|<media>|<ts>"
  static CallInvite? tryParse(String raw) {
    var s = raw.trim();

    // Unescape tối thiểu cho JSON bị HTML-escape
    if (s.contains('&quot;')) {
      s = s.replaceAll('&quot;', '"').replaceAll('&amp;', '&');
    }

    // --- JSON ---
    if (s.startsWith('{') && s.endsWith('}')) {
      try {
        final map = jsonDecode(s);
        if (map is Map &&
            map['type'] == 'call_invite' &&
            map['call_id'] != null &&
            map['media'] != null) {
          final callId = int.tryParse('${map['call_id']}') ?? 0;
          final media = '${map['media']}'.toLowerCase();
          final tsRaw = int.tryParse('${map['ts'] ?? 0}') ?? 0;
          final issued = _issuedFromTs(tsRaw);

          if (callId > 0 && (media == 'audio' || media == 'video')) {
            return CallInvite(callId: callId, media: media, issuedAt: issued);
          }
        }
      } catch (_) {/* ignore */}
    }

    // --- Pipe với 2 prefix hợp lệ ---
    if (s.startsWith('__CALL_INVITE__|') || s.startsWith('CALL|')) {
      final parts = s.split('|');
      if (parts.length >= 3) {
        // __CALL_INVITE__|<id>|<media>|<ts?>
        // CALL|<id>|<media>|<ts?>
        final idxShift = s.startsWith('__CALL_INVITE__|') ? 1 : 0;
        final id = int.tryParse(parts[1 + idxShift]) ?? 0;
        final media = parts[2 + idxShift].toLowerCase();
        final tsRaw = (parts.length > 3 + idxShift)
            ? int.tryParse(parts[3 + idxShift]) ?? 0
            : 0;
        final issued = _issuedFromTs(tsRaw);

        if (id > 0 && (media == 'audio' || media == 'video')) {
          return CallInvite(callId: id, media: media, issuedAt: issued);
        }
      }
    }

    return null;
  }

  /// Hết hạn sau TTL (mặc định 90s)
  bool isExpired({Duration ttl = const Duration(seconds: 90)}) {
    return DateTime.now().difference(issuedAt).abs() > ttl;
  }
}
