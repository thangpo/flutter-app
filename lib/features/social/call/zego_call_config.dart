import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class ZegoCallConfig {
  const ZegoCallConfig._();

  /// Lấy trực tiếp từ AppConstants, không cần dart-define
  static const int appID = AppConstants.socialZegoAppId;

  /// Optional (for offline call invitation / ringtone).
  /// Set via `--dart-define=ZEGO_CALL_RESOURCE_ID=...`
  static const String callResourceID =
      String.fromEnvironment('ZEGO_CALL_RESOURCE_ID', defaultValue: '');
}
