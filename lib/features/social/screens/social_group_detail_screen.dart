import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/di_container.dart' as di;
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_feed_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_group.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
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
                  IconButton(
                    icon: Icon(Icons.more_horiz,
                        color: theme.appBarTheme.foregroundColor ??
                            colorScheme.onSurface),
                    onPressed: () {},
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
        info?.imageFullUrl?.toString(),
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
                backgroundColor:
                    colorScheme.surface.withValues(alpha: 0.12),
                backgroundImage:
                    (avatarUrl != null && avatarUrl.isNotEmpty)
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
                          color:
                              colorScheme.onSurface.withValues(alpha: 0.7),
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
  final String? ownerId;
  final int initialCount;

  const _GroupMembersSheet({
    required this.groupId,
    required this.service,
    required this.canPromote,
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
    final bool isOwner = member.isOwner ||
        (widget.ownerId != null && widget.ownerId == member.id);
    final bool isAdmin = member.isAdmin || isOwner;
    final bool promoting = _promoting.contains(member.id);

    Widget? trailing;
    if (isOwner) {
      trailing = Chip(
        label: Text(t('group_owner', 'Chu nhom')),
        labelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
      );
    } else if (isAdmin) {
      trailing = Chip(
        label: Text(t('group_admin', 'Quan tri vien')),
        labelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
      );
    } else if (widget.canPromote) {
      trailing = promoting
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            )
          : TextButton(
              onPressed: () => _promoteMember(member),
              child: Text(t('make_admin', 'Cap quyen quan tri')),
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
