import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../utill/app_constants.dart';

class ZegoTokenResponse {
  final String token;
  final int expireAt; // epoch seconds
  final int expireIn; // seconds

  const ZegoTokenResponse({
    required this.token,
    required this.expireAt,
    required this.expireIn,
  });

  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return expireAt > 0 && now >= expireAt;
  }

  factory ZegoTokenResponse.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final token = json['token'] ??
        json['zego_token'] ??
        json['data']?['token'] ??
        '';
    final expireIn = _asInt(json['expire_in']) ??
        _asInt(json['expiry']) ??
        _asInt(json['expires_in']) ??
        3600;
    final expireAt = _asInt(json['expire_at']) ??
        _asInt(json['expired_at']) ??
        _asInt(json['expiry_ts']) ??
        (now + expireIn);

    return ZegoTokenResponse(
      token: token,
      expireAt: expireAt,
      expireIn: expireIn,
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed;
    }
    return null;
  }
}

class ZegoTokenRepository {
  Future<ZegoTokenResponse> fetchToken({
    required String accessToken,
    required String userId,
  }) async {
    final url = Uri.parse(
      '${AppConstants.socialBaseUrl}${AppConstants.socialGenerateZegoTokenUri}?access_token=$accessToken',
    );

    final body = {
      'server_key': AppConstants.socialServerKey,
      // Server will trust access_token, but keep user_id for clarity/logging
      'user_id': userId,
    };

    // Debug log cho tracing
    // ignore: avoid_print
    print('[ZEGO] POST /api/zego_token body=$body');

    final response = await http.post(url, body: body);

    // Debug log cho tracing
    // ignore: avoid_print
    print(
        '[ZEGO] POST /api/zego_token -> status=${response.statusCode}, len=${response.bodyBytes.length}');

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode} khi xin Zego token');
    }

    final Map<String, dynamic> jsonBody = jsonDecode(response.body);
    final status = jsonBody['api_status']?.toString();
    if (status != '200') {
      final err = jsonBody['errors']?['error_text'] ??
          jsonBody['error'] ??
          jsonBody['message'] ??
          'api_status=$status';
      throw Exception('Không lấy được Zego token: $err');
    }

    final parsed = ZegoTokenResponse.fromJson(jsonBody);
    if (parsed.token.isEmpty) {
      throw Exception('Zego token rỗng từ server');
    }

    return parsed;
  }
}
