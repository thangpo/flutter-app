import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class ZegoCallConfig {
  const ZegoCallConfig._();

  /// Lấy trực tiếp từ AppConstants, không cần dart-define
  static const int appID = AppConstants.socialZegoAppId;

  /// Resource ID cho offline push (đặt trong AppConstants).
  static const String callResourceID = AppConstants.socialZegoResourceId;
}
