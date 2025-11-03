import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_repository_ext.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/edit_profile_screen.dart';


import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user_profile.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_screen.dart'
    show SocialPostCard;

// tạo bài viết / tạo story
import 'package:flutter_sixvalley_ecommerce/features/social/screens/create_post_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/create_story_screen.dart';

// ví
import 'package:flutter_sixvalley_ecommerce/features/social/screens/wallet_screen.dart';

/// Tab hiện tại
enum _ProfileTab { posts, about }

class ProfileScreen extends StatefulWidget {
  final String? targetUserId;
  const ProfileScreen({super.key, this.targetUserId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // load profile đúng user được bấm
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<SocialController>()
          .loadUserProfile(targetUserId: widget.targetUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // truyền targetUserId xuống body
        child: _ProfileBody(
          targetUserId: widget.targetUserId,
        ),
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
    setState(() {
      _currentTab = _ProfileTab.about;
    });
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

        final followers = sc.followers;
        final posts = sc.profilePosts;

        // xác định có phải đang xem profile của chính mình không
        final myId = sc.currentUser?.id;
        final bool isSelf = (widget.targetUserId == null ||
            widget.targetUserId!.isEmpty ||
            widget.targetUserId == myId);

        if (loadingProfile && headerUser == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            slivers: [
              _ProfileAppBar(user: safeHeaderUser),

              // HEADER (cover, avatar, stats, nút hành động tùy isSelf, tab bar)
              SliverToBoxAdapter(
                child: _ProfileHeaderSection(
                  user: safeHeaderUser,
                  recentFollowers: followers,
                  currentTab: _currentTab,
                  onTabSelected: (_ProfileTab tab) {
                    setState(() {
                      _currentTab = tab;
                    });
                  },
                  isSelf: isSelf,
                ),
              ),

              // NỘI DUNG THEO TAB
              if (_currentTab == _ProfileTab.posts)
                SliverToBoxAdapter(
                  child: _ProfilePostsSection(
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
                    isSelf: isSelf, // <-- truyền xuống để ẩn composer nếu không phải mình
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: _ProfileAboutSection(
                    user: safeHeaderUser,
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: Dimensions.paddingSizeExtraLarge),
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
    final hasLast  = user.lastName?.trim().isNotEmpty == true;
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
    final isDark = theme.brightness == Brightness.dark;

    // tên hiển thị to
    final fullName = (() {
      if (user.displayName?.trim().isNotEmpty == true) {
        return user.displayName!.trim();
      }
      final byFirstLast =
      '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
      if (byFirstLast.isNotEmpty == true) {
        return byFirstLast;
      }
      return user.userName ?? 'Người dùng';
    })();

    final followerText = _formatCount(user.followersCount);
    final followingText = _formatCount(user.followingCount);
    final statsText =
        '$followerText người theo dõi • $followingText đang theo dõi';

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
                    child: const Center(child: CircularProgressIndicator()),
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: user.avatarUrl?.isNotEmpty == true
                          ? Image.network(
                        user.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _AvatarFallback(),
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

        // ===== NAME + VERIFIED BADGE =====
        // ===== NAME (HỌ + TÊN) + VERIFIED BADGE =====
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  // Họ + Tên nếu có, ngược lại dùng username
                  (() {
                    final hasFirst = user.firstName?.trim().isNotEmpty == true;
                    final hasLast  = user.lastName?.trim().isNotEmpty == true;
                    if (hasFirst || hasLast) {
                      return '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
                    }
                    return user.userName ?? 'Người dùng';
                  })(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
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

// ===== USERNAME NHỎ BÊN DƯỚI (chỉ hiện khi có HỌ + TÊN) =====
        Builder(
          builder: (_) {
            final hasFirst = user.firstName?.trim().isNotEmpty == true;
            final hasLast  = user.lastName?.trim().isNotEmpty == true;
            final hasFullName = hasFirst || hasLast;
            final handle = (user.userName?.trim().isNotEmpty == true)
                ? (user.userName!.startsWith('@') ? user.userName! : '@${user.userName!}')
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

        // follower/following text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            statsText,
            style: TextStyle(
              fontSize: 14,
              color: theme.hintColor,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // FOLLOWERS STACK
        if (recentFollowers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _CompactFollowersRow(
              followers: recentFollowers.take(6).toList(),
            ),
          ),

        const SizedBox(height: 20),

        // ===== ACTION BUTTONS =====
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              if (isSelf) ...[
                // =========== TRANG CỦA CHÍNH MÌNH ===========

                // Hàng 1: Công cụ chuyên nghiệp + Thêm vào tin
                Row(
                  children: [
                    // Công cụ chuyên nghiệp
                    Expanded(
                      flex: 3,
                      child: FilledButton.icon(
                        onPressed: () {
                          // TODO: mở công cụ chuyên nghiệp
                        },
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
                            vertical: 16,
                            horizontal: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // + Thêm vào tin
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
                            vertical: 16,
                            horizontal: 10,
                          ),
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

                // Hàng 2: Chỉnh sửa trang cá nhân (thay vì Quảng cáo)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // mở màn hình Edit Profile
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EditProfileScreen(
                                profile: user,
                                onSave: (updatedProfile) {
                                  // sau khi lưu xong, cập nhật controller
                                  // hàm updateProfile() là ví dụ, bạn có thể đổi theo SocialController của bạn
                                  // context
                                  //     .read<SocialController>()
                                  //     .updateProfile(updatedProfile);
                                },
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
                            vertical: 14,
                            horizontal: 12,
                          ),
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
                  ],
                ),
              ] else ...[
                // =========== TRANG CỦA NGƯỜI KHÁC ===========

                // =========== TRANG CỦA NGƯỜI KHÁC ===========
                Row(
                  children: [
                    // THEO DÕI / ĐANG THEO DÕI
                    Expanded(
                      flex: 3,
                      child: Consumer<SocialController>(
                        builder: (context, sc, __) {
                          final bool busy = sc.isFollowBusy(user.id);
                          // lấy trạng thái follow mới nhất (controller sẽ cập nhật profileHeaderUser)
                          final bool following =
                          sc.profileHeaderUser?.id == user.id
                              ? (sc.profileHeaderUser?.isFollowing ?? user.isFollowing)
                              : user.isFollowing;

                          return FilledButton.icon(
                            onPressed: busy
                                ? null
                                : () async {
                              // gọi toggle trong controller: sẽ khóa nút, gọi API và cập nhật header
                              await context
                                  .read<SocialController>()
                                  .toggleFollowUser();
                            },
                            icon: busy
                                ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : Icon(following ? Icons.check : Icons.person_add_alt_1, size: 18),
                            label: Text(
                              following ? 'Đang theo dõi' : 'Theo dõi',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
                          // Lấy access token từ SharedPreferences
                          final sp = await SharedPreferences.getInstance();
                          final token = sp.getString(AppConstants.socialAccessToken);

                          if (token == null || token.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bạn chưa đăng nhập MXH')),
                            );
                            return;
                          }

                          // Điều hướng sang ChatScreen với đúng người nhận
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                peerUserId : user.id, // đảm bảo là String, nếu int: user.id.toString()
                                accessToken: token,
                                peerName      : user.displayName ?? user.userName ?? 'Đoạn chat',
                                peerAvatar     : user.avatarUrl,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text(
                          'Nhắn tin',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          side: BorderSide(color: Theme.of(context).dividerColor, width: 1.2),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),
                    const _MoreCircleButton(),
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
                active: false,
                onTap: () {
                  onTabSelected(_ProfileTab.posts);
                },
              ),
              _SimpleTab(
                label: 'Xem thêm',
                hasDropdown: true,
                active: false,
                onTap: () {
                  // TODO menu khác
                },
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

  String _formatCount(int count) {
    if (count >= 1000) {
      final k = count / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}K';
    }
    return count.toString();
  }
}

// Nút tròn dấu "…"
class _MoreCircleButton extends StatelessWidget {
  const _MoreCircleButton();

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
        onPressed: () {
          // TODO: mở menu report/block...
        },
        icon: const Icon(Icons.more_horiz, size: 22),
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
// BLOCK "CHI TIẾT" + "BÀI VIẾT"
// (đầu tab Bài viết)
// ==============================
class _ProfileDetailsBlock extends StatelessWidget {
  final SocialUserProfile user;
  final VoidCallback onShowAbout;
  final bool isSelf; // <-- thêm cờ này để biết có hiện ô "Bạn đang nghĩ gì?" không

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
                Icon(
                  Icons.more_horiz,
                  size: 20,
                  color: theme.hintColor,
                ),
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
                      ? Icon(
                    Icons.person,
                    color: cs.onSurface.withOpacity(.6),
                  )
                      : null,
                ),
                const SizedBox(width: 12),

                // input giả
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      // mở SocialCreatePostScreen
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
      rows.add(
        _AboutRowData(Icons.location_on_outlined, locationText),
      );
    }
    if (user.website?.isNotEmpty == true) {
      rows.add(
        _AboutRowData(Icons.link, user.website!, isLink: true),
      );
    }
    if (user.genderText?.isNotEmpty == true) {
      rows.add(
        _AboutRowData(Icons.wc_rounded, user.genderText!),
      );
    }
    if (user.birthday?.isNotEmpty == true) {
      rows.add(
        _AboutRowData(Icons.cake_outlined, user.birthday!),
      );
    }
    if (user.relationshipStatus?.isNotEmpty == true) {
      rows.add(
        _AboutRowData(
          Icons.favorite_border,
          user.relationshipStatus!,
        ),
      );
    }
    if (user.lastSeenText?.isNotEmpty == true) {
      rows.add(
        _AboutRowData(
          Icons.schedule,
          'Hoạt động ${user.lastSeenText} trước',
        ),
      );
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
        Icon(
          data.icon,
          size: 20,
          color: theme.hintColor,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            data.text,
            style: textStyle,
          ),
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
  final bool isSelf; // <-- thêm cờ này

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
    // Nếu chưa có bài viết -> vẫn show block Chi tiết (và composer chỉ nếu isSelf)
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
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
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
