import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/block/aes_fast.dart';
import 'package:pointycastle/block/modes/ecb.dart';
import 'package:pointycastle/api.dart';

/// 🧠 Tiện ích giải mã tin nhắn nhóm WoWonder
/// WoWonder mã hoá tin nhắn bằng: AES-128-ECB với key = message['time']
/// Vì vậy hàm này dùng để giải mã về text gốc hiển thị trong Flutter.
class MessageDecryptor {
  /// 🔐 Giải mã AES-128-ECB từ WoWonder
  static String decryptAES128ECB(String base64Text, String key) {
    try {
      // ⚙️ Key chính là timestamp (ví dụ "1761727143")
      final keyBytes = utf8.encode(key);
      final input = base64.decode(base64Text);

      // Tạo cipher AES-128-ECB
      final cipher = ECBBlockCipher(AESFastEngine())
        ..init(
          false, // false = decrypt
          KeyParameter(
              Uint8List.fromList(_normalizeKey(keyBytes, 16))), // key 16 bytes
        );

      // Giải mã từng block
      final output = _processBlocks(cipher, input);

      // Trả kết quả UTF-8, bỏ padding thừa
      return utf8
          .decode(output, allowMalformed: true)
          .replaceAll(
              RegExp(r'[\x00-\x1F\x7F-\x9F]+'), '') // 🔥 xoá sạch ký tự control
          .trim();

    } catch (e) {
      // Nếu lỗi (ví dụ text không phải base64), trả nguyên text
      return base64Text;
    }
  }

  /// 🧩 Giải mã theo block 16 byte
  static List<int> _processBlocks(BlockCipher cipher, List<int> input) {
    final output = <int>[];
    for (var offset = 0; offset < input.length;) {
      final chunk = input.skip(offset).take(cipher.blockSize).toList();

      // Padding nếu thiếu bytes
      while (chunk.length < cipher.blockSize) {
        chunk.add(0);
      }

      // ⚡️ PointyCastle yêu cầu Uint8List
      output.addAll(cipher.process(Uint8List.fromList(chunk)));
      offset += cipher.blockSize;
    }
    return output;
  }

  /// 🧱 Đảm bảo key đủ 16 bytes cho AES-128
  static List<int> _normalizeKey(List<int> key, int size) {
    if (key.length == size) return key;
    if (key.length > size) return key.sublist(0, size);
    return [...key, ...List.filled(size - key.length, 0)];
  }
}
