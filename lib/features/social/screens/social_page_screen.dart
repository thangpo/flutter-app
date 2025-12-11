import 'dart:ui' show lerpDouble, ImageFilter;
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
                        background:
                        theme.brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        getTranslated('pages', context) ?? 'Pages',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: appBarForeground,
                        ),
                      ),
                      const Spacer(),
                      _RoundIconButton(
                        icon: Icons.add,
                        onTap: _openCreatePage,
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

                // ========== TAB BAR ==========
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
                        final distToNearest = (page - page.round()).abs().clamp(0.0, 0.5);
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
                            Tab(
                              text: getTranslated('for_you', context) ?? 'For You',
                            ),
                            Tab(
                              text:
                              getTranslated('your_pages', context) ?? 'Your Pages',
                            ),
                            Tab(
                              text:
                              getTranslated('liked_pages', context) ?? 'Like Pages',
                            ),
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

      // Chỉ còn TabBarView ở body thôi
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildForYouTab(context),
          _buildMyPagesTab(context),
          _buildLikedPagesTab(context),
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
          if (pages.isNotEmpty)
            ..._buildPageListItems(
              context,
              pages,
              canEdit: true,
            ),

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
        childAspectRatio: 0.70,
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
    final bool disableLike = false; // sau này thêm loading thì sửa

    void openPageDetail() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SocialPageDetailScreen(page: page),
        ),
      );
    }

    Future<void> handleLike() async {
      final pageCtrl = context.read<SocialPageController>();
      await pageCtrl.toggleLikePage(page);
    }

    final String buttonLabel = isLiked
        ? (getTranslated('liked_page', context) ?? 'Đã thích')
        : (getTranslated('like_page', context) ?? 'Thích trang');

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: openPageDetail,
        child: Ink(
          decoration: BoxDecoration(
            image: backgroundImage,
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: 0.60,
                  widthFactor: 1,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 16,
                        sigmaY: 16,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.05),
                              Colors.black.withOpacity(0.20),
                              Colors.black.withOpacity(0.45),
                              Colors.black.withOpacity(0.75),
                            ],
                            stops: const [0.0, 0.35, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // nút more góc phải trên
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.more_horiz,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),

              // 📄 Nội dung: KHÔNG có container nền bo cong nữa
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ) ??
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ) ??
                          TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: disableLike ? null : handleLike,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: Text(
                          buttonLabel,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ) ??
                              const TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
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
      BuildContext context,
      List<SocialGetPage> pages, {
        bool canEdit = false,
      }) {
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

                const SizedBox(width: 4),

                if (canEdit && page.isPageOwner)
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
          case 'delete':
            _confirmDeletePage(page);
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
        const PopupMenuDivider(height: 6),
        PopupMenuItem<String>(
          value: 'delete',
          child: Text(
            getTranslated('delete_page', ctx) ?? 'Xóa trang',
            style: TextStyle(color: Theme.of(ctx).colorScheme.error),
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

  Future<void> _confirmDeletePage(SocialGetPage page) async {
    final theme = Theme.of(context);
    final TextEditingController pwdCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final pageCtrl = context.read<SocialPageController>();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            getTranslated('delete_page', ctx) ?? 'Xóa trang',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getTranslated('delete_page_confirm', ctx) ??
                      'Bạn có chắc muốn xóa trang này? Hành động không thể hoàn tác.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: pwdCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: getTranslated('password', ctx) ?? 'Mật khẩu',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? (getTranslated('password_required', ctx) ??
                          'Vui lòng nhập mật khẩu')
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(getTranslated('cancel', ctx) ?? 'Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(ctx).pop(true);
                }
              },
              child: Text(getTranslated('delete', ctx) ?? 'Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final String password = pwdCtrl.text.trim();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          getTranslated('deleting_page', context) ?? 'Đang xóa trang...',
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    final bool ok = await pageCtrl.deletePage(page: page, password: password);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            getTranslated('delete_page_success', context) ?? 'Đã xóa trang.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.colorScheme.error,
          content: Text(
            pageCtrl.deletePageError ??
                getTranslated('delete_page_failed', context) ??
                'Xóa trang thất bại.',
          ),
        ),
      );
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
        child: Icon(
          icon,
          size: 20,
        ),
      ),
    );
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
