// 📁 lib/features/social/domain/repositories/group_chat_repository.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class GroupChatRepository {
  static const _endpoint = '/api/group_chat';

  /// Gọi API helper
  Future<http.Response> _post(String accessToken, Map<String, dynamic> body,
      {File? file}) async {
    final uri = Uri.parse('${AppConstants.socialBaseUrl}$_endpoint');
    var request = http.MultipartRequest('POST', uri);

    request.fields['server_key'] = AppConstants.socialServerKey;
    body.forEach((key, value) {
      if (value != null) request.fields[key] = value.toString();
    });
    request.fields['access_token'] = accessToken;

    if (file != null) {
      final stream = http.ByteStream(file.openRead());
      final length = await file.length();
      final multipart =
          http.MultipartFile('avatar', stream, length, filename: file.path);
      request.files.add(multipart);
    }

    final response = await request.send();
    return http.Response.fromStream(response);
  }

  // ======================
  // 🟢 Lấy danh sách nhóm
  // ======================
  Future<List<Map<String, dynamic>>> fetchGroups(
      {required String accessToken}) async {
    try {
      final response = await _post(accessToken, {'type': 'get_list'});
      final data = jsonDecode(response.body);

      if (data['api_status'] != 200) {
        throw Exception('fetchGroups failed: ${data['api_status']}');
      }

      final List list = (data['data'] ?? []) as List;
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      rethrow;
    }
  }

  // ======================
  // 🟢 Lấy tin nhắn nhóm
  // ======================
  Future<List<Map<String, dynamic>>> fetchMessages({
    required String accessToken,
    required String groupId,
  }) async {
    try {
      final response = await _post(accessToken, {
        'type': 'get_messages',
        'id': groupId,
      });

      final data = jsonDecode(response.body);

      if (data['api_status'] != 200) {
        throw Exception('fetchMessages failed: ${data['api_status']}');
      }

      final messages = (data['data']['messages'] ?? []) as List;
      return List<Map<String, dynamic>>.from(messages);
    } catch (e) {
      rethrow;
    }
  }

  // ======================
  // 🟢 Gửi tin nhắn nhóm
  // ======================
  Future<bool> sendMessage({
    required String accessToken,
    required String groupId,
    required String text,
  }) async {
    try {
      final response = await _post(accessToken, {
        'type': 'send_message',
        'id': groupId,
        'text': text,
      });

      final data = jsonDecode(response.body);
      return data['api_status'] == 200;
    } catch (e) {
      return false;
    }
  }

  // ======================
  // 🟢 Tạo nhóm mới
  // ======================
  Future<bool> createGroup({
    required String accessToken,
    required String groupName,
    required List<String> memberIds,
    File? avatar,
  }) async {
    try {
      final response = await _post(
        accessToken,
        {
          'type': 'create',
          'group_name': groupName,
          'users': memberIds.join(','),
        },
        file: avatar,
      );

      final data = jsonDecode(response.body);
      return data['api_status'] == 200;
    } catch (e) {
      return false;
    }
  }
}
