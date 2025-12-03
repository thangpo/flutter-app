import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../screens/flight_detail_screen.dart';

class FlightListItem extends StatelessWidget {
  final String flightId;
  final String airline;
  final String from;
  final String to;
  final String departure;
  final String arrival;
  final String price;
  final String cabinClass;
  final String baggage;
  final String availability;
  final String? logoUrl;

  const FlightListItem({
    super.key,
    required this.flightId,
    required this.airline,
    required this.from,
    required this.to,
    required this.departure,
    required this.arrival,
    required this.price,
    required this.cabinClass,
    required this.baggage,
    required this.availability,
    this.logoUrl,
  });

  // ====== Format helpers ======

  String formatPrice(String price) {
    try {
      String numericPrice = price.replaceAll(RegExp(r'[^0-9.,]'), '');
      if (numericPrice.isEmpty) return price;
      numericPrice = numericPrice.replaceAll(',', '.');
      final priceUSD = double.parse(numericPrice);
      final int priceVND = (priceUSD * 26000).round();
      final formatter = NumberFormat('#,###', 'vi_VN');
      return '${formatter.format(priceVND)} ₫';
    } catch (_) {
      return price;
    }
  }

  String formatDateTime(String dateTime) {
    try {
      DateTime dt;
      if (dateTime.contains('T')) {
        dt = DateTime.parse(dateTime);
      } else if (dateTime.contains('/')) {
        final parts = dateTime.split(' ');
        final dateParts = parts[0].split('/');
        if (dateParts.length == 3) {
          dt = DateTime(
            int.parse(dateParts[2]),
            int.parse(dateParts[1]),
            int.parse(dateParts[0]),
          );
          if (parts.length > 1) {
            final timeParts = parts[1].split(':');
            dt = DateTime(
              dt.year,
              dt.month,
              dt.day,
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
            );
          }
        } else {
          return dateTime;
        }
      } else {
        return dateTime;
      }

      final timeFormat = DateFormat('HH:mm', 'vi_VN');
      final dateFormat = DateFormat('dd/MM/yyyy', 'vi_VN');
      return '${timeFormat.format(dt)}, ${dateFormat.format(dt)}';
    } catch (_) {
      return dateTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const Color primary = Color(0xFF00BCD4);
    const Color primaryDark = Color(0xFF0097A7);

    final Color outerStart =
    isDark ? const Color(0xFF022C22) : primary;
    final Color outerEnd =
    isDark ? const Color(0xFF014451) : primaryDark;

    final Color cardBg =
    isDark ? const Color(0xFF020617) : Colors.white;
    final Color titleColor =
    isDark ? Colors.white : const Color(0xFF00838F);
    final Color subtitleColor =
    isDark ? Colors.white70 : Colors.grey[600]!;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlightDetailScreen(flightId: flightId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [outerStart, outerEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(isDark ? 0.35 : 0.30),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ====== Header: logo + hãng + giá ======
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        if (logoUrl != null && logoUrl!.endsWith('.svg'))
                          SvgPicture.network(
                            logoUrl!,
                            width: 40,
                            height: 40,
                            placeholderBuilder: (context) =>
                                Icon(Icons.flight, color: primaryDark),
                          )
                        else if (logoUrl != null && logoUrl!.isNotEmpty)
                          Image.network(
                            logoUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.flight, color: primaryDark),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [outerStart, outerEnd],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.flight_takeoff,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 80,
                          child: Text(
                            airline,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: primaryDark,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    const Spacer(),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE0E0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        formatPrice(price),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ====== Route & time ======
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            from,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatDateTime(departure),
                            style: TextStyle(
                              fontSize: 12,
                              color: subtitleColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF022C22)
                                  : const Color(0xFFE0F7FA),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward,
                              color: primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 2,
                            width: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [outerStart, outerEnd],
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            to,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatDateTime(arrival),
                            style: TextStyle(
                              fontSize: 12,
                              color: subtitleColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ====== Info chips (no overflow) ======
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF02131A)
                        : const Color(0xFFE0F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildInfoChip(
                        icon: Icons.event_seat,
                        text: availability,
                        color: titleColor,
                        bold: true,
                        isDark: isDark,
                      ),
                      _buildInfoChip(
                        icon: Icons.luggage,
                        text: baggage,
                        color: titleColor,
                        isDark: isDark,
                      ),
                      _buildInfoChip(
                        icon: Icons.business_center,
                        text: cabinClass,
                        color: titleColor,
                        isDark: isDark,
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
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
    bool bold = false,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}