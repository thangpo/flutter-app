import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/airport_models.dart';

class FlightAirportApi {
  static const String _base = 'https://vietnamtoure.com/api';

  static Future<List<AirportItem>> fetchAirports({
    String q = '',
    int limit = 20,
    int page = 1,
  }) async {
    final uri = Uri.parse('$_base/flights/airports').replace(
      queryParameters: <String, String>{
        'q': q,
        'limit': limit.toString(),
        'page': page.toString(),
      },
    );

    final res = await http.get(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final jsonMap = json.decode(res.body) as Map<String, dynamic>;
    if (jsonMap['status'] != 1) {
      throw Exception(jsonMap['message']?.toString() ?? 'API error');
    }

    final data = (jsonMap['data'] as Map<String, dynamic>);
    final rows = (data['rows'] as List<dynamic>? ?? const []);
    return rows
        .whereType<Map<String, dynamic>>()
        .map((e) => AirportItem.fromJson(e))
        .toList();
  }
}