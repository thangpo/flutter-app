import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/screens/hotel_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';

class HotelListSection extends StatelessWidget {
  final List<Map<String, dynamic>> hotels;
  final bool isDark;
  final String Function(BuildContext context, String key, String fallback) tr;

  const HotelListSection({
    super.key,
    required this.hotels,
    required this.isDark,
    required this.tr,
  });

  void _openHotelDetail(BuildContext context, Map<String, dynamic> hotel) {
    final slug = hotel['slug']?.toString() ?? '';
    if (slug.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'hotel_missing_slug', 'Không mở được chi tiết (thiếu slug).')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HotelDetailScreen(slug: slug),
      ),
    );
  }

  double _toPrice(dynamic raw) {
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble();

    final s = raw.toString().trim();
    final direct = double.tryParse(s);
    if (direct != null) return direct;
    final cleaned = s.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor = isDark ? Colors.white70 : Colors.grey[700];
    final mutedColor = isDark ? Colors.white60 : Colors.grey[600];

    final perNight = tr(context, 'hotel_per_night', 'mỗi đêm');
    final notAvailable = tr(context, 'not_available', '—');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            tr(context, 'hotel_best_deals', 'Ưu đãi khách sạn dành cho bạn'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
        ),
        const SizedBox(height: 8),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: hotels.length,
          itemBuilder: (context, index) {
            final h = hotels[index];
            final title = h['title']?.toString() ?? '';
            final location = h['location']?.toString() ?? '';
            final address = h['address']?.toString() ?? '';
            final thumb = h['thumbnail']?.toString() ?? '';
            final rating = double.tryParse(h['review_score']?.toString() ?? '');

            final priceValue = _toPrice(h['price']);
            final hasPrice = priceValue > 0;

            final priceText = hasPrice
                ? PriceConverter.convertPrice(context, priceValue)
                : notAvailable;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B1220) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDark
                    ? []
                    : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _openHotelDetail(context, h),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 86,
                            height: 86,
                            child: thumb.isNotEmpty
                                ? Image.network(
                              thumb,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              ),
                            )
                                : Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, size: 30),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 6),

                              if (location.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      size: 14,
                                      color: Color(0xFF0EA5E9),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        location,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, color: subColor),
                                      ),
                                    ),
                                  ],
                                ),

                              if (address.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: mutedColor),
                                ),
                              ],

                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  if (rating != null) ...[
                                    Icon(Icons.star_rounded, size: 16, color: Colors.amber[400]),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: titleColor,
                                      ),
                                    ),
                                  ],

                                  const Spacer(),

                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        priceText,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: hasPrice ? const Color(0xFF0EA5E9) : mutedColor,
                                        ),
                                      ),
                                      if (hasPrice) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          perNight,
                                          style: TextStyle(fontSize: 11, color: mutedColor),
                                        ),
                                      ],
                                    ],
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
              ),
            );
          },
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}