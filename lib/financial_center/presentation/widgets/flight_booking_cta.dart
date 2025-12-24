import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/flight_data_models.dart';
import '../widgets/fade_route.dart';
import '../screens/checkout_transition_video.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

class SeatPickResult {
  final FlightSeat seat;
  final int passengers;

  const SeatPickResult({
    required this.seat,
    required this.passengers,
  });
}

class FlightBookingCTA extends StatelessWidget {
  final bool enabled;
  final String priceText;
  final VoidCallback? onTap;

  const FlightBookingCTA({
    super.key,
    required this.enabled,
    required this.priceText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeController>(context, listen: true).darkTheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final labelPrice = getTranslated('price', context) ?? 'Giá vé';
    final labelBook = getTranslated('book_now', context) ?? 'Đặt vé';
    final accent = isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: bg,
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, -8),
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    labelPrice,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    priceText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: enabled ? onTap : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    disabledBackgroundColor: isDark ? Colors.white12 : Colors.black12,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    labelBook,
                    style: const TextStyle(fontWeight: FontWeight.w900),
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

Future<SeatPickResult?> showSeatClassPickerSheet({
  required BuildContext context,
  required List<FlightSeat> seats,
  required String airlineName,
  required String fromCode,
  required String toCode,
  required String departTimeText,
  required String arriveTimeText,
  required String flightCode,
  int initialPassengers = 1,
}) async {
  if (seats.isEmpty) return null;

  return showModalBottomSheet<SeatPickResult?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return _SeatClassPickerSheet(
        seats: seats,
        airlineName: airlineName,
        fromCode: fromCode,
        toCode: toCode,
        departTimeText: departTimeText,
        arriveTimeText: arriveTimeText,
        flightCode: flightCode,
        initialPassengers: initialPassengers < 1 ? 1 : initialPassengers,
      );
    },
  );
}

class _SeatClassPickerSheet extends StatefulWidget {
  final List<FlightSeat> seats;
  final String airlineName;
  final String fromCode;
  final String toCode;
  final String departTimeText;
  final String arriveTimeText;
  final String flightCode;
  final int initialPassengers;

  const _SeatClassPickerSheet({
    required this.seats,
    required this.airlineName,
    required this.fromCode,
    required this.toCode,
    required this.departTimeText,
    required this.arriveTimeText,
    required this.flightCode,
    required this.initialPassengers,
  });

  @override
  State<_SeatClassPickerSheet> createState() => _SeatClassPickerSheetState();
}

class _SeatClassPickerSheetState extends State<_SeatClassPickerSheet> {
  late final PageController _pageController;
  late int _index;
  late FlightSeat _selected;
  late int _passengers;
  double _sheetOpacity = 1.0;
  bool _navigating = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _index = 0;
    _selected = widget.seats.first;
    _passengers = widget.initialPassengers;
    _pageController = PageController(initialPage: 0);
    _validate();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSeatChanged(int newIndex) {
    setState(() {
      _index = newIndex;
      _selected = widget.seats[newIndex];
      _errorText = null;
    });
    _validate();
  }

  int _remain(FlightSeat s) => (s.maxPassengers ?? 0);

  void _validate() {
    final remain = _remain(_selected);
    final labelNotEnough = getTranslated('not_enough_seats', context) ?? 'Số vé còn lại không đủ.';
    setState(() {
      if (remain > 0 && _passengers > remain) {
        _errorText = '$labelNotEnough ($remain)';
      } else {
        _errorText = null;
      }
    });
  }

  void _inc() {
    setState(() => _passengers += 1);
    _validate();
  }

  void _dec() {
    if (_passengers <= 1) return;
    setState(() => _passengers -= 1);
    _validate();
  }

  double? _priceToDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  String _formatVnd(double value) {
    final n = value.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < n.length; i++) {
      final pos = n.length - i;
      buf.write(n[i]);
      if (pos > 1 && pos % 3 == 1) buf.write('.');
    }
    return '${buf.toString()} ₫';
  }

  String _seatPriceText(FlightSeat s) {
    final html = (s.priceHtml ?? '').trim();
    if (html.isNotEmpty) return html;
    final p = _priceToDouble(s.price);
    if (p == null) return '-';
    return _formatVnd(p);
  }

  Future<void> _goCheckoutWithFade(FlightCheckoutArgs args) async {
    if (_navigating) return;

    setState(() {
      _navigating = true;
      _sheetOpacity = 0.0; // mờ dần nội dung sheet
    });

    // Đợi animation mờ dần xong
    await Future.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;

    final rootNav = Navigator.of(context, rootNavigator: true);

    // Đóng bottom sheet
    rootNav.pop();

    // Đợi 1 frame cho việc pop hoàn tất rồi mới push
    WidgetsBinding.instance.addPostFrameCallback((_) {
      rootNav.push(
        fadeRoute(CheckoutTransitionVideoScreen(args: args)),
      );
    });
  }

  String _seatName(FlightSeat s) => s.seatType?.name ?? (getTranslated('seat_class', context) ?? 'Hạng vé');

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeController>(context, listen: true).darkTheme;
    final h = MediaQuery.sizeOf(context).height;
    final sheetH = (h * 0.90).clamp(560.0, 900.0);
    final accent = isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
    final bg = isDark ? const Color(0xFF0E1621) : const Color(0xFFF6F6F7);
    final cardBg = isDark ? const Color(0xFF121E2C) : Colors.white;
    final textMain = isDark ? Colors.white : Colors.black;
    final textSub = (isDark ? Colors.white : Colors.black).withOpacity(0.55);
    final border = isDark ? Colors.white12 : Colors.black12;
    final title = getTranslated('upgrade_ticket', context) ?? 'Nâng hạng vé';
    final tripLabel = getTranslated('trip', context) ?? 'Chuyến đi';
    final directLabel = getTranslated('direct_flight', context) ?? 'Bay thẳng';
    final conditionsLabel = getTranslated('see_ticket_conditions', context) ?? 'Xem điều kiện vé';
    final passengersLabel = getTranslated('passengers', context) ?? 'Số hành khách';
    final priceLabel = getTranslated('price', context) ?? 'Giá vé';
    final perPaxLabel = getTranslated('per_passenger', context) ?? '/ 1 hành khách';
    final bookLabel = getTranslated('book_now', context) ?? 'Đặt vé';
    final remainLabel = getTranslated('remaining', context) ?? 'Còn';
    final remain = _remain(_selected);
    final canSubmit = (_errorText == null) && (_passengers >= 1) && (remain == 0 ? true : _passengers <= remain);

    return SafeArea(
      child: IgnorePointer(
        ignoring: _navigating, // đang chuyển trang thì khóa thao tác
        child: AnimatedOpacity(
          opacity: _sheetOpacity,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: sheetH,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 10, 6),
                    child: Row(
                      children: [
                        const SizedBox(width: 40),
                        Expanded(
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textMain),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: textMain),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                            color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.flight_takeoff, size: 20, color: textMain),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.airlineName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontWeight: FontWeight.w900, color: textMain),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tripLabel,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textSub),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _seatPriceText(_selected),
                                style: TextStyle(fontWeight: FontWeight.w900, color: textMain),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _TimeCodeBlock(
                                time: widget.departTimeText,
                                code: widget.fromCode,
                                textMain: textMain,
                                textSub: textSub,
                              ),
                              const Spacer(),
                              Column(
                                children: [
                                  Text(
                                    '${widget.fromCode}  →  ${widget.toCode}',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textSub),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    directLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: textSub.withOpacity(0.85),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              _TimeCodeBlock(
                                time: widget.arriveTimeText,
                                code: widget.toCode,
                                alignRight: true,
                                textMain: textMain,
                                textSub: textSub,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              conditionsLabel,
                              style: TextStyle(color: accent, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: List.generate(widget.seats.length, (i) {
                              final active = i == _index;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(right: 6),
                                width: active ? 18 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: active ? accent : border,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          passengersLabel,
                          style: TextStyle(fontWeight: FontWeight.w900, color: textMain),
                        ),
                        const SizedBox(width: 10),
                        _Stepper(
                          value: _passengers,
                          onMinus: _dec,
                          onPlus: _inc,
                          isDark: isDark,
                          accent: accent,
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: widget.seats.length,
                      onPageChanged: _onSeatChanged,
                      itemBuilder: (_, i) {
                        final s = widget.seats[i];
                        final selected = s.id == _selected.id;

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: _SeatFullPageCard(
                            seat: s,
                            selected: selected,
                            seatName: _seatName(s),
                            seatPrice: _seatPriceText(s),
                            remainText: '$remainLabel: ${_remain(s)}',
                            isDark: isDark,
                            accent: accent,
                            cardBg: cardBg,
                            textMain: textMain,
                            textSub: textSub,
                            border: border,
                          ),
                        );
                      },
                    ),
                  ),

                  if ((_errorText ?? '').trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 18, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorText!,
                              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 20,
                          offset: const Offset(0, -8),
                          color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          priceLabel,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textSub),
                        ),
                        const SizedBox(height: 4),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Builder(builder: (_) {
                                final unit = _priceToDouble(_selected.price);
                                if (unit == null) {
                                  return Text(
                                    _seatPriceText(_selected),
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textMain),
                                  );
                                }
                                final total = unit * _passengers;
                                return Text(
                                  _formatVnd(total),
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textMain),
                                );
                              }),
                            ),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _seatPriceText(_selected),
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: textMain),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  perPaxLabel,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSub),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: canSubmit
                                ? () async {
                              final unit = _priceToDouble(_selected.price) ?? 0;
                              final total = unit * _passengers;

                              final args = FlightCheckoutArgs(
                                seat: _selected,
                                passengers: _passengers,
                                airlineName: widget.airlineName,
                                fromCode: widget.fromCode,
                                toCode: widget.toCode,
                                departTimeText: widget.departTimeText,
                                arriveTimeText: widget.arriveTimeText,
                                flightCode: widget.flightCode,
                                unitPrice: unit,
                                totalPrice: total,
                              );

                              await _goCheckoutWithFade(args);
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              disabledBackgroundColor: isDark ? Colors.white12 : Colors.black12,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              bookLabel,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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
    );
  }
}

class _SeatFullPageCard extends StatelessWidget {
  final FlightSeat seat;
  final bool selected;

  final String seatName;
  final String seatPrice;
  final String remainText;

  final bool isDark;
  final Color accent;
  final Color cardBg;
  final Color textMain;
  final Color textSub;
  final Color border;

  const _SeatFullPageCard({
    required this.seat,
    required this.selected,
    required this.seatName,
    required this.seatPrice,
    required this.remainText,
    required this.isDark,
    required this.accent,
    required this.cardBg,
    required this.textMain,
    required this.textSub,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final titleUpgrade = getTranslated('upgrade', context) ?? 'Nâng hạng';
    final labelSelected = getTranslated('selected', context) ?? 'Đang chọn';

    final cabin = (seat.baggageCabin ?? 0);
    final check = (seat.baggageCheckIn ?? 0);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? accent : border, width: selected ? 2 : 1),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned(
              left: 14,
              top: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B3D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  titleUpgrade,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
            ),

            if (selected)
              Positioned(
                right: 14,
                top: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withOpacity(0.5)),
                  ),
                  child: Text(
                    labelSelected,
                    style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(seatName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textMain)),
                    const SizedBox(height: 6),
                    Text(seatPrice, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textMain)),
                    const SizedBox(height: 10),

                    Text(remainText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textSub)),
                    const SizedBox(height: 16),

                    _BenefitLine(
                      ok: cabin > 0,
                      text: '$cabin kg ${getTranslated('cabin_baggage', context) ?? 'Hành lý xách tay'}',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _BenefitLine(
                      ok: check > 0,
                      warn: true,
                      text: '$check kg ${getTranslated('checked_baggage', context) ?? 'Hành lý ký gửi'}',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _BenefitLine(
                      ok: false,
                      text: getTranslated('refund', context) ?? 'Hoàn vé',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _BenefitLine(
                      ok: false,
                      warn: true,
                      text: getTranslated('change_flight', context) ?? 'Thay đổi chuyến bay',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeCodeBlock extends StatelessWidget {
  final String time;
  final String code;
  final bool alignRight;

  final Color textMain;
  final Color textSub;

  const _TimeCodeBlock({
    required this.time,
    required this.code,
    this.alignRight = false,
    required this.textMain,
    required this.textSub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(time, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textMain)),
        const SizedBox(height: 2),
        Text(code, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textSub)),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final bool isDark;
  final Color accent;

  const _Stepper({
    required this.value,
    required this.onMinus,
    required this.onPlus,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? Colors.white12 : Colors.black12;
    final fg = isDark ? Colors.white : Colors.black;

    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121E2C) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(icon: Icons.remove, onTap: onMinus, fg: fg, border: border),
          SizedBox(
            width: 36,
            child: Center(
              child: Text(
                '$value',
                style: TextStyle(fontWeight: FontWeight.w900, color: accent),
              ),
            ),
          ),
          _StepBtn(icon: Icons.add, onTap: onPlus, fg: fg, border: border),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color fg;
  final Color border;

  const _StepBtn({
    required this.icon,
    required this.onTap,
    required this.fg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, size: 18, color: fg.withOpacity(0.85)),
      ),
    );
  }
}

class _BenefitLine extends StatelessWidget {
  final bool ok;
  final bool warn;
  final String text;
  final bool isDark;

  const _BenefitLine({
    required this.ok,
    required this.text,
    this.warn = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final icon = ok ? Icons.check : Icons.close;
    final color = ok
        ? const Color(0xFF2E7D32)
        : (warn ? const Color(0xFFF9A825) : (isDark ? Colors.white54 : Colors.black45));

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.80),
            ),
          ),
        ),
      ],
    );
  }
}

class _FadeToBlackOverlay extends StatefulWidget {
  const _FadeToBlackOverlay();

  @override
  State<_FadeToBlackOverlay> createState() => _FadeToBlackOverlayState();
}

class _FadeToBlackOverlayState extends State<_FadeToBlackOverlay> {
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    // trigger fade-in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _opacity = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        opacity: _opacity,
        child: const ColoredBox(color: Colors.black),
      ),
    );
  }
}