import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_page_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_get_page.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/screens/create_page_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/edit_page_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_page_detail.dart';

import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

class SocialPagesScreen extends StatefulWidget {
  const SocialPagesScreen({super.key});

  @override
  State<SocialPagesScreen> createState() => _SocialPagesScreenState();
}

class _SocialPagesScreenState extends State<SocialPagesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _requestedSuggestedPages = false;
  bool _requestedMyPages = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (_tabController.index == 2) {
        // Tab "Đã thích"
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final social = context.read<SocialController>();
          final myId = social.currentUser?.id; // user_id hiện tại
          context.read<SocialPageController>().ensureLikedPagesLoaded(
            userId: myId,
          );
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Lần đầu vào màn sẽ gọi load gợi ý
    if (!_requestedSuggestedPages) {
      _requestedSuggestedPages = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<SocialPageController>().ensureSuggestedLoaded();
      });
    }

    // Lần đầu vào màn sẽ gọi load "Trang của bạn"
    if (!_requestedMyPages) {
      _requestedMyPages = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<SocialPageController>().ensureMyPagesLoaded();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openCreatePage() async {
    if (!mounted) return;

    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const CreatePageScreen(),
        fullscreenDialog: true,
      ),
    );

    if (created == true && mounted) {
      // Sau khi tạo xong: chuyển sang tab "Trang của bạn"
      _tabController.animateTo(1);
      // Nếu muốn chắc chắn load lại từ server:
      // await context.read<SocialPageController>().refreshMyPages();
    }
  }

  String _buildPageCategory(SocialGetPage page) {
    if (page.category.isNotEmpty) {
      return page.category;
    }
    return getTranslated('page', context) ?? 'Trang';
  }

  Future<void> _reloadSuggested() =>
      context.read<SocialPageController>().refreshSuggested();

  Future<void> _reloadMyPages() =>
      context.read<SocialPageController>().refreshMyPages();

  Future<void> _reloadLikedPages() =>
      context.read<SocialPageController>().refreshLikedPages();

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
      appBar: AppBar(
        backgroundColor: appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: appBarForeground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          getTranslated('pages', context) ?? 'Trang',
          style: theme.textTheme.titleMedium?.copyWith(
            color: appBarForeground,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ) ??
              TextStyle(
                color: appBarForeground,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: appBarForeground),
            onPressed: _openCreatePage,
            tooltip: getTranslated('create_page', context) ?? 'Tạo trang',
          ),
          IconButton(
            icon: Icon(Icons.person, color: appBarForeground),
            onPressed: () {
              // TODO: mở profile social
            },
            tooltip: getTranslated('profile', context) ?? 'Hồ sơ',
          ),
          IconButton(
            icon: Icon(Icons.search, color: appBarForeground),
            onPressed: () {
              // TODO: mở màn search page
            },
            tooltip: getTranslated('search', context) ?? 'Tìm kiếm',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: appBarBackground,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: colorScheme.primary,
              labelColor: colorScheme.primary,
              unselectedLabelColor: unselectedTabColor,
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(
                  text: getTranslated('for_you', context) ?? 'Dành cho bạn',
                ),
                Tab(
                  text:
                  getTranslated('your_pages', context) ?? 'Trang của bạn',
                ),
                Tab(
                  text:
                  getTranslated('liked_pages', context) ?? 'Đã thích',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildForYouTab(context),
                _buildMyPagesTab(context),
                _buildLikedPagesTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── TAB 1: DÀNH CHO BẠN ─────────────────

  Widget _buildForYouTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final controller = context.watch<SocialPageController>();

    // Gợi ý: những trang chưa like
    final List<SocialGetPage> pages =
    controller.suggestedPages.where((page) => !page.isLiked).toList();

    final bool loading = controller.loadingSuggested;

    return RefreshIndicator(
      onRefresh: _reloadSuggested,
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
          if (loading && pages.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!loading && pages.isEmpty)
            _buildEmptyBox(
              context: context,
              message: getTranslated('no_suggested_pages', context) ??
                  'Chưa có trang nào gợi ý',
            ),
          if (loading && pages.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (pages.isNotEmpty) _buildPagesGrid(context, pages),
        ],
      ),
    );
  }

  // ───────────────── TAB 2: TRANG CỦA BẠN ─────────────────

  Widget _buildMyPagesTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final controller = context.watch<SocialPageController>();
    final List<SocialGetPage> pages = controller.myPages;
    final bool loading = controller.loadingMyPages;

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

    return RefreshIndicator(
      onRefresh: _reloadMyPages,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              getTranslated('your_pages', context) ?? 'Trang của bạn',
              style: headerStyle,
            ),
          ),

          // Loading lần đầu
          if (loading && pages.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),

          // Không có page nào
          if (!loading && pages.isEmpty)
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
                    getTranslated('no_pages_yet', context) ??
                        'Bạn chưa tạo trang nào.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface
                          .withValues(alpha: 0.8),
                    ) ??
                        TextStyle(
                          color: colorScheme.onSurface
                              .withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    getTranslated(
                      'create_page_description', context,
                    ) ??
                        'Hãy tạo một trang cho thương hiệu, doanh nghiệp hoặc cộng đồng của bạn.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface
                          .withValues(alpha: 0.7),
                    ) ??
                        TextStyle(
                          color: colorScheme.onSurface
                              .withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openCreatePage,
                      icon: const Icon(Icons.add),
                      label: Text(
                        getTranslated('create_page', context) ?? 'Tạo trang',
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Có danh sách page
          if (pages.isNotEmpty) ..._buildPageListItems(context, pages),

          const SizedBox(height: 16),

          // Box "Khám phá thêm"
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
                      icon: Icons.flag,
                      label: getTranslated('create_page', context) ??
                          'Tạo trang',
                      onTap: _openCreatePage,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── TAB 3: TRANG ĐÃ THÍCH ─────────────────

  Widget _buildLikedPagesTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final controller = context.watch<SocialPageController>();
    final List<SocialGetPage> pages = controller.likedPages;
    final bool loading = controller.loadingLikedPages;

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

    return RefreshIndicator(
      onRefresh: _reloadLikedPages,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              getTranslated('liked_pages', context) ?? 'Trang đã thích',
              style: headerStyle,
            ),
          ),

          if (loading && pages.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),

          if (!loading && pages.isEmpty)
            _buildEmptyBox(
              context: context,
              message: getTranslated('no_liked_pages_yet', context) ??
                  'Bạn chưa thích trang nào.',
            ),

          if (pages.isNotEmpty) ..._buildPageListItems(context, pages),
        ],
      ),
    );
  }

  // ───────────────── COMMON: GRID + CARD + EMPTY ─────────────────

  Widget _buildPagesGrid(BuildContext context, List<SocialGetPage> pages) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: pages.length,
      itemBuilder: (context, index) {
        final page = pages[index];
        return _buildPageCard(context, page);
      },
    );
  }

  Widget _buildEmptyBox({
    required BuildContext context,
    required String message,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
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
    );
  }

  Widget _buildPageCard(BuildContext context, SocialGetPage page) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String imageUrl =
    (page.coverUrl.isNotEmpty ? page.coverUrl : page.avatarUrl).trim();

    final DecorationImage? backgroundImage = imageUrl.isNotEmpty
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

    final String title = page.name.isNotEmpty ? page.name : page.username;
    final String subtitle = _buildPageSubtitle(context, page);

    final bool isLiked = page.isLiked;
    final bool disableLike = false; // sau này có trạng thái loading thì thay

    void openPageDetail() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SocialPageDetailScreen(page: page),
        ),
      );
    }


    Future<void> handleLike() async {
      // TODO: gọi controller để like / unlike page
      // await context.read<SocialPageController>().toggleLike(page.pageId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            getTranslated('feature_coming_soon', context) ??
                'Chức năng này sẽ sớm được bổ sung.',
          ),
        ),
      );
    }

    final String buttonLabel = isLiked
        ? (getTranslated('liked_page', context) ?? 'Đã thích')
        : (getTranslated('like_page', context) ?? 'Thích trang');

    final Widget buttonChild = Text(
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
        onTap: openPageDetail,
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
                    Icons.more_horiz,
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
                        color:
                        Colors.white.withValues(alpha: 0.85),
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
                        onPressed: disableLike ? null : handleLike,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          padding:
                          const EdgeInsets.symmetric(vertical: 8),
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

  String _buildPageSubtitle(BuildContext context, SocialGetPage page) {
    final String category = page.category.isNotEmpty
        ? page.category
        : (getTranslated('page', context) ?? 'Trang');

    final int likes = page.likesCount;
    final String likesLabel = likes > 0
        ? '$likes ${getTranslated('likes', context) ?? 'lượt thích'}'
        : (getTranslated('no_likes_yet', context) ??
        'Chưa có lượt thích');

    return '$category • $likesLabel';
  }

  // ───────────────── LIST ITEM CHO "TRANG CỦA BẠN" & "ĐÃ THÍCH" ─────────────────

  List<Widget> _buildPageListItems(
      BuildContext context, List<SocialGetPage> pages) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Color mutedColor =
    colorScheme.onSurface.withValues(alpha: 0.6);

    return pages
        .map(
          (page) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SocialPageDetailScreen(page: page),
              ),
            );
          },
          child: Padding(
            padding:
            const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    image: (page.avatarUrl.isNotEmpty)
                        ? DecorationImage(
                      image:
                      NetworkImage(page.avatarUrl),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: page.avatarUrl.isEmpty
                      ? Icon(
                    Icons.flag,
                    color: colorScheme.primary,
                  )
                      : null,
                ),

                const SizedBox(width: 12),

                // Tên + activity
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        page.name.isNotEmpty
                            ? page.name
                            : page.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight:
                          FontWeight.w600,
                        ) ??
                            TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight:
                              FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _buildPageCategory(page),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(
                          color: mutedColor,
                        ) ??
                            TextStyle(
                              color: mutedColor,
                              fontSize: 12,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatPageActivity(page),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(
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

                const SizedBox(width: 4),

                _buildPageMoreButton(
                  context,
                  page,
                  mutedColor,
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .toList();
  }

  Widget _buildPageMoreButton(
      BuildContext context,
      SocialGetPage page,
      Color iconColor,
      ) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: iconColor),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _onEditPage(page);
            break;
        }
      },
      itemBuilder: (ctx) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'edit',
          child: Text(
            getTranslated('edit_page', ctx) ??
                'Chỉnh sửa trang',
          ),
        ),
      ],
    );
  }

  void _onEditPage(SocialGetPage page) async {
    final payload =
    await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => EditPageScreen(
          pageId: page.pageId,
          initialPageName: page.pageName,
          initialPageTitle: page.name,
          initialDescription: page.description,
          initialCategoryName: page.category,
          initialAvatarUrl: page.avatarUrl,
          initialCoverUrl: page.coverUrl,
        ),
      ),
    );

    if (payload != null && mounted) {
      final ctrl = context.read<SocialPageController>();
      final ok = await ctrl.updatePageFromPayload(payload);

      if (!ok) {
        final msg = ctrl.updatePageError ??
            'Cập nhật trang thất bại';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              getTranslated('update_page_success', context) ??
                  'Cập nhật trang thành công.',
            ),
          ),
        );
      }
    }
  }

  String _formatPageActivity(SocialGetPage page) {
    final int likes = page.likesCount;
    final int posts = page.usersPost;

    final String likesLabel = likes > 0
        ? '$likes ${getTranslated('likes', context) ?? 'lượt thích'}'
        : (getTranslated('no_likes_yet', context) ??
        'Chưa có lượt thích');

    final String postsLabel = posts > 0
        ? '$posts ${getTranslated('posts', context) ?? 'bài viết'}'
        : (getTranslated('no_posts_yet', context) ??
        'Chưa có bài viết');

    return '$likesLabel • $postsLabel';
  }
}

// OPTIONAL: nếu MoreScreen vẫn đang gọi SocialPagesForYouScreen
class SocialPagesForYouScreen extends StatelessWidget {
  const SocialPagesForYouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SocialPagesScreen();
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
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
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
