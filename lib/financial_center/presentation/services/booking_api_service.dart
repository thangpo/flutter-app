import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/logging_interceptor.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/domain/repositories/profile_repository.dart';


class BookingApiService {
  final Dio dio;
  final ProfileRepository profileRepository;

  BookingApiService({
    required this.dio,
    required this.profileRepository,
  });

  /// Khởi tạo service đầy đủ (DioClient + ProfileRepository)
  static Future<BookingApiService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final dio = Dio();
    final loggingInterceptor = LoggingInterceptor();

    final dioClient = DioClient(
      AppConstants.baseUrl,
      dio,
      loggingInterceptor: loggingInterceptor,
      sharedPreferences: prefs,
    );

    final profileRepo = ProfileRepository(
      dioClient: dioClient,
      sharedPreferences: prefs,
    );

    return BookingApiService(
      dio: dio,
      profileRepository: profileRepo,
    );
  }

  /// Lấy thông tin user profile
  Future<Map<String, dynamic>?> loadUserProfile() async {
    final response = await profileRepository.getProfileInfo();
    if (response.isSuccess) {
      return response.response.data;
    }
    return null;
  }

  /// API tỉnh
  Future<List<dynamic>> fetchProvinces() async {
    final res = await dio.get(
      'https://vnshop247.com/api/v1/shippingAPI/ghn/addressProvinceAPI',
    );
    if (res.statusCode == 200) {
      return res.data['data'] ?? [];
    }
    return [];
  }

  /// API quận/huyện
  Future<List<dynamic>> fetchDistricts(String provinceId) async {
    final res = await dio.get(
      'https://vnshop247.com/api/v1/shippingAPI/ghn/addressDistrict/$provinceId',
    );
    if (res.statusCode == 200) {
      return res.data['data']['original'] ?? [];
    }
    return [];
  }

  /// API phường/xã
  Future<List<dynamic>> fetchWards(String districtId) async {
    final res = await dio.get(
      'https://vnshop247.com/api/v1/shippingAPI/ghn/addressWard/$districtId',
    );
    if (res.statusCode == 200) {
      return res.data['data']['original'] ?? [];
    }
    return [];
  }

  /// Gửi data tạo QR SePay
  Future<Response> createSepayPayment(Map<String, dynamic> data) {
    return dio.post(
      'https://vietnamtoure.com/api/bookings/sepay/payment',
      data: data,
      options: Options(
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  /// Gửi data đặt tour thanh toán offline
  Future<Response> createOfflineBooking(Map<String, dynamic> data) {
    return dio.post(
      'https://vietnamtoure.com/api/bookings',
      data: data,
      options: Options(
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
  }
}