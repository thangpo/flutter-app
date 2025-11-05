import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/ads/domain/models/ads_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/ads/domain/repos/ads_repo.dart';
import 'package:provider/provider.dart';

class AdsController extends ChangeNotifier {
  final AdsRepo adsRepo;

  AdsController({required this.adsRepo});

  bool _isLoading = false;
  List<AdsModel> _adsList = [];
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  List<AdsModel> get adsList => _adsList;
  String? get errorMessage => _errorMessage;

  /// LẤY DANH SÁCH CHIẾN DỊCH
  Future<void> loadAds({
    required BuildContext context,
    int limit = 10,
    int offset = 0,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final auth = Provider.of<AuthController>(context, listen: false);
      final accessToken = await auth.authServiceInterface.getSocialAccessToken();

      if (accessToken == null) {
        throw Exception("Chưa đăng nhập");
      }

      _adsList = await adsRepo.fetchAds(
        accessToken: accessToken,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      print("AdsController.loadAds error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// TẠO CHIẾN DỊCH MỚI
  Future<bool> createAd({
    required BuildContext context,
    required Map<String, dynamic> formData,
    required String mediaPath,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final auth = Provider.of<AuthController>(context, listen: false);
      final accessToken = await auth.authServiceInterface.getSocialAccessToken();

      if (accessToken == null) {
        throw Exception("Chưa đăng nhập");
      }

      final success = await adsRepo.createAds(
        accessToken: accessToken,
        formData: formData,
        mediaPath: mediaPath,
      );

      if (success) {
        // Tự động reload danh sách sau khi tạo
        await loadAds(context: context);
      }

      return success;
    } catch (e) {
      print("AdsController.createAd error: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// XÓA BỘ NHỚ ĐỆM
  void clear() {
    _adsList = [];
    _errorMessage = null;
    notifyListeners();
  }
}