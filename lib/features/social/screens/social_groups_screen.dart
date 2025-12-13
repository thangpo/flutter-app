import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' show lerpDouble;

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_group_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_group.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

import 'social_group_detail_screen.dart';
import 'social_group_form_screen.dart';
import 'social_screen.dart' show SocialPostCard;

class SocialGroupsScreen extends StatefulWidget {
  const SocialGroupsScreen({super.key});

  @override
  State<SocialGroupsScreen> createState() => _SocialGroupsScreenState();
}

class _SocialGroupsScreenState extends State<SocialGroupsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _requestedSuggestedGroups = false;
  bool _requestedUserGroups = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requestedSuggestedGroups) {
      _requestedSuggestedGroups = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<SocialController>().loadSuggestedGroups();
      });
    }
    if (!_requestedUserGroups) {
      _requestedUserGroups = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<SocialController>().loadUserGroups();
      });
    }
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging && _tabController.index == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<SocialController>().loadGroupPosts();
      });
    }
  }

  Future<void> _openCreateGroup() async {
    final SocialGroup? created = await Navigator.of(context).push<SocialGroup>(
      MaterialPageRoute<SocialGroup>(
        builder: (_) => const SocialGroupFormScreen(),
        fullscreenDialog: true,
      ),
    );

    if (!mounted || created == null) return;

    await context.read<SocialController>().loadUserGroups(forceRefresh: true);

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SocialGroupDetailScreen(
          groupId: created.id,
          initialGroup: created,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appBarBackground =
        theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor;
    final appBarForeground =
        theme.appBarTheme.foregroundColor ?? colorScheme.onSurface;
    final unselectedTabColor = colorScheme.onSurface.withValues(alpha: 0.6);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(136),
        child: Container(
          decoration: BoxDecoration(
            color: appBarBackground,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ========== TOP ROW: BACK + TITLE + ACTIONS ==========
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      _RoundIconButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                        background: theme.brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        getTranslated('groups', context) ?? 'Nhóm',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: appBarForeground,
                        ),
                      ),
                      const Spacer(),
                      _RoundIconButton(
                        icon: Icons.add,
                        onTap: _openCreateGroup,
                      ),
                      const SizedBox(width: 8),
                      _RoundIconButton(
                        icon: Icons.person,
                        onTap: () {
                          // TODO: mở profile social
                        },
                      ),
                      const SizedBox(width: 8),
                      _RoundIconButton(
                        icon: Icons.search,
                        onTap: () {
                          // TODO: mở search
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // ========== TAB BAR (PILL) ==========
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: AnimatedBuilder(
                      animation: _tabController.animation!,
                      builder: (context, _) {
                        final anim = _tabController.animation!;
                        final page = anim.value;
                        final distToNearest =
                        (page - page.round()).abs().clamp(0.0, 0.5);
                        final progress = (distToNearest / 0.5).clamp(0.0, 1.0);
                        final radius = lerpDouble(12, 999, progress)!;

                        return TabBar(
                          controller: _tabController,
                          isScrollable: false,
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(radius),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: unselectedTabColor,
                          labelStyle: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          tabs: [
                            Tab(text: getTranslated('for_you', context) ?? 'Dành cho bạn'),
                            Tab(text: getTranslated('your_groups', context) ?? 'Nhóm của bạn'),
                            Tab(text: getTranslated('posts', context) ?? 'Bài viết'),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),

      // Body chỉ còn TabBarView như bên Page
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildForYouTab(context),
          _buildYourGroupsTab(context),
          _buildPostsTab(context),
        ],
      ),
    );
  }

  Widget _buildForYouTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = context.watch<SocialController>();
    final List<SocialGroup> groups = controller.suggestedGroups
        .where((group) => !group.isJoined && group.joinRequestStatus != 2)
        .toList();
    final bool loading = controller.loadingSuggestedGroups;

    return RefreshIndicator(
      onRefresh: () => context
          .read<SocialController>()
          .loadSuggestedGroups(forceRefresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              getTranslated('suggested_for_you', context) ?? 'Gợi ý cho bạn',
              style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ) ??
                  TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (loading && groups.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!loading && groups.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                getTranslated('no_suggested_groups', context) ??
                    'Chưa có nhóm nào gợi ý',
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ) ??
                    TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
              ),
            ),
          if (loading && groups.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (groups.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return Builder(
                  builder: (innerCtx) => _buildGroupCard(innerCtx, group),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, SocialGroup group) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String? imageUrl = group.coverUrl ?? group.avatarUrl;
    final DecorationImage? backgroundImage =
        imageUrl != null && imageUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              )
            : (Images.placeholder.isNotEmpty
                ? DecorationImage(
                    image: AssetImage(Images.placeholder),
                    fit: BoxFit.cover,
                  )
                : null);
    final String title = group.title != null && group.title!.isNotEmpty
        ? group.title!
        : group.name;
    final String subtitle = _buildGroupSubtitle(group);

    final bool isJoining = context.select<SocialGroupController, bool>(
      (controller) => controller.joiningGroup(group.id),
    );
    final bool isJoined = group.isJoined || group.isOwner;
    final bool pendingApproval =
        !isJoined && (group.joinRequestStatus == 2 || group.requiresApproval);
    final bool disableJoin = isJoining || isJoined || pendingApproval;

    void openGroupDetail() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SocialGroupDetailScreen(
            groupId: group.id,
            initialGroup: group,
          ),
        ),
      );
    }

    Future<void> handleJoin() async {
      final SocialGroupController groupController =
          context.read<SocialGroupController>();
      final SocialController socialController =
          context.read<SocialController>();
      try {
        final SocialGroup? updated = await groupController.joinGroup(group.id);
        if (!mounted) return;
        socialController.removeSuggestedGroupById(group.id);
        await socialController.loadUserGroups(forceRefresh: true);
        final SocialGroup effective = updated ?? group;
        final bool approvalNeeded =
            effective.joinRequestStatus == 2 || effective.requiresApproval;
        final String message = approvalNeeded
            ? (getTranslated('join_request_submitted', context) ??
                'Join request submitted for approval')
            : (getTranslated('joined_group_successfully', context) ??
                'Joined group successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }

    final String buttonLabel = isJoined
        ? (getTranslated('joined', context) ?? 'Đã tham gia')
        : (pendingApproval
            ? (getTranslated('pending_approval', context) ?? 'Đang chờ duyệt')
            : (getTranslated('join', context) ?? 'Tham gia'));
    final Widget buttonChild = isJoining
        ? SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
            ),
          )
        : Text(
            buttonLabel,
            style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ) ??
                TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
          );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: openGroupDetail,
        child: Ink(
          decoration: BoxDecoration(
            image: backgroundImage,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ) ??
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ) ??
                          TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                          ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: disableJoin ? null : handleJoin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: buttonChild,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildGroupSubtitle(SocialGroup group) {
    final String privacy = (group.privacy ?? '').trim().toLowerCase();
    final bool isPrivate = privacy == '2' ||
        privacy.contains('private') ||
        privacy.contains('closed');
    final String privacyLabel = isPrivate
        ? (getTranslated('private_group', context) ?? 'Private group')
        : (getTranslated('public_group', context) ?? 'Public group');

    final int count = group.memberCount;
    final String memberLabel = count > 0
        ? '${count} ${getTranslated('members', context) ?? 'members'}'
        : (getTranslated('no_members_yet', context) ?? 'No members yet');

    return '$privacyLabel | $memberLabel';
  }

  Widget _buildYourGroupsTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = context.watch<SocialController>();
    final List<SocialGroup> groups = controller.userGroups;
    final bool loading = controller.loadingUserGroups;

    final headerStyle = theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        );

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            getTranslated('recent_activity', context) ?? 'Hoạt động gần đây',
            style: headerStyle,
          ),
        ),
        if (loading && groups.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!loading && groups.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              getTranslated('you_have_no_groups', context) ??
                  'Bạn chưa tham gia nhóm nào.',
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ) ??
                  TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
            ),
          ),
        if (groups.isNotEmpty) ..._buildGroupListItems(context, groups),
        const SizedBox(height: 16),
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
                getTranslated('explore_more', context) ?? 'Khám phá thêm',
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
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _QuickAction(
                    icon: Icons.group_add,
                    label: getTranslated('create_group', context) ?? 'Tạo nhóm',
                    onTap: _openCreateGroup,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGroupListItems(
      BuildContext context, List<SocialGroup> groups) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Color mutedColor = colorScheme.onSurface.withValues(alpha: 0.6);

    return groups
        .map(
          (group) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SocialGroupDetailScreen(
                      groupId: group.id,
                      initialGroup: group,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.group,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.title?.isNotEmpty == true
                                ? group.title!
                                : group.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ) ??
                                TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatGroupActivity(group),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                                  color: mutedColor,
                                ) ??
                                TextStyle(
                                  color: mutedColor,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  String _formatGroupActivity(SocialGroup group) {
    final int members = group.memberCount;
    final String memberLabel = members > 0
        ? '$members ${getTranslated('members', context) ?? 'thành viên'}'
        : (getTranslated('no_members_yet', context) ?? 'Chưa có thành viên');

    final DateTime? updated = group.updatedAt ?? group.createdAt;
    if (updated != null) {
      final Duration diff = DateTime.now().difference(updated);
      if (diff.inDays >= 1) {
        return '$memberLabel • ${diff.inDays} ${getTranslated('days_ago', context) ?? 'ngày trước'}';
      }
      if (diff.inHours >= 1) {
        return '$memberLabel • ${diff.inHours} ${getTranslated('hours_ago', context) ?? 'giờ trước'}';
      }
      if (diff.inMinutes >= 1) {
        return '$memberLabel • ${diff.inMinutes} ${getTranslated('minutes_ago', context) ?? 'phút trước'}';
      }
    }
    return memberLabel;
  }

  Widget _buildPostsTab(BuildContext context) {
    final controller = context.watch<SocialController>();
    final List<SocialPost> posts = controller.groupPosts;
    final bool loading = controller.loadingGroupPosts;

    if (_tabController.index == 2 &&
        !controller.groupPostsFetched &&
        !controller.loadingGroupPosts) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<SocialController>().loadGroupPosts();
      });
    }

    Widget buildEmpty({required String message}) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      return ListView(
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
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ) ??
                  TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
            ),
          ),
        ],
      );
    }

    Widget listView;
    if (loading && posts.isEmpty) {
      listView = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          )
        ],
      );
    } else if (posts.isEmpty) {
      listView = buildEmpty(
        message: getTranslated('no_group_posts_yet', context) ??
            'Chưa có bài viết nào từ các nhóm của bạn.',
      );
    } else {
      listView = ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final SocialPost post = posts[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: SocialPostCard(post: post),
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          context.read<SocialController>().loadGroupPosts(forceRefresh: true),
      child: listView,
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final BorderRadius radius = BorderRadius.circular(10);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: radius,
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ) ??
                      TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? background;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: background ?? theme.cardColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}