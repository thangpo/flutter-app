import 'dart:convert';
import 'package:http/http.dart' as http;

class DuffelService {
  static const String apiKey = "duffel_test_lkVeDLi9UBt6AvHi8BuQ4CwXBj6HEhE5idyn3nz9hrb";

  /// Tìm kiếm chuyến bay dựa trên thông tin đầu vào
  static Future<List<dynamic>> searchFlights({
    required String fromCode,
    required String toCode,
    required String departureDate,
    String? returnDate,
    required int adults,
    int children = 0,
    int infants = 0,
  }) async {
    final postBody = {
      "data": {
        "slices": [
          {"origin": fromCode, "destination": toCode, "departure_date": departureDate},
          if (returnDate != null && returnDate.isNotEmpty)
            {"origin": toCode, "destination": fromCode, "departure_date": returnDate},
        ],
        "passengers": [
          for (int i = 0; i < adults; i++) {"type": "adult"},
          for (int i = 0; i < children; i++) {"type": "child"},
          for (int i = 0; i < infants; i++) {"type": "infant"},
        ],
        "cabin_class": "economy",
      }
    };

    try {
      final requestRes = await http.post(
        Uri.parse("https://api.duffel.com/air/offer_requests"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
          "Duffel-Version": "v2",
        },
        body: jsonEncode(postBody),
      );

      if (requestRes.statusCode != 201) {
        throw Exception("Offer request failed: ${requestRes.body}");
      }

      final requestData = jsonDecode(requestRes.body);
      final offerRequestId = requestData["data"]["id"];

      final offersRes = await http.get(
        Uri.parse("https://api.duffel.com/air/offers?offer_request_id=$offerRequestId&limit=20"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
          "Duffel-Version": "v2",
        },
      );

      if (offersRes.statusCode != 200) {
        throw Exception("Get offers failed: ${offersRes.body}");
      }

      final offersData = jsonDecode(offersRes.body);
      final offers = offersData["data"] as List;
      final vnAirlines = ["Vietnam Airlines", "VietJet Air", "Bamboo Airways", "Singapore Airlines", "American Airlines"];
      final filtered = offers
          .where((f) => f["owner"] != null && vnAirlines.contains(f["owner"]["name"]))
          .take(20)
          .toList();

      return filtered;
    } catch (e) {
      throw Exception("Lỗi Duffel API: $e");
    }
  }
}