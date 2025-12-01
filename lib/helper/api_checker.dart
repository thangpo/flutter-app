import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/error_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/helper/app_globals.dart';
import 'package:provider/provider.dart';

class ApiChecker {
  static const String _missingSocialTokenText = 'Please log in to your social network account';
  static bool _isRedirectingToLogin = false;

  static void checkApi(ApiResponseModel apiResponse,
      {bool firebaseResponse = false}) {
    final BuildContext? context = Get.context ?? navigatorKey.currentContext;
    final String errorText = apiResponse.error?.toString() ?? '';

    // Bỏ qua log spam khi lỗi rỗng hoặc chỉ là "Unexpected error occured"
    if (errorText.isEmpty || errorText == 'Unexpected error occured') {
      return;
    }

    if (_shouldForceLogout(apiResponse, errorText) && context != null) {
      final bool missingToken =
          errorText.contains(_missingSocialTokenText);
      final String message = missingToken
          ? 'Social session expired. Please sign in again.'
          : 'Session expired. Please sign in again.';
      _forceLogoutAndRedirect(context, message);
      return;
    }

    dynamic errorResponse = apiResponse.error is String
        ? apiResponse.error
        : ErrorResponse.fromJson(apiResponse.error);

    if (apiResponse.response?.statusCode == 500 && context != null) {
      showCustomSnackBar(
          getTranslated('internal_server_error', context), context);
      return;
    } else if (apiResponse.response?.statusCode == 503 && context != null) {
      showCustomSnackBar(apiResponse.response?.data['message'], context);
      return;
    }

    log("==ff=>${apiResponse.error}");
    String? errorMessage = apiResponse.error.toString();
    if (apiResponse.error is! String) {
      log(errorResponse.toString());
      //errorMessage = errorResponse.errors?[0].message;
    }

    if (context == null) {
      log('ApiChecker: Unable to display error message because context is null.');
      return;
    }
    final String? displayMessage =
        firebaseResponse && errorResponse is String
            ? errorResponse.replaceAll('_', ' ')
            : errorMessage;

    showCustomSnackBar(displayMessage, context);
  }

  static bool _shouldForceLogout(
      ApiResponseModel apiResponse, String errorText) {
    if (errorText == 'Failed to load data - status code: 401' ||
        apiResponse.response?.statusCode == 401) {
      return true;
    }
    if (errorText.contains(_missingSocialTokenText)) {
      return true;
    }
    return false;
  }

  static void _forceLogoutAndRedirect(BuildContext context, String message) {
    if (_isRedirectingToLogin) return;
    _isRedirectingToLogin = true;

    Provider.of<AuthController>(context, listen: false).clearSharedData();
    try {
      Provider.of<SocialController>(context, listen: false)
          .clearAuthState();
    } catch (_) {}

    showCustomSnackBar(message, context);

    Future.microtask(() {
      Get.navigator?.pushNamedAndRemoveUntil('/login', (route) => false);
      _isRedirectingToLogin = false;
    });
  }


  static ErrorResponse getError(ApiResponseModel apiResponse){
    ErrorResponse error;

    try{
      error = ErrorResponse.fromJson(apiResponse.response?.data);
    }catch(e){
      if(apiResponse.error is String){
        error = ErrorResponse(errors: [Errors(code: '', message: apiResponse.error.toString())]);

      }else{
        error = ErrorResponse.fromJson(apiResponse.error);
      }
    }
    return error;
  }
}
