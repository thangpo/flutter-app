import 'dart:convert';

/// Trả về chuỗi hiển thị từ 1 object message của WoWonder.
/// - Ưu tiên các field đã giải mã từ server: textDecoded / text_decoded / message...
/// - Nếu chỉ còn 'text' (thường là base64), thử decode base64 -> utf8.
/// - Nếu vẫn không đọc được, trả nguyên văn (để còn debug).
String pickWoWonderText(Map<String, dynamic> m) {
  // 1) Ưu tiên những field server đã giải mã
  for (final k in const [
    'textDecoded',
    'text_decoded',
    'message',
    'message_text',
    'original_text',
  ]) {
    final v = m[k];
    if (v != null && v.toString().trim().isNotEmpty) {
      return v.toString();
    }
  }

  // 2) Thử từ 'text' (thường là base64-cipher hoặc base64-utf8)
  final raw = (m['text'] ?? '').toString();
  if (raw.isEmpty) return '';

  // Thử base64 -> utf8
  final maybe = _tryBase64Utf8(raw);
  return maybe ?? raw;
}

String? _tryBase64Utf8(String s) {
  final t = s.trim();
  final base64Regex = RegExp(r'^[A-Za-z0-9+/=]+$');
  if (!base64Regex.hasMatch(t) || t.length % 4 != 0) return null;
  try {
    final bytes = base64.decode(t);
    final txt = utf8.decode(bytes, allowMalformed: true);
    // rỗng / không in được -> coi như fail
    final printable = RegExp(r'[\x20-\x7E\u0080-\uFFFF]');
    if (!printable.hasMatch(txt)) return null;
    return txt;
  } catch (_) {
    return null;
  }
}
