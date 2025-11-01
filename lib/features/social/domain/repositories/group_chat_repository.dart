// G:\flutter-app\lib\features\social\domain\repositories\group_chat_repository.dart

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class GroupChatRepository {
  GroupChatRepository();

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

  String _fieldNameFor(String? type) {
    switch (type) {
      case 'image':
        return 'image';
      case 'video':
        return 'video';
      case 'voice':
        return 'audio';
      default:
        return 'file';
    }
  }

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

  // -------------------- Groups --------------------

  Future<List<Map<String, dynamic>>> fetchGroups() async {
    final token = await _getAccessTokenOrThrow();
    final uri = Uri.parse('${_groupChatEndpoint()}?access_token=$token');

    final res = await http.post(
      uri,
      body: {
        'server_key': AppConstants.socialServerKey,
        'type': 'get_list',
      },
    ).timeout(const Duration(seconds: 25));

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

  // -------------------- Messages --------------------

  Future<List<Map<String, dynamic>>> fetchMessages(
    String groupId, {
    int limit = 200,
  }) async {
    final token = await _getAccessTokenOrThrow();
    final uri = Uri.parse('${_groupChatEndpoint()}?access_token=$token');

    final res = await http.post(
      uri,
      body: {
        'server_key': AppConstants.socialServerKey,
        'type': 'get_messages',
        'id': groupId,
        'limit': '$limit',
      },
    ).timeout(const Duration(seconds: 25));

    if (res.statusCode != 200) {
      throw Exception('Không lấy được tin nhắn (HTTP ${res.statusCode})');
    }
    final json = jsonDecode(res.body);
    if (json['api_status'] != 200) {
      throw Exception('Không lấy được tin nhắn: ${json['errors'] ?? res.body}');
    }
    final msgs = ((json['data'] ?? {})['messages'] ?? []) as List;
    return msgs.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchOlderMessages(
    String groupId, {
    required String beforeMessageId,
    int limit = 200,
  }) async {
    final token = await _getAccessTokenOrThrow();
    final uri = Uri.parse('${_groupChatEndpoint()}?access_token=$token');

    final body = {
      'server_key': AppConstants.socialServerKey,
      'type': 'get_messages',
      'id': groupId,
      'limit': '$limit',
      'before_id': beforeMessageId,
      'last_id': beforeMessageId,
      'old': '1',
    };

    final res =
        await http.post(uri, body: body).timeout(const Duration(seconds: 25));
    if (res.statusCode != 200) {
      throw Exception('Không lấy được tin nhắn cũ (HTTP ${res.statusCode})');
    }
    final json = jsonDecode(res.body);
    if (json['api_status'] != 200) {
      throw Exception(
          'Không lấy được tin nhắn cũ: ${json['errors'] ?? res.body}');
    }
    final msgs = ((json['data'] ?? {})['messages'] ?? []) as List;
    return msgs.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Trả về **message server** (nếu backend trả), để thay thế placeholder ngay lập tức.
  Future<Map<String, dynamic>?> sendMessage({
    required String groupId,
    required String text,
    File? file,
    String? type, // 'image' | 'video' | 'voice' | 'file' | null
  }) async {
    final token = await _getAccessTokenOrThrow();
    final uri = Uri.parse('${_groupChatEndpoint()}?access_token=$token');

    if (file == null) {
      final res = await http.post(
        uri,
        body: {
          'server_key': AppConstants.socialServerKey,
          'type': 'send',
          'id': groupId,
          'text': text.isEmpty ? ' ' : text,
          'message_type': 'code',
        },
      ).timeout(const Duration(seconds: 25));

      if (res.statusCode != 200) {
        throw Exception('Gửi text thất bại (HTTP ${res.statusCode})');
      }
      final json = jsonDecode(res.body);
      if (json['api_status'] != 200) {
        throw Exception('Gửi text thất bại: ${json['errors'] ?? res.body}');
      }
      final data = json['data'] ?? json['message'] ?? json['msg'];
      return (data is Map) ? Map<String, dynamic>.from(data) : null;
    }

    final req = http.MultipartRequest('POST', uri);
    req.fields['server_key'] = AppConstants.socialServerKey;
    req.fields['type'] = 'send';
    req.fields['id'] = groupId;
    req.fields['text'] = text.isEmpty ? ' ' : text;
    req.fields['message_type'] = 'code';

    final field = _fieldNameFor(type);
    final ct = _contentTypeFor(file.path);
    req.files.add(await http.MultipartFile.fromPath(
      field,
      file.path,
      contentType: ct,
      filename: p.basename(file.path),
    ));

    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw Exception(
          'Gửi $field thất bại (HTTP ${streamed.statusCode}): $body');
    }
    final json = jsonDecode(body);
    if (json['api_status'] != 200) {
      throw Exception('Gửi $field thất bại: ${json['errors'] ?? body}');
    }
    final data = json['data'] ?? json['message'] ?? json['msg'];
    return (data is Map) ? Map<String, dynamic>.from(data) : null;
  }
}
