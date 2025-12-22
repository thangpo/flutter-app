import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:provider/provider.dart';

class FlightSearchCriteria {
  final bool isRoundTrip;
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
  String fromCity = "Hồ Chí Minh";
  String fromCode = "SGN";
  String toCity = "Huế";
  String toCode = "HUI";

  DateTime? departureDate;

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

  String _fmtDate(DateTime? d) {
    if (d == null) return tr('flight_select_date', 'Chọn ngày');
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return "$y-$m-$day";
  }

  Future<void> _pickDepartureDate() async {
    final isDark = Provider.of<ThemeController>(context, listen: false).darkTheme;
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: departureDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) {
        final base = Theme.of(ctx);
        final scheme = (isDark ? const ColorScheme.dark() : const ColorScheme.light())
            .copyWith(primary: widget.headerBlue);
        return Theme(
          data: base.copyWith(
            colorScheme: scheme,
            dialogBackgroundColor: isDark ? const Color(0xFF0B1220) : Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    setState(() => departureDate = picked);
  }

  void _showPassengersSheet() {
    final isDark = Provider.of<ThemeController>(context, listen: false).darkTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0B1220) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        Widget row(
            String label,
            int value,
            VoidCallback onMinus,
            VoidCallback onPlus,
            ) {
          final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
          final iconColor = isDark ? Colors.white70 : Colors.black54;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textMain),
                  ),
                ),
                IconButton(
                  onPressed: onMinus,
                  icon: Icon(Icons.remove_circle_outline, color: iconColor),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    value.toString().padLeft(2, '0'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textMain),
                  ),
                ),
                IconButton(
                  onPressed: onPlus,
                  icon: Icon(Icons.add_circle_outline, color: iconColor),
                ),
              ],
            ),
          );
        }

        return StatefulBuilder(
          builder: (ctx, setModal) {
            final textMain = isDark ? Colors.white : const Color(0xFF0F172A);

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
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
                  Text(
                    tr('flight_passengers', 'Hành khách'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textMain),
                  ),
                  const SizedBox(height: 10),

                  row(
                    tr('flight_adults', 'Người lớn'),
                    adults,
                        () => setModal(() {
                      if (adults > 1) adults--;
                    }),
                        () => setModal(() => adults++),
                  ),
                  row(
                    tr('flight_children', 'Trẻ em'),
                    children,
                        () => setModal(() {
                      if (children > 0) children--;
                    }),
                        () => setModal(() => children++),
                  ),
                  row(
                    tr('flight_infants', 'Em bé'),
                    infants,
                        () => setModal(() {
                      if (infants > 0) infants--;
                    }),
                        () => setModal(() => infants++),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.headerBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(tr('flight_done', 'Xong')),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showClassDialog() async {
    final isDark = Provider.of<ThemeController>(context, listen: false).darkTheme;
    final classes = ["Economy", "Premium Economy", "Business", "First Class"];

    final selected = await showDialog<String>(
      context: context,
      builder: (_) {
        final textMain = isDark ? Colors.white : const Color(0xFF0F172A);

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0B1220) : Colors.white,
          title: Text(tr('flight_class', 'Hạng vé'), style: TextStyle(color: textMain)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: classes
                .map(
                  (c) => RadioListTile<String>(
                value: c,
                groupValue: cabinClass,
                activeColor: widget.headerBlue,
                onChanged: (v) => Navigator.pop(context, v),
                title: Text(c, style: TextStyle(color: textMain)),
              ),
            )
                .toList(),
          ),
        );
      },
    );

    if (selected == null) return;
    setState(() => cabinClass = selected);
  }

  Widget _swapButton({required VoidCallback onTap}) {
    final isDark = Provider.of<ThemeController>(context, listen: false).darkTheme;

    // Nút nổi rõ ở cả dark/light
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
    );
  }

  Future<void> _submit() async {
    if (fromCode == toCode) {
      _showWarning(tr('flight_warning_diff_airport', 'Vui lòng chọn điểm đi và điểm đến khác nhau.'));
      return;
    }
    if (departureDate == null) {
      _showWarning(tr('flight_warning_departure_required', 'Vui lòng chọn ngày đi.'));
      return;
    }

    final criteria = FlightSearchCriteria(
      isRoundTrip: false,
      fromCity: fromCity,
      fromCode: fromCode,
      toCity: toCity,
      toCode: toCode,
      departureDate: departureDate!,
      returnDate: null,
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
          // FROM/TO + SWAP (nút nằm giữa 2 tile và đẩy sang trái)
          Stack(
            children: [
              Column(
                children: [
                  _tile(
                    icon: Icons.flight_takeoff,
                    title: tr('flight_from', 'From'),
                    value: "$fromCity, $fromCode",
                    onTap: () {
                      // TODO: chọn sân bay đi
                    },
                  ),
                  const SizedBox(height: 10),
                  _tile(
                    icon: Icons.flight_land,
                    title: tr('flight_to', 'To'),
                    value: "$toCity, $toCode",
                    onTap: () {
                      // TODO: chọn sân bay đến
                    },
                  ),
                ],
              ),

              // Nút swap: đè lên giữa 2 tile, và "qua trái" theo icon box
              Positioned(
                top: 52,
                right: 26, // Bố chỉnh 20~40 tuỳ thích
                child: _swapButton(
                  onTap: () {
                    setState(() {
                      final tmpCity = fromCity;
                      final tmpCode = fromCode;
                      fromCity = toCity;
                      fromCode = toCode;
                      toCity = tmpCity;
                      toCode = tmpCode;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _tile(
            icon: Icons.calendar_month,
            title: tr('flight_departure_date', 'Departure'),
            value: departureDate == null
                ? tr('flight_select_date', 'Select date')
                : _fmtDate(departureDate),
            onTap: _pickDepartureDate,
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