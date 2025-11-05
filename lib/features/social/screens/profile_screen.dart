// lib/features/social/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:flutter/services.dart'; // Clipboard

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

import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_screen.dart'
    show SocialPostCard;

// NEW: sheet component (đã tạo file riêng)
import 'package:flutter_sixvalley_ecommerce/features/social/screens/member_list_bottom_sheet.dart';

// ví
import 'package:flutter_sixvalley_ecommerce/features/social/screens/wallet_screen.dart';

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
  final bool showDropdown; // nếu vẫn muốn mũi tên nhỏ

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
            color: theme.colorScheme.primary.withOpacity(0.6),
            width: 1.2,
          )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ImageIcon(
              image, // AssetImage / NetworkImage đều được
              size: 18,
              color: active ? theme.colorScheme.primary : theme.hintColor,
            ),
            if (showDropdown) const SizedBox(width: 4),
            if (showDropdown)
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: active ? theme.colorScheme.primary : theme.hintColor,
              ),
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
    // load profile đúng user được bấm
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialController>().loadUserProfile(
        targetUserId: widget.targetUserId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // truyền targetUserId xuống body
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
  // tab mặc định là "Bài viết"
  _ProfileTab _currentTab = _ProfileTab.posts;

  Future<void> _handleRefresh() async {
    final sc = context.read<SocialController>();
    await sc.loadUserProfile(targetUserId: widget.targetUserId);
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

        // Lấy list followers để hiển thị hàng avatar nhỏ + mở sheet
        final recentFollowers = sc.followers.toList();
        final posts = sc.profilePosts;

        // xác định có phải đang xem profile của chính mình không
        final myId = sc.currentUser?.id;
        final bool isSelf = (widget.targetUserId == null ||
            widget.targetUserId!.isEmpty ||
            widget.targetUserId == myId);

        // === Chọn nội dung theo tab (dưới dạng RenderBox) ===
        Widget tabContent;
        switch (_currentTab) {
          case _ProfileTab.about:
            tabContent = _ProfileAboutSection(user: safeHeaderUser);
            break;
          case _ProfileTab.photos:
            tabContent = _ProfilePhotosSection(
              targetUserId: widget.targetUserId,
            );
            break;
          case _ProfileTab.reels:
          case _ProfileTab.posts:
          default:
            tabContent = _ProfilePostsSection(
              user: safeHeaderUser,
              posts: posts,
              isLoadingMore: loadingPosts,
              onLoadMore: () {
                sc.loadMoreProfilePosts(
                  targetUserId: widget.targetUserId,
                  limit: 10,
                );
              },
              onShowAbout: _switchToAbout,
              isSelf: isSelf,
            );
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _ProfileAppBar(user: safeHeaderUser),

              // HEADER (cover, avatar, stats, nút hành động tùy isSelf, tab bar)
              SliverToBoxAdapter(
                child: _ProfileHeaderSection(
                  user: safeHeaderUser,
                  recentFollowers: recentFollowers,
                  currentTab: _currentTab,
                  onTabSelected: (_ProfileTab tab) {
                    setState(() => _currentTab = tab);
                  },
                  isSelf: isSelf,
                ),
              ),

              // NỘI DUNG THEO TAB
              SliverToBoxAdapter(child: tabContent),

              // khoảng đệm dưới cùng
              const SliverToBoxAdapter(
                child: SizedBox(height: Dimensions.paddingSizeExtraLarge),
              ),

              // Nếu muốn hiển thị shimmer/skeleton khi chưa có dữ liệu cơ bản
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

    // Ưu tiên họ + tên; nếu thiếu cả hai thì dùng username
    final hasFirst = user.firstName?.trim().isNotEmpty == true;
    final hasLast = user.lastName?.trim().isNotEmpty == true;
    final hasFullName = hasFirst || hasLast;

    final primaryTitle = hasFullName
        ? '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim()
        : (user.userName ?? 'Profile');

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
      actions: const [
        // tuỳ ý
      ],
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

    // Tên hiển thị lớn
    final fullName = (() {
      final first = (user.firstName ?? '').trim();
      final last = (user.lastName ?? '').trim();
      final firstLast =
      [first, last].where((s) => s.isNotEmpty).join(' ').trim();

      // Ưu tiên first + last; nếu cả hai đều trống thì fallback sang displayName, rồi userName
      if (firstLast.isNotEmpty) return firstLast;
      if (user.displayName?.trim().isNotEmpty == true) {
        return user.displayName!.trim();
      }
      return user.userName ?? 'Người dùng';
    })();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // === COVER + AVATAR ===
        SizedBox(
          height: 180,
          child: Stack(
            children: [
              // Cover
              Positioned.fill(
                child: user.coverUrl?.isNotEmpty == true
                    ? Image.network(
                  user.coverUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) =>
                  progress == null
                      ? child
                      : Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                        child: CircularProgressIndicator()),
                  ),
                  errorBuilder: (_, __, ___) => _CoverFallback(),
                )
                    : _CoverFallback(),
              ),

              // === NÚT VÍ CÁ NHÂN (MỚI THÊM) ===
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WalletScreen()),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.blue,
                      size: 22,
                    ),
                  ),
                ),
              ),

              // Avatar
              Positioned(
                left: 16,
                bottom: 0,
                child: Transform.translate(
                  offset: const Offset(0, 50),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        )
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
              ),
            ],
          ),
        ),

        const SizedBox(height: 70),

        // ===== NAME (HỌ + TÊN) + VERIFIED BADGE =====
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
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, size: 20),
            ],
          ),
        ),

        // ===== USERNAME nhỏ bên dưới (chỉ hiện khi có HỌ + TÊN) =====
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
                    color: Theme.of(context).hintColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        const SizedBox(height: 4),

        // ===== DÒNG CHỮ FOLLOWERS/FOLLOWING (tap để mở sheet) =====
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              InkWell(
                onTap: () => _showFollowersSheet(context),
                child: Text(
                  '${_formatCount(user.followersCount)} người theo dõi',
                  style: TextStyle(fontSize: 14, color: theme.hintColor),
                ),
              ),
              Text('•', style: TextStyle(fontSize: 14, color: theme.hintColor)),
              InkWell(
                onTap: () => _showFollowingSheet(context),
                child: Text(
                  '${_formatCount(user.followingCount)} đang theo dõi',
                  style: TextStyle(fontSize: 14, color: theme.hintColor),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // FOLLOWERS STACK (nếu có) — tap mở sheet Followers
        if (recentFollowers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => _showFollowersSheet(context),
              child: _CompactFollowersRow(
                followers: recentFollowers.take(6).toList(),
              ),
            ),
          ),

        const SizedBox(height: 20),

        // ===== ACTION BUTTONS =====
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              if (isSelf) ...[
                // Hàng 1: Công cụ chuyên nghiệp + Thêm vào tin
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.work_outline, size: 18),
                        label: const Text(
                          'Công cụ chuyên nghiệp',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SocialCreateStoryScreen(),
                              fullscreenDialog: true,
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: BorderSide(
                            color: theme.dividerColor,
                            width: 1.2,
                          ),
                        ),
                        child: const Text(
                          '+ Thêm vào tin',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Hàng 2: Chỉnh sửa trang cá nhân
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EditProfileScreen(
                                profile: user,
                                onSave: (updatedProfile) {},
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text(
                          'Chỉnh sửa trang cá nhân',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: BorderSide(
                            color: theme.dividerColor,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _MoreCircleButton(
                      onPressed: () => _showSelfProfileMenu(context, user),
                    ),
                  ],
                ),
              ] else ...[
                // Trang của người khác
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
                                  strokeWidth: 2),
                            )
                                : Icon(
                              following
                                  ? Icons.check
                                  : Icons.person_add_alt_1,
                              size: 18,
                            ),
                            label: Text(
                              following ? 'Đang theo dõi' : 'Theo dõi',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 1,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // NHẮN TIN
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final sp = await SharedPreferences.getInstance();
                          final token =
                          sp.getString(AppConstants.socialAccessToken);
                          if (token == null || token.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bạn chưa đăng nhập MXH'),
                              ),
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
                                    'Đoạn chat',
                                peerAvatar: user.avatarUrl,
                              ),
                            ),
                          );
                        },
                        icon:
                        const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text(
                          'Nhắn tin',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _MoreCircleButton(
                      onPressed: () => _showOtherProfileMenu(context, user),
                    ),
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
                label: 'Bài viết',
                active: currentTab == _ProfileTab.posts,
                onTap: () => onTabSelected(_ProfileTab.posts),
              ),
              _SimpleTab(
                label: 'Giới thiệu',
                active: currentTab == _ProfileTab.about,
                onTap: () => onTabSelected(_ProfileTab.about),
              ),
              _SimpleTab(
                label: 'Reels',
                active: currentTab == _ProfileTab.reels,
                onTap: () => onTabSelected(_ProfileTab.reels),
              ),
              _SimpleTab(
                label: 'Ảnh',
                active: currentTab == _ProfileTab.photos,
                onTap: () => onTabSelected(_ProfileTab.photos),
              ),
            ],
          ),
        ),

        // Divider ngăn header với phần nội dung
        Divider(
          height: 1,
          thickness: 0.8,
          color: theme.dividerColor.withOpacity(0.5),
        ),
      ],
    );
  }

  // ===== Helpers =====
  String _formatCount(int count) {
    if (count >= 1000) {
      final k = count / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}K';
    }
    return count.toString();
  }

  // ===== OPEN SHEETS (MemberListBottomSheet) =====
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
          title: 'Người theo dõi',
          totalCount: sc.profileHeaderUser?.followersCount,
          // Phân trang từ list đã có trong controller
          pageLoader: (after) async {
            const pageSize = 30;
            final start = int.tryParse(after ?? '0') ?? 0;
            final List<SocialUser> all = sc.followers.toList();
            final pageUsers = all.skip(start).take(pageSize).toList();
            final next =
            (start + pageSize < all.length) ? '${start + pageSize}' : null;
            return MemberPage(users: pageUsers, nextCursor: next);
          },
          onUserTap: (u) {
            Navigator.of(context).pop();
            // Nếu muốn mở profile user đó:
            // Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileScreen(targetUserId: u.id)));
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
          title: 'Đang theo dõi',
          totalCount: sc.profileHeaderUser?.followingCount,
          // Phân trang từ list đã có trong controller
          pageLoader: (after) async {
            const pageSize = 30;
            final start = int.tryParse(after ?? '0') ?? 0;
            final List<SocialUser> all = sc.following.toList();
            final pageUsers = all.skip(start).take(pageSize).toList();
            final next =
            (start + pageSize < all.length) ? '${start + pageSize}' : null;
            return MemberPage(users: pageUsers, nextCursor: next);
          },
          onUserTap: (u) {
            Navigator.of(context).pop();
            // Nếu muốn mở profile user đó:
            // Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileScreen(targetUserId: u.id)));
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
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image,
        size: 60,
        color: Colors.white54,
      ),
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
      child: Icon(
        Icons.person,
        size: 36,
        color: theme.hintColor,
      ),
    );
  }
}

// ==============================
// FOLLOWERS ROW (hàng avatar chồng)
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
                      ? const Icon(Icons.person,
                      size: 16, color: Colors.grey)
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
                child: Text(
                  '+$remain',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
  final bool hasDropdown;
  final VoidCallback onTap;

  const _SimpleTab({
    required this.label,
    required this.onTap,
    this.active = false,
    this.hasDropdown = false,
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
            color: theme.colorScheme.primary.withOpacity(0.6),
            width: 1.2,
          )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
              ),
            ),
            if (hasDropdown) const SizedBox(width: 4),
            if (hasDropdown)
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: active
                    ? theme.colorScheme.primary
                    : theme.hintColor,
              ),
          ],
        ),
      ),
    );
  }
}

// ==============================
// BLOCK "CHI TIẾT" + "BÀI VIẾT" (đầu tab Bài viết)
// ==============================
class _ProfileDetailsBlock extends StatelessWidget {
  final SocialUserProfile user;
  final VoidCallback onShowAbout;
  final bool isSelf; // cờ để biết có hiện ô "Bạn đang nghĩ gì?" không

  const _ProfileDetailsBlock({
    required this.user,
    required this.onShowAbout,
    required this.isSelf,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final onSurface = cs.onSurface;

    final String? avatarUrl = user.avatarUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====== TIÊU ĐỀ "Chi tiết" ======
          const Text(
            'Chi tiết',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // ====== DÒNG 1: "Trang cá nhân · ..." ======
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ô vuông xám
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Trang cá nhân',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' · '),
                      TextSpan(
                        text: (user.about != null &&
                            user.about!.trim().isNotEmpty)
                            ? user.about!.trim()
                            : 'Người sáng tạo nội dung',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ====== DÒNG 2: "Xem thông tin giới thiệu..." ======
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
                    'Xem thông tin giới thiệu của bạn',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ====== HEADER "Bài viết" + nút Bộ lọc ======
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bài viết',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: bộ lọc
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Bộ lọc',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ====== Ô "Bạn đang nghĩ gì?" chỉ hiện NẾU là trang của chính mình ======
          if (isSelf) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: cs.surfaceVariant,
                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: (avatarUrl == null || avatarUrl.isEmpty)
                      ? Icon(Icons.person, color: cs.onSurface.withOpacity(.6))
                      : null,
                ),
                const SizedBox(width: 12),

                // input giả
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SocialCreatePostScreen(),
                          fullscreenDialog: true,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceVariant.withOpacity(.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Bạn đang nghĩ gì?',
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(.7),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // nút media nhỏ
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image,
                    size: 20,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

// ==============================
// GIỚI THIỆU TAB CONTENT
// ==============================
class _ProfileAboutSection extends StatelessWidget {
  final SocialUserProfile user;
  const _ProfileAboutSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final locationText = () {
      final parts = <String>[];
      if (user.city?.isNotEmpty == true) parts.add(user.city!);
      if (user.country?.isNotEmpty == true) parts.add(user.country!);
      return parts.join(', ');
    }();

    final rows = <_AboutRowData>[];

    if (user.work?.isNotEmpty == true) {
      rows.add(_AboutRowData(Icons.work_outline, user.work!));
    }
    if (user.education?.isNotEmpty == true) {
      rows.add(_AboutRowData(Icons.school_outlined, user.education!));
    }
    if (locationText.isNotEmpty) {
      rows.add(_AboutRowData(Icons.location_on_outlined, locationText));
    }
    if (user.website?.isNotEmpty == true) {
      rows.add(_AboutRowData(Icons.link, user.website!, isLink: true));
    }
    if (user.genderText?.isNotEmpty == true) {
      rows.add(_AboutRowData(Icons.wc_rounded, user.genderText!));
    }
    if (user.birthday?.isNotEmpty == true) {
      rows.add(_AboutRowData(Icons.cake_outlined, user.birthday!));
    }
    if (user.relationshipStatus?.isNotEmpty == true) {
      rows.add(
          _AboutRowData(Icons.favorite_border, user.relationshipStatus!));
    }
    if (user.lastSeenText?.isNotEmpty == true) {
      rows.add(_AboutRowData(
          Icons.schedule, 'Hoạt động ${user.lastSeenText} trước'));
    }

    final bool hasAnyInfo =
        (user.about?.trim().isNotEmpty == true) || rows.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          const Text(
            'Giới thiệu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          if (user.about?.trim().isNotEmpty == true) ...[
            Text(
              user.about!.trim(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (rows.isEmpty && user.about?.trim().isEmpty != false)
            Text(
              'Chưa có thông tin giới thiệu.',
              style: TextStyle(
                fontSize: 14,
                color: theme.hintColor,
              ),
            ),

          for (final r in rows) ...[
            _AboutInfoRow(data: r),
            const SizedBox(height: 12),
          ],

          if (hasAnyInfo) const SizedBox(height: 24),
        ],
      ),
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
      decoration:
      data.isLink ? TextDecoration.underline : TextDecoration.none,
      height: 1.3,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(data.icon, size: 20, color: theme.hintColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(data.text, style: textStyle),
        ),
      ],
    );
  }
}

// ==============================
// DANH SÁCH BÀI VIẾT (TAB "Bài viết")
// Có block "Chi tiết" + "Bài viết" ở đầu
// ==============================
class _ProfilePostsSection extends StatelessWidget {
  final SocialUserProfile user;
  final List<SocialPost> posts;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final VoidCallback onShowAbout;
  final bool isSelf; // ẩn/hiện composer

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
    // Nếu chưa có bài viết -> vẫn show block Chi tiết (và composer tùy isSelf)
    if (posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(
          bottom: Dimensions.paddingSizeDefault,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _ProfileDetailsBlock(
              user: user,
              onShowAbout: onShowAbout,
              isSelf: isSelf,
            ),
            const SizedBox(height: 24),
            Padding(
              padding:
              const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Text(
                getTranslated('no_posts_yet', context) ??
                    'Chưa có bài viết nào',
                style: TextStyle(color: Theme.of(context).hintColor),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    // Có bài viết -> block Chi tiết (composer tùy isSelf), rồi danh sách post
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _ProfileDetailsBlock(
            user: user,
            onShowAbout: onShowAbout,
            isSelf: isSelf,
          ),
          const SizedBox(height: 24),

          for (int i = 0; i < posts.length; i++) ...[
            SocialPostCard(post: posts[i]),
            if (i != posts.length - 1)
              const SizedBox(height: Dimensions.paddingSizeSmall),
          ],

          const SizedBox(height: Dimensions.paddingSizeDefault),

          if (isLoadingMore)
            const Center(child: CircularProgressIndicator())
          else
            Center(
              child: TextButton(
                onPressed: onLoadMore,
                child: Text(
                  getTranslated('load_more_posts', context) ?? 'Tải thêm',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ==============================
// Nút tròn dấu "…"
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
        border: Border.all(
          color: theme.dividerColor,
          width: 1.2,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.more_horiz, size: 22),
      ),
    );
  }
}

void _showOtherProfileMenu(
    BuildContext context, SocialUserProfile user) {
  final theme = Theme.of(context);
  final sc = context.read<SocialController>();
  final bool isBlocked =
      sc.profileHeaderUser?.isBlocked ?? user.isBlocked;

  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: false,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Card chính của sheet
              Container(
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header: avatar + tên
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
                            : (user.userName ?? 'Người dùng'),
                        style:
                        const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle:
                      Text('@${user.userName ?? user.id}'),
                    ),
                    const Divider(height: 1),

                    // Báo cáo
                    ListTile(
                      leading: const Icon(Icons.flag_outlined, color: Colors.red),
                      title: const Text('Báo cáo'),
                      subtitle: const Text('Báo cáo trang cá nhân này'),
                      onTap: () {
                        Navigator.pop(context); // đóng sheet trước
                        // mở dialog báo cáo (lấy đúng targetId)
                        Future.microtask(() => _showReportUserDialog(context, targetUserId: user.id));
                      },
                    ),

                    const Divider(height: 1),

                    // Chặn / Bỏ chặn (động theo trạng thái)
                    ListTile(
                      leading:
                      const Icon(Icons.block, color: Colors.red),
                      title: Text(isBlocked ? 'Bỏ chặn' : 'Chặn'),
                      subtitle: Text(
                        isBlocked
                            ? 'Cho phép xem & tương tác lại'
                            : 'Không thấy nội dung và tương tác',
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await _confirmBlock(context, user,
                            unblock: isBlocked);
                      },
                    ),
                    const Divider(height: 1),

                    // Chia sẻ
                    ListTile(
                      leading:
                      const Icon(Icons.share_outlined),
                      title: const Text('Chia sẻ trang cá nhân'),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: mở share sheet / sao chép liên kết
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Nút Hủy
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  title: const Center(child: Text('Hủy')),
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

Future<void> _confirmBlock(
    BuildContext context,
    SocialUserProfile user, {
      bool unblock = false,
    }) async {
  final theme = Theme.of(context);
  final sc = context.read<SocialController>();

  final title = unblock ? 'Bỏ chặn người dùng?' : 'Chặn người dùng?';
  final content = unblock
      ? 'Bạn có chắc muốn bỏ chặn ${user.displayName ?? user.userName ?? 'người này'}?'
      : 'Bạn có chắc muốn chặn ${user.displayName ?? user.userName ?? 'người này'}?\nSau khi chặn, hai bên sẽ không nhìn thấy hoặc tương tác với nhau.';

  final actionText = unblock ? 'Bỏ chặn' : 'Chặn';

  final shouldProceed = await showDialog<bool>(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(actionText),
          ),
        ],
      );
    },
  );

  if (shouldProceed != true) return;

  try {
    // unblock=true => block=false; unblock=false => block=true
    await sc.toggleBlockUser(
      targetUserId: user.id,
      block: !unblock,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(unblock ? 'Đã bỏ chặn' : 'Đã chặn')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}

void _showSelfProfileMenu(
    BuildContext context, SocialUserProfile user) {
  final theme = Theme.of(context);

  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: false,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return SafeArea(
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
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header: avatar + tên
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
                            : (user.userName ?? 'Trang cá nhân của tôi'),
                        style:
                        const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle:
                      Text('@${user.userName ?? user.id}'),
                    ),
                    const Divider(height: 1),

                    // Danh sách đã chặn
                    ListTile(
                      leading: const Icon(Icons.block),
                      title: const Text('Danh sách đã chặn'),
                      subtitle:
                      const Text('Xem và bỏ chặn người dùng'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _showBlockedUsersSheet(context);
                      },
                    ),
                    const Divider(height: 1),

                    // Chia sẻ trang cá nhân
                    ListTile(
                      leading:
                      const Icon(Icons.share_outlined),
                      title: const Text('Chia sẻ trang cá nhân'),
                      onTap: () async {
                        Navigator.pop(context);
                        await _shareMyProfile(context, user);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Nút Hủy
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  title: const Center(child: Text('Hủy')),
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

Future<void> _shareMyProfile(
    BuildContext context, SocialUserProfile user) async {
  final base = AppConstants.socialBaseUrl
      .replaceAll(RegExp(r'/$'), '');
  // ưu tiên username, fallback sang id
  final path =
  (user.userName?.isNotEmpty ?? false) ? '/${user.userName}' : '/u/${user.id}';
  final url = '$base$path';

  await Clipboard.setData(ClipboardData(text: url));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Đã sao chép liên kết: $url')),
  );
}

// ==============================
// BỔ SUNG: SHEET "Danh sách đã chặn" + confirm dialog bỏ chặn
// ==============================
Future<void> _showBlockedUsersSheet(BuildContext context) async {
  final sc = context.read<SocialController>();

  // Tải nếu đang trống (yêu cầu bạn có sc.loadBlockedUsersIfEmpty())
  await sc.loadBlockedUsersIfEmpty();

  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.92,
      child: MemberListBottomSheet(
        title: 'Danh sách đã chặn',
        // Nếu API không trả total, dùng length hiện có
        totalCount: sc.blockedUsers.length,
        pageLoader: (after) async {
          const pageSize = 30;
          final start = int.tryParse(after ?? '0') ?? 0;
          final List<SocialUser> all = sc.blockedUsers.toList();
          final pageUsers = all.skip(start).take(pageSize).toList();
          final next = (start + pageSize < all.length)
              ? '${start + pageSize}'
              : null;
          return MemberPage(users: pageUsers, nextCursor: next);
        },
        onUserTap: (u) async {
          // Hỏi xác nhận
          final ok = await _confirmUnblockFromList(context, u);
          if (ok == true) {
            await sc.unblockFromList(u.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã bỏ chặn')),
            );
          }
        },
      ),
    ),
  );
}

Future<bool?> _confirmUnblockFromList(
    BuildContext context, SocialUser u) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Bỏ chặn người dùng?'),
      content: Text(
          'Bạn có chắc muốn bỏ chặn ${u.displayName ?? u.userName ?? u.id}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Bỏ chặn'),
        ),
      ],
    ),
  );
}

// === REPORT USER DIALOG ===
void _showReportUserDialog(BuildContext context, {String? targetUserId}) {
  final sc = context.read<SocialController>();
  final String? id = targetUserId ?? sc.profileHeaderUser?.id;

  if (id == null || id.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Không xác định người cần báo cáo')),
    );
    return;
  }

  final textCtrl = TextEditingController();
  bool sending = false;

  showDialog(
    context: context,
    barrierDismissible: !sending,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        final canSend = !sending && textCtrl.text.trim().isNotEmpty;
        return AlertDialog(
          title: const Text('Báo cáo người dùng'),
          content: TextField(
            controller: textCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Nhập lý do/ mô tả vi phạm...',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: canSend
                  ? () async {
                setState(() => sending = true);
                try {
                  // Gọi service qua controller (đã có trong Service/Repo)
                  final msg = await sc.service.reportUser(
                    targetUserId: id,
                    text: textCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          (msg is String && msg.trim().isNotEmpty)
                              ? msg
                              : 'Đã gửi báo cáo',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  setState(() => sending = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              }
                  : null,
              child: sending
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Gửi báo cáo'),
            ),
          ],
        );
      });
    },
  );
}

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
      // Chỉ nạp khi chưa có dữ liệu
      if (sc.profilePhotos.isEmpty && !sc.isLoadingProfilePhotos) {
        sc.refreshProfilePhotos(targetUserId: widget.targetUserId);
      }
    });
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
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (photos.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Chưa có ảnh',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ),
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
                  final full  = p.fullUrl ?? p.thumbUrl;

                  // Nếu không có URL hợp lệ thì render ô hỏng và không cho mở
                  if (full == null && thumb == null) {
                    return const ColoredBox(
                      color: Color(0x11000000),
                      child: Center(child: Icon(Icons.broken_image)),
                    );
                  }

                  // Dùng URL làm heroTag để khớp 1-1 giữa grid và viewer
                  final heroTag = (full ?? thumb)!;

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: GestureDetector(
                      onTap: () {
                        // Tạo danh sách URL ảnh full-size theo đúng thứ tự đang hiển thị
                        final urls = photos
                            .map((e) => e.fullUrl ?? e.thumbUrl)
                            .whereType<String>()
                            .toList();

                        // Xác định index ảnh được chạm tương ứng trong mảng urls
                        final tapped = full ?? thumb;
                        final initialIndex = tapped == null ? i : urls.indexOf(tapped);
                        final safeIndex = initialIndex < 0 ? 0 : initialIndex;

                        // heroTags dùng chính URLs để match Hero
                        final heroTags = urls;

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FullscreenGalleryLite(
                              urls: urls,
                              initialIndex: safeIndex,
                              heroTags: heroTags,
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag: heroTag,
                        child: Image.network(
                          // Ưu tiên thumb cho grid để tải nhanh
                          thumb ?? full!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Color(0x11000000),
                            child: Center(child: Icon(Icons.broken_image)),
                          ),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const ColoredBox(
                              color: Color(0x11000000),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          },
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
                      targetUserId: widget.targetUserId,
                    ),
                    child: const Text('Tải thêm'),
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
// FULLSCREEN GALLERY (thuần Flutter)
// ==============================
class FullscreenGalleryLite extends StatefulWidget {
  final List<String> urls;          // danh sách URL ảnh full-size
  final int initialIndex;           // mở tại ảnh thứ mấy
  final List<String>? heroTags;     // dùng để match Hero từ grid (nên trùng URL)

  const FullscreenGalleryLite({
    super.key,
    required this.urls,
    this.initialIndex = 0,
    this.heroTags,
  });

  @override
  State<FullscreenGalleryLite> createState() => _FullscreenGalleryLiteState();
}

class _FullscreenGalleryLiteState extends State<FullscreenGalleryLite>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late int _index;

  // Mỗi trang có một TransformationController để zoom/pan
  final _controllers = <int, TransformationController>{};

  // Double-tap zoom animation
  late final AnimationController _anim;
  Animation<Matrix4>? _matrixTween;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.urls.length - 1);
    _pageController = PageController(initialPage: _index);

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..addListener(() {
      final c = _controllers[_index];
      if (c != null && _matrixTween != null) c.value = _matrixTween!.value;
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isZoomed(int i) {
    final c = _controllers[i];
    return c != null && !c.value.isIdentity();
  }

  void _toggleZoom() {
    final c = _controllers[_index] ??= TransformationController();
    final isZoomed = !c.value.isIdentity();
    final end = isZoomed ? Matrix4.identity() : (Matrix4.identity()..scale(2.2));
    _matrixTween = Matrix4Tween(begin: c.value, end: end)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    // Nếu đang zoom ảnh hiện tại thì khoá vuốt PageView để không xung đột
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
              final tag = (widget.heroTags != null && i < (widget.heroTags!.length))
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
                        loadingBuilder: (c, child, p) =>
                        p == null ? child : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image, color: Colors.white, size: 48),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Top bar: nút đóng + chỉ số
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
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_index + 1}/${widget.urls.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
