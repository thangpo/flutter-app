import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/flight_service.dart';
import '../models/flight_data_models.dart';

class FlightDetailScreen extends StatelessWidget {
  final String flightId;
  const FlightDetailScreen({super.key, required this.flightId});

  DateTime? _parseIso(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _hhmm(DateTime? dt) => dt == null ? '--:--' : DateFormat('HH:mm', 'vi_VN').format(dt);

  String _dateLine(DateTime? dt) => dt == null ? '' : DateFormat('EEE, dd/MM/yyyy', 'vi_VN').format(dt);

  String _formatVnd(String? raw) {
    final s = (raw ?? '').toString();
    if (s.trim().isEmpty) return '-';
    try {
      final value = double.parse(s);
      return NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(value.round());
    } catch (_) {
      return s;
    }
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: FlightService.getFlightDetail(flightId),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Lỗi tải chi tiết: ${snap.error}'),
              ),
            );
          }

          final raw = snap.data ?? <String, dynamic>{};
          final detailRes = FlightDetailResponse.fromJson(raw);

          if (detailRes.status != 1) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(detailRes.message.isNotEmpty ? detailRes.message : 'Không thể tải dữ liệu.'),
              ),
            );
          }

          final flight = detailRes.flight;
          if (flight == null) {
            return const Center(child: Text('Không có dữ liệu.'));
          }

          final dep = _parseIso(flight.departureTimeIso ?? flight.departureTime);
          final arr = _parseIso(flight.arrivalTimeIso ?? flight.arrivalTime);

          final from = flight.airportFrom;
          final to = flight.airportTo;

          final fromCode = (from?.code?.trim().isNotEmpty ?? false) ? from!.code!.trim() : '---';
          final toCode = (to?.code?.trim().isNotEmpty ?? false) ? to!.code!.trim() : '---';

          final fromName = from?.name ?? '-';
          final toName = to?.name ?? '-';

          final airlineName = flight.airline?.name ?? 'Airline';
          final coverUrl = (flight.airline?.imageUrl?.trim().isNotEmpty ?? false) ? flight.airline!.imageUrl!.trim() : null;

          // Seat “đại diện” để show như boarding pass
          final mainSeat = flight.flightSeat.isNotEmpty ? flight.flightSeat.first : null;
          final seatClass = mainSeat?.seatType?.name ?? '—';

          // Map: 2 marker + polyline
          final fromLat = _toDouble(from?.mapLat);
          final fromLng = _toDouble(from?.mapLng);
          final toLat = _toDouble(to?.mapLat);
          final toLng = _toDouble(to?.mapLng);

          final canShowMap = fromLat != null && fromLng != null && toLat != null && toLng != null;

          final markers = <Marker>{};
          final polylines = <Polyline>{};

          LatLng? fromPos;
          LatLng? toPos;
          LatLng? center;

          if (canShowMap) {
            fromPos = LatLng(fromLat!, fromLng!);
            toPos = LatLng(toLat!, toLng!);

            center = LatLng((fromLat + toLat) / 2.0, (fromLng + toLng) / 2.0);

            markers.add(Marker(markerId: const MarkerId('from'), position: fromPos, infoWindow: InfoWindow(title: fromCode, snippet: fromName)));
            markers.add(Marker(markerId: const MarkerId('to'), position: toPos, infoWindow: InfoWindow(title: toCode, snippet: toName)));

            polylines.add(Polyline(
              polylineId: const PolylineId('route'),
              points: [fromPos, toPos],
              width: 4,
            ));
          }

          // Zoom “ước lượng” để nhìn được cả 2 điểm
          double initialZoom = 3.0;
          if (canShowMap) {
            final dLat = (fromLat! - toLat!).abs();
            final dLng = (fromLng! - toLng!).abs();
            final spread = math.max(dLat, dLng);
            // spread càng lớn -> zoom càng nhỏ
            if (spread < 1) initialZoom = 10;
            else if (spread < 5) initialZoom = 6.5;
            else if (spread < 15) initialZoom = 4.5;
            else initialZoom = 3.0;
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                stretch: true,
                expandedHeight: 220,
                elevation: 0,
                backgroundColor: const Color(0xFF0B2D4A),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final top = constraints.biggest.height;
                    // collapsedHeight xấp xỉ toolbarHeight + statusBar
                    final t = ((top - kToolbarHeight) / (220 - kToolbarHeight)).clamp(0.0, 1.0);

                    // t ~ 1: expanded (ảnh 1), t ~ 0: collapsed (ảnh 2)
                    return FlexibleSpaceBar(
                      titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 12, end: 16),
                      title: AnimatedOpacity(
                        duration: const Duration(milliseconds: 120),
                        opacity: 1.0 - t,
                        child: const Text(
                          'Boarding Pass',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // “world map” nền (dùng gradient + dot pattern giả lập)
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF0B2D4A), Color(0xFF123E62)],
                              ),
                            ),
                          ),
                          IgnorePointer(
                            child: CustomPaint(
                              painter: _DotWorldPainter(opacity: 0.20),
                            ),
                          ),

                          // Header kiểu ảnh 1 (Select Flight)
                          Positioned.fill(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 160),
                              opacity: t,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 52, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Select Flight',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                                    ),
                                    const SizedBox(height: 14),
                                    _RouteHeader(
                                      fromCode: fromCode,
                                      fromName: fromName,
                                      toCode: toCode,
                                      toName: toName,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _BoardingPassCard(
                        coverUrl: coverUrl,
                        dateLeft: _dateLine(dep),
                        timeRight: flight.departureTimeHtml ?? _hhmm(dep),
                        fromCode: fromCode,
                        fromName: fromName,
                        toCode: toCode,
                        toName: toName,
                        airlineName: airlineName,
                        durationText: (flight.duration ?? '').trim().isEmpty ? null : '${flight.duration}h',
                        flightCode: flight.code,
                        boarding: flight.departureTimeHtml ?? _hhmm(dep),
                        depart: flight.departureTimeHtml ?? _hhmm(dep),
                        arrive: flight.arrivalTimeHtml ?? _hhmm(arr),
                        gate: 'G${flight.id}', // API không có gate -> tạm theo id
                        seat: mainSeat?.id != null ? 'S${mainSeat!.id}' : '--',
                        seatClass: seatClass,
                        passenger: '—', // API không có passenger
                        priceText: _formatVnd(flight.minPrice),
                      ),

                      const SizedBox(height: 14),

                      if (flight.flightSeat.isNotEmpty) ...[
                        const Text(
                          'Seat classes',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        ...flight.flightSeat.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SeatRow(
                            title: s.seatType?.name ?? 'Seat',
                            price: s.priceHtml ?? _formatVnd(s.price),
                            sub: _seatSubLine(s),
                            right: 'Còn: ${s.maxPassengers ?? 0}',
                          ),
                        )),
                      ],

                      const SizedBox(height: 10),

                      if (canShowMap) ...[
                        const SizedBox(height: 6),
                        const Text(
                          'Route map',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            height: 240,
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: center ?? const LatLng(0, 0),
                                zoom: initialZoom,
                              ),
                              markers: markers,
                              polylines: polylines,
                              myLocationEnabled: false,
                              myLocationButtonEnabled: false,
                              compassEnabled: true,
                              zoomControlsEnabled: false,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if ((from?.address ?? '').trim().isNotEmpty || (to?.address ?? '').trim().isNotEmpty)
                          _MapLegend(
                            fromLabel: '$fromCode • ${from?.address ?? ''}',
                            toLabel: '$toCode • ${to?.address ?? ''}',
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _seatSubLine(FlightSeat s) {
    final parts = <String>[];
    if ((s.person ?? '').trim().isNotEmpty) parts.add('Person: ${s.person}');
    if (s.baggageCabin != null) parts.add('Cabin: ${s.baggageCabin}kg');
    if (s.baggageCheckIn != null) parts.add('Check-in: ${s.baggageCheckIn}kg');
    return parts.join(' • ');
  }
}

class _RouteHeader extends StatelessWidget {
  final String fromCode;
  final String fromName;
  final String toCode;
  final String toName;

  const _RouteHeader({
    required this.fromCode,
    required this.fromName,
    required this.toCode,
    required this.toName,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // dashed curve line + plane icon (giả lập giống ảnh)
        SizedBox(
          height: 86,
          child: CustomPaint(
            painter: _RoutePainter(),
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          left: 0,
          bottom: 0,
          child: _CodeCity(code: fromCode, city: fromName, alignLeft: true),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: _CodeCity(code: toCode, city: toName, alignLeft: false),
        ),
      ],
    );
  }
}

class _CodeCity extends StatelessWidget {
  final String code;
  final String city;
  final bool alignLeft;

  const _CodeCity({required this.code, required this.city, required this.alignLeft});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          code,
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 140,
          child: Text(
            city,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignLeft ? TextAlign.left : TextAlign.right,
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _BoardingPassCard extends StatelessWidget {
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

  const _BoardingPassCard({
    required this.coverUrl,
    required this.dateLeft,
    required this.timeRight,
    required this.fromCode,
    required this.fromName,
    required this.toCode,
    required this.toName,
    required this.airlineName,
    required this.durationText,
    required this.flightCode,
    required this.boarding,
    required this.depart,
    required this.arrive,
    required this.gate,
    required this.seat,
    required this.seatClass,
    required this.passenger,
    required this.priceText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6FAFF),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(blurRadius: 22, spreadRadius: 0, offset: Offset(0, 10), color: Color(0x1A000000)),
        ],
      ),
      child: Column(
        children: [
          // header strip
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    dateLeft.isEmpty ? '—' : dateLeft,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1B2A3A)),
                  ),
                ),
                Text(
                  timeRight,
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1B2A3A)),
                ),
              ],
            ),
          ),

          // route line
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _RouteText(code: fromCode, name: fromName, alignLeft: true),
                ),
                Column(
                  children: [
                    Icon(Icons.flight_takeoff, color: const Color(0xFF1B2A3A).withOpacity(0.8)),
                    if (durationText != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        durationText!,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black54),
                      ),
                    ],
                  ],
                ),
                Expanded(
                  child: _RouteText(code: toCode, name: toName, alignLeft: false),
                ),
              ],
            ),
          ),

          // cover (airline image) – dùng ảnh airline nếu có, không thì minh hoạ đơn giản
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 150,
                color: Colors.white,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (coverUrl != null)
                      Image.network(
                        coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          airlineName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            priceText,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // info grid like boarding pass
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF123E62),
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _MiniField(label: 'Flight', value: flightCode)),
                      Expanded(child: _MiniField(label: 'Boarding', value: boarding)),
                      Expanded(child: _MiniField(label: 'Depart', value: depart)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _MiniField(label: 'Gate', value: gate)),
                      Expanded(child: _MiniField(label: 'Seat', value: seat)),
                      Expanded(child: _MiniField(label: 'Arrive', value: arrive)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _MiniField(label: 'Class', value: seatClass)),
                      Expanded(child: _MiniField(label: 'Passenger', value: passenger)),
                      const Spacer(),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // barcode
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 60,
                color: Colors.white,
                child: CustomPaint(
                  painter: _BarcodePainter(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteText extends StatelessWidget {
  final String code;
  final String name;
  final bool alignLeft;

  const _RouteText({
    required this.code,
    required this.name,
    required this.alignLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          code,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1B2A3A)),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54),
        ),
      ],
    );
  }
}

class _MiniField extends StatelessWidget {
  final String label;
  final String value;

  const _MiniField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _SeatRow extends StatelessWidget {
  final String title;
  final String price;
  final String sub;
  final String right;

  const _SeatRow({
    required this.title,
    required this.price,
    required this.sub,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                if (sub.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(sub, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  final String fromLabel;
  final String toLabel;

  const _MapLegend({required this.fromLabel, required this.toLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fromLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(toLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/* ----------------- Painters ----------------- */

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(0.65);

    // dotted curve
    final path = Path();
    path.moveTo(size.width * 0.12, size.height * 0.58);
    path.quadraticBezierTo(size.width * 0.50, size.height * 0.10, size.width * 0.88, size.height * 0.58);

    _drawDashedPath(canvas, path, p, dash: 6, gap: 6);

    // plane icon in middle
    final plane = Paint()..color = Colors.white;
    final center = Offset(size.width * 0.50, size.height * 0.28);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(0.20);
    final r = RRect.fromRectAndRadius(const Rect.fromLTWH(-10, -3, 20, 6), const Radius.circular(3));
    canvas.drawRRect(r, plane);
    canvas.drawCircle(const Offset(-12, 0), 3, plane);
    canvas.drawCircle(const Offset(12, 0), 3, plane);
    canvas.restore();
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, {required double dash, required double gap}) {
    final metrics = path.computeMetrics().toList();
    for (final m in metrics) {
      double dist = 0;
      while (dist < m.length) {
        final next = dist + dash;
        final extract = m.extractPath(dist, math.min(next, m.length));
        canvas.drawPath(extract, paint);
        dist = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DotWorldPainter extends CustomPainter {
  final double opacity;
  _DotWorldPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = Colors.white.withOpacity(opacity);
    const step = 18.0;
    for (double y = 10; y < size.height; y += step) {
      for (double x = 10; x < size.width; x += step) {
        // tạo pattern “world map” giả lập: vùng giữa dày hơn
        final nx = (x / size.width - 0.5).abs();
        final ny = (y / size.height - 0.45).abs();
        final w = (1.0 - (nx * 1.2 + ny * 1.2)).clamp(0.0, 1.0);
        if (w > 0.25) {
          canvas.drawCircle(Offset(x, y), 1.2, dot);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.black87;
    double x = 6;
    final rnd = math.Random(8);
    while (x < size.width - 6) {
      final w = (rnd.nextInt(3) + 1).toDouble();
      final h = size.height * (0.65 + rnd.nextDouble() * 0.3);
      canvas.drawRect(Rect.fromLTWH(x, (size.height - h) / 2, w, h), p);
      x += w + (rnd.nextInt(3) + 2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}