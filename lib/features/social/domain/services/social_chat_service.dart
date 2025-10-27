import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class SocialChatService {
  static Uri _uri(String path, String token) =>
      Uri.parse('${AppConstants.socialBaseUrl}$path')
          .replace(queryParameters: {'access_token': token});

  static Map<String, String> _baseFields(String userId) => {
        'server_key': AppConstants.socialServerKey,
        'user_id': userId, // WoWonder expects `user_id` (NOT recipient_id)
      };

  /// Lấy tin nhắn 1-1
  static Future<List<Map<String, dynamic>>> getUserMessages({
    required String accessToken,
    required String peerUserId,
    String? beforeMessageId,
    int limit = 25,
  }) async {
    final req = http.MultipartRequest(
      'POST',
      _uri(AppConstants.socialChatGetUserMessagesUri, accessToken),
    );
    req.fields.addAll(_baseFields(peerUserId));
    req.fields['limit'] = '$limit';
    if (beforeMessageId != null && beforeMessageId.isNotEmpty) {
      req.fields['before_message_id'] = beforeMessageId;
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) return [];

    Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body);
    } catch (_) {
      return [];
    }
    if (!(json['api_status'] == 200 || json['status'] == 200)) return [];

    final root = (json['data'] ?? json) as Map<String, dynamic>;
    final List list = (root['messages'] ??
        root['message_data'] ??
        root['data'] ??
        []) as List;

    return list
        .where((e) => e is Map)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// Gửi tin nhắn text / gif / file
  /// - `text`, `gif`, `filePath` đều optional; truyền cái bạn có
  static Future<Map<String, dynamic>?> sendMessage({
    required String accessToken,
    required String peerUserId,
    String? text,
    String? gifUrl,
    String? filePath, // đường dẫn file local (ảnh/video/doc)
  }) async {
    final req = http.MultipartRequest(
      'POST',
      _uri(AppConstants.socialChatSendMessageUri, accessToken),
    );

    req.fields.addAll(_baseFields(peerUserId));

    // message_hash_id: chuỗi ngẫu nhiên (server yêu cầu)
    final rnd = Random();
    final hash = List.generate(12, (_) => rnd.nextInt(10)).join();
    req.fields['message_hash_id'] = hash;

    if (text != null && text.trim().isNotEmpty) {
      req.fields['text'] = text.trim();
    }
    if (gifUrl != null && gifUrl.trim().isNotEmpty) {
      req.fields['gif'] = gifUrl.trim();
    }
    if (filePath != null && filePath.trim().isNotEmpty) {
      final mime = lookupMimeType(filePath) ?? 'application/octet-stream';
      final parts = mime.split('/');
      req.files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: MediaType(parts.first, parts.last),
      ));
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) return null;

    Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body);
    } catch (_) {
      return null;
    }
    if (!(json['api_status'] == 200 || json['status'] == 200)) return null;

    // server thường trả: { message_data: [ {..message..} ] }
    final root = (json['data'] ?? json) as Map<String, dynamic>;
    final List list = (root['message_data'] ?? root['data'] ?? []) as List;
    if (list.isEmpty) return null;
    return Map<String, dynamic>.from(list.first as Map);
  }

  /// Đánh dấu đã đọc
  static Future<bool> readChats({
    required String accessToken,
    required String peerUserId,
  }) async {
    final req = http.MultipartRequest(
      'POST',
      _uri(AppConstants.socialChatReadChatsUri, accessToken),
    );
    req.fields.addAll(_baseFields(peerUserId));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) return false;

    try {
      final json = jsonDecode(res.body);
      return (json['api_status'] == 200 || json['status'] == 200);
    } catch (_) {
      return false;
    }
  }
}
