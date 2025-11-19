// lib/features/social/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:flutter/services.dart'; // Clipboard
import 'dart:typed_data';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/chat_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/edit_profile_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/create_post_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/create_story_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user_profile.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_reel.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_screen.dart'
    show SocialPostCard;
import 'package:flutter_sixvalley_ecommerce/features/social/screens/member_list_bottom_sheet.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/wallet_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/pokes_screen.dart';
import 'package:video_player/video_player.dart';

/// Tab hiện tại
enum _ProfileTab { posts, about, reels, photos }

class ProfileScreen extends StatefulWidget {
  final String? targetUserId;
  const ProfileScreen({super.key, this.targetUserId});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ImageTab extends StatelessWidget {
  final ImageProvider image;
  final bool active;
  final VoidCallback onTap;
  final bool showDropdown;
  const _ImageTab({
    required this.image,
    required this.onTap,
    this.active = false,
    this.showDropdown = false,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? theme.colorScheme.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: active
              ? Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.6), width: 1.2)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ImageIcon(image,
                size: 18,
                color: active ? theme.colorScheme.primary : theme.hintColor),
            if (showDropdown) const SizedBox(width: 4),
            if (showDropdown)
              Icon(Icons.keyboard_arrow_down,
                  size: 16,
                  color: active ? theme.colorScheme.primary : theme.hintColor),
          ],
        ),
      ),
    );
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialController>().loadUserProfile(
            targetUserId: widget.targetUserId,
            force: false, // KHÔNG ép tải lại
            useCache: true, // ƯU TIÊN cache để render ngay
            backgroundRefresh: true, // cache cũ thì refresh NGẦM
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _ProfileBody(targetUserId: widget.targetUserId),
      ),
    );
  }
}

class _ProfileBody extends StatefulWidget {
  final String? targetUserId;
  const _ProfileBody({required this.targetUserId});
  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
  _ProfileTab _currentTab = _ProfileTab.posts;
  @override
  bool get wantKeepAlive => true;
  Future<void> _handleRefresh() async {
    final sc = context.read<SocialController>();
    await sc.loadUserProfile(
      targetUserId: widget.targetUserId,
      force: true, // ÉP tải mới
      useCache: true, // vẫn render cache trước khi tải
      backgroundRefresh: false,
    );
  }

  void _switchToAbout() {
    setState(() => _currentTab = _ProfileTab.about);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SocialController>(
      builder: (context, sc, _) {
        final loadingProfile = sc.isLoadingProfile;
        final loadingPosts = sc.isLoadingProfilePosts;
        final headerUser = sc.profileHeaderUser;
        final safeHeaderUser = headerUser ??
            const SocialUserProfile(
              id: '0',
              displayName: 'Người dùng',
              firstName: null,
              lastName: null,
              userName: null,
              avatarUrl: null,
              coverUrl: null,
              followersCount: 0,
              followingCount: 0,
              postsCount: 0,
              friendsCount: 0,
              isVerified: false,
              about: null,
              work: null,
              education: null,
              city: null,
              country: null,
              website: null,
              birthday: null,
              relationshipStatus: null,
              genderText: null,
              lastSeenText: null,
              isFollowing: false,
              isFollowingMe: false,
            );

        final recentFollowers = sc.followers.toList();
        final posts = sc.profilePosts;
        final myId = sc.currentUser?.id;
        final bool isSelf = (widget.targetUserId == null ||
            widget.targetUserId!.isEmpty ||
            widget.targetUserId == myId);

        Widget tabContent;
        switch (_currentTab) {
          case _ProfileTab.about:
            tabContent = _ProfileAboutSection(user: safeHeaderUser);
            break;
          case _ProfileTab.photos:
            tabContent =
                _ProfilePhotosSection(targetUserId: widget.targetUserId);
            break;
          case _ProfileTab.reels:
            tabContent =
                _ProfileReelsSection(targetUserId: widget.targetUserId);
            break;
          case _ProfileTab.posts:
          default:
            tabContent = _ProfilePostsSection(
              user: safeHeaderUser,
              posts: posts,
              isLoadingMore: loadingPosts,
              onLoadMore: () {
                sc.loadMoreProfilePosts(
                    targetUserId: widget.targetUserId, limit: 10);
              },
              onShowAbout: _switchToAbout,
              isSelf: isSelf,
            );
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            key: const PageStorageKey('profile_scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _ProfileAppBar(user: safeHeaderUser),
              SliverToBoxAdapter(
                child: _ProfileHeaderSection(
                  user: safeHeaderUser,
                  recentFollowers: recentFollowers,
                  currentTab: _currentTab,
                  onTabSelected: (_ProfileTab tab) async {
                    setState(() => _currentTab = tab);
                    if (tab == _ProfileTab.reels) {
                      final viewedId = widget.targetUserId ??
                          sc.profileHeaderUser?.id ??
                          sc.currentUser?.id;
                      if ((sc.profileReels.isEmpty ||
                              sc.reelsForUserId != viewedId) &&
                          !sc.isLoadingProfileReels) {
                        await sc.refreshProfileReels(
                            targetUserId: viewedId, limit: 20);
                      }
                    }
                  },
                  isSelf: isSelf,
                ),
              ),
              SliverToBoxAdapter(child: tabContent),
              const SliverToBoxAdapter(
                  child: SizedBox(height: Dimensions.paddingSizeExtraLarge)),
              if (loadingProfile && headerUser == null)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ==============================
// APP BAR
// ==============================
class _ProfileAppBar extends StatelessWidget {
  final SocialUserProfile user;
  const _ProfileAppBar({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFirst = user.firstName?.trim().isNotEmpty == true;
    final hasLast = user.lastName?.trim().isNotEmpty == true;
    final hasFullName = hasFirst || hasLast;
    final primaryTitle = hasFullName
        ? '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim()
        : (user.userName ?? getTranslated('profile', context) ?? 'Profile');

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.95),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              primaryTitle,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (user.isVerified)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.verified, color: Colors.red, size: 18),
            ),
        ],
      ),
      actions: const [],
    );
  }
}

// ==============================
// HEADER – Cover, Avatar, Stats, Buttons, Tabs
// ==============================
class _ProfileHeaderSection extends StatelessWidget {
  final SocialUserProfile user;
  final List<SocialUser> recentFollowers;
  final _ProfileTab currentTab;
  final ValueChanged<_ProfileTab> onTabSelected;
  final bool isSelf;
  const _ProfileHeaderSection({
    required this.user,
    required this.recentFollowers,
    required this.currentTab,
    required this.onTabSelected,
    required this.isSelf,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullName = (() {
      final first = (user.firstName ?? '').trim();
      final last = (user.lastName ?? '').trim();
      final firstLast =
          [first, last].where((s) => s.isNotEmpty).join(' ').trim();
      if (firstLast.isNotEmpty) return firstLast;
      if (user.displayName?.trim().isNotEmpty == true)
        return user.displayName!.trim();
      return user.userName ?? getTranslated('user', context) ?? 'Người dùng';
    })();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // === COVER + AVATAR ===
        SizedBox(
          height: 220,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: user.coverUrl?.isNotEmpty == true
                    ? Image.network(
                        user.coverUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                    child: CircularProgressIndicator())),
                        errorBuilder: (_, __, ___) => _CoverFallback(),
                      )
                    : _CoverFallback(),
              ),
              Positioned(
                left: 16,
                bottom: -40,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 6))
                    ],
                  ),
                  child: ClipOval(
                    child: user.avatarUrl?.isNotEmpty == true
                        ? Image.network(
                            user.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _AvatarFallback(),
                          )
                        : const _AvatarFallback(),
                  ),
                ),
              ),
              // === NÚT VÍ ===
              if (isSelf)
                Positioned(
                  right: 16,
                  bottom: -15,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WalletScreen())
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.7),
                            Colors.white.withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                            spreadRadius: -5,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(-2, -2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.blue.shade600,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                getTranslated('my_wallet', context) ?? 'Ví của tôi',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 70),
        // ===== NAME + VERIFIED BADGE =====
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  fullName,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              if (user.isVerified)
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, size: 20),
            ],
          ),
        ),
        // ===== USERNAME =====
        Builder(
          builder: (_) {
            final hasFirst = user.firstName?.trim().isNotEmpty == true;
            final hasLast = user.lastName?.trim().isNotEmpty == true;
            final hasFullName = hasFirst || hasLast;
            final handle = (user.userName?.trim().isNotEmpty == true)
                ? (user.userName!.startsWith('@')
                    ? user.userName!
                    : '@${user.userName!}')
                : null;
            if (hasFullName && handle != null) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  handle,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.hintColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 4),
        // ===== FOLLOWERS/FOLLOWING =====
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Builder(builder: (context) {
            final theme = Theme.of(context);
            final sc =
                context.watch<SocialController>(); // lắng nghe để rebuild
            final isViewingSame = sc.profileHeaderUser?.id == user.id;

            // Ưu tiên length của state nếu đang xem đúng user;
            // fallback về số trong user.*Count khi list chưa có.
            final followersCount = isViewingSame && sc.followers.isNotEmpty
                ? sc.followers.length
                : (user.followersCount ?? 0);

            final followingCount = isViewingSame && sc.following.isNotEmpty
                ? sc.following.length
                : (user.followingCount ?? 0);

            return Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                InkWell(
                  onTap: () => _showFollowersSheet(context),
                  child: Text(
                    '${_formatCount(followersCount)} ${getTranslated('followers', context) ?? 'người theo dõi'}',
                    style: TextStyle(fontSize: 14, color: theme.hintColor),
                  ),
                ),
                Text('•',
                    style: TextStyle(fontSize: 14, color: theme.hintColor)),
                InkWell(
                  onTap: () => _showFollowingSheet(context),
                  child: Text(
                    '${_formatCount(followingCount)} ${getTranslated('following', context) ?? 'đang theo dõi'}',
                    style: TextStyle(fontSize: 14, color: theme.hintColor),
                  ),
                ),
              ],
            );
          }),
        ),

        const SizedBox(height: 16),
        // FOLLOWERS STACK
        if (recentFollowers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => _showFollowersSheet(context),
              child: _CompactFollowersRow(
                  followers: recentFollowers.take(6).toList()),
            ),
          ),
        const SizedBox(height: 20),
        // ===== ACTION BUTTONS =====
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              if (isSelf) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.work_outline, size: 18),
                        label: Text(
                          getTranslated('professional_tools', context) ??
                              'Công cụ chuyên nghiệp',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13.5),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          elevation: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const SocialCreateStoryScreen(),
                            fullscreenDialog: true,
                          ));
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          side:
                              BorderSide(color: theme.dividerColor, width: 1.2),
                        ),
                        child: Text(
                          getTranslated('add_to_story', context) ??
                              '+ Thêm vào tin',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => EditProfileScreen(
                                profile: user, onSave: (updatedProfile) {}),
                          ));
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: Text(
                          getTranslated('edit_profile', context) ??
                              'Chỉnh sửa trang cá nhân',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13.5),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          side:
                              BorderSide(color: theme.dividerColor, width: 1.2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _MoreCircleButton(
                        onPressed: () => _showSelfProfileMenu(context, user)),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Consumer<SocialController>(
                        builder: (context, sc, __) {
                          final bool busy = sc.isFollowBusy(user.id);
                          final bool following =
                              sc.profileHeaderUser?.id == user.id
                                  ? (sc.profileHeaderUser?.isFollowing ??
                                      user.isFollowing)
                                  : user.isFollowing;
                          return FilledButton.icon(
                            onPressed: busy
                                ? null
                                : () async {
                                    await context
                                        .read<SocialController>()
                                        .toggleFollowUser(
                                            targetUserId: user.id);
                                  },
                            icon: busy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Icon(
                                    following
                                        ? Icons.check
                                        : Icons.person_add_alt_1,
                                    size: 18),
                            label: Text(
                              following
                                  ? (getTranslated('following', context) ??
                                      'Đang theo dõi')
                                  : (getTranslated('follow', context) ??
                                      'Theo dõi'),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13.5),
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                              elevation: 1,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final sp = await SharedPreferences.getInstance();
                          final token =
                              sp.getString(AppConstants.socialAccessToken);
                          if (token == null || token.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(getTranslated(
                                          'not_logged_in_social', context) ??
                                      'Bạn chưa đăng nhập MXH')),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                peerUserId: user.id,
                                accessToken: token,
                                peerName: user.displayName ??
                                    user.userName ??
                                    getTranslated('chat', context) ??
                                    'Đoạn chat',
                                peerAvatar: user.avatarUrl,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: Text(
                          getTranslated('messages', context) ?? 'Nhắn tin',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          side:
                              BorderSide(color: theme.dividerColor, width: 1.2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _MoreCircleButton(
                        onPressed: () => _showOtherProfileMenu(context, user)),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        // ===== TAB BAR =====
        SizedBox(
          height: 44,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              _SimpleTab(
                label: getTranslated('posts', context) ?? 'Bài viết',
                active: currentTab == _ProfileTab.posts,
                onTap: () => onTabSelected(_ProfileTab.posts),
              ),
              _SimpleTab(
                label: getTranslated('about', context) ?? 'Giới thiệu',
                active: currentTab == _ProfileTab.about,
                onTap: () => onTabSelected(_ProfileTab.about),
              ),
              _SimpleTab(
                label: getTranslated('reels', context) ?? 'Reels',
                active: currentTab == _ProfileTab.reels,
                onTap: () => onTabSelected(_ProfileTab.reels),
              ),
              _SimpleTab(
                label: getTranslated('photos', context) ?? 'Ảnh',
                active: currentTab == _ProfileTab.photos,
                onTap: () => onTabSelected(_ProfileTab.photos),
              ),
            ],
          ),
        ),
        Divider(
            height: 1,
            thickness: 0.8,
            color: theme.dividerColor.withOpacity(0.5)),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      final k = count / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}K';
    }
    return count.toString();
  }

  void _showFollowersSheet(BuildContext context) {
    final sc = context.read<SocialController>();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: MemberListBottomSheet(
          title: getTranslated('followers', context) ?? 'Người theo dõi',
          totalCount: sc.profileHeaderUser?.followersCount,
          pageLoader: (after) async {
            const pageSize = 30;
            final start = int.tryParse(after ?? '0') ?? 0;
            final List<SocialUser> all = sc.followers.toList();
            final pageUsers = all.skip(start).take(pageSize).toList();
            final next =
                (start + pageSize < all.length) ? '${start + pageSize}' : null;
            return MemberPage(users: pageUsers, nextCursor: next);
          },
          // === Điều hướng sang Profile khi chạm 1 user ===
          onUserTap: (u) {
            Navigator.of(context).pop();
            Future.microtask(() {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                    builder: (_) => ProfileScreen(targetUserId: u.id)),
              );
            });
          },
        ),
      ),
    );
  }

  void _showFollowingSheet(BuildContext context) {
    final sc = context.read<SocialController>();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: MemberListBottomSheet(
          title: getTranslated('following', context) ?? 'Đang theo dõi',
          totalCount: sc.profileHeaderUser?.followingCount,
          pageLoader: (after) async {
            const pageSize = 30;
            final start = int.tryParse(after ?? '0') ?? 0;
            final List<SocialUser> all = sc.following.toList();
            final pageUsers = all.skip(start).take(pageSize).toList();
            final next =
                (start + pageSize < all.length) ? '${start + pageSize}' : null;
            return MemberPage(users: pageUsers, nextCursor: next);
          },
          // === Điều hướng sang Profile khi chạm 1 user ===
          onUserTap: (u) {
            Navigator.of(context).pop();
            Future.microtask(() {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                    builder: (_) => ProfileScreen(targetUserId: u.id)),
              );
            });
          },
        ),
      ),
    );
  }
}

// ==============================
// COVER & AVATAR FALLBACK
// ==============================
class _CoverFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.image, size: 60, color: Colors.white54),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.dividerColor,
      alignment: Alignment.center,
      child: Icon(Icons.person, size: 36, color: theme.hintColor),
    );
  }
}

// ==============================
// FOLLOWERS ROW
// ==============================
class _CompactFollowersRow extends StatelessWidget {
  final List<SocialUser> followers;
  const _CompactFollowersRow({required this.followers});
  @override
  Widget build(BuildContext context) {
    final display = followers.take(6).toList();
    final remain = followers.length - display.length;
    return SizedBox(
      height: 40,
      child: Stack(
        children: [
          for (int i = 0; i < display.length; i++)
            Positioned(
              left: i * 26.0,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: display[i].avatarUrl?.isNotEmpty == true
                      ? NetworkImage(display[i].avatarUrl!)
                      : null,
                  child: display[i].avatarUrl?.isNotEmpty != true
                      ? const Icon(Icons.person, size: 16, color: Colors.grey)
                      : null,
                ),
              ),
            ),
          if (remain > 0)
            Positioned(
              left: display.length * 26.0,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade400,
                child: Text('+$remain',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}

// ==============================
// TAB ITEM
// ==============================
class _SimpleTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SimpleTab(
      {required this.label, required this.onTap, this.active = false});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? theme.colorScheme.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: active
              ? Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.6), width: 1.2)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            color: active
                ? theme.colorScheme.primary
                : theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
          ),
        ),
      ),
    );
  }
}

// ==============================
// CHI TIẾT + BÀI VIẾT BLOCK
// ==============================
class _ProfileDetailsBlock extends StatelessWidget {
  final SocialUserProfile user;
  final VoidCallback onShowAbout;
  final bool isSelf;
  const _ProfileDetailsBlock(
      {required this.user, required this.onShowAbout, required this.isSelf});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final String? avatarUrl = user.avatarUrl;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTranslated('details', context) ?? 'Chi tiết',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4),
                    children: [
                      TextSpan(
                          text: getTranslated('personal_page', context) ??
                              'Trang cá nhân',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const TextSpan(text: ' · '),
                      TextSpan(
                          text: (user.about?.trim().isNotEmpty == true)
                              ? user.about!.trim()
                              : (getTranslated('content_creator', context) ??
                                  'Người sáng tạo nội dung')),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: onShowAbout,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.more_horiz, size: 20, color: theme.hintColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    getTranslated('view_about_info', context) ??
                        'Xem thông tin giới thiệu của bạn',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: cs.onSurface),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getTranslated('posts_title', context) ?? 'Bài viết',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: Text(
                  getTranslated('filter', context) ?? 'Bộ lọc',
                  style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isSelf)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: cs.surfaceVariant,
                  backgroundImage: (avatarUrl?.isNotEmpty == true)
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: (avatarUrl?.isEmpty ?? true)
                      ? Icon(Icons.person, color: cs.onSurface.withOpacity(.6))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const SocialCreatePostScreen(),
                        fullscreenDialog: true)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                          color: cs.surfaceVariant.withOpacity(.5),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        getTranslated('what_are_you_thinking', context) ??
                            'Bạn đang nghĩ gì?',
                        style: TextStyle(
                            color: cs.onSurface.withOpacity(.7), fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child:
                      Icon(Icons.image, size: 20, color: Colors.green.shade700),
                ),
              ],
            ),
          if (isSelf) const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ==============================
// GIỚI THIỆU TAB
// ==============================
class _ProfileAboutSection extends StatelessWidget {
  final SocialUserProfile user;
  const _ProfileAboutSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationText = [user.city, user.country]
        .where((s) => s?.isNotEmpty == true)
        .join(', ');
    final rows = <_AboutRowData>[];
    if (user.work?.isNotEmpty == true)
      rows.add(_AboutRowData(Icons.work_outline, user.work!));
    if (user.education?.isNotEmpty == true)
      rows.add(_AboutRowData(Icons.school_outlined, user.education!));
    if (locationText.isNotEmpty)
      rows.add(_AboutRowData(Icons.location_on_outlined, locationText));
    if (user.website?.isNotEmpty == true)
      rows.add(_AboutRowData(Icons.link, user.website!, isLink: true));
    if (user.genderText?.isNotEmpty == true)
      rows.add(_AboutRowData(Icons.wc_rounded, user.genderText!));
    if (user.birthday?.isNotEmpty == true)
      rows.add(_AboutRowData(Icons.cake_outlined, user.birthday!));
    if (user.relationshipStatus?.isNotEmpty == true)
      rows.add(_AboutRowData(Icons.favorite_border, user.relationshipStatus!));
    if (user.lastSeenText?.isNotEmpty == true)
      rows.add(_AboutRowData(Icons.schedule,
          '${getTranslated('active', context) ?? 'Hoạt động'} ${user.lastSeenText} trước'));

    final hasAnyInfo =
        (user.about?.trim().isNotEmpty == true) || rows.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(getTranslated('about', context) ?? 'Giới thiệu',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (user.about?.trim().isNotEmpty == true) ...[
          Text(user.about!.trim(),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: theme.textTheme.bodyMedium?.color)),
          const SizedBox(height: 16),
        ],
        if (!hasAnyInfo)
          Text(
              getTranslated('no_about_info', context) ??
                  'Chưa có thông tin giới thiệu.',
              style: TextStyle(fontSize: 14, color: theme.hintColor)),
        for (final r in rows) ...[
          _AboutInfoRow(data: r),
          const SizedBox(height: 12)
        ],
        if (hasAnyInfo) const SizedBox(height: 24),
      ],
    );
  }
}

class _AboutRowData {
  final IconData icon;
  final String text;
  final bool isLink;
  const _AboutRowData(this.icon, this.text, {this.isLink = false});
}

class _AboutInfoRow extends StatelessWidget {
  final _AboutRowData data;
  const _AboutInfoRow({required this.data});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: data.isLink ? Colors.blue : theme.textTheme.bodyMedium?.color,
      decoration: data.isLink ? TextDecoration.underline : TextDecoration.none,
      height: 1.3,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(data.icon, size: 20, color: theme.hintColor),
        const SizedBox(width: 10),
        Expanded(child: Text(data.text, style: textStyle)),
      ],
    );
  }
}

// ==============================
// DANH SÁCH BÀI VIẾT
// ==============================
class _ProfilePostsSection extends StatelessWidget {
  final SocialUserProfile user;
  final List<SocialPost> posts;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final VoidCallback onShowAbout;
  final bool isSelf;
  const _ProfilePostsSection({
    required this.user,
    required this.posts,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.onShowAbout,
    required this.isSelf,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          _ProfileDetailsBlock(
              user: user, onShowAbout: onShowAbout, isSelf: isSelf),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Text(
              getTranslated('no_posts_yet', context) ?? 'Chưa có bài viết nào',
              style: TextStyle(color: Theme.of(context).hintColor),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        _ProfileDetailsBlock(
            user: user, onShowAbout: onShowAbout, isSelf: isSelf),
        const SizedBox(height: 24),
        for (int i = 0; i < posts.length; i++) ...[
          // 1 bài viết – vẫn full bề ngang
          Container(
            color: Colors.white, // nền trắng của post
            child: SocialPostCard(post: posts[i]),
          ),

          // Dải xám ngăn giữa 2 bài (như hình bạn gửi)
          if (i != posts.length - 1)
            Container(
              height: 8, // độ dày dải xám
              color: const Color(0xFFF0F2F5), // màu nền xám nhạt kiểu Facebook
            ),
        ],
        const SizedBox(height: Dimensions.paddingSizeDefault),
        if (isLoadingMore)
          const Center(child: CircularProgressIndicator())
        else
          Center(
            child: TextButton(
              onPressed: onLoadMore,
              child: Text(
                getTranslated('load_more', context) ?? 'Tải thêm',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}

// ==============================
// NÚT MORE
// ==============================
class _MoreCircleButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _MoreCircleButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: theme.dividerColor, width: 1.2),
      ),
      child: IconButton(
          onPressed: onPressed, icon: const Icon(Icons.more_horiz, size: 22)),
    );
  }
}

// ==============================
// MENU CHO NGƯỜI KHÁC
// ==============================
void _showOtherProfileMenu(BuildContext context, SocialUserProfile user) {
  final theme = Theme.of(context);
  final sc = context.read<SocialController>();
  final bool isBlocked = sc.profileHeaderUser?.isBlocked ?? user.isBlocked;

  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true, // ✅ cho phép sheet cao & cuộn
    backgroundColor: Colors.transparent,
    builder: (_) {
      final media = MediaQuery.of(context);

      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 2,
            right: 2,
            bottom: media.viewInsets.bottom + 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ phần menu chính được bọc Flexible để nếu cao quá sẽ co lại + scroll
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.dividerColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        ListTile(
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundImage:
                            (user.avatarUrl?.isNotEmpty ?? false)
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            child: (user.avatarUrl?.isEmpty ?? true)
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(
                            user.displayName?.isNotEmpty == true
                                ? user.displayName!
                                : (user.userName ??
                                getTranslated('user', context) ??
                                'Người dùng'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text('@${user.userName ?? user.id}'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.flag_outlined,
                            color: Colors.red,
                          ),
                          title: Text(
                            getTranslated('report', context) ?? 'Báo cáo',
                          ),
                          subtitle: Text(
                            getTranslated('report_this_profile', context) ??
                                'Báo cáo trang cá nhân này',
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Future.microtask(
                                  () => _showReportUserDialog(
                                context,
                                targetUserId: user.id,
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading:
                          const Icon(Icons.block, color: Colors.red),
                          title: Text(
                            isBlocked
                                ? (getTranslated('unblock', context) ??
                                'Bỏ chặn')
                                : (getTranslated('block', context) ??
                                'Chặn'),
                          ),
                          subtitle: Text(
                            isBlocked
                                ? (getTranslated(
                                'allow_interaction', context) ??
                                'Cho phép xem & tương tác lại')
                                : (getTranslated(
                                'block_interaction', context) ??
                                'Không thấy nội dung và tương tác'),
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            await _confirmBlock(
                              context,
                              user,
                              unblock: isBlocked,
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.share_outlined),
                          title: Text(
                            getTranslated('share_profile', context) ??
                                'Chia sẻ trang cá nhân',
                          ),
                          onTap: () => Navigator.pop(context),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.touch_app_rounded),
                          title: Text(
                            getTranslated('poke', context) ?? 'Chọc',
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            await createPoke(context, user);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // nút Cancel luôn thấy được ở dưới
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  title: Center(
                    child: Text(
                      getTranslated('cancel', context) ?? 'Hủy',
                    ),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _confirmBlock(BuildContext context, SocialUserProfile user,
    {bool unblock = false}) async {
  final theme = Theme.of(context);
  final sc = context.read<SocialController>();
  final title = unblock
      ? (getTranslated('unblock_confirm', context) ?? 'Bỏ chặn người dùng?')
      : (getTranslated('block_confirm', context) ?? 'Chặn người dùng?');
  final content = unblock
      ? '${getTranslated('unblock_message', context) ?? 'Bạn có chắc muốn bỏ chặn'} ${user.displayName ?? user.userName ?? 'người này'}?'
      : '${getTranslated('block_message', context) ?? 'Bạn có chắc muốn chặn'} ${user.displayName ?? user.userName ?? 'người này'}?\n${getTranslated('block_effect', context) ?? 'Sau khi chặn, hai bên sẽ không nhìn thấy hoặc tương tác với nhau.'}';
  final actionText = unblock
      ? (getTranslated('unblock', context) ?? 'Bỏ chặn')
      : (getTranslated('block', context) ?? 'Chặn');

  final shouldProceed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(getTranslated('cancel', context) ?? 'Hủy')),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, true),
          child: Text(actionText),
        ),
      ],
    ),
  );

  if (shouldProceed != true) return;
  try {
    await sc.toggleBlockUser(targetUserId: user.id, block: !unblock);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(unblock
            ? (getTranslated('unblocked', context) ?? 'Đã bỏ chặn')
            : (getTranslated('blocked', context) ?? 'Đã chặn'))));
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(e.toString())));
  }
}

// ==============================
// MENU CÁ NHÂN
// ==============================
void _showSelfProfileMenu(BuildContext context, SocialUserProfile user) {
  final theme = Theme.of(context);
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: false,
    backgroundColor: Colors.transparent,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6))
                  ]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: theme.dividerColor,
                              borderRadius: BorderRadius.circular(2)))),
                  ListTile(
                    leading: CircleAvatar(
                        radius: 20,
                        backgroundImage: (user.avatarUrl?.isNotEmpty ?? false)
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: (user.avatarUrl?.isEmpty ?? true)
                            ? const Icon(Icons.person)
                            : null),
                    title: Text(
                        user.displayName?.isNotEmpty == true
                            ? user.displayName!
                            : (user.userName ??
                                getTranslated('my_profile', context) ??
                                'Trang cá nhân của tôi'),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('@${user.userName ?? user.id}'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.block),
                    title: Text(getTranslated('blocked_list', context) ??
                        'Danh sách đã chặn'),
                    subtitle: Text(getTranslated('view_unblock', context) ??
                        'Xem và bỏ chặn người dùng'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _showBlockedUsersSheet(context);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.share_outlined),
                    title: Text(getTranslated('share_profile', context) ??
                        'Chia sẻ trang cá nhân'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _shareMyProfile(context, user);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.touch_app_rounded),
                    title: Text(getTranslated('who_poked_me', context) ??
                        'Ai chọc tôi thế?'),
                    onTap: () async {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PokesScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                  title: Center(
                      child: Text(getTranslated('cancel', context) ?? 'Hủy')),
                  onTap: () => Navigator.pop(context)),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _shareMyProfile(
    BuildContext context, SocialUserProfile user) async {
  final base = AppConstants.socialBaseUrl.replaceAll(RegExp(r'/$'), '');
  final path = (user.userName?.isNotEmpty ?? false)
      ? '/${user.userName}'
      : '/u/${user.id}';
  final url = '$base$path';
  await Clipboard.setData(ClipboardData(text: url));
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          '${getTranslated('copied_link', context) ?? 'Đã sao chép liên kết'}: $url')));
}

Future<void> createPoke(BuildContext context, SocialUserProfile user) async {
  final sc = context.read<SocialController>();
  final int userId = int.tryParse(user.id.toString()) ?? 0;
  if (userId == 0) {
    if (!context.mounted) return;
    return;
  }
  final ok = await sc.createPoke(userId);
  if (!context.mounted) return;
  if (ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã chọc ${user.displayName}')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bạn đã chọc người này rồi!')),
    );
  }
}

// ==============================
// DANH SÁCH CHẶN
// ==============================
Future<void> _showBlockedUsersSheet(BuildContext context) async {
  final sc = context.read<SocialController>();
  await sc.loadBlockedUsersIfEmpty();
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.92,
      child: MemberListBottomSheet(
          title: getTranslated('blocked_list', context) ?? 'Danh sách đã chặn',
          totalCount: sc.blockedUsers.length,
          pageLoader: (after) async {
            const pageSize = 30;
            final start = int.tryParse(after ?? '0') ?? 0;
            final List<SocialUser> all = sc.blockedUsers.toList();
            final pageUsers = all.skip(start).take(pageSize).toList();
            final next =
                (start + pageSize < all.length) ? '${start + pageSize}' : null;
            return MemberPage(users: pageUsers, nextCursor: next);
          },
          onUserTap: (u) async {
            final ok = await _confirmUnblockFromList(context, u);
            if (ok == true) {
              await sc.unblockFromList(u.id);

              // Đóng sheet hiện tại
              if (!context.mounted) return;
              Navigator.pop(context);

              // Chờ animation đóng (~200ms) để tránh “giựt”
              await Future.delayed(const Duration(milliseconds: 220));

              // Mở lại đúng sheet cũ với dữ liệu mới
              if (!context.mounted) return;
              _showBlockedUsersSheet(context);

              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Đã bỏ chặn')));
            }
          }),
    ),
  );
}

Future<bool?> _confirmUnblockFromList(BuildContext context, SocialUser u) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(
          getTranslated('unblock_confirm', context) ?? 'Bỏ chặn người dùng?'),
      content: Text(
          '${getTranslated('unblock_message', context) ?? 'Bạn có chắc muốn bỏ chặn'} ${u.displayName ?? u.userName ?? u.id}?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(getTranslated('cancel', context) ?? 'Hủy')),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, true),
          child: Text(getTranslated('unblock', context) ?? 'Bỏ chặn'),
        ),
      ],
    ),
  );
}

// ==============================
// BÁO CÁO
// ==============================
void _showReportUserDialog(BuildContext context, {String? targetUserId}) {
  final sc = context.read<SocialController>();
  final String? id = targetUserId ?? sc.profileHeaderUser?.id;
  if (id == null || id.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(getTranslated('report_error', context) ??
            'Không xác định người cần báo cáo')));
    return;
  }

  final textCtrl = TextEditingController();
  bool sending = false;

  showDialog(
    context: context,
    barrierDismissible: !sending,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final canSend = !sending && textCtrl.text.trim().isNotEmpty;
        return AlertDialog(
          title: Text(
              getTranslated('report_user', context) ?? 'Báo cáo người dùng'),
          content: TextField(
            controller: textCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: getTranslated('report_hint', context) ??
                  'Nhập lý do/ mô tả vi phạm...',
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          actions: [
            TextButton(
                onPressed: sending ? null : () => Navigator.pop(ctx),
                child: Text(getTranslated('cancel', context) ?? 'Hủy')),
            ElevatedButton(
              onPressed: canSend
                  ? () async {
                      setState(() => sending = true);
                      try {
                        final msg = await sc.service.reportUser(
                            targetUserId: id, text: textCtrl.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text((msg is String &&
                                      msg.trim().isNotEmpty)
                                  ? msg
                                  : (getTranslated('report_sent', context) ??
                                      'Đã gửi báo cáo'))));
                        }
                      } catch (e) {
                        setState(() => sending = false);
                        if (context.mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())));
                      }
                    }
                  : null,
              child: sending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      getTranslated('send_report', context) ?? 'Gửi báo cáo'),
            ),
          ],
        );
      },
    ),
  );
}

// ==============================
// ẢNH
// ==============================
class _ProfilePhotosSection extends StatefulWidget {
  final String? targetUserId;
  const _ProfilePhotosSection({this.targetUserId});
  @override
  State<_ProfilePhotosSection> createState() => _ProfilePhotosSectionState();
}

class _ProfilePhotosSectionState extends State<_ProfilePhotosSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sc = context.read<SocialController>();
      _kickoffInitialLoad();
      if (sc.profilePhotos.isEmpty && !sc.isLoadingProfilePhotos) {
        sc.refreshProfilePhotos(targetUserId: widget.targetUserId);
      }
    });
  }

  Future<void> _kickoffInitialLoad() async {
    final sc = context.read<SocialController>();
    final id = widget.targetUserId;

    // 1) Load hồ sơ theo id (null => hồ sơ của mình)
    await sc.loadUserProfile(targetUserId: id, force: true);

    // 2) Load ảnh hồ sơ (giữ đoạn bạn đang làm, nhưng gộp về đây cho rõ ràng)
    if (sc.profilePhotos.isEmpty && !sc.isLoadingProfilePhotos) {
      await sc.refreshProfilePhotos(targetUserId: id);
    }

    // (tuỳ bạn) nếu có feed/bài viết/followers… thì gọi tiếp tại đây
    // await sc.loadProfilePosts(targetUserId: id, force: true);
    // await sc.refreshFollowers(targetUserId: id);
  }

  @override
  void didUpdateWidget(covariant _ProfilePhotosSection oldWidget) {
    // <= sửa đúng chữ ký widget
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetUserId != widget.targetUserId) {
      _reloadForNewUserId();
    }
  }

  Future<void> _reloadForNewUserId() async {
    final sc = context.read<SocialController>();
    final id = widget.targetUserId;

    // (tuỳ chọn) nếu controller có hàm dọn state, gọi để tránh nháy dữ liệu cũ
    // sc.resetProfileState();

    await sc.loadUserProfile(targetUserId: id, force: true);
    await sc.refreshProfilePhotos(targetUserId: id);
    if (mounted) setState(() {}); // cập nhật UI nếu cần
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SocialController>(
      builder: (context, sc, _) {
        final photos = sc.profilePhotos;
        final loading = sc.isLoadingProfilePhotos;
        if (loading && photos.isEmpty) {
          return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()));
        }
        if (photos.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
                child: Text(
                    getTranslated('no_photos', context) ?? 'Chưa có ảnh',
                    style: TextStyle(color: Theme.of(context).hintColor))),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                itemCount: photos.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1,
                ),
                itemBuilder: (_, i) {
                  final p = photos[i];
                  final thumb = p.thumbUrl ?? p.fullUrl;
                  final full = p.fullUrl ?? p.thumbUrl;
                  if (full == null && thumb == null) {
                    return const ColoredBox(
                        color: Color(0x11000000),
                        child: Center(child: Icon(Icons.broken_image)));
                  }
                  final heroTag = (full ?? thumb)!;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: GestureDetector(
                      onTap: () {
                        final urls = photos
                            .map((e) => e.fullUrl ?? e.thumbUrl)
                            .whereType<String>()
                            .toList();
                        final tapped = full ?? thumb;
                        final initialIndex =
                            tapped == null ? i : urls.indexOf(tapped);
                        final safeIndex = initialIndex < 0 ? 0 : initialIndex;
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => FullscreenGalleryLite(
                              urls: urls,
                              initialIndex: safeIndex,
                              heroTags: urls),
                        ));
                      },
                      child: Hero(
                        tag: heroTag,
                        child: Image.network(
                          thumb ?? full!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                              color: Color(0x11000000),
                              child: Center(child: Icon(Icons.broken_image))),
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                                  ? child
                                  : const ColoredBox(
                                      color: Color(0x11000000),
                                      child: Center(
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            if (sc.hasMoreProfilePhotos)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Center(
                  child: TextButton(
                    onPressed: () => sc.loadMoreProfilePhotos(
                        targetUserId: widget.targetUserId),
                    child:
                        Text(getTranslated('load_more', context) ?? 'Tải thêm'),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ==============================
// REELS
// ==============================
class _ProfileReelsSection extends StatefulWidget {
  final String? targetUserId;
  const _ProfileReelsSection({this.targetUserId});
  @override
  State<_ProfileReelsSection> createState() => _ProfileReelsSectionState();
}

class _ProfileReelsSectionState extends State<_ProfileReelsSection> {
  final Map<String, Future<Uint8List?>> _thumbFutureCache = {};

  Future<Uint8List?> _genThumb(String videoUrl) {
    return VideoThumbnail.thumbnailData(
      video: videoUrl,
      imageFormat: ImageFormat.JPEG,
      timeMs: 0,
      maxHeight: 480,
      quality: 75,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sc = context.read<SocialController>();
      final viewedId =
          widget.targetUserId ?? sc.profileHeaderUser?.id ?? sc.currentUser?.id;
      if ((sc.profileReels.isEmpty || sc.reelsForUserId != viewedId) &&
          !sc.isLoadingProfileReels) {
        await sc.refreshProfileReels(targetUserId: viewedId, limit: 20);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SocialController>(
      builder: (context, sc, _) {
        final reels = sc.profileReels;
        final loading = sc.isLoadingProfileReels;
        if (loading && reels.isEmpty) {
          return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()));
        }
        if (reels.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
                child: Text(
                    getTranslated('no_videos', context) ?? 'Chưa có video',
                    style: TextStyle(color: Theme.of(context).hintColor))),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                itemCount: reels.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 9 / 16,
                ),
                itemBuilder: (_, i) {
                  final r = reels[i];
                  Widget preview;
                  if (r.thumbUrl != null && r.thumbUrl!.isNotEmpty) {
                    preview = Image.network(
                      r.thumbUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                          color: Color(0x11000000),
                          child: Center(child: Icon(Icons.broken_image))),
                      loadingBuilder: (c, child, p) => p == null
                          ? child
                          : const ColoredBox(
                              color: Color(0x11000000),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))),
                    );
                  } else if (r.videoUrl != null && r.videoUrl!.isNotEmpty) {
                    final fut = _thumbFutureCache.putIfAbsent(
                        r.videoUrl!, () => _genThumb(r.videoUrl!));
                    preview = FutureBuilder<Uint8List?>(
                      future: fut,
                      builder: (_, snap) {
                        if (snap.hasData && snap.data != null)
                          return Image.memory(snap.data!, fit: BoxFit.cover);
                        if (snap.hasError)
                          return const ColoredBox(
                              color: Color(0x11000000),
                              child: Center(child: Icon(Icons.videocam_off)));
                        return const ColoredBox(
                            color: Color(0x11000000),
                            child: Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)));
                      },
                    );
                  } else {
                    preview = const ColoredBox(
                        color: Color(0x11000000),
                        child: Center(child: Icon(Icons.videocam_off)));
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => _ReelPlayerScreen(reel: r))),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          preview,
                          const Align(
                              alignment: Alignment.center,
                              child: Icon(Icons.play_circle_outline,
                                  size: 36, color: Colors.white)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            if (sc.hasMoreProfileReels)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Center(
                  child: TextButton(
                    onPressed: () => sc.loadMoreProfileReels(
                        targetUserId: widget.targetUserId, limit: 20),
                    child:
                        Text(getTranslated('load_more', context) ?? 'Tải thêm'),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ==============================
// GALLERY
// ==============================
class FullscreenGalleryLite extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  final List<String>? heroTags;
  const FullscreenGalleryLite(
      {super.key, required this.urls, this.initialIndex = 0, this.heroTags});
  @override
  State<FullscreenGalleryLite> createState() => _FullscreenGalleryLiteState();
}

class _FullscreenGalleryLiteState extends State<FullscreenGalleryLite>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late int _index;
  final _controllers = <int, TransformationController>{};
  late final AnimationController _anim;
  Animation<Matrix4>? _matrixTween;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.urls.length - 1);
    _pageController = PageController(initialPage: _index);
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180))
      ..addListener(() {
        final c = _controllers[_index];
        if (c != null && _matrixTween != null) c.value = _matrixTween!.value;
      });
  }

  @override
  void dispose() {
    _anim.dispose();
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  bool _isZoomed(int i) =>
      _controllers[i] != null && !_controllers[i]!.value.isIdentity();

  void _toggleZoom() {
    final c = _controllers[_index] ??= TransformationController();
    final isZoomed = !c.value.isIdentity();
    final end = isZoomed ? Matrix4.identity() : Matrix4.identity()
      ..scale(2.2);
    _matrixTween = Matrix4Tween(begin: c.value, end: end)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final physics = _isZoomed(_index)
        ? const NeverScrollableScrollPhysics()
        : const PageScrollPhysics();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: physics,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: widget.urls.length,
            itemBuilder: (ctx, i) {
              final tag =
                  (widget.heroTags != null && i < widget.heroTags!.length)
                      ? widget.heroTags![i]
                      : widget.urls[i];
              final controller = _controllers[i] ??= TransformationController();
              return Center(
                child: Hero(
                  tag: tag,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onDoubleTap: _toggleZoom,
                    child: InteractiveViewer(
                      transformationController: controller,
                      minScale: 1,
                      maxScale: 3.5,
                      panEnabled: true,
                      scaleEnabled: true,
                      onInteractionEnd: (_) => setState(() {}),
                      child: Image.network(
                        widget.urls[i],
                        fit: BoxFit.contain,
                        loadingBuilder: (c, child, p) => p == null
                            ? child
                            : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image,
                            color: Colors.white,
                            size: 48),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filled(
                  style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('${_index + 1}/${widget.urls.length}',
                      style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================
// REEL PLAYER
// ==============================
class _ReelPlayerScreen extends StatefulWidget {
  final SocialReel reel;
  const _ReelPlayerScreen({required this.reel});
  @override
  State<_ReelPlayerScreen> createState() => _ReelPlayerScreenState();
}

class _ReelPlayerScreenState extends State<_ReelPlayerScreen> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final url = widget.reel.videoUrl;
    if (url != null && url.isNotEmpty) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() => _ready = true);
          _controller!.setLooping(true);
          _controller!.play();
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aspect = (_controller?.value.aspectRatio ?? 0) == 0
        ? (9 / 16)
        : _controller!.value.aspectRatio;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _ready && _controller != null
                ? AspectRatio(
                    aspectRatio: aspect, child: VideoPlayer(_controller!))
                : const CircularProgressIndicator(),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton.filled(
              style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
        ],
      ),
    );
  }
}
