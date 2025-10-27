import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

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

  SocialStory? _currentUserStory;
  SocialStory? get currentUserStory => _currentUserStory;

  final List<SocialPost> _posts = [];
  List<SocialPost> get posts => List.unmodifiable(_posts);
  
   String? _accessToken;                         
  String? get accessToken => _accessToken;

  final List<SocialStory> _stories = [];
  List<SocialStory> get stories => List.unmodifiable(_stories);
  int _storiesOffset = 0;
  final Map<String, Queue<_PendingStoryReaction>> _queuedStoryReactions =
      <String, Queue<_PendingStoryReaction>>{};

  void clearAuthState({bool notify = true}) {
    _loading = false;
    _creatingPost = false;
    _creatingStory = false;
    _loadingUser = false;
    _currentUser = null;
    _currentUserStory = null;
    _posts.clear();
    _stories.clear();
    _afterId = null;
    _storiesOffset = 0;
    _storyReactionLoading.clear();
    _storyViewers.clear();
    if (notify) {
      notifyListeners();
    }
  }

  String? _afterId;
  final Set<String> _storyReactionLoading = <String>{};
  static const int _storyViewersPageSize = 50;
  final Map<String, StoryViewersState> _storyViewers =
      <String, StoryViewersState>{};

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
        final within24h =
            posted == null || now.difference(posted) <= const Duration(hours: 24);
        final notExpired = expire == null || expire.isAfter(now);
        if (within24h && notExpired) {
          filteredItems.add(item);
        }
      }
      if (filteredItems.isEmpty) continue;

      filteredItems.sort((a, b) {
        final aTime =
            a.postedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            b.postedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
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
    final fresh =
        await service.getMyStories(limit: effectiveLimit, offset: 0);
    _replaceStories(fresh);
    notifyListeners();
  }

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
        _mergeStories([story]);
        notifyListeners();
        final int reloadLimit =
            (_stories.length + 5).clamp(10, 50);
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

  Future<void> loadCurrentUser({bool force = false}) async {
  if (_loadingUser) return;
  if (!force && _currentUser != null) return;

  _loadingUser = true;
  try {
    // 🔹 NẠP access token từ SharedPreferences nếu chưa có trong RAM
    final sp = await SharedPreferences.getInstance();
    _accessToken ??= sp.getString(AppConstants.socialAccessToken);

    // 🔹 Nếu chưa kết nối WoWonder thì không gọi API, clear state nhẹ nhàng
    if (_accessToken == null || _accessToken!.isEmpty) {
      _currentUser = null;
      _syncCurrentUserStoryFrom(_stories); // giữ logic đồng bộ story hiện có
      notifyListeners();
      return; // thoát sớm, finally vẫn chạy để _loadingUser=false
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

      final userStories = await service.getMyStories(limit: 10, offset: 0);
      _replaceStories(userStories);

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
          final SocialStoryItem refreshedItem = refreshedStory.items
              .firstWhere(
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
        final DateTime aTime = a.viewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bTime = b.viewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
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

  Future<void> reactOnPost(SocialPost post, String reaction) async {
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
    } catch (e) {
      _updatePost(post.id, post);
      final msg = e.toString();
      showCustomSnackBar(msg, Get.context!, isError: true);
    }
  }

  Map<String, int> _adjustReactionBreakdown(
    Map<String, int> base, {
    String? remove,
    String? add,
  }) {
    if ((remove == null || remove.isEmpty) &&
        (add == null || add.isEmpty)) return base;
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
}

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


