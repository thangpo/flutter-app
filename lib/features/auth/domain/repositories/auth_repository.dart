import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/exception/api_error_handler.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AuthRepository implements AuthRepoInterface{
  final DioClient? dioClient;
  final SharedPreferences? sharedPreferences;
  AuthRepository({required this.dioClient, required this.sharedPreferences});


  @override
  Future<ApiResponseModel> socialLogin(Map<String, dynamic>  socialLogin) async {
    try {
      Response response = await dioClient!.post(AppConstants.socialLoginUri, data: socialLogin);
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }



  @override
  Future<ApiResponseModel> registration(Map<String, dynamic> register) async {
    try {
      Response response = await dioClient!.post(AppConstants.registrationUri, data: register);
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> login(String? userInput, String? password, String? type) async {
    try {
      Response response = await dioClient!.post(AppConstants.loginUri,
        data: {"email_or_phone": userInput, "password": password, "type": type},
      );
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> verifyProfileInfo(String userInput, String token, String type) async {
    try {
      Response response = await dioClient!.post(
          AppConstants.verifyProfileInfo, data: {"email_or_phone": userInput, "token": token, "type": type});
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> firebaseAuthTokenStore(String userInput, String token) async {
    try {
      Response response = await dioClient!.post(
          AppConstants.firebaseAuthTokenStore, data: {"identity": userInput, "token": token});
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> logout() async {
    try {Response response = await dioClient!.get(AppConstants.logOut);
    return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> updateDeviceToken() async {
    try {
      String? deviceToken = await _getDeviceToken();
      FirebaseMessaging.instance.subscribeToTopic(AppConstants.topic);
      FirebaseMessaging.instance.subscribeToTopic(AppConstants.demoTopic);
      Response response = await dioClient!.post(
        AppConstants.tokenUri,
        data: {"_method": "put", 'guest_id' : Provider.of<AuthController>(Get.context!, listen: false).getGuestToken(),
          "cm_firebase_token": deviceToken},
      );
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  Future<String?> _getDeviceToken() async {
    String? deviceToken;
    if(Platform.isIOS) {
      deviceToken = await FirebaseMessaging.instance.getToken();
    }else {
      deviceToken = await FirebaseMessaging.instance.getToken();
    }
    if (deviceToken != null) {
      log('--------Device Token---------- $deviceToken--');
    }
    return deviceToken;
  }


  @override
  Future<void> saveUserToken(String token) async {
    dioClient!.updateHeader(token, null);
    try {
      await sharedPreferences!.setString(AppConstants.userLoginToken, token);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ApiResponseModel> setLanguageCode(String languageCode) async {
    try {
      final response = await dioClient!.post(AppConstants.setCurrentLanguage,
          data: {'current_language' : languageCode, '_method' : 'put'});
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  String getUserToken() {
    return sharedPreferences!.getString(AppConstants.userLoginToken) ?? "";
  }

  @override
  Future<void> saveGuestId(String guestId) async {
    try {
      await sharedPreferences!.setString(AppConstants.guestId, guestId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  String? getGuestIdToken() {
    return sharedPreferences!.getString(AppConstants.guestId) ?? "1";
  }

  @override
  bool isGuestIdExist() {
    return sharedPreferences!.containsKey(AppConstants.guestId);
  }

  @override
  Future<bool> clearGuestId() async {
    sharedPreferences!.remove(AppConstants.guestId);
    return true;
  }



  @override
  bool isLoggedIn() {
    return sharedPreferences!.containsKey(AppConstants.userLoginToken);
  }

  @override
  Future<bool> clearSharedData() async {
    sharedPreferences?.remove(AppConstants.userLoginToken);
    sharedPreferences?.remove(AppConstants.guestId);
    return true;
  }


  @override
  Future<ApiResponseModel> sendOtpToEmail(String email, String temporaryToken) async {
    try {
      Response response = await dioClient!.post(AppConstants.sendOtpToEmail,
          data: {"email": email, "temporary_token" : temporaryToken});
        return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> resendEmailOtp(String email, String temporaryToken) async {
    try {
      Response response = await dioClient!.post(AppConstants.resendEmailOtpUri,
          data: {"email": email, "temporary_token" : temporaryToken});
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> verifyEmail(String email, String token, String tempToken) async {
    try {
      Response response = await dioClient!.post(AppConstants.verifyEmailUri, data: {"email": email, "token": token,});
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }



  @override
  Future<ApiResponseModel> sendOtpToPhone(String phone, String temporaryToken) async {
    try {
      Response response = await dioClient!.post(AppConstants.sendOtpToPhone,
          data: {"phone": phone, "temporary_token" :temporaryToken});
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> resendPhoneOtp(String phone, String temporaryToken) async {
    try {
      Response response = await dioClient!.post(
          AppConstants.resendPhoneOtpUri,
          data: {"phone": phone, "temporary_token" :temporaryToken});
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> verifyPhone(String phone, String token, String otp) async {
    try {
      Response response = await dioClient!.post(
          AppConstants.verifyPhoneUri, data: {"phone": phone.trim(), "token": otp});
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> verifyOtp(String identity, String otp) async {
    try {
      Response response = await dioClient!.post(
          AppConstants.verifyOtpUri, data: {"phone": identity, "token": otp});
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> resetPassword(String identity, String otp ,String password, String confirmPassword) async {
    try {
      Response response = await dioClient!.post(
          AppConstants.resetPasswordUri, data: {"_method" : "put", "identity": identity.trim(), "otp": otp,"password": password, "confirm_password":confirmPassword});
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> firebaseAuthVerify({required String phoneNumber, required String session, required String otp, required bool isForgetPassword}) async {
    try {
      Response response = await dioClient!.post(
        AppConstants.firebaseAuthVerify,
        data: {
          'sessionInfo' : session,
          'phoneNumber' : phoneNumber,
          'code' : otp,
          'is_reset_token' : isForgetPassword ? 1 : 0,
        },
      );
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> registerWithOtp(String name, {String? email, required String phone}) async {

    try {
      Response response = await dioClient!.post(
        AppConstants.registerWithOtp,
        data: {"name": name, "email": email, "phone": phone},
      );
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }


  @override
  Future<ApiResponseModel> registerWithSocialMedia(String name, {required String email,String? phone}) async {
    try {
      Response response = await dioClient!.post(
        AppConstants.registerWithSocialMedia,
        data: {"name": name, "email": email, "phone": phone},
      );
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }


  @override
  Future<ApiResponseModel> existingAccountCheck({required String email, required int userResponse, required String medium}) async {
    try {
      Response response = await dioClient!.post(
        AppConstants.existingAccountCheck,
        data: {"email": email, "user_response": userResponse, "medium": medium},
      );
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }




  @override
  Future<void> saveUserEmailAndPassword(String userData) async {
    try {
      await sharedPreferences!.setString(AppConstants.userLogData, userData);
    } catch (e) {
      rethrow;
    }
  }

  @override
  String getUserEmail() {
    return sharedPreferences!.getString(AppConstants.userLogData) ?? "";
  }

  @override
  String getUserPassword() {
    return sharedPreferences!.getString(AppConstants.userPassword) ?? "";
  }

  @override
  Future<bool> clearUserEmailAndPassword() async {
    await sharedPreferences!.remove(AppConstants.userPassword);
    return await sharedPreferences!.remove(AppConstants.userEmail);
  }

  @override
  Future<ApiResponseModel> forgetPassword(String identity,  String type) async {

    try {
      Response response = await dioClient!.post(AppConstants.forgetPasswordUri, data: {"email_or_phone": identity, "type" : type});

      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> verifyToken(String email, String token) async {
    try {
      Response response = await dioClient!.post(AppConstants.verifyTokenUri, data: {"email_or_phone": email, "reset_token": token});
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> getGuestId() async {
    try {
      final response = await dioClient!.get(AppConstants.getGuestIdUri);
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> checkEmail(String email) async {
    try {
      Response response = await dioClient!.post(AppConstants.checkEmailUri, data: {"email": email});
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }


  @override
  Future<ApiResponseModel> checkPhone(String phone) async {
    try {
      Response response = await dioClient!.post(AppConstants.baseUrl + AppConstants.checkPhoneUri + phone, data: {"phone" : phone});
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<void> setAppleLoginEmail(String email) async {
    try {
      await sharedPreferences!.setString(AppConstants.appleLoginEmail, email);
    } catch (e) {
      rethrow;
    }
  }

  @override
  String getAppleLoginEmail() {
    return sharedPreferences!.getString(AppConstants.appleLoginEmail) ?? "";
  }

  @override
  Future<void> saveGuestCartId(String guestId) async {
    try {
      await sharedPreferences!.setString(AppConstants.guestCartId, guestId);
    } catch (e) {
      rethrow;
    }
  }


  @override
  String? getGuestCartId() {
    return sharedPreferences!.getString(AppConstants.guestCartId) ?? "-1";
  }


  @override
  Future getList({int? offset}) {
    // TODO: implement getList
    throw UnimplementedError();
  }

  @override
  Future add(value) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future delete(int id) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future get(String id) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int id) {
    // TODO: implement update
    throw UnimplementedError();
  }

}
