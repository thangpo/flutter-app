import 'package:flutter_sixvalley_ecommerce/features/ads/domain/models/ads_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/ads/services/ads_service.dart';

class AdsRepo {
  final AdsService adsService;
  AdsRepo({required this.adsService});

  /// LẤY DANH SÁCH CHIẾN DỊCH
  Future<List<AdsModel>> fetchAds({
    required String accessToken,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final data = await adsService.fetchMyCampaigns(
        accessToken: accessToken,
        limit: limit,
        offset: offset,
      );

      return data.map((json) => AdsModel.fromJson(json)).toList();
    } catch (e) {
      print("AdsRepo fetchAds error: $e");
      return [];
    }
  }

  /// TẠO CHIẾN DỊCH MỚI
  Future<bool> createAds({
    required String accessToken,
    required Map<String, dynamic> formData,
    required String mediaPath,
  }) async {
    try {
      final response = await adsService.createCampaign(
        accessToken: accessToken,
        formData: formData,
        mediaPath: mediaPath,
      );
      return response['api_status'] == 200;
    } catch (e) {
      print("AdsRepo createAds error: $e");
      return false;
    }
  }
}