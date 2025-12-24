import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/airport_models.dart';
import '../screens/airport_picker_screen.dart';
import '../screens/flight_date_picker_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

class FlightSearchCriteria {
  final bool isRoundTrip;
  final int fromAirportId;
  final int toAirportId;
  final int? fromLocationId;
  final int? toLocationId;
  final String fromCity;
  final String fromCode;
  final String toCity;
  final String toCode;
  final DateTime departureDate;
  final DateTime? returnDate;
  final int adults;
  final int children;
  final int infants;
  final String cabinClass;

  const FlightSearchCriteria({
    required this.isRoundTrip,
    required this.fromAirportId,
    required this.toAirportId,
    required this.fromLocationId,
    required this.toLocationId,
    required this.fromCity,
    required this.fromCode,
    required this.toCity,
    required this.toCode,
    required this.departureDate,
    required this.returnDate,
    required this.adults,
    required this.children,
    required this.infants,
    required this.cabinClass,
  });

  int get totalPassengers => adults + children + infants;
}

class FlightSearchForm extends StatefulWidget {
  final Color headerBlue;
  final Future<void> Function(FlightSearchCriteria criteria) onSearch;

  const FlightSearchForm({
    super.key,
    required this.headerBlue,
    required this.onSearch,
  });

  @override
  State<FlightSearchForm> createState() => _FlightSearchFormState();
}

class _FlightSearchFormState extends State<FlightSearchForm> {
  AirportItem? _fromAirport;
  AirportItem? _toAirport;
  String fromCity = "Hồ Chí Minh";
  String fromCode = "SGN";
  String toCity = "Huế";
  String toCode = "HUI";
  DateTime? departureDate;
  DateTime? returnDate;
  int adults = 1;
  int children = 0;
  int infants = 0;
  String cabinClass = "Economy";

  String tr(String key, String fallback) {
    final v = getTranslated(key, context);
    if (v == null || v.isEmpty || v == key) return fallback;
    return v;
  }

  void _showWarning(String message) {
    final isDark = Provider.of<ThemeController>(context, listen: false).darkTheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isDark ? const Color(0xFFB91C1C) : Colors.red,
      ),
    );
  }

  void _applyFrom(AirportItem? a) {
    if (a == null) {
      fromCity = tr('flight_select_from', 'Chọn điểm đi');
      fromCode = '';
      return;
    }
    fromCity = a.location?.name ?? a.name;
    fromCode = a.code;
  }

  void _applyTo(AirportItem? a) {
    if (a == null) {
      toCity = tr('flight_select_to', 'Chọn điểm đến');
      toCode = '';
      return;
    }
    toCity = a.location?.name ?? a.name;
    toCode = a.code;
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return tr('flight_select_date', 'Chọn ngày');
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return "$y-$m-$day";
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickFromAirport() async {
    final picked = await Navigator.push<AirportItem>(
      context,
      MaterialPageRoute(
        builder: (_) => AirportPickerScreen(
          title: tr('flight_pick_from', 'Chọn sân bay đi'),
          selected: _fromAirport,
          disabledAirportId: _toAirport?.id,
        ),
      ),
    );

    if (picked == null) return;

    setState(() {
      _fromAirport = picked;
      fromCity = picked.location?.name ?? picked.name;
      fromCode = picked.code;

      if (_toAirport?.id == picked.id) {
        _toAirport = null;
        toCity = tr('flight_select_to', 'Chọn điểm đến');
        toCode = '';
      }
    });
  }

  Future<void> _pickToAirport() async {
    final picked = await Navigator.push<AirportItem>(
      context,
      MaterialPageRoute(
        builder: (_) => AirportPickerScreen(
          title: tr('flight_pick_to', 'Chọn sân bay đến'),
          selected: _toAirport,
          disabledAirportId: _fromAirport?.id,
        ),
      ),
    );

    if (picked == null) return;

    setState(() {
      _toAirport = picked;
      toCity = picked.location?.name ?? picked.name;
      toCode = picked.code;

      if (_fromAirport?.id == picked.id) {
        _fromAirport = null;
        fromCity = tr('flight_select_from', 'Chọn điểm đi');
        fromCode = '';
      }
    });
  }

  Future<void> _pickDepartureDate() async {
    final now = DateTime.now();

    final picked = await Navigator.of(context, rootNavigator: true).push<DateTimeRange>(
      MaterialPageRoute(
        builder: (_) => FlightDatePickerScreen(
          title: tr('flight_date_range', 'Select date range'),
          accentColor: widget.headerBlue,
          firstDate: now,
          lastDate: now.add(const Duration(days: 365)),
          initialStart: departureDate,
          initialEnd: returnDate,
        ),
      ),
    );

    if (picked == null) return;

    setState(() {
      departureDate = picked.start;
      returnDate = picked.end;
    });
  }

  void _showPassengersSheet() {
    final isDark = Provider.of<ThemeController>(context, listen: false).darkTheme;

    final bg = isDark ? const Color(0xFF0B1220) : Colors.white;
    final surface = isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
    final border = isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08);

    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub = isDark ? Colors.white70 : Colors.black54;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: isDark ? Colors.black54 : Colors.black26,
      builder: (_) {
        Widget counterRow({
          required String label,
          required int value,
          required VoidCallback onMinus,
          required VoidCallback onPlus,
        }) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textMain,
                    ),
                  ),
                ),

                // minus
                _RoundIconButton(
                  icon: Icons.remove,
                  onTap: onMinus,
                  isDark: isDark,
                ),

                const SizedBox(width: 10),

                SizedBox(
                  width: 34,
                  child: Text(
                    value.toString().padLeft(2, '0'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: textMain,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // plus
                _RoundIconButton(
                  icon: Icons.add,
                  onTap: onPlus,
                  isDark: isDark,
                ),
              ],
            ),
          );
        }

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: StatefulBuilder(
                builder: (ctx, setModal) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        tr('flight_passengers', 'Passengers'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: textMain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tr('flight_passengers_hint', 'Choose number of passengers'),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: textSub,
                        ),
                      ),
                      const SizedBox(height: 12),

                      counterRow(
                        label: tr('flight_adults', 'Adults'),
                        value: adults,
                        onMinus: () => setModal(() {
                          if (adults > 1) adults--;
                        }),
                        onPlus: () => setModal(() => adults++),
                      ),
                      const SizedBox(height: 10),

                      counterRow(
                        label: tr('flight_children', 'Children'),
                        value: children,
                        onMinus: () => setModal(() {
                          if (children > 0) children--;
                        }),
                        onPlus: () => setModal(() => children++),
                      ),
                      const SizedBox(height: 10),

                      counterRow(
                        label: tr('flight_infants', 'Infants'),
                        value: infants,
                        onMinus: () => setModal(() {
                          if (infants > 0) infants--;
                        }),
                        onPlus: () => setModal(() => infants++),
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {});
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.headerBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            tr('flight_done', 'Done'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showClassDialog() async {
    final isDark = Provider.of<ThemeController>(context, listen: false).darkTheme;

    final classes = const ["Economy", "Premium Economy", "Business", "First Class"];

    final bg = isDark ? const Color(0xFF0B1220) : Colors.white;
    final surface = isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
    final border = isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08);

    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub = isDark ? Colors.white70 : Colors.black54;

    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: isDark ? Colors.black54 : Colors.black26,
      builder: (_) {
        String temp = cabinClass;

        Widget optionTile(String value) {
          final selected = temp == value;

          final tileBg = selected ? widget.headerBlue.withOpacity(isDark ? 0.22 : 0.12) : surface;
          final tileBorder = selected ? widget.headerBlue.withOpacity(0.40) : border;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: tileBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tileBorder),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  // setState của StatefulBuilder ở dưới
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: selected
                              ? widget.headerBlue
                              : (isDark ? Colors.white.withOpacity(0.08) : Colors.white),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? Colors.transparent
                                : (isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)),
                          ),
                        ),
                        child: Icon(
                          selected ? Icons.check : Icons.work_outline,
                          size: 18,
                          color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black.withOpacity(0.65)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          value,
                          style: TextStyle(
                            color: textMain,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 120),
                        opacity: selected ? 1 : 0,
                        child: Icon(Icons.check_circle, color: widget.headerBlue, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return StatefulBuilder(
          builder: (ctx, setModal) {
            Widget optionTileBound(String value) {
              final selected = temp == value;

              final tileBg = selected ? widget.headerBlue.withOpacity(isDark ? 0.22 : 0.12) : surface;
              final tileBorder = selected ? widget.headerBlue.withOpacity(0.40) : border;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: tileBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tileBorder),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setModal(() => temp = value),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: selected
                                  ? widget.headerBlue
                                  : (isDark ? Colors.white.withOpacity(0.08) : Colors.white),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? Colors.transparent
                                    : (isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)),
                              ),
                            ),
                            child: Icon(
                              selected ? Icons.check : Icons.work_outline,
                              size: 18,
                              color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black.withOpacity(0.65)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              value,
                              style: TextStyle(
                                color: textMain,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 120),
                            opacity: selected ? 1 : 0,
                            child: Icon(Icons.check_circle, color: widget.headerBlue, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tr('flight_class', 'Cabin class'),
                              style: TextStyle(
                                color: textMain,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close, color: textSub),
                          ),
                        ],
                      ),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          tr('flight_class_hint', 'Choose your cabin class'),
                          style: TextStyle(
                            color: textSub,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      ...classes.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: optionTileBound(c),
                      )),

                      const SizedBox(height: 6),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, temp),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.headerBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            tr('flight_done', 'Done'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (picked == null) return;
    setState(() => cabinClass = picked);
  }

  Widget _swapButton({required VoidCallback onTap}) {
    final isDark = Provider.of<ThemeController>(context, listen: false).darkTheme;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: widget.headerBlue,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.swap_vert, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    bool compact = false,
    double rightPadding = 14,
  }) {
    final isDark = Provider.of<ThemeController>(context, listen: false).darkTheme;

    final bg = isDark ? const Color(0xFF111827) : const Color(0xFFF1F3F6);
    final titleColor = isDark ? Colors.white70 : Colors.black.withOpacity(0.55);
    final valueColor = isDark ? Colors.white : Colors.black.withOpacity(0.85);
    final iconBoxBg = isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.9);
    final iconColor = isDark ? Colors.white70 : Colors.black.withOpacity(0.70);

    final titleStyle = TextStyle(
      fontSize: compact ? 11 : 12,
      color: titleColor,
      fontWeight: FontWeight.w600,
    );

    final valueStyle = TextStyle(
      fontSize: compact ? 13 : 14,
      color: valueColor,
      fontWeight: FontWeight.w800,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: EdgeInsets.fromLTRB(
            12,
            compact ? 12 : 14,
            rightPadding,
            compact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBoxBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: titleStyle),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: valueStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_fromAirport == null) {
      _showWarning(tr('flight_warning_from_required', 'Vui lòng chọn sân bay đi.'));
      return;
    }
    if (_toAirport == null) {
      _showWarning(tr('flight_warning_to_required', 'Vui lòng chọn sân bay đến.'));
      return;
    }
    if (_fromAirport!.id == _toAirport!.id) {
      _showWarning(tr('flight_warning_diff_airport', 'Vui lòng chọn điểm đi và điểm đến khác nhau.'));
      return;
    }
    if (departureDate == null) {
      _showWarning(tr('flight_warning_departure_required', 'Vui lòng chọn ngày đi.'));
      return;
    }

    final fromLocId = _fromAirport!.location?.id;
    final toLocId   = _toAirport!.location?.id;
    if (fromLocId == null || toLocId == null) {
      _showWarning('Sân bay chưa có location_id. Kiểm tra API airports trả về location.id.');
      return;
    }
    final isRoundTrip = returnDate != null && !_isSameDay(departureDate!, returnDate!);

    final criteria = FlightSearchCriteria(
      isRoundTrip: isRoundTrip,
      fromAirportId: _fromAirport!.id,
      toAirportId: _toAirport!.id,
      fromLocationId: fromLocId,
      toLocationId: toLocId,
      fromCity: fromCity,
      fromCode: fromCode,
      toCity: toCity,
      toCode: toCode,
      departureDate: departureDate!,
      returnDate: returnDate,
      adults: adults,
      children: children,
      infants: infants,
      cabinClass: cabinClass,
    );

    await widget.onSearch(criteria);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeController>(context, listen: true).darkTheme;
    final cardBg = isDark ? const Color(0xFF0B1220) : Colors.white;
    final border = isDark ? Colors.white10 : Colors.transparent;
    final shadow = isDark
        ? <BoxShadow>[]
        : [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: shadow,
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Column(
                children: [
                  _tile(
                    icon: Icons.flight_takeoff,
                    title: tr('flight_from', 'From'),
                    value: _fromAirport == null
                        ? tr('flight_select_from', 'Chọn điểm đi')
                        : _fromAirport!.displayTitle,
                    onTap: _pickFromAirport,
                  ),

                  const SizedBox(height: 8),

                  _tile(
                    icon: Icons.flight_land,
                    title: tr('flight_to', 'To'),
                    value: _toAirport == null
                        ? tr('flight_select_to', 'Chọn điểm đến')
                        : _toAirport!.displayTitle,
                    onTap: _pickToAirport,
                  ),
                ],
              ),

              Positioned(
                top: 52,
                right: 26,
                child: _swapButton(
                  onTap: () {
                    if (_fromAirport == null || _toAirport == null) return;
                    setState(() {
                      final tmp = _fromAirport;
                      _fromAirport = _toAirport;
                      _toAirport = tmp;

                      _applyFrom(_fromAirport);
                      _applyTo(_toAirport);
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Listener(
            onPointerDown: (_) => debugPrint('Pointer down on calendar tile'),
            child: _tile(
              icon: Icons.calendar_month,
              title: tr('flight_departure_date', 'Departure'),
              value: departureDate == null
                  ? tr('flight_select_date_range', 'Select date range')
                  : (returnDate == null
                  ? _fmtDate(departureDate)
                  : "${_fmtDate(departureDate)} → ${_fmtDate(returnDate)}"),
              onTap: () {
                debugPrint('Tapped departure tile');
                _pickDepartureDate();
              },
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _tile(
                  icon: Icons.people_alt_outlined,
                  title: tr('flight_passengers', 'Passengers'),
                  value: "${(adults + children + infants)} ${tr('flight_adults', 'Adult')}",
                  onTap: _showPassengersSheet,
                  compact: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _tile(
                  icon: Icons.work_outline,
                  title: tr('flight_class', 'Class'),
                  value: cabinClass,
                  onTap: _showClassDialog,
                  compact: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.headerBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                tr('flight_search_btn', 'Search flights'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.06);
    final border = isDark ? Colors.white.withOpacity(0.14) : Colors.black.withOpacity(0.10);
    final fg = isDark ? Colors.white : const Color(0xFF0F172A);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: border),
          ),
          child: Icon(icon, size: 18, color: fg),
        ),
      ),
    );
  }
}