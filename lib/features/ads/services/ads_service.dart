import 'dart:convert';
import 'dart:io';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_sixvalley_ecommerce/features/ads/domain/models/countries.dart';

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
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'server_key': AppConstants.socialServerKey,
        'type': 'fetch_ads',
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );

    final jsonResponse = jsonDecode(response.body);

    if (jsonResponse['api_status'] == "404") {
      throw Exception("Server key sai: ${jsonResponse['errors']['error_text']}");
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
    final budget = int.tryParse(formData['budget'].toString()) ?? 0;
    if (budget <= 0) throw Exception('Ngân sách phải lớn hơn 0');

    final url = Uri.parse("$_baseUrl?access_token=$accessToken");
    var request = http.MultipartRequest('POST', url);

    final countries = formData['countries'] as List<Country>? ?? [];
    final audienceList = countries
        .map((c) => c.value)
        .where((v) => v != "0" && v.isNotEmpty)
        .join(',');

    if (audienceList.isEmpty) throw Exception('Chưa chọn quốc gia hợp lệ');

    String genderValue() {
      final g = formData['gender']?.toString() ?? 'all';
      if (g == 'Nam') return 'male';
      if (g == 'Nữ') return 'female';
      return 'all';
    }

    String appearsFixed = (formData['appears'] ?? 'post').toString();
    if (appearsFixed == 'entire') {
      appearsFixed = 'post';
      dev.log('appears=entire → tự chuyển thành post (ảnh không hỗ trợ)');
    }

    request.fields.addAll({
      'server_key': AppConstants.socialServerKey,
      'type': 'create',
      'name': (formData['name'] ?? '').toString(),
      'website': (formData['website'] ?? '').toString(),
      'headline': (formData['headline'] ?? '').toString(),
      'description': (formData['description'] ?? '').toString(),
      'start': (formData['start'] ?? '').toString(),
      'end': (formData['end'] ?? '').toString(),
      'budget': budget.toString(),
      'bidding': (formData['bidding'] ?? 'clicks').toString().toLowerCase(),
      'appears': appearsFixed,
      'audience-list': audienceList,
      'gender': genderValue(),
      'location': (formData['location'] ?? '').toString(),
      'page': 'vnshop247page',
    });

    if (mediaPath.isNotEmpty) {
      final file = File(mediaPath);
      if (!await file.exists()) throw Exception('File ảnh không tồn tại');

      final size = await file.length();
      if (size > 5 * 1024 * 1024) throw Exception('Ảnh tối đa 5MB');
      if (size == 0) throw Exception('File ảnh rỗng');

      String mediaType = 'image/jpeg';
      final ext = mediaPath.toLowerCase();
      if (ext.endsWith('.png')) {
        mediaType = 'image/png';
      } else if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) {
        mediaType = 'image/jpeg';
      } else if (ext.endsWith('.gif')) {
        mediaType = 'image/gif';
      } else if (ext.endsWith('.mp4')) {
        mediaType = 'video/mp4';
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'media',
          mediaPath,
          contentType: MediaType.parse(mediaType),
        ),
      );

      dev.log('Upload ảnh: ${size ~/ 1024} KB | Type: $mediaType');
    }


    dev.log('Gửi fields: ${request.fields}');
    dev.log('audience-list: $audienceList | appears: $appearsFixed');

    try {
      final streamedResponse = await request.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamedResponse);
      final jsonResponse = jsonDecode(response.body);

      dev.log('📥 Response create ads: $jsonResponse (code: ${response.statusCode})');

      final apiStatus = jsonResponse['api_status']?.toString() ?? '0';
      if (apiStatus == "404") throw Exception("Server key sai");
      if (apiStatus != "200") {
        final err = jsonResponse['errors']?['error_text'] ?? 'Please check your details';
        throw Exception(err);
      }
      return jsonResponse;
    } catch (e) {
      dev.log('💥 Exception tạo ads: $e');
      rethrow;
    }
  }
}