import 'dart:convert';
import 'package:http/http.dart' as http;

class TourService {
  static const String baseUrl = 'https://vietnamtoure.com/api';

  static Future<List<dynamic>> fetchTours() async {
    final uri = Uri.parse('$baseUrl/tours');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == true && data['data'] != null) {
        return data['data'];
      }
    }
    throw Exception('Không thể tải danh sách tour');
  }

  static Future<List<dynamic>> searchTours({
    String? title,
    int? locationId,
  }) async {
    final uri = Uri.parse('$baseUrl/tours/search');
    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        if (title != null && title.isNotEmpty) 'title': title,
        if (locationId != null) 'location_id': locationId.toString(),
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == true && data['data'] != null) {
        return data['data'];
      }
    }

    throw Exception('Không thể tìm kiếm tour');
  }
}