import 'dart:convert';
import 'package:http/http.dart' as http;

class HotelRoomService {
  static const String baseUrl =
      'https://vietnamtoure.com/api/hotel/check-availability';

  static Future<List<dynamic>> checkAvailability({
    required int hotelId,
    required String startDate,
    required String endDate,
    required int adults,
    required int children,
  }) async {

    final body = {
      'hotel_id': hotelId.toString(),
      'start_date': startDate,
      'end_date': endDate,
      'adults': adults.toString(),
      'children': children.toString(),
      'firstLoad': 'false',
    };

    final res = await http.post(Uri.parse(baseUrl), body: body);

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }

    final jsonRes = json.decode(res.body);

    if (jsonRes['success'] != true) {
      throw Exception(jsonRes['message'] ?? jsonRes['error'] ?? "API error");
    }
    return (jsonRes['data']?['rooms'] as List?) ?? [];
  }
}