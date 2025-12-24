import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../screens/flight_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

class FlightListItem extends StatefulWidget {
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

  @override
  State<FlightListItem> createState() => _FlightListItemState();
}

class _FlightListItemState extends State<FlightListItem> {
  bool _pressed = false;

  String _formatMoneyVND(String raw) {
    try {
      var s = raw.replaceAll(RegExp(r'[^0-9.,]'), '');
      if (s.isEmpty) return raw;

      if (s.contains(',') && s.contains('.')) {
        s = s.replaceAll(',', '');
      } else if (s.contains(',') && !s.contains('.')) {
        s = s.replaceAll(',', '.');
      }

      final value = double.parse(s);
      final vnd = value.round();
      final formatter = NumberFormat.currency(
        locale: 'vi_VN',
        symbol: '₫',
        decimalDigits: 0,
      );
      return formatter.format(vnd);
    } catch (_) {
      return raw;
    }
  }

  DateTime? _parseDate(String s) {
    try {
      if (s.contains('T')) return DateTime.parse(s).toLocal();
      return null;
    } catch (_) {
      return null;
    }
  }

  String _hhmm(String s) {
    final dt = _parseDate(s);
    if (dt == null) return '--:--';
    return DateFormat('HH:mm', 'vi_VN').format(dt);
  }

  String _durationText() {
    final dep = _parseDate(widget.departure);
    final arr = _parseDate(widget.arrival);
    if (dep == null || arr == null) return '';
    final diff = arr.difference(dep);
    if (diff.isNegative) return '';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h <= 0 && m <= 0) return '';
    return '${h.toString().padLeft(2, '0')}h ${m.toString().padLeft(2, '0')}m';
  }

  String _shortCodeFromName(String name) {
    final trimmed = name.trim();

    final dashParts = trimmed.split('-');
    if (dashParts.length >= 2) {
      final last = dashParts.last.trim().toUpperCase();
      if (RegExp(r'^[A-Z]{3}$').hasMatch(last)) return last;
    }

    final upper = trimmed.toUpperCase();
    if (RegExp(r'^[A-Z]{3}$').hasMatch(upper)) return upper;

    final words = trimmed
        .replaceAll(RegExp(r'[^A-Za-zÀ-ỹ0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) return upper.isNotEmpty ? upper.substring(0, 1) : '---';

    String code = '';
    for (final w in words) {
      code += w.characters.first.toUpperCase();
      if (code.length == 3) break;
    }

    if (code.length < 3) {
      final compact = trimmed.replaceAll(' ', '').toUpperCase();
      code = (compact.length >= 3) ? compact.substring(0, 3) : compact;
    }

    return code.padRight(3, '-');
  }

  bool _isRecommended() {
    final a = widget.availability.toLowerCase();
    return a.contains('còn') || a.contains('available');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeController>(context, listen: true).darkTheme;
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final border = isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08);
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub = isDark ? Colors.white70 : const Color(0xFF64748B);
    final priceColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    final dashed = isDark ? Colors.white.withOpacity(0.12) : Colors.black12;
    final line = isDark ? Colors.white.withOpacity(0.14) : Colors.black12;
    final fromCode = _shortCodeFromName(widget.from);
    final toCode = _shortCodeFromName(widget.to);
    final depTime = _hhmm(widget.departure);
    final arrTime = _hhmm(widget.arrival);
    final dur = _durationText();
    final badgeBg = isDark ? const Color(0xFF052E1A) : const Color(0xFFE8F7EE);
    final badgeFg = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onHighlightChanged: (v) => setState(() => _pressed = v),
            onTap: () {
              debugPrint('OPEN DETAIL flightId=${widget.flightId}');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FlightDetailScreen(flightId: widget.flightId)),
              );
            },
            child: PhysicalShape(
              clipper: TicketClipper(
                radius: 12,
                notchRadius: 12,
                notchYFactor: 0.70,
              ),
              color: cardBg,
              elevation: isDark ? 0 : 5,
              shadowColor: Colors.black.withOpacity(0.18),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                      child: Row(
                        children: [
                          _LogoCircle(url: widget.logoUrl, isDark: isDark),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.airline.isNotEmpty ? widget.airline : 'Airline',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: textMain,
                              ),
                            ),
                          ),
                          if (_isRecommended())
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isDark ? Colors.white.withOpacity(0.12) : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                'Recommended',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: badgeFg,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: _CodeBlock(
                              code: fromCode,
                              place: widget.from,
                              time: depTime,
                              alignEnd: false,
                              textMain: textMain,
                              textSub: textSub,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            children: [
                              Text(
                                dur.isNotEmpty ? dur : ' ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: textSub,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(width: 32, height: 1, color: line),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.flight,
                                    size: 16,
                                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(width: 32, height: 1, color: line),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Non-stop',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: textSub,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _CodeBlock(
                              code: toCode,
                              place: widget.to,
                              time: arrTime,
                              alignEnd: true,
                              textMain: textMain,
                              textSub: textSub,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: DashedLine(color: dashed),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                      child: Row(
                        children: [
                          Icon(Icons.event_seat, size: 16, color: textSub),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.availability.isNotEmpty ? widget.availability : 'Available',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: textSub,
                              ),
                            ),
                          ),
                          Text(
                            _formatMoneyVND(widget.price),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: priceColor,
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
}

class _LogoCircle extends StatelessWidget {
  final String? url;
  final bool isDark;

  const _LogoCircle({required this.url, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final u = (url ?? '').trim();

    Widget child;
    if (u.isNotEmpty && u.toLowerCase().endsWith('.svg')) {
      child = SvgPicture.network(
        u,
        width: 20,
        height: 20,
        placeholderBuilder: (_) => const Icon(Icons.flight, size: 18),
      );
    } else if (u.isNotEmpty) {
      child = Image.network(
        u,
        width: 20,
        height: 20,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.flight, size: 18),
      );
    } else {
      child = const Icon(Icons.flight, size: 18);
    }

    final bg = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05);
    final border = isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.06);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border),
      ),
      alignment: Alignment.center,
      child: ClipOval(child: child),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;
  final String place;
  final String time;
  final bool alignEnd;
  final Color textMain;
  final Color textSub;

  const _CodeBlock({
    required this.code,
    required this.place,
    required this.time,
    required this.alignEnd,
    required this.textMain,
    required this.textSub,
  });

  @override
  Widget build(BuildContext context) {
    final align = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          code,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: textMain,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          place,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textSub,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: textMain,
          ),
        ),
      ],
    );
  }
}

class TicketClipper extends CustomClipper<Path> {
  final double radius;
  final double notchRadius;
  final double notchYFactor;

  TicketClipper({
    this.radius = 16,
    this.notchRadius = 12,
    this.notchYFactor = 0.70,
  });

  @override
  Path getClip(Size size) {
    final r = radius.clamp(0.0, 40.0);
    final nr = notchRadius.clamp(0.0, 40.0);
    final notchY = (size.height * notchYFactor).clamp(r + nr, size.height - r - nr);

    final p = Path();

    p.moveTo(r, 0);
    p.lineTo(size.width - r, 0);
    p.quadraticBezierTo(size.width, 0, size.width, r);

    p.lineTo(size.width, notchY - nr);
    p.arcToPoint(
      Offset(size.width, notchY + nr),
      radius: Radius.circular(nr),
      clockwise: false,
    );

    p.lineTo(size.width, size.height - r);
    p.quadraticBezierTo(size.width, size.height, size.width - r, size.height);

    p.lineTo(r, size.height);
    p.quadraticBezierTo(0, size.height, 0, size.height - r);

    p.lineTo(0, notchY + nr);
    p.arcToPoint(
      Offset(0, notchY - nr),
      radius: Radius.circular(nr),
      clockwise: false,
    );

    p.lineTo(0, r);
    p.quadraticBezierTo(0, 0, r, 0);

    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant TicketClipper oldClipper) {
    return oldClipper.radius != radius ||
        oldClipper.notchRadius != notchRadius ||
        oldClipper.notchYFactor != notchYFactor;
  }
}

class DashedLine extends StatelessWidget {
  final Color color;
  final double height;
  final double dashWidth;
  final double dashSpace;

  const DashedLine({
    super.key,
    required this.color,
    this.height = 1,
    this.dashWidth = 6,
    this.dashSpace = 4,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        final dashCount = (w / (dashWidth + dashSpace)).floor();
        return Row(
          children: List.generate(dashCount, (_) {
            return Padding(
              padding: EdgeInsets.only(right: dashSpace),
              child: SizedBox(
                width: dashWidth,
                height: height,
                child: DecoratedBox(decoration: BoxDecoration(color: color)),
              ),
            );
          }),
        );
      },
    );
  }
}

class FlightReveal extends StatefulWidget {
  final int index;
  final Widget child;

  const FlightReveal({super.key, required this.index, required this.child});

  @override
  State<FlightReveal> createState() => _FlightRevealState();
}

class _FlightRevealState extends State<FlightReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _opacity = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

    _timer = Timer(Duration(milliseconds: 45 * widget.index), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}