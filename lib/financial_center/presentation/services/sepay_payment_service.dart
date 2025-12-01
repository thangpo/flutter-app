import 'dart:convert';
import 'package:dio/dio.dart';

class SepayPaymentService {
  final Dio _dio;

  // baseUrl mặc định, bố có thể truyền khác nếu cần
  SepayPaymentService({
    Dio? dio,
    String baseUrl = 'https://vietnamtoure.com/api',
  }) : _dio = dio ??
      Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

  /// Check trạng thái booking theo order_code
  Future<Map<String, dynamic>> checkBookingStatus(String orderCode) async {
    final Response response = await _dio.get('/bookings/check/$orderCode');

    final data = response.data is String
        ? jsonDecode(response.data as String)
        : response.data as Map<String, dynamic>;

    final bookingStatus =
    (data['booking_status'] ?? '').toString().toLowerCase();

    return <String, dynamic>{
      'http_status': response.statusCode,
      'status': data['status'] == true,
      'booking_status': bookingStatus,
      'raw': data,
    };
  }

  /// Hủy booking
  Future<Response> cancelBooking(String orderCode) async {
    final Response response = await _dio.post(
      '/bookings/cancel',
      data: jsonEncode({'order_code': orderCode}),
    );
    return response;
  }
}