abstract class AuthServiceInterface {
  Future<dynamic> socialLogin(Map<String, dynamic> body);

  Future<dynamic> registration(
    Map<String, dynamic> body,
  );

  Future<dynamic> socialCreateAccount({
    required String username,
    required String password,
    required String email,
    required String confirmPassword,
    required String serverKey,
    String? firstName,
    String? lastName,
  });

  Future<void> saveSocialAccessToken(String token);

  Future<String?> getSocialAccessToken();
  Future<void> clearSocialAccessToken();

  Future<void> saveSocialUserId(String userId);
  Future<String?> getSocialUserId();
  Future<void> clearSocialUserId();

  Future socialWoLogin({
    required String username,
    required String password,
    required String serverKey,
    String? timezone,
    String? deviceId,
  });
  Future socialLogout({required String accessToken});

  Future<dynamic> login(String? userInput, String? password, String? type);

  Future<dynamic> logout();

  Future<dynamic> getGuestId();

  Future<dynamic> updateDeviceToken();

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

  Future<dynamic> setLanguageCode(String token);

  Future<dynamic> forgetPassword(String identity, String type);

  Future<void> saveGuestId(String id);

  Future<dynamic> sendOtpToEmail(String email, String token);

  Future<dynamic> resendEmailOtp(String email, String token);

  Future<dynamic> verifyEmail(String email, String code, String token);

  Future<dynamic> sendOtpToPhone(String phone, String token);

  Future<dynamic> resendPhoneOtp(String phone, String token);

  Future<dynamic> verifyPhone(String phone, String otp, String token);

  Future<dynamic> verifyOtp(String otp, String identity);

  Future<void> saveUserEmailAndPassword(String userData);

  Future<dynamic> resetPassword(
      String otp, String identity, String password, String confirmPassword);

  Future<dynamic> checkEmail(String checkMail);

  Future<dynamic> checkPhone(String checkPhone);

  Future<dynamic> firebaseAuthVerify(
      {required String phoneNumber,
      required String session,
      required String otp,
      required bool isForgetPassword});

  Future<dynamic> registerWithOtp(String name,
      {String? email, required String phone});

  Future<dynamic> registerWithSocialMedia(String name,
      {required String email, String? phone});

  Future<dynamic> verifyToken(String email, String token);

  Future<dynamic> existingAccountCheck(
      {required String email,
      required int userResponse,
      required String medium});

  Future<dynamic> verifyProfileInfo(
      {required String userInput, required String token, required String type});

  Future<dynamic> firebaseAuthTokenStore(
      {required String userInput, required String token});

  Future<void> setAppleLoginEmail(String email);

  String getAppleLoginEmail();

  Future<void> saveGuestCartId(String id);

  String? getGuestCartId();
}
