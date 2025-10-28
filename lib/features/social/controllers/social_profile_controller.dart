import 'package:flutter/foundation.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_profile_service.dart';

class SocialProfileController extends ChangeNotifier {
  final SocialProfileService service;

  SocialProfileController({required this.service});

  // ===== STATE =====
  SocialUser? _currentUser;
  List<SocialUser> _followers = const [];
  List<SocialUser> _following = const [];
  List<dynamic> _likedPages = const [];
  List<SocialPost> _posts = const [];

  bool _loadingInit = true;
  bool _loadingMore = false;

  String? _lastPostId; // để phân trang tiếp

  // ===== GETTERS dùng trong UI =====
  SocialUser? get currentUser => _currentUser;
  List<SocialUser> get followers => _followers;
  List<SocialUser> get following => _following;
  List<dynamic> get likedPages => _likedPages;
  List<SocialPost> get posts => _posts;

  bool get isLoadingInit => _loadingInit;
  bool get isLoadingMore => _loadingMore;

  // ===== LOAD LẦN ĐẦU (PROFILE + POSTS ĐẦU TIÊN) =====
  Future<void> init() async {
    _loadingInit = true;
    notifyListeners();

    // 1. Lấy thông tin profile hiện tại
    final bundle = await service.getCurrentUserProfile();
    _currentUser = bundle.user;
    _followers = bundle.followers;
    _following = bundle.following;
    _likedPages = bundle.likedPages;

    // 2. Lấy bài viết đầu tiên
    if (_currentUser != null && _currentUser!.id.isNotEmpty) {
      final feedPage = await service.getUserPosts(
        targetUserId: _currentUser!.id,
        limit: 10,
        afterPostId: null,
      );
      _posts = feedPage.posts;
      _lastPostId = feedPage.lastId;
    } else {
      _posts = const [];
      _lastPostId = null;
    }

    _loadingInit = false;
    notifyListeners();
  }

  // ===== LOAD THÊM BÀI VIẾT (PAGINATION) =====
  Future<void> loadMorePosts({int limit = 10}) async {
    // Guard điều kiện
    if (_loadingMore) return;
    if (_currentUser == null) return;
    if (_lastPostId == null || _lastPostId!.isEmpty) return;

    _loadingMore = true;
    notifyListeners();

    final feedPage = await service.getUserPosts(
      targetUserId: _currentUser!.id,
      limit: limit,
      afterPostId: _lastPostId,
    );

    if (feedPage.posts.isNotEmpty) {
      _posts = [..._posts, ...feedPage.posts];
      _lastPostId = feedPage.lastId;
    }

    _loadingMore = false;
    notifyListeners();
  }
  void applyReactionUpdate({
    required String postId,
    required String newReaction,          // ví dụ 'Like' hoặc ''
    required int newReactionCount,        // ví dụ 12
    required Map<String, int> newBreakdown, // ví dụ {'Like': 10, 'Love':2}
  }) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final updated = _posts[idx].copyWith(
      myReaction: newReaction,
      reactionCount: newReactionCount,
      reactionBreakdown: newBreakdown,
    );

    _posts = [
      ..._posts.sublist(0, idx),
      updated,
      ..._posts.sublist(idx + 1),
    ];

    notifyListeners();
  }

}
