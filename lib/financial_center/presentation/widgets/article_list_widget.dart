import 'package:flutter/material.dart';
import '../services/article_service.dart';
import '../screens/article_detail_screen.dart';
import '../widgets/article_card_skeleton.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';


class ArticleListWidget extends StatefulWidget {
  const ArticleListWidget({super.key});

  @override
  State<ArticleListWidget> createState() => _ArticleListWidgetState();
}

class _ArticleListWidgetState extends State<ArticleListWidget> {
  List<dynamic> articles = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() => isLoading = true);
    try {
      final data = await ArticleService.fetchArticles();
      setState(() => articles = data);
    } catch (e) {
      debugPrint('Lỗi tải bài viết: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return 'https://vietnamtoure.com/uploads/default.jpg';
    }
    if (imageUrl.startsWith('http')) return imageUrl;
    return 'https://vietnamtoure.com$imageUrl';
  }

  String tr(BuildContext context, String key, String fallback) {
    return getTranslated(key, context) ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'articles_section_title', 'Khám phá bài viết'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 180,
            height: 12,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white12
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 18,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              return const ArticleCardSkeleton();
            },
          ),

          const SizedBox(height: 16),
        ],
      );
    }

    if (articles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 72,
              color: isDark ? Colors.white24 : const Color(0xFF0077BE),
            ),
            const SizedBox(height: 12),
            Text(
              tr(context, 'no_article', 'Không có bài viết nào'),
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'articles_section_title', 'Khám phá bài viết'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tr(
            context,
            'articles_section_subtitle',
            'Gợi ý trải nghiệm & kinh nghiệm du lịch cho bạn',
          ),
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white70 : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 16),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: articles.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 18,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, index) {
            final article = articles[index];
            return _buildArticleCard(context, article, index, isDark);
          },
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildArticleCard(
      BuildContext context, dynamic article, int index, bool isDark) {
    final String title =
    (article['title'] as String?)?.trim().isNotEmpty == true
        ? article['title']
        : tr(context, 'article_untitled', 'Bài viết chưa có tiêu đề');

    final String subtitle =
    (article['short_content'] as String?)?.trim().isNotEmpty == true
        ? article['short_content']
        : tr(
      context,
      'article_default_subtitle',
      'Gợi ý điểm đến & trải nghiệm thú vị cho hành trình của bạn.',
    );

    final imageUrl = _getFullImageUrl(article['image_url']);

    final List<List<Color>> bgPalettes = [
      [const Color(0xFFE5F3FF), const Color(0xFFCCE7FF)],
      [const Color(0xFFEAFCEC), const Color(0xFFCFF5D2)],
      [const Color(0xFFF5EEF9), const Color(0xFFE6D9FF)],
      [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)],
    ];
    final palette = bgPalettes[index % bgPalettes.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(article: article),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : palette.first,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: isDark
                              ? const Color(0xFF020617)
                              : Colors.grey.shade300,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 36,
                            color: isDark
                                ? Colors.white30
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.15),
                              Colors.black.withOpacity(0.45),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 18,
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tr(context, 'article_tag_new', 'MỚI'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr(
                          context,
                          'article_chip_label',
                          'Góc du lịch',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.12)
                            : const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tr(context, 'article_cta', 'Xem ngay'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
}