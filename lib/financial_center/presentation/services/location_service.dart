import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static const String baseUrl = 'https://vietnamtoure.com/api/locations';

  static Future<List<Map<String, dynamic>>> fetchLocations() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      throw Exception('Dữ liệu không hợp lệ');
    } catch (e) {
      throw Exception('Không thể tải danh sách địa chỉ: $e');
    }
  }
}