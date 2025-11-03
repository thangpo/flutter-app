import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class SocialUserService {
  Future<Map<String, dynamic>> getWalletBalance({
    required String accessToken,
    required int userId,
  }) async {
    final url = Uri.parse(
      "${AppConstants.socialBaseUrl}/api/get-user-data?access_token=$accessToken",
    );

    final body = {
      "server_key": AppConstants.socialServerKey,
      "fetch": "user_data",
      "user_id": userId.toString(),
      "send_notify": "1",
    };

    try {
      final response = await http.post(url, body: body);

      if (response.statusCode != 200) {
        throw Exception("HTTP Error: ${response.statusCode}");
      }

      final data = json.decode(response.body);

      final apiStatus = data["api_status"]?.toString() ?? "";
      if (apiStatus != "200") {
        String errorMsg = "Unknown API error";

        if (data["errors"] != null) {
          if (data["errors"] is Map) {
            errorMsg = data["errors"]["error_text"] ??
                data["errors"]["error_id"] ??
                "API Error";
          } else if (data["errors"] is String) {
            errorMsg = data["errors"];
          }
        }

        throw Exception("API Status: $apiStatus - $errorMsg");
      }

      if (data["user_data"] == null) {
        throw Exception("Response không có user_data");
      }

      return data["user_data"];

    } catch (e) {
      if (e is FormatException) {
        throw Exception("Lỗi parse JSON: ${e.message}");
      }
      rethrow;
    }
  }
}
