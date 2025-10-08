import 'package:flutter_sixvalley_ecommerce/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/domain/services/auth_service_interface.dart';

class AuthService implements AuthServiceInterface{
  AuthRepoInterface authRepoInterface;
  AuthService({required this.authRepoInterface});

  @override
  Future<bool> clearGuestId() {
    return authRepoInterface.clearGuestId();
  }

  @override
  Future<bool> clearSharedData() {
    return authRepoInterface.clearSharedData();
  }

  @override
  Future<bool> clearUserEmailAndPassword() {
    return authRepoInterface.clearUserEmailAndPassword();
  }

  @override
  Future forgetPassword(String identity, String type) {
    return authRepoInterface.forgetPassword(identity, type);
  }

  @override
  Future getGuestId() {
    return authRepoInterface.getGuestId();
  }

  @override
  String? getGuestIdToken() {
    return authRepoInterface.getGuestIdToken();
  }

  @override
  String getUserEmail() {
    return authRepoInterface.getUserEmail();
  }

  @override
  String getUserPassword() {
    return authRepoInterface.getUserPassword();
  }

  @override
  String getUserToken() {
    return authRepoInterface.getUserToken();
  }

  @override
  bool isGuestIdExist() {
    return authRepoInterface.isGuestIdExist();
  }

  @override
  bool isLoggedIn() {
    return authRepoInterface.isLoggedIn();
  }

  @override
  Future login(String? userInput, String? password, String? type) {
    return authRepoInterface.login(userInput, password, type);
  }

  @override
  Future logout() {
    return authRepoInterface.logout();
  }

  @override
  Future registration(Map<String, dynamic> body) {
    return authRepoInterface.registration(body);
  }

  @override
  Future resendEmailOtp(String email, String token) {
    return authRepoInterface.resendEmailOtp(email, token);
  }

  @override
  Future resendPhoneOtp(String phone, String token) {
    return authRepoInterface.resendPhoneOtp(phone, token);
  }

  @override
  Future resetPassword(String otp, String identity, String password, String confirmPassword) {
    return authRepoInterface.resetPassword(otp, identity, password, confirmPassword);
  }

  @override
  Future<void> saveGuestId(String id) {
    return authRepoInterface.saveGuestId(id);
  }

  @override
  Future<void> saveUserEmailAndPassword(String userLogData) {
    return authRepoInterface.saveUserEmailAndPassword(userLogData);
  }

  @override
  Future<void> saveUserToken(String token) {
    return authRepoInterface.saveUserToken(token);
  }

  @override
  Future sendOtpToEmail(String email, String token) {
    return authRepoInterface.sendOtpToEmail(email, token);
  }

  @override
  Future sendOtpToPhone(String phone, String token) {
    return authRepoInterface.sendOtpToPhone(phone, token);
  }

  @override
  Future setLanguageCode(String code) {
    return authRepoInterface.setLanguageCode(code);
  }

  @override
  Future socialLogin(Map<String, dynamic> body) {
    return authRepoInterface.socialLogin(body);
  }

  @override
  Future updateDeviceToken() {
    return authRepoInterface.updateDeviceToken();
  }

  @override
  Future verifyEmail(String email, String code, String token) {
    return authRepoInterface.verifyEmail(email, code, token);
  }

  @override
  Future verifyOtp(String otp, String identity) {
    return authRepoInterface.verifyOtp(otp, identity);
  }

  @override
  Future verifyPhone(String phone, String otp, String token) {
    return authRepoInterface.verifyPhone(phone, otp, token);
  }

  @override
  Future checkEmail(String mail) {
    return authRepoInterface.checkEmail(mail);
  }

  @override
  Future checkPhone(String phone) {
    return authRepoInterface.checkPhone(phone);
  }

  @override
  Future firebaseAuthVerify({required String phoneNumber, required String session, required String otp, required bool isForgetPassword}){
    return authRepoInterface.firebaseAuthVerify(phoneNumber: phoneNumber, session: session, otp: otp, isForgetPassword: isForgetPassword);
  }

  @override
  Future registerWithOtp(String name, {String? email, required String phone}) {
    return authRepoInterface.registerWithOtp(name, email: email, phone: phone);
  }


  @override
  Future registerWithSocialMedia(String name, {required String email,String? phone})  {
    return authRepoInterface.registerWithSocialMedia(name, email: email, phone: phone);
  }

  @override
  Future verifyToken(String email, String token) {
    return  authRepoInterface.verifyToken(email, token);
  }

  @override
  Future existingAccountCheck({required String email, required int userResponse, required String medium}) {
    return authRepoInterface.existingAccountCheck(email: email, userResponse: userResponse, medium: medium);
  }

  @override
  Future verifyProfileInfo({required String userInput, required String token, required String type}) {
    return authRepoInterface.verifyProfileInfo(userInput, token, type);
  }


  @override
  Future firebaseAuthTokenStore({required String userInput, required String token}) {
    return authRepoInterface.firebaseAuthTokenStore(userInput, token);
  }

  @override
  Future<void> setAppleLoginEmail(String email) {
    return authRepoInterface.setAppleLoginEmail(email);
  }

  @override
  String getAppleLoginEmail() {
    return authRepoInterface.getAppleLoginEmail();
  }


  @override
  Future<void> saveGuestCartId(String id) {
    return authRepoInterface.saveGuestCartId(id);
  }

  @override
  String? getGuestCartId() {
   return authRepoInterface.getGuestCartId();
  }

}