import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_page_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_get_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_page_mess.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_page_chat.dart';
import 'dart:convert';
import 'dart:async'; // cho Timer realtime
import 'package:dio/dio.dart'; // nếu Lữ Bố muốn gửi file/gif/image


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

  // ================== PAGE DETAIL ==================
  bool _loadingPageDetail = false;
  String? _pageDetailError;
  SocialGetPage? _pageDetail;

  bool get loadingPageDetail => _loadingPageDetail;
  String? get pageDetailError => _pageDetailError;
  SocialGetPage? get pageDetail => _pageDetail;

  // ================== DELETE PAGE ==================
  bool _deletingPage = false;
  String? _deletePageError;

  bool get deletingPage => _deletingPage;
  String? get deletePageError => _deletePageError;

  // ================== PAGE CHAT LIST ==================
  List<PageChatThread> _pageChatList = [];
  bool _loadingPageChatList = false;
  String? _pageChatListError;
  final Map<String, PageUserBrief> _pageUserCache = <String, PageUserBrief>{};
  Timer? _pageChatListTimer;

  List<PageChatThread> get pageChatList =>
      List<PageChatThread>.unmodifiable(_pageChatList);

  bool get loadingPageChatList => _loadingPageChatList;
  String? get pageChatListError => _pageChatListError;

  // ================== PAGE CHAT STATE ==================
  List<SocialPageMessage> _pageMessages = <SocialPageMessage>[];
  bool _loadingPageMessages = false;
  bool _sendingPageMessage = false;
  String? _pageMessagesError;
  bool _hasMorePageMessages = true;
  int? _lastMessageId;

  int? _currentChatPageId;
  String? _currentChatRecipientId;
  Timer? _chatPollingTimer;

  List<SocialPageMessage> get pageMessages =>
      List<SocialPageMessage>.unmodifiable(_pageMessages);

  bool get loadingPageMessages => _loadingPageMessages;
  bool get sendingPageMessage => _sendingPageMessage;
  String? get pageMessagesError => _pageMessagesError;
  bool get hasMorePageMessages => _hasMorePageMessages;


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
  String _tryDecodePageMessage(String text, int time) {
    if (text.isEmpty) return text;

    // kiểm tra xem có phải base64 không
    final base64Regex = RegExp(r'^[A-Za-z0-9+/=]+$');
    if (!base64Regex.hasMatch(text)) return text;

    try {
      final decoded = utf8.decode(base64.decode(text));
      return decoded;
    } catch (_) {
      return text;
    }
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

  Future<SocialGetPage> fetchPageDetail({
    String? pageId,
    String? pageName,
    bool force = false,

    /// fallback để đảm bảo không-null (vd: widget.page truyền vào)
    SocialGetPage? fallback,
  }) async {
    final String id = (pageId ?? '').trim();
    final String name = (pageName ?? '').trim();

    // 1) Không có id/name -> trả fallback nếu có, không thì throw
    if (id.isEmpty && name.isEmpty) {
      _pageDetailError = 'Missing pageId/pageName';
      notifyListeners();
      if (fallback != null) return fallback;
      throw Exception(_pageDetailError);
    }

    // 2) Cache hiện tại
    if (!force && _pageDetail != null) {
      if (id.isNotEmpty && _pageDetail!.pageId.toString() == id) return _pageDetail!;
      if (name.isNotEmpty &&
          (_pageDetail!.pageName == name || _pageDetail!.username == name)) {
        return _pageDetail!;
      }
    }

    // 3) Tìm trong các list đã tải trước
    if (!force && id.isNotEmpty) {
      final cached = findPageByIdString(id);
      if (cached != null) {
        _pageDetail = cached;
        notifyListeners();
        return cached;
      }
    }

    _loadingPageDetail = true;
    _pageDetailError = null;
    notifyListeners();

    try {
      // service.getPageDetail PHẢI trả về SocialGetPage (non-null)
      final SocialGetPage result = await service.getPageDetail(
        pageId: id.isNotEmpty ? id : null,
        pageName: name.isNotEmpty ? name : null,
      );

      _pageDetail = result;
      return result;
    } catch (e, st) {
      debugPrint('fetchPageDetail ERROR: $e\n$st');
      _pageDetailError = e.toString();

      // ✅ Không return null nữa: ưu tiên cache -> fallback -> throw
      if (_pageDetail != null) return _pageDetail!;
      if (fallback != null) return fallback;

      throw Exception(_pageDetailError);
    } finally {
      _loadingPageDetail = false;
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
  //                    PAGE CHAT: INIT / REALTIME
  // ============================================================

  /// Gọi khi mở màn hình chat với page
  Future<void> initPageChat({
    required int pageId,
    required String recipientId,
  }) async {
    _chatPollingTimer?.cancel();

    _currentChatPageId = pageId;
    _currentChatRecipientId = recipientId;
    _pageMessages = <SocialPageMessage>[];
    _lastMessageId = null;
    _hasMorePageMessages = true;
    _pageMessagesError = null;
    _loadingPageMessages = true;
    notifyListeners();

    try {
      final List<SocialPageMessage> initial =
      await service.getPageMessages(
        pageId: pageId.toString(),
        recipientId: recipientId,
        limit: 20,
      );

      _pageMessages = initial.map((m) {
        return SocialPageMessage(
          id: m.id,
          fromId: m.fromId,
          toId: m.toId,
          pageId: m.pageId,
          text: _tryDecodePageMessage(m.text, m.time),
          media: m.media,
          stickers: m.stickers,
          lng: m.lng,
          lat: m.lat,
          time: m.time,
          timeText: m.timeText,
          position: m.position,
          type: m.type,
          fileSize: m.fileSize,
          messageHashId: m.messageHashId,
          displayText: _tryDecodePageMessage(m.displayText, m.time),
          user: m.user,
          reply: m.reply == null
              ? null
              : m.reply!.copyWith(
            text: _tryDecodePageMessage(m.reply!.text, m.reply!.time),
            displayText: _tryDecodePageMessage(
                m.reply!.displayText, m.reply!.time),
          ),
        );
      }).toList();

      // 🔥🔥🔥 QUAN TRỌNG NHẤT — SORT THEO THỜI GIAN
      _pageMessages.sort((a, b) => a.time.compareTo(b.time));

      if (_pageMessages.isNotEmpty) {
        _lastMessageId = _pageMessages
            .map((e) => e.id)
            .reduce((a, b) => a > b ? a : b);
      }
    } catch (e, st) {
      debugPrint('initPageChat ERROR: $e\n$st');
      _pageMessagesError = e.toString();
    } finally {
      _loadingPageMessages = false;
      notifyListeners();
    }

    _chatPollingTimer = Timer.periodic(
      const Duration(seconds: 2),
          (_) => _pollNewPageMessages(),
    );
  }

  /// Gọi trong dispose() của màn hình chat
  void disposePageChat() {
    _chatPollingTimer?.cancel();
    _chatPollingTimer = null;
  }

  Future<void> _pollNewPageMessages() async {
    if (_currentChatPageId == null ||
        _currentChatRecipientId == null ||
        _lastMessageId == null) {
      return;
    }

    try {
      final List<SocialPageMessage> newer = await service.getPageMessages(
        pageId: _currentChatPageId!.toString(),
        recipientId: _currentChatRecipientId!,
        afterMessageId: _lastMessageId,
        limit: 20,
      );

      if (newer.isEmpty) return;

      final mapped = newer.map(
            (m) => m.copyWith(
          text: _tryDecodePageMessage(m.text, m.time),
          displayText: _tryDecodePageMessage(m.displayText, m.time),
          reply: m.reply == null
              ? null
              : m.reply!.copyWith(
            text: _tryDecodePageMessage(m.reply!.text, m.reply!.time),
            displayText: _tryDecodePageMessage(
                m.reply!.displayText, m.reply!.time),
          ),
        ),
      );

      _pageMessages = _mergeMessagesUnique(_pageMessages, mapped);

      // 🔥 MUST HAVE — SORT THEO TIME
      _pageMessages.sort((a, b) => a.time.compareTo(b.time));

      // cập nhật last ID sau khi sort
      _lastMessageId = _pageMessages.isNotEmpty
          ? _pageMessages.map((e) => e.id).reduce((a, b) => a > b ? a : b)
          : null;

      if (_pageMessages.isNotEmpty) {
        _updatePageThreadAfterMessage(_pageMessages.last);
      }

      notifyListeners();
    } catch (e, st) {
      debugPrint('_pollNewPageMessages ERROR: $e\n$st');
    }
  }


  // ============================================================
  //                    PAGE CHAT: SEND MESSAGE
  // ============================================================

  Future<void> sendPageChatMessage({
    String text = '',
    MultipartFile? file,
    MultipartFile? voiceFile,
    String? voiceDuration,
    String? gif,
    String? imageUrl,
    String? lng,
    String? lat,
  }) async {
    if (_currentChatPageId == null || _currentChatRecipientId == null) {
      debugPrint(
          'sendPageChatMessage: missing _currentChatPageId or _currentChatRecipientId');
      return;
    }
    if (_sendingPageMessage) return;

    final bool hasAttachment = file != null ||
        voiceFile != null ||
        (gif != null && gif.isNotEmpty) ||
        (imageUrl != null && imageUrl.isNotEmpty);
    final String safeText =
        text.trim().isNotEmpty ? text : (hasAttachment ? ' ' : '');

    if (!hasAttachment && safeText.isEmpty) {
      _pageMessagesError = 'Message is empty';
      notifyListeners();
      return;
    }

    _sendingPageMessage = true;
    _pageMessagesError = null;
    notifyListeners();

    try {
      final String hashId =
      DateTime.now().millisecondsSinceEpoch.toString();

      final List<SocialPageMessage> sent =
      await service.sendPageMessage(
        pageId: _currentChatPageId!.toString(),
        recipientId: _currentChatRecipientId!,
        text: safeText,
        messageHashId: hashId,
        file: file,
        voiceFile: voiceFile,
        voiceDuration: voiceDuration,
        gif: gif,
        imageUrl: imageUrl,
        lng: lng,
        lat: lat,
      );

      if (sent.isNotEmpty) {
        final mapped = sent.map((m) => m.copyWith(
          text: _tryDecodePageMessage(m.text, m.time),
          displayText: _tryDecodePageMessage(m.displayText, m.time),
          reply: m.reply == null
              ? null
              : m.reply!.copyWith(
            text: _tryDecodePageMessage(m.reply!.text, m.reply!.time),
            displayText: _tryDecodePageMessage(m.reply!.displayText, m.reply!.time),
          ),
        ));

        _pageMessages = _mergeMessagesUnique(_pageMessages, mapped);

// 🔥 SORT THEO TIME ĐỂ ĐẢM BẢO TIN MỚI LUÔN XUỐNG DƯỚI
        _pageMessages.sort((a, b) => a.time.compareTo(b.time));


        _lastMessageId = _pageMessages
            .map((e) => e.id)
            .reduce((a, b) => a > b ? a : b);
        _updatePageThreadAfterMessage(_pageMessages.last);
        notifyListeners();
      }
    } catch (e, st) {
      debugPrint('sendPageChatMessage ERROR: $e\n$st');
      _pageMessagesError = e.toString();
      notifyListeners();
    } finally {
      _sendingPageMessage = false;
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
  // ============================================================
  //                    DELETE PAGE
  // ============================================================

  Future<bool> deletePage({
    required SocialGetPage page,
    required String password,
  }) async {
    if (_deletingPage) return false;

    _deletingPage = true;
    _deletePageError = null;
    notifyListeners();

    try {
      // gọi service – yêu cầu bố đã khai báo trong interface:
      // Future<bool> deletePage({required String pageId, required String password});
      final bool ok = await service.deletePage(
        pageId: page.pageId.toString(),
        password: password,
      );

      if (!ok) {
        _deletePageError ??= 'Failed to delete page';
        return false;
      }

      // Xoá khỏi 3 list: myPages, suggestedPages, likedPages
      _removePageFromStates(page.pageId);

      notifyListeners();
      return true;
    } catch (e, st) {
      debugPrint('deletePage ERROR: $e\n$st');
      _deletePageError = e.toString();
      return false;
    } finally {
      _deletingPage = false;
      notifyListeners();
    }
  }

  void _removePageFromStates(int pageId) {
    for (final _PageListState state in <_PageListState>[
      _myPagesState,
      _recommendedState,
      _likedPagesState,
    ]) {
      final List<SocialGetPage> current =
      List<SocialGetPage>.from(state.items);
      current.removeWhere((p) => p.pageId == pageId);
      state.items = current;
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
  DateTime? _safeParseDate(String raw) {
    if (raw.isEmpty) return null;

    try {
      // thử parse chuẩn ISO
      return DateTime.parse(raw);
    } catch (_) {}

    try {
      // Format HH:mm (không có ngày)
      final parts = raw.split(':');
      if (parts.length == 2) {
        final now = DateTime.now();
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          return DateTime(now.year, now.month, now.day, hour, minute);
        }
      }
    } catch (_) {}

    return null;
  }


  Future<void> loadPageChatList({int limit = 50, int offset = 0}) async {
    _loadingPageChatList = true;
    _pageChatListError = null;
    notifyListeners();

    try {
      final List<PageChatThread> list =
      await service.getPageChatList(limit: limit, offset: offset);

      // 🔥 Sort không bao giờ crash
      list.sort((a, b) {
        final da = _safeParseDate(a.lastMessageTime);
        final db = _safeParseDate(b.lastMessageTime);

        if (da == null && db == null) {
          return b.lastMessageTime.compareTo(a.lastMessageTime);
        }
        if (da == null) return 1;
        if (db == null) return -1;

        return db.compareTo(da); // Mới nhất lên đầu
      });

        _pageChatList = list;
        await _hydratePageChatPeers();
    } catch (e, st) {
      debugPrint('loadPageChatList ERROR: $e\n$st');
      _pageChatListError = e.toString();
    } finally {
      _loadingPageChatList = false;
      notifyListeners();
    }
  }

  /// Polling version: không bật loading UI, chỉ cập nhật khi có thay đổi
  Future<void> pollPageChatList({int limit = 50, int offset = 0}) async {
    if (_loadingPageChatList) return;
    try {
      final List<PageChatThread> list =
          await service.getPageChatList(limit: limit, offset: offset);

      list.sort((a, b) {
        final da = _safeParseDate(a.lastMessageTime);
        final db = _safeParseDate(b.lastMessageTime);
        if (da == null && db == null) {
          return b.lastMessageTime.compareTo(a.lastMessageTime);
        }
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

      // so sánh nhanh: map pageId -> lastMessageTime + lastMessage
      bool changed = list.length != _pageChatList.length;
      if (!changed) {
        for (int i = 0; i < list.length; i++) {
          final newItem = list[i];
          final oldItem = _pageChatList[i];
          if (newItem.pageId != oldItem.pageId ||
              newItem.lastMessageTime != oldItem.lastMessageTime ||
              newItem.lastMessage != oldItem.lastMessage ||
              newItem.unreadCount != oldItem.unreadCount) {
            changed = true;
            break;
          }
        }
      }

      if (changed) {
        _pageChatList = list;
        await _hydratePageChatPeers();
      }
    } catch (e, st) {
      debugPrint('pollPageChatList ERROR: $e\n$st');
    }
  }


  Future<void> refreshPageChatList() async {
    return loadPageChatList(limit: 50, offset: 0);
  }

  void startPageChatListPolling({Duration interval = const Duration(seconds: 5)}) {
    _pageChatListTimer?.cancel();
    _pageChatListTimer = Timer.periodic(interval, (_) {
      pollPageChatList();
    });
  }

  void stopPageChatListPolling() {
    _pageChatListTimer?.cancel();
    _pageChatListTimer = null;
  }

  Future<void> _hydratePageChatPeers() async {
    // collect ids missing name/avatar
    bool _isNameMissing(PageChatThread t) =>
        t.peerName.isEmpty || t.peerName == t.userId;

    final Set<String> missingIds = _pageChatList
        .where((t) =>
            t.userId.isNotEmpty &&
            (_isNameMissing(t) || t.peerAvatar.isEmpty))
        .map((t) => t.userId)
        .where((id) => !_pageUserCache.containsKey(id))
        .toSet();

    for (final id in missingIds) {
      try {
        final PageUserBrief? u = await service.getUserDataById(userId: id);
        if (u != null) {
          _pageUserCache[id] = u;
        }
      } catch (_) {
        // ignore per-id failures
      }
    }

    if (_pageUserCache.isEmpty) return;

    bool changed = false;
    final List<PageChatThread> updated = _pageChatList.map((t) {
      final PageUserBrief? u = _pageUserCache[t.userId];
      if (u == null) return t;
      final bool needName = _isNameMissing(t);
      final bool needAvatar = t.peerAvatar.isEmpty;
      if (!needName && !needAvatar) return t;
      changed = true;
      return t.copyWith(
        peerName: needName ? u.name : t.peerName,
        peerAvatar: needAvatar ? u.avatar : t.peerAvatar,
        avatar: needAvatar ? u.avatar : t.avatar,
      );
    }).toList();

    if (changed) {
      _pageChatList = updated;
      notifyListeners();
    }
  }

  Future<void> loadMorePageMessages() async {
    if (_currentChatPageId == null ||
        _currentChatRecipientId == null ||
        !_hasMorePageMessages ||
        _loadingPageMessages) {
      return;
    }

    _loadingPageMessages = true;
    notifyListeners();

    try {
      final int? oldestId = _pageMessages.isNotEmpty
          ? _pageMessages.first.id
          : null;

      final List<SocialPageMessage> older =
      await service.getPageMessages(
        pageId: _currentChatPageId!.toString(),
        recipientId: _currentChatRecipientId!,
        beforeMessageId: oldestId,
        limit: 20,
      );

      if (older.isEmpty) {
        _hasMorePageMessages = false;
      } else {
        _pageMessages = [
          ...older,
          ..._pageMessages,
        ];
      }
    } catch (e, st) {
      debugPrint('loadMorePageMessages ERROR: $e\n$st');
    } finally {
      _loadingPageMessages = false;
      notifyListeners();
    }
  }


  // ================== HELPER: UPSERT PAGE VÀO CÁC STATE ==================

  void updatePagePost(SocialPost updated) {
    final index = _pagePosts.indexWhere((p) => p.id == updated.id);
    if (index == -1) return;

    _pagePosts[index] = updated;
    notifyListeners();
  }

  /// Chèn một bài viết mới vào đầu danh sách bài viết của page.
  void prependPagePost(SocialPost post) {
    _pagePosts = <SocialPost>[post, ..._pagePosts];
    _pagePostsInitialized = true;
    notifyListeners();
  }

  /// Tìm page theo id (string) trong các danh sách đã tải.
  SocialGetPage? findPageByIdString(String pageId) {
    final String needle = pageId.trim();
    if (needle.isEmpty) return null;
    for (final _PageListState state
        in <_PageListState>[_recommendedState, _myPagesState, _likedPagesState]) {
      try {
        return state.items.firstWhere((p) => p.pageId.toString() == needle);
      } catch (_) {
        continue;
      }
    }
    return null;
  }





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
  void bumpThreadToTop(String threadId) {
    final list = List<PageChatThread>.from(_pageChatList);
    final index = list.indexWhere((t) => t.pageId == threadId);
    if (index == -1) return;

    final item = list.removeAt(index);
    list.insert(0, item);
    _pageChatList = list;
    notifyListeners();
  }

  void _updatePageThreadAfterMessage(SocialPageMessage message) {
    if (_currentChatPageId == null || _currentChatRecipientId == null) return;
    final String threadId = _currentChatPageId!.toString();
    final String recipientId = _currentChatRecipientId!;

    int idx = _pageChatList.indexWhere(
      (t) =>
          t.pageId == threadId &&
          (t.userId == recipientId || t.ownerId == recipientId),
    );

    // fallback: match by pageId only
    if (idx == -1) {
      idx = _pageChatList.indexWhere((t) => t.pageId == threadId);
    }
    if (idx == -1) return;

    String _formatTime() {
      if (message.timeText.isNotEmpty) return message.timeText;
      try {
        final DateTime dt = DateTime.fromMillisecondsSinceEpoch(
          message.time * 1000,
          isUtc: false,
        );
        final two = (int v) => v.toString().padLeft(2, '0');
        return '${two(dt.hour)}:${two(dt.minute)}';
      } catch (_) {
        return '';
      }
    }

    String _displayText() {
      if (message.displayText.isNotEmpty) return message.displayText;
      final String lowerType = message.type.toLowerCase();
      if (lowerType.contains('voice') || lowerType.contains('audio')) {
        return '[Voice]';
      }
      if (lowerType.contains('image') || lowerType.contains('photo')) {
        return '[Image]';
      }
      if (message.text.isNotEmpty) return message.text;
      if (message.media.isNotEmpty) return '[Media]';
      return '';
    }

    final PageChatThread current = _pageChatList[idx];
    final PageChatThread updated = current.copyWith(
      lastMessage: _displayText(),
      lastMessageTime: _formatTime(),
      lastMessageType: message.type,
      unreadCount: 0,
    );

    final list = List<PageChatThread>.from(_pageChatList);
    list.removeAt(idx);
    list.insert(0, updated);
    _pageChatList = list;
    notifyListeners();
  }

  void markPageThreadRead(String pageId, {String? peerId}) {
    final List<PageChatThread> list = List<PageChatThread>.from(_pageChatList);
    bool changed = false;

    for (int i = 0; i < list.length; i++) {
      final t = list[i];
      if (t.pageId != pageId) continue;
      if (peerId != null &&
          t.userId.isNotEmpty &&
          t.userId != peerId &&
          t.ownerId != peerId) {
        continue;
      }
      if (t.unreadCount != 0) {
        list[i] = t.copyWith(unreadCount: 0);
        changed = true;
      }
    }

    if (changed) {
      _pageChatList = list;
      notifyListeners();
    }
  }

  List<SocialPageMessage> _mergeMessagesUnique(
      List<SocialPageMessage> current,
      Iterable<SocialPageMessage> incoming) {
    final Map<String, SocialPageMessage> map = <String, SocialPageMessage>{};

    String _keyOf(SocialPageMessage m) {
      if (m.id > 0) return 'id:${m.id}';
      if (m.messageHashId.isNotEmpty) return 'hash:${m.messageHashId}';
      return 'time:${m.time}_${m.text}';
    }

    for (final m in current) {
      map[_keyOf(m)] = m;
    }
    for (final m in incoming) {
      map[_keyOf(m)] = m;
    }

    final List<SocialPageMessage> merged = map.values.toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return merged;
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

