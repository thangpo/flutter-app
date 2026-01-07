import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FlightService {
  static const String baseUrl = "https://vietnamtoure.com/api";
  static String? bearerToken;

  static Map<String, String> _headers() {
    final headers = <String, String>{
      "Accept": "application/json",
      "Content-Type": "application/json",
    };
    if (bearerToken != null && bearerToken!.isNotEmpty) {
      headers["Authorization"] = "Bearer $bearerToken";
    }
    return headers;
  }

  static Map<String, dynamic> _decodeJson(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  static void _ensureOk(Map<String, dynamic> body) {
    if (body["status"] != 1) {
      throw Exception(body["message"] ?? "API error");
    }
  }

  static Future<Map<String, dynamic>> getFlights({
    Map<String, dynamic>? params,
  }) async {
    final qp = <String, String>{};

    if (params != null) {
      params.forEach((key, value) {
        if (value == null) return;
        qp[key] = value.toString();
      });
    }

    final url = Uri.parse("$baseUrl/flights").replace(queryParameters: qp);
    final response = await http.get(url, headers: _headers());
    final body = _decodeJson(response);

    if (response.statusCode == 200) {
      _ensureOk(body);
      return body;
    } else {
      throw Exception("Lỗi khi lấy danh sách flights: ${response.statusCode} - ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> searchFlights({
    int limit = 9,
    int page = 1,
    String? start,
    String? end,
    String? keyword,
    String? airportFromId,
    String? airportToId,
    String? airlineId,
    String? seatType,
    num? minPrice,
    num? maxPrice,
    bool withLocations = false,
    bool withAttributes = false,
    bool withSeatTypes = true,
    Map<String, dynamic>? extraParams,
  }) async {
    final params = <String, dynamic>{
      'limit': limit,
      'page': page,
      if (start != null && start.trim().isNotEmpty) 'start': start.trim(),
      if (end != null && end.trim().isNotEmpty) 'end': end.trim(),
      if (keyword != null && keyword.trim().isNotEmpty) 's': keyword.trim(),
      if (airportFromId != null && airportFromId.isNotEmpty) 'airport_from': airportFromId,
      if (airportToId != null && airportToId.isNotEmpty) 'airport_to': airportToId,
      if (airlineId != null && airlineId.isNotEmpty) 'airline_id': airlineId,
      if (seatType != null && seatType.isNotEmpty) 'seat_type': seatType,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      'with_locations': withLocations ? 1 : 0,
      'with_attributes': withAttributes ? 1 : 0,
      'with_seat_types': withSeatTypes ? 1 : 0,
    };

    if (extraParams != null) params.addAll(extraParams);

    return getFlights(params: params);
  }

  static Future<Map<String, dynamic>> getFlightDetail(String flightId) async {
    final url = Uri.parse("$baseUrl/flights/$flightId");
    final response = await http.get(url, headers: _headers());
    final body = _decodeJson(response);

    if (response.statusCode == 200) {
      _ensureOk(body);
      return body;
    } else {
      throw Exception("Lỗi khi lấy chi tiết chuyến bay: ${response.statusCode} - ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> getFlightData(String flightId) async {
    final url = Uri.parse("$baseUrl/flights/$flightId/data");

    final response = await http.get(url, headers: _headers());
    final body = _decodeJson(response);

    if (response.statusCode == 200) {
      _ensureOk(body);
      return body;
    } else {
      throw Exception("Lỗi khi lấy flight data: ${response.statusCode} - ${response.body}");
    }
  }

  static Future<List<dynamic>> getOffers({
    int limit = 9,
    int page = 1,
    Map<String, dynamic>? extraParams,
  }) async {
    final params = <String, dynamic>{
      "limit": limit,
      "page": page,
    };

    if (extraParams != null) {
      params.addAll(extraParams);
    }

    final res = await getFlights(params: params);
    final data = res["data"] as Map<String, dynamic>;
    return (data["rows"] as List<dynamic>);
  }

  static Future<List<dynamic>> getSeatMaps(String flightId) async {
    final res = await getFlightDetail(flightId);
    final data = res["data"] as Map<String, dynamic>;
    final flight = data["flight"] as Map<String, dynamic>;
    final seats = flight["flight_seat"];
    if (seats is List) return seats;

    return <dynamic>[];
  }

  static Future<Map<String, dynamic>> createBooking({
    required String objectModel,
    required int objectId,
    required String startDate,
    String? endDate,
    required int totalGuests,
    String? customerNotes,
    String? gateway,
    required double amount,
    required Map<String, dynamic> contactInfo,
    List<Map<String, dynamic>>? passengers,
    Map<String, dynamic>? flightInfo,
    Map<String, dynamic>? extra,

    bool enableLog = true,
  }) async {
    final payload = <String, dynamic>{
      "object_model": objectModel,
      "object_id": objectId,
      "start_date": startDate,
      "end_date": endDate,
      "total_guests": totalGuests,
      "customer_notes": customerNotes,
      "gateway": gateway,
      "amount": amount,
      "contact_info": contactInfo,
      if (passengers != null) "passengers": passengers,
      if (flightInfo != null) "flight_info": flightInfo,
    };

    if (extra != null) payload.addAll(extra);

    final url = Uri.parse("$baseUrl/bookings");
    final headers = _headers();
    final safeHeaders = Map<String, String>.from(headers);
    if (safeHeaders.containsKey("Authorization")) {
      final v = safeHeaders["Authorization"] ?? "";
      safeHeaders["Authorization"] = v.length > 18 ? "${v.substring(0, 18)}***" : "***";
    }

    if (enableLog) {
      debugPrint("========== [BOOKING REQUEST] ==========");
      debugPrint("POST: $url");
      debugPrint("Headers: ${jsonEncode(safeHeaders)}");
      debugPrint("Payload:\n${const JsonEncoder.withIndent('  ').convert(payload)}");
    }

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(payload),
    );

    final rawText = utf8.decode(response.bodyBytes);
    if (enableLog) {
      debugPrint("========== [BOOKING RESPONSE] ==========");
      debugPrint("Status: ${response.statusCode}");
      debugPrint("Body:\n$rawText");
      debugPrint("=======================================");
    }

    late final Map<String, dynamic> body;
    try {
      body = jsonDecode(rawText) as Map<String, dynamic>;
    } catch (_) {
      throw Exception("Response không phải JSON. Status=${response.statusCode}, body=$rawText");
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (body.containsKey("status")) {
        _ensureOk(body);
      } else if (body["success"] == false) {
        throw Exception(body["message"] ?? "Booking failed");
      }
      return body;
    } else if (response.statusCode == 422) {
      throw Exception("Validation error: $rawText");
    } else {
      throw Exception("Lỗi khi tạo booking: ${response.statusCode} - $rawText");
    }
  }

  static void _ensureOkSepay(Map<String, dynamic> body) {
    final s = body["status"];
    final ok = (s == true) || (s == 1) || (s == "1") || (s == "true");
    if (!ok) {
      throw Exception(body["message"] ?? "SePay API error");
    }
  }

  static Future<Map<String, dynamic>> createSepayPayment({
    required String objectModel,
    required int objectId,
    required String startDate,
    String? endDate,
    required int totalGuests,
    String? customerNotes,
    required double amount,
    required Map<String, dynamic> contactInfo,
    required List<Map<String, dynamic>> passengers,
    required Map<String, dynamic> flightInfo,
    String? couponCode,
  }) async {
    final payload = <String, dynamic>{
      "object_model": objectModel,
      "object_id": objectId,
      "start_date": startDate,
      "end_date": endDate,
      "total_guests": totalGuests,
      "customer_notes": customerNotes,
      "gateway": "sepay",
      "amount": amount,
      "contact_info": contactInfo,
      "passengers": passengers,
      "flight_info": flightInfo,
      if (couponCode != null && couponCode.trim().isNotEmpty) "coupon_code": couponCode.trim(),
    };

    final url = Uri.parse("$baseUrl/bookings/sepay/payment");
    final response = await http.post(url, headers: _headers(), body: jsonEncode(payload));
    final rawText = utf8.decode(response.bodyBytes);

    late final Map<String, dynamic> body;
    try {
      body = jsonDecode(rawText) as Map<String, dynamic>;
    } catch (_) {
      throw Exception("Response không phải JSON. Status=${response.statusCode}, body=$rawText");
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      _ensureOkSepay(body);
      return body;
    }

    throw Exception("SePay create payment failed: ${response.statusCode} - $rawText");
  }

  static Future<Map<String, dynamic>> checkBookingStatus(String code) async {
    final url = Uri.parse("$baseUrl/bookings/check/$code");
    final response = await http.get(url, headers: _headers());
    final rawText = utf8.decode(response.bodyBytes);

    late final Map<String, dynamic> body;
    try {
      body = jsonDecode(rawText) as Map<String, dynamic>;
    } catch (_) {
      throw Exception("Response không phải JSON. Status=${response.statusCode}, body=$rawText");
    }

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception("checkBookingStatus failed: ${response.statusCode} - $rawText");
  }

  static Future<Map<String, dynamic>> cancelBooking(String code) async {
    final url = Uri.parse("$baseUrl/bookings/cancel");
    final payload = {"code": code};
    final response = await http.post(url, headers: _headers(), body: jsonEncode(payload));
    final rawText = utf8.decode(response.bodyBytes);

    try {
      return jsonDecode(rawText) as Map<String, dynamic>;
    } catch (_) {
      throw Exception("Cancel response không phải JSON. Status=${response.statusCode}, body=$rawText");
    }
  }

}