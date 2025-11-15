import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_page_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_get_page.dart';

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

  @override
  void initState() {
    super.initState();
    // 3 tab: Dành cho bạn / Trang của bạn / Đã thích
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requestedSuggestedPages) {
      _requestedSuggestedPages = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Tạm thời chỉ load gợi ý
        context.read<SocialPageController>().ensureSuggestedLoaded();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openCreatePage() async {
    // TODO: mở màn tạo page thật sự
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          getTranslated('create_page_coming_soon', context) ??
              'Chức năng tạo trang sẽ sớm được bổ sung.',
        ),
      ),
    );
  }

  Future<void> _reloadSuggested() =>
      context.read<SocialPageController>().refreshSuggested();

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
          // TabBar giống Groups
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
                _buildForYouTab(context),      // tab gợi ý (đã có logic)
                _buildMyPagesTab(context),     // placeholder + nút tạo trang
                _buildLikedPagesTab(context),  // placeholder
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

    // gợi ý: những trang chưa like
    final List<SocialGetPage> pages = controller.suggestedPages
        .where((page) => !page.isLiked)
        .toList();

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
          if (pages.isNotEmpty)
            _buildPagesGrid(context, pages),
        ],
      ),
    );
  }

  // ───────────────── TAB 2: TRANG CỦA BẠN ─────────────────

  Widget _buildMyPagesTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            getTranslated('your_pages', context) ?? 'Trang của bạn',
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
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ) ??
                    TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                getTranslated('create_page_description', context) ??
                    'Hãy tạo một trang cho thương hiệu, doanh nghiệp hoặc cộng đồng của bạn.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ) ??
                    TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
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
      ],
    );
  }

  // ───────────────── TAB 3: TRANG ĐÃ THÍCH ─────────────────

  Widget _buildLikedPagesTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          getTranslated('liked_pages_coming_soon', context) ??
              'Tính năng danh sách trang đã thích\nsẽ được bổ sung trong các phiên bản tiếp theo.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ) ??
              TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 13,
              ),
        ),
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
      // TODO: mở màn chi tiết page
    }

    Future<void> handleLike() async {
      // TODO: gọi controller để like / unlike
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
                        onPressed: disableLike ? null : handleLike,
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

  String _buildPageSubtitle(BuildContext context, SocialGetPage page) {
    final String category = page.category.isNotEmpty
        ? page.category
        : (getTranslated('page', context) ?? 'Trang');

    final int likes = page.likesCount;
    final String likesLabel = likes > 0
        ? '$likes ${getTranslated('likes', context) ?? 'lượt thích'}'
        : (getTranslated('no_likes_yet', context) ?? 'Chưa có lượt thích');

    return '$category • $likesLabel';
  }
}

// OPTIONAL: nếu bạn vẫn đang gọi SocialPagesForYouScreen ở MoreScreen
class SocialPagesForYouScreen extends StatelessWidget {
  const SocialPagesForYouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SocialPagesScreen();
  }
}
