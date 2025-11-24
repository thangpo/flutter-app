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

    print("====================================");
    print("🚀 CALL API CHECK-AVAILABILITY");
    print("➡ URL: $baseUrl");
    print("➡ BODY gửi lên: ${jsonEncode(body)}");
    print("====================================");

    final res = await http.post(Uri.parse(baseUrl), body: body);

    print("⬅ STATUS CODE: ${res.statusCode}");
    print("⬅ RAW RESPONSE:");
    print(res.body);
    print("====================================");

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }

    final jsonRes = json.decode(res.body);

    if (jsonRes['success'] != true) {
      print("❌ API ERROR: ${jsonRes['message'] ?? jsonRes['error']}");
      throw Exception(jsonRes['message'] ?? jsonRes['error'] ?? "API error");
    }

    print("✅ API SUCCESS, rooms length: ${(jsonRes['data']?['rooms'] as List?)?.length ?? 0}");

    return (jsonRes['data']?['rooms'] as List?) ?? [];
  }
}