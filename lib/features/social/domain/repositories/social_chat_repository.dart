import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/wowonder_text.dart';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class SocialChatRepository {
  // ==== GET user messages ====
  Future<List<Map<String, dynamic>>> getUserMessages({
    required String token,
    required String peerUserId,
    int limit = 25,
    String? beforeMessageId,
    String? afterMessageId,
  }) async {
    final url = Uri.parse(
      '${AppConstants.socialBaseUrl}${AppConstants.socialChatGetUserMessagesUri}?access_token=$token',
    );

    final body = <String, String>{
      'server_key': AppConstants.socialServerKey,
      'recipient_id': peerUserId,
      'limit': '$limit',
    };
    if (_notEmpty(beforeMessageId))
      body['before_message_id'] = beforeMessageId!;
    if (_notEmpty(afterMessageId)) body['after_message_id'] = afterMessageId!;

    final res = await http.post(url, body: body);
    if (kDebugMode)
      debugPrint('get_user_messages -> ${res.statusCode} ${res.body}');
    if (res.statusCode != 200) return [];

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    if ((map['api_status'] ?? map['status']) != 200) return [];

    final list = (map['messages'] ?? map['data'] ?? []) as List;
    final out = <Map<String, dynamic>>[];
    for (final e in list) {
      final m = Map<String, dynamic>.from(e as Map);
      m['display_text'] = pickWoWonderText(m);
      if (m['reply'] is Map) {
        final r = Map<String, dynamic>.from(m['reply']);
        r['display_text'] = pickWoWonderText(r);
        m['reply'] = r;
      }
      out.add(m);
    }
    return out;
  }

  // ==== Mark as read ====
  Future<void> readChats({
    required String token,
    required String peerUserId,
  }) async {
    final url = Uri.parse(
      '${AppConstants.socialBaseUrl}${AppConstants.socialChatReadChatsUri}?access_token=$token',
    );
    final res = await http.post(url, body: {
      'server_key': AppConstants.socialServerKey,
      'recipient_id': peerUserId,
    });
    if (kDebugMode) debugPrint('read_chats -> ${res.statusCode} ${res.body}');
  }

  // ==== SEND (text / gif / file) ====
    Future<Map<String, dynamic>?> sendMessage({
    required String token,
    required String peerUserId,
    String? text,
    String? gifUrl,
    String? filePath,
  }) async {
    // MUST be '/api/send-message'
    final base =
        '${AppConstants.socialBaseUrl}${AppConstants.socialChatSendMessageUri}?access_token=$token';

    // 1) File -> multipart/form-data
    if (_notEmpty(filePath)) {
      final url = Uri.parse(base);
      final req = http.MultipartRequest('POST', url)
        ..fields['server_key'] = AppConstants.socialServerKey
        ..fields['user_id'] = peerUserId
        ..fields['message_hash_id'] =
            DateTime.now().microsecondsSinceEpoch.toString()
        ..files.add(await http.MultipartFile.fromPath('file', filePath!,
            filename: p.basename(filePath!)));
      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      if (kDebugMode) {
        debugPrint('send-message[multipart] -> ${res.statusCode} ${res.body}');
      }
      if (res.statusCode != 200) return null;

      final parsed = _parseSendResponse(res.body);

      // HIỂN THỊ NGAY: nếu là file thì dùng tên file làm display_text
      if (parsed != null) {
        parsed['display_text'] = p.basename(filePath);
      }
      return parsed;
    }

    // 2) Text/GIF -> x-www-form-urlencoded
    final url = Uri.parse(base);
    final fields = <String, String>{
      'server_key': AppConstants.socialServerKey,
      'user_id': peerUserId,
      'message_hash_id': DateTime.now().microsecondsSinceEpoch.toString(),
      if (_notEmpty(text)) 'text': text!,
      if (_notEmpty(gifUrl)) 'gif': gifUrl!,
    };
    final res = await http.post(url, body: fields);
    if (kDebugMode) {
      debugPrint('send-message[form] -> ${res.statusCode} ${res.body}');
    }
    if (res.statusCode != 200) return null;

    final parsed = _parseSendResponse(res.body);

    // HIỂN THỊ NGAY: override display_text bằng nội dung vừa gửi
    if (parsed != null) {
      if (_notEmpty(text)) {
        parsed['display_text'] = text!;
      } else if (_notEmpty(gifUrl)) {
        parsed['display_text'] = '[GIF]';
      }
    }
    return parsed;
  }

  // ---- helpers ----
  Map<String, dynamic>? _parseSendResponse(String body) {
    final map = jsonDecode(body) as Map<String, dynamic>;
    if ((map['api_status'] ?? map['status']) != 200) return null;

    dynamic md = map['message_data'] ?? map['data'] ?? map['message'];
    if (md is List && md.isNotEmpty) md = md.first;
    if (md is! Map) return null;

    final m = Map<String, dynamic>.from(md as Map);
    m['display_text'] = pickWoWonderText(m);
    if (m['reply'] is Map) {
      final r = Map<String, dynamic>.from(m['reply']);
      r['display_text'] = pickWoWonderText(r);
      m['reply'] = r;
    }
    return m;
  }

  bool _notEmpty(String? s) => s != null && s.trim().isNotEmpty;
}
