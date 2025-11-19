import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_page_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_get_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_feed_page.dart';
// XOÁ DÒNG NÀY NẾU CÓ
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_service_interface.dart';

class SocialPageController with ChangeNotifier {
  final SocialPageServiceInterface service;
  final SocialController socialController;

  SocialPageController({
    required this.service,
    required this.socialController,
  });

  static const int _pageSize = 20;
  // ================== LIKE / UNLIKE PAGE ==================
  bool _likingPage = false;
  String? _likePageError;

  bool get likingPage => _likingPage;
  String? get likePageError => _likePageError;

  // ================== ARTICLE CATEGORIES ==================
  List<SocialArticleCategory> _articleCategories = <SocialArticleCategory>[];
  bool _loadingCategories = false;
  bool _categoriesInitialized = false;
  String? _categoriesError;

  List<SocialArticleCategory> get articleCategories =>
      List<SocialArticleCategory>.unmodifiable(_articleCategories);

  bool get loadingCategories => _loadingCategories;

  bool get categoriesInitialized => _categoriesInitialized;

  String? get categoriesError => _categoriesError;

  // ================== STATE: BÀI VIẾT CỦA PAGE ==================
  List<SocialPost> _pagePosts = <SocialPost>[];
  bool _loadingPagePosts = false;
  bool _pagePostsInitialized = false;
  String? _pagePostsError;

  // Thêm:
  bool _loadingMorePagePosts = false;
  bool _hasMorePagePosts = true;
  int? _currentPostsPageId; // page hiện tại đang xem bài viết

  List<SocialPost> get pagePosts =>
      List<SocialPost>.unmodifiable(_pagePosts);

  bool get loadingPagePosts => _loadingPagePosts;
  bool get loadingMorePagePosts => _loadingMorePagePosts;
  bool get hasMorePagePosts => _hasMorePagePosts;

  bool get pagePostsInitialized => _pagePostsInitialized;
  String? get pagePostsError => _pagePostsError;

  // ================== CREATE / UPDATE PAGE ==================
  bool _creatingPage = false;
  String? _createPageError;
  SocialGetPage? _lastCreatedPage;

  bool get creatingPage => _creatingPage;
  String? get createPageError => _createPageError;

  String? get lastError => _createPageError;

  SocialGetPage? get lastCreatedPage => _lastCreatedPage;

  bool _updatingPage = false;
  String? _updatePageError;
  SocialGetPage? _lastUpdatedPage;

  SocialGetPage? get lastUpdatedPage => _lastUpdatedPage;

  bool get updatingPage => _updatingPage;
  String? get updatePageError => _updatePageError;

  // ================== LIST STATES ==================
  /// Gợi ý
  final _PageListState _recommendedState = _PageListState();

  /// Trang của bạn
  final _PageListState _myPagesState = _PageListState();

  /// Trang đã thích
  final _PageListState _likedPagesState = _PageListState();

  // ================== GETTERS: TRANG ĐÃ THÍCH ==================
  List<SocialGetPage> get likedPages =>
      List<SocialGetPage>.unmodifiable(_likedPagesState.items);

  bool get likedPagesInitialized => _likedPagesState.initialized;

  bool get refreshingLikedPages =>
      _likedPagesState.refreshing && !_likedPagesState.loading;

  bool get loadingLikedPages => _likedPagesState.loading;

  bool get hasMoreLikedPages => _likedPagesState.hasMore;

  String? get likedPagesError => _likedPagesState.error;

  // ================== GETTERS: GỢI Ý ==================
  List<SocialGetPage> get suggestedPages =>
      List<SocialGetPage>.unmodifiable(_recommendedState.items);

  bool get suggestedInitialized => _recommendedState.initialized;

  bool get refreshingSuggested =>
      _recommendedState.refreshing && !_recommendedState.loading;

  bool get loadingSuggested => _recommendedState.loading;

  bool get hasMoreSuggested => _recommendedState.hasMore;

  String? get suggestedError => _recommendedState.error;

  // ================== GETTERS: TRANG CỦA BẠN ==================
  List<SocialGetPage> get myPages =>
      List<SocialGetPage>.unmodifiable(_myPagesState.items);

  bool get myPagesInitialized => _myPagesState.initialized;

  bool get refreshingMyPages =>
      _myPagesState.refreshing && !_myPagesState.loading;

  bool get loadingMyPages => _myPagesState.loading;

  bool get hasMoreMyPages => _myPagesState.hasMore;

  String? get myPagesError => _myPagesState.error;

  // ============================================================
  //                    HÀM: GỢI Ý
  // ============================================================

  Future<void> ensureSuggestedLoaded() async {
    if (_recommendedState.initialized ||
        _recommendedState.loading ||
        _recommendedState.refreshing) {
      return;
    }
    await refreshSuggested();
  }

  Future<void> refreshSuggested() async {
    final state = _recommendedState;
    if (state.refreshing) return;

    state.refreshing = true;
    state.error = null;
    notifyListeners();

    try {
      final List<SocialGetPage> pages = await service.getRecommendedPages(
        limit: _pageSize,
      );

      state.items = List<SocialGetPage>.from(pages);
      state.offset = pages.length;
      state.hasMore = pages.length >= _pageSize;
      state.initialized = true;
    } catch (e) {
      state.error = e.toString();
      state.hasMore = state.items.isNotEmpty;
      state.initialized = true;
      rethrow;
    } finally {
      state.refreshing = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreSuggested() async {
    final state = _recommendedState;
    if (state.loading || state.refreshing || !state.hasMore) return;

    state.loading = true;
    state.error = null;
    notifyListeners();

    try {
      final List<SocialGetPage> pages = await service.getRecommendedPages(
        limit: _pageSize,
        // nếu backend support offset -> thêm ở đây
        // offset: state.offset,
      );

      if (pages.isEmpty) {
        state.hasMore = false;
      } else {
        final merged = List<SocialGetPage>.from(state.items)..addAll(pages);
        state.items = merged;
        state.offset = merged.length;
        state.hasMore = pages.length >= _pageSize;
      }
    } catch (e) {
      state.error = e.toString();
      rethrow;
    } finally {
      state.loading = false;
      notifyListeners();
    }
  }

  void removeSuggestedPageById(int pageId) {
    final state = _recommendedState;
    final List<SocialGetPage> updated = List<SocialGetPage>.from(state.items)
      ..removeWhere((p) => p.pageId == pageId);
    state.items = updated;
    notifyListeners();
  }

  void upsertSuggestedPage(SocialGetPage page) {
    final state = _recommendedState;
    final List<SocialGetPage> updated = List<SocialGetPage>.from(state.items);
    final int index =
    updated.indexWhere((element) => element.pageId == page.pageId);
    if (index >= 0) {
      updated[index] = page;
    } else {
      updated.insert(0, page);
    }
    state.items = updated;
    notifyListeners();
  }

  // ============================================================
  //                    HÀM: TRANG CỦA BẠN
  // ============================================================

  Future<void> ensureMyPagesLoaded() async {
    if (_myPagesState.initialized ||
        _myPagesState.loading ||
        _myPagesState.refreshing) {
      return;
    }
    await refreshMyPages();
  }

  Future<void> refreshMyPages() async {
    final state = _myPagesState;
    if (state.refreshing) return;

    state.refreshing = true;
    state.error = null;
    notifyListeners();

    try {
      final List<SocialGetPage> pages =
      await service.getMyPages(limit: _pageSize);

      state.items = List<SocialGetPage>.from(pages);
      state.offset = pages.length;
      state.hasMore = pages.length >= _pageSize;
      state.initialized = true;
    } catch (e) {
      state.error = e.toString();
      state.hasMore = state.items.isNotEmpty;
      state.initialized = true;
      rethrow;
    } finally {
      state.refreshing = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreMyPages() async {
    final state = _myPagesState;
    if (state.loading || state.refreshing || !state.hasMore) return;

    state.loading = true;
    state.error = null;
    notifyListeners();

    try {
      final List<SocialGetPage> pages =
      await service.getMyPages(limit: _pageSize);
      // nếu backend có offset thì chuyền offset = state.offset

      if (pages.isEmpty) {
        state.hasMore = false;
      } else {
        final merged = List<SocialGetPage>.from(state.items)..addAll(pages);
        state.items = merged;
        state.offset = merged.length;
        state.hasMore = pages.length >= _pageSize;
      }
    } catch (e) {
      state.error = e.toString();
      rethrow;
    } finally {
      state.loading = false;
      notifyListeners();
    }
  }

  // ============================================================
  //                    HÀM: TRANG ĐÃ THÍCH
  //     🔥 ĐÃ CHỈNH ĐỂ NHẬN userId, fallback từ socialController
  // ============================================================

  /// Dùng trong initState/social tab:
  ///   context.read<SocialPageController>()
  ///          .ensureLikedPagesLoaded(userId: someId);
  Future<void> ensureLikedPagesLoaded({String? userId}) async {
    final state = _likedPagesState;

    if (state.loading || state.refreshing) {
      debugPrint(
        'ensureLikedPagesLoaded: skip (loading=${state.loading}, refreshing=${state.refreshing})',
      );
      return;
    }

    if (!state.initialized || state.items.isEmpty) {
      debugPrint(
        'ensureLikedPagesLoaded -> call refreshLikedPages(userId: $userId)',
      );
      await refreshLikedPages(userId: userId);  // <-- TRUYỀN XUỐNG ĐÂY
    } else {
      debugPrint(
        'ensureLikedPagesLoaded: already initialized, items=${state.items.length}',
      );
    }
  }


  Future<void> refreshLikedPages({String? userId}) async {
    final state = _likedPagesState;

    if (state.refreshing) {
      debugPrint('refreshLikedPages: skip because refreshing=true');
      return;
    }

    debugPrint('refreshLikedPages START: '
        'initialized=${state.initialized}, '
        'items=${state.items.length}, '
        'loading=${state.loading}, '
        'refreshing=${state.refreshing}');

    state.refreshing = true;
    state.error = null;
    notifyListeners();

    // 1. Ưu tiên tham số truyền vào
    String? currentUserId = userId;

    // 2. Nếu chưa có, lấy từ SocialController
    currentUserId ??= socialController.currentUser?.id;

    // 3. Nếu vẫn chưa có, lấy từ SharedPreferences (AppConstants.socialUserId là KEY)
    if (currentUserId == null || currentUserId.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      currentUserId = prefs.getString(AppConstants.socialUserId);
    }

    debugPrint('refreshLikedPages: currentUserId=$currentUserId');

    if (currentUserId == null || currentUserId.isEmpty) {
      state.error = 'Vui lòng đăng nhập để xem trang đã thích.';
      state.refreshing = false;
      notifyListeners();
      debugPrint('refreshLikedPages: abort because currentUserId is null/empty');
      return;
    }

    try {
      final List<SocialGetPage> pages = await service.getLikedPages(
        limit: _pageSize,
        userId: currentUserId,
      );

      debugPrint(
          'refreshLikedPages: fetched ${pages.length} liked pages from API');

      state.items = List<SocialGetPage>.from(pages);
      state.offset = pages.length;
      state.hasMore = pages.length >= _pageSize;
      state.initialized = true;
    } catch (e, st) {
      debugPrint('refreshLikedPages ERROR: $e\n$st');
      state.error = e.toString();
      state.hasMore = state.items.isNotEmpty;
      state.initialized = false;
    } finally {
      state.refreshing = false;
      notifyListeners();
      debugPrint(
          'refreshLikedPages END: items=${state.items.length}, hasMore=${state.hasMore}');
    }
  }



  Future<void> loadMoreLikedPages() async {
    final state = _likedPagesState;
    if (state.loading || state.refreshing || !state.hasMore) {
      print('loadMoreLikedPages: skip (loading=${state.loading}, '
          'refreshing=${state.refreshing}, hasMore=${state.hasMore})');
      return;
    }

    state.loading = true;
    state.error = null;
    notifyListeners();

    // 1. Lấy từ SocialController
    String? currentUserId = socialController.currentUser?.id;

    // 2. Nếu chưa có, đọc từ SharedPreferences
    if (currentUserId == null || currentUserId.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      currentUserId = prefs.getString(AppConstants.socialUserId);
    }

    print('loadMoreLikedPages: currentUserId=$currentUserId');

    if (currentUserId == null || currentUserId.isEmpty) {
      state.error = 'Vui lòng đăng nhập để xem trang đã thích.';
      state.loading = false;
      notifyListeners();
      return;
    }

    try {
      final List<SocialGetPage> pages = await service.getLikedPages(
        limit: _pageSize,
        userId: currentUserId,
        // offset: state.offset, // nếu backend support offset thì mở lại
      );

      print('loadMoreLikedPages: fetched ${pages.length} more liked pages');

      if (pages.isEmpty) {
        state.hasMore = false;
      } else {
        final merged = List<SocialGetPage>.from(state.items)..addAll(pages);
        state.items = merged;
        state.offset = merged.length;
        state.hasMore = pages.length >= _pageSize;
      }
    } catch (e, st) {
      print('loadMoreLikedPages ERROR: $e\n$st');
      state.error = e.toString();
    } finally {
      state.loading = false;
      notifyListeners();
    }
  }
  // ============================================================
  //                    BÀI VIẾT CỦA PAGE
  // ============================================================
  /// Gọi khi mở SocialPageDetailScreen lần đầu
  Future<void> loadInitialPagePosts(int pageId) async {
    // Nếu đã load cho cùng pageId rồi thì thôi
    if (_pagePostsInitialized && _currentPostsPageId == pageId) {
      return;
    }

    _currentPostsPageId = pageId;
    _loadingPagePosts = true;
    _loadingMorePagePosts = false;
    _pagePostsError = null;
    _pagePostsInitialized = false;
    _hasMorePagePosts = true;
    _pagePosts = <SocialPost>[];
    notifyListeners();

    try {
      final List<SocialPost> posts = await service.getPagePosts(
        pageId: pageId,
        limit: _pageSize,
      );

      _pagePosts = posts;
      _pagePostsInitialized = true;
      _hasMorePagePosts = posts.length >= _pageSize;
    } catch (e, st) {
      debugPrint('loadInitialPagePosts ERROR: $e\n$st');
      _pagePostsError = e.toString();
      _pagePostsInitialized = true;
      _hasMorePagePosts = false;
    } finally {
      _loadingPagePosts = false;
      notifyListeners();
    }
  }

  /// Refresh lại toàn bộ bài viết của page (kéo để reload)
  Future<void> refreshPagePosts(int pageId) async {
    _currentPostsPageId = pageId;
    _loadingPagePosts = true;
    _loadingMorePagePosts = false;
    _pagePostsError = null;
    _hasMorePagePosts = true;
    notifyListeners();

    try {
      final List<SocialPost> posts = await service.getPagePosts(
        pageId: pageId,
        limit: _pageSize,
      );

      _pagePosts = posts;
      _pagePostsInitialized = true;
      _hasMorePagePosts = posts.length >= _pageSize;
    } catch (e, st) {
      debugPrint('refreshPagePosts ERROR: $e\n$st');
      _pagePostsError = e.toString();
      _hasMorePagePosts = false;
    } finally {
      _loadingPagePosts = false;
      notifyListeners();
    }
  }
  Future<void> loadMorePagePosts(int pageId) async {
    // Đang load hoặc không còn dữ liệu
    if (_loadingMorePagePosts || !_hasMorePagePosts) {
      return;
    }

    // Nếu đổi sang page khác thì nên load lại từ đầu
    if (_currentPostsPageId != null && _currentPostsPageId != pageId) {
      await loadInitialPagePosts(pageId);
      return;
    }

    _currentPostsPageId = pageId;
    _loadingMorePagePosts = true;
    _pagePostsError = null;
    notifyListeners();

    try {
      int? afterPostId;
      if (_pagePosts.isNotEmpty) {
        // backend dùng after_post_id = post_id của bài cuối cùng
        afterPostId = int.tryParse(_pagePosts.last.id);
      }

      final List<SocialPost> more = await service.getPagePosts(
        pageId: pageId,
        limit: _pageSize,
        afterPostId: afterPostId,
      );

      if (more.isEmpty) {
        _hasMorePagePosts = false;
      } else {
        _pagePosts = List<SocialPost>.from(_pagePosts)..addAll(more);
        _hasMorePagePosts = more.length >= _pageSize;
      }
    } catch (e, st) {
      debugPrint('loadMorePagePosts ERROR: $e\n$st');
      _pagePostsError = e.toString();
    } finally {
      _loadingMorePagePosts = false;
      notifyListeners();
    }
  }


  // ============================================================
  //                    LIKE / UNLIKE PAGE
  // ============================================================

  /// Toggle like/unlike cho 1 page.
  /// - Gọi service.toggleLikePage(pageId)
  /// - Cập nhật lại 3 list: recommended, myPages, likedPages
  ///
  /// Trả về:
  ///   true  -> sau khi gọi xong, page đang ở trạng thái "đã thích"
  ///   false -> sau khi gọi xong, page đang ở trạng thái "chưa thích" hoặc lỗi
  Future<bool> toggleLikePage(SocialGetPage page) async {
    if (_likingPage) {
      // đang gửi request rồi -> không làm gì thêm, giữ nguyên trạng thái cũ
      return page.isLiked;
    }

    _likingPage = true;
    _likePageError = null;
    notifyListeners();

    final bool wasLiked = page.isLiked;

    try {
      // ❗ Ở đây: CHỈ CẦN BIẾT REQUEST CÓ OK KHÔNG
      final bool ok = await service.toggleLikePage(
        pageId: page.pageId.toString(),
      );

      if (!ok) {
        // API trả lỗi -> không đổi gì
        return wasLiked;
      }

      // 👉 TRẠNG THÁI MỚI = ĐẢO TRẠNG THÁI CŨ
      final bool isLikedNow = !wasLiked;

      // Tính lại lượt theo dõi
      int newLikes = page.likesCount;
      if (isLikedNow && !wasLiked) {
        newLikes++;
      } else if (!isLikedNow && wasLiked && newLikes > 0) {
        newLikes--;
      }

      final SocialGetPage updatedPage = page.copyWith(
        isLiked: isLikedNow,
        likesCount: newLikes,
      );

      // Cập nhật cả 3 list: myPages, recommended, likedPages
      _applyLikeToggleToState(
        _myPagesState,
        updatedPage,
        isLikedNow,
        isLikedTab: false,
      );

      _applyLikeToggleToState(
        _recommendedState,
        updatedPage,
        isLikedNow,
        isLikedTab: false,
      );

      _applyLikeToggleToState(
        _likedPagesState,
        updatedPage,
        isLikedNow,
        isLikedTab: true,
      );

      notifyListeners();
      return isLikedNow;
    } catch (e, st) {
      debugPrint('toggleLikePage ERROR: $e\n$st');
      _likePageError = e.toString();
      notifyListeners();
      // lỗi thì giữ nguyên trạng thái cũ
      return wasLiked;
    } finally {
      _likingPage = false;
      notifyListeners();
    }
  }




  /// Cập nhật 1 `_PageListState` sau khi like/unlike 1 page.
  ///
  /// - Nếu page đã có trong list:
  ///    + isLikedTab == true  & isLikedNow == false -> remove khỏi list liked
  ///    + ngược lại -> replace bằng updatedPage
  /// - Nếu page chưa có trong list:
  ///    + isLikedTab == true & isLikedNow == true -> insert vào đầu list liked
  void _applyLikeToggleToState(
      _PageListState state,
      SocialGetPage updatedPage,
      bool isLikedNow, {
        required bool isLikedTab,
      }) {
    final List<SocialGetPage> current = List<SocialGetPage>.from(state.items);
    final int index =
    current.indexWhere((p) => p.pageId == updatedPage.pageId);

    if (index >= 0) {
      if (isLikedTab && !isLikedNow) {
        // Tab "Trang đã thích" mà giờ unliked -> remove
        current.removeAt(index);
      } else {
        // Các list khác, hoặc vẫn liked -> update item
        current[index] = updatedPage;
      }
    } else {
      // chưa có trong list
      if (isLikedTab && isLikedNow) {
        // mới like -> thêm vào đầu list likedPages
        current.insert(0, updatedPage);
      }
    }

    state.items = current;

    if (isLikedTab) {
      state.initialized = true;
    }
  }





  // ============================================================
  //                    ARTICLE CATEGORIES
  // ============================================================

  Future<void> loadArticleCategories({bool force = false}) async {
    if (_loadingCategories) return;
    if (_categoriesInitialized && !force) return;

    _loadingCategories = true;
    _categoriesError = null;
    notifyListeners();

    try {
      final List<SocialArticleCategory> cats =
      await service.getArticleCategories();

      _articleCategories = List<SocialArticleCategory>.from(cats);
      _categoriesInitialized = true;
    } catch (e) {
      _categoriesError = e.toString();
      _categoriesInitialized = true;
    } finally {
      _loadingCategories = false;
      notifyListeners();
    }
  }

  // ============================================================
  //                    CREATE / UPDATE PAGE
  // ============================================================

  Future<bool> createPage({
    required String pageName,
    required String pageTitle,
    required int categoryId,
    String? description,
  }) async {
    if (_creatingPage) return false;

    _creatingPage = true;
    _createPageError = null;
    notifyListeners();

    try {
      final SocialGetPage page = await service.createPage(
        pageName: pageName,
        pageTitle: pageTitle,
        categoryId: categoryId,
        description: description,
      );

      _lastCreatedPage = page;

      final state = _myPagesState;
      final List<SocialGetPage> current =
      List<SocialGetPage>.from(state.items);
      final int index =
      current.indexWhere((element) => element.pageId == page.pageId);
      if (index >= 0) {
        current[index] = page;
      } else {
        current.insert(0, page);
      }
      state.items = current;
      state.initialized = true;

      notifyListeners();
      return true;
    } catch (e) {
      _createPageError = e.toString();
      notifyListeners();
      return false;
    } finally {
      _creatingPage = false;
      notifyListeners();
    }
  }

  Future<bool> updatePageFromPayload(Map<String, dynamic> payload) async {
    if (_updatingPage) return false;

    _updatingPage = true;
    _updatePageError = null;
    notifyListeners();

    try {
      final SocialGetPage? page =
      await service.updatePageFromPayload(payload);

      if (page != null) {
        _lastUpdatedPage = page;
        _upsertPageIntoStates(page);
      } else {
        await refreshMyPages();
      }

      return true;
    } catch (e) {
      _updatePageError = e.toString();
      return false;
    } finally {
      _updatingPage = false;
      notifyListeners();
    }
  }

  // ================== HELPER: UPSERT PAGE VÀO CÁC STATE ==================

  void _upsertPageIntoStates(SocialGetPage page) {
    // myPages
    {
      final state = _myPagesState;
      final List<SocialGetPage> current =
      List<SocialGetPage>.from(state.items);
      final int index =
      current.indexWhere((element) => element.pageId == page.pageId);
      if (index >= 0) {
        current[index] = page;
      } else {
        current.insert(0, page);
      }
      state.items = current;
      state.initialized = true;
    }

    // recommended
        {
      final state = _recommendedState;
      final List<SocialGetPage> current =
      List<SocialGetPage>.from(state.items);
      final int index =
      current.indexWhere((element) => element.pageId == page.pageId);
      if (index >= 0) {
        current[index] = page;
        state.items = current;
      }
    }
  }
}

// ============================================================
//                      PAGE LIST STATE
// ============================================================

class _PageListState {
  List<SocialGetPage> items;
  bool loading;
  bool refreshing;
  bool hasMore;
  int offset;
  bool initialized;
  String? error;

  _PageListState({
    List<SocialGetPage>? items,
    this.loading = false,
    this.refreshing = false,
    this.hasMore = true,
    this.offset = 0,
    this.initialized = false,
    this.error,
  }) : items = items ?? <SocialGetPage>[];
}


