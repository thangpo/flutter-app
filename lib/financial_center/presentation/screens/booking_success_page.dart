import 'dart:ui'; // BackdropFilter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:provider/provider.dart';

class BookingSuccessPage extends StatefulWidget {
  final Map<String, dynamic> bookingInfo;

  const BookingSuccessPage({super.key, required this.bookingInfo});

  @override
  State<BookingSuccessPage> createState() => _BookingSuccessPageState();
}

class _BookingSuccessPageState extends State<BookingSuccessPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late NumberFormat _vndFormatter;

  @override
  void initState() {
    super.initState();

    _vndFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int _calculateDays(String? start, String? end) {
    if (start == null || end == null) return 0;
    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      return e.difference(s).inDays + 1;
    } catch (_) {
      return 0;
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'N/A') return 'N/A';
    try {
      final d = DateTime.parse(raw);
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      final yyyy = d.year.toString();
      return '$dd/$mm/$yyyy';
    } catch (_) {
      return raw;
    }
  }

  String _t(String key, String fallback) {
    return getTranslated(key, context) ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.bookingInfo;

    final themeCtrl = Provider.of<ThemeController>(context, listen: true);
    final bool isDark = themeCtrl.darkTheme;

    final String tourImage =
    (info['tour_image'] ?? info['image'] ?? info['tour']?['image'] ?? '')
        .toString();
    final String tourName =
    (info['tour_name'] ?? info['title'] ?? _t('your_trip', 'Your trip'))
        .toString();
    final String location =
    (info['location'] ?? info['address'] ?? '').toString();

    final String code = (info['code'] ?? '').toString();

    final String startRaw = (info['start_date'] ?? 'N/A').toString();
    final String endRaw = (info['end_date'] ?? 'N/A').toString();

    final String startDate = _formatDate(startRaw);
    final String endDate = _formatDate(endRaw);

    final String guests =
    (info['total_guests'] != null) ? '${info['total_guests']}' : '-';

    String total;
    if (info['total'] != null) {
      final num? value = num.tryParse(info['total'].toString());
      total = value != null
          ? _vndFormatter.format(value)
          : info['total'].toString();
    } else {
      total = 'N/A';
    }

    final int days = _calculateDays(info['start_date'], info['end_date']);

    final String description = (info['tour_description'] ??
        _t('booking_success_desc',
            'Đặt tour của bạn đã được xác nhận. '
                'Hãy chuẩn bị hành lý và tận hưởng chuyến đi sắp tới!'))
        .toString();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: tourImage.isNotEmpty
                ? Image.network(
              tourImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade400,
                alignment: Alignment.center,
                child: Icon(Icons.image_not_supported,
                    size: 40, color: Colors.grey.shade700),
              ),
            )
                : Container(
              color: Colors.grey.shade400,
              alignment: Alignment.center,
              child: Icon(Icons.image_not_supported,
                  size: 40, color: Colors.grey.shade700),
            ),
          ),

          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.2),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(isDark ? 0.45 : 0.32),
                      borderRadius: BorderRadius.circular(28),
                      border:
                      Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tourName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (location.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.place,
                                  size: 16, color: Colors.white70),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 8),

                        if (code.isNotEmpty)
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text(
                                        _t('booking_code_copied',
                                            'Đã sao chép mã đặt tour'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor:
                                  Colors.black.withOpacity(0.85),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  const Icon(Icons.confirmation_number,
                                      size: 14, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      code,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            _InfoChip(
                              icon: Icons.calendar_today,
                              label: _t('start_date', 'Start'),
                              value: startDate,
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              icon: Icons.event,
                              label: _t('end_date', 'End'),
                              value: endDate,
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            _InfoChip(
                              icon: Icons.people_alt_rounded,
                              label: _t('guests', 'Guests'),
                              value: guests,
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              icon: Icons.schedule,
                              label: _t('days', 'Days'),
                              value: days > 0 ? '$days' : '-',
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _t('total', 'Total'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              total,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Text(
                          _t('description', 'Description'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: const StadiumBorder(),
                              elevation: 0,
                            ),
                            child: Text(
                              _t('back_to_home', 'Về trang chủ'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}