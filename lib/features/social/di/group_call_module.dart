import 'package:flutter_sixvalley_ecommerce/features/social/controllers/group_call_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/webrtc_group_signaling_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

Future<GroupWebRTCSignalingRepository> buildGroupSignalingRepo() async {
  final sp = await SharedPreferences.getInstance();
  final token = sp.getString(AppConstants.socialAccessToken);

  return WebRTCGroupSignalingRepositoryImpl(
    baseUrl: AppConstants.socialBaseUrl,
    serverKey: AppConstants.socialServerKey,
    getAccessToken: () async => token,
  );
}

Future<GroupCallController> buildGroupCallController() async {
  final repo = await buildGroupSignalingRepo();
  return GroupCallController(signaling: repo);
}
