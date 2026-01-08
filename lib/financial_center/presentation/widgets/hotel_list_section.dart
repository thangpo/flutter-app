import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/screens/hotel_map_screen.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/hotel_flip_transition.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/screens/hotel_detail_screen.dart';

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

  void _openHotelDetail(BuildContext context, Map<String, dynamic> hotel) {
    final slug = hotel['slug']?.toString();
    if (slug == null || slug.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(context, 'hotel_missing_slug', 'Không mở được chi tiết (thiếu slug).'),
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      IOSAppOpenTransition(
        page: HotelDetailScreen(slug: slug),
      ),
    );
  }

  void _openHotelMap(BuildContext context, Map<String, dynamic> hotel) {
    if (mapData.isEmpty) return;

    final id = hotel['id'];
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
  }

  // (Tuỳ chọn) chip trạng thái giống ảnh 2 nhưng không có ID
  // Bạn có thể map theo field thực tế của API (vd: status/badge/label)
  String? _getBadgeText(Map<String, dynamic> h) {
    final v = h['badge'] ?? h['status_label'] ?? h['status'];
    final s = v?.toString().trim();
    if (s == null || s.isEmpty) return null;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor = isDark ? Colors.white70 : Colors.grey[700];
    final mutedColor = isDark ? Colors.white60 : Colors.grey[600];

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
            final price = _formatPrice(h['price']?.toString());

            final canOpenMap = mapData.isNotEmpty;
            final canOpenDetail = (h['slug']?.toString().isNotEmpty ?? false);

            final badgeText = _getBadgeText(h);

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
                  onTap: () => onHotelTap(h),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // ===== Header mini (giống ảnh 2 nhưng không có ID) =====
                        if (badgeText != null) ...[
                          Row(
                            children: [
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(isDark ? 0.18 : 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(isDark ? 0.35 : 0.25),
                                  ),
                                ),
                                child: Text(
                                  badgeText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.greenAccent : Colors.green[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],

                        // ===== Row: thumb + info + price =====
                        Row(
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
                                  if (rating != null)
                                    Row(
                                      children: [
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
                                        const SizedBox(width: 6),
                                        Text(
                                          tr(context, 'hotel_rating_label', 'Điểm đánh giá'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.white54 : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Price (căn phải, không kèm nút để tránh overflow)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (price.isNotEmpty) ...[
                                  Text(
                                    price,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0EA5E9),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tr(context, 'hotel_per_night', 'mỗi đêm'),
                                    style: TextStyle(fontSize: 11, color: mutedColor),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // ===== Buttons row (giống ảnh 2: 2 nút ngang, dễ bấm) =====
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: OutlinedButton(
                                  onPressed: canOpenDetail ? () => _openHotelDetail(context, h) : null,
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    side: BorderSide(
                                      color: (isDark ? Colors.white : const Color(0xFF111827))
                                          .withOpacity(0.18),
                                    ),
                                  ),
                                  child: Text(
                                    tr(context, 'hotel_detail', 'Chi tiết'),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: FilledButton(
                                  onPressed: canOpenMap ? () => _openHotelMap(context, h) : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF2F4BFF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    tr(context, 'hotel_view_on_map', 'Xem bản đồ'),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                            ),
                          ],
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