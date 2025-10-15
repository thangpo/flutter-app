import 'dart:convert';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/logging_interceptor.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/domain/repositories/profile_repository.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class TourOrderService {
  late ProfileRepository _profileRepository;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final dio = Dio();
    final loggingInterceptor = LoggingInterceptor();

    final dioClient = DioClient(
      AppConstants.baseUrl,
      dio,
      loggingInterceptor: loggingInterceptor,
      sharedPreferences: prefs,
    );

    _profileRepository = ProfileRepository(
      dioClient: dioClient,
      sharedPreferences: prefs,
    );
  }

  /// 🔹 Lấy danh sách đơn hàng, có thể lọc theo `status`
  Future<List<dynamic>> fetchTourOrders({String? status}) async {
    final response = await _profileRepository.getProfileInfo();

    if (!response.isSuccess) {
      throw Exception("Không lấy được thông tin người dùng");
    }

    final userData = response.response.data;
    final String? email = userData['email'];

    if (email == null || email.isEmpty) {
      throw Exception("Không tìm thấy email người dùng");
    }

    // 🔹 Body có thêm status nếu được chọn
    final body = {
      "email": email,
      if (status != null && status.isNotEmpty) "status": status,
    };

    final tourResponse = await http
        .post(
      Uri.parse('https://vietnamtoure.com/api/bookings/history-by-email'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    )
        .timeout(const Duration(seconds: 15));

    if (tourResponse.statusCode == 200) {
      final data = jsonDecode(tourResponse.body);
      if (data is Map && data.containsKey('data') && data['data'] is List) {
        return data['data'];
      } else {
        throw Exception("Dữ liệu trả về không đúng định dạng");
      }
    } else {
      throw Exception(
          "Không thể tải dữ liệu tour (mã lỗi: ${tourResponse.statusCode})");
    }
  }
}