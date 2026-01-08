import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HotelMapPreview extends StatelessWidget {
  final List<Map<String, dynamic>> hotels;
  final LatLng center;
  final double zoom;
  final MapController controller;
  final VoidCallback? onOpenMap;
  final BorderRadius borderRadius;

  // NEW
  final bool showTopLabel;

  const HotelMapPreview({
    super.key,
    required this.hotels,
    required this.center,
    required this.zoom,
    required this.controller,
    this.onOpenMap,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.showTopLabel = true,
  });

  List<Marker> _buildMarkers() {
    return hotels.map((h) {
      final lat = double.tryParse(h['lat']?.toString() ?? '');
      final lng = double.tryParse(h['lng']?.toString() ?? '');
      if (lat == null || lng == null || (lat == 0 && lng == 0)) return null;

      return Marker(
        point: LatLng(lat, lng),
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on,
            color: Color(0xFFEF4444),
            size: 26,
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: controller,
              options: MapOptions(
                initialCenter: center,
                initialZoom: zoom,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.vnshop.vietnamtoure',
                ),
                MarkerLayer(markers: _buildMarkers()),
              ],
            ),
          ),

          // TOP LABEL (optional)
          if (showTopLabel)
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Bản đồ khách sạn',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    if (onOpenMap == null) return content;

    return GestureDetector(
      onTap: onOpenMap,
      child: content,
    );
  }
}