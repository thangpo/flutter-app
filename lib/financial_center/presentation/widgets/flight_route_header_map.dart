import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

class FlightRouteHeaderMap extends StatefulWidget {
  final ll.LatLng from;
  final ll.LatLng to;

  final String fromCode;
  final String fromName;
  final String toCode;
  final String toName;

  final double height;
  final double borderRadius;

  const FlightRouteHeaderMap({
    super.key,
    required this.from,
    required this.to,
    required this.fromCode,
    required this.fromName,
    required this.toCode,
    required this.toName,
    this.height = 220,
    this.borderRadius = 0,
  });

  @override
  State<FlightRouteHeaderMap> createState() => _FlightRouteHeaderMapState();
}

class _FlightRouteHeaderMapState extends State<FlightRouteHeaderMap> {
  final MapController _mapController = MapController();
  bool _fitted = false;

  @override
  Widget build(BuildContext context) {
    final from = widget.from;
    final to = widget.to;

    final bounds = LatLngBounds.fromPoints([from, to]);
    final mid = _midPoint(from, to);

    // bearing (radians) from->to
    final bearing = _bearingRad(from, to);

    // rotate map so flight direction becomes horizontal (east)
    final mapRotation = bearing - math.pi / 2;

    final dashed = _buildDashedPolylines(
      from,
      to,
      steps: 140,
      dashSegments: 6,
      gapSegments: 6,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: mid,
                initialZoom: 4,
                initialRotation: mapRotation,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                ),
                onMapReady: () {
                  if (_fitted) return;
                  _fitted = true;

                  // Fit trước, rồi rotate lại để không bị fit reset rotation
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _mapController.fitCamera(
                      CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.fromLTRB(64, 28, 64, 28),
                      ),
                    );

                    // rotate lại sau fit (quan trọng)
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _mapController.rotate(mapRotation);
                    });
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.your.app',
                ),
                PolylineLayer(polylines: dashed),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: from,
                      width: 40,
                      height: 40,
                      child: const _PinDot(color: Colors.white),
                    ),
                    Marker(
                      point: to,
                      width: 40,
                      height: 40,
                      child: const _PinDot(color: Colors.white),
                    ),
                    Marker(
                      point: mid,
                      width: 34,
                      height: 34,
                      child: Transform.rotate(
                        angle: bearing, // icon plane xoay theo hướng bay
                        child: const Icon(Icons.flight, size: 22, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // (TÙY CHỌN) lớp tối nhẹ toàn map
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(color: Colors.black.withOpacity(0.10)),
              ),
            ),

            // Scrim gradient: tối phần dưới để chữ trắng nổi rõ
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.00),
                        Colors.black.withOpacity(0.38),
                      ],
                      stops: const [0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Labels
            Positioned(
              left: 14,
              bottom: 12,
              child: _CodeCityHeader(
                code: widget.fromCode,
                name: widget.fromName,
                alignLeft: true,
              ),
            ),
            Positioned(
              right: 14,
              bottom: 12,
              child: _CodeCityHeader(
                code: widget.toCode,
                name: widget.toName,
                alignLeft: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static ll.LatLng _midPoint(ll.LatLng a, ll.LatLng b) =>
      ll.LatLng((a.latitude + b.latitude) / 2.0, (a.longitude + b.longitude) / 2.0);

  static double _deg2rad(double d) => d * (math.pi / 180.0);

  static double _bearingRad(ll.LatLng a, ll.LatLng b) {
    final lat1 = _deg2rad(a.latitude);
    final lat2 = _deg2rad(b.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return math.atan2(y, x);
  }

  static List<Polyline> _buildDashedPolylines(
      ll.LatLng a,
      ll.LatLng b, {
        required int steps,
        required int dashSegments,
        required int gapSegments,
      }) {
    final points = <ll.LatLng>[];
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      points.add(
        ll.LatLng(
          a.latitude + (b.latitude - a.latitude) * t,
          a.longitude + (b.longitude - a.longitude) * t,
        ),
      );
    }

    final cycle = dashSegments + gapSegments;
    final polylines = <Polyline>[];
    List<ll.LatLng> current = [];

    for (int i = 0; i < points.length - 1; i++) {
      final inDash = (i % cycle) < dashSegments;

      if (inDash) {
        if (current.isEmpty) current.add(points[i]);
        current.add(points[i + 1]);
      } else {
        if (current.length >= 2) {
          polylines.add(
            Polyline(
              points: List<ll.LatLng>.from(current),
              strokeWidth: 2.2,
              color: Colors.black.withOpacity(0.85),

            ),
          );
        }
        current = [];
      }
    }

    if (current.length >= 2) {
      polylines.add(
        Polyline(
          points: List<ll.LatLng>.from(current),
          strokeWidth: 2.2,
          color: Colors.black.withOpacity(0.85),
        ),
      );
    }

    return polylines;
  }
}

class _CodeCityHeader extends StatelessWidget {
  final String code;
  final String name;
  final bool alignLeft;

  const _CodeCityHeader({
    required this.code,
    required this.name,
    required this.alignLeft,
  });

  @override
  Widget build(BuildContext context) {
    final shadow = const [
      Shadow(blurRadius: 12, color: Colors.black87, offset: Offset(0, 2)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
      ),
      child: Column(
        crossAxisAlignment:
        alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(
            code,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              shadows: shadow,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: 140,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: alignLeft ? TextAlign.left : TextAlign.right,
              style: TextStyle(
                color: Colors.white.withOpacity(0.90),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                shadows: shadow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinDot extends StatelessWidget {
  final Color color;
  const _PinDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black54)],
        ),
      ),
    );
  }
}
