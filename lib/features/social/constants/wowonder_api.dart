import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

/// Cấu hình API WoWonder
/// Dùng cho các endpoint liên quan đến group chat
class WoWonderApiConfig {
  /// Ví dụ: https://social.vnshop247.com/api/group_chat?access_token=...
  static Uri groupChatUri(String accessToken) {
    return Uri.parse('${AppConstants.socialBaseUrl}/api/group_chat')
        .replace(queryParameters: {'access_token': accessToken});
  }

  /// Server key của WoWonder (lấy từ AppConstants)
  static String get serverKey => AppConstants.socialServerKey;
}
