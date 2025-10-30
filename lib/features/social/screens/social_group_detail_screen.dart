import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/di_container.dart' as di;
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_feed_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_group.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_group_join_request.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_group_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/create_post_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/profile_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_group_form_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_screen.dart'
    show SocialPostCard;
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:provider/provider.dart';

class SocialGroupDetailScreen extends StatefulWidget {
  final String groupId;
  final SocialGroup? initialGroup;

  const SocialGroupDetailScreen({
    super.key,
    required this.groupId,
    this.initialGroup,
  });

  @override
  State<SocialGroupDetailScreen> createState() =>
      _SocialGroupDetailScreenState();
}

class _SocialGroupDetailScreenState extends State<SocialGroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final SocialGroupServiceInterface _service;

  SocialGroup? _group;
  bool _loading = false;
  String? _error;
  int? _memberCount;
  bool _joiningGroup = false;

  final List<SocialPost> _posts = <SocialPost>[];
  bool _postsFetched = false;
  bool _loadingPosts = false;
  bool _loadingMorePosts = false;
  String? _postsCursor;
  String? _postsError;
  bool _hasMorePosts = true;
  bool _reportingGroup = false;
  bool _deletingGroup = false;
  final ScrollController _postsScrollController = ScrollController();

  static const List<_GroupEvent> _events = <_GroupEvent>[
    _GroupEvent(
      title: 'Livestream tro chuyen toi thu 6',
      schedule: 'Thu 6, 20:00 - Truc tuyen',
      description:
          'Chia se xu huong moi nhat va giao luu cung thanh vien trong nhom.',
    ),
    _GroupEvent(
      title: 'Cuoc thi sang tao xu huong',
      schedule: 'Chu nhat, 14:00 - Zoom meeting',
      description:
          'Gui y tuong sang tao de nhan qua tang tu ban quan tri truoc thu 6.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChanged);
    _service = di.sl<SocialGroupServiceInterface>();
    _group = widget.initialGroup;
    _memberCount = widget.initialGroup?.memberCount;
    _postsScrollController.addListener(_handlePostsScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadGroup();
      _ensurePostsLoaded();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _postsScrollController.removeListener(_handlePostsScroll);
    _postsScrollController.dispose();
    super.dispose();
  }

  String t(String key, String fallback) =>
      getTranslated(key, context) ?? fallback;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final SocialGroup? maybeGroup = _group ?? widget.initialGroup;

    if (maybeGroup == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t('group_details', 'Chi tiet nhom')),
        ),
        body: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : Text(_error ?? t('no_data_found', 'Khong co du lieu nhom.')),
        ),
      );
    }

    final SocialGroup group = maybeGroup;
    final String? cover = group.coverUrl ?? group.avatarUrl;
    final String title =
        group.title?.isNotEmpty == true ? group.title! : group.name;
    final String subtitle = _buildMemberInfo(group);
    final String about = group.about?.isNotEmpty == true
        ? group.about!
        : t('no_description', 'Nhom chua co mo ta.');
    final bool canManage = group.isAdmin;
    final List<_GroupMenuAction> menuActions =
        _resolveMenuActions(group: group, canManage: canManage);
    final bool showJoinButton = !group.isJoined;
    final bool canCompose = group.isOwner || group.isJoined;
    final bool joinRequestPending =
        showJoinButton && group.joinRequestStatus == 2;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: theme.scaffoldBackgroundColor,
                foregroundColor:
                    theme.appBarTheme.foregroundColor ?? colorScheme.onSurface,
                expandedHeight: 220,
                pinned: true,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back,
                      color: theme.appBarTheme.foregroundColor ??
                          colorScheme.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  if (canManage)
                    IconButton(
                      icon: Icon(Icons.edit,
                          color: theme.appBarTheme.foregroundColor ??
                              colorScheme.onSurface),
                      onPressed: _openEditGroup,
                    ),
                  if (menuActions.isNotEmpty)
                    PopupMenuButton<_GroupMenuAction>(
                      icon: Icon(
                        Icons.more_horiz,
                        color: theme.appBarTheme.foregroundColor ??
                            colorScheme.onSurface,
                      ),
                      onSelected: (action) => _handleMenuAction(action, group),
                      itemBuilder: (context) {
                        return menuActions.map((action) {
                          return PopupMenuItem<_GroupMenuAction>(
                            value: action,
                            child: Text(_menuActionLabel(action)),
                          );
                        }).toList();
                      },
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: cover == null
                            ? <Color>[
                                colorScheme.primary,
                                colorScheme.primaryContainer
                                    .withValues(alpha: 0.9),
                              ]
                            : <Color>[
                                Colors.black.withValues(alpha: 0.2),
                                Colors.black.withValues(alpha: 0.6),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      image: cover != null
                          ? DecorationImage(
                              image: NetworkImage(cover),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor:
                              colorScheme.onPrimary.withValues(alpha: 0.12),
                          backgroundImage: group.avatarUrl != null &&
                                  group.avatarUrl!.isNotEmpty
                              ? NetworkImage(group.avatarUrl!)
                              : null,
                          child: (group.avatarUrl == null ||
                                  group.avatarUrl!.isEmpty)
                              ? Icon(Icons.groups,
                                  size: 42, color: colorScheme.onPrimary)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildHeader(
                    theme: theme,
                    colorScheme: colorScheme,
                    title: title,
                    subtitle: subtitle,
                    showJoinButton: showJoinButton,
                    joinRequestPending: joinRequestPending,
                    canCompose: canCompose,
                    group: group,
                  ),
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPostsTab(),
                    _buildAboutTab(about),
                    _buildPhotosTab(),
                    _buildEventsTab(),
                  ],
                ),
              ),
            ],
          ),
          if (_loading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: _error != null
          ? FloatingActionButton.small(
              onPressed: _loadGroup,
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }

  Column _buildHeader({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String title,
    required String subtitle,
    required bool showJoinButton,
    required bool joinRequestPending,
    required bool canCompose,
    required SocialGroup group,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ) ??
              TextStyle(
                color: colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _openMembersSheet,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.group, size: 18, color: colorScheme.onSurface),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ) ??
                        TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (showJoinButton)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_joiningGroup || joinRequestPending)
                  ? null
                  : _handleJoinGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _joiningGroup
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : Text(
                      joinRequestPending
                          ? t('join_group_pending_short', 'Da gui yeu cau')
                          : t('join_group', 'Tham gia nhom'),
                      style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ) ??
                          TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
            ),
          ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.12),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('highlight_content', 'Noi dung noi bat'),
                style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ) ??
                    TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              if (canCompose) ...[
                _buildGroupComposer(
                  theme: theme,
                  colorScheme: colorScheme,
                  group: group,
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  _buildHighlightChip(
                    icon: Icons.play_circle_outline,
                    label: t('video', 'Video'),
                  ),
                  const SizedBox(width: 12),
                  _buildHighlightChip(
                    icon: Icons.insert_photo_outlined,
                    label: t('photos', 'Anh'),
                  ),
                  const SizedBox(width: 12),
                  _buildHighlightChip(
                    icon: Icons.event_available_outlined,
                    label: t('events', 'Su kien'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
          labelStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Bai viet'),
            Tab(text: 'Gioi thieu'),
            Tab(text: 'Anh'),
            Tab(text: 'Su kien'),
          ],
        ),
      ],
    );
  }

  Widget _buildHighlightChip({required IconData icon, required String label}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ) ??
                TextStyle(
                  color: colorScheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 0) {
      _ensurePostsLoaded();
    }
  }

  void _handlePostsScroll() {
    if (!_postsScrollController.hasClients) return;
    if (_loadingMorePosts || _loadingPosts || !_hasMorePosts) return;
    final position = _postsScrollController.position;
    if (position.maxScrollExtent - position.pixels <= 200) {
      _loadMoreGroupPosts();
    }
  }

  void _ensurePostsLoaded({bool forceRefresh = false}) {
    if (_loadingPosts) return;
    if (!forceRefresh && _postsFetched) return;
    _loadGroupPosts(forceRefresh: forceRefresh);
  }

  Future<void> _loadGroup() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final SocialGroup? fetched =
          await _service.getGroupById(groupId: widget.groupId);
      if (!mounted) return;
      setState(() {
        if (fetched != null) {
          _group = fetched;
          _memberCount = fetched.memberCount;
          _applyGroupInfoToPosts();
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadGroupPosts({bool forceRefresh = false}) async {
    if (_loadingPosts) return;
    if (!forceRefresh && _postsFetched) return;

    setState(() {
      _loadingPosts = true;
      _postsError = null;
      if (forceRefresh) {
        _postsCursor = null;
        _hasMorePosts = true;
      }
    });

    try {
      final SocialFeedPage page = await _service.getGroupFeed(
        groupId: widget.groupId,
        limit: 10,
      );
      if (!mounted) return;
      setState(() {
        _posts
          ..clear()
          ..addAll(page.posts.map(_enrichPost));
        _postsFetched = true;
        _postsCursor = page.lastId;
        _hasMorePosts =
            page.posts.isNotEmpty && (page.lastId?.isNotEmpty ?? false);
        _loadingPosts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _postsError = e.toString();
        _loadingPosts = false;
      });
    }
  }

  Future<void> _loadMoreGroupPosts() async {
    if (_loadingMorePosts || _loadingPosts || !_hasMorePosts) return;
    final String? cursor = _postsCursor;
    if (cursor == null || cursor.isEmpty) return;

    setState(() {
      _loadingMorePosts = true;
      _postsError = null;
    });

    try {
      final SocialFeedPage page = await _service.getGroupFeed(
        groupId: widget.groupId,
        limit: 10,
        afterPostId: cursor,
      );
      if (!mounted) return;
      setState(() {
        if (page.posts.isEmpty) {
          _hasMorePosts = false;
        } else {
          _posts.addAll(page.posts.map(_enrichPost));
          _postsCursor = page.lastId;
          _hasMorePosts = page.lastId != null && page.lastId!.isNotEmpty;
        }
        _loadingMorePosts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _postsError = e.toString();
        _loadingMorePosts = false;
      });
    }
  }

  void _applyGroupInfoToPosts() {
    if (_posts.isEmpty) return;
    final List<SocialPost> updated = _posts.map(_enrichPost).toList();
    _posts
      ..clear()
      ..addAll(updated);
  }

  SocialPost _enrichPost(SocialPost post) {
    final SocialGroup? group = _group ?? widget.initialGroup;
    if (group == null) {
      return post.copyWith(
        isGroupPost: true,
        groupId: post.groupId ?? widget.groupId,
      );
    }
    return post.copyWith(
      isGroupPost: true,
      groupId: post.groupId ?? group.id,
      groupName: post.groupName ?? group.name,
      groupTitle: post.groupTitle ?? group.title ?? group.name,
      groupUrl: post.groupUrl ?? group.url,
      groupAvatar: post.groupAvatar ?? group.avatarUrl,
      groupCover: post.groupCover ?? group.coverUrl,
    );
  }

  void _handlePostUpdated(SocialPost updated) {
    final int index = _posts.indexWhere((element) => element.id == updated.id);
    if (index == -1 || !mounted) return;
    setState(() {
      _posts[index] = _enrichPost(updated);
    });
  }

  String _buildMemberInfo(SocialGroup group) {
    final String privacy = (group.privacy ?? '').toLowerCase();
    final bool isPrivate =
        privacy == '2' || privacy.contains('private') || privacy == 'closed';
    final String privacyLabel = isPrivate
        ? t('private_group', 'Nhom rieng tu')
        : t('public_group', 'Nhom cong khai');

    final int members = _memberCount ?? group.memberCount;
    final String memberLabel = members > 0
        ? t('member_count', '$members thanh vien')
        : t('no_members', 'Chua co thanh vien');
    return '$privacyLabel • $memberLabel';
  }

  Widget _buildPostsTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget buildMessage(String message, {Widget? action}) {
      return ListView(
        controller: _postsScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.72),
                      ) ??
                      TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.72),
                        fontSize: 13,
                      ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 12),
                  action,
                ],
              ],
            ),
          ),
        ],
      );
    }

    Future<void> refresh() => _loadGroupPosts(forceRefresh: true);

    if (_loadingPosts && _posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          controller: _postsScrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      );
    }

    if (_postsError != null && _posts.isEmpty) {
      final String message =
          _postsError ?? t('failed_to_load_posts', 'Khong the tai bai viet.');
      return RefreshIndicator(
        onRefresh: refresh,
        child: buildMessage(
          message,
          action: Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _loadGroupPosts(forceRefresh: true),
              child: Text(t('retry', 'Thu lai')),
            ),
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: buildMessage(
          t('no_group_posts', 'Nhom chua co bai viet nao.'),
        ),
      );
    }

    final bool showLoadingMore = _loadingMorePosts;
    final bool showLoadMoreError =
        !showLoadingMore && _postsError != null && _posts.isNotEmpty;
    final int extraItems = (showLoadingMore || showLoadMoreError) ? 1 : 0;

    final listView = ListView.separated(
      controller: _postsScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _posts.length + extraItems,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index < _posts.length) {
          final SocialPost post = _posts[index];
          return SocialPostCard(
            post: post,
            onPostUpdated: _handlePostUpdated,
          );
        }
        if (showLoadingMore) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: _loadMoreGroupPosts,
            icon: const Icon(Icons.refresh),
            label: Text(t('retry', 'Thu lai')),
          ),
        );
      },
    );

    return RefreshIndicator(
      onRefresh: refresh,
      child: listView,
    );
  }

  Widget _buildAboutTab(String about) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          t('group_about', 'Gioi thieu ve nhom'),
          style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ) ??
              TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          about,
          style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ) ??
              TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
                fontSize: 14,
              ),
        ),
      ],
    );
  }

  Widget _buildPhotosTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(
            Icons.image_outlined,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        );
      },
    );
  }

  Widget _buildEventsTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final _GroupEvent event = _events[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ) ??
                    TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.schedule,
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.75),
                          ) ??
                          TextStyle(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.75),
                            fontSize: 14,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                event.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ) ??
                    TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openEditGroup() async {
    final SocialGroup? current = _group ?? widget.initialGroup;
    if (current == null) return;

    final SocialGroup? updated = await Navigator.of(context).push<SocialGroup>(
      MaterialPageRoute<SocialGroup>(
        builder: (_) => SocialGroupFormScreen(group: current),
      ),
    );

    if (!mounted || updated == null) return;

    setState(() {
      _group = updated;
      _memberCount = updated.memberCount;
      _applyGroupInfoToPosts();
    });
  }

  List<_GroupMenuAction> _resolveMenuActions({
    required SocialGroup group,
    required bool canManage,
  }) {
    final List<_GroupMenuAction> actions = <_GroupMenuAction>[];
    final String? joinPrivacy = group.joinPrivacy?.trim();
    final bool requiresApproval =
        group.requiresApproval || (joinPrivacy != null && joinPrivacy == '2');
    final bool isMember = group.isOwner || group.isAdmin || group.isJoined;
    if (canManage) {
      if (requiresApproval) {
        actions.add(_GroupMenuAction.joinRequests);
      }
    }
    if (isMember) {
      actions.add(_GroupMenuAction.inviteMembers);
      actions.add(_GroupMenuAction.reportGroup);
    }
    if (group.isOwner) {
      actions.add(_GroupMenuAction.deleteGroup);
    }
    return actions;
  }

  String _menuActionLabel(_GroupMenuAction action) {
    switch (action) {
      case _GroupMenuAction.joinRequests:
        return t('join_requests', 'Join requests');
      case _GroupMenuAction.inviteMembers:
        return t('invite_members', 'Invite members');
      case _GroupMenuAction.reportGroup:
        return t('report_group', 'Report group');
      case _GroupMenuAction.deleteGroup:
        return t('delete_group', 'Delete group');
    }
  }

  Future<void> _handleMenuAction(
      _GroupMenuAction action, SocialGroup group) async {
    switch (action) {
      case _GroupMenuAction.joinRequests:
        await _showJoinRequests(group);
        break;
      case _GroupMenuAction.inviteMembers:
        await _showInviteMembers(group);
        break;
      case _GroupMenuAction.reportGroup:
        await _showReportGroup(group);
        break;
      case _GroupMenuAction.deleteGroup:
        await _showDeleteGroup(group);
        break;
    }
  }

  Future<void> _showInviteMembers(SocialGroup group) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (BuildContext ctx) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          child: _InviteMembersSheet(
            groupId: group.id,
            service: _service,
          ),
        );
      },
    );
  }

  Future<void> _showReportGroup(SocialGroup group) async {
    if (!mounted || _reportingGroup) return;
    final String? message = await _promptReportGroupReason();
    if (message == null || message.trim().isEmpty) return;
    if (!mounted) return;
    setState(() {
      _reportingGroup = true;
    });
    try {
      await _service.reportGroup(
        groupId: group.id,
        text: message.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('report_group_success', 'Report submitted')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _reportingGroup = false;
        });
      }
    }
  }

  Future<String?> _promptReportGroupReason() async {
    final TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setStateDialog) {
            final bool canSubmit = controller.text.trim().isNotEmpty;
            return AlertDialog(
              title: Text(t('report_group', 'Report group')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('report_group_hint', 'Let us know why you are reporting this group.'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: t('report_group_placeholder', 'Enter your reason'),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setStateDialog(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(t('cancel', 'Cancel')),
                ),
                FilledButton(
                  onPressed: canSubmit
                      ? () => Navigator.of(dialogContext)
                          .pop(controller.text.trim())
                      : null,
                  child: Text(t('send', 'Send')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteGroup(SocialGroup group) async {
    if (!mounted || _deletingGroup) return;
    final String? password = await _promptDeleteGroupPassword();
    if (password == null || password.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _deletingGroup = true;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _service.deleteGroup(
        groupId: group.id,
        password: password,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(t('delete_group_success', 'Group deleted')),
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingGroup = false;
        });
      }
    }
  }

  Future<String?> _promptDeleteGroupPassword() async {
    final TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder:
              (BuildContext context, void Function(void Function()) setStateDialog) {
            final bool canSubmit = controller.text.trim().isNotEmpty;
            return AlertDialog(
              title: Text(t('delete_group', 'Delete group')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('delete_group_hint',
                        'Enter your account password to confirm deleting this group.'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: t('delete_group_placeholder', 'Password'),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setStateDialog(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(t('cancel', 'Cancel')),
                ),
                FilledButton(
                  onPressed: canSubmit
                      ? () => Navigator.of(dialogContext)
                          .pop(controller.text.trim())
                      : null,
                  child: Text(t('delete', 'Delete')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showJoinRequests(SocialGroup group) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (BuildContext ctx) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          child: _JoinRequestsSheet(
            group: group,
            service: _service,
          ),
        );
      },
    );
  }

  Future<void> _openCreatePost(SocialGroup group) async {
    final SocialPost? created = await Navigator.of(context).push<SocialPost>(
      MaterialPageRoute<SocialPost>(
        builder: (_) => SocialCreatePostScreen(
          groupId: group.id,
          groupName: group.name,
          groupTitle: group.title,
        ),
        fullscreenDialog: true,
      ),
    );

    if (!mounted || created == null) return;

    final SocialPost enriched = _enrichPost(
      created.copyWith(
        isGroupPost: true,
        groupId: group.id,
        groupName: group.name,
        groupTitle: group.title ?? group.name,
        groupAvatar: group.avatarUrl,
        groupCover: group.coverUrl,
      ),
    );

    setState(() {
      _posts.insert(0, enriched);
      _postsFetched = true;
    });

    _ensurePostsLoaded(forceRefresh: true);
  }

  Future<void> _handleJoinGroup() async {
    if (_joiningGroup) return;
    final SocialGroup? target = _group ?? widget.initialGroup;
    if (target == null) return;

    setState(() {
      _joiningGroup = true;
    });

    try {
      final SocialGroup? joined = await _service.joinGroup(groupId: target.id);
      if (!mounted) return;

      final SocialGroup base = (_group ?? widget.initialGroup)!;
      final int baseMembers = _memberCount ?? base.memberCount;
      final SocialGroup resolved = _mergeJoinResult(
        base: base,
        response: joined,
        baseMembers: baseMembers,
      );

      setState(() {
        _group = resolved;
        _memberCount = resolved.memberCount;
        _applyGroupInfoToPosts();
        _joiningGroup = false;
      });

      if (!mounted) return;
      final bool joinPending = !resolved.isJoined &&
          (resolved.joinRequestStatus == 2 || resolved.requiresApproval);
      final String message = joinPending
          ? t('join_group_pending', 'Da gui yeu cau tham gia nhom.')
          : t('join_group_success', 'Da tham gia nhom.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      _ensurePostsLoaded(forceRefresh: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _joiningGroup = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  SocialGroup _mergeJoinResult({
    required SocialGroup base,
    required SocialGroup? response,
    required int baseMembers,
  }) {
    if (response == null) {
      final int updatedJoinStatus =
          base.joinRequestStatus == 0 ? 1 : base.joinRequestStatus;
      return base.copyWith(
        isJoined: true,
        joinRequestStatus: updatedJoinStatus,
        memberCount: baseMembers + 1,
      );
    }

    final bool joinPending = !response.isJoined &&
        (response.joinRequestStatus == 2 || response.requiresApproval);

    final int memberCount = response.memberCount != 0
        ? response.memberCount
        : joinPending
            ? baseMembers
            : baseMembers + 1;

    return base.copyWith(
      name: response.name,
      title: response.title,
      about: response.about,
      description: response.description,
      category: response.category,
      subCategory: response.subCategory,
      privacy: response.privacy,
      joinPrivacy: response.joinPrivacy,
      avatarUrl: response.avatarUrl,
      coverUrl: response.coverUrl,
      memberCount: memberCount,
      pendingCount: response.pendingCount,
      isJoined: joinPending ? false : response.isJoined,
      isAdmin: response.isAdmin,
      isOwner: response.isOwner,
      requiresApproval: response.requiresApproval,
      joinRequestStatus: joinPending
          ? 2
          : (response.isJoined
              ? (response.joinRequestStatus == 0
                  ? 1
                  : response.joinRequestStatus)
              : response.joinRequestStatus),
      owner: response.owner,
      customFields: response.customFields.isNotEmpty
          ? response.customFields
          : base.customFields,
      createdAt: response.createdAt ?? base.createdAt,
      updatedAt: response.updatedAt ?? base.updatedAt,
      status: response.status ?? base.status,
      url: response.url ?? base.url,
    );
  }

  Widget _buildGroupComposer({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required SocialGroup group,
  }) {
    final SocialUser? socialUser =
        context.select<SocialController, SocialUser?>((c) => c.currentUser);
    final String? fallbackAvatar =
        context.select<ProfileController, String?>((controller) {
      final info = controller.userInfoModel;
      final List<String?> candidates = <String?>[
        info?.imageFullUrl?.path,
        info?.image?.toString(),
      ];
      for (final String? candidate in candidates) {
        if (candidate != null && candidate.trim().isNotEmpty) {
          return candidate.trim();
        }
      }
      return null;
    });

    String? avatarUrl = socialUser?.avatarUrl?.trim();
    if (avatarUrl == null || avatarUrl.isEmpty) {
      avatarUrl = fallbackAvatar;
    }

    final BorderRadius inputRadius = BorderRadius.circular(12);
    final String composerHint = t('whats_on_your_mind', 'Ban dang nghi gi?');
    final String groupDisplay =
        group.title?.isNotEmpty == true ? group.title! : group.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              borderRadius: BorderRadius.circular(999),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.surface.withValues(alpha: 0.12),
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? Icon(
                        Icons.person,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _openCreatePost(group),
                borderRadius: inputRadius,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: inputRadius,
                  ),
                  child: Text(
                    composerHint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 15,
                        ) ??
                        TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 15,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              Icons.groups_2_outlined,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                groupDisplay,
                style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ) ??
                    TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openMembersSheet() {
    final SocialGroup? group = _group ?? widget.initialGroup;
    if (group == null) return;
    String? currentUserId;
    try {
      currentUserId =
          context.read<SocialController>().currentUser?.id;
    } catch (_) {
      currentUserId = null;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: _GroupMembersSheet(
          groupId: group.id,
          service: _service,
          canPromote: group.isOwner,
          canManageMembers: group.isOwner || group.isAdmin,
          currentUserId: currentUserId,
          ownerId: group.owner?.id,
          initialCount: _memberCount ?? group.memberCount,
        ),
      ),
    );
  }
}

class _GroupMembersSheet extends StatefulWidget {
  final String groupId;
  final SocialGroupServiceInterface service;
  final bool canPromote;
  final bool canManageMembers;
  final String? currentUserId;
  final String? ownerId;
  final int initialCount;

  const _GroupMembersSheet({
    required this.groupId,
    required this.service,
    required this.canPromote,
    required this.canManageMembers,
    this.currentUserId,
    this.ownerId,
    this.initialCount = 0,
  });

  @override
  State<_GroupMembersSheet> createState() => _GroupMembersSheetState();
}

class _GroupMembersSheetState extends State<_GroupMembersSheet> {
  static const int _pageSize = 30;
  final List<SocialUser> _members = <SocialUser>[];
  final Set<String> _promoting = <String>{};
  final Set<String> _removing = <String>{};
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _loadMembers(refresh: true);
  }

  String t(String key, String fallback) =>
      getTranslated(key, context) ?? fallback;

  Future<void> _loadMembers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _loading = true;
        _error = null;
        _offset = 0;
        _hasMore = true;
        _promoting.clear();
        _removing.clear();
      });
    } else {
      if (_loading || _loadingMore || !_hasMore) return;
      setState(() {
        _loadingMore = true;
        _error = null;
      });
    }

    try {
      final List<SocialUser> fetched = await widget.service.getGroupMembers(
        groupId: widget.groupId,
        limit: _pageSize,
        offset: refresh ? 0 : _offset,
      );
      if (!mounted) return;
      setState(() {
        if (refresh) {
          _members
            ..clear()
            ..addAll(fetched);
          _loading = false;
        } else {
          _members.addAll(fetched);
          _loadingMore = false;
        }
        _offset = refresh ? fetched.length : _offset + fetched.length;
        _hasMore = fetched.length >= _pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (refresh) {
          _loading = false;
        } else {
          _loadingMore = false;
        }
        _error = e.toString();
      });
    }
  }

  Future<void> _promoteMember(SocialUser member) async {
    if (!widget.canPromote || _promoting.contains(member.id)) return;
    setState(() {
      _promoting.add(member.id);
    });
    try {
      await widget.service.makeGroupAdmin(
        groupId: widget.groupId,
        userId: member.id,
      );
      if (!mounted) return;
      setState(() {
        final int index = _members.indexWhere((m) => m.id == member.id);
        if (index != -1) {
          _members[index] = _members[index].copyWith(isAdmin: true);
        }
        _promoting.remove(member.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('promote_success', 'Da cap quyen quan tri.'))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _promoting.remove(member.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _removeMember(SocialUser member) async {
    if (_removing.contains(member.id)) return;
    if (widget.currentUserId != null &&
        widget.currentUserId == member.id) {
      return;
    }
    setState(() {
      _removing.add(member.id);
    });
    try {
      await widget.service.removeGroupMember(
        groupId: widget.groupId,
        userId: member.id,
      );
      if (!mounted) return;
      setState(() {
        _removing.remove(member.id);
        _members.removeWhere((m) => m.id == member.id);
        _offset = _members.length;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('member_removed', 'Removed from group'))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _removing.remove(member.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Color sheetColor =
        theme.dialogTheme.backgroundColor ?? colorScheme.surface;
    final int totalKnown =
        _members.isNotEmpty ? _members.length : widget.initialCount;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Material(
        color: sheetColor,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('group_members', 'Thanh vien'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t('member_count',
                                '${totalKnown > 0 ? totalKnown : 0} thanh vien'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _loadMembers(refresh: true),
                  child: _buildList(theme, colorScheme),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(ThemeData theme, ColorScheme colorScheme) {
    if (_members.isEmpty && _loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_members.isEmpty && _error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('members_load_failed',
                      'Khong the tai danh sach thanh vien.'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _loadMembers(refresh: true),
                  icon: const Icon(Icons.refresh),
                  label: Text(t('retry', 'Thu lai')),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final bool loadMoreError =
        !_loadingMore && _error != null && _members.isNotEmpty;
    final bool showLoadMoreTile = _hasMore || _loadingMore || loadMoreError;

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _members.length + (showLoadMoreTile ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index < _members.length) {
          final SocialUser member = _members[index];
          return _buildMemberTile(member, theme, colorScheme);
        }

        if (_loadingMore) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (loadMoreError) {
          return OutlinedButton.icon(
            onPressed: () => _loadMembers(),
            icon: const Icon(Icons.refresh),
            label: Text(t('retry', 'Thu lai')),
          );
        }

        if (!_hasMore) {
          return const SizedBox.shrink();
        }

        return TextButton.icon(
          onPressed: () => _loadMembers(),
          icon: const Icon(Icons.more_horiz),
          label: Text(t('load_more', 'Tai them')),
        );
      },
    );
  }

  Widget _buildMemberTile(
      SocialUser member, ThemeData theme, ColorScheme colorScheme) {
    final bool isOwnerMember = member.isOwner ||
        (widget.ownerId != null && widget.ownerId == member.id);
    final bool isAdminMember = member.isAdmin;
    final bool hasAdminPrivileges = isOwnerMember || isAdminMember;
    final bool promoting = _promoting.contains(member.id);
    final bool removing = _removing.contains(member.id);
    final bool canRemove = widget.canManageMembers &&
        !hasAdminPrivileges &&
        member.id != widget.currentUserId;

    Widget? roleChip;
    if (isOwnerMember) {
      roleChip = Chip(
        label: Text(t('group_owner', 'Chu nhom')),
        labelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
      );
    } else if (isAdminMember) {
      roleChip = Chip(
        label: Text(t('group_admin', 'Quan tri vien')),
        labelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
      );
    }

    final List<Widget> actionButtons = <Widget>[];
    if (!hasAdminPrivileges &&
        widget.canPromote &&
        member.id != widget.currentUserId) {
      actionButtons.add(
        promoting
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              )
            : TextButton(
                onPressed: () => _promoteMember(member),
                child: Text(t('make_admin', 'Cap quyen quan tri')),
              ),
      );
    }

    if (canRemove) {
      actionButtons.add(
        removing
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.error),
                ),
              )
            : TextButton(
                onPressed: () => _removeMember(member),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error,
                ),
                child: Text(t('delete', 'Delete')),
              ),
      );
    }

    Widget? trailing;
    if (roleChip != null || actionButtons.isNotEmpty) {
      trailing = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (roleChip != null) roleChip,
          if (roleChip != null && actionButtons.isNotEmpty)
            const SizedBox(height: 8),
          if (actionButtons.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.end,
              children: actionButtons,
            ),
        ],
      );
    }

    final String initials = _resolveInitials(member);

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
          backgroundImage:
              (member.avatarUrl != null && member.avatarUrl!.isNotEmpty)
                  ? NetworkImage(member.avatarUrl!)
                  : null,
          child: (member.avatarUrl == null || member.avatarUrl!.isEmpty)
              ? Text(
                  initials,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.displayName ?? member.userName ?? member.id,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (member.userName != null && member.userName!.isNotEmpty)
                Text(
                  '@${member.userName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing,
        ],
      ],
    );
  }

  String _resolveInitials(SocialUser member) {
    final String? name = member.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name.substring(0, 1).toUpperCase();
    }
    final String? username = member.userName?.trim();
    if (username != null && username.isNotEmpty) {
      return username.substring(0, 1).toUpperCase();
    }
    return member.id.isNotEmpty ? member.id[0].toUpperCase() : '?';
  }
}

class _GroupEvent {
  final String title;
  final String schedule;
  final String description;

  const _GroupEvent({
    required this.title,
    required this.schedule,
    required this.description,
  });
}

class _InviteMembersSheet extends StatefulWidget {
  final String groupId;
  final SocialGroupServiceInterface service;

  const _InviteMembersSheet({
    required this.groupId,
    required this.service,
  });

  @override
  State<_InviteMembersSheet> createState() => _InviteMembersSheetState();
}

class _InviteMembersSheetState extends State<_InviteMembersSheet> {
  static const int _pageSize = 30;
  final List<SocialUser> _suggestions = <SocialUser>[];
  final Set<String> _inviting = <String>{};
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _loadSuggestions(refresh: true);
  }

  String t(String key, String fallback) =>
      getTranslated(key, context) ?? fallback;

  Future<void> _loadSuggestions({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _loading = true;
        _error = null;
        _offset = 0;
        _hasMore = true;
      });
    } else {
      if (_loading || _loadingMore || !_hasMore) return;
      setState(() {
        _loadingMore = true;
        _error = null;
      });
    }

    try {
      final List<SocialUser> fetched = await widget.service.getGroupNonMembers(
        groupId: widget.groupId,
        limit: _pageSize,
        offset: refresh ? 0 : _offset,
      );
      if (!mounted) return;
      setState(() {
        if (refresh) {
          _suggestions
            ..clear()
            ..addAll(fetched);
          _loading = false;
        } else {
          _suggestions.addAll(fetched);
          _loadingMore = false;
        }
        _offset = refresh ? fetched.length : _offset + fetched.length;
        _hasMore = fetched.length >= _pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (refresh) {
          _loading = false;
        } else {
          _loadingMore = false;
        }
        _error = e.toString();
      });
    }
  }

  Future<void> _invite(SocialUser user) async {
    if (_inviting.contains(user.id)) return;
    setState(() {
      _inviting.add(user.id);
    });
    try {
      await widget.service.inviteGroupMember(
        groupId: widget.groupId,
        userId: user.id,
      );
      if (!mounted) return;
      setState(() {
        _inviting.remove(user.id);
        _suggestions.removeWhere((element) => element.id == user.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('invite_sent', 'Invitation sent')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _inviting.remove(user.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color sheetColor =
        theme.dialogTheme.backgroundColor ?? colorScheme.surface;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Material(
        color: sheetColor,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('invite_members', 'Invite members'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t('group_invite_suggestions',
                                'People not in this group'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _loadSuggestions(refresh: true),
                  child: _buildList(theme, colorScheme),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(ThemeData theme, ColorScheme colorScheme) {
    if (_suggestions.isEmpty && _loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_suggestions.isEmpty && _error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('members_load_failed',
                      'Failed to load invite suggestions.'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _loadSuggestions(refresh: true),
                  icon: const Icon(Icons.refresh),
                  label: Text(t('retry', 'Thu lai')),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_suggestions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        children: [
          Column(
            children: [
              Icon(
                Icons.group_outlined,
                size: 48,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                t('no_invite_suggestions', 'No members to invite right now.'),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      );
    }

    final bool loadMoreError =
        !_loadingMore && _error != null && _suggestions.isNotEmpty;
    final bool showLoadMoreTile = _hasMore || _loadingMore || loadMoreError;

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _suggestions.length + (showLoadMoreTile ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index < _suggestions.length) {
          final SocialUser user = _suggestions[index];
          return _buildUserTile(user, theme, colorScheme);
        }

        if (_loadingMore) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (loadMoreError) {
          return OutlinedButton.icon(
            onPressed: () => _loadSuggestions(),
            icon: const Icon(Icons.refresh),
            label: Text(t('retry', 'Thu lai')),
          );
        }

        if (!_hasMore) {
          return const SizedBox.shrink();
        }

        return TextButton.icon(
          onPressed: () => _loadSuggestions(),
          icon: const Icon(Icons.more_horiz),
          label: Text(t('load_more', 'Tai them')),
        );
      },
    );
  }

  Widget _buildUserTile(
      SocialUser user, ThemeData theme, ColorScheme colorScheme) {
    final bool inviting = _inviting.contains(user.id);
    final String initials = _initials(user);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
        backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
            ? NetworkImage(user.avatarUrl!)
            : null,
        child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
            ? Text(
                initials,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              )
            : null,
      ),
      title: Text(
        _displayName(user),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: user.userName != null && user.userName!.isNotEmpty
          ? Text(
              '@${user.userName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            )
          : null,
      trailing: inviting
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            )
          : FilledButton(
              onPressed: () => _invite(user),
              child: Text(t('invite', 'Invite')),
            ),
    );
  }

  String _displayName(SocialUser user) {
    final String? displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    final String? username = user.userName?.trim();
    if (username != null && username.isNotEmpty) {
      return username;
    }
    return user.id;
  }

  String _initials(SocialUser user) {
    final String name = _displayName(user);
    if (name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
  }
}

class _JoinRequestsSheet extends StatefulWidget {
  final SocialGroup group;
  final SocialGroupServiceInterface service;

  const _JoinRequestsSheet({
    required this.group,
    required this.service,
  });

  @override
  State<_JoinRequestsSheet> createState() => _JoinRequestsSheetState();
}

class _JoinRequestsSheetState extends State<_JoinRequestsSheet> {
  bool _loading = true;
  String? _error;
  List<SocialGroupJoinRequest> _requests = <SocialGroupJoinRequest>[];
  final Set<String> _processing = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _processing.clear();
      _loading = true;
      _error = null;
    });
    try {
      final List<SocialGroupJoinRequest> results =
          await widget.service.getGroupJoinRequests(
        groupId: widget.group.id,
        limit: 50,
        offset: 0,
      );
      if (!mounted) return;
      setState(() {
        _requests = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final String title = widget.group.title?.isNotEmpty == true
        ? widget.group.title!
        : widget.group.name;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    getTranslated('join_requests', context) ?? 'Join requests',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody(context, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              getTranslated('failed_to_load', context) ?? 'Failed to load data',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _load,
              child: Text(getTranslated('retry', context) ?? 'Retry'),
            ),
          ],
        ),
      );
    }
    if (_requests.isEmpty) {
      return Center(
        child: Text(
          getTranslated('no_join_requests', context) ??
              'No pending join requests.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: theme.dividerColor.withOpacity(.2),
        ),
        itemBuilder: (BuildContext context, int index) {
          final SocialGroupJoinRequest request = _requests[index];
          final SocialUser user = request.user;
          final bool processing = _processing.contains(request.key);
          return ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.12),
              backgroundImage:
                  user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? NetworkImage(user.avatarUrl!)
                      : null,
              child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                  ? Text(
                      _initials(user),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            title: Text(
              _displayName(user),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user.userName != null && user.userName!.isNotEmpty)
                  Text(
                    '@${user.userName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton(
                      onPressed: processing
                          ? null
                          : () => _handleRequestAction(
                                request: request,
                                accept: true,
                              ),
                      child: processing
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              getTranslated('accept', context) ?? 'Accept',
                            ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: processing
                          ? null
                          : () => _handleRequestAction(
                                request: request,
                                accept: false,
                              ),
                      child: Text(
                        getTranslated('delete', context) ?? 'Delete',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _displayName(SocialUser user) {
    final String? displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    final String? username = user.userName?.trim();
    if (username != null && username.isNotEmpty) {
      return username;
    }
    return user.id;
  }

  String _initials(SocialUser user) {
    final String name = _displayName(user);
    if (name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
  }

  Future<void> _handleRequestAction({
    required SocialGroupJoinRequest request,
    required bool accept,
  }) async {
    if (_processing.contains(request.key)) return;
    setState(() {
      _processing.add(request.key);
    });
    try {
      await widget.service.respondToJoinRequest(
        groupId: widget.group.id,
        userId: request.userId,
        requestId: request.requestId,
        accept: accept,
      );
      if (!mounted) return;
      setState(() {
        _processing.remove(request.key);
        _requests.removeWhere(
          (element) =>
              element.key == request.key || element.userId == request.userId,
        );
      });
      if (!mounted) return;
      final String messageKey =
          accept ? 'join_request_accepted' : 'join_request_removed';
      final String fallback = accept ? 'Request accepted' : 'Request removed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTranslated(messageKey, context) ?? fallback),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing.remove(request.key);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

enum _GroupMenuAction { joinRequests, inviteMembers, reportGroup, deleteGroup }
