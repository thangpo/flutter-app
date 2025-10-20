import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';

class SocialController with ChangeNotifier {
  final SocialServiceInterface service;
  SocialController({required this.service});

  bool _loading = false;
  bool get loading => _loading;

  bool _creatingPost = false;
  bool get creatingPost => _creatingPost;

  bool _creatingStory = false;
  bool get creatingStory => _creatingStory;

  bool _loadingUser = false;
  SocialUser? _currentUser;
  SocialUser? get currentUser => _currentUser;

  final List<SocialPost> _posts = [];
  List<SocialPost> get posts => List.unmodifiable(_posts);

  void _updatePost(String id, SocialPost newPost) {
    final i = _posts.indexWhere((e) => e.id == id);
    if (i != -1) {
      _posts[i] = newPost;
      notifyListeners();
    }
  }

  Future<SocialPost?> createPost({
    String? text,
    List<String>? imagePaths,
    String? videoPath,
    String? videoThumbnailPath,
    int privacy = 0,
    String? backgroundColorId,
  }) async {
    if (_creatingPost) return null;
    _creatingPost = true;
    notifyListeners();
    try {
      final SocialPost post = await service.createPost(
        text: text,
        imagePaths: imagePaths,
        videoPath: videoPath,
        videoThumbnailPath: videoThumbnailPath,
        privacy: privacy,
        backgroundColorId: backgroundColorId,
      );
      _posts.insert(0, post);
      return post;
    } catch (e) {
      showCustomSnackBar(e.toString(), Get.context!, isError: true);
      rethrow;
    } finally {
      _creatingPost = false;
      notifyListeners();
    }
  }

  Future<SocialStory?> createStory({
    required String fileType,
    required String filePath,
    String? coverPath,
    String? storyTitle,
    String? storyDescription,
    String? highlightHash,
  }) async {
    if (_creatingStory) return null;
    _creatingStory = true;
    notifyListeners();
    try {
      final SocialStory? story = await service.createStory(
        fileType: fileType,
        filePath: filePath,
        coverPath: coverPath,
        storyTitle: storyTitle,
        storyDescription: storyDescription,
        highlightHash: highlightHash,
      );
      if (story != null) {
        _stories.removeWhere((element) => element.id == story.id);
        _stories.insert(0, story);
      }
      return story;
    } catch (e) {
      showCustomSnackBar(e.toString(), Get.context!, isError: true);
      rethrow;
    } finally {
      _creatingStory = false;
      notifyListeners();
    }
  }

  Future<void> loadCurrentUser({bool force = false}) async {
    if (_loadingUser) return;
    if (!force && _currentUser != null) return;
    _loadingUser = true;
    try {
      final user = await service.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      showCustomSnackBar(e.toString(), Get.context!, isError: true);
    } finally {
      _loadingUser = false;
    }
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
        showCustomSnackBar(
            'Không có bài viết. Kiểm tra socialAccessToken / API response.',
            navigatorKey.currentContext!);
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

    // If already reacted and user taps again => dislike (remove reaction)
    if (was.isNotEmpty && (reaction.isEmpty || reaction == 'Like')) {
      final optimistic = post.copyWith(
        myReaction: '',
        reactionCount: (post.reactionCount - 1).clamp(0, 1 << 31),
      );
      _updatePost(post.id, optimistic);
      try {
        await service.reactToPost(
            postId: post.id, reaction: was, action: 'dislike');
      } catch (e) {
        _updatePost(post.id, post);
        showCustomSnackBar(e.toString(), Get.context!, isError: true);
      }
      return;
    }
    final now = reaction;
    int delta = 0;
    if (was.isEmpty && now.isNotEmpty) delta = 1;
    if (was.isNotEmpty && now.isEmpty) delta = -1;
    final optimistic = post.copyWith(
      myReaction: now,
      reactionCount: (post.reactionCount + delta).clamp(0, 1 << 31),
    );
    _updatePost(post.id, optimistic);

    try {
      await service.reactToPost(
          postId: post.id, reaction: reaction, action: 'reaction');
      // (Optional) Nếu muốn đồng bộ lại số liệu từ server:
      // - có thể gọi get-post-data và cập nhật reactionCount/myReaction
    } catch (e) {
      // rollback khi lỗi
      _updatePost(post.id, post);

      // Ưu tiên thông điệp server (error_text)
      final msg = e.toString();
      showCustomSnackBar(msg, Get.context!, isError: true);
    }
  }
}
