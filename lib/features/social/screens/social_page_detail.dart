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
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_page_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
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

  @override
  void initState() {
    super.initState();
    _page = widget.page; // <-- KHỞI TẠO STATE LOCAL

    // Load posts ban đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pageCtrl = context.read<SocialPageController>();
      pageCtrl.loadInitialPagePosts(_page.pageId);
    });

    // Lắng nghe scroll để:
    // - Hiện/ẩn Title trên AppBar
    // - Tự động load more khi gần đáy
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // 1. Hiện/ẩn title trong AppBar
    if (_scrollController.offset > 180 && !_showTitle) {
      setState(() => _showTitle = true);
    } else if (_scrollController.offset <= 180 && _showTitle) {
      setState(() => _showTitle = false);
    }

    // 2. Auto load more khi gần chạm đáy
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
      _showToast(getTranslated('update_failed', context) ?? 'Cập nhật thất bại');
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

  // ---------------- UI -----------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final page = _page;
    final bool isPageOwner = page.isPageOwner;

    const double avatarRadius = 55;
    const double topMargin = 60;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<SocialPageController>(
        builder: (context, pageCtrl, child) {
          final List<SocialPost> posts = pageCtrl.pagePosts;
          final bool isNotInitialized = !pageCtrl.pagePostsInitialized;

          return CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // -------- APP BAR --------
              SliverAppBar(
                expandedHeight: 220.0,
                floating: false,
                pinned: true,
                backgroundColor: theme.primaryColor,
                leading: IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.black38,
                    child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const CircleAvatar(
                      backgroundColor: Colors.black38,
                      child: Icon(Icons.more_horiz, color: Colors.white, size: 20),
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                ],
                title: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _showTitle ? 1.0 : 0.0,
                  child: Text(
                    page.name,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        page.coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: Colors.grey.shade400),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black26, Colors.transparent],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // -------- INFO SECTION (avatar + tên + stats + buttons) --------
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: topMargin - avatarRadius),
                      padding: const EdgeInsets.only(
                        top: avatarRadius + 10,
                        bottom: 20,
                      ),
                      decoration: BoxDecoration(color: theme.cardColor),
                      child: Column(
                        children: [
                          // Tên trang
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              page.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Username + category
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '@${page.username} • ${page.category}',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: theme.hintColor),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Stats
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: IntrinsicHeight(
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
                          ),
                          const SizedBox(height: 20),

                          // Buttons
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: isPageOwner
                                ? Row(
                              children: [
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
                              ],
                            )
                                : Row(
                              children: [
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
                          ),
                        ],
                      ),
                    ),

                    // Avatar
                    Positioned(
                      top: -avatarRadius + 30,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
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
              ),

              // -------- INTRO + CREATE POST --------
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

              // -------- TITLE "Bài viết" --------
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    "Bài viết",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // -------- POSTS / SKELETON / EMPTY --------
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
                      // index cuối để render loading / spacing
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

                      // Mỗi bài viết
                      final post = posts[index];
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        color: theme.cardColor,
                        child: SocialPostCard(
                          post: post,
                          onPostUpdated: (updatedPost) {
                            // ⬇️ Chính là dòng này
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
            ],
          );
        },
      ),
    );
  }

  // ---------------- HELPERS -----------------

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
}
