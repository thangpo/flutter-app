import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/search_chat_result.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class ChatSearchService {
  /// Gọi API /api/chat với type=search_chat
  static Future<SearchChatResult> search({
    required String accessToken,
    required String text,
    int limit = 20,
  }) async {
    final uri = Uri.parse('${AppConstants.socialBaseUrl}/api/chat')
        .replace(queryParameters: {'access_token': accessToken});

    final request = http.MultipartRequest('POST', uri);
    request.fields['server_key'] = AppConstants.socialServerKey;
    request.fields['type'] = 'search_chat';
    request.fields['text'] = text;
    request.fields['limit'] = limit.toString();

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) {
      throw Exception('search_chat failed (${res.statusCode})');
    }

    final body = jsonDecode(res.body);
    if (body is! Map || body['api_status'] != 200) {
      throw Exception(body['errors']?.toString() ?? 'search_chat error');
    }

    return SearchChatResult.fromJson(
      Map<String, dynamic>.from(body['data'] as Map),
    );
  }
}
