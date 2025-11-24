// G:\flutter-app\lib\features\social\screens\social_page_detail.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_get_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_screen.dart'
    show SocialPostCard;
import 'package:flutter_sixvalley_ecommerce/features/social/screens/create_post_screen.dart';

import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_page_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/edit_page_screen.dart';

class SocialPageDetailScreen extends StatefulWidget {
  final SocialGetPage page;

  const SocialPageDetailScreen({
    Key? key,
    required this.page,
  }) : super(key: key);

  @override
  State<SocialPageDetailScreen> createState() => _SocialPageDetailScreenState();
}

class _SocialPageDetailScreenState extends State<SocialPageDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;
  late SocialGetPage _page;

  // Tab đang chọn (Trang chủ, Giới thiệu, Video, Ảnh, Xem thêm)
  String _selectedTab = 'home';

  @override
  void initState() {
    super.initState();
    _page = widget.page;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pageCtrl = context.read<SocialPageController>();
      pageCtrl.loadInitialPagePosts(_page.pageId);
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 180 && !_showTitle) {
      setState(() => _showTitle = true);
    } else if (_scrollController.offset <= 180 && _showTitle) {
      setState(() => _showTitle = false);
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      final pageCtrl = context.read<SocialPageController>();
      if (pageCtrl.hasMorePagePosts && !pageCtrl.loadingMorePagePosts) {
        pageCtrl.loadMorePagePosts(_page.pageId);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------- ACTIONS -----------------

  void _onFollowOrUnfollow() async {
    final pageCtrl = context.read<SocialPageController>();

    final bool wasLiked = _page.isLiked;
    final bool isLikedNow = await pageCtrl.toggleLikePage(_page);
    if (!mounted) return;

    setState(() {
      int newLikes = _page.likesCount;

      if (isLikedNow && !wasLiked) {
        newLikes++;
      } else if (!isLikedNow && wasLiked && newLikes > 0) {
        newLikes--;
      }

      _page = _page.copyWith(
        isLiked: isLikedNow,
        likesCount: newLikes,
      );
    });
  }

  void _onMessage() {
    _showToast(getTranslated('feature_coming_soon', context) ?? 'Sắp ra mắt');
  }

  Future<void> _onEditPage() async {
    final payload = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => EditPageScreen(
          pageId: _page.pageId,
          initialPageName: _page.pageName,
          initialPageTitle: _page.name,
          initialDescription: _page.description,
          initialCategoryName: _page.category,
          initialAvatarUrl: _page.avatarUrl,
          initialCoverUrl: _page.coverUrl,
        ),
      ),
    );

    if (!mounted || payload == null) return;

    final ctrl = context.read<SocialPageController>();
    final ok = await ctrl.updatePageFromPayload(payload);

    if (!mounted) return;

    if (ok && ctrl.lastUpdatedPage != null) {
      setState(() {
        _page = ctrl.lastUpdatedPage!;
      });
      _showToast(getTranslated('page_updated', context) ?? 'Đã cập nhật trang');
    } else if (ok) {
      _showToast(getTranslated('page_updated', context) ?? 'Đã cập nhật trang');
    } else {
      _showToast(
          getTranslated('update_failed', context) ?? 'Cập nhật thất bại');
    }
  }

  void _onAdvertise() {
    _showToast('Tính năng quảng cáo đang phát triển');
  }

  Future<void> _onCreatePost() async {
    if (!_page.isPageOwner) {
      _showToast(
        getTranslated('only_page_owner_can_post', context) ??
            'Chỉ chủ trang mới có thể đăng bài.',
      );
      return;
    }

    final SocialPost? created = await Navigator.of(context).push<SocialPost>(
      MaterialPageRoute(
        builder: (_) => SocialCreatePostScreen(
          pageId: _page.pageId.toString(),
          pageName: _page.name,
        ),
        fullscreenDialog: true,
      ),
    );

    if (!mounted || created == null) return;

    final SocialPost resolved =
        created.copyWith(pageId: created.pageId ?? _page.pageId.toString());

    context.read<SocialPageController>().prependPagePost(resolved);
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _onSelectTab(String id) {
    if (_selectedTab == id) return;
    setState(() {
      _selectedTab = id;
    });
  }

  // ---------------- UI -----------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final page = _page;
    final bool isPageOwner = page.isPageOwner;

    const double avatarRadius = 55;
    const double coverHeight = 200;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Consumer<SocialPageController>(
          builder: (context, pageCtrl, child) {
            final List<SocialPost> posts = pageCtrl.pagePosts;
            final bool isNotInitialized = !pageCtrl.pagePostsInitialized;

            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // -------- APP BAR NHỎ (GIỐNG FB) --------
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.more_horiz),
                      onPressed: () {},
                    ),
                  ],
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _showTitle ? 1.0 : 0.0,
                    child: Text(
                      page.name,
                      style: const TextStyle(fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // -------- COVER + AVATAR + INFO CƠ BẢN --------
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Cover + avatar chồng lên (giống Facebook)
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          SizedBox(
                            height: coverHeight,
                            width: double.infinity,
                            child: Image.network(
                              page.coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: Colors.grey.shade400),
                            ),
                          ),
                          Positioned(
                            bottom: -avatarRadius,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.scaffoldBackgroundColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: avatarRadius,
                                backgroundImage: NetworkImage(page.avatarUrl),
                                backgroundColor: Colors.grey.shade200,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: avatarRadius + 12),

                      // Tên, username, category, stats, buttons
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: theme.cardColor,
                        child: Column(
                          children: [
                            // Tên trang
                            Text(
                              page.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Username + category
                            Text(
                              '@${page.username} • ${page.category}',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: theme.hintColor),
                            ),
                            const SizedBox(height: 12),

                            // Rating + lượt theo dõi
                            Column(
                              children: [
                                if (page.rating > 0)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 18,
                                        color: Colors.orange.shade400,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        page.rating.toStringAsFixed(1),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  '${page.likesCount} người theo dõi',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Stats: followers / posts
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildStatItem(
                                      context,
                                      page.likesCount.toString(),
                                      getTranslated('followers', context) ??
                                          'Theo dõi',
                                    ),
                                  ),
                                  VerticalDivider(
                                    color: theme.dividerColor,
                                    thickness: 1,
                                    width: 20,
                                  ),
                                  Expanded(
                                    child: _buildStatItem(
                                      context,
                                      page.usersPost.toString(),
                                      getTranslated('posts', context) ??
                                          'Bài viết',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Buttons (Đang theo dõi / Nhắn tin) hoặc Chỉnh sửa / Quảng cáo
                            Row(
                              children: isPageOwner
                                  ? [
                                      Expanded(
                                        child: _buildActionButton(
                                          context,
                                          'Chỉnh sửa',
                                          Icons.edit_outlined,
                                          theme.canvasColor,
                                          Colors.black87,
                                          _onEditPage,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _buildActionButton(
                                          context,
                                          'Quảng cáo',
                                          Icons.campaign_outlined,
                                          Colors.blue.shade50,
                                          Colors.blue,
                                          _onAdvertise,
                                        ),
                                      ),
                                    ]
                                  : [
                                      Expanded(
                                        child: _buildActionButton(
                                          context,
                                          page.isLiked
                                              ? 'Đang theo dõi'
                                              : 'Theo dõi',
                                          page.isLiked
                                              ? Icons.check
                                              : Icons.add,
                                          page.isLiked
                                              ? theme.canvasColor
                                              : theme.primaryColor,
                                          page.isLiked
                                              ? Colors.black87
                                              : Colors.white,
                                          _onFollowOrUnfollow,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _buildActionButton(
                                          context,
                                          'Nhắn tin',
                                          Icons.chat_bubble_outline,
                                          theme.canvasColor,
                                          Colors.black87,
                                          _onMessage,
                                        ),
                                      ),
                                    ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // -------- TAB NAVIGATION --------
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTabItem(
                            context,
                            id: 'home',
                            label: 'Bài viết',
                          ),
                          _buildTabItem(
                            context,
                            id: 'about',
                            label: 'Giới thiệu',
                          ),
                          _buildTabItem(
                            context,
                            id: 'video',
                            label: 'Video',
                          ),
                          _buildTabItem(
                            context,
                            id: 'photos',
                            label: 'Ảnh',
                          ),
                          _buildTabItem(
                            context,
                            id: 'more',
                            label: 'Xem thêm',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // -------- NỘI DUNG THEO TAB --------
                ..._buildTabContentSlivers(
                  context: context,
                  theme: theme,
                  page: page,
                  isPageOwner: isPageOwner,
                  pageCtrl: pageCtrl,
                  posts: posts,
                  isNotInitialized: isNotInitialized,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------- HELPERS -----------------

  List<Widget> _buildTabContentSlivers({
    required BuildContext context,
    required ThemeData theme,
    required SocialGetPage page,
    required bool isPageOwner,
    required SocialPageController pageCtrl,
    required List<SocialPost> posts,
    required bool isNotInitialized,
  }) {
    // HOME TAB: Giới thiệu + ô tạo bài + Bài viết
    if (_selectedTab == 'home') {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (page.description != null &&
                    page.description!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Giới thiệu",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          page.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (isPageOwner)
                  InkWell(
                    onTap: _onCreatePost,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: NetworkImage(page.avatarUrl),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Bạn đang nghĩ gì?",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.image_outlined,
                            color: Colors.green.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // TITLE "Bài viết"
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Bài viết",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // POSTS / SKELETON / EMPTY
        if (isNotInitialized)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildSkeletonPost(context),
              childCount: 3,
            ),
          )
        else if (posts.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 50),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.post_add,
                      size: 50,
                      color: theme.disabledColor,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      getTranslated('no_posts_yet', context) ??
                          'Chưa có bài viết nào',
                      style: TextStyle(color: theme.hintColor),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == posts.length) {
                  if (pageCtrl.hasMorePagePosts) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  return const SizedBox(height: 40);
                }

                final post = posts[index];
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  color: theme.cardColor,
                  child: SocialPostCard(
                    post: post,
                    onPostUpdated: (updatedPost) {
                      context
                          .read<SocialPageController>()
                          .updatePagePost(updatedPost);
                    },
                  ),
                );
              },
              childCount: posts.length + 1,
            ),
          ),
      ];
    }

    // ABOUT TAB
    if (_selectedTab == 'about') {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Giới thiệu",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (page.description != null && page.description!.isNotEmpty)
                        ? page.description!
                        : 'Trang này chưa có mô tả.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    // VIDEO / PHOTOS / MORE: placeholder
    String label;
    if (_selectedTab == 'video') {
      label = 'Chưa có video nào.';
    } else if (_selectedTab == 'photos') {
      label = 'Chưa có ảnh nào.';
    } else {
      label = 'Tính năng đang phát triển.';
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
          child: Center(
            child: Text(
              label,
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.hintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color bg,
    Color text,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: text),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: text,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonPost(BuildContext context) {
    final color = Theme.of(context).hintColor.withOpacity(0.1);
    final cardColor = Theme.of(context).cardColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      color: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 120, height: 14, color: color),
                  const SizedBox(height: 6),
                  Container(width: 80, height: 12, color: color),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            height: 200,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context, {
    required String id,
    required String label,
  }) {
    final theme = Theme.of(context);
    final bool selected = _selectedTab == id;
    final Color activeColor = theme.primaryColor;
    final Color inactiveColor = theme.hintColor;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => _onSelectTab(id),
      child: Padding(
        padding: const EdgeInsets.only(right: 20, top: 4, bottom: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: 34,
              decoration: BoxDecoration(
                color: selected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
