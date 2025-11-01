// G:\flutter-app\lib\features\social\domain\repositories\group_chat_repository.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class GroupChatRepository {
  GroupChatRepository();

  // -------------------- auth + endpoint --------------------
  Future<String> _getAccessTokenOrThrow() async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString(AppConstants.socialAccessToken);
    if (token == null || token.isEmpty) {
      throw Exception('Chưa đăng nhập mạng xã hội');
    }
    return token;
  }

  String _groupChatEndpoint() {
    final base = AppConstants.socialBaseUrl.endsWith('/')
        ? AppConstants.socialBaseUrl
            .substring(0, AppConstants.socialBaseUrl.length - 1)
        : AppConstants.socialBaseUrl;
    return '$base/api/group_chat';
  }

  // -------------------- mime helper --------------------
  MediaType? _contentTypeFor(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return MediaType('image', 'jpeg');
      case '.png':
        return MediaType('image', 'png');
      case '.gif':
        return MediaType('image', 'gif');
      case '.webp':
        return MediaType('image', 'webp');
      case '.mp4':
        return MediaType('video', 'mp4');
      case '.mov':
        return MediaType('video', 'quicktime');
      case '.mkv':
        return MediaType('video', 'x-matroska');
      case '.m4a':
        return MediaType('audio', 'mp4'); // AAC in MP4 (m4a)
      case '.aac':
        return MediaType('audio', 'aac');
      case '.mp3':
        return MediaType('audio', 'mpeg');
      case '.wav':
        return MediaType('audio', 'wav');
      case '.pdf':
        return MediaType('application', 'pdf');
      default:
        return null;
    }
  }

  // -------------------- WoWonder text decrypt --------------------
  static final RegExp _maybeBase64 = RegExp(r'^[A-Za-z0-9+/=]+$');

  String _cleanB64(String s) => s
      .replaceAll('-', '+')
      .replaceAll('_', '/')
      .replaceAll(' ', '+')
      .replaceAll('\n', '');

  Uint8List _keyBytes16(String keyStr) {
    final src = utf8.encode(keyStr);
    final out = Uint8List(16);
    final n = src.length > 16 ? 16 : src.length;
    for (int i = 0; i < n; i++) {
      out[i] = src[i];
    }
    return out; // phần còn lại là 0 (zero-pad)
  }

  String _stripTrailingZeros(String s) {
    final bytes = utf8.encode(s);
    int end = bytes.length;
    while (end > 0 && bytes[end - 1] == 0) end--;
    return utf8.decode(bytes.sublist(0, end), allowMalformed: true);
  }

  /// Giải mã theo PHP: openssl_encrypt($text, "AES-128-ECB", $time)
  String _decryptIfNeeded(String raw, dynamic timeVal) {
    if (raw.isEmpty) return '';
    final b64 = _cleanB64(raw);
    if (!_maybeBase64.hasMatch(b64) || b64.length % 4 != 0) {
      return raw; // không phải base64
    }
    final keyStr = '${timeVal ?? ''}';
    if (keyStr.isEmpty) return raw;

    final key = enc.Key(_keyBytes16(keyStr));
    final encrypted = enc.Encrypted.fromBase64(b64);

    // 1) PKCS7 (OpenSSL mặc định)
    try {
      final e =
          enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb, padding: 'PKCS7'));
      return e.decrypt(encrypted, iv: enc.IV.fromLength(0));
    } catch (_) {}

    // 2) No padding
    try {
      final e = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb));
      final out = e.decrypt(encrypted, iv: enc.IV.fromLength(0));
      if (out.isNotEmpty) return out;
    } catch (_) {}

    // 3) Zero padding (fallback)
    try {
      final e = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb));
      final out = e.decrypt(encrypted, iv: enc.IV.fromLength(0));
      return _stripTrailingZeros(out);
    } catch (_) {}

    return raw;
  }

  Map<String, dynamic> _normalizeMsg(Map<String, dynamic> m) {
    final media = (m['media'] ?? '').toString();
    final lower = media.toLowerCase();

    final isVoice = (m['type_two']?.toString() == 'voice');
    final isImg = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
    final isVid = lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv');
    final isAud = isVoice ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.mp3') ||
        lower.endsWith('.wav');

    m['is_image'] = isImg;
    m['is_video'] = isVid;
    m['is_audio'] = isAud;
    m['is_file'] = media.isNotEmpty && !isImg && !isVid && !isAud;

    final rawText = (m['text'] ?? '').toString();
    final timeVal = m['time'];
    m['display_text'] = _decryptIfNeeded(rawText, timeVal);

    return m;
  }

  // -------------------- Groups --------------------
  Future<List<Map<String, dynamic>>> fetchGroups() async {
    final token = await _getAccessTokenOrThrow();
    final uri = Uri.parse('${_groupChatEndpoint()}?access_token=$token');

    final res = await http.post(uri, body: {
      'server_key': AppConstants.socialServerKey,
      'type': 'get_list',
    }).timeout(const Duration(seconds: 25));

    if (res.statusCode != 200) {
      throw Exception('Không lấy được danh sách nhóm (HTTP ${res.statusCode})');
    }
    final json = jsonDecode(res.body);
    if (json['api_status'] != 200) {
      throw Exception(
          'Không lấy được danh sách nhóm: ${json['errors'] ?? res.body}');
    }
    final data = (json['data'] ?? []) as List;
    return data.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<bool> createGroup({
    required String name,
    required List<String> memberIds,
    File? avatarFile,
  }) async {
    final token = await _getAccessTokenOrThrow();
    final uri = Uri.parse('${_groupChatEndpoint()}?access_token=$token');

    final req = http.MultipartRequest('POST', uri);
    req.fields['server_key'] = AppConstants.socialServerKey;
    req.fields['type'] = 'create';
    req.fields['group_name'] = name;
    req.fields['parts'] = memberIds.join(',');

    if (avatarFile != null) {
      final ct = _contentTypeFor(avatarFile.path);
      req.files.add(await http.MultipartFile.fromPath(
        'avatar',
        avatarFile.path,
        contentType: ct,
        filename: p.basename(avatarFile.path),
      ));
    }

    final streamed = await req.send().timeout(const Duration(seconds: 40));
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw Exception('Tạo nhóm thất bại (HTTP ${streamed.statusCode}): $body');
    }
    final json = jsonDecode(body);
    if (json['api_status'] != 200) {
      throw Exception('Tạo nhóm thất bại: ${json['errors'] ?? body}');
    }
    return true;
  }

  // -------------------- Messages (fetch) --------------------
  Future<List<Map<String, dynamic>>> fetchMessages(
    String groupId, {
    int limit = 200,
  }) async {
    final token = await _getAccessTokenOrThrow();
    final uri = Uri.parse('${_groupChatEndpoint()}?access_token=$token');

    final res = await http.post(uri, body: {
      'server_key': AppConstants.socialServerKey,
      'type': 'fetch_messages',
      'id': groupId,
      'limit': '$limit',
    }).timeout(const Duration(seconds: 25));

    if (res.statusCode != 200) {
      throw Exception('Không lấy được tin nhắn (HTTP ${res.statusCode})');
    }
    final json = jsonDecode(res.body);
    if (json['api_status'] != 200) {
      throw Exception('Không lấy được tin nhắn: ${json['errors'] ?? res.body}');
    }

    final msgs = ((json['data'] ?? {})['messages'] ?? []) as List;
    return msgs
        .cast<Map>()
        .map((e) => _normalizeMsg(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchOlderMessages(
    String groupId, {
    required String beforeMessageId,
    int limit = 200,
  }) async {
    final token = await _getAccessTokenOrThrow();
    final uri = Uri.parse('${_groupChatEndpoint()}?access_token=$token');

    final res = await http.post(uri, body: {
      'server_key': AppConstants.socialServerKey,
      'type': 'fetch_messages',
      'id': groupId,
      'limit': '$limit',
      'before_message_id': beforeMessageId,
    }).timeout(const Duration(seconds: 25));

    if (res.statusCode != 200) {
      throw Exception('Không lấy được tin nhắn cũ (HTTP ${res.statusCode})');
    }
    final json = jsonDecode(res.body);
    if (json['api_status'] != 200) {
      throw Exception(
          'Không lấy được tin nhắn cũ: ${json['errors'] ?? res.body}');
    }
    final msgs = ((json['data'] ?? {})['messages'] ?? []) as List;
    return msgs
        .cast<Map>()
        .map((e) => _normalizeMsg(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchNewerMessages(
    String groupId, {
    required String afterMessageId,
    int limit = 200,
  }) async {
    final token = await _getAccessTokenOrThrow();
    final uri = Uri.parse('${_groupChatEndpoint()}?access_token=$token');

    final res = await http.post(uri, body: {
      'server_key': AppConstants.socialServerKey,
      'type': 'fetch_messages',
      'id': groupId,
      'limit': '$limit',
      'after_message_id': afterMessageId,
    }).timeout(const Duration(seconds: 25));

    if (res.statusCode != 200) {
      throw Exception('Không lấy được tin nhắn mới (HTTP ${res.statusCode})');
    }
    final json = jsonDecode(res.body);
    if (json['api_status'] != 200) {
      throw Exception(
          'Không lấy được tin nhắn mới: ${json['errors'] ?? res.body}');
    }
    final msgs = ((json['data'] ?? {})['messages'] ?? []) as List;
    return msgs
        .cast<Map>()
        .map((e) => _normalizeMsg(Map<String, dynamic>.from(e)))
        .toList();
  }

  // -------------------- Send (text/file) --------------------
  Future<Map<String, dynamic>?> sendMessage({
    required String groupId,
    required String text,
    File? file,
    String? type, // UI only
    String? messageHashId,
  }) async {
    final token = await _getAccessTokenOrThrow();
    final uri = Uri.parse('${_groupChatEndpoint()}?access_token=$token');

    if (file == null) {
      final body = {
        'server_key': AppConstants.socialServerKey,
        'type': 'send',
        'id': groupId,
        'text': text.isEmpty ? ' ' : text,
      };
      if (messageHashId != null && messageHashId.isNotEmpty) {
        body['message_hash_id'] = messageHashId;
      }

      final res =
          await http.post(uri, body: body).timeout(const Duration(seconds: 25));

      if (res.statusCode != 200) {
        throw Exception('Gửi text thất bại (HTTP ${res.statusCode})');
      }
      final json = jsonDecode(res.body);
      if (json['api_status'] != 200) {
        throw Exception('Gửi text thất bại: ${json['errors'] ?? res.body}');
      }
      final data = json['data'] ?? json['message'] ?? json['msg'];
      if (data is Map) {
        final m = Map<String, dynamic>.from(data);
        return _normalizeMsg(m);
      }
      return null;
    }

    // multipart
    final req = http.MultipartRequest('POST', uri);
    req.fields['server_key'] = AppConstants.socialServerKey;
    req.fields['type'] = 'send';
    req.fields['id'] = groupId;
    req.fields['text'] = text.isEmpty ? ' ' : text;
    if (messageHashId != null && messageHashId.isNotEmpty) {
      req.fields['message_hash_id'] = messageHashId;
    }

    final ct = _contentTypeFor(file.path);
    req.files.add(await http.MultipartFile.fromPath(
      'file', // endpoint yêu cầu tên field 'file' cho mọi loại
      file.path,
      contentType: ct,
      filename: p.basename(file.path),
    ));

    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final bodyStr = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception(
          'Gửi file thất bại (HTTP ${streamed.statusCode}): $bodyStr');
    }
    final json = jsonDecode(bodyStr);
    if (json['api_status'] != 200) {
      throw Exception('Gửi file thất bại: ${json['errors'] ?? bodyStr}');
    }
    final data = json['data'] ?? json['message'] ?? json['msg'];
    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      return _normalizeMsg(m);
    }
    return null;
  }
}
