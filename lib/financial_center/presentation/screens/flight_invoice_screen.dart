import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

class FlightInvoiceScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Map<String, dynamic> flightInfo;
  final Map<String, dynamic> contactInfo;
  final List<Map<String, dynamic>> passengers;
  final String homeRouteName;

  const FlightInvoiceScreen({
    super.key,
    required this.booking,
    required this.flightInfo,
    required this.contactInfo,
    required this.passengers,
    this.homeRouteName = '/',
  });

  @override
  State<FlightInvoiceScreen> createState() => _FlightInvoiceScreenState();
}

class _FlightInvoiceScreenState extends State<FlightInvoiceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slideCard;
  late final Animation<Offset> _slideBanner;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: const Duration(milliseconds: 780));
    _fade = CurvedAnimation(parent: _ctl, curve: Curves.easeOutCubic);
    _slideCard = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctl, curve: Curves.easeOutCubic));
    _slideBanner = Tween<Offset>(begin: const Offset(0, -0.6), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctl, curve: Curves.easeOutBack));
    _ctl.forward();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  String _safeStr(dynamic v) => (v ?? '').toString();

  String _formatVnd(dynamic value) {
    double v = 0;
    if (value is num) v = value.toDouble();
    if (value is String) v = double.tryParse(value) ?? 0;
    final n = v.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < n.length; i++) {
      final pos = n.length - i;
      buf.write(n[i]);
      if (pos > 1 && pos % 3 == 1) buf.write('.');
    }
    return '${buf.toString()} ₫';
  }

  DateTime? _parseBackendDate(dynamic v) {
    final s = _safeStr(v).trim();
    if (s.isEmpty) return null;
    final iso = s.contains('T') ? s : s.replaceFirst(' ', 'T');
    return DateTime.tryParse(iso);
  }

  String _timeLeftText(BuildContext context) {
    final depart = _parseBackendDate(widget.booking['start_date']);
    if (depart == null) return '—';
    final diff = depart.difference(DateTime.now());
    if (diff.inSeconds <= 0) return getTranslated('fi_departed', context) ?? 'Departed';

    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h <= 0) {
      final mins = getTranslated('fi_mins', context) ?? 'mins';
      return '$m $mins';
    }
    final hours = getTranslated('fi_hours_short', context) ?? 'h';
    return '$h$hours ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeController>(context, listen: true).darkTheme;
    final bgTop = isDark ? const Color(0xFF0A2E58) : const Color(0xFF0D4A8C);
    final bgBottom = isDark ? const Color(0xFF061C34) : const Color(0xFF07315F);
    final ticketBg = isDark ? const Color(0xFF101723) : Colors.white;
    final ticketText = isDark ? Colors.white : Colors.black;
    final ticketSubText = (isDark ? Colors.white : Colors.black).withOpacity(0.62);
    final chipBg = isDark ? const Color(0xFF0B3C73) : bgTop;
    final softBoxBg = isDark ? const Color(0xFF131C2A) : const Color(0xFFF3F5F8);
    final softBoxBorder = isDark ? Colors.white10 : Colors.black12;
    final priceBoxBg = isDark ? const Color(0xFF0F1622) : const Color(0xFFF9FAFC);
    final priceBoxBorder = isDark ? Colors.white12 : Colors.black12;
    final barcodeBg = isDark ? const Color(0xFF0E1520) : Colors.white;
    final barcodeInk = isDark ? Colors.white70 : Colors.black87;
    final booking = widget.booking;
    final flightInfo = widget.flightInfo;
    final contact = widget.contactInfo;
    final code = _safeStr(booking['code']);
    final status = _safeStr(booking['status']);
    final gateway = _safeStr(booking['gateway']);
    final airlineName = _safeStr(flightInfo['airline_name']).trim().isEmpty
        ? (getTranslated('fi_airline', context) ?? 'AIRLINE')
        : _safeStr(flightInfo['airline_name']);
    final flightCode = _safeStr(flightInfo['flight_code']);
    final fromCode = _safeStr(flightInfo['from_code']);
    final toCode = _safeStr(flightInfo['to_code']);
    final departTime = _safeStr(flightInfo['depart_time']);
    final arriveTime = _safeStr(flightInfo['arrive_time']);
    final seatClass = _safeStr(flightInfo['seat_class']).trim().isEmpty ? 'Economy' : _safeStr(flightInfo['seat_class']);
    final seatQty = (flightInfo['seat_qty'] ?? widget.passengers.length).toString();
    final unitPrice = flightInfo['unit_price'];
    final total = booking['total'];
    final passengerName = () {
      if (widget.passengers.isNotEmpty) {
        final n = _safeStr(widget.passengers.first['full_name']).trim();
        if (n.isNotEmpty) return n;
      }
      final fn = _safeStr(contact['first_name']).trim();
      final ln = _safeStr(contact['last_name']).trim();
      final merged = ('$ln $fn').trim();
      return merged.isEmpty ? (getTranslated('fi_passenger', context) ?? 'Passenger') : merged;
    }();
    final terminal = '--';
    final gateNo = '--';
    final seatNo = '--';
    final title = getTranslated('fi_boarding_pass', context) ?? 'BOARDING PASS';
    final congrats = getTranslated('fi_congrats', context) ?? 'Chúc mừng! Bạn đã đặt vé thành công.';
    final copied = getTranslated('fi_copied', context) ?? 'Đã copy mã booking';
    final backHome = getTranslated('fi_back_home', context) ?? 'Quay lại trang chủ';

    return Scaffold(
      backgroundColor: bgBottom,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [bgTop, bgBottom],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          Positioned(
            top: -120,
            left: -90,
            child: _GlowCircle(size: 260, color: Colors.white.withOpacity(isDark ? 0.06 : 0.08)),
          ),
          Positioned(
            top: 120,
            right: -110,
            child: _GlowCircle(size: 240, color: Colors.white.withOpacity(isDark ? 0.05 : 0.06)),
          ),
          Positioned(
            bottom: -130,
            left: -90,
            child: _GlowCircle(size: 280, color: Colors.white.withOpacity(isDark ? 0.04 : 0.05)),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: getTranslated('fi_copy_booking_code', context) ?? 'Copy booking code',
                        onPressed: code.isEmpty
                            ? null
                            : () async {
                          await Clipboard.setData(ClipboardData(text: code));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(copied)),
                          );
                        },
                        icon: const Icon(Icons.copy, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                SlideTransition(
                  position: _slideBanner,
                  child: FadeTransition(
                    opacity: _fade,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(isDark ? 0.10 : 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(isDark ? 0.16 : 0.18)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.celebration, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                congrats,
                                maxLines: 2,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                textHeightBehavior: const TextHeightBehavior(
                                  applyHeightToFirstAscent: false,
                                  applyHeightToLastDescent: false,
                                ),
                                strutStyle: const StrutStyle(
                                  forceStrutHeight: true,
                                  height: 1.15,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                    child: SlideTransition(
                      position: _slideCard,
                      child: FadeTransition(
                        opacity: _fade,
                        child: _TicketCard(
                          bgColor: ticketBg,
                          shadowOpacity: isDark ? 0.26 : 0.18,
                          child: DefaultTextStyle.merge(
                            style: TextStyle(color: ticketText),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white10 : bgTop.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: softBoxBorder),
                                      ),
                                      child: Icon(Icons.flight, color: isDark ? Colors.white70 : const Color(0xFF0D4A8C)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        airlineName.toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          letterSpacing: 0.6,
                                          color: ticketText,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: chipBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            getTranslated('fi_time_left', context) ?? 'TIME LEFT',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 10,
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                          Text(
                                            _timeLeftText(context),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                Row(
                                  children: [
                                    Expanded(
                                      child: _BigCodeBlock(
                                        code: fromCode.isEmpty ? '---' : fromCode,
                                        sub1: _safeStr(flightInfo['from_country']),
                                        sub2: departTime,
                                        textColor: ticketText,
                                        subColor: ticketSubText,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      children: [
                                        Text(
                                          _durationText(departTime, arriveTime),
                                          style: TextStyle(fontWeight: FontWeight.w800, color: ticketSubText),
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: 76,
                                          child: Row(
                                            children: [
                                              Expanded(child: Divider(thickness: 1, color: softBoxBorder)),
                                              const SizedBox(width: 6),
                                              Icon(Icons.airplanemode_active, size: 18, color: isDark ? Colors.white70 : const Color(0xFF0D4A8C)),
                                              const SizedBox(width: 6),
                                              Expanded(child: Divider(thickness: 1, color: softBoxBorder)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _BigCodeBlock(
                                        code: toCode.isEmpty ? '---' : toCode,
                                        sub1: _safeStr(flightInfo['to_country']),
                                        sub2: arriveTime,
                                        alignRight: true,
                                        textColor: ticketText,
                                        subColor: ticketSubText,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),
                                _DashedDivider(color: softBoxBorder),
                                const SizedBox(height: 14),

                                _InfoRow(
                                  label: getTranslated('fi_passenger', context) ?? 'Passenger',
                                  value: passengerName,
                                  labelColor: ticketSubText,
                                  valueColor: ticketText,
                                  valueWeight: FontWeight.w900,
                                ),
                                const SizedBox(height: 10),

                                Row(
                                  children: [
                                    Expanded(
                                      child: _InfoRow(
                                        label: getTranslated('fi_flight_no', context) ?? 'Flight No.',
                                        value: flightCode.isEmpty ? '--' : flightCode,
                                        labelColor: ticketSubText,
                                        valueColor: ticketText,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _InfoRow(
                                        label: getTranslated('fi_terminal', context) ?? 'Terminal',
                                        value: terminal,
                                        alignRight: true,
                                        labelColor: ticketSubText,
                                        valueColor: ticketText,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                Row(
                                  children: [
                                    Expanded(
                                      child: _InfoRow(
                                        label: getTranslated('fi_gate_no', context) ?? 'Gate No.',
                                        value: gateNo,
                                        labelColor: ticketSubText,
                                        valueColor: ticketText,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _InfoRow(
                                        label: getTranslated('fi_seat', context) ?? 'Seat',
                                        value: seatNo,
                                        alignRight: true,
                                        labelColor: ticketSubText,
                                        valueColor: ticketText,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: softBoxBg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: softBoxBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _MiniTag(
                                          title: getTranslated('fi_class', context) ?? 'Class',
                                          value: seatClass,
                                          titleColor: ticketSubText,
                                          valueColor: ticketText,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _MiniTag(
                                          title: getTranslated('fi_passengers', context) ?? 'Passengers',
                                          value: seatQty,
                                          titleColor: ticketSubText,
                                          valueColor: ticketText,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _MiniTag(
                                          title: getTranslated('fi_unit', context) ?? 'Unit',
                                          value: _formatVnd(unitPrice),
                                          titleColor: ticketSubText,
                                          valueColor: ticketText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),
                                _DashedDivider(color: softBoxBorder),
                                const SizedBox(height: 12),
                                _PseudoBarcode(value: code, bg: barcodeBg, ink: barcodeInk),
                                const SizedBox(height: 10),
                                Text(
                                  code.isEmpty ? '—' : code,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: ticketText,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: priceBoxBg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: priceBoxBorder),
                                  ),
                                  child: Column(
                                    children: [
                                      _PriceRow(
                                        label: getTranslated('fi_status', context) ?? 'Status',
                                        value: status.isEmpty ? '--' : status,
                                        color: ticketText,
                                      ),
                                      _PriceRow(
                                        label: getTranslated('fi_payment', context) ?? 'Payment',
                                        value: gateway.isEmpty ? '--' : gateway,
                                        color: ticketText,
                                      ),
                                      _PriceRow(
                                        label: getTranslated('fi_subtotal', context) ?? 'Subtotal',
                                        value: _formatVnd(booking['total_before_fees']),
                                        color: ticketText,
                                      ),
                                      _PriceRow(
                                        label: getTranslated('fi_discount', context) ?? 'Discount',
                                        value: _formatVnd(booking['coupon_amount']),
                                        color: ticketText,
                                      ),
                                      Divider(color: softBoxBorder),
                                      _PriceRow(
                                        label: (getTranslated('fi_total', context) ?? 'TOTAL').toUpperCase(),
                                        value: _formatVnd(total),
                                        bold: true,
                                        color: ticketText,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),

                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: chipBg,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pushNamedAndRemoveUntil(
                                        widget.homeRouteName,
                                            (route) => false,
                                      );
                                    },
                                    child: Text(
                                      backHome,
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _durationText(String depart, String arrive) {
    final d = _parseHHmm(depart);
    final a = _parseHHmm(arrive);
    if (d == null || a == null) return '';
    var diff = a.difference(d);
    if (diff.isNegative) diff += const Duration(days: 1);
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  DateTime? _parseHHmm(String s) {
    final t = s.trim();
    if (!RegExp(r'^\d{1,2}:\d{2}$').hasMatch(t)) return null;
    final parts = t.split(':');
    final hh = int.tryParse(parts[0]) ?? 0;
    final mm = int.tryParse(parts[1]) ?? 0;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hh, mm);
  }
}

class _TicketCard extends StatelessWidget {
  final Widget child;
  final Color bgColor;
  final double shadowOpacity;

  const _TicketCard({
    required this.child,
    required this.bgColor,
    required this.shadowOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _TicketClipper(),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              blurRadius: 26,
              offset: const Offset(0, 18),
              color: Colors.black.withOpacity(shadowOpacity),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: child,
        ),
      ),
    );
  }
}

class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const r = 22.0;
    const notchRadius = 16.0;
    final notchY = size.height * 0.53;
    final p = Path();
    p.moveTo(r, 0);
    p.quadraticBezierTo(0, 0, 0, r);
    p.lineTo(0, notchY - notchRadius);
    p.arcToPoint(
      Offset(0, notchY + notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    p.lineTo(0, size.height - r);
    p.quadraticBezierTo(0, size.height, r, size.height);
    p.lineTo(size.width - r, size.height);
    p.quadraticBezierTo(size.width, size.height, size.width, size.height - r);
    p.lineTo(size.width, notchY + notchRadius);
    p.arcToPoint(
      Offset(size.width, notchY - notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    p.lineTo(size.width, r);
    p.quadraticBezierTo(size.width, 0, size.width - r, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant _TicketClipper oldClipper) => false;
}

class _BigCodeBlock extends StatelessWidget {
  final String code;
  final String sub1;
  final String sub2;
  final bool alignRight;
  final Color textColor;
  final Color subColor;

  const _BigCodeBlock({
    required this.code,
    required this.sub1,
    required this.sub2,
    required this.textColor,
    required this.subColor,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final align = alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          code.toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: 0.8, color: textColor),
        ),
        if (sub1.trim().isNotEmpty)
          Text(sub1, style: TextStyle(color: subColor, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(sub2, style: TextStyle(fontWeight: FontWeight.w900, color: textColor)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool alignRight;
  final FontWeight valueWeight;
  final Color labelColor;
  final Color valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
    this.alignRight = false,
    this.valueWeight = FontWeight.w900,
  });

  @override
  Widget build(BuildContext context) {
    final a = alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: a,
      children: [
        Text(label, style: TextStyle(color: labelColor, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(value.isEmpty ? '--' : value, style: TextStyle(fontWeight: valueWeight, fontSize: 16, color: valueColor)),
      ],
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String title;
  final String value;
  final Color titleColor;
  final Color valueColor;

  const _MiniTag({
    required this.title,
    required this.value,
    required this.titleColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: titleColor, fontWeight: FontWeight.w700, fontSize: 12)),
        const SizedBox(height: 6),
        Text(value.isEmpty ? '--' : value, style: TextStyle(fontWeight: FontWeight.w900, color: valueColor)),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color color;

  const _PriceRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = bold ? FontWeight.w900 : FontWeight.w800;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: w, color: color))),
          Text(value.isEmpty ? '--' : value, style: TextStyle(fontWeight: w, color: color)),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  final Color color;
  const _DashedDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth;
      const dashW = 6.0;
      const dashGap = 4.0;
      final count = (w / (dashW + dashGap)).floor();
      return Row(
        children: List.generate(count, (_) {
          return Padding(
            padding: const EdgeInsets.only(right: dashGap),
            child: SizedBox(
              width: dashW,
              height: 1.2,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            ),
          );
        }),
      );
    });
  }
}

class _PseudoBarcode extends StatelessWidget {
  final String value;
  final Color bg;
  final Color ink;

  const _PseudoBarcode({
    required this.value,
    required this.bg,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      width: double.infinity,
      child: CustomPaint(
        painter: _PseudoBarcodePainter(value: value, bg: bg, ink: ink),
      ),
    );
  }
}

class _PseudoBarcodePainter extends CustomPainter {
  final String value;
  final Color bg;
  final Color ink;

  _PseudoBarcodePainter({required this.value, required this.bg, required this.ink});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = ink;
    final bgPaint = Paint()..color = bg;

    canvas.drawRect(Offset.zero & size, bgPaint);

    final bytes = value.codeUnits;
    if (bytes.isEmpty) return;

    double x = 6;
    final maxX = size.width - 6;
    final h = size.height;
    final rng = _XorShift32(_hash(bytes));

    while (x < maxX) {
      final bw = 1.0 + (rng.nextInt(3)).toDouble();
      final gap = 1.0 + (rng.nextInt(2)).toDouble();
      final barH = h * (0.72 + (rng.nextInt(25) / 100));
      final top = (h - barH) / 2;

      canvas.drawRect(Rect.fromLTWH(x, top, bw, barH), paint);
      x += bw + gap;
    }
  }

  int _hash(List<int> bytes) {
    int h = 0x811C9DC5;
    for (final b in bytes) {
      h ^= b & 0xFF;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h;
  }

  @override
  bool shouldRepaint(covariant _PseudoBarcodePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.bg != bg || oldDelegate.ink != ink;
}

class _XorShift32 {
  int _state;
  _XorShift32(this._state) {
    if (_state == 0) _state = 2463534242;
  }
  int nextInt(int max) {
    _state ^= (_state << 13) & 0xFFFFFFFF;
    _state ^= (_state >> 17) & 0xFFFFFFFF;
    _state ^= (_state << 5) & 0xFFFFFFFF;
    final v = (_state & 0x7FFFFFFF) % max;
    return v;
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}