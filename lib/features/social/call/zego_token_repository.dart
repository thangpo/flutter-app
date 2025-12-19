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

    final response = await http.post(url, body: {
      'server_key': AppConstants.socialServerKey,
      // Server will trust access_token, but keep user_id for clarity/logging
      'user_id': userId,
    });

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode} khi xin Zego token');
    }

    final body = jsonDecode(response.body);
    final status = body['api_status']?.toString();
    if (status != '200') {
      final err = body['errors']?['error_text'] ??
          body['error'] ??
          body['message'] ??
          'api_status=$status';
      throw Exception('Không lấy được Zego token: $err');
    }

    final parsed = ZegoTokenResponse.fromJson(body);
    if (parsed.token.isEmpty) {
      throw Exception('Zego token rỗng từ server');
    }

    return parsed;
  }
}
