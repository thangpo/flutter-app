import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationToursMapScreen extends StatelessWidget {
  final String locationName;
  final String imageUrl;       // ảnh của địa điểm
  final double centerLat;
  final double centerLng;
  final double mapZoom;
  final List<Map<String, dynamic>> tours;

  const LocationToursMapScreen({
    Key? key,
    required this.locationName,
    required this.imageUrl,
    required this.centerLat,
    required this.centerLng,
    required this.mapZoom,
    required this.tours,
  }) : super(key: key);


  Marker _buildTourMarker(Map<String, dynamic> t) {
    final title = t['title'] ?? '';
    final image = t['image'] ?? '';

    return Marker(
      point: LatLng(t['lat'], t['lng']),
      width: 120,
      height: 140,
      child: Column(
        children: [
          // Bubble name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Circle image
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green, width: 3),
            ),
            child: ClipOval(
              child: Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey,
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
          ),

          const SizedBox(height: 2),

          // Pin icon
          const Icon(
            Icons.location_on,
            color: Colors.green,
            size: 28,
          ),
        ],
      ),
    );
  }

  Marker _buildLocationMarker() {
    return Marker(
      point: LatLng(centerLat, centerLng),
      width: 160,
      height: 160,
      child: Column(
        children: [
          // Title bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Text(
              locationName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Square big image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 70,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 2),

          const Icon(
            Icons.location_pin,
            size: 34,
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Marker> markers = [];
    markers.add(_buildLocationMarker());
    for (var t in tours) {
      if (t['lat'] != null && t['lng'] != null) {
        markers.add(_buildTourMarker(t));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Tour tại $locationName"),
        backgroundColor: Colors.deepPurple,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(centerLat, centerLng),
          initialZoom: mapZoom,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}