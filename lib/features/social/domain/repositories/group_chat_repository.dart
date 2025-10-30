import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/constants/wowonder_api.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/message_decryptor.dart';

class GroupChatRepository {
  final String _base = AppConstants.socialBaseUrl;
  final String _serverKey = AppConstants.socialServerKey;

  /// 🧩 Lấy access token hiện tại của user
  Future<String> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.socialAccessToken);
    if (token == null || token.isEmpty) {
      throw Exception('❌ Chưa đăng nhập mạng xã hội');
    }
    return token;
  }

  /// 🧱 Lấy danh sách nhóm chat
  Future<List<Map<String, dynamic>>> fetchGroups() async {
    final accessToken = await _getAccessToken();

    final uri =
        Uri.parse('$_base${WowonderAPI.groupChat}?access_token=$accessToken');
    final res = await http.post(uri, body: {
      'server_key': _serverKey,
      'type': 'get_list',
    });

    if (res.statusCode != 200) {
      throw Exception('Lỗi mạng (${res.statusCode})');
    }

    final data = json.decode(res.body);
    if (data['api_status'] == 200 && data['data'] is List) {
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception(
          data['errors']?['error_text'] ?? 'Không thể lấy danh sách nhóm');
    }
  }

  /// 🧩 Tạo nhóm chat mới
  Future<bool> createGroup({
    required String name,
    required List<String> memberIds,
    File? avatarFile,
  }) async {
    final accessToken = await _getAccessToken();

    final uri =
        Uri.parse('$_base${WowonderAPI.groupChat}?access_token=$accessToken');
    final req = http.MultipartRequest('POST', uri)
      ..fields['server_key'] = _serverKey
      ..fields['type'] = 'create'
      ..fields['group_name'] = name
      ..fields['parts'] = memberIds.join(',');

    if (avatarFile != null) {
      final fileName = avatarFile.path.split('/').last;
      req.files.add(await http.MultipartFile.fromPath('avatar', avatarFile.path,
          filename: fileName));
    }

    final res = await req.send();
    final body = await res.stream.bytesToString();
    final data = json.decode(body);

    if (res.statusCode == 200 && data['api_status'] == 200) {
      return true;
    } else {
      throw Exception(data['errors']?['error_text'] ?? 'Tạo nhóm thất bại');
    }
  }

  /// 💬 Lấy tin nhắn trong nhóm (tự động giải mã Base64/AES)
  Future<List<Map<String, dynamic>>> fetchMessages(String groupId) async {
    final accessToken = await _getAccessToken();

    final uri =
        Uri.parse('$_base${WowonderAPI.groupChat}?access_token=$accessToken');
    final res = await http.post(uri, body: {
      'server_key': _serverKey,
      'type': 'fetch_messages',
      'id': groupId,
    });

    if (res.statusCode != 200) throw Exception('Lỗi mạng (${res.statusCode})');

    final data = json.decode(res.body);
    if (data['api_status'] != 200) {
      throw Exception('API lỗi: ${data['api_status']}');
    }

    final msgs = (data['data']?['messages'] ?? []) as List;

    return msgs.map<Map<String, dynamic>>((m) {
      final msg = Map<String, dynamic>.from(m);
      final raw = msg['text'] ?? '';
      if (raw is! String || raw.isEmpty) return msg;

      try {
        final timeKey = msg['time']?.toString() ?? '';
        msg['text'] = MessageDecryptor.decryptAES128ECB(raw, timeKey);
      } catch (_) {
        try {
          msg['text'] = utf8.decode(base64.decode(raw));
        } catch (_) {
          msg['text'] = raw;
        }
      }
      return msg;
    }).toList();
  }

  /// 🚀 Gửi tin nhắn nhóm (text / image)
  Future<void> sendMessage({
    required String groupId,
    required String text,
    String? imageUrl,
  }) async {
    final accessToken = await _getAccessToken();

    final uri =
        Uri.parse('$_base${WowonderAPI.groupChat}?access_token=$accessToken');
    final body = {
      'server_key': _serverKey,
      'type': 'send',
      'id': groupId,
      'text': text,
      'message_type': 'code', // ⚠️ "code" để WoWonder hiểu là tin mã hóa
    };

    if (imageUrl != null && imageUrl.isNotEmpty) {
      body['image_url'] = imageUrl;
    }

    final res = await http.post(uri, body: body);
    if (res.statusCode != 200) throw Exception('Lỗi mạng (${res.statusCode})');

    final data = json.decode(res.body);
    if (data['api_status'] != 200) {
      throw Exception(data['errors']?['error_text'] ?? 'Gửi tin nhắn thất bại');
    }
  }
}
