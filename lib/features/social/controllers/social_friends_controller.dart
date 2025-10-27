import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_friends_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_friend.dart';
// Nếu có SocialController chứa currentUser WoWonder, lấy từ đó luôn:
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';

class SocialFriendsController extends GetxController {
  final SocialFriendsRepository repo;
  SocialFriendsController(this.repo);

  final isLoading = false.obs;
  final friends = <SocialFriend>[].obs;
  final filtered = <SocialFriend>[].obs;

  /// [context] để lấy currentUser từ Provider<SocialController> (nếu có)
  Future<void> load(String accessToken,
      {BuildContext? context, String? userId}) async {
    isLoading.value = true;

    // 1) Ưu tiên userId truyền vào
    String? uid = userId;

    // 2) Thử lấy từ SharedPreferences
    if (uid == null || uid.isEmpty) {
      final sp = await SharedPreferences.getInstance();
      uid = sp.getString(AppConstants.socialUserId);
    }

    // 3) Nếu vẫn chưa có, thử lấy từ SocialController.currentUser
    if ((uid == null || uid.isEmpty) && context != null) {
      try {
        final sc = Provider.of<SocialController>(context, listen: false);
        uid = sc.currentUser?.id?.toString();
      } catch (_) {}
    }

    final raw = await repo.fetchFriends(token: accessToken, userId: uid);

    final list =
        raw.map<SocialFriend>((e) => SocialFriend.fromWowonder(e)).toList();

    friends.assignAll(list);
    filtered.assignAll(list);
    isLoading.value = false;
  }

  void search(String q) {
    if (q.trim().isEmpty) {
      filtered.assignAll(friends);
    } else {
      final k = q.toLowerCase();
      filtered
          .assignAll(friends.where((u) => u.name.toLowerCase().contains(k)));
    }
  }
}
