import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

class ArticleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> article;

  const ArticleDetailScreen({super.key, required this.article});

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

    final String title =
    (article['title'] as String?)?.trim().isNotEmpty == true
        ? article['title']
        : tr(context, 'article_title_fallback', 'Bài viết');

    final String highlight =
    (article['short_content'] as String?)?.trim().isNotEmpty == true
        ? article['short_content']
        : tr(
      context,
      'article_highlight_fallback',
      'Khám phá thêm những trải nghiệm du lịch thú vị cùng VietnamToure.',
    );

    final String author =
    (article['author'] as String?)?.trim().isNotEmpty == true
        ? article['author']
        : 'VietnamToure';

    final String createdAt =
    (article['created_at'] as String?)?.trim().isNotEmpty == true
        ? article['created_at']
        : '';

    final String imageUrl = _getFullImageUrl(article['image_url'] as String?);
    final String contentHtml = article['content'] ?? '';

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF022C22) : const Color(0xFF064E3B),
      body: SafeArea(
        child: Column(
          children: [
            /// Thanh trên cùng: Back + tiêu đề
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// Nội dung scroll được
            Expanded(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // CARD LỚN kiểu story
                    _buildStoryCard(
                      context: context,
                      imageUrl: imageUrl,
                      author: author,
                      title: title,
                      highlight: highlight,
                      createdAt: createdAt,
                    ),

                    const SizedBox(height: 24),

                    // Nội dung chi tiết (HTML)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF020617) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: contentHtml.trim().isEmpty
                          ? Text(
                        tr(
                          context,
                          'article_content_updating',
                          'Nội dung bài viết đang được cập nhật.',
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.7,
                          color: isDark
                              ? Colors.white.withOpacity(0.9)
                              : const Color(0xFF111827),
                        ),
                      )
                          : HtmlWidget(
                        contentHtml,
                        textStyle: TextStyle(
                          fontSize: 16,
                          height: 1.7,
                          color: isDark
                              ? Colors.white.withOpacity(0.9)
                              : const Color(0xFF111827),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard({
    required BuildContext context,
    required String imageUrl,
    required String author,
    required String title,
    required String highlight,
    required String createdAt,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: isDark
                      ? const Color(0xFF020617)
                      : Colors.grey.shade300,
                  child: Icon(
                    Icons.image_not_supported,
                    size: 60,
                    color:
                    isDark ? Colors.white30 : Colors.grey.shade600,
                  ),
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.25),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: Text(
                            author.isNotEmpty
                                ? author.characters.first.toUpperCase()
                                : 'V',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '@$author',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          highlight,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      height: 1,
                      width: double.infinity,
                      color: Colors.white.withOpacity(0.4),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: Text(
                            author.isNotEmpty
                                ? author.characters.first.toUpperCase()
                                : 'V',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            highlight,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (createdAt.isNotEmpty)
                          SizedBox(
                            width: 60,
                            child: Text(
                              createdAt,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 10,
                              ),
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
      ),
    );
  }
}
