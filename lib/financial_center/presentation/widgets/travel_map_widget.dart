import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../screens/hotel_map_screen.dart';
import '../services/hotel_service.dart';
import '../services/tour_service.dart';

class TravelMapWidget extends StatefulWidget {
  const TravelMapWidget({super.key});

  @override
  State<TravelMapWidget> createState() => _TravelMapWidgetState();
}

class _TravelMapWidgetState extends State<TravelMapWidget> {
  final HotelService _hotelService = HotelService();

  final MapController _mapController = MapController();

  bool _isLoading = false;
  bool _isError = false;
  List<Map<String, dynamic>> _places = [];

  LatLng _center = const LatLng(21.0278, 105.8342);
  double _zoom = 4.8;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      final hotelsRaw = await _hotelService.fetchHotels(limit: 20);
      final toursRaw = await TourService.fetchTours();
      final hotels = _buildMapDataFromHotels(hotelsRaw);
      final tours = _buildMapDataFromTours(toursRaw);
      final all = <Map<String, dynamic>>[];
      all.addAll(hotels);
      all.addAll(tours);

      LatLng? firstValid;
      for (final p in all) {
        final lat = p['lat'] as double?;
        final lng = p['lng'] as double?;
        if (lat != null && lng != null) {
          firstValid = LatLng(lat, lng);
          break;
        }
      }

      setState(() {
        _places = all;
        if (firstValid != null) {
          _center = firstValid!;
          _zoom = 5.8;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu map travel: $e');
      setState(() {
        _isLoading = false;
        _isError = true;
      });
    }
  }

  List<Map<String, dynamic>> _buildMapDataFromHotels(List<dynamic> hotels) {
    final valid = hotels.whereType<Map>().where((h) {
      final lat = double.tryParse(h['lat']?.toString() ?? '') ?? 0;
      final lng = double.tryParse(h['lng']?.toString() ?? '') ?? 0;
      return lat != 0 && lng != 0;
    }).toList();

    return valid.map<Map<String, dynamic>>((h) {
      final price = h['price']?.toString();
      final lat = double.tryParse(h['lat']?.toString() ?? '');
      final lng = double.tryParse(h['lng']?.toString() ?? '');

      return {
        'id'          : h['id'],
        'type'        : 'hotel',
        'title'       : h['title'] ?? '',
        'slug'        : h['slug'] ?? '',
        'lat'         : lat,
        'lng'         : lng,
        'thumbnail'   : h['thumbnail'] ?? h['image_url'] ?? '',
        'location'    : h['location'] ?? '',
        'address'     : h['address'] ?? '',
        'review_score': h['review_score'],
        'price'       : price,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _buildMapDataFromTours(List<dynamic> tours) {
    final valid = tours.whereType<Map>().where((t) {
      final lat = double.tryParse(t['lat']?.toString() ?? '') ?? 0;
      final lng = double.tryParse(t['lng']?.toString() ?? '') ?? 0;
      return lat != 0 && lng != 0;
    }).toList();

    return valid.map<Map<String, dynamic>>((t) {
      final price = t['price']?.toString();
      final lat = double.tryParse(t['lat']?.toString() ?? '');
      final lng = double.tryParse(t['lng']?.toString() ?? '');

      return {
        'id'          : t['id'],
        'type'        : 'tour',
        'title'       : t['title'] ?? '',
        'slug'        : t['slug'] ?? '',
        'lat'         : lat,
        'lng'         : lng,
        'thumbnail'   : t['image_url'] ?? t['thumbnail'] ?? '',
        'location'    : t['location'] ?? '',
        'address'     : t['location'] ?? '',
        'review_score': t['review_score'],
        'price'       : price,
      };
    }).toList();
  }

  List<Marker> _buildMarkers() {
    return _places.map((p) {
      final lat = p['lat'] as double?;
      final lng = p['lng'] as double?;
      if (lat == null || lng == null) return null;

      final isTour = p['type'] == 'tour';
      final title = (p['title']?.toString() ?? '').trim();
      final shortTitle =
      title.length > 18 ? '${title.substring(0, 18)}…' : title;

      return Marker(
        point: LatLng(lat, lng),
        width: 120,
        height: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (shortTitle.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.16),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  shortTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                isTour ? Icons.flag_rounded : Icons.hotel_rounded,
                size: 22,
                color: isTour
                    ? const Color(0xFFEC4899)
                    : const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      );
    }).whereType<Marker>().toList();
  }

  void _openFullMap() {
    if (_places.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có dữ liệu địa điểm để hiển thị bản đồ.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HotelMapScreen(
          hotels: _places,
          initialHotel: _places.first,
          autoLocateOnStart: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.grey.withOpacity(0.15),
          ),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_isError) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.red.withOpacity(0.05),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(height: 8),
                const Text('Lỗi tải dữ liệu bản đồ'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loadData,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_places.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.grey.withOpacity(0.08),
          ),
          alignment: Alignment.center,
          child: const Text('Chưa có tour / khách sạn để hiển thị bản đồ.'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _openFullMap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 400,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: _zoom,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.vnshop.vietnamtoure',
                    ),
                    MarkerLayer(
                      markers: _buildMarkers(),
                    ),
                  ],
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.travel_explore_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Bản đồ tour & khách sạn',
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
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.map_rounded,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Xem tất cả trên bản đồ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}