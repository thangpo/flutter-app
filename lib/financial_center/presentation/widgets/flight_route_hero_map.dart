import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

class FlightRouteHeroMap extends StatefulWidget {
  final ll.LatLng from;
  final ll.LatLng to;
  final String fromLabel;
  final String toLabel;
  final String fromName;
  final String toName;
  final Color originColor;
  final Color destColor;
  final double splitT;
  final double planeT;
  final double curveFactor;
  final double lineWidth;
  final bool isDark;
  final bool dashedDest;
  final bool dashedOrigin;
  final EdgeInsets fitPadding;
  final bool rotateToRoute;
  final IconData planeIcon;
  final double planeRotationOffsetRad;
  final Color planeColor;

  const FlightRouteHeroMap({
    super.key,
    required this.from,
    required this.to,
    required this.fromLabel,
    required this.toLabel,
    required this.originColor,
    required this.destColor,
    required this.isDark,
    this.fromName = '',
    this.toName = '',
    this.splitT = 0.55,
    this.planeT = 0.52,
    this.curveFactor = 0.22,
    this.lineWidth = 4,
    this.dashedDest = true,
    this.dashedOrigin = true,
    this.fitPadding = const EdgeInsets.fromLTRB(64, 28, 64, 240),
    this.rotateToRoute = true,
    this.planeIcon = Icons.airplanemode_active,
    this.planeRotationOffsetRad = -math.pi / 2,
    this.planeColor = Colors.pinkAccent,
  });

  @override
  State<FlightRouteHeroMap> createState() => _FlightRouteHeroMapState();
}

class _FlightRouteHeroMapState extends State<FlightRouteHeroMap> {
  final MapController _mapController = MapController();
  bool _fitted = false;

  ll.LatLng _lerp(ll.LatLng a, ll.LatLng b, double t) {
    return ll.LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  ll.LatLng _midPoint(ll.LatLng a, ll.LatLng b) =>
      ll.LatLng((a.latitude + b.latitude) / 2.0, (a.longitude + b.longitude) / 2.0);

  double _bearingRad(ll.LatLng a, ll.LatLng b) {
    final lat1 = a.latitudeInRad;
    final lat2 = b.latitudeInRad;
    final dLon = (b.longitude - a.longitude) * (math.pi / 180.0);
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    return math.atan2(y, x);
  }

  List<ll.LatLng> _buildCurvedPoints({int steps = 160}) {
    final from = widget.from;
    final to = widget.to;
    final mid = _lerp(from, to, 0.5);
    final dx = to.longitude - from.longitude;
    final dy = to.latitude - from.latitude;
    final dist = math.sqrt(dx * dx + dy * dy);

    var px = -dy;
    var py = dx;
    final plen = math.sqrt(px * px + py * py);
    if (plen != 0) {
      px /= plen;
      py /= plen;
    }

    final offset = dist * widget.curveFactor;
    final control = ll.LatLng(
      mid.latitude + py * offset,
      mid.longitude + px * offset,
    );

    ll.LatLng bez(double t) {
      final u = 1 - t;
      final lat = u * u * from.latitude + 2 * u * t * control.latitude + t * t * to.latitude;
      final lon = u * u * from.longitude + 2 * u * t * control.longitude + t * t * to.longitude;
      return ll.LatLng(lat, lon);
    }

    return List.generate(steps + 1, (i) => bez(i / steps));
  }

  List<Polyline> _makeDashedPolylines(
      List<ll.LatLng> pts, {
        required Color color,
        required double strokeWidth,
        int dashOn = 6,
        int dashOff = 6,
      }) {
    if (pts.length < 2) return const [];

    final polylines = <Polyline>[];
    int i = 0;

    while (i < pts.length - 1) {
      final start = i;
      final end = math.min(pts.length - 1, i + dashOn);
      final seg = pts.sublist(start, end + 1);

      if (seg.length >= 2) {
        polylines.add(Polyline(points: seg, strokeWidth: strokeWidth, color: color));
      }
      i = end + dashOff;
    }

    return polylines;
  }

  Marker _airportLabelMarker({
    required bool isDark,
    required ColorScheme scheme,
    required ll.LatLng point,
    required String code,
    required String name,
    required bool placeAbove,
  }) {
    final bg = isDark
        ? Colors.black.withOpacity(0.38)
        : Colors.white.withOpacity(0.82);
    final border = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.10);

    final textColor = isDark ? Colors.white : (scheme.onSurface);
    final subTextColor = isDark ? Colors.white.withOpacity(0.90) : scheme.onSurface.withOpacity(0.72);

    final displayName = name.trim().isEmpty ? code : name;

    return Marker(
      point: point,
      rotate: false,
      width: 220,
      height: 96,
      alignment: placeAbove ? Alignment.bottomCenter : Alignment.topCenter,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                    color: Colors.black.withOpacity(isDark ? 0.30 : 0.10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    code,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: 180,
                    child: Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            _PinDot(color: isDark ? Colors.white : scheme.onSurface),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
    final from = widget.from;
    final to = widget.to;
    final points = _buildCurvedPoints();
    final bounds = LatLngBounds.fromPoints([from, to]);
    final mid = _midPoint(from, to);
    final splitIndex = (widget.splitT.clamp(0.0, 1.0) * (points.length - 1)).round();
    final planeIndex = (widget.planeT.clamp(0.0, 1.0) * (points.length - 1)).round();
    final firstPart = points.sublist(0, math.max(2, splitIndex + 1));
    final secondPart = points.sublist(math.max(0, splitIndex), points.length);
    final routeBearing = _bearingRad(from, to);
    final mapRotationRad = widget.rotateToRoute ? (routeBearing - (math.pi / 2)) : 0.0;
    final nextIdx = math.min(points.length - 1, planeIndex + 1);
    final prevIdx = math.max(0, planeIndex - 1);
    final planeBearingWorld = _bearingRad(points[prevIdx], points[nextIdx]) + widget.planeRotationOffsetRad;
    final planeAngleRelative = planeBearingWorld - mapRotationRad;
    final fromIsNorth = from.latitude > to.latitude;
    final fromPlaceAbove = !fromIsNorth;
    final toPlaceAbove = fromIsNorth;
    final topTint = isDark ? Colors.black.withOpacity(0.10) : Colors.white.withOpacity(0.06);
    final bottomGradStart = isDark ? Colors.black.withOpacity(0.00) : Colors.white.withOpacity(0.00);
    final bottomGradEnd = isDark ? Colors.black.withOpacity(0.40) : Colors.white.withOpacity(0.55);

    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: mid,
            initialZoom: 4,
            initialRotation: mapRotationRad,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
            ),
            onMapReady: () {
              if (_fitted) return;
              _fitted = true;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _mapController.fitCamera(
                  CameraFit.bounds(
                    bounds: bounds,
                    padding: widget.fitPadding,
                  ),
                );

                if (widget.rotateToRoute) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _mapController.rotate(mapRotationRad);
                  });
                }
              });
            },
          ),
          children: [
            TileLayer(
              urlTemplate: tileUrl,
              subdomains: const ['a', 'b', 'c'],
              retinaMode: true,
            ),

            PolylineLayer(
              polylines: [
                if (!widget.dashedOrigin)
                  Polyline(
                    points: firstPart,
                    strokeWidth: widget.lineWidth,
                    color: widget.originColor,
                  )
                else
                  ..._makeDashedPolylines(
                    firstPart,
                    color: widget.originColor.withOpacity(0.95),
                    strokeWidth: widget.lineWidth,
                    dashOn: 6,
                    dashOff: 6,
                  ),
                if (!widget.dashedDest)
                  Polyline(
                    points: secondPart,
                    strokeWidth: widget.lineWidth,
                    color: widget.destColor,
                  )
                else
                  ..._makeDashedPolylines(
                    secondPart,
                    color: widget.destColor.withOpacity(0.85),
                    strokeWidth: (widget.lineWidth - 1).clamp(2.0, widget.lineWidth),
                    dashOn: 6,
                    dashOff: 6,
                  ),
              ],
            ),

            MarkerLayer(
              markers: [
                _airportLabelMarker(
                  isDark: isDark,
                  scheme: scheme,
                  point: from,
                  code: widget.fromLabel,
                  name: widget.fromName,
                  placeAbove: fromPlaceAbove,
                ),
                _airportLabelMarker(
                  isDark: isDark,
                  scheme: scheme,
                  point: to,
                  code: widget.toLabel,
                  name: widget.toName,
                  placeAbove: toPlaceAbove,
                ),
                Marker(
                  point: points[planeIndex],
                  rotate: true,
                  width: 40,
                  height: 40,
                  child: Transform.rotate(
                    angle: planeAngleRelative,
                    child: Icon(widget.planeIcon, size: 40, color: widget.planeColor),
                  ),
                ),
              ],
            ),
          ],
        ),

        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(color: topTint),
          ),
        ),

        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [bottomGradStart, bottomGradEnd],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PinDot extends StatelessWidget {
  final Color color;
  const _PinDot({required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(isDark ? 0.55 : 0.18),
            ),
          ],
        ),
      ),
    );
  }
}