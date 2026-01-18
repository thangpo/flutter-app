import 'dart:convert';
import 'package:http/http.dart' as http;

class WishlistService {
  WishlistService({
    required this.baseUrl,
    required this.getAccessToken,
  });

  final String baseUrl;
  final Future<String?> Function() getAccessToken;

  Map<String, String> _headers(String token) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> index({int perPage = 20}) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Missing access token');
    }

    final uri = Uri.parse('$baseUrl/wishlist').replace(queryParameters: {
      'per_page': perPage.toString(),
    });

    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Wishlist index failed: ${res.statusCode} ${res.body}');
  }

  Future<bool> check({
    required int objectId,
    required String objectModel,
  }) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Missing access token');
    }

    final uri = Uri.parse('$baseUrl/wishlist/check').replace(queryParameters: {
      'object_id': objectId.toString(),
      'object_model': objectModel,
    });

    final res = await http.get(uri, headers: _headers(token));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (body['data']?['active'] == true);
    }
    throw Exception('Wishlist check failed: ${res.statusCode} ${res.body}');
  }

  Future<bool> toggle({
    required int objectId,
    required String objectModel,
  }) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Missing access token');
    }

    final uri = Uri.parse('$baseUrl/wishlist/toggle');
    final res = await http.post(
      uri,
      headers: _headers(token),
      body: jsonEncode({
        'object_id': objectId,
        'object_model': objectModel,
      }),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (body['data']?['active'] == true) ||
          (body['data']?['class'] == 'active');
    }

    throw Exception('Wishlist toggle failed: ${res.statusCode} ${res.body}');
  }

  Future<void> remove({
    required int objectId,
    required String objectModel,
  }) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Missing access token');
    }

    final uri = Uri.parse('$baseUrl/wishlist');
    final res = await http.delete(
      uri,
      headers: _headers(token),
      body: jsonEncode({
        'object_id': objectId,
        'object_model': objectModel,
      }),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) return;

    throw Exception('Wishlist remove failed: ${res.statusCode} ${res.body}');
  }
}