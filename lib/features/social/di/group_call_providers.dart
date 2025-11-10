// lib/features/social/di/group_call_providers.dart
//
// Đăng ký Provider cho Group Call:
// - WebRTCGroupSignalingRepositoryImpl (map tới /api/v2/endpoints/webrtc_group.php)
// - GroupCallController (quản lý join/peers/polling)
// Cách dùng trong main.dart (ví dụ):
//
//   import 'package:flutter_sixvalley_ecommerce/features/social/di/group_call_providers.dart';
//
//   MultiProvider(
//     providers: [
//       ...buildGroupCallProviders(),
//       // các provider khác...
//     ],
//     child: MyApp(),
//   );
//
// YÊU CẦU:
// - Đã cấu hình AppConstants.socialBaseUrl & AppConstants.socialServerKey
// - Access token Social lưu trong SharedPreferences key: AppConstants.socialAccessToken

import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/group_call_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/webrtc_group_signaling_repository.dart';

List<SingleChildWidget> buildGroupCallProviders() {
  final repo = WebRTCGroupSignalingRepositoryImpl(
    baseUrl: AppConstants.socialBaseUrl,
    serverKey: AppConstants.socialServerKey,
    getAccessToken: () async {
      final sp = await SharedPreferences.getInstance();
      // Key access token Social, ví dụ: 'social_access_token'
      return sp.getString(AppConstants.socialAccessToken);
    },
  );

  return <SingleChildWidget>[
    Provider<GroupWebRTCSignalingRepository>.value(value: repo),
    ChangeNotifierProvider<GroupCallController>(
      create: (_) => GroupCallController(signaling: repo)..init(),
    ),
  ];
}
