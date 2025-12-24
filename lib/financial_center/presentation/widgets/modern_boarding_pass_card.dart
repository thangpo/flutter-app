import 'dart:math' as math;
import 'package:flutter/material.dart';

class ModernBoardingPassCard extends StatelessWidget {
  final bool isDark;
  final String? coverUrl;
  final String dateLeft;
  final String timeRight;
  final String fromCode;
  final String fromName;
  final String toCode;
  final String toName;
  final String airlineName;
  final String? durationText;
  final String flightCode;
  final String boarding;
  final String depart;
  final String arrive;
  final String gate;
  final String seat;
  final String seatClass;
  final String passenger;
  final String priceText;
  final bool showBarcode;

  const ModernBoardingPassCard({
    super.key,
    this.isDark = false,
    this.coverUrl,
    required this.dateLeft,
    required this.timeRight,
    required this.fromCode,
    required this.fromName,
    required this.toCode,
    required this.toName,
    required this.airlineName,
    this.durationText,
    required this.flightCode,
    required this.boarding,
    required this.depart,
    required this.arrive,
    required this.gate,
    required this.seat,
    required this.seatClass,
    required this.passenger,
    required this.priceText,
    this.showBarcode = false,
  });

  @override
  Widget build(BuildContext context) {
    final outerGradient = isDark
        ? const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1A3A52), Color(0xFF0D2438)],
    )
        : const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFE8F4FF), Color(0xFFD0E8FF)],
    );

    final topText = isDark ? Colors.white : const Color(0xFF0F1E2B);

    // Panel info
    final infoBg = isDark ? const Color(0xFF0A2840) : const Color(0xFF0D3554);
    final infoLabel = Colors.white.withOpacity(0.65);
    final infoValue = Colors.white;

    final w = MediaQuery.sizeOf(context).width;
    final ts = MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.25);

    // Ảnh full ngang, tự co theo width
    final imageH = (w * 0.50).clamp(180.0, 240.0);

    // Panel cao hơn chút vì có thêm Price
    final panelH = (170.0 * ts).clamp(170.0, 230.0);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 10),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: outerGradient,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              blurRadius: 30,
              offset: const Offset(0, 16),
              color: Colors.black.withOpacity(isDark ? 0.42 : 0.15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // Decorative blobs
              Positioned(
                left: -70,
                top: 140,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isDark ? 0.05 : 0.18),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: -80,
                bottom: -60,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isDark ? 0.04 : 0.14),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date + Time header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            dateLeft.isEmpty ? '—' : dateLeft,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: topText,
                              fontSize: 13.5,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        Text(
                          timeRight,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: topText,
                            fontSize: 13.5,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Route row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Row(
                      children: [
                        _TicketCity(
                          code: fromCode,
                          name: fromName,
                          alignLeft: true,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RouteCenter(
                            isDark: isDark,
                            durationText: durationText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _TicketCity(
                          code: toCode,
                          name: toName,
                          alignLeft: false,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  // Image (full width)
                  SizedBox(
                    height: imageH,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (coverUrl != null && coverUrl!.isNotEmpty)
                          Image.network(
                            coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildDefaultImage(isDark),
                          )
                        else
                          _buildDefaultImage(isDark),

                        // Overlay gradient
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.04),
                                  Colors.black.withOpacity(0.33),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Airline name
                        Positioned(
                          left: 16,
                          bottom: 16,
                          child: Text(
                            airlineName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(blurRadius: 12, color: Colors.black45)
                              ],
                            ),
                          ),
                        ),

                        // NOTE: đã bỏ Price pill trên ảnh theo yêu cầu
                      ],
                    ),
                  ),

                  // INFO PANEL: vuông (không bo cong 4 góc), và là phần đáy thật
                  Container(
                    height: panelH,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: infoBg,
                      // Vuông hoàn toàn
                      borderRadius: BorderRadius.zero,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 16,
                          offset: const Offset(0, -2),
                          color: Colors.black.withOpacity(0.12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Row 1: đưa Price xuống đây
                        Row(
                          children: [
                            Expanded(
                              child: _InfoField(
                                label: 'Flight',
                                value: flightCode,
                                labelColor: infoLabel,
                                valueColor: infoValue,
                              ),
                            ),
                            Expanded(
                              child: _InfoField(
                                label: 'Boarding',
                                value: boarding,
                                labelColor: infoLabel,
                                valueColor: infoValue,
                              ),
                            ),
                            Expanded(
                              child: _InfoField(
                                label: 'Price',
                                value: priceText,
                                labelColor: infoLabel,
                                valueColor: infoValue,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _InfoField(
                                label: 'Gate',
                                value: gate,
                                labelColor: infoLabel,
                                valueColor: infoValue,
                              ),
                            ),
                            Expanded(
                              child: _InfoField(
                                label: 'Seat',
                                value: seat,
                                labelColor: infoLabel,
                                valueColor: infoValue,
                              ),
                            ),
                            Expanded(
                              child: _InfoField(
                                label: 'Depart',
                                value: depart,
                                labelColor: infoLabel,
                                valueColor: infoValue,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _InfoField(
                                label: 'Class',
                                value: seatClass,
                                labelColor: infoLabel,
                                valueColor: infoValue,
                              ),
                            ),
                            Expanded(
                              child: _InfoField(
                                label: 'Passenger',
                                value: passenger,
                                labelColor: infoLabel,
                                valueColor: infoValue,
                              ),
                            ),
                            Expanded(
                              child: _InfoField(
                                label: 'Arrive',
                                value: arrive,
                                labelColor: infoLabel,
                                valueColor: infoValue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Barcode (nếu bật)
                  if (showBarcode) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _SideNotch(isDark: isDark),
                          Expanded(
                            child: CustomPaint(
                              painter: _DashedLinePainter(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withOpacity(0.22),
                                dash: 7,
                                gap: 7,
                                strokeWidth: 1.5,
                              ),
                              child: const SizedBox(height: 18),
                            ),
                          ),
                          _SideNotch(isDark: isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          height: 72,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFFF4F8FC),
                          child: CustomPaint(
                            painter: _BarcodePainter(seed: flightCode.hashCode),
                          ),
                        ),
                      ),
                    ),
                  ] else
                    const SizedBox(height: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultImage(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0E3A5D), const Color(0xFF082338)]
              : [const Color(0xFFE5F3FF), const Color(0xFFCEE7FF)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.flight_takeoff,
          size: 64,
          color: Colors.white.withOpacity(0.35),
        ),
      ),
    );
  }
}

class _RouteCenter extends StatelessWidget {
  final bool isDark;
  final String? durationText;

  const _RouteCenter({
    required this.isDark,
    required this.durationText,
  });

  @override
  Widget build(BuildContext context) {
    final lineColor =
    (isDark ? Colors.white : const Color(0xFF1B2A3A)).withOpacity(0.50);
    final iconColor =
    (isDark ? Colors.white : const Color(0xFF1B2A3A)).withOpacity(0.82);
    final durColor = (isDark ? Colors.white : Colors.black).withOpacity(0.70);

    return SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: _DashedLinePainter(
                color: lineColor,
                dash: 7,
                gap: 7,
                strokeWidth: 2.2,
              ),
              child: const SizedBox(height: 12),
            ),
          ),
          Positioned(
            top: 10,
            child: Transform.rotate(
              angle: math.pi / 2,
              child: Icon(Icons.flight, size: 20, color: iconColor),
            ),
          ),
          if ((durationText ?? '').trim().isNotEmpty)
            Positioned(
              top: 36,
              child: Text(
                durationText!,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: durColor,
                  letterSpacing: 0.2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TicketCity extends StatelessWidget {
  final String code;
  final String name;
  final bool alignLeft;
  final bool isDark;

  const _TicketCity({
    required this.code,
    required this.name,
    required this.alignLeft,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final codeColor = isDark ? Colors.white : const Color(0xFF0F1E2B);
    final nameColor = (isDark ? Colors.white : Colors.black).withOpacity(0.62);

    return Column(
      crossAxisAlignment:
      alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          code,
          style: TextStyle(
            color: codeColor,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          width: 110,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignLeft ? TextAlign.left : TextAlign.right,
            style: TextStyle(
              color: nameColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  const _InfoField({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _SideNotch extends StatelessWidget {
  final bool isDark;
  const _SideNotch({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 18,
      child: Center(
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.15),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double dash;
  final double gap;
  final double strokeWidth;

  _DashedLinePainter({
    required this.color,
    required this.dash,
    required this.gap,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    double x = 0;
    final y = size.height / 2;

    while (x < size.width) {
      final x2 = (x + dash <= size.width) ? (x + dash) : size.width;
      canvas.drawLine(Offset(x, y), Offset(x2, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dash != dash ||
        oldDelegate.gap != gap ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _BarcodePainter extends CustomPainter {
  final int seed;
  _BarcodePainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black87;
    double x = 12;
    final rnd = math.Random(seed);

    while (x < size.width - 12) {
      final w = (rnd.nextInt(4) + 1).toDouble();
      final h = size.height * (0.58 + rnd.nextDouble() * 0.36);
      canvas.drawRect(Rect.fromLTWH(x, (size.height - h) / 2, w, h), paint);
      x += w + (rnd.nextInt(4) + 2);
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodePainter oldDelegate) => false;
}