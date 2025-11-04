import 'dart:convert';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';

class SepayService {
  static const String baseUrl = 'https://social.vnshop247.com/api/';

  Future<Map<String, dynamic>?> createPaymentQR({
    required BuildContext context,
    required int amount,
  }) async {
    try {
      final auth = Provider.of<AuthController>(context, listen: false);

      final accessToken = await auth.authServiceInterface.getSocialAccessToken();

      if (accessToken == null) {
        throw Exception("Access Token is NULL");
      }

      final url = Uri.parse(
        '$baseUrl?type=sepay&action=make_qr&access_token=$accessToken',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'server_key': AppConstants.socialServerKey,
          'amount': amount.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['api_status'] == 200) {
          return data['data'];
        }
      }

      return null;
    } catch (e) {
      print('Error creating payment QR: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> checkPaymentStatus({
    required BuildContext context,
    required String orderCode,
  }) async {
    try {
      final auth = Provider.of<AuthController>(context, listen: false);
      final accessToken = await auth.authServiceInterface.getSocialAccessToken();

      if (accessToken == null) {
        throw Exception("Access Token is NULL");
      }

      final url = Uri.parse(
        '$baseUrl?type=sepay&action=check&order_code=$orderCode&access_token=$accessToken',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'server_key': AppConstants.socialServerKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['api_status'] == 200) {
          return data['data'];
        }
      }

      return null;
    } catch (e) {
      print('Error checking payment status: $e');
      return null;
    }
  }


  Future<Map<String, dynamic>?> getFollowingUsers({
    required BuildContext context,
    required int userId,
    int limit = 10,
  }) async {
    try {
      final auth = Provider.of<AuthController>(context, listen: false);
      final userIdStr = await auth.authServiceInterface.getSocialUserId();
      final accessToken = await auth.authServiceInterface.getSocialAccessToken();

      if (accessToken == null) {
        throw Exception("Access Token NULL");
      }

      final url = Uri.parse(
        "${baseUrl}get-friends?access_token=$accessToken",
      );

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "server_key": AppConstants.socialServerKey,
          "type": "following",
          "user_id": userId.toString(),
          "limit": limit.toString(),
        },
      );

      final result = jsonDecode(response.body);
      print("GET FOLLOWING RESPONSE: $result");

      return result;
    } catch (e) {
      print("Get Following Failed: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> sendMoney({
    required BuildContext context,
    required int amount,
    required int userId,
  }) async {
    try {
      final auth = Provider.of<AuthController>(context, listen: false);

      final accessToken = await auth.authServiceInterface.getSocialAccessToken();
      if (accessToken == null) {
        throw Exception("Access Token is NULL");
      }

      final url = Uri.parse(
        "${baseUrl}wallet?access_token=$accessToken",
      );

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "server_key": AppConstants.socialServerKey,
          "type": "send",
          "amount": amount.toString(),
          "user_id": userId.toString(),
        },
      );

      print("SEND MONEY RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }

      return null;
    } catch (e) {
      print("Send Money Error: $e");
      return null;
    }
  }

  Future<List<dynamic>?> getTransactions({
    required BuildContext context,
  }) async {
    try {
      final auth = Provider.of<AuthController>(context, listen: false);
      final accessToken = await auth.authServiceInterface.getSocialAccessToken();

      if (accessToken == null) {
        throw Exception("Access Token is NULL");
      }

      final url = Uri.parse("${baseUrl}wallet?access_token=$accessToken");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "server_key": AppConstants.socialServerKey,
          "type": "get_transactions",
        },
      );

      print("GET TRANSACTIONS RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['api_status'] == 200) {
          return data['transactions'] as List<dynamic>;
        } else {
          print("API Error: ${data['errors']}");
        }
      }

      return null;
    } catch (e) {
      print("Get Transactions Error: $e");
      return null;
    }
  }

}