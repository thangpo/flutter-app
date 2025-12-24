import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

class FlightDatePickerScreen extends StatefulWidget {
  final String title;
  final Color accentColor;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final List<String> timeSlots;
  final String? initialTime;

  const FlightDatePickerScreen({
    super.key,
    required this.title,
    required this.accentColor,
    required this.firstDate,
    required this.lastDate,
    this.initialStart,
    this.initialEnd,
    this.timeSlots = const ['11:00', '13:00', '14:00', '17:00'],
    this.initialTime,
  });

  @override
  State<FlightDatePickerScreen> createState() => _FlightDatePickerScreenState();
}

class _FlightDatePickerScreenState extends State<FlightDatePickerScreen> {
  late DateTime _monthCursor;

  DateTime? _startDate;
  DateTime? _endDate;

  String? _selectedTime;

  String tr(String key, String fallback) {
    final v = getTranslated(key, context);
    if (v == null || v.isEmpty || v == key) return fallback;
    return v;
  }

  @override
  void initState() {
    super.initState();

    _startDate = widget.initialStart;
    _endDate = widget.initialEnd;
    _selectedTime = widget.initialTime;

    final base = widget.initialStart ?? DateTime.now();
    _monthCursor = DateTime(base.year, base.month, 1);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isInRange(DateTime d) {
    final dd = _dateOnly(d);
    final first = _dateOnly(widget.firstDate);
    final last = _dateOnly(widget.lastDate);
    return !dd.isBefore(first) && !dd.isAfter(last);
  }

  bool _isBetweenInclusive(DateTime d, DateTime start, DateTime end) {
    final dd = _dateOnly(d);
    final s = _dateOnly(start);
    final e = _dateOnly(end);
    return !dd.isBefore(s) && !dd.isAfter(e);
  }

  String _fmt(DateTime? d) {
    if (d == null) return tr('flight_select_date', 'Select date');
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return "$y-$m-$day";
  }

  String _monthTitle(DateTime m) {
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
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = first.weekday - 1;

    const totalCells = 42;
    final cells = List<DateTime?>.filled(totalCells, null);

    int day = 1;
    for (int i = leadingBlanks; i < totalCells && day <= daysInMonth; i++) {
      cells[i] = DateTime(month.year, month.month, day);
      day++;
    }
    return cells;
  }

  void _onPickDay(DateTime d) {
    if (!_isInRange(d)) return;

    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        _startDate = d;
        _endDate = null;
        return;
      }
      final s = _startDate!;
      final dd = _dateOnly(d);
      final ss = _dateOnly(s);

      if (dd.isBefore(ss)) {
        _endDate = _startDate;
        _startDate = d;
      } else {
        _endDate = d;
      }
    });
  }

  void _confirm() {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('flight_warning_date_range_required', 'Vui lòng chọn ngày bắt đầu và ngày kết thúc.'),
          ),
        ),
      );
      return;
    }

    final s = _dateOnly(_startDate!);
    final e = _dateOnly(_endDate!);

    if (e.isBefore(s)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('flight_warning_end_after_start', 'Ngày kết thúc phải lớn hơn hoặc bằng ngày bắt đầu.'),
          ),
        ),
      );
      return;
    }

    Navigator.pop(context, DateTimeRange(start: s, end: e));
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
    final rangeText = (_startDate == null && _endDate == null)
        ? tr('flight_select_date_range', 'Select start & end date')
        : (_startDate != null && _endDate == null)
        ? '${tr('flight_start_date', 'Start')}: ${_fmt(_startDate)} • ${tr('flight_pick_end', 'Pick end date')}'
        : '${_fmt(_startDate)} → ${_fmt(_endDate)}';

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
                            tr('flight_pick_date_title', 'Pick date range'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rangeText,
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

                            final isStart = _startDate != null && _isSameDay(d, _startDate!);
                            final isEnd = _endDate != null && _isSameDay(d, _endDate!);

                            final inSelectedRange = (_startDate != null && _endDate != null)
                                ? _isBetweenInclusive(d, _startDate!, _endDate!)
                                : false;

                            final bgColor = (isStart || isEnd)
                                ? widget.accentColor
                                : (inSelectedRange ? widget.accentColor.withOpacity(isDark ? 0.22 : 0.16) : Colors.transparent);

                            final fgColor = !inRange
                                ? (isDark ? Colors.white24 : Colors.black26)
                                : ((isStart || isEnd) ? Colors.white : textMain);

                            return InkWell(
                              onTap: !inRange ? null : () => _onPickDay(d),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${d.day}',
                                  style: TextStyle(
                                    color: fgColor,
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
                                  color: selected
                                      ? widget.accentColor
                                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
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