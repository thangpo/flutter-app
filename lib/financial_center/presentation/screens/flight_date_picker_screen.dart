import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

class FlightDatePickerScreen extends StatefulWidget {
  final String title;
  final Color accentColor;

  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  // UI giống ảnh có phần time slots (tuỳ chọn)
  final List<String> timeSlots;
  final String? initialTime;

  const FlightDatePickerScreen({
    super.key,
    required this.title,
    required this.accentColor,
    required this.firstDate,
    required this.lastDate,
    this.initialDate,
    this.timeSlots = const ['11:00', '13:00', '14:00', '17:00'],
    this.initialTime,
  });

  @override
  State<FlightDatePickerScreen> createState() => _FlightDatePickerScreenState();
}

class _FlightDatePickerScreenState extends State<FlightDatePickerScreen> {
  late DateTime _monthCursor; // đang xem tháng nào
  DateTime? _selectedDate;
  String? _selectedTime;

  String tr(String key, String fallback) {
    final v = getTranslated(key, context);
    if (v == null || v.isEmpty || v == key) return fallback;
    return v;
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedTime = widget.initialTime;

    final base = widget.initialDate ?? DateTime.now();
    _monthCursor = DateTime(base.year, base.month, 1);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isInRange(DateTime d) {
    final dd = DateTime(d.year, d.month, d.day);
    final first = DateTime(widget.firstDate.year, widget.firstDate.month, widget.firstDate.day);
    final last = DateTime(widget.lastDate.year, widget.lastDate.month, widget.lastDate.day);
    return !dd.isBefore(first) && !dd.isAfter(last);
  }

  String _monthTitle(DateTime m) {
    // January 2020 style
    final months = <String>[
      tr('month_jan', 'January'),
      tr('month_feb', 'February'),
      tr('month_mar', 'March'),
      tr('month_apr', 'April'),
      tr('month_may', 'May'),
      tr('month_jun', 'June'),
      tr('month_jul', 'July'),
      tr('month_aug', 'August'),
      tr('month_sep', 'September'),
      tr('month_oct', 'October'),
      tr('month_nov', 'November'),
      tr('month_dec', 'December'),
    ];
    return '${months[m.month - 1]} ${m.year}';
  }

  void _prevMonth() {
    setState(() {
      _monthCursor = DateTime(_monthCursor.year, _monthCursor.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _monthCursor = DateTime(_monthCursor.year, _monthCursor.month + 1, 1);
    });
  }

  List<DateTime?> _buildMonthCells(DateTime month) {
    // Monday-first: Mon..Sun (giống ảnh M T W T F S S)
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final leadingBlanks = first.weekday - 1; // Mon=1 => 0 blank
    final totalCells = 42; // 6 weeks * 7

    final cells = List<DateTime?>.filled(totalCells, null);

    int day = 1;
    for (int i = leadingBlanks; i < totalCells && day <= daysInMonth; i++) {
      cells[i] = DateTime(month.year, month.month, day);
      day++;
    }
    return cells;
  }

  void _confirm() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('flight_warning_departure_required', 'Vui lòng chọn ngày đi.'))),
      );
      return;
    }
    Navigator.pop(context, _selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeController>(context, listen: true).darkTheme;

    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF6F7FB);
    final card = isDark ? const Color(0xFF111827) : Colors.white;
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub = isDark ? Colors.white70 : Colors.black54;
    final divider = isDark ? Colors.white10 : Colors.black12;

    final cells = _buildMonthCells(_monthCursor);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        foregroundColor: textMain,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top “doctor card” style (giống ảnh) — dùng làm header info
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('flight_pick_date_title', 'Pick departure date'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedDate == null
                                ? tr('flight_select_date', 'Select date')
                                : '${_selectedDate!.year.toString().padLeft(4, '0')}-'
                                '${_selectedDate!.month.toString().padLeft(2, '0')}-'
                                '${_selectedDate!.day.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.95)),
                  ],
                ),
              ),
            ),

            // Calendar card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: isDark
                        ? const []
                        : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(color: divider),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 14),

                      // Month header with arrows
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _prevMonth,
                              icon: Icon(Icons.chevron_left, color: textMain),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  _monthTitle(_monthCursor),
                                  style: TextStyle(
                                    color: textMain,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _nextMonth,
                              icon: Icon(Icons.chevron_right, color: textMain),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Weekday labels (M T W T F S S)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            for (final w in [
                              tr('weekday_mon_short', 'M'),
                              tr('weekday_tue_short', 'T'),
                              tr('weekday_wed_short', 'W'),
                              tr('weekday_thu_short', 'T'),
                              tr('weekday_fri_short', 'F'),
                              tr('weekday_sat_short', 'S'),
                              tr('weekday_sun_short', 'S'),
                            ])
                              Expanded(
                                child: Center(
                                  child: Text(
                                    w,
                                    style: TextStyle(
                                      color: textSub,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Calendar grid
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cells.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                            childAspectRatio: 1.1,
                          ),
                          itemBuilder: (_, i) {
                            final d = cells[i];
                            if (d == null) return const SizedBox.shrink();

                            final inRange = _isInRange(d);
                            final isSelected = _selectedDate != null && _isSameDay(d, _selectedDate!);

                            final fg = !inRange
                                ? (isDark ? Colors.white24 : Colors.black26)
                                : (isSelected ? Colors.white : textMain);

                            return InkWell(
                              onTap: !inRange
                                  ? null
                                  : () {
                                setState(() => _selectedDate = d);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected ? widget.accentColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${d.day}',
                                  style: TextStyle(
                                    color: fg,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 10),
                      Divider(height: 1, color: divider),
                      const SizedBox(height: 10),

                      // Available times (giống ảnh) — tuỳ chọn dùng hay không
                      Text(
                        tr('flight_available_times', 'Available Times'),
                        style: TextStyle(
                          color: textSub,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: widget.timeSlots.map((t) {
                            final selected = _selectedTime == t;
                            return InkWell(
                              onTap: () => setState(() => _selectedTime = t),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected ? widget.accentColor : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: selected ? Colors.transparent : divider),
                                ),
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    color: selected ? Colors.white : textMain,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const Spacer(),

                      // Bottom button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _confirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.accentColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              tr('flight_confirm_date', 'Confirm'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
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
          ],
        ),
      ),
    );
  }
}