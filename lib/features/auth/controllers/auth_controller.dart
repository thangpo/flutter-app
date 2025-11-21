import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/domain/models/register_model.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/error_response.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/response_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/domain/models/signup_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/domain/models/social_login_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/domain/models/user_log_data.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/domain/services/auth_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/enums/from_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/login_screen.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/otp_registration_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/otp_verification_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/reset_password_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/domain/models/profile_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/helper/country_code_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/app_localization.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/helper/app_globals.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_notifications_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/controllers/localization_controller.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/firebase_token_updater.dart';

class AuthController with ChangeNotifier {
  final AuthServiceInterface authServiceInterface;
  AuthController({required this.authServiceInterface});

  bool _isLoading = false;
  bool? _isRemember = false;

  bool _isAcceptTerms = false;
  bool get isAcceptTerms => _isAcceptTerms;

  bool _isNumberLogin = false;
  bool get isNumberLogin => _isNumberLogin;

  bool _isNumberLoginScreenText = false;
  bool get isNumberLoginScreenText => _isNumberLoginScreenText;

  bool _isActiveRememberMe = false;
  bool get isActiveRememberMe => _isActiveRememberMe;

  String? _loginErrorMessage = '';
  String? get loginErrorMessage => _loginErrorMessage;

  set setIsLoading(bool value) => _isLoading = value;
  set setIsPhoneVerificationButttonLoading(bool value) =>
      _isPhoneNumberVerificationButtonLoading = value;

  bool _resendButtonLoading = false;
  bool get resendButtonLoading => _resendButtonLoading;

  bool _sendToEmail = false;
  bool get sendToEmail => _sendToEmail;

  String? _verificationMsg = '';
  String? get verificationMessage => _verificationMsg;

  bool _isForgotPasswordLoading = false;
  bool get isForgotPasswordLoading => _isForgotPasswordLoading;
  set setForgetPasswordLoading(bool value) => _isForgotPasswordLoading = value;

  String countryDialCode = '+880';
  void setCountryCode(String countryCode, {bool notify = true}) {
    countryDialCode = countryCode;
    if (notify) {
      notifyListeners();
    }
  }

  String? _verificationID = '';
  String? get verificationID => _verificationID;

  bool get isLoading => _isLoading;
  bool? get isRemember => _isRemember;

  void updateRemember() {
    _isRemember = !_isRemember!;
    notifyListeners();
  }

  Future<void> socialLogin(
      SocialLoginModel socialLogin, Function callback) async {
    _isLoading = true;
    notifyListeners();

    ApiResponseModel apiResponse =
        await authServiceInterface.socialLogin(socialLogin.toJson());
    if (apiResponse.response != null &&
        apiResponse.response?.statusCode == 200) {
      final CustomerVerification? customerVerification =
          Provider.of<SplashController>(Get.context!, listen: false)
              .configModel!
              .customerVerification;

      _isLoading = false;
      Map map = apiResponse.response!.data;

      String? message = '',
          token = '',
          temporaryToken = '',
          email = '',
          phone = '';
      ProfileModel? profileModel;
      bool isPhoneVerified = false;
      bool isMailVerified = false;

      try {
        message = map['error_message'];
        token = map['token'];
        temporaryToken = map['temp_token'];
        if (map["user"] != null) {
          email = map["user"]["email"];
          phone = map["user"]["phone"];
          isPhoneVerified = map["user"]["is_phone_verified"] ?? false;
          isMailVerified = map["user"]["is_email_verified"] ?? false;
        }
      } catch (e) {
        message = null;
        token = null;
        temporaryToken = null;
      }

      if (token != null) {
        authServiceInterface.saveUserToken(token);
        await authServiceInterface.updateDeviceToken();
        setCurrentLanguage(
            Provider.of<LocalizationController>(Get.context!, listen: false)
                    .getCurrentLanguage() ??
                'en');
      }

      if (map.containsKey('user')) {
        try {
          profileModel = ProfileModel.fromJson(map['user']);
          callback(true, null, null, profileModel, message, socialLogin.medium,
              null, socialLogin.email, socialLogin.name);
        } catch (e) {
          if (kDebugMode) {
            print('----------$e------------');
          }
        }
      }

      if (token != null && token.isNotEmpty) {
        authServiceInterface.saveUserToken(token);
        await authServiceInterface.updateDeviceToken();
        setCurrentLanguage(
            Provider.of<LocalizationController>(Get.context!, listen: false)
                    .getCurrentLanguage() ??
                'en');
        callback(true, token, null, null, message, socialLogin.medium, null,
            socialLogin.email, socialLogin.name);
      }

      if (temporaryToken != null && temporaryToken.isNotEmpty) {
        callback(true, null, temporaryToken, null, message, socialLogin.medium,
            null, socialLogin.email, socialLogin.name);
      }

      if (phone != null &&
          phone.isNotEmpty &&
          !isPhoneVerified &&
          (customerVerification?.phone == 1 ||
              customerVerification?.firebase == 1)) {
        callback(true, null, null, null, message, socialLogin.medium, phone,
            socialLogin.email, socialLogin.name);
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    _isLoading = false;
    notifyListeners();
  }

  // Future<String> onConfigurationAppleEmail(
  //     AuthorizationCredentialAppleID credential) async {
  //   final email = credential.email;
  //
  //   if (email != null && email.isNotEmpty && email != 'null') {
  //     await authServiceInterface.setAppleLoginEmail(email);
  //     return email;
  //   }
  //
  //   return authServiceInterface.getAppleLoginEmail();
  // }

  Future registration(
      RegisterModel register, Function callback, ConfigModel config) async {
    _isLoading = true;
    notifyListeners();
    ApiResponseModel apiResponse =
        await authServiceInterface.registration(register.toJson());

    _isLoading = false;
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      Map map = apiResponse.response!.data;
      String? tempToken = '', token = '', message = '';

      if (map.containsKey('temporary_token')) {
        tempToken = map["temporary_token"];
      } else if (map.containsKey('token')) {
        token = map["token"];
      }

      // ========== EXTERNAL SOCIAL CREATE-ACCOUNT ==========
      final String _email = register.email ?? '';
      final String _password = register.password ?? '';
      final String _username = _email.contains('@')
          ? _email.split('@').first
          : (register.fName ?? 'user');
      final String? _firstName = register.fName;
      final String? _lastName = register.lName;

      // Gọi API Social (multipart/form-data)
      final ApiResponseModel socialResp =
          await authServiceInterface.socialCreateAccount(
        username: _username,
        password: _password,
        email: _email,
        confirmPassword: _password,
        serverKey: AppConstants.socialServerKey,
        firstName: _firstName,
        lastName: _lastName,
      );

      // 1) Không có HTTP response (mạng/transport lỗi)
      if (socialResp.response == null) {
        _isLoading = false;
        notifyListeners();
        ApiChecker.checkApi(socialResp);
        return;
      }

      // 2) HTTP status != 200
      if (socialResp.response!.statusCode != 200) {
        _isLoading = false;
        notifyListeners();
        ApiChecker.checkApi(socialResp);
        return;
      }

      // 3) Kiểm tra api_status: có thể là int 200 hoặc string '200'
      final data = socialResp.response!.data;
      dynamic status = (data is Map) ? data['api_status'] : null;
      final bool isOk = status == 200 || status == '200';

      if (!isOk) {
        _isLoading = false;
        notifyListeners();

        // Thử lấy lỗi chi tiết từ errors.error_text nếu có
        String? errText;
        if (data is Map && data['errors'] is Map) {
          final errs = data['errors'] as Map;
          final et = errs['error_text'];
          if (et != null) errText = et.toString();
        }

        if (errText != null && errText.isNotEmpty) {
          // Nếu bạn muốn dùng snack bar trực tiếp:
          // showCustomSnackBar(errText);
          // Hoặc gói lại vào ApiChecker tạm thời:
          showCustomSnackBar(errText, Get.context!,
              isError:
                  true); // nếu bạn có hàm tiện ích; nếu không, dùng showCustomSnackBar
        } else {
          ApiChecker.checkApi(socialResp);
        }
        return;
      }

      // 4) Lấy access_token (bắt buộc phải có)
      final String accessToken = (data['access_token'] ?? '').toString();
      if (accessToken.isEmpty) {
        _isLoading = false;
        notifyListeners();
        showCustomSnackBar(
          getTranslated('social_missing_access_token', Get.context!) ??
              'Social create account failed: missing access_token',
          Get.context!,
          isError: true,
        );
        // ApiChecker.checkApi(socialResp);
        return;
      }

      // 5) Lưu token Social, tiếp tục flow chính
      await authServiceInterface.saveSocialAccessToken(accessToken);
      final String socialUserId = (data['user_id'] ?? '').toString();
      if (socialUserId.isNotEmpty) {
        await authServiceInterface.saveSocialUserId(socialUserId);
      }
      try {
        await Provider.of<SocialController>(Get.context!, listen: false)
            .loadCurrentUser(force: true);
      } catch (_) {}
      // 🔴 CẬP NHẬT FCM TOKEN CHO USER SOCIAL VỪA ĐĂNG KÝ
      try {
        await FirebaseTokenUpdater.update();
      } catch (e) {
        debugPrint('[FCM] update after social registration failed: $e');
      }
      // ========== END EXTERNAL CALL ==========

      Future<void> saveSocialUserId(String userId) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('social_user_id', userId);
      }

      Future<String?> getSocialUserId() async {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString('social_user_id');
      }

      message = map["message"];

      if (token != null && token.isNotEmpty) {
        authServiceInterface.saveUserToken(token);
        await authServiceInterface.updateDeviceToken();
        Navigator.pushAndRemoveUntil(
            Get.context!,
            MaterialPageRoute(builder: (_) => const DashBoardScreen()),
            (route) => false);
      } else if (tempToken != null && tempToken.isNotEmpty) {
        String type;
        if (config.customerVerification?.firebase == 1) {
          type = 'phone';
        } else if (config.customerVerification?.phone == 1) {
          type = 'phone';
        } else {
          type = 'email';
        }
        sendVerificationCode(
            config, SignUpModel(email: register.email, phone: register.phone),
            type: type, fromPage: FromPage.login);
      }
      notifyListeners();
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }

  Future logOut() async {
    ApiResponseModel apiResponse = await authServiceInterface.logout();
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      // ========== EXTERNAL SOCIAL LOGOUT ==========
      try {
        final token = await authServiceInterface.getSocialAccessToken();
        if (token != null && token.isNotEmpty) {
          final ApiResponseModel sResp =
              await authServiceInterface.socialLogout(accessToken: token);
          // Tuỳ chọn: Nếu muốn "fail chung" cả logout khi Social lỗi, bỏ comment block dưới.

          if (sResp.response == null || sResp.response!.statusCode != 200) {
            _isLoading = false;
            notifyListeners();
            ApiChecker.checkApi(sResp);
            return;
          }
          final data = sResp.response!.data;
          final st = (data is Map) ? data['api_status'] : null;
          final bool ok = st == 200 || st == '200';
          if (!ok) {
            _isLoading = false;
            notifyListeners();
            String? errText;
            if (data is Map && data['errors'] is Map) {
              errText = (data['errors']['error_text'])?.toString();
            }
            if (errText != null && errText.isNotEmpty) {
              showCustomSnackBar(errText, Get.context!, isError: true);
            } else {
              ApiChecker.checkApi(sResp);
            }
            return;
          }
        }
      } catch (_) {
        // Mặc định: không chặn logout app nếu Social lỗi.
        showCustomSnackBar('Social logout failed', Get.context!, isError: true);
      } finally {
        await authServiceInterface.clearSocialAccessToken();
        await authServiceInterface.clearSocialUserId();
        try {
          Provider.of<SocialController>(Get.context!, listen: false)
              .clearAuthState();
        } catch (_) {}
      }
      // ========== END EXTERNAL SOCIAL LOGOUT ==========

      await authServiceInterface.clearSharedData();
      Provider.of<SocialNotificationsController>(Get.context!, listen: false)
          .reset();
      // Nếu có ProfileController thì clear luôn
      // Get.find<ProfileController>().clearProfileData();
    }
  }

  Future<void> setCurrentLanguage(String currentLanguage) async {
    ApiResponseModel apiResponse =
        await authServiceInterface.setLanguageCode(currentLanguage);
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
    } else {
      ApiChecker.checkApi(apiResponse);
    }
  }

  Future<ResponseModel> login(String? userInput, String? password, String? type,
      FromPage? fromPage) async {
    _isLoading = true;
    _loginErrorMessage = '';
    notifyListeners();

    String? type0 = type;
    String? userInputData = userInput;

    ApiResponseModel apiResponse =
        await authServiceInterface.login(userInput, password, type0);

    ResponseModel responseModel;
    _isLoading = false;
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      final ConfigModel config =
          Provider.of<SplashController>(Get.context!, listen: false)
              .configModel!;
      clearGuestId();
      Map map = apiResponse.response!.data;

      String? temporaryToken = '', token = '', message = '', email, phone;
      bool isPhoneVerified = false;
      bool isMailVerified = false;

      try {
        message = map["message"];
        token = map["token"];
        temporaryToken = map["temporary_token"];
        email = map["email"];
        phone = map["phone"];
        isPhoneVerified = map["is_phone_verified"] ?? false;
        isMailVerified = map["is_email_verified"] ?? false;
      } catch (e) {
        message = null;
        token = null;
        temporaryToken = null;
      }

      if (isPhoneVerified &&
          !isMailVerified &&
          config.customerVerification?.phone == 0 &&
          config.customerVerification?.email == 1 &&
          email != null) {
        type0 = 'email';
        userInputData = email;
      }

      if (!isPhoneVerified &&
          isMailVerified &&
          config.customerVerification?.phone == 1 &&
          config.customerVerification?.email == 0 &&
          phone != null) {
        type0 = 'phone';
        userInputData = phone;
      }

      if (!isPhoneVerified &&
          !isMailVerified &&
          config.customerVerification?.phone == 0 &&
          config.customerVerification?.email == 1 &&
          email != null) {
        type0 = 'email';
        userInputData = email;
      }

      if (!isPhoneVerified &&
          !isMailVerified &&
          config.customerVerification?.phone == 1 &&
          config.customerVerification?.email == 0 &&
          phone != null) {
        type0 = 'phone';
        userInputData = phone;
      }

      // ========== EXTERNAL SOCIAL AUTH (LOGIN) ==========
      // Lấy username & password để gọi Social:
      // - Ưu tiên userInputData (email/username user nhập)
      // - Nếu cần, có thể map email thành username tuỳ backend; ở đây dùng nguyên vẹn.
      final String _socialUsername =
          (userInputData ?? userInput ?? '').toString();
      final String _socialPassword = (password ?? '').toString();

      final ApiResponseModel socialResp =
          await authServiceInterface.socialWoLogin(
        username: _socialUsername,
        password: _socialPassword,
        serverKey: AppConstants.socialServerKey,
        // timezone: DateTime.now().timeZoneName,     // (tuỳ chọn)
        // deviceId: oneSignalId,                     // (tuỳ chọn)
      );
      print('[SOCIAL LOGIN DEBUG] body: ${socialResp.response?.data}');
      // 1) Không có HTTP response hoặc status != 200
      if (socialResp.response == null ||
          socialResp.response!.statusCode != 200) {
        _isLoading = false;
        notifyListeners();
        ApiChecker.checkApi(socialResp);
        return ResponseModel(apiResponse.error, false);
      }

      // 2) Kiểm tra api_status trong body: 200 hoặc '200'
      final data = socialResp.response!.data;
      final status = (data is Map) ? data['api_status'] : null;
      final bool ok = status == 200 || status == '200';
      if (!ok) {
        _isLoading = false;
        notifyListeners();

        String? errText;
        if (data is Map && data['errors'] is Map) {
          errText = (data['errors']['error_text'])?.toString();
        }
        if (errText != null && errText.isNotEmpty) {
          showCustomSnackBar(errText, Get.context!, isError: true);
        } else {
          ApiChecker.checkApi(socialResp);
        }
        return ResponseModel(apiResponse.error, false);
      }

      // 3) Lấy access_token Social (bắt buộc)
      final String socialAccessToken = (data['access_token'] ?? '').toString();
      if (socialAccessToken.isEmpty) {
        _isLoading = false;
        notifyListeners();
        showCustomSnackBar(
            'Social login failed: missing access_token', Get.context!,
            isError: true);
        return ResponseModel(apiResponse.error, false);
      }

      // 4) Lưu access_token Social
      await authServiceInterface.saveSocialAccessToken(socialAccessToken);
      final String socialUserId = (data['user_id'] ?? '').toString();
      if (socialUserId.isNotEmpty) {
        await authServiceInterface.saveSocialUserId(socialUserId);
      }
      try {
        await Provider.of<SocialController>(Get.context!, listen: false)
            .loadCurrentUser(force: true);
      } catch (_) {}
      // 🔴 CẬP NHẬT FCM TOKEN CHO USER SOCIAL VỪA LOGIN
      try {
        await FirebaseTokenUpdater.update();
      } catch (e) {
        debugPrint('[FCM] update after social login failed: $e');
      }
      // ========== END EXTERNAL SOCIAL AUTH ==========
      if (token != null && token.isNotEmpty) {
        authServiceInterface.saveUserToken(token);
        await authServiceInterface.updateDeviceToken();
      } else if (temporaryToken != null) {
        await sendVerificationCode(
            Provider.of<SplashController>(Get.context!, listen: false)
                .configModel!,
            SignUpModel(email: userInputData, phone: userInputData),
            type: type0,
            fromPage: fromPage);
      }

      responseModel = ResponseModel('verification', token != null);
      // callback(true, token, temporaryToken, message);
      notifyListeners();
    } else {
      notifyListeners();
      responseModel = ResponseModel(apiResponse.error, false);
      ApiChecker.checkApi(apiResponse);
    }

    _isLoading = false;
    notifyListeners();
    return responseModel;
  }

  Future<void> updateToken(BuildContext context) async {
    ApiResponseModel apiResponse =
        await authServiceInterface.updateDeviceToken();
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
    } else {
      ApiChecker.checkApi(apiResponse);
    }
  }

  Future<ApiResponseModel> sendOtpToEmail(String email, String temporaryToken,
      {bool resendOtp = false}) async {
    _isPhoneNumberVerificationButtonLoading = true;
    notifyListeners();
    ApiResponseModel apiResponse;
    if (resendOtp) {
      apiResponse =
          await authServiceInterface.resendEmailOtp(email, temporaryToken);
    } else {
      apiResponse =
          await authServiceInterface.sendOtpToEmail(email, temporaryToken);
    }
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      resendTime = (apiResponse.response!.data["resend_time"]);
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }

  Future<void> sendVerificationCode(ConfigModel config, SignUpModel signUpModel,
      {String? type, FromPage? fromPage, bool isResend = false}) async {
    _resendButtonLoading = true;
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    if (config.customerVerification!.status == 1) {
      if (type == 'email' && config.customerVerification?.email == 1) {
        await checkEmail(signUpModel.email!, fromPage);
      } else if (type == 'phone' &&
          config.customerVerification?.firebase == 1) {
        await firebaseVerifyPhoneNumber(signUpModel.phone!, fromPage!,
            isResend: isResend);
      } else if (type == 'phone' && config.customerVerification?.phone == 1) {
        await checkPhone(signUpModel.phone!, fromPage);
      }
    }
    _resendButtonLoading = false;
    notifyListeners();
  }

  Future<ResponseModel> checkEmail(String email, FromPage? fromPage) async {
    _isPhoneNumberVerificationButtonLoading = true;
    _resendButtonLoading = true;

    _verificationMsg = '';
    notifyListeners();
    ApiResponseModel apiResponse = await authServiceInterface.checkEmail(email);

    ResponseModel responseModel;

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      responseModel = ResponseModel(apiResponse.response!.data["token"], true);

      bool callRoute = fromPage != FromPage.verification;

      if (fromPage != null &&
          (fromPage == FromPage.profile || fromPage == FromPage.login)) {
        if (callRoute) {
          Navigator.push(
              Get.context!,
              MaterialPageRoute(
                  builder: (_) => VerificationScreen(email, fromPage)));
        }
      }
    } else {
      _verificationMsg = ApiChecker.getError(apiResponse).errors![0].message;
      showCustomSnackBar(_verificationMsg, Get.context!);
      responseModel = ResponseModel(_verificationMsg, false);
    }
    _isPhoneNumberVerificationButtonLoading = false;
    _resendButtonLoading = false;
    notifyListeners();

    return responseModel;
  }

  Future<void> firebaseVerifyPhoneNumber(String phoneNumber, FromPage fromPage,
      {bool isForgetPassword = false, bool isResend = false}) async {
    if (!isResend) {
      _isPhoneNumberVerificationButtonLoading = true;
    }
    _resendButtonLoading = true;
    notifyListeners();

    String? vID;

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        _isPhoneNumberVerificationButtonLoading = false;
        notifyListeners();

        // Navigator.of(Get.context!).pop();

        if (e.code == 'invalid-phone-number') {
          showCustomSnackBar(
              getTranslated('please_submit_a_valid_phone_number', Get.context!),
              Get.context!);
        } else {
          showCustomSnackBar(
              getTranslated('${e.message}'.replaceAll('_', ' ').toCapitalized(),
                  Get.context!),
              Get.context!);
        }
      },
      codeSent: (String vId, int? resendToken) async {
        _isPhoneNumberVerificationButtonLoading = false;
        _resendButtonLoading = false;
        notifyListeners();

        bool callRoute = fromPage != FromPage.verification;

        await callFirebaseStoretiken(phoneNumber, vId);

        _verificationID = vId;

        if (fromPage == FromPage.verification) {
          showCustomSnackBar(
              getTranslated('resend_code_successful', Get.context!),
              Get.context!,
              isError: false);
        }

        if (callRoute) {
          Navigator.push(
              Get.context!,
              MaterialPageRoute(
                  builder: (_) =>
                      VerificationScreen(phoneNumber, fromPage, session: vId)));
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _resendButtonLoading = false;
      },
    );

    //await Future.delayed(Duration(seconds: 10));

    _resendButtonLoading = false;
    notifyListeners();
  }

  Future<void> callFirebaseStoretiken(String phoneNumber, String vID) async {
    ApiResponseModel apiResponse = await authServiceInterface
        .firebaseAuthTokenStore(userInput: phoneNumber, token: vID);
  }

  Future<ResponseModel> checkPhoneForOtp(
      String phone, FromPage fromPage) async {
    _isPhoneNumberVerificationButtonLoading = true;
    _verificationMsg = '';
    notifyListeners();
    ApiResponseModel apiResponse = await authServiceInterface.checkPhone(phone);
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    ResponseModel responseModel;
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      responseModel = ResponseModel(apiResponse.response!.data["token"], true);

      bool callRoute = fromPage != FromPage.verification;

      if (callRoute && apiResponse.response!.data["token"] != 'inactive') {
        Navigator.push(
            Get.context!,
            MaterialPageRoute(
                builder: (_) => VerificationScreen(phone, fromPage)));
      } else {
        showCustomSnackBar(apiResponse.response!.data["message"], Get.context!);
      }
    } else {
      _verificationMsg = ApiChecker.getError(apiResponse).errors![0].message;
      showCustomSnackBar(_verificationMsg, Get.context!);
      responseModel = ResponseModel(_verificationMsg, false);
    }
    notifyListeners();
    return responseModel;
  }

  Future<ResponseModel> checkPhone(String phone, FromPage? fromPage) async {
    _isPhoneNumberVerificationButtonLoading = true;
    _verificationMsg = '';
    notifyListeners();
    ApiResponseModel apiResponse = await authServiceInterface.checkPhone(phone);
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    ResponseModel responseModel;
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      responseModel = ResponseModel(apiResponse.response!.data["token"], true);

      bool callRoute = fromPage != FromPage.verification;

      if (callRoute) {
        Navigator.push(
            Get.context!,
            MaterialPageRoute(
                builder: (_) => VerificationScreen(phone, fromPage!)));
      }
    } else {
      _verificationMsg = ApiChecker.getError(apiResponse).errors![0].message;
      showCustomSnackBar(_verificationMsg, Get.context!);
      responseModel = ResponseModel(_verificationMsg, false);
    }
    notifyListeners();
    return responseModel;
  }

  Future<ResponseModel> verifyEmail(String email) async {
    _isPhoneNumberVerificationButtonLoading = true;
    _verificationMsg = '';
    notifyListeners();
    ApiResponseModel apiResponse =
        await authServiceInterface.verifyEmail(email, _verificationCode, '');

    notifyListeners();
    ResponseModel responseModel;
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      String token = apiResponse.response!.data["token"];
      await authServiceInterface.saveUserToken(token);
      await authServiceInterface.updateDeviceToken();
      // final ProfileProvider profileProvider = Provider.of<ProfileProvider>(Get.context!, listen: false);
      // profileProvider.getUserInfo(true);
      responseModel =
          ResponseModel(apiResponse.response!.data["message"], true);
    } else {
      _verificationMsg = ApiChecker.getError(apiResponse).errors![0].message;
      showCustomSnackBar(_verificationMsg, Get.context!);
      responseModel = ResponseModel(_verificationMsg, false);
    }
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    return responseModel;
  }

  Future<void> firebaseOtpLogin(
      {required String phoneNumber,
      required String session,
      required String otp,
      bool isForgetPassword = false}) async {
    _isPhoneNumberVerificationButtonLoading = true;
    notifyListeners();
    ApiResponseModel apiResponse =
        await authServiceInterface.firebaseAuthVerify(
      session: session,
      phoneNumber: phoneNumber,
      otp: otp,
      isForgetPassword: isForgetPassword,
    );

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      Map map = apiResponse.response!.data;
      String? token;
      String? tempToken;

      try {
        token = map["token"];
        tempToken = map["temp_token"];
      } catch (error) {
        log('$error');
      }

      if (isForgetPassword) {
        Navigator.push(
            Get.context!,
            MaterialPageRoute(
                builder: (_) =>
                    ResetPasswordScreen(mobileNumber: phoneNumber, otp: otp)));
      } else {
        String countryCode =
            CountryCodeHelper.getCountryCode(phoneNumber ?? '')!;
        saveUserEmailAndPassword(UserLogData(
            countryCode: countryCode,
            phoneNumber:
                CountryCodeHelper.extractPhoneNumber(countryCode, phoneNumber),
            email: null,
            password: null));
        if (token != null) {
          await authServiceInterface.saveUserToken(token);
          await authServiceInterface.updateDeviceToken();
          Navigator.pushAndRemoveUntil(
              Get.context!,
              MaterialPageRoute(builder: (_) => const DashBoardScreen()),
              (route) => false);
        } else if (tempToken != null) {
          Navigator.push(
              Get.context!,
              MaterialPageRoute(
                  builder: (_) => OtpRegistrationScreen(
                      tempToken: tempToken ?? '', userInput: phoneNumber)));
        }
      }
    } else {
      ApiChecker.checkApi(apiResponse, firebaseResponse: true);
    }

    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
  }

  Future<ResponseModel> registerWithOtp(String name,
      {String? email, required String phone}) async {
    _isPhoneNumberVerificationButtonLoading = true;
    _loginErrorMessage = '';
    notifyListeners();
    ApiResponseModel apiResponse = await authServiceInterface
        .registerWithOtp(name, email: email, phone: phone);
    ResponseModel responseModel;
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      String? token;
      Map map = apiResponse.response!.data;
      if (map.containsKey('token')) {
        token = map["token"];
      }
      if (token != null) {
        await authServiceInterface.saveUserToken(token);
      }
      responseModel = ResponseModel('verification', token != null);
    } else {
      _loginErrorMessage = ApiChecker.getError(apiResponse).errors![0].message;
      showCustomSnackBar(_loginErrorMessage, Get.context!);
      responseModel = ResponseModel(_loginErrorMessage, false);
    }
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    return responseModel;
  }

  Future<(ResponseModel?, String?)> verifyPhoneForOtp(String phone) async {
    _isPhoneNumberVerificationButtonLoading = true;
    String phoneNumber = phone;
    if (phone.contains('++')) {
      phoneNumber = phone.replaceAll('++', '+');
    }
    _verificationMsg = '';
    notifyListeners();
    ApiResponseModel apiResponse =
        await authServiceInterface.verifyOtp(phoneNumber, _verificationCode);
    notifyListeners();
    ResponseModel? responseModel;
    String? token;
    String? tempToken;
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      Map map = apiResponse.response!.data;
      if (map.containsKey('temporary_token')) {
        tempToken = map["temporary_token"];
      } else if (map.containsKey('token')) {
        token = map["token"];
      }

      if (token != null) {
        await authServiceInterface.saveUserToken(token);
        responseModel = ResponseModel('verification', true);
      } else if (tempToken != null) {
        responseModel = ResponseModel('verification', true);
      }
    } else {
      _verificationMsg = ApiChecker.getError(apiResponse).errors![0].message;
      showCustomSnackBar(_verificationMsg, Get.context!);
      responseModel = ResponseModel(_verificationMsg, false);
    }
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    return (responseModel, tempToken);
  }

  Future<(ResponseModel, String?)> registerWithSocialMedia(String name,
      {required String email, String? phone}) async {
    _isPhoneNumberVerificationButtonLoading = true;
    _loginErrorMessage = '';
    notifyListeners();
    ApiResponseModel apiResponse = await authServiceInterface
        .registerWithSocialMedia(name, email: email, phone: phone);
    ResponseModel responseModel;
    String? token;
    String? tempToken;

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      Map map = apiResponse.response!.data;
      if (map.containsKey('token')) {
        token = map["token"];
      }
      if (map.containsKey('temp_token')) {
        tempToken = map["temp_token"];
      }

      if (token != null) {
        authServiceInterface.saveUserToken(token);
        responseModel = ResponseModel('verification', true);
      } else if (tempToken != null) {
        responseModel = ResponseModel('verification', true);
      } else {
        responseModel = ResponseModel('', false);
      }
    } else {
      _loginErrorMessage = ApiChecker.getError(apiResponse).errors![0].message;
      showCustomSnackBar(_loginErrorMessage, Get.context!);
      responseModel = ResponseModel(_loginErrorMessage, false);
    }
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    return (responseModel, tempToken);
  }

  int resendTime = 0;

  Future<ResponseModel> sendOtpToPhone(String phone, String temporaryToken,
      {bool fromResend = false}) async {
    _isPhoneNumberVerificationButtonLoading = true;
    notifyListeners();
    ApiResponseModel apiResponse;
    if (fromResend) {
      apiResponse =
          await authServiceInterface.resendPhoneOtp(phone, temporaryToken);
    } else {
      apiResponse =
          await authServiceInterface.sendOtpToPhone(phone, temporaryToken);
    }
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    ResponseModel responseModel;
    if (apiResponse.response != null &&
        apiResponse.response?.statusCode == 200) {
      responseModel = ResponseModel(apiResponse.response!.data["token"], true);
      // resendTime = (apiResponse.response!.data["resend_time"]);
    } else {
      String? errorMessage;
      if (apiResponse.error is String) {
        errorMessage = apiResponse.error.toString();
      } else {
        ErrorResponse errorResponse = apiResponse.error;
        errorMessage = errorResponse.errors![0].message;
      }
      responseModel = ResponseModel(errorMessage, false);
    }
    notifyListeners();
    return responseModel;
  }

  Future<ResponseModel> verifyProfileInfo(String userInput, String type) async {
    _isPhoneNumberVerificationButtonLoading = true;
    _verificationMsg = '';
    notifyListeners();
    ApiResponseModel apiResponse = await authServiceInterface.verifyProfileInfo(
        userInput: userInput, token: _verificationCode, type: type);
    ResponseModel? responseModel;
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      final ProfileController profileProvider =
          Provider.of<ProfileController>(Get.context!, listen: false);
      profileProvider.getUserInfo(Get.context!);
      showCustomSnackBar(apiResponse.response!.data['message'], Get.context!,
          isError: false);
      responseModel = ResponseModel('verification', true);
    } else {
      _verificationMsg = ApiChecker.getError(apiResponse).errors![0].message;
      showCustomSnackBar(_verificationMsg, Get.context!);
      responseModel = ResponseModel(_verificationMsg, false);
    }
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    return (responseModel);
  }

  Future<ResponseModel> verifyPhone(String phone, String token) async {
    _isPhoneNumberVerificationButtonLoading = true;
    String phoneNumber = phone;
    if (phone.contains('++')) {
      phoneNumber = phone.replaceAll('++', '+');
    }
    _verificationMsg = '';
    notifyListeners();

    ApiResponseModel apiResponse = await authServiceInterface.verifyPhone(
        phoneNumber, token, _verificationCode);
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    ResponseModel responseModel;
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      responseModel =
          ResponseModel(apiResponse.response!.data["message"], true);
      String token = apiResponse.response!.data["token"];
      await authServiceInterface.saveUserToken(token);
      await authServiceInterface.updateDeviceToken();
    } else {
      _verificationMsg = ApiChecker.getError(apiResponse).errors![0].message;
      showCustomSnackBar(_verificationMsg, Get.context!, isError: true);
      responseModel = ResponseModel(_verificationMsg, false);
    }

    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    return responseModel;
  }

  Future<ApiResponseModel> verifyOtpForResetPassword(String phone) async {
    _isPhoneNumberVerificationButtonLoading = true;
    notifyListeners();

    ApiResponseModel apiResponse =
        await authServiceInterface.verifyOtp(phone, _verificationCode);
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
    } else {
      _isPhoneNumberVerificationButtonLoading = false;
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }

  Future<ApiResponseModel> resetPassword(String identity, String otp,
      String password, String confirmPassword) async {
    _isPhoneNumberVerificationButtonLoading = true;
    notifyListeners();
    ApiResponseModel apiResponse = await authServiceInterface.resetPassword(
        identity, otp, password, confirmPassword);
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      showCustomSnackBar(
          getTranslated('password_reset_successfully', Get.context!),
          Get.context!,
          isError: false);
      Navigator.pushAndRemoveUntil(
          Get.context!,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false);
    } else {
      _isPhoneNumberVerificationButtonLoading = false;
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }

  // for phone verification
  bool _isPhoneNumberVerificationButtonLoading = false;
  bool get isPhoneNumberVerificationButtonLoading =>
      _isPhoneNumberVerificationButtonLoading;
  String _email = '';
  String _phone = '';

  String get email => _email;
  String get phone => _phone;

  void updateEmail(String email) {
    _email = email;
    notifyListeners();
  }

  void updatePhone(String phone) {
    _phone = phone;
    notifyListeners();
  }

  String _verificationCode = '';
  String get verificationCode => _verificationCode;
  bool _isEnableVerificationCode = false;
  bool get isEnableVerificationCode => _isEnableVerificationCode;

  void updateVerificationCode(String query) {
    if (query.length == 6) {
      _isEnableVerificationCode = true;
    } else {
      _isEnableVerificationCode = false;
    }
    _verificationCode = query;
    notifyListeners();
  }

  String getUserToken() {
    return authServiceInterface.getUserToken();
  }

  String? getGuestToken() {
    return authServiceInterface.getGuestIdToken();
  }

  bool isLoggedIn() {
    return authServiceInterface.isLoggedIn();
  }

  bool isGuestIdExist() {
    return authServiceInterface.isGuestIdExist();
  }

  @override
  Future<bool> clearSharedData() async {
    final prefs = await SharedPreferences.getInstance();
    String? rawUserData = prefs.getString('user_email');
    UserLogData? oldUser;
    if (rawUserData != null) {
      try {
        oldUser = UserLogData.fromJson(jsonDecode(rawUserData));
      } catch (_) {}
    }

    await prefs.clear();

    if (oldUser != null &&
        (oldUser.email != null || oldUser.phoneNumber != null)) {
      final keepUser = UserLogData(
        email: oldUser.email,
        phoneNumber: oldUser.phoneNumber,
        countryCode: oldUser.countryCode,
        password: null,
      );
      await prefs.setString('user_email', jsonEncode(keepUser.toJson()));
    }

    return true;
  }

  Future<bool> clearGuestId() async {
    return await authServiceInterface.clearGuestId();
  }

  void saveUserEmailAndPassword(UserLogData userLogData) {
    authServiceInterface
        .saveUserEmailAndPassword(jsonEncode(userLogData.toJson()));
  }

  UserLogData? getUserData() {
    UserLogData? userData;
    try {
      final rawData = authServiceInterface
          .getUserEmail(); // Lấy chuỗi JSON từ SharedPreferences
      if (rawData.isNotEmpty) {
        userData = UserLogData.fromJson(jsonDecode(rawData));

        // Chỉ giữ email/phone, password để null
        userData = UserLogData(
          email: userData.email,
          phoneNumber: userData.phoneNumber,
          countryCode: userData.countryCode,
          password: null, // KHÔNG điền password
        );
      }
    } catch (error) {
      debugPrint('Error getting saved user data: $error');
    }
    return userData;
  }

  Future<bool> clearUserEmailAndPassword() async {
    return authServiceInterface.clearUserEmailAndPassword();
  }

  String getUserPassword() {
    return authServiceInterface.getUserPassword();
  }

  Future<ResponseModel?> forgetPassword(
      {required ConfigModel config,
      required String phoneOrEmail,
      required String type,
      bool isResend = false}) async {
    ResponseModel? responseModel;
    if (isResend) {
      _resendButtonLoading = true;
    } else {
      _isForgotPasswordLoading = true;
    }

    isSentToMail(false);
    notifyListeners();

    if (type == 'phone' &&
        config.customerVerification?.firebase == 1 &&
        config.customerVerification?.phone == 1) {
      await firebaseVerifyPhoneNumber(phoneOrEmail,
          isResend ? FromPage.verification : FromPage.forgetPassword,
          isForgetPassword: true);
    } else {
      responseModel = await _forgetPassword(phoneOrEmail, type);
    }

    if (isResend) {
      _resendButtonLoading = false;
    } else {
      _isForgotPasswordLoading = false;
    }

    notifyListeners();
    return responseModel;
  }

  Future<ResponseModel> _forgetPassword(String email, String type) async {
    _isForgotPasswordLoading = true;
    _resendButtonLoading = true;
    notifyListeners();

    ApiResponseModel apiResponse =
        await authServiceInterface.forgetPassword(email, type);
    ResponseModel responseModel;

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      responseModel =
          ResponseModel(apiResponse.response!.data["message"], true);
      isSentToMail(apiResponse.response!.data["type"] == 'sent_to_mail');
    } else {
      responseModel = ResponseModel(
          ApiChecker.getError(apiResponse).errors![0].message, false);
      ApiChecker.checkApi(apiResponse);
    }
    _resendButtonLoading = false;
    _isForgotPasswordLoading = false;
    notifyListeners();

    return responseModel;
  }

  void isSentToMail(bool value) {
    _sendToEmail = value;
    notifyListeners();
  }

  Future<ResponseModel> verifyToken(String email) async {
    _isPhoneNumberVerificationButtonLoading = true;
    notifyListeners();
    ApiResponseModel apiResponse =
        await authServiceInterface.verifyToken(email, _verificationCode);

    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    ResponseModel responseModel;
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      responseModel =
          ResponseModel(apiResponse.response!.data["message"], true);
    } else {
      responseModel = ResponseModel(
          ApiChecker.getError(apiResponse).errors![0].message, false);
    }
    return responseModel;
  }

  Future<(ResponseModel?, String?)> existingAccountCheck(
      {required String email,
      required int userResponse,
      required String medium}) async {
    _isPhoneNumberVerificationButtonLoading = true;
    notifyListeners();
    ApiResponseModel apiResponse =
        await authServiceInterface.existingAccountCheck(
            email: email, userResponse: userResponse, medium: medium);
    ResponseModel responseModel;
    String? token;
    String? tempToken;
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      Map map = apiResponse.response!.data;

      if (map.containsKey('token')) {
        token = map["token"];
      }

      if (map.containsKey('temp_token')) {
        tempToken = map["temp_token"];
      }

      if (token != null) {
        await authServiceInterface.saveUserToken(token);
        responseModel = ResponseModel('token', true);
      } else if (tempToken != null) {
        responseModel = ResponseModel('tempToken', true);
      } else {
        responseModel = ResponseModel('', true);
      }
    } else {
      _loginErrorMessage = ApiChecker.getError(apiResponse).errors![0].message;
      showCustomSnackBar(_loginErrorMessage, Get.context!);
      responseModel = ResponseModel(_loginErrorMessage, false);
    }
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    return (responseModel, tempToken);
  }

  Future<void> getGuestIdUrl() async {
    ApiResponseModel apiResponse = await authServiceInterface.getGuestId();
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
      authServiceInterface
          .saveGuestId(apiResponse.response!.data['guest_id'].toString());
      authServiceInterface
          .saveGuestCartId(apiResponse.response!.data['guest_id'].toString());
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }

  void toggleTermsCheck() {
    _isAcceptTerms = !_isAcceptTerms;
    notifyListeners();
  }

  void toggleIsNumberLogin({bool? value, bool isUpdate = true}) {
    if (value == null) {
      _isNumberLogin = !_isNumberLogin;
    } else {
      _isNumberLogin = value;
    }

    if (isUpdate) {
      notifyListeners();
    }
  }

  void toggleIsNumberLoginScreenText({bool? value, bool isUpdate = true}) {
    if (value == null) {
      _isNumberLoginScreenText = !_isNumberLoginScreenText;
    } else {
      _isNumberLoginScreenText = value;
    }

    if (isUpdate) {
      notifyListeners();
    }
  }

  void toggleRememberMe() {
    _isActiveRememberMe = !_isActiveRememberMe;
    notifyListeners();
  }

  void clearVerificationMessage() {
    _verificationMsg = '';
  }

  void removeGoogleLogIn() {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;
    googleSignIn.signOut();
    googleSignIn.disconnect();
  }

  String? getGuestCartId() {
    return authServiceInterface.getGuestCartId();
  }
}

