// lib/features/social/domain/repositories/social_chat_repository.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';


import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/wowonder_text.dart';

class SocialChatRepository {
  // ================= Helpers =================
  bool _notEmpty(String? s) => s != null && s.trim().isNotEmpty;

  Never _throwApi(String body, {int? httpCode}) {
    try {
      final m = jsonDecode(body) as Map<String, dynamic>;
      final status = m['api_status'] ?? m['status'];
      final err = (m['errors'] is Map)
          ? (m['errors']['error_text'] ?? m['errors']['error_id'])
          : (m['message'] ?? m['error'] ?? m['api_text']);
      throw Exception(
        'API error${httpCode != null ? ' ($httpCode)' : ''}: $status - $err',
      );
    } catch (_) {
      throw Exception(
          'API error${httpCode != null ? ' ($httpCode)' : ''}: $body');
    }
  }

  // Build absolute URL from WoWonder "media" path
  String _absUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final clean = path.startsWith('/') ? path.substring(1) : path;
    // WoWonder thường trả: upload/photos/... => nối base
    return '${AppConstants.socialBaseUrl}/$clean';
  }

  // Mime guess
  MediaType _guessMediaType(String path) {
    final ext = p.extension(path).toLowerCase();
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
      case '.qt':
        return MediaType('video', 'quicktime');
      case '.m4a':
        return MediaType('audio', 'mp4');
      case '.aac':
        return MediaType('audio', 'aac');
      case '.mp3':
        return MediaType('audio', 'mpeg');
      case '.wav':
        return MediaType('audio', 'wav');
      case '.ogg':
        return MediaType('audio', 'ogg');
      case '.pdf':
        return MediaType('application', 'pdf');
      case '.doc':
        return MediaType('application', 'msword');
      case '.docx':
        return MediaType('application',
            'vnd.openxmlformats-officedocument.wordprocessingml.document');
      case '.xls':
        return MediaType('application', 'vnd.ms-excel');
      case '.xlsx':
        return MediaType('application',
            'vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      case '.zip':
        return MediaType('application', 'zip');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  bool _isImageExt(String ext) =>
      ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext);
  bool _isVideoExt(String ext) =>
      ['.mp4', '.mov', '.m4v', '.webm', '.qt'].contains(ext);
  bool _isAudioExt(String ext) =>
      ['.m4a', '.aac', '.mp3', '.wav', '.ogg'].contains(ext);

  // Chuẩn hoá 1 message của WoWonder để UI render đúng
  void _hydrateWoWonderMessage(Map<String, dynamic> m) {
    m['display_text'] ??= pickWoWonderText(m);

    if (m['reply'] is Map) {
      final r = Map<String, dynamic>.from(m['reply']);
      r['display_text'] = pickWoWonderText(r);
      m['reply'] = r;
    }

    // ✅ FIX: fallback cho mediaFileName/mediaFileNames
    String media = '';
    if (m['media'] != null && '${m['media']}'.isNotEmpty) {
      media = '${m['media']}';
    } else if (m['mediaFileName'] != null &&
        '${m['mediaFileName']}'.isNotEmpty) {
      media = '${m['mediaFileName']}';
    } else if (m['mediaFileNames'] != null &&
        '${m['mediaFileNames']}'.isNotEmpty) {
      media = '${m['mediaFileNames']}';
    }

    if (media.isNotEmpty) {
      final ext = p.extension(media).toLowerCase();
      m['media_ext'] = ext;
      m['media_url'] = _absUrl(media);
      m['is_image'] = _isImageExt(ext);
      m['is_video'] = _isVideoExt(ext);
      m['is_audio'] = _isAudioExt(ext);

      // audio/image/video thì không cần display_text
      if (m['is_image'] == true ||
          m['is_video'] == true ||
          m['is_audio'] == true) {
        m.remove('display_text');
      }
    }
  }

  Map<String, dynamic>? _parseSendResponse(String body) {
    final map = jsonDecode(body) as Map<String, dynamic>;
    final ok = (map['api_status'] ?? map['status']) == 200;
    if (!ok) return null;

    dynamic md = map['message_data'] ?? map['data'] ?? map['message'];
    if (md is List && md.isNotEmpty) md = md.first;
    if (md is! Map) return null;

    final m = Map<String, dynamic>.from(md as Map<String, dynamic>);
    _hydrateWoWonderMessage(m);
    return m;
  }

  // ================= GET user messages =================
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
      // WoWonder dùng 'recipient_id' khi fetch/read (không phải user_id)
      'recipient_id': peerUserId,
      'limit': '$limit',
      if (_notEmpty(beforeMessageId)) 'before_message_id': beforeMessageId!,
      if (_notEmpty(afterMessageId)) 'after_message_id': afterMessageId!,
    };

    final res =
        await http.post(url, body: body).timeout(const Duration(seconds: 20));

    if (kDebugMode) {
      debugPrint('get_user_messages -> ${res.statusCode} ${res.body}');
    }
    if (res.statusCode != 200) _throwApi(res.body, httpCode: res.statusCode);

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final ok = (map['api_status'] ?? map['status']) == 200;
    if (!ok) _throwApi(res.body);

    final list = (map['messages'] ?? map['data'] ?? []) as List;
    final out = <Map<String, dynamic>>[];
    for (final e in list) {
      final m = Map<String, dynamic>.from(e as Map);
      _hydrateWoWonderMessage(m);
      out.add(m);
    }
    return out;
  }

  // ================= Mark as read =================
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
    }).timeout(const Duration(seconds: 15));

    if (kDebugMode) {
      debugPrint('read_chats -> ${res.statusCode} ${res.body}');
    }
    if (res.statusCode != 200) _throwApi(res.body, httpCode: res.statusCode);
  }

  MediaType _mimeFromPath(String path) {
    final ext = p.extension(path).toLowerCase();
    if (ext == '.m4a') return MediaType('audio', 'mp4');
    if (ext == '.aac') return MediaType('audio', 'aac');
    if (ext == '.mp3') return MediaType('audio', 'mpeg');
    if (ext == '.wav') return MediaType('audio', 'wav');
    if (ext == '.ogg') return MediaType('audio', 'ogg');
    if (ext == '.png') return MediaType('image', 'png');
    if (ext == '.jpg' || ext == '.jpeg') return MediaType('image', 'jpeg');
    if (ext == '.webp') return MediaType('image', 'webp');
    if (ext == '.pdf') return MediaType('application', 'pdf');
    if (ext == '.zip') return MediaType('application', 'zip');
    return MediaType('application', 'octet-stream');
  }

  // ================= SEND (text / gif / file) =================
  Future<Map<String, dynamic>?> sendMessage({
    required String token,
    required String peerUserId,
    String? text,
    String? gifUrl,
    String? filePath,
    String? replyToMessageId, // đổi tên cho khớp ChatScreen
  }) async {
    final base =
        '${AppConstants.socialBaseUrl}${AppConstants.socialChatSendMessageUri}?access_token=$token';

    // 1) Multipart (ảnh/video/tài liệu/ghi âm)
    if (_notEmpty(filePath)) {
      final url = Uri.parse(base);
      final req = http.MultipartRequest('POST', url)
        ..fields['server_key'] = AppConstants.socialServerKey
        // 🔧 WoWonder (send multipart) yêu cầu user_id
        ..fields['user_id'] = peerUserId
        // vẫn giữ recipient_id cho an toàn (một số phiên bản chấp nhận)
        ..fields['recipient_id'] = peerUserId
        ..fields['message_hash_id'] =
            DateTime.now().microsecondsSinceEpoch.toString();

      if (_notEmpty(replyToMessageId)) {
        req.fields['reply_id'] = replyToMessageId!;
      }

      final filename = p.basename(filePath!);
      final ct = _guessMediaType(filePath);

      req.files.add(
        await http.MultipartFile.fromPath(
          'file', // khóa WoWonder
          filePath,
          filename: filename,
          contentType: ct,
        ),
      );

      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);

      if (kDebugMode) {
        debugPrint('send-message[multipart] -> ${res.statusCode} ${res.body}');
      }
      if (res.statusCode != 200) _throwApi(res.body, httpCode: res.statusCode);

      final parsed = _parseSendResponse(res.body);
      if (parsed != null) parsed['display_text'] = filename;
      return parsed;
    }

    // 2) x-www-form-urlencoded (text / GIF)
    final url = Uri.parse(base);
    final fields = <String, String>{
      'server_key': AppConstants.socialServerKey,
      // 🔧 thêm user_id cho đồng nhất
      'user_id': peerUserId,
      'recipient_id': peerUserId,
      'message_hash_id': DateTime.now().microsecondsSinceEpoch.toString(),
      if (_notEmpty(text)) 'text': text!,
      if (_notEmpty(gifUrl)) 'gif': gifUrl!,
      if (_notEmpty(replyToMessageId)) 'reply_id': replyToMessageId!,
    };

    final res =
        await http.post(url, body: fields).timeout(const Duration(seconds: 20));

    if (kDebugMode) {
      debugPrint('send-message[form] -> ${res.statusCode} ${res.body}');
    }
    if (res.statusCode != 200) _throwApi(res.body, httpCode: res.statusCode);

    final parsed = _parseSendResponse(res.body);
    if (parsed != null) {
      if (_notEmpty(text)) {
        parsed['display_text'] = text!;
      } else if (_notEmpty(gifUrl)) {
        parsed['display_text'] = '[GIF]';
      }
    }
    return parsed;
  }

  // ================= REACT MESSAGE =================
  Future<void> reactMessage({
    required String token,
    required String messageId,
    required String reaction,
  }) async {
    final url = Uri.parse(
      '${AppConstants.socialBaseUrl}/api/react_message?access_token=$token',
    );

    final req = http.MultipartRequest('POST', url)
      ..fields['server_key'] = AppConstants.socialServerKey
      ..fields['id'] = messageId
      ..fields['reaction'] = reaction.toString();

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    if (kDebugMode) {
      debugPrint('react_message -> ${res.statusCode} ${res.body}');
    }

    if (res.statusCode != 200) {
      _throwApi(res.body, httpCode: res.statusCode);
    } else {
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final ok = (map['api_status'] ?? map['status']) == 200;
      if (!ok) _throwApi(res.body);
    }
  }

  Future<bool> deleteMessage({
    required String token,
    required String messageId,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.socialBaseUrl}/api/delete_message?access_token=$token',
      );

      // Gửi dạng form body bình thường, WoWonder vẫn nhận được
      final resp = await http.post(
        uri,
        body: {
          'server_key': AppConstants.socialServerKey,
          'message_id': messageId,
        },
      );

      if (resp.statusCode != 200) {
        debugPrint(
            'deleteMessage httpStatus != 200: ${resp.statusCode} ${resp.body}');
        return false;
      }

      dynamic data = jsonDecode(resp.body);
      if (data is! Map<String, dynamic>) {
        return false;
      }

      final status = int.tryParse(
              '${data['api_status'] ?? data['status'] ?? data['code'] ?? ''}') ??
          0;

      return status == 200;
    } catch (e, st) {
      debugPrint('deleteMessage error: $e\n$st');
      return false;
    }
  }


  // ================= SEARCH USERS (forward) =================
  /// Tìm người dùng WoWonder để chuyển tiếp tin nhắn
  ///
  /// Trả về list map có các key tối thiểu:
  /// { user_id, name, avatar }
  Future<List<Map<String, dynamic>>> searchUsers({
    required String token,
    String query = '',
    int limit = 30,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.socialBaseUrl}/api/get_users?access_token=$token',
      );

      final body = <String, String>{
        'server_key': AppConstants.socialServerKey,
        // tuỳ backend: type = search / get_users
        'type': 'search',
        'limit': '$limit',
      };

      if (query.trim().isNotEmpty) {
        // tuỳ backend: có thể là search_query / keyword / search_key
        body['search_query'] = query.trim();
      }

      final res =
          await http.post(uri, body: body).timeout(const Duration(seconds: 20));

      if (kDebugMode) {
        debugPrint('searchUsers -> ${res.statusCode} ${res.body}');
      }

      if (res.statusCode != 200) {
        _throwApi(res.body, httpCode: res.statusCode);
      }

      final data = jsonDecode(res.body);
      if (data is! Map<String, dynamic>) return [];

      final ok =
          (data['api_status'] ?? data['status'] ?? data['code'] ?? 0) == 200;
      if (!ok) {
        _throwApi(res.body);
      }

      final rawList = (data['users'] ?? data['data'] ?? []) as List;
      final List<Map<String, dynamic>> out = [];

      for (final item in rawList) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item as Map);

        final id = '${m['user_id'] ?? m['id'] ?? ''}'.trim();
        if (id.isEmpty) continue;

        out.add({
          'user_id': id,
          'name': (m['name'] ?? m['username'] ?? '').toString(),
          'avatar': _absUrl((m['avatar'] ?? m['avatar_url'] ?? '').toString()),
        });
      }

      return out;
    } catch (e, st) {
      debugPrint('searchUsers error: $e\n$st');
      return [];
    }
  }



}
