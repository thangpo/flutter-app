import 'dart:convert';
import 'package:http/http.dart' as http;

class HotelService {
  final String baseUrl = "https://vietnamtoure.com/api";

  Future<List<dynamic>> fetchHotels({int limit = 10}) async {
    final response = await http.get(Uri.parse('$baseUrl/hotels?limit=$limit'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load hotels');
    }
  }

  Future<Map<String, dynamic>> fetchHotelDetail(String slug) async {
    final response = await http.get(Uri.parse('$baseUrl/hotels/$slug'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load hotel detail');
    }
  }
}
