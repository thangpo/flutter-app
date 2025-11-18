import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_group.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_feed_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user_profile.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_service.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_photo.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_reel.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post_color.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_search_result.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/post_background_presets.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_live_repository.dart';

class SocialController with ChangeNotifier {
  final SocialServiceInterface service;
  SocialController({required this.service}) {
    loadPostBackgrounds();
  }
  //follow user in profile
  final Set<String> _followBusy = {};
  bool _updatingProfile = false;

  List<Map<String, dynamic>> pokes = [];
  bool _loadingPokes = false;
  bool get loadingPokes => _loadingPokes;

  bool isFollowBusy(String userId) => _followBusy.contains(userId);
  // ========== NEWS FEED STATE ==========
  bool _loading = false;
  bool get loading => _loading;

  bool _creatingPost = false;
  bool get creatingPost => _creatingPost;

  bool _creatingStory = false;
  bool get creatingStory => _creatingStory;

  bool _creatingPoke= false;
  bool get creatingPoke => _creatingPoke;

  bool _addingFamily = false;
  bool get addingFamily => _addingFamily;

  bool _loadingUser = false;
  SocialUser? _currentUser;
  SocialUser? get currentUser => _currentUser;

  SocialUserProfile? _profileHeaderUser;
  SocialUserProfile? get profileHeaderUser => _profileHeaderUser;

  SocialStory? _currentUserStory;
  SocialStory? get currentUserStory => _currentUserStory;

  final List<SocialPost> _posts = [];
  List<SocialPost> get posts => List.unmodifiable(_posts);

  final List<SocialPost> _savedPosts = <SocialPost>[];
  List<SocialPost> get savedPosts => List.unmodifiable(_savedPosts);

  bool _loadingSavedPosts = false;
  bool get loadingSavedPosts => _loadingSavedPosts;

  bool _hasMoreSavedPosts = true;
  bool get hasMoreSavedPosts => _hasMoreSavedPosts;

  String? _savedAfterId;
  static const int _savedPostsPageSize = 10;
  static const int _searchPageSize = 20;
  static const Duration _searchDebounceDuration = Duration(milliseconds: 450);

  String? _accessToken;
  String? get accessToken => _accessToken;

  bool _creatingLive = false;
  bool get creatingLive => _creatingLive;

  // ---- STATE ----
  final List<SocialUser> followersList = [];
  final List<SocialUser> followingList = [];

  bool loadingFollowers = false;
  bool loadingFollowing = false;

  String? _followersAfter; // cursor/offset trang tiếp theo
  String? _followingAfter;
  // --- SEARCH STATE ---
  Timer? _searchDebounce;
  int _searchRequestId = 0;
  String _searchKeyword = '';
  bool _searchLoadingState = false;
  SocialSearchResult _searchResult = const SocialSearchResult();
  String? _searchError;

  String get searchKeyword => _searchKeyword;
  bool get searchLoading => _searchLoadingState;
  SocialSearchResult get searchResult => _searchResult;
  String? get searchError => _searchError;
  bool get hasSearchQuery => _searchKeyword.trim().isNotEmpty;

  void updateSearchKeyword(String value, {bool immediate = false}) {
    _searchKeyword = value;
    _searchError = null;
    _searchDebounce?.cancel();

    if (_searchKeyword.trim().isEmpty) {
      _searchResult = const SocialSearchResult();
      _searchLoadingState = false;
      notifyListeners();
      return;
    }

    if (immediate) {
      _performSearch();
    } else {
      _searchDebounce = Timer(
        _searchDebounceDuration,
        () => _performSearch(),
      );
    }
    notifyListeners();
  }

  Future<SocialSearchResult> searchNow(String keyword) {
    _searchDebounce?.cancel();
    _searchKeyword = keyword;
    return _performSearch();
  }

  Future<SocialSearchResult> refreshSearchResults() {
    _searchDebounce?.cancel();
    return _performSearch();
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    _searchKeyword = '';
    _searchResult = const SocialSearchResult();
    _searchError = null;
    _searchLoadingState = false;
    notifyListeners();
  }

  Future<SocialSearchResult> _performSearch() async {
    final String query = _searchKeyword.trim();
    _searchError = null;
    if (query.isEmpty) {
      _searchResult = const SocialSearchResult();
      _searchLoadingState = false;
      notifyListeners();
      return _searchResult;
    }

    final int requestId = ++_searchRequestId;
    _searchLoadingState = true;
    notifyListeners();

    try {
      final SocialSearchResult result = await service.searchEverything(
        keyword: query,
        limit: _searchPageSize,
      );
      if (_searchRequestId == requestId) {
        _searchResult = result;
        _searchError = null;
      }
      return result;
    } catch (e) {
      if (_searchRequestId == requestId) {
        _searchError = e.toString();
      }
      return const SocialSearchResult();
    } finally {
      if (_searchRequestId == requestId) {
        _searchLoadingState = false;
        notifyListeners();
      }
    }
  }

//new 11/04/2025
  final Set<String> _blockBusy = {};
  bool isBlockBusy(String userId) => _blockBusy.contains(userId);

  List<SocialUser> _blockedUsers = <SocialUser>[]; // danh sách user đã chặn
  Set<String> _blockedIds = <String>{};
  bool _loadingBlocked = false;
  bool get isLoadingBlocked => _loadingBlocked;
  UnmodifiableListView<SocialUser> get blockedUsers =>
      UnmodifiableListView(_blockedUsers);
  bool isUserBlocked(String userId) => _blockedIds.contains(userId);
  //end
  //05/11/2025 report user
  final Set<String> _reportBusy = {};
  bool isReportBusy(String userId) => _reportBusy.contains(userId);
  List<SocialPhoto> _profilePhotos = <SocialPhoto>[];
  bool _loadingProfilePhotos = false;
  String? _photosOffset; // nếu backend trả offset/id tiếp theo
  bool _hasMoreProfilePhotos = true;
  String? _photosForUserId;

  List<SocialPhoto> get profilePhotos => List.unmodifiable(_profilePhotos);
  bool get isLoadingProfilePhotos => _loadingProfilePhotos;
  bool get hasMoreProfilePhotos => _hasMoreProfilePhotos;

  // --- REELS STATE ---
  List<SocialReel> _profileReels = <SocialReel>[];
  bool _loadingProfileReels = false;
  String? _reelsOffset; // nếu backend có trả offset/id trang tiếp theo
  bool _hasMoreProfileReels = true;
  String? _reelsForUserId; // cache theo user đang xem

  List<SocialReel> get profileReels => List.unmodifiable(_profileReels);
  bool get isLoadingProfileReels => _loadingProfileReels;
  bool get hasMoreProfileReels => _hasMoreProfileReels;
  String? get reelsForUserId => _reelsForUserId;

  // --- POST BACKGROUND COLORS ---
  List<PostBackgroundPreset> _postBackgroundPresets =
      List<PostBackgroundPreset>.from(PostBackgroundPresets.defaults);
  final Set<String> _backgroundPresetIds =
      PostBackgroundPresets.defaults.map((preset) => preset.id).toSet();
  final Set<String> _pendingColorFetch = <String>{};
  bool _loadingPostColors = false;
  DateTime? _postColorsFetchedAt;

  List<PostBackgroundPreset> get postBackgroundPresets =>
      List.unmodifiable(_postBackgroundPresets);
  bool get loadingPostColors => _loadingPostColors;
  PostBackgroundPreset? findBackgroundPreset(String? id) {
    if (id == null || id.isEmpty) return null;
    final PostBackgroundPreset? preset =
        PostBackgroundPresets.findById(_postBackgroundPresets, id);
    if (preset != null) return preset;
    return PostBackgroundPresets.findById(PostBackgroundPresets.defaults, id);
  }

  void _resetBackgroundPresetsToDefaults() {
    _postBackgroundPresets =
        List<PostBackgroundPreset>.from(PostBackgroundPresets.defaults);
    _backgroundPresetIds
      ..clear()
      ..addAll(PostBackgroundPresets.defaults.map((preset) => preset.id));
  }

  //end

  bool get hasMoreFollowers =>
      _followersAfter != null && _followersAfter!.isNotEmpty;
  bool get hasMoreFollowing =>
      _followingAfter != null && _followingAfter!.isNotEmpty;

  final List<SocialStory> _stories = [];
  List<SocialStory> get stories => List.unmodifiable(_stories);
  int _storiesOffset = 0;
  final Map<String, Queue<_PendingStoryReaction>> _queuedStoryReactions =
      <String, Queue<_PendingStoryReaction>>{};
  final Set<String> _viewedStoryItemIds = <String>{};
  final Set<String> _storyViewInFlight = <String>{};
  final List<SocialGroup> _suggestedGroups = <SocialGroup>[];
  List<SocialGroup> get suggestedGroups => List.unmodifiable(_suggestedGroups);
  bool _loadingSuggestedGroups = false;
  bool get loadingSuggestedGroups => _loadingSuggestedGroups;
  bool _suggestedGroupsFetched = false;
  String _lastSuggestedKeyword = '';
  final List<SocialGroup> _userGroups = <SocialGroup>[];
  List<SocialGroup> get userGroups => List.unmodifiable(_userGroups);
  bool _loadingUserGroups = false;
  bool get loadingUserGroups => _loadingUserGroups;
  bool _userGroupsFetched = false;
  final List<SocialPost> _groupPosts = <SocialPost>[];
  List<SocialPost> get groupPosts => List.unmodifiable(_groupPosts);
  bool _loadingGroupPosts = false;
  bool get loadingGroupPosts => _loadingGroupPosts;
  bool _groupPostsFetched = false;
  bool get groupPostsFetched => _groupPostsFetched;

  String? _afterId;
  final Set<String> _storyReactionLoading = <String>{};
  static const int _storyViewersPageSize = 50;
  final Map<String, StoryViewersState> _storyViewers =
      <String, StoryViewersState>{};
  final Set<String> _sharingPosts = <String>{};
  bool isSharing(String id) => _sharingPosts.contains(id);
  final Set<String> _postActionBusy = <String>{};
  bool isPostActionBusy(String id) => _postActionBusy.contains(id);
  bool _pendingLoadMore = false;
  final Map<String, List<SocialUser>> _mentionCache =
      <String, List<SocialUser>>{};
  final Map<String, SocialUser> _userCacheById = <String, SocialUser>{};
  final Map<String, SocialUser> _userCacheByUsername = <String, SocialUser>{};

  // ========== USER PROFILE STATE (MERGED FROM PROFILE CONTROLLER) ==========
  List<SocialUser> _followers = const [];
  List<SocialUser> _following = const [];
  List<dynamic> _likedPages = const [];
  List<SocialPost> _profilePosts = [];

  bool _loadingProfile = false;
  bool _loadingProfilePosts = false;
  String? _lastProfilePostId;

  // Profile getters
  List<SocialUser> get followers => _followers;
  List<SocialUser> get following => _following;
  List<dynamic> get likedPages => _likedPages;
  List<SocialPost> get profilePosts => List.unmodifiable(_profilePosts);
  bool get isLoadingProfile => _loadingProfile;
  bool get isLoadingProfilePosts => _loadingProfilePosts;

  // ========== CLEAR STATE ==========
  void clearAuthState({bool notify = true}) {
    _loading = false;
    _creatingPost = false;
    _creatingStory = false;
    _loadingUser = false;
    _currentUser = null;
    _currentUserStory = null;
    _posts.clear();
    _savedPosts.clear();
    _loadingSavedPosts = false;
    _hasMoreSavedPosts = true;
    _savedAfterId = null;
    _stories.clear();
    _viewedStoryItemIds.clear();
    _storyViewInFlight.clear();
    _suggestedGroups.clear();
    _loadingSuggestedGroups = false;
    _suggestedGroupsFetched = false;
    _lastSuggestedKeyword = '';
    _userGroups.clear();
    _loadingUserGroups = false;
    _userGroupsFetched = false;
    _groupPosts.clear();
    _loadingGroupPosts = false;
    _groupPostsFetched = false;
    _afterId = null;
    _storiesOffset = 0;
    _storyReactionLoading.clear();
    _storyViewers.clear();
    _blockBusy.clear();
    // Clear profile state
    _followers = const [];
    _following = const [];
    _likedPages = const [];
    _profilePosts.clear();
    _loadingProfile = false;
    _loadingProfilePosts = false;
    _lastProfilePostId = null;

    //clear photo
    _profilePhotos = <SocialPhoto>[];
    _loadingProfilePhotos = false;
    _hasMoreProfilePhotos = true;
    _photosOffset = null;
    _photosForUserId = null;
    // reset reels
    _profileReels = <SocialReel>[];
    _loadingProfileReels = false;
    _reelsOffset = null;
    _hasMoreProfileReels = true;
    _reelsForUserId = null;

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> loadSuggestedGroups({
    String keyword = '',
    bool forceRefresh = false,
  }) async {
    final String normalizedKeyword = keyword.trim();
    if (_loadingSuggestedGroups) return;
    if (!forceRefresh &&
        _suggestedGroupsFetched &&
        normalizedKeyword == _lastSuggestedKeyword) {
      return;
    }

    _loadingSuggestedGroups = true;
    notifyListeners();

    try {
      final List<SocialGroup> groups =
          await service.searchGroups(keyword: normalizedKeyword);
      _suggestedGroups
        ..clear()
        ..addAll(groups);
      _suggestedGroupsFetched = true;
      _lastSuggestedKeyword = normalizedKeyword;
    } catch (e) {
      final ctx = Get.context;
      if (ctx != null) {
        showCustomSnackBar(e.toString(), ctx, isError: true);
      }
    } finally {
      _loadingSuggestedGroups = false;
      notifyListeners();
    }
  }

  void removeSuggestedGroupById(String groupId) {
    final int index =
        _suggestedGroups.indexWhere((SocialGroup g) => g.id == groupId);
    if (index != -1) {
      _suggestedGroups.removeAt(index);
      notifyListeners();
    }
  }

  //follow user in profile
  Future<bool> toggleFollowUser({String? targetUserId}) async {
    // Xác định userId mục tiêu
    final header = _profileHeaderUser;
    final id = (targetUserId ?? header?.id);

    if (id == null || id.isEmpty) {
      throw Exception('Không xác định được userId để follow.');
    }
    if (_currentUser?.id == id) {
      // Không cho follow chính mình
      return _profileHeaderUser?.isFollowing ?? false;
    }

    // Chống double-tap
    if (_followBusy.contains(id)) {
      return _profileHeaderUser?.isFollowing ?? false;
    }
    _followBusy.add(id);
    notifyListeners();

    try {
      // service.toggleFollow phải trả về bool:
      // true = "followed", false = "unfollowed"
      final bool followed = await service.toggleFollow(targetUserId: id);

      // Cập nhật ngay UI header nếu đang mở profile người đó
      if (_profileHeaderUser?.id == id) {
        final cur = _profileHeaderUser!;
        final newCount = followed
            ? cur.followersCount + 1
            : (cur.followersCount > 0 ? cur.followersCount - 1 : 0);

        _profileHeaderUser = cur.copyWith(
          isFollowing: followed,
          followersCount: newCount,
        );
      }

      // Nếu bạn có list followers/recentFollowers => cập nhật đồng bộ ở đây
      // (ví dụ: add/remove user trong danh sách)

      notifyListeners();
      return followed;
    } catch (e) {
      // Có thể log hoặc show SnackBar ở UI
      rethrow;
    } finally {
      _followBusy.remove(id);
      notifyListeners();
    }
  }

  //block user 11/04/2025
  Future<bool> toggleBlockUser({
    String? targetUserId,
    required bool block, // true = block, false = un-block
  }) async {
    final String? id = targetUserId ?? _profileHeaderUser?.id;
    if (id == null || id.isEmpty) {
      throw Exception('Không xác định userId để chặn.');
    }
    // Không cho tự chặn chính mình
    if (_currentUser?.id == id) {
      return _profileHeaderUser?.isBlocked ?? false;
    }
    // Chống double-tap
    if (_blockBusy.contains(id)) {
      return _profileHeaderUser?.isBlocked ?? false;
    }

    _blockBusy.add(id);
    notifyListeners();

    try {
      // service.blockUser phải trả về bool: true=blocked, false=un-blocked
      final bool blocked = await service.blockUser(
        targetUserId: id,
        block: block,
      );

      // Cập nhật ngay header nếu đang mở profile user đó
      if (_profileHeaderUser?.id == id && _profileHeaderUser != null) {
        final cur = _profileHeaderUser!;

        if (blocked) {
          // Lưu trạng thái trước khi chặn để có thể khôi phục khi bỏ chặn
          _preBlock[id] = _PreBlockSnapshot(
            isFollowing: cur.isFollowing,
            followersCount: cur.followersCount,
            followingCount: cur.followingCount,
          );

          // Tuỳ luật: chặn thì coi như không còn follow nhau → có thể trừ số ngay (optimistic)
          final wasFollowingMe = cur.isFollowingMe == true;
          final wasIFollow = cur.isFollowing == true;

          _profileHeaderUser = cur.copyWith(
            isBlocked: true,
            isFollowing: false,
            followersCount: (cur.followersCount != null && wasFollowingMe)
                ? (cur.followersCount! - 1).clamp(0, 1 << 30)
                : cur.followersCount,
            followingCount: (cur.followingCount != null && wasIFollow)
                ? (cur.followingCount! - 1).clamp(0, 1 << 30)
                : cur.followingCount,
          );
        } else {
          // Bỏ chặn: khôi phục từ snapshot (nếu hệ thống/luật của bạn giữ follow sau unblock)
          final snap = _preBlock.remove(id);
          const restoreFollowRelation =
              true; // đổi false nếu KHÔNG muốn khôi phục follow

          _profileHeaderUser = cur.copyWith(
            isBlocked: false,
            isFollowing: restoreFollowRelation
                ? (snap?.isFollowing ?? cur.isFollowing)
                : cur.isFollowing,
            followersCount: restoreFollowRelation
                ? (snap?.followersCount ?? cur.followersCount)
                : cur.followersCount,
            followingCount: restoreFollowRelation
                ? (snap?.followingCount ?? cur.followingCount)
                : cur.followingCount,
          );
        }
      }

      // (Tuỳ chọn) Nếu muốn đồng bộ list followers/following trong trang profile:
      // nếu blocked thì loại user khỏi danh sách… (bạn có thể bỏ nếu backend tự xử)
      if (blocked) {
        _blockedIds.add(id);
        if (!_blockedUsers.any((u) => u.id == id)) {
          final src =
              (_profileHeaderUser?.id == id) ? _profileHeaderUser : null;
          // tạo list mới để đổi reference
          _blockedUsers = [
            SocialUser(
              id: id,
              displayName: src?.displayName,
              userName: src?.userName,
              avatarUrl: src?.avatarUrl,
              coverUrl: src?.coverUrl,
            ),
            ..._blockedUsers,
          ];
        } else {
          _blockedUsers = List<SocialUser>.from(_blockedUsers);
        }
      } else {
        _blockedIds.remove(id);
        _blockedUsers.removeWhere((u) => u.id == id);
        _blockedUsers = List<SocialUser>.from(_blockedUsers); // đổi reference
      }
      notifyListeners();
      return blocked;
    } finally {
      _blockBusy.remove(id);
      notifyListeners();
    }
  }

  Future<void> refreshBlockedUsers({bool force = false}) async {
    if (_loadingBlocked) return;
    if (!force && _blockedUsers.isNotEmpty) return;

    _loadingBlocked = true;
    notifyListeners();
    try {
      // YÊU CẦU: service.getBlockedUsers() trả về List<SocialUser>
      final users = await service.getBlockedUsers();

      _blockedUsers = users;
      _blockedIds = users.map((u) => u.id).toSet();

      // Đồng bộ cờ isBlocked cho header profile nếu đang mở
      if (_profileHeaderUser != null) {
        final isBlockedNow = _blockedIds.contains(_profileHeaderUser!.id);
        _profileHeaderUser = _profileHeaderUser!.copyWith(
          isBlocked: isBlockedNow,
          // (tùy luật) nếu bị chặn thì cũng coi như không còn follow
          isFollowing: isBlockedNow ? false : _profileHeaderUser!.isFollowing,
        );
      }
    } finally {
      _loadingBlocked = false;
      notifyListeners();
    }
  }

  Future<void> loadBlockedUsersIfEmpty({bool force = false}) async {
    // Nếu force => luôn tải lại; nếu không => chỉ tải khi list đang trống
    if (force) {
      await refreshBlockedUsers(force: true);
    } else {
      if (!_loadingBlocked && _blockedUsers.isEmpty) {
        await refreshBlockedUsers(force: true);
      }
    }
  }

  /// Unblock nhanh từ danh sách đã chặn (UI gọi)
  Future<bool> unblockFromList(String userId) async {
    if (userId.isEmpty) return false;
    try {
      // toggleBlockUser trả về "blocked" (true nếu đang chặn). Với block:false
      // thì kết quả mong muốn là false (đã bỏ chặn).
      final bool blocked = await toggleBlockUser(
        targetUserId: userId,
        block: false,
      );
      // Sau khi toggleBlockUser, danh sách _blockedUsers/_blockedIds đã được đồng bộ.
      return !blocked; // true = đã bỏ chặn thành công
    } catch (_) {
      rethrow;
    }
  }

  //photo
  Future<void> refreshProfilePhotos({String? targetUserId}) async {
    if (_loadingProfilePhotos) return;
    _loadingProfilePhotos = true;
    _photosOffset = null;
    _hasMoreProfilePhotos = true;
    notifyListeners();

    try {
      final photos = await service.getUserPhotos(
        targetUserId:
            targetUserId ?? _profileHeaderUser?.id ?? _currentUser?.id,
        limit: 35,
        offset: null,
      );
      _profilePhotos = photos;
      // Nếu backend không trả offset/has_more, ta ước lượng theo limit
      _hasMoreProfilePhotos = photos.length >= 35;
    } catch (e) {
      _profilePhotos = <SocialPhoto>[];
      _hasMoreProfilePhotos = false;
    } finally {
      _loadingProfilePhotos = false;
      notifyListeners();
    }
  }

// ----- LOAD MORE -----
  Future<void> loadMoreProfilePhotos({String? targetUserId}) async {
    if (_loadingProfilePhotos || !_hasMoreProfilePhotos) return;
    _loadingProfilePhotos = true;
    notifyListeners();

    try {
      final photos = await service.getUserPhotos(
        targetUserId:
            targetUserId ?? _profileHeaderUser?.id ?? _currentUser?.id,
        limit: 35,
        offset: _photosOffset,
      );
      if (photos.isEmpty) {
        _hasMoreProfilePhotos = false;
      } else {
        _profilePhotos = [..._profilePhotos, ...photos];
        // cập nhật _photosOffset nếu backend có trả trong resp (tuỳ bạn mở rộng)
        _hasMoreProfilePhotos = photos.length >= 35;
      }
    } finally {
      _loadingProfilePhotos = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfileReels(
      {String? targetUserId, int limit = 20}) async {
    if (_loadingProfileReels) return;

    final String? viewedId =
        targetUserId ?? _profileHeaderUser?.id ?? _currentUser?.id;
    if (viewedId == null || viewedId.isEmpty) {
      // không có user để load
      _profileReels = <SocialReel>[];
      _hasMoreProfileReels = false;
      notifyListeners();
      return;
    }

    _loadingProfileReels = true;
    // Nếu đổi sang user khác => reset paging
    if (_reelsForUserId != viewedId) {
      _reelsOffset = null;
      _profileReels = <SocialReel>[];
      _hasMoreProfileReels = true;
      _reelsForUserId = viewedId;
    }
    notifyListeners();

    try {
      // YÊU CẦU: service có getUserReels(type='videos' ở repo)
      final List<SocialReel> reels = await service.getUserReels(
        targetUserId: viewedId,
        limit: limit,
        offset: null,
      );

      _profileReels = reels;
      _hasMoreProfileReels = reels.length >= limit;
      // Nếu repo/service có trả next offset => gán _reelsOffset ở đây
      // _reelsOffset = service.lastReelsOffset; // (tuỳ bạn mở rộng)
    } catch (_) {
      _profileReels = <SocialReel>[];
      _hasMoreProfileReels = false;
    } finally {
      _loadingProfileReels = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreProfileReels(
      {String? targetUserId, int limit = 20}) async {
    if (_loadingProfileReels || !_hasMoreProfileReels) return;

    final String? viewedId =
        targetUserId ?? _profileHeaderUser?.id ?? _currentUser?.id;
    if (viewedId == null || viewedId.isEmpty) return;

    // Nếu userId đổi mà bạn chưa refresh => ép refresh trước
    if (_reelsForUserId != viewedId) {
      await refreshProfileReels(targetUserId: viewedId, limit: limit);
      return;
    }

    _loadingProfileReels = true;
    notifyListeners();

    try {
      final List<SocialReel> reels = await service.getUserReels(
        targetUserId: viewedId,
        limit: limit,
        offset: _reelsOffset,
      );

      if (reels.isEmpty) {
        _hasMoreProfileReels = false;
      } else {
        _profileReels = <SocialReel>[..._profileReels, ...reels];
        _hasMoreProfileReels = reels.length >= limit;
        // nếu backend có trả offset => cập nhật
        // _reelsOffset = service.lastReelsOffset; // (tuỳ bạn mở rộng)
      }
    } finally {
      _loadingProfileReels = false;
      notifyListeners();
    }
  }

  //report user
  /// Trả về message từ server (nếu có), đồng thời show snackbar nếu có context.
  Future<String> reportUser({
    String? targetUserId,
    required String text,
  }) async {
    final String trimmed = text.trim();

    // Xác định id mục tiêu: ưu tiên tham số, fallback header user
    final String? id = (targetUserId != null && targetUserId.isNotEmpty)
        ? targetUserId
        : _profileHeaderUser?.id;

    if (id == null || id.isEmpty) {
      throw Exception('Không xác định người cần báo cáo.');
    }

    // Không cho báo cáo chính mình
    if (_currentUser?.id == id) {
      throw Exception('Bạn không thể báo cáo chính mình.');
    }

    if (trimmed.isEmpty) {
      throw Exception('Vui lòng nhập nội dung báo cáo.');
    }

    // Chặn double-tap
    if (_reportBusy.contains(id)) {
      throw Exception('Đang gửi báo cáo, vui lòng đợi...');
    }
    _reportBusy.add(id);
    notifyListeners();

    try {
      // YÊU CẦU: SocialServiceInterface phải có reportUser(targetUserId, text)
      // Service nên trả về String message (hoặc throw nếu lỗi).
      final String msg = await service.reportUser(
        targetUserId: id,
        text: trimmed,
      );

      final ctx = Get.context; // nếu bạn đang dùng GetX cho context
      if (ctx != null) {
        final okMsg = (msg.isNotEmpty) ? msg : 'Đã gửi báo cáo';
        showCustomSnackBar(okMsg, ctx, isError: false);
      }
      return msg;
    } catch (e) {
      final ctx = Get.context;
      if (ctx != null) {
        showCustomSnackBar(e.toString(), ctx, isError: true);
      }
      rethrow;
    } finally {
      _reportBusy.remove(id);
      notifyListeners();
    }
  }

  //photo

  //edit prodile user by aoanhan

  Future<SocialUserProfile> updateDataUserFromEdit(
    SocialUserProfile edited, {
    String? currentPassword,
    String? newPassword,
    String? ecomToken,
  }) async {
    if (_updatingProfile) {
      throw Exception('Đang cập nhật hồ sơ, vui lòng đợi xíu...');
    }
    _updatingProfile = true;
    notifyListeners();

    // helper nhỏ để bóc path local (nếu bạn chưa dùng extension avatarLocalPath/coverLocalPath)
    String? _localPath(String? s) {
      if (s == null || s.isEmpty) return null;
      if (s.startsWith('file://')) return s.substring(7);
      if (s.startsWith('/')) return s;
      return null;
    }

    // Ưu tiên password truyền từ tham số; fallback sang field trong model (nếu bạn có giữ tạm)
    String? cp = (currentPassword ?? edited.currentPassword)?.trim();
    String? np = (newPassword ?? edited.newPassword)?.trim();

    // Nếu chỉ nhập 1 trong 2 -> báo lỗi sớm
    if ((cp?.isNotEmpty ?? false) ^ (np?.isNotEmpty ?? false)) {
      _updatingProfile = false;
      notifyListeners();
      throw Exception('Vui lòng nhập đủ Mật khẩu hiện tại và Mật khẩu mới');
    }
    // Rule cơ bản cho mật khẩu mới
    if ((np?.isNotEmpty ?? false) && (np!.length < 6)) {
      _updatingProfile = false;
      notifyListeners();
      throw Exception('Mật khẩu mới phải từ 6 ký tự trở lên');
    }

    try {
      // Nếu bạn đã thêm extension SocialUserProfileX, có thể dùng:
      // final avatarLocal = edited.avatarLocalPath;
      // final coverLocal  = edited.coverLocalPath;
      final String? avatarLocal = _localPath(edited.avatarUrl);
      final String? coverLocal = _localPath(edited.coverUrl);

      // Gọi Service: thêm first_name, last_name, current/new_password
      final updated = await service.updateDataUser(
        // --- tên ---
        displayName: edited.displayName, // required String? (có thể null)
        firstName: edited.firstName,
        lastName: edited.lastName,

        // --- thông tin khác ---
        about: edited.about,
        genderText: edited.genderText,
        birthdayIso: edited.birthday, // yyyy-MM-dd
        address: edited.address,
        website: edited.website,
        relationshipText: edited.relationshipStatus,

        // --- mật khẩu (chỉ gửi khi cả 2 đều có giá trị) ---
        currentPassword: (cp?.isNotEmpty ?? false) ? cp : null,
        newPassword: (np?.isNotEmpty ?? false) ? np : null,

        // --- file ảnh ---
        avatarFilePath: avatarLocal,
        coverFilePath: coverLocal,
        ecomToken: ecomToken,
      );

      // Đồng bộ lại header/current user (giữ nguyên như cũ)
      if (_profileHeaderUser?.id == updated.id) {
        _profileHeaderUser = updated;
      }
      if (_currentUser?.id == updated.id) {
        _currentUser = SocialUser(
          id: _currentUser!.id,
          displayName: updated.displayName ?? _currentUser!.displayName,
          userName: updated.userName ?? _currentUser!.userName,
          avatarUrl: updated.avatarUrl ?? _currentUser!.avatarUrl,
          coverUrl: updated.coverUrl ?? _currentUser!.coverUrl,
        );
      }

      notifyListeners();
      return updated;
    } catch (e) {
      showCustomSnackBar(e.toString(), Get.context!, isError: true);
      rethrow;
    } finally {
      _updatingProfile = false;
      notifyListeners();
    }
  }

  Future<void> loadUserGroups({bool forceRefresh = false}) async {
    if (_loadingUserGroups) return;
    if (!forceRefresh && _userGroupsFetched) return;

    _loadingUserGroups = true;
    notifyListeners();

    try {
      final List<SocialGroup> joined =
          await service.getMyGroups(type: 'joined_groups');
      final List<SocialGroup> mine =
          await service.getMyGroups(type: 'my_groups');

      final Map<String, SocialGroup> merged = <String, SocialGroup>{};
      for (final SocialGroup group in joined) {
        merged[group.id] = group;
      }
      for (final SocialGroup group in mine) {
        merged[group.id] = group;
      }

      final List<SocialGroup> ordered = merged.values.toList()
        ..sort((a, b) {
          final DateTime aTime = a.updatedAt ??
              a.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final DateTime bTime = b.updatedAt ??
              b.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });

      _userGroups
        ..clear()
        ..addAll(ordered);
      _userGroupsFetched = true;
      _groupPosts.clear();
      _groupPostsFetched = false;
    } catch (e) {
      final ctx = Get.context;
      if (ctx != null) {
        showCustomSnackBar(e.toString(), ctx, isError: true);
      }
    } finally {
      _loadingUserGroups = false;
      notifyListeners();
    }
  }

  Future<void> loadGroupPosts({bool forceRefresh = false}) async {
    if (_loadingGroupPosts) return;
    if (!forceRefresh && _groupPostsFetched) return;

    if (_userGroups.isEmpty && !_loadingUserGroups) {
      await loadUserGroups(forceRefresh: forceRefresh);
    }
    if (_userGroups.isEmpty) {
      _groupPosts.clear();
      _groupPostsFetched = true;
      notifyListeners();
      return;
    }

    _loadingGroupPosts = true;
    notifyListeners();

    try {
      final List<SocialPost> aggregated = <SocialPost>[];
      for (final SocialGroup group in _userGroups) {
        try {
          final SocialFeedPage page =
              await service.getGroupFeed(groupId: group.id, limit: 10);
          for (final SocialPost post in page.posts) {
            aggregated.add(post.copyWith(
              isGroupPost: true,
              groupId: group.id,
              groupName: group.name,
              groupTitle: group.title ?? post.groupTitle,
              groupUrl: group.url ?? post.groupUrl,
              groupAvatar: group.avatarUrl ?? post.groupAvatar,
              groupCover: group.coverUrl ?? post.groupCover,
            ));
          }
        } catch (e) {
          debugPrint('Failed to load posts for group ${group.id}: $e');
        }
      }
      _groupPosts
        ..clear()
        ..addAll(aggregated);
      _groupPostsFetched = true;
    } catch (e) {
      final ctx = Get.context;
      if (ctx != null) {
        showCustomSnackBar(e.toString(), ctx, isError: true);
      }
    } finally {
      _loadingGroupPosts = false;
      notifyListeners();
    }
  }

  String _storyKey(SocialStory story) {
    final userKey = story.userId;
    if (userKey != null && userKey.isNotEmpty) {
      return 'user:$userKey';
    }
    return 'story:${story.id}';
  }

  int _storyComparator(SocialStory a, SocialStory b) {
    final aTime =
        a.firstItem?.postedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime =
        b.firstItem?.postedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  }

  List<SocialStory> _normalizeStories(Iterable<SocialStory> source) {
    final now = DateTime.now();
    final result = <String, SocialStory>{};

    for (final story in source) {
      final filteredItems = <SocialStoryItem>[];
      for (final item in story.items) {
        final posted = item.postedAt;
        final expire = item.expireAt;
        final within24h = posted == null ||
            now.difference(posted) <= const Duration(hours: 24);
        final notExpired = expire == null || expire.isAfter(now);
        if (within24h && notExpired) {
          filteredItems.add(item);
        }
      }
      if (filteredItems.isEmpty) continue;

      filteredItems.sort((a, b) {
        final aTime = a.postedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.postedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      final SocialStoryItem first = filteredItems.first;
      final normalized = story.copyWith(
        items: filteredItems,
        thumbUrl: first.thumbUrl ?? first.mediaUrl ?? story.thumbUrl,
        mediaUrl: first.mediaUrl ?? first.thumbUrl ?? story.mediaUrl,
      );
      result[_storyKey(normalized)] = normalized;
    }

    final ordered = result.values.toList()..sort(_storyComparator);
    return ordered;
  }

  void _syncCurrentUserStoryFrom(Iterable<SocialStory> source,
      {bool resetIfMissing = false}) {
    if (_currentUser == null) {
      if (resetIfMissing) {
        _currentUserStory = null;
      }
      return;
    }
    final userId = _currentUser!.id;
    SocialStory? found;
    for (final story in source) {
      if (story.userId == userId) {
        found = story;
        break;
      }
    }
    if (found != null) {
      _currentUserStory = found;
    } else if (resetIfMissing) {
      _currentUserStory = null;
    }
  }

  int _findStoryIndex(SocialStory target) {
    final key = _storyKey(target);
    final idx = _stories.indexWhere((story) => _storyKey(story) == key);
    if (idx != -1) {
      return idx;
    }
    return _stories.indexWhere((story) => story.id == target.id);
  }

  void _replaceStoryItem(
      int storyIndex, int itemIndex, SocialStoryItem newItem) {
    if (storyIndex < 0 ||
        storyIndex >= _stories.length ||
        itemIndex < 0 ||
        itemIndex >= _stories[storyIndex].items.length) {
      return;
    }
    final SocialStory story = _stories[storyIndex];
    final List<SocialStoryItem> updatedItems =
        List<SocialStoryItem>.from(story.items);
    updatedItems[itemIndex] = newItem;
    _stories[storyIndex] = story.copyWith(items: updatedItems);
    _syncCurrentUserStoryFrom(_stories);
  }

  StoryViewersState? storyViewersState(String storyItemId) =>
      _storyViewers[storyItemId];

  void _replaceStories(Iterable<SocialStory> source) {
    final original = source.toList();
    final normalized = _normalizeStories(original);
    _stories
      ..clear()
      ..addAll(normalized);
    _storiesOffset = original.length;
    _syncCurrentUserStoryFrom(_stories, resetIfMissing: true);
  }

  void _mergeStories(Iterable<SocialStory> source) {
    final normalized = _normalizeStories(source);
    if (normalized.isEmpty) return;

    final map = <String, SocialStory>{
      for (final story in _stories) _storyKey(story): story,
    };
    for (final story in normalized) {
      map[_storyKey(story)] = story;
    }

    final merged = map.values.toList()..sort(_storyComparator);
    _stories
      ..clear()
      ..addAll(merged);
    _syncCurrentUserStoryFrom(_stories);
  }

  Future<void> _reloadStoriesFromServer({int? limit}) async {
    final effectiveLimit =
        limit ?? (_stories.isNotEmpty ? _stories.length : 10);
    final fresh = await service.getMyStories(limit: effectiveLimit, offset: 0);
    _replaceStories(fresh);
    notifyListeners();
  }

  SocialPost? findPostById(String id) {
    for (final list in <List<SocialPost>>[
      _posts,
      _groupPosts,
      _profilePosts,
      _savedPosts,
    ]) {
      for (final post in list) {
        if (post.id == id) {
          return post;
        }
      }
    }
    return null;
  }

  void _updatePost(String id, SocialPost newPost) {
    bool changed = false;

    final int feedIndex = _posts.indexWhere((e) => e.id == id);
    if (feedIndex != -1) {
      _posts[feedIndex] = newPost;
      changed = true;
    }

    final int groupIndex = _groupPosts.indexWhere((e) => e.id == id);
    if (groupIndex != -1) {
      _groupPosts[groupIndex] = newPost;
      changed = true;
    }

    final int profileIndex = _profilePosts.indexWhere((p) => p.id == id);
    if (profileIndex != -1) {
      _profilePosts[profileIndex] = newPost;
      changed = true;
    }

    final int savedIndex = _savedPosts.indexWhere((p) => p.id == id);
    if (savedIndex != -1) {
      _savedPosts[savedIndex] = newPost;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  bool _removePostEverywhere(String id) {
    bool removed = false;

    final int feedBefore = _posts.length;
    _posts.removeWhere((p) => p.id == id);
    if (_posts.length != feedBefore) {
      removed = true;
    }

    final int groupBefore = _groupPosts.length;
    _groupPosts.removeWhere((p) => p.id == id);
    if (_groupPosts.length != groupBefore) {
      removed = true;
    }

    final int profileBefore = _profilePosts.length;
    _profilePosts.removeWhere((p) => p.id == id);
    if (_profilePosts.length != profileBefore) {
      removed = true;
    }

    return removed;
  }

  // ========== POST CREATION ==========
  Future<SocialPost?> createPost({
    String? text,
    List<String>? imagePaths,
    String? videoPath,
    String? videoThumbnailPath,
    int privacy = 0,
    String? backgroundColorId,
    String? feelingType,
    String? feelingValue,
    String? groupId,
    String? postMap,
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
        feelingType: feelingType,
        feelingValue: feelingValue,
        groupId: groupId,
        postMap: postMap,
      );
      final SocialPost normalized = groupId != null
          ? post.copyWith(
              isGroupPost: true,
              groupId: groupId,
            )
          : post;
      _posts.insert(0, normalized);
      final String? colorId = backgroundColorId ?? normalized.backgroundColorId;
      if (colorId != null && colorId.isNotEmpty) {
        ensureBackgroundPreset(colorId);
      }
      return normalized;
    } catch (e) {
      showCustomSnackBar(e.toString(), Get.context!, isError: true);
      rethrow;
    } finally {
      _creatingPost = false;
      notifyListeners();
    }
  }

  // ========== STORY CREATION ==========
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
        _mergeStories([story]);
        notifyListeners();
        final int reloadLimit = (_stories.length + 5).clamp(10, 50);
        await _reloadStoriesFromServer(limit: reloadLimit);
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
  // ========== POKE CREATION ==========
  Future<bool> createPoke(int userId) async {
    if (_creatingPoke) return false;
    _creatingPoke = true;
    notifyListeners();

    try {
      final bool ok = await service.createPoke(userId);
      if (ok) {
        fetchPokes(); // ✔ reload danh sách
      }
      return ok;// ok = true hoặc false
    } catch (e) {
      showCustomSnackBar(e.toString(), Get.context!, isError: true);
      return false;
    } finally {
      _creatingPoke = false;
      notifyListeners();
    }
  }
  Future<void> fetchPokes() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      pokes = await service.fetchPokes();
    } catch (e) {
      print("POKES ERROR: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
  Future<bool> removePoke(int pokeId) async {
    try {
      final ok = await service.removePoke(pokeId);
      if (ok) {
        pokes.removeWhere(
              (e) => int.parse(e["id"].toString()) == pokeId,
        );
        notifyListeners();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }
  // ================= ADD TO FAMILY =================
  Future<bool> addToFamily(int userId, String relationshipType) async {
    if (_addingFamily) return false;
    _addingFamily = true;
    notifyListeners();

    try {
      final bool ok = await service.addToFamily(userId, relationshipType);
      return ok;
    } catch (e) {
      showCustomSnackBar(e.toString(), Get.context!, isError: true);
      return false;
    } finally {
      _addingFamily = false;
      notifyListeners();
    }
  }


  void setAccessToken(String token) {
    _accessToken = token;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> createLive() async {
    if (_accessToken == null) throw Exception('Thiếu accessToken');

    try {
      _creatingLive = true;
      notifyListeners();

      final repo = SocialLiveRepository(
        apiBaseUrl: 'https://social.vnshop247.com',
        serverKey:
            'f6e69c898ddd643154c9bd4b152555842e26a868-d195c100005dddb9f1a30a67a5ae42d4-19845955',
      );

      final data = await repo.createLive(
        accessToken: _accessToken!,
        streamName: 'live_${DateTime.now().millisecondsSinceEpoch}',
      );
      return data;
    } catch (e) {
      rethrow;
    } finally {
      _creatingLive = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createLiveSession({int? broadcasterUid}) async {
    final String? token = _accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Missing access token');
    }

    _creatingLive = true;
    notifyListeners();

    try {
      final SocialLiveRepository repo = SocialLiveRepository(
        apiBaseUrl: AppConstants.socialBaseUrl,
        serverKey: AppConstants.socialServerKey,
      );

      final String rawUserId = (_currentUser?.id ?? '').trim();
      String idSegment = rawUserId.replaceAll(RegExp(r'[^0-9]'), '');
      if (idSegment.isEmpty) {
        idSegment = '0';
      }

      final int timestamp = DateTime.now().microsecondsSinceEpoch;
      int randomComponent = timestamp.remainder(10000000);
      if (randomComponent <= 0) {
        randomComponent =
            DateTime.now().millisecondsSinceEpoch.remainder(10000000);
        if (randomComponent <= 0) {
          randomComponent = 1;
        }
      }

      const int tokenUid = 0;
      String streamName = 'stream_${idSegment}_$randomComponent';
      final String baseStreamName = streamName;

      Map<String, dynamic>? agoraPayload;
      String? tokenAgora;
      try {
        agoraPayload = await repo.generateAgoraToken(
          accessToken: token,
          channelName: streamName,
          uid: tokenUid,
          role: 'publisher',
        );
        tokenAgora = (agoraPayload?['token_agora'] ?? agoraPayload?['token'])
            ?.toString();
        final String? payloadChannel =
            agoraPayload?['channel_name']?.toString() ??
                agoraPayload?['channel']?.toString();
        if (payloadChannel != null && payloadChannel.isNotEmpty) {
          streamName = payloadChannel;
        }
      } catch (error) {
        debugPrint('generateAgoraToken failed: $error');
        throw Exception('Failed to generate Agora token: $error');
      }

      if (tokenAgora == null || tokenAgora.isEmpty) {
        throw Exception('Agora token response is empty.');
      }

      if (streamName.trim().isEmpty) {
        streamName = baseStreamName;
      }

      final Map<String, dynamic> postData = await repo.createLive(
        accessToken: token,
        streamName: streamName,
        token: tokenAgora,
      );

      postData.putIfAbsent('agora_token', () => tokenAgora);

      final Map<String, dynamic> result = <String, dynamic>{
        'post_data': postData,
        'stream_name': streamName,
        'uid': tokenUid,
        'token': tokenAgora,
      };

      if (agoraPayload != null) {
        result['agora'] = agoraPayload;
      }

      return result;
    } finally {
      _creatingLive = false;
      notifyListeners();
    }
  }

  // ========== LOAD CURRENT USER ==========
  Future<void> loadCurrentUser({bool force = false}) async {
    if (_loadingUser) return;
    if (!force && _currentUser != null) return;

    _loadingUser = true;
    try {
      final sp = await SharedPreferences.getInstance();
      _accessToken ??= sp.getString(AppConstants.socialAccessToken);

      if (_accessToken == null || _accessToken!.isEmpty) {
        _currentUser = null;
        _syncCurrentUserStoryFrom(_stories);
        notifyListeners();
        return;
      }

      final user = await service.getCurrentUser();

      if (user != null) {
        _currentUser = user;
        _syncCurrentUserStoryFrom(_stories);
        notifyListeners();
      }
    } catch (e) {
      showCustomSnackBar(e.toString(), Get.context!, isError: true);
    } finally {
      _loadingUser = false;
    }
  }

  Future<void> loadPostBackgrounds({bool force = false}) async {
    if (_loadingPostColors) return;
    if (!force && _postColorsFetchedAt != null) return;
    _loadingPostColors = true;
    notifyListeners();
    try {
      final List<SocialPostColor> remote = await service.getPostColors();
      final List<PostBackgroundPreset> presets =
          PostBackgroundPresets.fromRemote(remote);
      if (presets.isNotEmpty) {
        _postBackgroundPresets = presets;
        _backgroundPresetIds
          ..clear()
          ..addAll(presets.map((preset) => preset.id));
      } else {
        _resetBackgroundPresetsToDefaults();
      }
      _postColorsFetchedAt = DateTime.now();
    } catch (_) {
      _resetBackgroundPresetsToDefaults();
    } finally {
      _loadingPostColors = false;
      notifyListeners();
    }
  }

  void _prefetchBackgroundsForPosts(Iterable<SocialPost> posts) {
    for (final SocialPost post in posts) {
      final String? id = post.backgroundColorId;
      if (id != null && id.isNotEmpty) {
        ensureBackgroundPreset(id);
      }
    }
  }

  Future<void> ensureBackgroundPreset(String id) async {
    if (id.isEmpty) return;
    if (_backgroundPresetIds.contains(id)) return;
    if (_pendingColorFetch.contains(id)) return;

    final PostBackgroundPreset? fallback =
        PostBackgroundPresets.findById(PostBackgroundPresets.defaults, id);
    if (fallback != null) {
      _backgroundPresetIds.add(id);
      _postBackgroundPresets.add(fallback);
      notifyListeners();
      return;
    }

    _pendingColorFetch.add(id);
    try {
      final SocialPostColor? color = await service.getPostColorById(id);
      if (color == null) return;
      final PostBackgroundPreset preset =
          PostBackgroundPreset.fromSocialColor(color);
      if (!preset.hasGradient && !preset.hasImage) return;
      if (_backgroundPresetIds.contains(preset.id)) return;
      _backgroundPresetIds.add(preset.id);
      _postBackgroundPresets.add(preset);
      notifyListeners();
    } catch (_) {
      // ignore failures
    } finally {
      _pendingColorFetch.remove(id);
    }
  }

  // ========== NEWS FEED OPERATIONS ==========
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
      _prefetchBackgroundsForPosts(list);

      final userStories = await service.getMyStories(limit: 10, offset: 0);
      _replaceStories(userStories);

      if (_posts.isEmpty) {
        showCustomSnackBar('Không có bài viết. Vui lòng đăng nhập.',
            navigatorKey.currentContext!);
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loading) return;
    final scheduler = SchedulerBinding.instance;
    final phase = scheduler.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks) {
      if (_pendingLoadMore) return;
      _pendingLoadMore = true;
      scheduler.addPostFrameCallback((_) {
        _pendingLoadMore = false;
        loadMore();
      });
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      final list = await service.getNewsFeed(limit: 10, afterPostId: _afterId);
      if (list.isNotEmpty) {
        _posts.addAll(list);
        _afterId = list.last.id;
        _prefetchBackgroundsForPosts(list);
      }
    } catch (e) {
      showCustomSnackBar(e.toString(), Get.context!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ========== STORY REACTIONS ==========
  Future<void> refreshSavedPosts() async {
    if (_loadingSavedPosts) return;
    _loadingSavedPosts = true;
    _hasMoreSavedPosts = true;
    notifyListeners();
    try {
      final List<SocialPost> list =
          await service.getSavedPosts(limit: _savedPostsPageSize);
      _savedPosts
        ..clear()
        ..addAll(list);
      _savedAfterId = list.isNotEmpty ? list.last.id : null;
      _hasMoreSavedPosts = list.length >= _savedPostsPageSize;
    } finally {
      _loadingSavedPosts = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreSavedPosts() async {
    if (_loadingSavedPosts || !_hasMoreSavedPosts) return;
    final String? anchorId =
        _savedAfterId ?? (_savedPosts.isNotEmpty ? _savedPosts.last.id : null);
    _loadingSavedPosts = true;
    notifyListeners();
    try {
      final List<SocialPost> list = await service.getSavedPosts(
        limit: _savedPostsPageSize,
        afterPostId: anchorId,
      );
      if (list.isEmpty) {
        if (_savedPosts.isNotEmpty) {
          _hasMoreSavedPosts = false;
        }
        return;
      }
      _savedPosts.addAll(list);
      _savedAfterId = list.last.id;
      if (list.length < _savedPostsPageSize) {
        _hasMoreSavedPosts = false;
      }
    } finally {
      _loadingSavedPosts = false;
      notifyListeners();
    }
  }

  Future<void> markStoryItemViewed({
    required SocialStory story,
    required SocialStoryItem item,
  }) async {
    final String storyItemId = item.id;
    if (storyItemId.isEmpty) return;

    final String? currentUserId = currentUser?.id;
    final String? ownerId = story.userId ?? item.userId;
    if (currentUserId != null && ownerId != null && currentUserId == ownerId) {
      return;
    }

    if (item.isViewed) {
      _viewedStoryItemIds.add(storyItemId);
      return;
    }
    if (_viewedStoryItemIds.contains(storyItemId)) {
      return;
    }

    final int storyIndex = _findStoryIndex(story);
    if (storyIndex == -1) return;
    final int itemIndex = _stories[storyIndex]
        .items
        .indexWhere((element) => element.id == storyItemId);
    if (itemIndex == -1) return;

    final SocialStoryItem currentItem = _stories[storyIndex].items[itemIndex];
    if (currentItem.isViewed) {
      _viewedStoryItemIds.add(storyItemId);
      return;
    }

    final SocialStoryItem optimistic = currentItem.copyWith(
      isViewed: true,
      viewCount: (currentItem.viewCount ?? 0) + 1,
    );

    _viewedStoryItemIds.add(storyItemId);
    _replaceStoryItem(storyIndex, itemIndex, optimistic);
    notifyListeners();

    if (_storyViewInFlight.contains(storyItemId)) {
      return;
    }
    _storyViewInFlight.add(storyItemId);

    try {
      final SocialStory? refreshed =
          await service.getStoryById(storyId: storyItemId);
      if (refreshed != null && refreshed.items.isNotEmpty) {
        final SocialStoryItem? refreshedItem = refreshed.items.firstWhere(
          (element) => element.id == storyItemId,
          orElse: () => refreshed.items.first,
        );
        if (refreshedItem != null) {
          final int latestStoryIndex = _findStoryIndex(story);
          if (latestStoryIndex != -1) {
            final int latestItemIndex = _stories[latestStoryIndex]
                .items
                .indexWhere((element) => element.id == storyItemId);
            if (latestItemIndex != -1) {
              _replaceStoryItem(
                  latestStoryIndex,
                  latestItemIndex,
                  refreshedItem.copyWith(
                    isViewed: true,
                  ));
              notifyListeners();
            }
          }
        }
      }
    } catch (_) {
      _viewedStoryItemIds.remove(storyItemId);
      final int latestStoryIndex = _findStoryIndex(story);
      if (latestStoryIndex != -1) {
        final int latestItemIndex = _stories[latestStoryIndex]
            .items
            .indexWhere((element) => element.id == storyItemId);
        if (latestItemIndex != -1) {
          _replaceStoryItem(latestStoryIndex, latestItemIndex, currentItem);
        }
      }
      notifyListeners();
    } finally {
      _storyViewInFlight.remove(storyItemId);
    }
  }

  Future<void> reactOnStoryItem({
    required SocialStory story,
    required SocialStoryItem item,
    required String reaction,
    SocialStoryReaction? previousOverride,
    bool fromQueue = false,
  }) async {
    final int storyIndex = _findStoryIndex(story);
    if (storyIndex == -1) return;
    final SocialStory targetStory = _stories[storyIndex];
    final int itemIndex =
        targetStory.items.indexWhere((element) => element.id == item.id);
    if (itemIndex == -1) return;

    final SocialStoryItem currentItem = targetStory.items[itemIndex];

    final SocialStoryReaction originalReaction =
        currentItem.reaction ?? const SocialStoryReaction(isReacted: false);
    final SocialStoryReaction previous = previousOverride ?? originalReaction;
    final String normalized = normalizeSocialReaction(reaction);

    if (normalized.isEmpty && !previous.isReacted) {
      if (!fromQueue) {
        return;
      } else {
        if (!identical(currentItem.reaction, originalReaction)) {
          _replaceStoryItem(
            storyIndex,
            itemIndex,
            currentItem.copyWith(reaction: originalReaction),
          );
          notifyListeners();
        }
        return;
      }
    }

    final bool removeReaction = normalized.isEmpty;

    final String sendingReaction = removeReaction ? '' : normalized;
    final int? previousCount = previous.count;
    int? nextCount;
    if (previousCount != null) {
      int delta = 0;
      if (!removeReaction && normalized.isNotEmpty) {
        delta = 1;
      } else if (removeReaction && previousCount > 0) {
        delta = -1;
      }
      nextCount = (previousCount + delta).clamp(0, 1 << 30);
    } else if (!removeReaction && normalized.isNotEmpty) {
      nextCount = 1;
    }

    final SocialStoryReaction optimistic = SocialStoryReaction(
      isReacted: !removeReaction && normalized.isNotEmpty,
      type: removeReaction ? '' : normalized,
      count: nextCount,
    );

    final _PendingStoryReaction pending =
        _PendingStoryReaction(reaction: sendingReaction);

    if (_storyReactionLoading.contains(currentItem.id)) {
      final Queue<_PendingStoryReaction> queue =
          _queuedStoryReactions.putIfAbsent(
        currentItem.id,
        () => Queue<_PendingStoryReaction>(),
      );
      queue.add(pending);
      _replaceStoryItem(
        storyIndex,
        itemIndex,
        currentItem.copyWith(reaction: optimistic),
      );
      notifyListeners();
      return;
    }

    _storyReactionLoading.add(currentItem.id);

    _replaceStoryItem(
      storyIndex,
      itemIndex,
      currentItem.copyWith(reaction: optimistic),
    );
    notifyListeners();

    try {
      await service.reactToStory(
        storyId: currentItem.id,
        reaction: sendingReaction,
      );
    } catch (e) {
      _replaceStoryItem(
        storyIndex,
        itemIndex,
        currentItem.copyWith(reaction: originalReaction),
      );
      notifyListeners();
      final msg = e.toString();
      showCustomSnackBar(msg, Get.context!, isError: true);
    } finally {
      _storyReactionLoading.remove(currentItem.id);
      final Queue<_PendingStoryReaction>? queue =
          _queuedStoryReactions[currentItem.id];
      final _PendingStoryReaction? queued =
          queue != null && queue.isNotEmpty ? queue.removeFirst() : null;
      if (queue != null && queue.isEmpty) {
        _queuedStoryReactions.remove(currentItem.id);
      }
      if (queued != null) {
        final String storyKey = _storyKey(targetStory);
        final int refreshedStoryIndex =
            _stories.indexWhere((element) => _storyKey(element) == storyKey);
        if (refreshedStoryIndex != -1) {
          final SocialStory refreshedStory = _stories[refreshedStoryIndex];
          final SocialStoryItem refreshedItem = refreshedStory.items.firstWhere(
            (element) => element.id == currentItem.id,
            orElse: () => currentItem,
          );
          await reactOnStoryItem(
            story: refreshedStory,
            item: refreshedItem,
            reaction: queued.reaction,
            fromQueue: true,
          );
        }
      }
    }
  }

  // ========== STORY VIEWERS ==========
  Future<void> fetchStoryViewers(
    SocialStoryItem item, {
    bool refresh = false,
  }) async {
    final String key = item.id;
    final StoryViewersState previous =
        _storyViewers[key] ?? const StoryViewersState();

    if (!refresh && previous.loading) return;
    if (!refresh && !previous.hasMore && previous.viewers.isNotEmpty) return;

    final int offset = refresh ? 0 : previous.nextOffset;
    _storyViewers[key] = previous.copyWith(
      loading: true,
      viewers: refresh ? <SocialStoryViewer>[] : previous.viewers,
      hasMore: refresh ? true : previous.hasMore,
      nextOffset: offset,
      total: refresh ? (item.viewCount ?? previous.total) : previous.total,
      fetched: previous.fetched,
    );
    notifyListeners();

    try {
      final SocialStoryViewersPage page = await service.getStoryViews(
        storyId: item.id,
        limit: _storyViewersPageSize,
        offset: offset,
      );

      final List<SocialStoryViewer> merged = refresh
          ? <SocialStoryViewer>[]
          : List<SocialStoryViewer>.from(previous.viewers);

      for (final SocialStoryViewer viewer in page.viewers) {
        final String viewerKey =
            viewer.userId.isNotEmpty ? viewer.userId : viewer.id;
        final int existingIndex = merged.indexWhere((existing) {
          final String existingKey =
              existing.userId.isNotEmpty ? existing.userId : existing.id;
          return existingKey == viewerKey;
        });
        if (existingIndex >= 0) {
          merged[existingIndex] = viewer;
        } else {
          merged.add(viewer);
        }
      }

      merged.sort((a, b) {
        final DateTime aTime =
            a.viewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bTime =
            b.viewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      final int calculatedNextOffset = page.nextOffset > offset
          ? page.nextOffset
          : offset + page.viewers.length;
      final int total =
          page.total != 0 ? page.total : (item.viewCount ?? merged.length);

      _storyViewers[key] = StoryViewersState(
        viewers: merged,
        loading: false,
        hasMore: page.hasMore,
        nextOffset: calculatedNextOffset,
        total: total,
        fetched: true,
      );
    } catch (e) {
      _storyViewers[key] =
          previous.copyWith(loading: false, fetched: previous.fetched);
      notifyListeners();
      showCustomSnackBar(e.toString(), Get.context!, isError: true);
      return;
    }

    notifyListeners();
  }

  Future<void> refreshStoryViewers(SocialStoryItem item) =>
      fetchStoryViewers(item, refresh: true);

  Future<void> loadMoreStoryViewers(SocialStoryItem item) =>
      fetchStoryViewers(item, refresh: false);

  Future<void> loadMoreStories() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      final fetchedStories =
          await service.getMyStories(limit: 10, offset: _storiesOffset);
      if (fetchedStories.isNotEmpty) {
        _mergeStories(fetchedStories);
        _storiesOffset += fetchedStories.length;
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<SocialPost> reactOnPost(SocialPost post, String reaction) async {
    final was = post.myReaction;

    if (was.isNotEmpty && (reaction.isEmpty || reaction == 'Like')) {
      final updatedBreakdown =
          _adjustReactionBreakdown(post.reactionBreakdown, remove: was);
      final optimistic = post.copyWith(
        myReaction: '',
        reactionCount: (post.reactionCount - 1).clamp(0, 1 << 31),
        reactionBreakdown: updatedBreakdown,
      );
      _updatePost(post.id, optimistic);
      try {
        await service.reactToPost(
            postId: post.id, reaction: was, action: 'dislike');
        return optimistic;
      } catch (e) {
        _updatePost(post.id, post);
        showCustomSnackBar(e.toString(), Get.context!, isError: true);
        return post;
      }
    }
    final now = reaction;
    int delta = 0;
    if (was.isEmpty && now.isNotEmpty) delta = 1;
    if (was.isNotEmpty && now.isEmpty) delta = -1;
    final updatedBreakdown = _adjustReactionBreakdown(
      post.reactionBreakdown,
      remove: was,
      add: now,
    );
    final optimistic = post.copyWith(
      myReaction: now,
      reactionCount: (post.reactionCount + delta).clamp(0, 1 << 31),
      reactionBreakdown: updatedBreakdown,
    );
    _updatePost(post.id, optimistic);

    try {
      await service.reactToPost(
          postId: post.id, reaction: reaction, action: 'reaction');
      return optimistic;
    } catch (e) {
      _updatePost(post.id, post);
      final msg = e.toString();
      showCustomSnackBar(msg, Get.context!, isError: true);
      return post;
    }
  }

  // ========== POST SHARING ==========
  Future<bool> sharePost(SocialPost post, {String? text}) async {
    if (_sharingPosts.contains(post.id)) return false;
    _sharingPosts.add(post.id);
    notifyListeners();

    final SocialPost optimistic =
        post.copyWith(shareCount: post.shareCount + 1);
    _updatePost(post.id, optimistic);

    try {
      final SocialPost shared =
          await service.sharePost(postId: post.id, text: text);
      SocialPost resolved = shared;
      try {
        final SocialPost? refreshed =
            await service.getPostById(postId: shared.id);
        if (refreshed != null) {
          resolved = refreshed;
        }
      } catch (_) {
        // ignore fallback, optimistic shared data will be used
      }
      resolved = _ensureSharedLiveMetadata(resolved, post);
      _posts.insert(0, resolved);
      notifyListeners();
      final ctx = Get.context!;
      final successMsg = getTranslated('share_post_success', ctx) ??
          'Post shared successfully';
      showCustomSnackBar(successMsg, ctx, isError: false);
      return true;
    } catch (e) {
      _updatePost(post.id, post);
      showCustomSnackBar(e.toString(), Get.context!, isError: true);
      return false;
    } finally {
      _sharingPosts.remove(post.id);
      notifyListeners();
    }
  }

  SocialPost _ensureSharedLiveMetadata(
    SocialPost response,
    SocialPost original,
  ) {
    final String? originalType = original.postType?.toLowerCase();
    if (originalType != 'live') {
      return response;
    }

    SocialPost? shared = response.sharedPost;
    if (shared == null) {
      return response.copyWith(sharedPost: original);
    }

    bool changed = false;
    bool isBlank(String? value) => value == null || value.trim().isEmpty;

    if (isBlank(shared.postType) && !isBlank(original.postType)) {
      shared = shared.copyWith(postType: original.postType);
      changed = true;
    }
    if (isBlank(shared.liveStreamName) && !isBlank(original.liveStreamName)) {
      shared = shared.copyWith(liveStreamName: original.liveStreamName);
      changed = true;
    }
    if (isBlank(shared.liveAgoraToken) && !isBlank(original.liveAgoraToken)) {
      shared = shared.copyWith(liveAgoraToken: original.liveAgoraToken);
      changed = true;
    }
    if (isBlank(shared.liveResourceId) && !isBlank(original.liveResourceId)) {
      shared = shared.copyWith(liveResourceId: original.liveResourceId);
      changed = true;
    }
    if (isBlank(shared.liveSid) && !isBlank(original.liveSid)) {
      shared = shared.copyWith(liveSid: original.liveSid);
      changed = true;
    }
    if (shared.liveStartedAt == null && original.liveStartedAt != null) {
      shared = shared.copyWith(liveStartedAt: original.liveStartedAt);
      changed = true;
    }

    final String? fallbackThumbnail =
        !isBlank(original.thumbnailUrl) ? original.thumbnailUrl : null;
    final String? fallbackImage =
        !isBlank(original.imageUrl) ? original.imageUrl : fallbackThumbnail;
    if (isBlank(shared.thumbnailUrl) && !isBlank(fallbackThumbnail)) {
      shared = shared.copyWith(thumbnailUrl: fallbackThumbnail);
      changed = true;
    }
    if (isBlank(shared.imageUrl) && !isBlank(fallbackImage)) {
      shared = shared.copyWith(imageUrl: fallbackImage);
      changed = true;
    }
    if (shared.imageUrls.isEmpty && original.imageUrls.isNotEmpty) {
      shared = shared.copyWith(imageUrls: original.imageUrls);
      changed = true;
    }
    if (isBlank(shared.imageUrl) && shared.imageUrls.isNotEmpty) {
      shared = shared.copyWith(imageUrl: shared.imageUrls.first);
      changed = true;
    }
    if (isBlank(shared.thumbnailUrl) && !isBlank(shared.imageUrl)) {
      shared = shared.copyWith(thumbnailUrl: shared.imageUrl);
      changed = true;
    }
    if (isBlank(shared.videoUrl) && !isBlank(original.videoUrl)) {
      shared = shared.copyWith(videoUrl: original.videoUrl);
      changed = true;
    }
    if (isBlank(shared.fileUrl) && !isBlank(original.fileUrl)) {
      shared = shared.copyWith(fileUrl: original.fileUrl);
      changed = true;
    }

    final bool liveEnded = shared.liveEnded || original.liveEnded;
    if (liveEnded != shared.liveEnded) {
      shared = shared.copyWith(liveEnded: liveEnded);
      changed = true;
    }

    return changed ? response.copyWith(sharedPost: shared) : response;
  }

  Future<List<SocialUser>> searchMentionUsers({
    required String keyword,
    int limit = 8,
  }) async {
    final String normalized = keyword.trim().toLowerCase();
    if (normalized.isEmpty) return const <SocialUser>[];
    final List<SocialUser>? cached = _mentionCache[normalized];
    if (cached != null) {
      if (cached.length > limit) {
        return cached.sublist(0, limit);
      }
      return List<SocialUser>.from(cached);
    }
    try {
      final List<SocialUser> results =
          await service.searchUsers(keyword: keyword, limit: limit);
      final List<SocialUser> filtered = results
          .where(
              (SocialUser user) => (user.userName?.trim().isNotEmpty ?? false))
          .toList();
      for (final SocialUser user in filtered) {
        _cacheUser(user);
      }
      _mentionCache[normalized] = filtered;
      if (filtered.length > limit) {
        return filtered.sublist(0, limit);
      }
      return filtered;
    } catch (_) {
      _mentionCache.putIfAbsent(normalized, () => const <SocialUser>[]);
      return const <SocialUser>[];
    }
  }

  SocialUser? getCachedUserById(String id) {
    final String key = id.trim();
    if (key.isEmpty) return null;
    return _userCacheById[key];
  }

  SocialUser? getCachedUserByUsername(String username) {
    final String key = username.trim().toLowerCase();
    if (key.isEmpty) return null;
    return _userCacheByUsername[key];
  }

  String? getCachedMentionLabelById(String id) {
    final SocialUser? user = getCachedUserById(id);
    if (user == null) return null;
    if (user.userName?.isNotEmpty ?? false) return user.userName;
    if (user.displayName?.isNotEmpty ?? false) return user.displayName;
    return null;
  }

  Future<SocialUser?> resolveUserById(String id) async {
    final String key = id.trim();
    if (key.isEmpty) return null;
    final SocialUser? cached = _userCacheById[key];
    if (cached != null) return cached;
    try {
      final SocialUser? user = await service.getUserById(userId: key);
      if (user != null) {
        _cacheUser(user);
      }
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<SocialUser?> resolveUserByUsername(String username) async {
    final String key = username.trim().toLowerCase();
    if (key.isEmpty) return null;
    final SocialUser? cached = _userCacheByUsername[key];
    if (cached != null) return cached;
    try {
      final SocialUser? user =
          await service.getUserByUsername(username: username);
      if (user != null) {
        _cacheUser(user);
      }
      return user;
    } catch (_) {
      return null;
    }
  }

  void rememberUser(SocialUser user) => _cacheUser(user);

  void _cacheUser(SocialUser user) {
    _userCacheById[user.id] = user;
    final String? username = user.userName?.trim();
    if (username != null && username.isNotEmpty) {
      _userCacheByUsername[username.toLowerCase()] = user;
    }
  }

  Future<void> toggleSavePost(SocialPost post) async {
    if (_postActionBusy.contains(post.id)) return;
    _postActionBusy.add(post.id);
    notifyListeners();

    final BuildContext? ctx = Get.context;
    try {
      final String actionResult = await service.performPostAction(
        postId: post.id,
        action: 'save',
      );

      if (ctx != null) {
        final String lower = actionResult.toLowerCase();
        String? messageKey;
        if (lower.contains('unsaved')) {
          messageKey = 'post_unsaved';
        } else if (lower.contains('saved')) {
          messageKey = 'post_saved';
        }
        final String message = messageKey != null
            ? (getTranslated(messageKey, ctx) ?? actionResult)
            : actionResult;
        showCustomSnackBar(message, ctx, isError: false);
      }
    } catch (e) {
      if (ctx != null) {
        showCustomSnackBar(e.toString(), ctx, isError: true);
      }
    } finally {
      _postActionBusy.remove(post.id);
      notifyListeners();
    }
  }

  Future<void> hidePost(SocialPost post) async {
    if (_postActionBusy.contains(post.id)) return;
    _postActionBusy.add(post.id);
    notifyListeners();

    final BuildContext? ctx = Get.context;
    try {
      final String result = await service.hidePost(postId: post.id);
      final bool removed = _removePostEverywhere(post.id);
      if (removed) {
        notifyListeners();
      }
      if (ctx != null) {
        final String message = getTranslated('post_hidden', ctx) ?? result;
        showCustomSnackBar(message, ctx, isError: false);
      }
    } catch (e) {
      if (ctx != null) {
        showCustomSnackBar(e.toString(), ctx, isError: true);
      }
    } finally {
      _postActionBusy.remove(post.id);
      notifyListeners();
    }
  }

  Future<void> deletePost(SocialPost post) async {
    if (_postActionBusy.contains(post.id)) return;
    _postActionBusy.add(post.id);
    notifyListeners();

    final BuildContext? ctx = Get.context;
    try {
      Map<String, dynamic>? extra;
      if (post.pageId != null && post.pageId!.isNotEmpty) {
        extra = {'page_id': post.pageId};
      }
      if (post.groupId != null && post.groupId!.isNotEmpty) {
        (extra ??= {})['group_id'] = post.groupId;
      }
      final String result = await service.performPostAction(
        postId: post.id,
        action: 'delete',
        extraFields: extra,
      );
      final bool removed = _removePostEverywhere(post.id);
      if (removed) {
        notifyListeners();
      }
      if (ctx != null) {
        final String message = getTranslated('post_deleted', ctx) ?? result;
        showCustomSnackBar(message, ctx, isError: false);
      }
    } catch (e) {
      if (ctx != null) {
        showCustomSnackBar(e.toString(), ctx, isError: true);
      }
    } finally {
      _postActionBusy.remove(post.id);
      notifyListeners();
    }
  }

  Future<void> editPost(
    SocialPost post, {
    required String text,
    int? privacyType,
  }) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      final BuildContext? ctx = Get.context;
      if (ctx != null) {
        final String message = getTranslated('post_text_required', ctx) ??
            'Post text cannot be empty';
        showCustomSnackBar(message, ctx, isError: true);
      }
      return;
    }
    if (_postActionBusy.contains(post.id)) return;
    _postActionBusy.add(post.id);
    notifyListeners();

    final BuildContext? ctx = Get.context;
    try {
      final Map<String, dynamic> extra = {'text': trimmed};
      if (privacyType != null) {
        extra['privacy_type'] = privacyType.toString();
      } else if (post.privacyType != null) {
        extra['privacy_type'] = post.privacyType.toString();
      }
      if (post.pageId != null && post.pageId!.isNotEmpty) {
        extra['page_id'] = post.pageId;
      }
      if (post.groupId != null && post.groupId!.isNotEmpty) {
        extra['group_id'] = post.groupId;
      }
      await service.performPostAction(
        postId: post.id,
        action: 'edit',
        extraFields: extra,
      );
      SocialPost updated = post.copyWith(text: trimmed, rawText: trimmed);
      try {
        final SocialPost? refreshed = await service.getPostById(
          postId: post.id,
        );
        if (refreshed != null) {
          updated = refreshed;
        }
      } catch (_) {
        // Ignore fetch errors; fallback to optimistic update.
      }
      _updatePost(post.id, updated);
      if (ctx != null) {
        final String message =
            getTranslated('post_updated', ctx) ?? 'Post updated';
        showCustomSnackBar(message, ctx, isError: false);
      }
    } catch (e) {
      if (ctx != null) {
        showCustomSnackBar(e.toString(), ctx, isError: true);
      }
    } finally {
      _postActionBusy.remove(post.id);
      notifyListeners();
    }
  }

  Future<void> reportPost(SocialPost post) async {
    if (_postActionBusy.contains(post.id)) return;
    _postActionBusy.add(post.id);
    notifyListeners();

    final BuildContext? ctx = Get.context;
    try {
      final String result = await service.performPostAction(
        postId: post.id,
        action: 'report',
      );
      if (ctx != null) {
        final String message = getTranslated('post_reported', ctx) ?? result;
        showCustomSnackBar(message, ctx, isError: false);
      }
    } catch (e) {
      if (ctx != null) {
        showCustomSnackBar(e.toString(), ctx, isError: true);
      }
    } finally {
      _postActionBusy.remove(post.id);
      notifyListeners();
    }
  }

  Map<String, int> _adjustReactionBreakdown(
    Map<String, int> base, {
    String? remove,
    String? add,
  }) {
    if ((remove == null || remove.isEmpty) && (add == null || add.isEmpty))
      return base;
    final Map<String, int> next = Map<String, int>.from(base);
    void apply(String? key, int delta) {
      if (key == null || key.isEmpty) return;
      final int current = next[key] ?? 0;
      final int updated = current + delta;
      if (updated <= 0) {
        next.remove(key);
      } else {
        next[key] = updated;
      }
    }

    apply(remove, -1);
    apply(add, 1);
    return next;
  }

  // ========== USER PROFILE OPERATIONS (MERGED FROM PROFILE CONTROLLER) ==========

  /// Load profile đầy đủ (user + followers + following + liked_pages + posts)
  Future<void> loadUserProfile({
    String? targetUserId,
    bool force = false, // kéo-to-refresh => true
    bool useCache = true, // vào lại màn => true
    bool backgroundRefresh = true, // có cache cũ thì refresh ngầm
  }) async {
    final String? id = targetUserId ?? _currentUser?.id;
    if (id == null || id.isEmpty) return;

    // Nếu đang tải cùng user -> bỏ
    if (_loadingProfile && id == _profileHeaderUser?.id) return;

    // 1) Dùng cache nếu có và không force
    final cached = _profileCache[id];
    final hasCache = cached != null;
    final isStale = hasCache ? _isProfileStale(id) : true;

    if (useCache && hasCache && !force) {
      // render ngay dữ liệu cũ
      _profileHeaderUser = cached!.user;
      _followers = List<SocialUser>.from(cached.followers);
      _following = List<SocialUser>.from(cached.following);
      _likedPages = List<dynamic>.from(cached.likedPages);
      _profilePosts = List<SocialPost>.from(cached.posts);
      _lastProfilePostId = cached.lastPostId;
      notifyListeners();

      // refresh ngầm nếu cache đã cũ
      if (backgroundRefresh && isStale) {
        // không clear UI; tải lại âm thầm
        _refreshProfileFromNetwork(id: id);
      }
      return;
    }

    // 2) Không có cache (hoặc force) => hiển thị loading như cũ
    _loadingProfile = true;
    _profileHeaderUser = null;
    _followers = const [];
    _following = const [];
    _likedPages = const [];
    _profilePosts = [];
    _lastProfilePostId = null;
    notifyListeners();

    await _refreshProfileFromNetwork(id: id, showError: true);
  }

  Future<void> _refreshProfileFromNetwork({
    required String id,
    bool showError = false,
  }) async {
    try {
      if (service is! SocialService) {
        throw Exception('Service must be SocialService to load profile');
      }
      final SocialService socialService = service as SocialService;

      // 1) Bundle profile
      final bundle = await socialService.getUserProfile(targetUserId: id);
      _profileHeaderUser = bundle.user;

      // 2) Photos + Reels (song song cho nhanh)
      // (không clear UI, chỉ cập nhật)
      await Future.wait([
        refreshProfilePhotos(targetUserId: id),
        refreshProfileReels(targetUserId: id),
      ]);

      // 3) Followers/Following/LikedPages từ bundle
      _followers = bundle.followers;
      _following = bundle.following;
      _likedPages = bundle.likedPages;

      // 4) Posts trang 1
      if (bundle.user != null && bundle.user!.id.isNotEmpty) {
        final feedPage = await socialService.getUserPosts(
          targetUserId: bundle.user!.id,
          limit: 10,
          afterPostId: null,
        );
        _profilePosts = feedPage.posts;
        _lastProfilePostId = feedPage.lastId;
      } else {
        _profilePosts = [];
        _lastProfilePostId = null;
      }

      // 5) (tuỳ chọn) sync _currentUser một phần khi là profile của mình
      if (id == _currentUser?.id &&
          _currentUser != null &&
          bundle.user != null) {
        _currentUser = SocialUser(
          id: _currentUser!.id,
          displayName: bundle.user!.displayName ?? _currentUser!.displayName,
          userName: bundle.user!.userName ?? _currentUser!.userName,
          avatarUrl: bundle.user!.avatarUrl ?? _currentUser!.avatarUrl,
          coverUrl: bundle.user!.coverUrl ?? _currentUser!.coverUrl,
        );
      }

      // 6) Ghi cache
      _profileCache[id] = _ProfileBundleCache(
        user: _profileHeaderUser,
        followers: _followers,
        following: _following,
        likedPages: _likedPages,
        posts: _profilePosts,
        lastPostId: _lastProfilePostId,
        fetchedAt: DateTime.now(),
      );
    } catch (e) {
      if (showError) {
        // giữ nguyên cách báo lỗi hiện tại của bạn
        showCustomSnackBar(e.toString(), Get.context!, isError: true);
      }
    } finally {
      _loadingProfile = false;
      notifyListeners();
    }
  }

  /// Load more profile posts (pagination)
  Future<void> loadMoreProfilePosts({
    String? targetUserId,
    int limit = 10,
  }) async {
    if (_loadingProfilePosts) return;
    if (_lastProfilePostId == null || _lastProfilePostId!.isEmpty) return;

    final userId = targetUserId ?? _profileHeaderUser?.id ?? _currentUser?.id;
    if (userId == null || userId.isEmpty) return;

    _loadingProfilePosts = true;
    notifyListeners();

    try {
      if (service is! SocialService) {
        throw Exception('Service must be SocialService');
      }

      final SocialService socialService = service as SocialService;

      final feedPage = await socialService.getUserPosts(
        targetUserId: userId,
        limit: limit,
        afterPostId: _lastProfilePostId,
      );

      if (feedPage.posts.isNotEmpty) {
        _profilePosts = [..._profilePosts, ...feedPage.posts];
        _lastProfilePostId = feedPage.lastId;
      }
    } catch (e) {
      showCustomSnackBar(e.toString(), Get.context!, isError: true);
    } finally {
      _loadingProfilePosts = false;
      notifyListeners();
    }
  }

  /// Apply reaction update to profile post (from ProfileController)
  void applyReactionUpdate({
    required String postId,
    required String newReaction,
    required int newReactionCount,
    required Map<String, int> newBreakdown,
  }) {
    final idx = _profilePosts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final updated = _profilePosts[idx].copyWith(
      myReaction: newReaction,
      reactionCount: newReactionCount,
      reactionBreakdown: newBreakdown,
    );

    _profilePosts = [
      ..._profilePosts.sublist(0, idx),
      updated,
      ..._profilePosts.sublist(idx + 1),
    ];

    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}

// ========== HELPER CLASSES ==========
class StoryViewersState {
  final List<SocialStoryViewer> viewers;
  final bool loading;
  final bool hasMore;
  final int nextOffset;
  final int total;
  final bool fetched;

  const StoryViewersState({
    this.viewers = const <SocialStoryViewer>[],
    this.loading = false,
    this.hasMore = false,
    this.nextOffset = 0,
    this.total = 0,
    this.fetched = false,
  });

  StoryViewersState copyWith({
    List<SocialStoryViewer>? viewers,
    bool? loading,
    bool? hasMore,
    int? nextOffset,
    int? total,
    bool? fetched,
  }) {
    return StoryViewersState(
      viewers: viewers ?? this.viewers,
      loading: loading ?? this.loading,
      hasMore: hasMore ?? this.hasMore,
      nextOffset: nextOffset ?? this.nextOffset,
      total: total ?? this.total,
      fetched: fetched ?? this.fetched,
    );
  }
}

class _PendingStoryReaction {
  final String reaction;

  const _PendingStoryReaction({required this.reaction});
}

class _PreBlockSnapshot {
  final bool? isFollowing;
  final int? followersCount;
  final int? followingCount;
  const _PreBlockSnapshot(
      {this.isFollowing, this.followersCount, this.followingCount});
}

final Map<String, _PreBlockSnapshot> _preBlock = <String, _PreBlockSnapshot>{};

class _ProfileBundleCache {
  final SocialUserProfile? user;
  final List<SocialUser> followers;
  final List<SocialUser> following;
  final List<dynamic> likedPages; // giữ nguyên kiểu bạn đang dùng
  final List<SocialPost> posts;
  final String? lastPostId;
  final DateTime fetchedAt;
  const _ProfileBundleCache({
    required this.user,
    required this.followers,
    required this.following,
    required this.likedPages,
    required this.posts,
    required this.lastPostId,
    required this.fetchedAt,
  });
}

final Map<String, _ProfileBundleCache> _profileCache =
    <String, _ProfileBundleCache>{};
Duration get _profileTTL => const Duration(minutes: 5);

bool _isProfileStale(String id) {
  final dt = _profileCache[id]?.fetchedAt;
  if (dt == null) return true;
  return DateTime.now().difference(dt) > _profileTTL;
}
