import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

import 'tour_detail_screen.dart';

class BookingCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isDarkMode;
  final Color oceanBlue;
  final Color lightOceanBlue;

  /// callback dẫn đường – bạn sẽ implement mở map ở ngoài
  final void Function(Map<String, dynamic> booking)? onNavigate;

  const BookingCard({
    super.key,
    required this.item,
    required this.isDarkMode,
    required this.oceanBlue,
    required this.lightOceanBlue,
    this.onNavigate,
  });

  String _formatMoney(String amount) {
    try {
      final value = double.tryParse(amount) ?? 0;
      return "${value.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
            (match) => '.',
      )}₫";
    } catch (_) {
      return "$amount₫";
    }
  }

  String _getStatusLabel(BuildContext context, String status) {
    final statusMap = {
      'draft': getTranslated('draft', context) ?? 'Nháp',
      'unpaid': getTranslated('unpaid', context) ?? 'Chưa thanh toán',
      'processing': getTranslated('processing', context) ?? 'Đang xử lý',
      'confirmed': getTranslated('confirmed', context) ?? 'Đã xác nhận',
      'completed': getTranslated('completed', context) ?? 'Hoàn thành',
      'paid': getTranslated('paid', context) ?? 'Đã thanh toán',
      'partial_payment':
      getTranslated('partial_payment', context) ?? 'Thanh toán một phần',
      'cancelled': getTranslated('cancelled', context) ?? 'Đã hủy',
    };
    return statusMap[status] ?? status.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final service = (item['service'] ?? {}) as Map<String, dynamic>;

    final String title =
        service['title'] ?? getTranslated('undefined_tour', context) ?? 'Tour không xác định';
    final String subtitle = service['address'] ?? (item['city'] ?? '');
    final String imageUrl = service['thumbnail'] ?? '';

    final String startDate = item['start_date'] ?? '';
    final String endDate = item['end_date'] ?? '';
    final String total = item['total'] ?? '0';
    final String status = item['status'] ?? 'unknown';
    final String serviceType =
        item['service_type'] ?? item['object_model'] ?? '';

    // ---- TÍNH SỐ ĐÊM ----
    int nights = 0;
    DateTime? start;
    try {
      start = DateTime.parse(startDate);
      final e = DateTime.parse(endDate);
      nights = e.difference(start).inDays;
      if (nights <= 0) nights = 1;
    } catch (_) {}

    final int guests = item['total_guests'] is int
        ? item['total_guests'] as int
        : int.tryParse('${item['total_guests'] ?? 0}') ?? 0;

    final colorMap = {
      'draft': isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
      'unpaid': isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700,
      'processing': lightOceanBlue,
      'confirmed': isDarkMode ? Colors.teal.shade300 : Colors.teal.shade600,
      'completed': isDarkMode ? Colors.green.shade300 : Colors.green.shade600,
      'paid': isDarkMode ? Colors.green.shade300 : Colors.green.shade700,
      'partial_payment':
      isDarkMode ? Colors.purple.shade300 : Colors.purple.shade600,
      'cancelled': isDarkMode ? Colors.red.shade300 : Colors.red.shade600,
    };

    final statusColor = colorMap[status] ?? Colors.grey;

    // ====== LOGIC HIỆN NÚT DẪN ĐƯỜNG ======
    bool canNavigate = false;
    if (start != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOnly = DateTime(start.year, start.month, start.day);

      if (serviceType == 'tour') {
        // hôm nay / ngày mai / ngày kia
        final d1 = today.add(const Duration(days: 1));
        final d2 = today.add(const Duration(days: 2));
        if (!startOnly.isBefore(today) && !startOnly.isAfter(d2)) {
          canNavigate = true;
        }
      } else if (serviceType == 'hotel') {
        // chỉ đúng ngày checkin
        if (startOnly.isAtSameMomentAs(today)) {
          canNavigate = true;
        }
      }
    }

    final String navigateLabel =
        getTranslated('navigate_to_place', context) ?? 'Dẫn đường';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.6 : 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.black,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TourDetailScreen(tour: item),
                  ),
                );
              },
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    // Background image
                    Positioned.fill(
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade800,
                        ),
                      )
                          : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              oceanBlue,
                              lightOceanBlue,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Dark gradient bottom
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.9),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ====== HÀNG TRÊN: STATUS + NÚT DẪN ĐƯỜNG ======
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: [
                          // Status chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getStatusLabel(context, status),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (canNavigate && onNavigate != null)
                            InkWell(
                              onTap: () => onNavigate!(item),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.navigation_rounded,
                                      size: 14,
                                      color: Colors.black87,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      navigateLabel,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Main text bottom
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (subtitle.isNotEmpty)
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 13,
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule_rounded,
                                      size: 13,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$nights đêm',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(
                                      Icons.people_alt_rounded,
                                      size: 13,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$guests khách',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatMoney(total),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                serviceType == 'hotel' ? '/đêm' : '/tour',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
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
          ),
        ),
      ),
    );
  }
}