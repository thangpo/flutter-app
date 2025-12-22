import 'dart:convert';
import 'package:http/http.dart' as http;

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
}