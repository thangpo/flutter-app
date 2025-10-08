import 'dart:convert';
import 'package:http/http.dart' as http;

class FlightService {
  static const String baseUrl = "https://api.duffel.com/air";
  static const String apiKey =
      "Bearer duffel_test_lkVeDLi9UBt6AvHi8BuQ4CwXBj6HEhE5idyn3nz9hrb"; // key thật

  /// Lấy chi tiết 1 offer (chuyến bay)
  static Future<Map<String, dynamic>> getFlightDetail(String flightId) async {
    final url = Uri.parse("$baseUrl/offers/$flightId");

    final response = await http.get(
      url,
      headers: {
        "Authorization": apiKey,
        "Accept": "application/json",
        "Duffel-Version": "v2",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("Lỗi khi lấy chi tiết chuyến bay: ${response.body}");
    }
  }

  /// Lấy sơ đồ ghế của offer
  static Future<List<dynamic>> getSeatMaps(String flightId) async {
    final url = Uri.parse("$baseUrl/seat_maps?offer_id=$flightId");

    final response = await http.get(
      url,
      headers: {
        "Authorization": apiKey,
        "Accept": "application/json",
        "Duffel-Version": "v2",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data["data"] as List<dynamic>;
    } else {
      throw Exception("Lỗi khi lấy seat maps: ${response.body}");
    }
  }

  /// 👉 Thêm hàm này để lấy các hạng vé (upgrade offers)
  static Future<List<dynamic>> getOffers(String offerRequestId) async {
    final url =
    Uri.parse("$baseUrl/offers?offer_request_id=$offerRequestId");

    final response = await http.get(
      url,
      headers: {
        "Authorization": apiKey,
        "Accept": "application/json",
        "Duffel-Version": "v2",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data["data"] as List<dynamic>;
    } else {
      throw Exception("Lỗi khi lấy offers: ${response.body}");
    }
  }
}