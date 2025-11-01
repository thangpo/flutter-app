// lib/features/profile/controllers/profile_contrroller.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/response_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/domain/models/profile_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/domain/services/profile_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';

import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

// Social
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user_profile.dart';

class ProfileController extends ChangeNotifier {
  final ProfileServiceInterface? profileServiceInterface;
  ProfileController({required this.profileServiceInterface});

  ProfileModel? _userInfoModel;
  bool _isLoading = false;
  bool _isDeleting = false;
  double? _balance;
  double? loyaltyPoint = 0;
  String userID = '-1';

  bool get isDeleting => _isDeleting;
  double? get balance => _balance;
  ProfileModel? get userInfoModel => _userInfoModel;
  bool get isLoading => _isLoading;

  Future<String> getUserInfo(BuildContext context) async {
    final ApiResponseModel apiResponse =
    await profileServiceInterface!.getProfileInfo();
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      _userInfoModel = ProfileModel.fromJson(apiResponse.response!.data);
      userID = _userInfoModel!.id.toString();
      _balance = _userInfoModel?.walletBalance ?? 0;
      loyaltyPoint = _userInfoModel?.loyaltyPoint ?? 0;
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
    return userID;
  }

  Future<ApiResponseModel> deleteCustomerAccount(
      BuildContext context, int customerId) async {
    _isDeleting = true;
    notifyListeners();
    final ApiResponseModel apiResponse =
    await profileServiceInterface!.delete(customerId);
    _isDeleting = false;

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      final Map map = apiResponse.response!.data;
      final String message = map['message'];
      showCustomSnackBar(message, context, isError: false);
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }

  /// CẬP NHẬT E-COM (KHÔNG điều hướng tại đây)
  Future<ResponseModel> updateUserInfo(
      ProfileModel updateUserModel,
      String pass,
      File? file,
      String token,
      ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final http.StreamedResponse response =
      await profileServiceInterface!.updateProfile(
        updateUserModel,
        pass,
        file,
        token,
      );

      final int sc = response.statusCode;
      final bool hasBody = (response.contentLength ?? 0) > 0;
      final String body = hasBody ? await response.stream.bytesToString() : '';

      if (sc >= 200 && sc < 300) {
        String? message;
        if (body.isNotEmpty) {
          try {
            final decoded = jsonDecode(body);
            if (decoded is Map) {
              message = decoded['message'] as String?;
            }
          } catch (_) {/* ignore decode error on empty/non-json */}
        }

        _userInfoModel = updateUserModel;
        return ResponseModel(message ?? 'Updated successfully', true);
      } else {
        String? errorMessage;
        if (body.isNotEmpty) {
          try {
            final decoded = jsonDecode(body);
            if (decoded is Map) {
              errorMessage = decoded['errors']?[0]?['message'] as String?;
            }
          } catch (_) {/* ignore */}
        }
        return ResponseModel(errorMessage ?? 'HTTP $sc', false);
      }
    } catch (e) {
      return ResponseModel(e.toString(), false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  /// ĐỒNG BỘ F/L NAME (và mật khẩu nếu đủ cặp) từ E-com sang Social
  Future<void> syncEcomToSocial(
      BuildContext context, {
        ProfileModel? source, // nếu null sẽ lấy từ _userInfoModel
        String? currentPwd,
        String? newPwd,
      }) async {
    String? nz(String? s) =>
        (s != null && s.trim().isNotEmpty) ? s.trim() : null;

    try {
      final social = context.read<SocialController>();

      // Lấy Social ID hiện tại
      String? socialId = social.currentUser?.id;
      if (socialId == null || socialId.isEmpty) {
        try {
          await social.loadUserProfile();
        } catch (_) {}
        socialId = social.currentUser?.id;
      }
      socialId ??= 'me'; // fallback an toàn

      // Lấy tên từ E-com
      final String? fName = nz(source?.fName ?? _userInfoModel?.fName);
      final String? lName = nz(source?.lName ?? _userInfoModel?.lName);

      // Chỉ đồng bộ first/last name
      final edited = SocialUserProfile(
        id: socialId,
        firstName: fName,
        lastName: lName,
        displayName: null,
      );

      final String? cp = nz(currentPwd);
      final String? np = nz(newPwd);
      final bool sendPwd = (cp != null && np != null);

      await social.updateDataUserFromEdit(
        edited,
        currentPassword: sendPwd ? cp : null,
        newPassword: sendPwd ? np : null,
        ecomToken: null,
      );

      await social.loadUserProfile();
    } catch (e) {
      showCustomSnackBar('Đồng bộ sang MXH thất bại: $e', context,
          isError: true);
    }
  }

  void clearProfileData() {
    _userInfoModel = null;
    notifyListeners();
  }
}
