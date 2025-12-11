import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:provider/provider.dart';

import 'popup_hotel.dart';
import 'popup_tour.dart';
import 'nearby_strip.dart';
import 'vietnam_islands_overlay.dart';

class HotelMapScreen extends StatefulWidget {
  final List<Map<String, dynamic>> hotels;
  final Map<String, dynamic>? initialHotel;
  final bool autoLocateOnStart;

  const HotelMapScreen({
    super.key,
    required this.hotels,
    this.initialHotel,
    this.autoLocateOnStart = true,
  });

  @override
  State<HotelMapScreen> createState() => _HotelMapScreenState();
}

class _HotelMapScreenState extends State<HotelMapScreen> {
  late MapController _map;

  Map<String, dynamic>? _selected;

  bool _showHotelPopup = false;
  bool _showTourPopup = false;
  bool _showNearbyStrip = false;

  List<Map<String, dynamic>> _nearby = [];

  LatLng _center = const LatLng(21.03, 105.8);
  double _zoom = 12;

  @override
  void initState() {
    super.initState();
    _map = MapController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _goToMyLocation();
      _applyInitialSelection();
    });
  }

  void _applyInitialSelection() {
    if (widget.initialHotel == null) return;

    final h = widget.initialHotel!;
    _selected = h;

    final lat = double.tryParse(h['lat'].toString());
    final lng = double.tryParse(h['lng'].toString());
    if (lat == null || lng == null) return;

    _map.move(LatLng(lat, lng), 15);
  }

  Future<void> _goToMyLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final user = LatLng(pos.latitude, pos.longitude);

      setState(() {
        _center = user;
        _zoom = 15;
      });

      _map.move(user, 15);
      _loadNearbyUser(user);

    } catch (e) {
      debugPrint("Location Error: $e");
    }
  }

  void _loadNearbyUser(LatLng user) {
    final calc = const Distance();
    final List<Map<String, dynamic>> rs = [];

    for (final h in widget.hotels) {
      final la = double.tryParse(h['lat'].toString());
      final lo = double.tryParse(h['lng'].toString());
      if (la == null || lo == null) continue;

      final d = calc(user, LatLng(la, lo));

      if (d <= 15000) {
        rs.add({...h, '_distance': d});
      }
    }

    rs.sort((a, b) => (a['_distance'] as double).compareTo(b['_distance'] as double));

    setState(() {
      _nearby = rs;
      _showNearbyStrip = rs.isNotEmpty;
      _selected = null;
      _showHotelPopup = false;
      _showTourPopup = false;
    });
  }

  bool _isHotel(Map<String, dynamic>? h) => h != null && h['type'] != 'tour';
  bool _isTour(Map<String, dynamic>? h) => h != null && h['type'] == 'tour';

  void _selectItem(Map<String, dynamic> item) {
    final isTour = _isTour(item);

    setState(() {
      _selected = item;
      _showHotelPopup = !isTour;
      _showTourPopup = isTour;
      _showNearbyStrip = false;
    });

    final lat = double.tryParse(item['lat'].toString());
    final lng = double.tryParse(item['lng'].toString());
    if (lat != null && lng != null) {
      _map.move(LatLng(lat, lng), 15);
    }
  }

  List<Marker> _markers() {
    return widget.hotels.map((h) {
      final la = double.tryParse(h['lat'].toString());
      final lo = double.tryParse(h['lng'].toString());
      if (la == null || lo == null) return null;

      final selected = _selected?['id'] == h['id'];

      final name = h['title'] ?? "";
      final short =
      name.length > 18 ? "${name.substring(0, 18)}…" : name;

      final rating = double.tryParse(h['review_score']?.toString() ?? '');
      final isTour = _isTour(h);

      final img = h['thumbnail'] ?? h['image_url'] ?? "";

      return Marker(
        point: LatLng(la, lo),
        width: 140,
        height: 110,
        child: GestureDetector(
          onTap: () => _selectItem(h),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(short,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                    if (!isTour && rating != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 11),
                          )
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: selected ? Colors.green : Colors.white, width: 3),
                  image: img != ""
                      ? DecorationImage(image: NetworkImage(img), fit: BoxFit.cover)
                      : null,
                  color: Colors.grey[300],
                ),
                child: img == ""
                    ? Icon(
                  isTour ? Icons.hiking : Icons.bed,
                  color: selected ? Colors.green : Colors.white,
                )
                    : null,
              ),
            ],
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeController>(context).darkTheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(initialCenter: _center, initialZoom: _zoom),
              children: [
                TileLayer(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png"),

                VietnamIslandsOverlay(isDark: isDark),

                MarkerLayer(markers: _markers()),
              ],
            ),
          ),

          if (_showNearbyStrip)
            NearbyStrip(
              items: _nearby,
              onTapItem: (h) => _selectItem(h),
              onClose: () => setState(() => _showNearbyStrip = false),
            ),

          if (_showHotelPopup && _selected != null && _isHotel(_selected))
            HotelPopup(
              data: _selected!,
              onClose: () => setState(() => _showHotelPopup = false),
            ),

          if (_showTourPopup && _selected != null && _isTour(_selected))
            TourPopup(
              data: _selected!,
              onClose: () => setState(() => _showTourPopup = false),
            ),
        ],
      ),
    );
  }
}