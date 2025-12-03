import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../screens/tour_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';


class TourCard extends StatelessWidget {
  final dynamic tour;

  const TourCard({super.key, required this.tour});

  String _formatPrice(num? price) {
    if (price == null) return '';

    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String tr(String key, String fallback) =>
        getTranslated(key, context) ?? fallback;

    final String title =
    (tour['title'] as String?)?.trim().isNotEmpty == true
        ? tour['title']
        : tr('unnamed_tour', 'Tour chưa có tên');

    final String subtitle =
    (tour['description'] as String?)?.trim().isNotEmpty == true
        ? tour['description']
        : tr(
      'default_tour_subtitle',
      'Trải nghiệm hành trình đáng nhớ tại điểm đến tuyệt vời này',
    );

    final String locationText =
    (tour['location'] as String?)?.trim().isNotEmpty == true
        ? tour['location']
        : tr('unknown_location', 'Địa điểm đang cập nhật');

    final dynamic rawPrice = tour['price'];
    num? priceNum;
    if (rawPrice != null) {
      try {
        priceNum = rawPrice is num
            ? rawPrice
            : num.parse(rawPrice.toString().replaceAll(',', ''));
      } catch (_) {
        priceNum = null;
      }
    }

    final String? imageUrl = (tour['image_url'] ??
        tour['image'] ??
        tour['banner'] ??
        tour['thumbnail'])
    as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TourDetailScreen(tourId: tour['id']),
                ),
              );
            },
            child: SizedBox(
              height: 300,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildImageFallback(isDark),
                    )
                        : _buildImageFallback(isDark),
                  ),

                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.10),
                            Colors.black.withOpacity(0.55),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bookmark_border_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(40),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 14,
                          sigmaY: 14,
                        ),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                          color: (isDark
                              ? Colors.black
                              : Colors.white)
                              .withOpacity(0.25),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.95),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 16,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      locationText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (priceNum != null)
                                Text(
                                  '${tr('from_price', 'Giá chỉ từ')} '
                                      '${_formatPrice(priceNum)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                )
                              else
                                Text(
                                  tr('contact_for_price',
                                      'Liên hệ để biết giá'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.95),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageFallback(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF020617), const Color(0xFF0F172A)]
              : [const Color(0xFFE0F2FE), const Color(0xFFBFDBFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.landscape_rounded,
        size: 48,
        color: isDark ? Colors.white24 : Colors.blueGrey[400],
      ),
    );
  }
}