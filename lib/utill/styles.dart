import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';

/// Dùng font Roboto cho toàn bộ app.
/// Nếu bạn có font khác trong pubspec.yaml, có thể đổi ở đây.
const String fontFamily = 'Roboto';

/// Regular text style
final robotoRegular = TextStyle(
  fontFamily: fontFamily,
  fontWeight: FontWeight.w400,
  fontSize: Dimensions.fontSizeDefault,
);

/// Medium text style
final robotoMedium = TextStyle(
  fontFamily: fontFamily,
  fontWeight: FontWeight.w500,
  fontSize: Dimensions.fontSizeDefault,
);

/// Bold text style
final robotoBold = TextStyle(
  fontFamily: fontFamily,
  fontWeight: FontWeight.w700,
  fontSize: Dimensions.fontSizeDefault,
);

/// Light text style
final robotoLight = TextStyle(
  fontFamily: fontFamily,
  fontWeight: FontWeight.w300,
  fontSize: Dimensions.fontSizeDefault,
);
