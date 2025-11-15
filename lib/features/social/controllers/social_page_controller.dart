import 'package:flutter/material.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_get_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_page_service_interface.dart';

class SocialPageController with ChangeNotifier {
  final SocialPageServiceInterface service;
  SocialPageController({required this.service});

  static const int _pageSize = 20;

  // State cho "Page gợi ý"
  final _PageListState _recommendedState = _PageListState();

  // ====== GETTERS cho UI dùng ======

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

  // ====== HÀM PUBLIC CHO UI GỌI ======

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
        // offset: 0,
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

  /// Load thêm page gợi ý (nếu endpoint support offset)
  Future<void> loadMoreSuggested() async {
    final state = _recommendedState;
    if (state.loading || state.refreshing || !state.hasMore) return;

    state.loading = true;
    state.error = null;
    notifyListeners();

    try {
      final List<SocialGetPage> pages = await service.getRecommendedPages(
        limit: _pageSize,
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
