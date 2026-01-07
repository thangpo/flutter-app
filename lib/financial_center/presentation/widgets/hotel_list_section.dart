import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/screens/hotel_map_screen.dart';
import 'package:latlong2/latlong.dart';

class HotelListSection extends StatelessWidget {
  final List<Map<String, dynamic>> hotels;
  final List<Map<String, dynamic>> mapData;
  final bool isDark;
  final String Function(BuildContext context, String key, String fallback) tr;
  final void Function(Map<String, dynamic> hotel) onHotelTap;

  const HotelListSection({
    super.key,
    required this.hotels,
    required this.mapData,
    required this.isDark,
    required this.tr,
    required this.onHotelTap,
  });

  String _formatPrice(String? price) {
    if (price == null || price.isEmpty) return '';
    return '$price \$';
  }

  @override
  Widget build(BuildContext context) {
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
              color: isDark ? Colors.white : const Color(0xFF111827),
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
            final price = _formatPrice(h['price']?.toString());

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF020617) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDark
                    ? []
                    : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onHotelTap(h),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: 90,
                          height: 90,
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
                            child: const Icon(Icons.image, size: 32),
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
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
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
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white70 : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (rating != null) ...[
                                  Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: Colors.amber[400],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    tr(context, 'hotel_rating_label', 'Điểm đánh giá'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white54 : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (price.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              price,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0EA5E9),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tr(context, 'hotel_per_night', 'mỗi đêm'),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          OutlinedButton.icon(
                            onPressed: mapData.isEmpty
                                ? null
                                : () {
                              final id = h['id'];
                              Map<String, dynamic> initial = mapData.first;

                              try {
                                initial = mapData.firstWhere((x) => x['id'] == id);
                              } catch (_) {}

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HotelMapScreen(
                                    hotels: mapData,
                                    initialHotel: initial,
                                    autoLocateOnStart: true,
                                  ),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              side: BorderSide(
                                color: const Color(0xFF0EA5E9).withOpacity(0.8),
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.map_rounded, size: 14),
                            label: Text(
                              tr(context, 'hotel_view_on_map', 'Xem bản đồ'),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
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