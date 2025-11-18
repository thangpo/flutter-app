import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_get_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';

// Dùng lại SocialPostCard từ social_screen.dart (giống profile)
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_screen.dart'
    show SocialPostCard;

import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_page_controller.dart';

class SocialPageDetailScreen extends StatefulWidget {
  final SocialGetPage page;

  const SocialPageDetailScreen({
    super.key,
    required this.page,
  });

  @override
  State<SocialPageDetailScreen> createState() => _SocialPageDetailScreenState();
}

class _SocialPageDetailScreenState extends State<SocialPageDetailScreen> {
  @override
  void initState() {
    super.initState();

    // Gọi controller để load bài viết của page lần đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pageCtrl = context.read<SocialPageController>();
      pageCtrl.loadInitialPagePosts(widget.page.pageId);
    });
  }

  // ================== HANDLER CÁC ACTION (tạm thời) ==================

  void _onCreatePost() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          getTranslated('feature_coming_soon', context) ??
              'Chức năng đăng bài với tư cách trang sẽ sớm được bổ sung.',
        ),
      ),
    );
  }

  void _onShowAbout() {
    final desc = widget.page.description;
    if (desc == null || desc.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giới thiệu về ${widget.page.name}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  desc,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onToggleLike() async {
    final pageCtrl = context.read<SocialPageController>();
    final bool isLikedNow = await pageCtrl.toggleLikePage(widget.page);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isLikedNow
              ? (getTranslated('page_liked', context) ?? 'Đã thích trang.')
              : (getTranslated('page_unliked', context) ?? 'Đã bỏ thích trang.'),
        ),
      ),
    );
  }

  void _onMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          getTranslated('feature_coming_soon', context) ??
              'Chức năng nhắn tin với trang sẽ sớm được bổ sung.',
        ),
      ),
    );
  }

  void _onMore() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Chia sẻ trang'),
                onTap: () {
                  Navigator.pop(ctx);
                  // TODO: share
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Sao chép liên kết'),
                onTap: () {
                  Navigator.pop(ctx);
                  // TODO: copy link
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ================== BUILD UI ==================

  @override
  Widget build(BuildContext context) {
    final page = widget.page;
    final theme = Theme.of(context);
    final bool isPageOwner = page.isPageOwner;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(page.name),
        elevation: 0,
      ),
      body: Consumer<SocialPageController>(
        builder: (context, pageCtrl, _) {
          final List<SocialPost> posts = pageCtrl.pagePosts;
          final bool isInitialLoading =
              pageCtrl.loadingPagePosts && !pageCtrl.pagePostsInitialized;
          final bool isLoadingMore = pageCtrl.loadingMorePagePosts;
          final bool hasMore = pageCtrl.hasMorePagePosts;
          final String? error = pageCtrl.pagePostsError;

          // Đang load lần đầu
          if (isInitialLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Lỗi khi load lần đầu (chưa có dữ liệu)
          if (error != null && !pageCtrl.pagePostsInitialized) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      getTranslated('something_went_wrong', context) ??
                          'Đã xảy ra lỗi khi tải dữ liệu.',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<SocialPageController>()
                            .loadInitialPagePosts(page.pageId);
                      },
                      child: Text(
                        getTranslated('retry', context) ?? 'Thử lại',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Có dữ liệu (hoặc chưa có nhưng không lỗi) -> build layout chính
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// HEADER
                _PageHeaderBlock(
                  page: page,
                  isPageOwner: isPageOwner,
                  onTapMore: _onMore,
                  onTapMessage: _onMessage,
                  onTapLikeOrUnlike: _onToggleLike,
                ),

                const SizedBox(height: 12),

                /// ALERT OWNER
                if (isPageOwner)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                    ),
                    child: _PageManagementAlert(page: page),
                  ),

                const SizedBox(height: 12),

                /// COMPOSER
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                  ),
                  child: _PageComposer(
                    page: page,
                    onCreatePost: _onCreatePost,
                  ),
                ),

                const SizedBox(height: 12),

                /// MAIN: Giới thiệu + Thông tin nhanh + Posts (tất cả xếp dọc)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                    vertical: 8,
                  ),
                  child: _PagePostsSection(
                    page: page,
                    posts: posts,
                    isLoadingMore: isLoadingMore,
                    onLoadMore: () => context
                        .read<SocialPageController>()
                        .loadMorePagePosts(page.pageId),
                    onShowAbout: _onShowAbout,
                    hasMore: hasMore,
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// ===================================================================
/// HEADER PAGE (cover + avatar + info + nút)
/// ===================================================================

class _PageHeaderBlock extends StatelessWidget {
  final SocialGetPage page;
  final bool isPageOwner;
  final VoidCallback onTapMore;
  final VoidCallback onTapMessage;
  final VoidCallback onTapLikeOrUnlike;

  const _PageHeaderBlock({
    required this.page,
    required this.isPageOwner,
    required this.onTapMore,
    required this.onTapMessage,
    required this.onTapLikeOrUnlike,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: theme.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cover
          SizedBox(
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  page.coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey.shade300),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Avatar + info + nút
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeDefault,
              16,
              Dimensions.paddingSizeDefault,
              12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 4,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(page.avatarUrl),
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        page.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${page.username} · ${page.category}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${page.likesCount} lượt thích',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.hintColor),
                          ),
                          const SizedBox(width: 8),
                          const Text('•'),
                          const SizedBox(width: 8),
                          Text(
                            '${page.usersPost} bài viết',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.hintColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: onTapMore,
                  icon: const Icon(Icons.more_horiz),
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ],
            ),
          ),

          // Hàng nút action (tách thành 2 dòng để tránh overflow)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: 8,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTapLikeOrUnlike,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        icon: Icon(
                          page.isLiked
                              ? Icons.check
                              : Icons.thumb_up_outlined,
                          size: 18,
                        ),
                        label:
                        Text(page.isLiked ? 'Đang thích' : 'Thích trang'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTapMessage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        icon: const Icon(Icons.message_outlined, size: 18),
                        label: const Text('Nhắn tin'),
                      ),
                    ),
                  ],
                ),
                if (isPageOwner) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: mở EditPageScreen
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text('Chỉnh sửa'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ===================================================================
/// ALERT QUẢN LÝ PAGE (OWNER)
/// ===================================================================

class _PageManagementAlert extends StatelessWidget {
  final SocialGetPage page;

  const _PageManagementAlert({required this.page});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueAccent,
            ),
            child: const Icon(Icons.flag, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bạn đang quản lý trang này. Hãy đăng nội dung thường xuyên để tăng tương tác.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// ===================================================================
/// COMPOSER ĐĂNG BÀI VỚI TƯ CÁCH PAGE
/// ===================================================================

class _PageComposer extends StatelessWidget {
  final SocialGetPage page;
  final VoidCallback onCreatePost;

  const _PageComposer({
    required this.page,
    required this.onCreatePost,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(page.avatarUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onCreatePost,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.inputDecorationTheme.fillColor ??
                          theme.dividerColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Viết gì đó với tư cách ${page.name}...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _ComposerIconButton(
                icon: Icons.image_outlined,
                label: 'Ảnh/Video',
              ),
              _ComposerIconButton(
                icon: Icons.insert_emoticon_outlined,
                label: 'Cảm xúc',
              ),
              _ComposerIconButton(
                icon: Icons.location_on_outlined,
                label: 'Check-in',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComposerIconButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ComposerIconButton({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        // TODO: mở picker tương ứng
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.hintColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===================================================================
/// PHẦN POSTS CỦA PAGE
/// ===================================================================

class _PagePostsSection extends StatelessWidget {
  final SocialGetPage page;
  final List<SocialPost> posts;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final VoidCallback onShowAbout;
  final bool hasMore;

  const _PagePostsSection({
    required this.page,
    required this.posts,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.onShowAbout,
    required this.hasMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (posts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _PageAboutSnippet(page: page, onShowAbout: onShowAbout),
          const SizedBox(height: 12),
          // 👉 Thông tin nhanh đặt NGAY DƯỚI Giới thiệu
          _PageSidebarInfo(page: page),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Text(
              getTranslated('no_posts_yet', context) ??
                  'Trang này chưa có bài viết nào',
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
        const SizedBox(height: 8),
        _PageAboutSnippet(page: page, onShowAbout: onShowAbout),
        const SizedBox(height: 12),
        // 👉 Thông tin nhanh ngay dưới Giới thiệu
        _PageSidebarInfo(page: page),
        const SizedBox(height: 16),

        for (int i = 0; i < posts.length; i++) ...[
          Container(
            color: theme.cardColor,
            child: SocialPostCard(post: posts[i]),
          ),
          if (i != posts.length - 1)
            Container(
              height: 8,
              color: const Color(0xFFF0F2F5),
            ),
        ],

        const SizedBox(height: Dimensions.paddingSizeDefault),
        if (isLoadingMore)
          const Center(child: CircularProgressIndicator())
        else if (hasMore)
          Center(
            child: TextButton(
              onPressed: onLoadMore,
              child: Text(
                getTranslated('load_more', context) ?? 'Tải thêm',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}

class _PageAboutSnippet extends StatelessWidget {
  final SocialGetPage page;
  final VoidCallback onShowAbout;

  const _PageAboutSnippet({
    required this.page,
    required this.onShowAbout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (page.description == null || page.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: onShowAbout,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Giới thiệu',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              page.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// ===================================================================
/// SIDEBAR INFO PAGE (giờ dùng như "card thông tin nhanh" dưới Giới thiệu)
/// ===================================================================

class _PageSidebarInfo extends StatelessWidget {
  final SocialGetPage page;

  const _PageSidebarInfo({required this.page});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin nhanh',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.thumb_up_alt_outlined,
            label: 'Lượt thích',
            value: page.likesCount.toString(),
          ),
          _InfoRow(
            icon: Icons.article_outlined,
            label: 'Bài viết',
            value: page.usersPost.toString(),
          ),
          if (page.website != null && page.website!.isNotEmpty)
            _InfoRow(
              icon: Icons.public,
              label: 'Website',
              value: page.website!,
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.hintColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          // 👇 Cho value co giãn + ellipsis để tránh overflow
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
