// lib/features/social/di/group_call_providers.dart

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
