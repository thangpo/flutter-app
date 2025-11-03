import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class SocialLiveRepository {
  final String apiBaseUrl;
  final String serverKey;

  const SocialLiveRepository({
    required this.apiBaseUrl,
    required this.serverKey,
  });

  Future<Map<String, dynamic>> createLive({
    required String accessToken,
    required String streamName,
    String token = '',
  }) async {
    final Uri url = Uri.parse(
      '$apiBaseUrl${AppConstants.socialLiveUri}?access_token=$accessToken',
    );

    final http.Response response = await http.post(url, body: {
      'server_key': serverKey,
      'type': 'create',
      'stream_name': streamName,
      'token': token,
    });

    if (response.statusCode != 200) {
      throw Exception('Live API returned status ${response.statusCode}');
    }

    final Map<String, dynamic>? body = _extractJsonBody(response.body);
    if (body == null) {
      throw Exception('Live API returned invalid response payload.');
    }

    if (body['api_status'] != 200) {
      final Object? reason = body['api_text'] ?? body['errors'];
      throw Exception(reason?.toString() ?? 'Failed to create live stream.');
    }

    final Object? postData = body['post_data'];
    if (postData is Map<String, dynamic>) {
      return Map<String, dynamic>.from(postData);
    }
    if (postData is Map) {
      return postData.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    throw Exception('Live API response is missing post_data.');
  }

  Future<Map<String, dynamic>?> generateAgoraToken({
    required String accessToken,
    required String channelName,
    required int uid,
    String role = 'publisher',
  }) async {
    final Uri url = Uri.parse(
      '$apiBaseUrl${AppConstants.socialGenerateAgoraTokenUri}?access_token=$accessToken',
    );

    final http.Response response = await http.post(url, body: {
      'server_key': serverKey,
      'channelName': channelName,
      'uid': uid.toString(),
      'role': role,
    });

    if (response.statusCode != 200) {
      throw Exception(
        'generate_agora_token returned status ${response.statusCode}',
      );
    }

    final Map<String, dynamic>? body = _extractJsonBody(response.body);
    if (body == null) return null;

    return body;
  }

  Map<String, dynamic>? _extractJsonBody(String rawBody) {
    final int start = rawBody.indexOf('{');
    final int end = rawBody.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      return null;
    }
    final String slice = rawBody.substring(start, end + 1);
    final dynamic decoded = json.decode(slice);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }
}
