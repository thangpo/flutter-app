import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';

class SocialController with ChangeNotifier {
  final SocialServiceInterface service;
  SocialController({required this.service});

  bool _loading = false;
  bool get loading => _loading;

  final List<SocialPost> _posts = [];
  List<SocialPost> get posts => List.unmodifiable(_posts);

  void _updatePost(String id, SocialPost newPost) {
    final i = _posts.indexWhere((e) => e.id == id);
    if (i != -1) { _posts[i] = newPost; notifyListeners(); }
  }

  final List<SocialStory> _stories = [];
  List<SocialStory> get stories => List.unmodifiable(_stories);
  int _storiesOffset = 0;

  String? _afterId;

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      final list = await service.getNewsFeed(limit: 10);
      _posts
        ..clear()
        ..addAll(list);
      _afterId = list.isNotEmpty ? list.last.id : null;

      // load stories nếu bạn dùng
      final s = await service.getStories(limit: 10, offset: 0);
      _stories.clear();
      final existing = _stories.map((e) => e.id).toSet();
      final unique = s.where((e) => !existing.contains(e.id)).toList();
      _stories.addAll(unique);
      _storiesOffset = _stories.length;

      // Gợi ý debug (có thể bỏ khi xong):
      if (_posts.isEmpty) {
        showCustomSnackBar('Không có bài viết. Kiểm tra socialAccessToken / API response.', navigatorKey.currentContext!);
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      final list = await service.getNewsFeed(limit: 10, afterPostId: _afterId);
      if (list.isNotEmpty) {
        _posts.addAll(list);
        _afterId = list.last.id;
      }
    } catch (e) {
      showCustomSnackBar(e.toString(), Get.context!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreStories() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      final s = await service.getStories(limit: 10, offset: _storiesOffset);
      if (s.isNotEmpty) {
        final existing = _stories.map((e) => e.id).toSet();
        final unique = s.where((e) => !existing.contains(e.id)).toList();
        _stories.addAll(unique);
        _storiesOffset = _stories.length;
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> reactOnPost(SocialPost post, String reaction) async {
    // optimistic update
    final was = post.myReaction;
    final now = reaction;
    int delta = 0;
    if (was.isEmpty && now.isNotEmpty) delta = 1;
    if (was.isNotEmpty && now.isEmpty) delta = -1;
    final optimistic = post.copyWith(
      myReaction: now,
      reactionCount: (post.reactionCount + delta).clamp(0, 1<<31),
    );
    _updatePost(post.id, optimistic);

    try {
      final ok = await service.reactToPost(postId: post.id, reaction: reaction);
      // (nếu service trả bool ok; hoặc kiểm tra resp theo cách bạn dùng)
    } catch (e) {
      _updatePost(post.id, post);
      final msg = e.toString();
      if (msg.contains('server_key')) {
        showCustomSnackBar('Thiếu server_key: kiểm tra API Settings > Server Key', Get.context!, isError: true);
      } else {
        showCustomSnackBar('Bày tỏ cảm xúc thất bại: $msg', Get.context!, isError: true);
      }
    }
  }

}
