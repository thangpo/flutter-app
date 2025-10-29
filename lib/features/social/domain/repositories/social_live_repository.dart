import 'dart:convert';
import 'package:http/http.dart' as http;

class SocialLiveRepository {
  final String apiBaseUrl;
  final String serverKey;

  SocialLiveRepository({
    required this.apiBaseUrl,
    required this.serverKey,
  });

  Future<Map<String, dynamic>?> createLive(String accessToken) async {
    final url = Uri.parse('$apiBaseUrl/api/live?access_token=$accessToken');
    print(serverKey);
    final response = await http.post(url, body: {
      'server_key': serverKey,
      'type': 'create',
      'stream_name': 'test_stream_123',
      'post_privacy': '0',
    });

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body['api_status'] == 200 && body['post_data'] != null) {
        return body['post_data'];
      }
    }
    return null;
  }
}
