import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_page_service.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_get_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_page_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
class SocialPageController with ChangeNotifier {
  final SocialPageServiceInterface service;
  final SocialController socialController;
  SocialPageController({required this.service,required this.socialController});

  static const int _pageSize = 20;
  List<SocialArticleCategory> _articleCategories = <SocialArticleCategory>[];
  bool _loadingCategories = false;
  bool _categoriesInitialized = false;
  String? _categoriesError;

  List<SocialArticleCategory> get articleCategories =>
      List<SocialArticleCategory>.unmodifiable(_articleCategories);

  bool get loadingCategories => _loadingCategories;

  bool get categoriesInitialized => _categoriesInitialized;

  String? get categoriesError => _categoriesError;

  bool _creatingPage = false;
  String? _createPageError;
  SocialGetPage? _lastCreatedPage;

  bool get creatingPage => _creatingPage;
  String? get createPageError => _createPageError;

  // Nếu muốn dùng chung với pattern lastError (giống GroupChatController)
  String? get lastError => _createPageError;

  SocialGetPage? get lastCreatedPage => _lastCreatedPage;
  bool _updatingPage = false;
  String? _updatePageError;
  SocialGetPage? _lastUpdatedPage;
  SocialGetPage? get lastUpdatedPage => _lastUpdatedPage;

  bool get updatingPage => _updatingPage;
  String? get updatePageError => _updatePageError;

  // State cho "Page gợi ý"
  final _PageListState _recommendedState = _PageListState();

  // State cho "Trang của bạn"
  final _PageListState _myPagesState = _PageListState();

  // state cho "" Trang đã thích
  final _PageListState _likedPagesState = _PageListState();
  // ================== GETTERS: GỢI Ý ==================
  // ================== GETTERS: TRANG ĐÃ THÍCH ==================

  List<SocialGetPage> get likedPages =>
      List<SocialGetPage>.unmodifiable(_likedPagesState.items);

  bool get likedPagesInitialized => _likedPagesState.initialized;

  bool get refreshingLikedPages =>
      _likedPagesState.refreshing && !_likedPagesState.loading;

  bool get loadingLikedPages => _likedPagesState.loading;

  bool get hasMoreLikedPages => _likedPagesState.hasMore;

  String? get likedPagesError => _likedPagesState.error;


  /// Danh sách page gợi ý (read-only)
  List<SocialGetPage> get suggestedPages =>
      List<SocialGetPage>.unmodifiable(_recommendedState.items);

  /// Đã load lần đầu chưa
  bool get suggestedInitialized => _recommendedState.initialized;

  /// Đang refresh (kéo xuống load lại) không
  bool get refreshingSuggested =>
      _recommendedState.refreshing && !_recommendedState.loading;

  /// Đang load thêm / load initial
  bool get loadingSuggested => _recommendedState.loading;

  /// Còn dữ liệu để loadMore không
  bool get hasMoreSuggested => _recommendedState.hasMore;

  /// Thông báo lỗi (nếu có)
  String? get suggestedError => _recommendedState.error;

  // ================== GETTERS: TRANG CỦA BẠN ==================

  /// Danh sách "Trang của bạn"
  List<SocialGetPage> get myPages =>
      List<SocialGetPage>.unmodifiable(_myPagesState.items);

  bool get myPagesInitialized => _myPagesState.initialized;

  bool get refreshingMyPages =>
      _myPagesState.refreshing && !_myPagesState.loading;

  bool get loadingMyPages => _myPagesState.loading;

  bool get hasMoreMyPages => _myPagesState.hasMore;

  String? get myPagesError => _myPagesState.error;

  // ================== HÀM: GỢI Ý ==================

  /// Đảm bảo đã load dữ liệu gợi ý (dùng trong initState / addPostFrameCallback)
  Future<void> ensureSuggestedLoaded() async {
    if (_recommendedState.initialized ||
        _recommendedState.loading ||
        _recommendedState.refreshing) {
      return;
    }
    await refreshSuggested();
  }

  /// Refresh lại danh sách page gợi ý (kéo để load lại)
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

  /// Load thêm page gợi ý (nếu endpoint support offset sau này)
  Future<void> loadMoreSuggested() async {
    final state = _recommendedState;
    if (state.loading || state.refreshing || !state.hasMore) return;

    state.loading = true;
    state.error = null;
    notifyListeners();

    try {
      final List<SocialGetPage> pages = await service.getRecommendedPages(
        limit: _pageSize,
        // TODO: nếu backend support offset thì pass offset ở đây
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

  /// Xoá 1 page khỏi danh sách gợi ý (sau khi user đã "Thích trang" chẳng hạn)
  void removeSuggestedPageById(int pageId) {
    final state = _recommendedState;
    final List<SocialGetPage> updated = List<SocialGetPage>.from(state.items)
      ..removeWhere((p) => p.pageId == pageId);
    state.items = updated;
    notifyListeners();
  }

  /// Cập nhật / chèn 1 page vào danh sách (nếu sau này có API like/unlike page trả dữ liệu mới)
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

  // ================== HÀM: TRANG CỦA BẠN ==================

  /// Đảm bảo đã load "Trang của bạn"
  Future<void> ensureMyPagesLoaded() async {
    if (_myPagesState.initialized ||
        _myPagesState.loading ||
        _myPagesState.refreshing) {
      return;
    }
    await refreshMyPages();
  }

  /// Refresh lại "Trang của bạn"
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

  /// (Tuỳ chọn) sau này nếu có API phân trang cho my_pages thì implement tiếp
  Future<void> loadMoreMyPages() async {
    final state = _myPagesState;
    if (state.loading || state.refreshing || !state.hasMore) return;

    state.loading = true;
    state.error = null;
    notifyListeners();

    try {
      final List<SocialGetPage> pages =
      await service.getMyPages(limit: _pageSize);
      // TODO: nếu backend có offset thì truyền offset = state.offset

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

  // ================== HÀM: TRANG ĐÃ THÍCH ==================

  Future<void> ensureLikedPagesLoaded() async {
    if (_likedPagesState.initialized ||
        _likedPagesState.loading ||
        _likedPagesState.refreshing) {
      return;
    }
    await refreshLikedPages();
  }

  Future<void> refreshLikedPages() async {
    final state = _likedPagesState;
    if (state.refreshing) return;

    state.refreshing = true;
    state.error = null;
    notifyListeners();

    // --- BẮT ĐẦU SỬA ---
    // 1. Lấy User ID từ socialController
    final String? currentUserId = socialController.currentUser?.id;

    // 2. Kiểm tra đăng nhập
    if (currentUserId == null || currentUserId.isEmpty) {
      state.error = "Vui lòng đăng nhập để xem trang đã thích."; // (Hoặc dùng getTranslated)
      state.refreshing = false;
      state.initialized = true;
      notifyListeners();
      return;
    }
    // --- KẾT THÚC SỬA ---

    try {
      final List<SocialGetPage> pages =
      await service.getLikedPages(
        limit: _pageSize,
        userId: currentUserId, // <-- 3. Truyền userId vào service
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

  Future<void> loadMoreLikedPages() async {
    final state = _likedPagesState;
    if (state.loading || state.refreshing || !state.hasMore) return;

    state.loading = true;
    state.error = null;
    notifyListeners();

    // --- BẮT ĐẦU SỬA ---
    final String? currentUserId = socialController.currentUser?.id;

    if (currentUserId == null || currentUserId.isEmpty) {
      state.error = "Vui lòng đăng nhập để xem trang đã thích.";
      state.loading = false;
      notifyListeners();
      return;
    }
    // --- KẾT THÚC SỬA ---

    try {
      final List<SocialGetPage> pages =
      await service.getLikedPages(
        limit: _pageSize,
        userId: currentUserId, // <-- Truyền userId vào service
        // offset: state.offset, // (Nếu backend hỗ trợ)
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
      // vẫn giữ list cũ nếu có
    } finally {
      _loadingCategories = false;
      notifyListeners();
    }
  }
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

      // upsert vào danh sách "Trang của bạn"
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
  /// Update thông tin trang từ payload mà EditPageScreen pop ra
  ///
  /// payload dạng:
  /// {
  ///   'page_id': '123',
  ///   'page_name': 'abc',
  ///   'page_title': 'ABC Store',
  ///   'page_description': '...',
  ///   'avatar': File(...),
  ///   'cover': File(...),
  ///   ...
  /// }
  Future<bool> updatePageFromPayload(Map<String, dynamic> payload) async {
    if (_updatingPage) return false;

    _updatingPage = true;
    _updatePageError = null;
    notifyListeners();

    try {
      // service giờ trả SocialGetPage? (nullable)
      final SocialGetPage? page =
      await service.updatePageFromPayload(payload);

      if (page != null) {
        _lastUpdatedPage = page;
        _upsertPageIntoStates(page);
      } else {
        // Không có page_data → vẫn coi là thành công, chỉ refresh list
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
    // myPages: insert nếu chưa có, còn nếu có thì replace
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

    // recommended: chỉ replace nếu đã tồn tại trong list
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
