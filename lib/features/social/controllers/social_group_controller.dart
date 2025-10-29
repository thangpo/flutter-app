import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_group.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_group_service_interface.dart';

class SocialGroupController with ChangeNotifier {
  final SocialGroupServiceInterface service;
  SocialGroupController({required this.service});

  static const int _pageSize = 20;

  final Map<SocialGroupQueryType, _GroupListState> _states =
      <SocialGroupQueryType, _GroupListState>{
    SocialGroupQueryType.myGroups: _GroupListState(),
    SocialGroupQueryType.joinedGroups: _GroupListState(),
    SocialGroupQueryType.discover: _GroupListState(),
  };
  final Map<String, _GroupFeedState> _feedStates = <String, _GroupFeedState>{};

  bool _creatingGroup = false;
  bool get creatingGroup => _creatingGroup;

  final Set<String> _joiningGroups = <String>{};
  bool joiningGroup(String groupId) => _joiningGroups.contains(groupId);

  final Set<String> _updatingGroups = <String>{};
  bool updatingGroup(String groupId) => _updatingGroups.contains(groupId);

  Future<void> ensureLoaded(SocialGroupQueryType type) async {
    final state = _states[type]!;
    if (state.initialized || state.loading || state.refreshing) return;
    await refresh(type);
  }

  List<SocialGroup> groups(SocialGroupQueryType type) {
    return List<SocialGroup>.unmodifiable(_states[type]!.items);
  }

  bool isRefreshing(SocialGroupQueryType type) =>
      _states[type]!.refreshing && !_states[type]!.loading;

  bool isLoadingMore(SocialGroupQueryType type) => _states[type]!.loading;

  bool hasMore(SocialGroupQueryType type) => _states[type]!.hasMore;

  String? errorMessage(SocialGroupQueryType type) => _states[type]!.error;

  _GroupFeedState _feedState(String groupId) {
    return _feedStates.putIfAbsent(groupId, () => _GroupFeedState());
  }

  List<SocialPost> groupFeed(String groupId) =>
      List<SocialPost>.unmodifiable(_feedState(groupId).posts);

  bool isFeedInitialized(String groupId) => _feedState(groupId).initialized;

  bool isFeedRefreshing(String groupId) =>
      _feedState(groupId).refreshing && !_feedState(groupId).loading;

  bool isFeedLoadingMore(String groupId) => _feedState(groupId).loading;

  bool feedHasMore(String groupId) => _feedState(groupId).hasMore;

  String? feedError(String groupId) => _feedState(groupId).error;

  Future<void> refresh(SocialGroupQueryType type) async {
    final state = _states[type]!;
    if (state.refreshing) return;

    state.refreshing = true;
    state.error = null;
    notifyListeners();

    try {
      final groups = await service.getGroups(
        type: type,
        limit: _pageSize,
        offset: 0,
      );
      state.items = List<SocialGroup>.from(groups);
      state.offset = groups.length;
      state.hasMore = groups.length >= _pageSize;
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

  Future<void> loadMore(SocialGroupQueryType type) async {
    final state = _states[type]!;
    if (state.loading || state.refreshing || !state.hasMore) return;

    state.loading = true;
    state.error = null;
    notifyListeners();

    try {
      final groups = await service.getGroups(
        type: type,
        limit: _pageSize,
        offset: state.offset,
      );
      if (groups.isEmpty) {
        state.hasMore = false;
      } else {
        final merged = List<SocialGroup>.from(state.items)..addAll(groups);
        state.items = merged;
        state.offset = merged.length;
        state.hasMore = groups.length >= _pageSize;
      }
    } catch (e) {
      state.error = e.toString();
      rethrow;
    } finally {
      state.loading = false;
      notifyListeners();
    }
  }

  Future<void> ensureFeedLoaded(String groupId) async {
    final state = _feedState(groupId);
    if (state.initialized || state.loading || state.refreshing) return;
    await refreshFeed(groupId);
  }

  Future<void> refreshFeed(String groupId) async {
    final state = _feedState(groupId);
    if (state.refreshing) return;
    state.refreshing = true;
    state.error = null;
    notifyListeners();

    try {
      final page = await service.getGroupFeed(
        groupId: groupId,
        limit: _pageSize,
      );
      state.posts = List<SocialPost>.from(page.posts);
      state.lastId =
          page.lastId ?? (page.posts.isNotEmpty ? page.posts.last.id : null);
      state.hasMore = page.posts.length >= _pageSize;
      state.initialized = true;
    } catch (e) {
      state.error = e.toString();
      state.hasMore = state.posts.isNotEmpty;
      state.initialized = true;
      rethrow;
    } finally {
      state.refreshing = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreFeed(String groupId) async {
    final state = _feedState(groupId);
    if (state.loading || state.refreshing || !state.hasMore) return;
    state.loading = true;
    state.error = null;
    notifyListeners();

    try {
      final page = await service.getGroupFeed(
        groupId: groupId,
        limit: _pageSize,
        afterPostId: state.lastId,
      );
      if (page.posts.isEmpty) {
        state.hasMore = false;
      } else {
        state.posts = List<SocialPost>.from(state.posts)..addAll(page.posts);
        state.lastId = page.lastId ?? page.posts.last.id;
        state.hasMore = page.posts.length >= _pageSize;
      }
    } catch (e) {
      state.error = e.toString();
      rethrow;
    } finally {
      state.loading = false;
      notifyListeners();
    }
  }

  Future<SocialGroup> createGroup({
    required String groupName,
    required String groupTitle,
    required String category,
    String? about,
    String? groupSubCategory,
    Map<String, dynamic>? customFields,
    String? privacy,
    String? joinPrivacy,
    String? avatarPath,
    String? coverPath,
  }) async {
    if (_creatingGroup) {
      throw Exception('A group creation is already in progress.');
    }

    _creatingGroup = true;
    notifyListeners();

    try {
      SocialGroup group = await service.createGroup(
        groupName: groupName,
        groupTitle: groupTitle,
        category: category,
        about: about,
        groupSubCategory: groupSubCategory,
        customFields: customFields,
        privacy: privacy,
        joinPrivacy: joinPrivacy,
        avatarPath: avatarPath,
        coverPath: coverPath,
      );

      group = group.copyWith(
        isJoined: true,
        isAdmin: true,
      );
      _upsertGroup(group, SocialGroupQueryType.myGroups, insertFirst: true);
      _upsertGroup(group, SocialGroupQueryType.joinedGroups, insertFirst: true);
      _removeGroupIfExists(group.id, SocialGroupQueryType.discover);

      return group;
    } finally {
      _creatingGroup = false;
      notifyListeners();
    }
  }

  Future<SocialGroup> updateGroup({
    required String groupId,
    String? groupTitle,
    String? about,
    String? category,
    String? groupSubCategory,
    Map<String, dynamic>? customFields,
    String? privacy,
    String? joinPrivacy,
    String? avatarPath,
    String? coverPath,
  }) async {
    if (_updatingGroups.contains(groupId)) {
      throw Exception('The group is already being updated.');
    }
    _updatingGroups.add(groupId);
    notifyListeners();

    try {
      final SocialGroup group = await service.updateGroup(
        groupId: groupId,
        groupTitle: groupTitle,
        about: about,
        category: category,
        groupSubCategory: groupSubCategory,
        customFields: customFields,
        privacy: privacy,
        joinPrivacy: joinPrivacy,
        avatarPath: avatarPath,
        coverPath: coverPath,
      );

      _upsertGroup(group, SocialGroupQueryType.myGroups);
      _upsertGroup(group, SocialGroupQueryType.joinedGroups);
      _upsertGroup(
        group,
        SocialGroupQueryType.discover,
        onlyIfExists: true,
      );

      return group;
    } finally {
      _updatingGroups.remove(groupId);
      notifyListeners();
    }
  }

  Future<SocialGroup?> joinGroup(String groupId) async {
    if (_joiningGroups.contains(groupId)) {
      throw Exception('Join request already in progress.');
    }
    _joiningGroups.add(groupId);
    notifyListeners();

    SocialGroup? baseGroup = _findGroupById(groupId);

    try {
      final SocialGroup? response = await service.joinGroup(groupId: groupId);
      if (response != null) {
        baseGroup = response;
      }
      if (baseGroup == null) {
        throw Exception('Unable to find group data to update.');
      }
      SocialGroup updated = baseGroup.copyWith(isJoined: true);

      _upsertGroup(updated, SocialGroupQueryType.joinedGroups,
          insertFirst: true);
      _upsertGroup(
        updated,
        SocialGroupQueryType.myGroups,
        onlyIfExists: !(updated.isAdmin),
      );
      _upsertGroup(
        updated,
        SocialGroupQueryType.discover,
        onlyIfExists: true,
      );

      return updated;
    } finally {
      _joiningGroups.remove(groupId);
      notifyListeners();
    }
  }

  Future<List<SocialUser>> getGroupMembers(
      {required String groupId, int limit = 20, int offset = 0}) {
    return service.getGroupMembers(
      groupId: groupId,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<SocialUser>> getGroupNonMembers(
      {required String groupId, int limit = 20, int offset = 0}) {
    return service.getGroupNonMembers(
      groupId: groupId,
      limit: limit,
      offset: offset,
    );
  }

  Future<void> makeAdmin({required String groupId, required String userId}) {
    return service.makeGroupAdmin(groupId: groupId, userId: userId);
  }

  SocialGroup? _findGroupById(String groupId) {
    for (final state in _states.values) {
      final index = state.items.indexWhere((element) => element.id == groupId);
      if (index >= 0) {
        return state.items[index];
      }
    }
    return null;
  }

  void _upsertGroup(
    SocialGroup group,
    SocialGroupQueryType type, {
    bool insertFirst = false,
    bool onlyIfExists = false,
  }) {
    final state = _states[type]!;
    final List<SocialGroup> updated = List<SocialGroup>.from(state.items);
    final int index = updated.indexWhere((g) => g.id == group.id);
    if (index >= 0) {
      updated[index] = group;
    } else if (!onlyIfExists) {
      if (insertFirst) {
        updated.insert(0, group);
      } else {
        updated.add(group);
      }
    }
    state.items = updated;
  }

  void _removeGroupIfExists(String groupId, SocialGroupQueryType type) {
    final state = _states[type]!;
    final List<SocialGroup> updated = List<SocialGroup>.from(state.items);
    updated.removeWhere((element) => element.id == groupId);
    state.items = updated;
  }
}

class _GroupListState {
  List<SocialGroup> items;
  bool loading;
  bool refreshing;
  bool hasMore;
  int offset;
  bool initialized;
  String? error;

  _GroupListState({
    List<SocialGroup>? items,
    this.loading = false,
    this.refreshing = false,
    this.hasMore = true,
    this.offset = 0,
    this.initialized = false,
    this.error,
  }) : items = items ?? <SocialGroup>[];
}

class _GroupFeedState {
  List<SocialPost> posts;
  bool loading;
  bool refreshing;
  bool hasMore;
  String? lastId;
  bool initialized;
  String? error;

  _GroupFeedState({
    List<SocialPost>? posts,
    this.loading = false,
    this.refreshing = false,
    this.hasMore = true,
    this.lastId,
    this.initialized = false,
    this.error,
  }) : posts = posts ?? <SocialPost>[];
}
