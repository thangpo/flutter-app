// import 'dart:convert';

// /// Trả về chuỗi hiển thị từ 1 object message của WoWonder.
// /// - Ưu tiên các field đã giải mã từ server: textDecoded / text_decoded / message...
// /// - Nếu chỉ còn 'text' (thường là base64), thử decode base64 -> utf8.
// /// - Nếu vẫn không đọc được, trả nguyên văn (để còn debug).
// String pickWoWonderText(Map<String, dynamic> m) {
//   // 1) Ưu tiên những field server đã giải mã
//   for (final k in const [
//     'textDecoded',
//     'text_decoded',
//     'message',
//     'message_text',
//     'original_text',
//   ]) {
//     final v = m[k];
//     if (v != null && v.toString().trim().isNotEmpty) {
//       return v.toString();
//     }
//   }

//   // 2) Thử từ 'text' (thường là base64-cipher hoặc base64-utf8)
//   final raw = (m['text'] ?? '').toString();
//   if (raw.isEmpty) return '';

//   // Thử base64 -> utf8
//   final maybe = _tryBase64Utf8(raw);
//   return maybe ?? raw;
// }

// String? _tryBase64Utf8(String s) {
//   final t = s.trim();
//   final base64Regex = RegExp(r'^[A-Za-z0-9+/=]+$');
//   if (!base64Regex.hasMatch(t) || t.length % 4 != 0) return null;
//   try {
//     final bytes = base64.decode(t);
//     final txt = utf8.decode(bytes, allowMalformed: true);
//     // rỗng / không in được -> coi như fail
//     final printable = RegExp(r'[\x20-\x7E\u0080-\uFFFF]');
//     if (!printable.hasMatch(txt)) return null;
//     return txt;
//   } catch (_) {
//     return null;
//   }
// }


import 'dart:core';
import 'package:path/path.dart' as p;

import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

/// Lấy chuỗi mô tả để hiển thị trong bubble (fallback khi không phải ảnh/video)
String pickWoWonderText(Map msg) {
  final textDecoded = _str(msg['textDecoded']);
  final text = _str(msg['text']);
  final gif = _str(msg['gif']);
  final stickers = _str(msg['stickers']);
  final productId = _str(msg['product_id']);
  final media = _str(msg['media']);
  final mediaName = _str(msg['mediaFileName']);

  if (textDecoded.isNotEmpty) return textDecoded;
  if (text.isNotEmpty) return text;

  if (isImageMessage(msg)) {
    // tên file ảnh
    if (mediaName.isNotEmpty) return mediaName;
    if (media.isNotEmpty) return p.basename(media);
    return '[Image]';
  }
  if (isVideoMessage(msg)) {
    if (mediaName.isNotEmpty) return mediaName;
    if (media.isNotEmpty) return p.basename(media);
    return '[Video]';
  }
  if (isAudioMessage(msg)) {
    if (mediaName.isNotEmpty) return mediaName;
    if (media.isNotEmpty) return p.basename(media);
    return '[Audio]';
  }

  if (gif.isNotEmpty) return '[GIF]';
  if (stickers.isNotEmpty) return '[Sticker]';
  if (productId.isNotEmpty && productId != '0') return '[Product]';

  // Cuối cùng: hiện tên file nếu có, hoặc type
  if (mediaName.isNotEmpty) return mediaName;
  if (media.isNotEmpty) return p.basename(media);

  final type = _str(msg['type'] ?? msg['type_two']);
  return type.isNotEmpty ? '[$type]' : '';
}

/// URL tuyệt đối cho media (ảnh/video/audio/file)
String? mediaUrl(Map msg) {
  // Sticker có thể là url tuyệt đối
  final stickers = _str(msg['stickers']);
  if (stickers.isNotEmpty) return _abs(stickers);

  final media = _str(msg['media']);
  if (media.isEmpty) return null;

  return _abs(media);
}

/// Có phải ảnh?
bool isImageMessage(Map msg) {
  // type từ WoWonder thường có chứa "image"
  final t = _str(msg['type'] ?? msg['type_two']).toLowerCase();
  if (t.contains('image') || t.contains('_image')) return true;

  final m = _str(msg['media']).toLowerCase();
  return _hasAnyExt(m, const ['.jpg', '.jpeg', '.png', '.gif', '.webp']);
}

/// Có phải video?
bool isVideoMessage(Map msg) {
  final t = _str(msg['type'] ?? msg['type_two']).toLowerCase();
  if (t.contains('video') || t.contains('_video')) return true;

  final m = _str(msg['media']).toLowerCase();
  return _hasAnyExt(m, const ['.mp4', '.mov', '.mkv', '.webm', '.3gp']);
}

/// Có phải audio/voice?
bool isAudioMessage(Map msg) {
  final t = _str(msg['type'] ?? msg['type_two']).toLowerCase();
  if (t.contains('audio') || t.contains('_audio') || t.contains('voice')) {
    return true;
  }

  final m = _str(msg['media']).toLowerCase();
  return _hasAnyExt(m, const ['.m4a', '.aac', '.mp3', '.wav', '.ogg']);
}

/// Tên file (nếu có)
String? filenameFromMessage(Map msg) {
  final n = _str(msg['mediaFileName']);
  if (n.isNotEmpty) return n;
  final m = _str(msg['media']);
  if (m.isNotEmpty) return p.basename(m);
  return null;
}

// ================= helpers =================

String _str(dynamic v) => (v == null) ? '' : v.toString().trim();

bool _hasAnyExt(String path, List<String> exts) {
  if (path.isEmpty) return false;
  final ext = p.extension(path);
  for (final e in exts) {
    if (ext == e) return true;
  }
  return false;
}

String _abs(String maybeUrl) {
  final u = maybeUrl.trim();
  if (u.isEmpty) return u;

  // Đã tuyệt đối
  if (u.startsWith('http://') || u.startsWith('https://')) return u;

  // Đôi khi WoWonder trả về đường dẫn kiểu "upload/photos/2025/.."
  // Ghép với base
  final base = AppConstants.socialBaseUrl.endsWith('/')
      ? AppConstants.socialBaseUrl
          .substring(0, AppConstants.socialBaseUrl.length - 1)
      : AppConstants.socialBaseUrl;

  final path = u.startsWith('/') ? u : '/$u';
  return '$base$path';
}
