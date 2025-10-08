import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/interface/repo_interface.dart';

abstract class AuthRepoInterface<T> implements RepositoryInterface{

  Future<ApiResponseModel> socialLogin(Map<String, dynamic> body);

  Future<ApiResponseModel> registration(Map<String, dynamic> body);

  Future<ApiResponseModel> login(String? userInput, String? password, String? type);

  Future<ApiResponseModel> logout();

  Future<ApiResponseModel> getGuestId();

  Future<ApiResponseModel> updateDeviceToken();
  
  String getUserToken();
  
  String? getGuestIdToken();
  
  bool isGuestIdExist();
  
  bool isLoggedIn();
  
  Future<bool> clearSharedData();
  
  Future<bool> clearGuestId();
  
  String getUserEmail();
  
  String getUserPassword();
  
  Future<bool> clearUserEmailAndPassword();

  Future<void> saveUserToken(String token);

  Future<ApiResponseModel> setLanguageCode(String code);

  Future<ApiResponseModel> forgetPassword(String identity, String yout);

  Future<void> saveGuestId(String id);

  Future<ApiResponseModel> sendOtpToEmail(String email, String token);

  Future<ApiResponseModel> resendEmailOtp(String email, String token);

  Future<ApiResponseModel> verifyEmail(String email, String code, String token);

  Future<ApiResponseModel> sendOtpToPhone(String phone,  String token);

  Future<ApiResponseModel> resendPhoneOtp(String phone,  String token);

  Future<ApiResponseModel> verifyPhone(String phone,  String otp, String token);

  Future<ApiResponseModel> verifyOtp(String otp,  String identity);
  
  Future<void> saveUserEmailAndPassword(String userData);

  Future<ApiResponseModel> resetPassword(String otp,  String identity, String password, String confirmPassword);

  Future<ApiResponseModel> checkEmail(String mail);

  Future<ApiResponseModel> checkPhone(String phone);

  Future<ApiResponseModel> firebaseAuthVerify({required String phoneNumber, required String session, required String otp, required bool isForgetPassword});

  Future<ApiResponseModel> registerWithOtp(String name, {String? email, required String phone});

  Future<ApiResponseModel> registerWithSocialMedia(String name, {required String email,String? phone});

  Future<ApiResponseModel> verifyToken(String email, String token);

  Future<ApiResponseModel> existingAccountCheck({required String email, required int userResponse, required String medium});

  Future<ApiResponseModel> verifyProfileInfo(String userInput, String token, String type);

  Future<ApiResponseModel> firebaseAuthTokenStore(String userInput, String token);

  Future<void> setAppleLoginEmail(String email);

  String getAppleLoginEmail();

  Future<void> saveGuestCartId(String id);

  String? getGuestCartId();

}