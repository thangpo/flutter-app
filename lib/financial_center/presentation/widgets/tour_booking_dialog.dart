import 'dart:ui';
import 'package:intl/intl.dart';
import '../models/booking_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';



class TourBookingDialog extends StatefulWidget {
  final Map<String, dynamic> tourData;
  const TourBookingDialog({super.key, required this.tourData});

  static Future<void> show(
      BuildContext context, Map<String, dynamic> tourData) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => TourBookingDialog(tourData: tourData),
    );
  }

  @override
  State<TourBookingDialog> createState() => _TourBookingDialogState();
}

class _TourBookingDialogState extends State<TourBookingDialog> {
  static const Color primaryOcean = Color(0xFF0077BE);
  static const Color lightOcean = Color(0xFF4DA6D6);
  static const Color paleOcean = Color(0xFFE3F2FD);
  static const Color darkPrimary = Color(0xFF64B5F6);
  static const Color darkSecondary = Color(0xFF42A5F5);

  late List<dynamic> personTypes;
  late List<dynamic> extras;
  late Map<String, int> quantities;
  late Map<String, bool> extrasSelected;

  DateTime? selectedDate;
  late DateTime _currentMonth;

  final NumberFormat _vndFormatter =
  NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    final bookingData = widget.tourData['booking_data'] ?? {};
    final rawPersonTypes = List.from(bookingData['person_types'] ?? []);
    final filtered = rawPersonTypes.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      if (name.contains('room') || name.contains('phòng')) return false;
      if (name.contains('adult') ||
          name.contains('người lớn') ||
          name.contains('child') ||
          name.contains('trẻ')) {
        return true;
      }
      return false;
    }).toList();

    personTypes = filtered.isNotEmpty ? filtered : rawPersonTypes;

    extras = List.from(bookingData['extra_price'] ?? []);

    quantities = {
      for (final p in personTypes)
        p['name'] as String: (p['number'] ?? 0) as int,
    };

    extrasSelected = {
      for (final e in extras)
        e['name'] as String: (e['enable'] ?? 0) == 1,
    };

    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
  }

  double _calculateTotal() {
    double total = double.tryParse(
      widget.tourData['sale_price']?.toString() ??
          widget.tourData['price']?.toString() ??
          '0',
    ) ??
        0.0;

    for (final p in personTypes) {
      final name = p['name'] as String;
      final price = double.tryParse(p['price'].toString()) ?? 0.0;
      total += (quantities[name] ?? 0) * price;
    }

    for (final e in extras) {
      final name = e['name'] as String;
      if (extrasSelected[name] == true) {
        total += double.tryParse(e['price'].toString()) ?? 0.0;
      }
    }
    return total;
  }

  void _confirmBooking(BuildContext context) {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            getTranslated('please_select_start_date', context) ??
                'Vui lòng chọn ngày bắt đầu',
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final booking = BookingData(
      tourId: widget.tourData['id'] ?? 0,
      tourName: widget.tourData['title'] ?? 'Không có tên',
      tourImage: widget.tourData['banner_image_url'] ?? '',
      startDate: selectedDate!,
      personCounts: Map<String, int>.from(quantities),
      extras: Map<String, bool>.from(extrasSelected),
      total: _calculateTotal(),
      numberOfPeople:
      quantities.values.fold<int>(0, (sum, val) => sum + val),
    );

    Navigator.pop(context);
    Navigator.pushNamed(
      context,
      '/booking-confirm',
      arguments: booking,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final sheetHeight = size.height * 0.9;
    final theme = Provider.of<ThemeController>(context, listen: false);
    final isDark = theme.darkTheme;
    final total = _calculateTotal();
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: sheetHeight,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: isDark
                    ? Colors.grey[900]!.withOpacity(0.92)
                    : Colors.white.withOpacity(0.98),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [darkPrimary, darkSecondary]
                              : [primaryOcean, lightOcean],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  getTranslated('book_tour', context) ??
                                      'book_tour',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.tourData['title'] ?? 'Tour',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getTranslated('dates', context) ?? 'Dates',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color:
                                isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),

                            _glassCard(
                              isDark,
                              child: _buildInlineCalendar(isDark),
                            ),

                            const SizedBox(height: 20),

                            Text(
                              getTranslated('guest_and_room', context) ??
                                  'Guest & Room',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color:
                                isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),

                            for (final p in personTypes) ...[
                              _glassCard(
                                isDark,
                                margin:
                                const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p['name'],
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            p['desc'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white60
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.grey[850]!
                                            .withOpacity(0.8)
                                            : Colors.grey[100],
                                        borderRadius:
                                        BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.remove,
                                              size: 18,
                                              color: isDark
                                                  ? darkPrimary
                                                  : primaryOcean,
                                            ),
                                            onPressed: () {
                                              final name =
                                              p['name'] as String;
                                              final min = p['min'] ?? 0;
                                              if (quantities[name]! > min) {
                                                setState(() =>
                                                quantities[name] =
                                                    quantities[name]! -
                                                        1);
                                              }
                                            },
                                          ),
                                          Text(
                                            '${quantities[p['name']]}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.add,
                                              size: 18,
                                              color: isDark
                                                  ? darkPrimary
                                                  : primaryOcean,
                                            ),
                                            onPressed: () {
                                              final name =
                                              p['name'] as String;
                                              final max = p['max'] ?? 10;
                                              if (quantities[name]! < max) {
                                                setState(() =>
                                                quantities[name] =
                                                    quantities[name]! +
                                                        1);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            if (extras.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                getTranslated(
                                    'extra_services', context) ??
                                    'Extra services',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              for (final e in extras)
                                _glassCard(
                                  isDark,
                                  margin:
                                  const EdgeInsets.only(bottom: 8),
                                  child: CheckboxListTile(
                                    value: extrasSelected[e['name']],
                                    title: Text(
                                      e['name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    subtitle: Text(
                                      e['price_html'],
                                      style: TextStyle(
                                        color: isDark
                                            ? darkPrimary
                                            : primaryOcean,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onChanged: (val) {
                                      setState(
                                            () => extrasSelected[e['name']] =
                                            val ?? false,
                                      );
                                    },
                                    activeColor: isDark
                                        ? darkPrimary
                                        : primaryOcean,
                                    controlAffinity:
                                    ListTileControlAffinity.leading,
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    Container(
                      padding:
                      const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(0.9)
                            : Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.06),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                getTranslated('total', context) ??
                                    'Total',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _vndFormatter.format(total),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? darkPrimary
                                      : primaryOcean,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 160,
                            child: ElevatedButton(
                              onPressed: () => _confirmBooking(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? darkPrimary
                                    : primaryOcean,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(18),
                                ),
                              ),
                              child: Text(
                                getTranslated(
                                    'confirm_booking', context) ??
                                    'Buy',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
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
          ),
        ),
      ),
    );
  }

  // ====== INLINE CALENDAR (chọn 1 ngày) ======
  Widget _buildInlineCalendar(bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth =
    DateTime(_currentMonth.year, _currentMonth.month, 1);

    final int startWeekday = (firstDayOfMonth.weekday % 7);
    final totalItems = startWeekday + daysInMonth;

    final monthLabel =
        '${_monthName(_currentMonth.month)}, ${_currentMonth.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // header month + arrows
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              splashRadius: 20,
              onPressed: () {
                final previous =
                DateTime(_currentMonth.year, _currentMonth.month - 1);
                if (previous.isBefore(DateTime(today.year, today.month))) {
                  return;
                }
                setState(() {
                  _currentMonth = previous;
                });
              },
            ),
            Text(
              monthLabel,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              splashRadius: 20,
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(
                      _currentMonth.year, _currentMonth.month + 1);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),

        // weekday labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _WeekdayLabel('Sun'),
            _WeekdayLabel('Mon'),
            _WeekdayLabel('Tue'),
            _WeekdayLabel('Wed'),
            _WeekdayLabel('Thu'),
            _WeekdayLabel('Fri'),
            _WeekdayLabel('Sat'),
          ],
        ),
        const SizedBox(height: 6),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: totalItems,
          itemBuilder: (context, index) {
            if (index < startWeekday) {
              return const SizedBox.shrink();
            }
            final dayNumber = index - startWeekday + 1;
            final date = DateTime(
                _currentMonth.year, _currentMonth.month, dayNumber);

            final bool isPast = date.isBefore(today);
            final bool isSelected = selectedDate != null &&
                date.year == selectedDate!.year &&
                date.month == selectedDate!.month &&
                date.day == selectedDate!.day;

            Color bgColor = Colors.transparent;
            Color textColor =
            isDark ? Colors.white70 : Colors.black87;

            if (isSelected) {
              bgColor = isDark ? darkPrimary : primaryOcean;
              textColor = Colors.white;
            } else if (isPast) {
              textColor =
              isDark ? Colors.white24 : Colors.grey.shade400;
            }

            return GestureDetector(
              onTap: isPast
                  ? null
                  : () {
                setState(() {
                  selectedDate = date;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$dayNumber',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }

  Widget _glassCard(bool isDark,
      {required Widget child, EdgeInsets? margin}) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey[800]!.withOpacity(0.4)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.15)
              : lightOcean.withOpacity(0.2),
          width: 1.2,
        ),
      ),
      child: child,
    );
  }
}

// Label thứ trong tuần
class _WeekdayLabel extends StatelessWidget {
  final String text;
  const _WeekdayLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}