import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

class HotelReviewSection extends StatelessWidget {
  final double score;
  final int reviewCount;
  final List<dynamic> reviews;

  const HotelReviewSection({
    super.key,
    required this.score,
    required this.reviewCount,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeController>(context, listen: false);
    final isDark = theme.darkTheme;

    return _buildSection(
      context: context,
      isDark: isDark,
      title: getTranslated('guest_reviews', context) ?? 'Đánh giá của khách',
      icon: Icons.rate_review_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (score > 0 || reviewCount > 0)
            _buildScoreCard(context, isDark, score, reviewCount),

          const SizedBox(height: 16),

          if (reviews.isEmpty)
            Text(
              getTranslated('no_reviews_yet', context) ??
                  'Chưa có đánh giá nào.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            )
          else
            Column(
              children: reviews.take(3).map((rv) {
                final review = rv as Map;

                final dynamic authorRaw = review['author'];
                String author = '';

                if (authorRaw is Map) {
                  author = (authorRaw['name'] ?? '').toString().trim();
                  if (author.isEmpty) {
                    final first =
                    (authorRaw['first_name'] ?? '').toString().trim();
                    final last =
                    (authorRaw['last_name'] ?? '').toString().trim();
                    author = [first, last]
                        .where((e) => e.isNotEmpty)
                        .join(' ')
                        .trim();
                  }
                } else if (authorRaw is String &&
                    authorRaw.trim().isNotEmpty) {
                  author = authorRaw.trim();
                }

                if (author.isEmpty &&
                    review['name'] != null &&
                    review['name'].toString().trim().isNotEmpty) {
                  author = review['name'].toString().trim();
                }

                if (author.isEmpty &&
                    review['user'] is Map &&
                    (review['user']['name'] ?? '')
                        .toString()
                        .trim()
                        .isNotEmpty) {
                  author = review['user']['name'].toString().trim();
                }

                if (author.isEmpty) {
                  author = getTranslated('anonymous_guest', context) ??
                      'Khách ẩn danh';
                }

                final String comment =
                (review['content'] ?? review['comment'] ?? '')
                    .toString();

                final double rate =
                    double.tryParse(review['rate_number']?.toString() ?? '') ??
                        double.tryParse(review['rate']?.toString() ?? '0') ??
                        0;

                final String rawDate =
                (review['created_at'] ?? review['created'] ?? '')
                    .toString();

                final String displayDate = _formatReviewDate(rawDate);

                return _buildReviewItem(
                  context: context,
                  isDark: isDark,
                  author: author,
                  comment: comment,
                  rate: rate,
                  date: displayDate,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  String _formatReviewDate(String raw) {
    if (raw.isEmpty) return '';

    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return raw;
    }
  }

  Widget _buildScoreCard(
      BuildContext context,
      bool isDark,
      double score,
      int reviewCount,
      ) {
    final reviewsLabel =
        getTranslated('reviews', context) ?? 'lượt đánh giá';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.blue[50],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.blue[100]!,
            ),
          ),
          child: Row(
            children: [
              Text(
                score.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.blue[300] : Colors.blue[700],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _reviewScoreLabel(context, score),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.blue[200] : Colors.blue[700],
                    ),
                  ),
                  Text(
                    '$reviewCount $reviewsLabel',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem({
    required BuildContext context,
    required bool isDark,
    required String author,
    required String comment,
    required double rate,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  author,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < rate.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 16,
                    color: isDark ? Colors.orange[300] : Colors.orange[400],
                  );
                }),
              ),
            ],
          ),

          if (date.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                date,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),

          if (comment.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                comment,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[200] : Colors.grey[800],
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _reviewScoreLabel(BuildContext context, double score) {
    if (score >= 9) {
      return getTranslated('excellent', context) ?? 'Xuất sắc';
    }
    if (score >= 8) {
      return getTranslated('very_good', context) ?? 'Rất tốt';
    }
    if (score >= 7) {
      return getTranslated('good', context) ?? 'Tốt';
    }
    if (score > 0) {
      return getTranslated('fair', context) ?? 'Được';
    }
    return getTranslated('good', context) ?? 'Tốt';
  }

  Widget _buildSection({
    required BuildContext context,
    required bool isDark,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isDark ? Colors.blue[200] : Colors.blue[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
