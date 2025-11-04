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

  // -------------------- Token & Endpoint --------------------
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

  // -------------------- Content Type --------------------
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
        return MediaType('audio', 'mp4');
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

  // -------------------- Decrypt helpers --------------------
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
    for (int i = 0; i < n; i++) out[i] = src[i];
    return out;
  }

  String _stripTrailingZeros(String s) {
    final bytes = utf8.encode(s);
    int end = bytes.length;
    while (end > 0 && bytes[end - 1] == 0) end--;
    return utf8.decode(bytes.sublist(0, end), allowMalformed: true);
  }

  String _decryptIfNeeded(String raw, dynamic timeVal) {
    if (raw.isEmpty) return '';
    final b64 = _cleanB64(raw);
    if (!_maybeBase64.hasMatch(b64) || b64.length % 4 != 0) return raw;
    final keyStr = '${timeVal ?? ''}';
    if (keyStr.isEmpty) return raw;

    final key = enc.Key(_keyBytes16(keyStr));
    final encrypted = enc.Encrypted.fromBase64(b64);

    try {
      final e =
          enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb, padding: 'PKCS7'));
      return e.decrypt(encrypted, iv: enc.IV.fromLength(0));
    } catch (_) {}
    try {
      final e = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb));
      final out = e.decrypt(encrypted, iv: enc.IV.fromLength(0));
      if (out.isNotEmpty) return out;
    } catch (_) {}
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
    if (!(_isOk(json))) {
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

    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw Exception('Tạo nhóm thất bại (HTTP ${streamed.statusCode}): $body');
    }
    final json = jsonDecode(body);
    if (!(_isOk(json))) {
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
    if (!(_isOk(json))) {
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
    if (!(_isOk(json))) {
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
    if (!(_isOk(json))) {
      throw Exception(
          'Không lấy được tin nhắn mới: ${json['errors'] ?? res.body}');
    }
    final msgs = ((json['data'] ?? {})['messages'] ?? []) as List;
    return msgs
        .cast<Map>()
        .map((e) => _normalizeMsg(Map<String, dynamic>.from(e)))
        .toList();
  }

  // -------------------- Send --------------------
  Future<Map<String, dynamic>?> sendMessage({
    required String groupId,
    required String text,
    File? file,
    String? type,
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
      if (!(_isOk(json))) {
        throw Exception('Gửi text thất bại: ${json['errors'] ?? res.body}');
      }
      final m = _extractMessageMap(json);
      return m == null ? null : _normalizeMsg(m);
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
      'file',
      file.path,
      contentType: ct,
      filename: p.basename(file.path),
    ));

    final streamed = await req.send().timeout(const Duration(seconds: 120));
    final bodyStr = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception(
          'Gửi file thất bại (HTTP ${streamed.statusCode}): $bodyStr');
    }
    final json = jsonDecode(bodyStr);
    if (!(_isOk(json))) {
      throw Exception('Gửi file thất bại: ${json['errors'] ?? bodyStr}');
    }
    final m = _extractMessageMap(json);
    return m == null ? null : _normalizeMsg(m);
  }

  // -------------------- Edit Group --------------------
  Future<Map<String, dynamic>> editGroup({
    required String groupId,
    String? name,
    File? avatarFile,
  }) async {
    final token = await _getAccessTokenOrThrow();
    final uri = Uri.parse('${_groupChatEndpoint()}?access_token=$token');

    if ((name == null || name.trim().isEmpty) && avatarFile == null) {
      return {'group_id': groupId, 'group_name': name ?? ''};
    }

    final req = http.MultipartRequest('POST', uri);
    req.fields['server_key'] = AppConstants.socialServerKey;
    req.fields['type'] = 'edit';
    req.fields['id'] = groupId;
    if (name != null && name.trim().isNotEmpty) {
      req.fields['group_name'] = name.trim();
    }
    if (avatarFile != null) {
      final ct = _contentTypeFor(avatarFile.path);
      req.files.add(await http.MultipartFile.fromPath(
        'avatar',
        avatarFile.path,
        filename: p.basename(avatarFile.path),
        contentType: ct,
      ));
    }

    final streamed = await req.send().timeout(const Duration(seconds: 40));
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception(
          'Edit group thất bại (HTTP ${streamed.statusCode}): $body');
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Edit group: phản hồi không phải JSON: $body');
    }

    if (json['api_status'] != 200) {
      throw Exception('Edit group thất bại: ${json['errors'] ?? body}');
    }

    final objRaw = (json['data'] ?? json['group'] ?? json['message'] ?? json);
    final obj = (objRaw is Map)
        ? Map<String, dynamic>.from(objRaw)
        : <String, dynamic>{};

    return {
      'group_id': obj['group_id']?.toString() ?? groupId,
      'group_name': (obj['group_name'] ?? obj['name'] ?? name ?? '').toString(),
      'avatar':
          (obj['avatar_full'] ?? obj['avatar'] ?? obj['group_avatar'] ?? '')
              .toString(),
    };
  }

  // -------------------- Members --------------------
  Future<List<Map<String, dynamic>>> fetchGroupMembers(String groupId) async {
    final token = await _getAccessTokenOrThrow();
    final url = '${AppConstants.socialBaseUrl}/api/group_chat';
    final res = await http.post(Uri.parse('$url?access_token=$token'), body: {
      'server_key': AppConstants.socialServerKey,
      'type': 'get_members',
      'id': groupId,
    });

    final data = jsonDecode(res.body);
    if (!_isOk(data)) throw Exception('Failed to fetch members');

    final members = (data['data']?['members'] ?? []) as List;
    return members.map((e) => Map<String, dynamic>.from(e)).toList();
  }



  Future<bool> removeGroupUsers(String groupId, List<String> userIds) async {
    final token = await _getAccessTokenOrThrow();
    final url = '${AppConstants.socialBaseUrl}/api/group_chat';
    final parts = userIds.join(',');
    final res = await http.post(Uri.parse('$url?access_token=$token'), body: {
      'server_key': AppConstants.socialServerKey,
      'type': 'remove_user',
      'id': groupId,
      'parts': parts,
    });

    final data = jsonDecode(res.body);
    return _isOk(data);
  }

  Future<bool> addUsersToGroup(String groupId, List<String> userIds) async {
    if (userIds.isEmpty) return true;
    final token = await _getAccessTokenOrThrow();
    final uri = Uri.parse('${_groupChatEndpoint()}?access_token=$token');

    final res = await http.post(uri, body: {
      'server_key': AppConstants.socialServerKey,
      'type': 'add_user',
      'id': groupId,
      'parts': userIds.join(','),
    }).timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      throw Exception('Thêm thành viên thất bại (HTTP ${res.statusCode})');
    }
    final json = jsonDecode(res.body);
    if (!(_isOk(json))) {
      throw Exception(
          'Thêm thành viên thất bại: ${json['errors'] ?? res.body}');
    }
    return true;
  }

  // -------------------- Helpers --------------------
  bool _isOk(Map json) {
    final s = json['api_status'] ?? json['status'] ?? json['code'];
    return '$s' == '200';
  }

  Map<String, dynamic>? _extractMessageMap(Map json) {
    dynamic data = json['data'];
    if (data is Map && data['message'] is Map) data = data['message'];
    data ??= json['message'] ?? json['msg'] ?? json['messages'];

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  List<dynamic> _extractList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map && data.containsKey('data')) {
      final d = data['data'];
      if (d is List) return d;
    }
    return [];
  }
}
