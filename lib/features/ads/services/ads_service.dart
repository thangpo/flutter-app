import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class AdsService {
  static const String _baseUrl = "https://social.vnshop247.com/api/ads";

  Future<List<Map<String, dynamic>>> fetchMyCampaigns({
    required String accessToken,
    int limit = 10,
    int offset = 0,
  }) async {
    final url = Uri.parse("$_baseUrl?access_token=$accessToken");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'server_key': AppConstants.socialServerKey,
        'type': 'fetch_ads',
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );

    final jsonResponse = jsonDecode(response.body);

    if (jsonResponse['api_status'] == "404") {
      throw Exception("Lỗi server_key: ${jsonResponse['errors']['error_text']}");
      List<Map<String, dynamic>>.from(jsonResponse['data']);
    }

    if (jsonResponse['api_status'] != 200) {
      throw Exception("Lỗi API: ${jsonResponse['errors']?['error_text'] ?? 'Unknown error'}");
    }

    return List<Map<String, dynamic>>.from(jsonResponse['data']);
  }

  Future<Map<String, dynamic>> createCampaign({
    required String accessToken,
    required Map<String, dynamic> formData,
    required String mediaPath,
  }) async {
    final url = Uri.parse("$_baseUrl?access_token=$accessToken");

    var request = http.MultipartRequest('POST', url);

    request.fields.addAll({
      'server_key': AppConstants.socialServerKey,
      'type': 'create',
      'name': formData['name'],
      'headline': formData['headline'],
      'description': formData['description'],
      'url': formData['url'],
      'location': formData['location'],
      'audience': formData['audience'].join(','),
      'gender': formData['gender'],
      'appears': formData['appears'],
      'bidding': formData['bidding'],
    });

    if (mediaPath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('ad_media', mediaPath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final jsonResponse = jsonDecode(response.body);

    if (jsonResponse['api_status'] != 200) {
      throw Exception(jsonResponse['errors']?['error_text'] ?? 'Tạo thất bại');
    }

    return jsonResponse;
  }
}