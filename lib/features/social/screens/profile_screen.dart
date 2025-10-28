import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/logging_interceptor.dart';

import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';

// Controller/profile (ChangeNotifier)
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_profile_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_profile_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_profile_service.dart';

// Card bài viết (dùng trong feed)
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_screen.dart'
    show SocialPostCard;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<SharedPreferences> _prefsFuture;

  @override
  void initState() {
    super.initState();
    _prefsFuture = SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: _prefsFuture,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snap.hasData) {
          return const Scaffold(
            body: Center(
              child: Text('Lỗi: không lấy được SharedPreferences'),
            ),
          );
        }

        final sharedPrefs = snap.data!;

        // Tạo DioClient cho social API (có loggingInterceptor)
        final dio = Dio();
        final logging = LoggingInterceptor();
        final dioClient = DioClient(
          AppConstants.socialBaseUrl,
          dio,
          sharedPreferences: sharedPrefs,
          loggingInterceptor: logging,
        );

        return ChangeNotifierProvider<SocialProfileController>(
          create: (_) {
            final repo = SocialProfileRepository(
              dioClient: dioClient,
              sharedPreferences: sharedPrefs,
            );

            final service = SocialProfileService(
              socialRepository: repo,
            );

            final ctrl = SocialProfileController(service: service);
            ctrl.init(); // nạp user + followers + posts đầu tiên
            return ctrl;
          },
          child: const _ProfileBody(),
        );
      },
    );
  }
}

class _ProfileBody extends StatefulWidget {
  const _ProfileBody();

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
  Future<void> _handleRefresh() async {
    await context.read<SocialProfileController>().init();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SocialProfileController>(
      builder: (context, pc, _) {
        final bool loadingInit = pc.isLoadingInit;
        final bool loadingMore = pc.isLoadingMore;

        final SocialUser? user = pc.currentUser;
        final List<SocialUser> followers = pc.followers;
        final List<SocialUser> following = pc.following;
        final List<SocialPost> posts = pc.posts;

        if (loadingInit) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // user fallback để UI không crash
        final SocialUser safeUser = user ??
            const SocialUser(
              id: '0',
              displayName: 'Người dùng',
              firstName: null,
              lastName: null,
              userName: null,
              avatarUrl: null,
              coverUrl: null,
            );

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: CustomScrollView(
                slivers: [
                  _ProfileAppBar(user: safeUser),

                  SliverToBoxAdapter(
                    child: _ProfileHeaderSection(user: safeUser),
                  ),

                  SliverToBoxAdapter(
                    child: _ProfileStatsRow(
                      followers: followers,
                      following: following,
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: _FollowersPreviewSection(followers: followers),
                  ),

                  SliverToBoxAdapter(
                    child: _ProfilePostsSection(
                      posts: posts,
                      isLoadingMore: loadingMore,
                      onLoadMore: () => pc.loadMorePosts(limit: 10),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: Dimensions.paddingSizeExtraLarge),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// SliverAppBar giống style MainHomeScreen nhưng có back và tên user
class _ProfileAppBar extends StatelessWidget {
  final SocialUser user;
  const _ProfileAppBar({required this.user});

  @override
  Widget build(BuildContext context) {
    final String titleText = user.displayName ??
        user.userName ??
        '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();

    return SliverAppBar(
      floating: true,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).highlightColor,
      title: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              titleText.isEmpty ? 'Profile' : titleText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            // TODO: mở settings / edit profile
          },
          icon: const Icon(Icons.more_vert),
        ),
      ],
    );
  }
}

/// ==============================
/// Header user (cover + avatar + tên + username)
/// ==============================
class _ProfileHeaderSection extends StatelessWidget {
  final SocialUser user;
  const _ProfileHeaderSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cover = user.coverUrl;
    final avatar = user.avatarUrl;
    final fullName = user.displayName ??
        user.userName ??
        '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeDefault,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Cover ảnh header
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                image: (cover != null && cover.isNotEmpty)
                    ? DecorationImage(
                  image: NetworkImage(cover),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
            ),

            // Avatar + tên + nút
            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: theme.dividerColor,
                    backgroundImage: (avatar != null && avatar.isNotEmpty)
                        ? NetworkImage(avatar)
                        : null,
                  ),
                  const SizedBox(width: Dimensions.paddingSizeDefault),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isEmpty ? 'User' : fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        if (user.userName != null &&
                            user.userName!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '@${user.userName}',
                            style: TextStyle(
                              color: theme.hintColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Follow / Edit profile tuỳ theo đây là profile của mình hay người khác
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      getTranslated('edit_profile', context) ?? 'Chỉnh sửa',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ==============================
/// Stats followers / following
/// ==============================
class _ProfileStatsRow extends StatelessWidget {
  final List<SocialUser> followers;
  final List<SocialUser> following;

  const _ProfileStatsRow({
    required this.followers,
    required this.following,
  });

  String _fmtCount(int v) {
    if (v >= 1000000) {
      // ví dụ 1.2M
      final double millions = v / 1000000;
      return '${millions.toStringAsFixed(1)}M';
    } else if (v >= 1000) {
      final double thousands = v / 1000;
      return '${thousands.toStringAsFixed(1)}K';
    }
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _StatItem(
              label: getTranslated('followers', context) ?? 'Followers',
              value: _fmtCount(followers.length),
            ),
            _VerticalDivider(color: theme.dividerColor),
            _StatItem(
              label: getTranslated('following', context) ?? 'Following',
              value: _fmtCount(following.length),
            ),
            _VerticalDivider(color: theme.dividerColor),
            _StatItem(
              label: getTranslated('friends', context) ?? 'Bạn bè',
              value: _fmtCount(followers.length), // hoặc logic riêng về "bạn bè"
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: theme.hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  final Color color;
  const _VerticalDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: color.withValues(alpha: 0.4),
    );
  }
}

/// ==============================
/// Followers preview ngang
/// ==============================
class _FollowersPreviewSection extends StatelessWidget {
  final List<SocialUser> followers;
  const _FollowersPreviewSection({required this.followers});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (followers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        child: _SectionError(
          message: getTranslated('no_followers', context) ??
              'Chưa có người theo dõi',
          compact: true,
        ),
      );
    }

    // chỉ preview tối đa 10 người
    final preview =
    followers.length > 10 ? followers.sublist(0, 10) : followers;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTranslated('recent_followers', context) ??
                'Người theo dõi gần đây',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: preview.length,
              separatorBuilder: (_, __) =>
              const SizedBox(width: Dimensions.paddingSizeSmall),
              itemBuilder: (context, i) {
                final f = preview[i];
                final avatar = f.avatarUrl;
                final name = f.displayName ??
                    f.userName ??
                    f.firstName ??
                    'User';

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.dividerColor,
                      backgroundImage: (avatar != null && avatar.isNotEmpty)
                          ? NetworkImage(avatar)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 64,
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.hintColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ==============================
/// Danh sách bài viết cá nhân
/// ==============================
class _ProfilePostsSection extends StatelessWidget {
  final List<SocialPost> posts;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  const _ProfilePostsSection({
    required this.posts,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeDefault,
        ),
        child: _SectionError(
          message: getTranslated('no_posts_yet', context) ??
              'Chưa có bài viết nào',
          compact: true,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeDefault,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTranslated('your_posts', context) ?? 'Bài viết của bạn',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          // danh sách post (reused SocialPostCard)
          for (int i = 0; i < posts.length; i++) ...[
            SocialPostCard(post: posts[i]),
            if (i != posts.length - 1)
              const SizedBox(height: Dimensions.paddingSizeSmall),
          ],

          const SizedBox(height: Dimensions.paddingSizeDefault),

          // pagination footer
          if (isLoadingMore)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Center(
              child: TextButton(
                onPressed: onLoadMore,
                style: TextButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                ),
                child: Text(
                  getTranslated('load_more_posts', context) ??
                      'Tải thêm bài viết',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ==============================
/// Nhãn báo lỗi thân thiện
/// ==============================
class _SectionError extends StatelessWidget {
  final String message;
  final bool compact;
  const _SectionError({
    required this.message,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: compact
            ? Dimensions.paddingSizeSmall
            : Dimensions.paddingSizeDefault,
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
