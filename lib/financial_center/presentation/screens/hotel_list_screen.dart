import 'dart:math';
import 'hotel_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/hotel_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

class HotelListScreen extends StatefulWidget {
  const HotelListScreen({super.key});
  @override
  State<HotelListScreen> createState() => _HotelListScreenState();
}

class _HotelListScreenState extends State<HotelListScreen> {
  final HotelService _hotelService = HotelService();

  List<Map<String, dynamic>> _hotels = [];
  bool _isLoading = false;
  bool _isError = false;

  final MapController _mapController = MapController();
  LatLng _mapCenter = const LatLng(21.0278, 105.8342);
  double _mapZoom = 5.2;

  @override
  void initState() {
    super.initState();
    _loadHotels();
  }

  Future<void> _loadHotels() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      final data = await _hotelService.fetchHotels(limit: 20);
      final List<Map<String, dynamic>> hotels = [];

      LatLng? firstValid;

      for (final item in data) {
        if (item is Map<String, dynamic>) {
          hotels.add(item);

          final latStr = item['lat']?.toString();
          final lngStr = item['lng']?.toString();
          final lat = double.tryParse(latStr ?? '');
          final lng = double.tryParse(lngStr ?? '');

          if (firstValid == null && lat != null && lng != null) {
            firstValid = LatLng(lat, lng);
          }
        }
      }

      setState(() {
        _hotels = hotels;
        if (firstValid != null) {
          _mapCenter = firstValid!;
          _mapZoom = 6.5;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Lỗi tải hotels: $e');
      setState(() {
        _isLoading = false;
        _isError = true;
      });
    }
  }

  List<Map<String, dynamic>> _buildMapDataFromHotels() {
    final List<Map<String, dynamic>> result = [];

    for (final h in _hotels) {
      final lat = double.tryParse(h['lat']?.toString() ?? '');
      final lng = double.tryParse(h['lng']?.toString() ?? '');

      if (lat == null || lng == null || (lat == 0 && lng == 0)) {
        continue;
      }

      final price = h['price']?.toString();

      result.add({
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
      });
    }

    return result;
  }

  String _tr(BuildContext context, String key, String fallback) {
    return getTranslated(key, context) ?? fallback;
  }

  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];

    for (final h in _hotels) {
      final lat = double.tryParse(h['lat']?.toString() ?? '');
      final lng = double.tryParse(h['lng']?.toString() ?? '');
      if (lat == null || lng == null) continue;

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {

            },
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
          ),
        ),
      );
    }
    return markers;
  }

  void _moveToHotel(Map<String, dynamic> hotel) {
    final lat = double.tryParse(hotel['lat']?.toString() ?? '');
    final lng = double.tryParse(hotel['lng']?.toString() ?? '');
    if (lat == null || lng == null) return;

    final target = LatLng(lat, lng);
    _mapCenter = target;
    _mapZoom = 12;
    _mapController.move(target, _mapZoom);
  }

  String _formatPrice(String? price) {
    if (price == null || price.isEmpty) return '';
    return '$price \$';
  }

  @override
  Widget build(BuildContext context) {
    final themeController =
    Provider.of<ThemeController>(context, listen: true);
    final isDark = themeController.darkTheme;

    final bgColor =
    isDark ? const Color(0xFF020617) : const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          _tr(context, 'hotel_list_title', 'Khách sạn nổi bật'),
        ),
        backgroundColor: isDark ? const Color(0xFF020617) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: isDark ? 0 : 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: _loadHotels,
        color: const Color(0xFF0EA5E9),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _isError
            ? _buildError(context, isDark)
            : _hotels.isEmpty
            ? _buildEmpty(context, isDark)
            : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () {
                    final mapData =
                    _buildMapDataFromHotels();

                    if (mapData.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Không có khách sạn nào có tọa độ để hiển thị bản đồ.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HotelMapScreen(
                          hotels: mapData,
                          initialHotel: mapData.first,
                          autoLocateOnStart: true,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      height: 240,
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _mapCenter,
                              initialZoom: _mapZoom,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                'com.vnshop.vietnamtoure',
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
                              padding: const EdgeInsets
                                  .symmetric(
                                  horizontal: 10,
                                  vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black
                                    .withOpacity(0.45),
                                borderRadius:
                                BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize:
                                MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.map_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _tr(
                                      context,
                                      'hotel_map_label',
                                      'Bản đồ khách sạn',
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight:
                                      FontWeight.w500,
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
              ),

              const SizedBox(height: 20),

              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _tr(
                    context,
                    'hotel_best_deals',
                    'Ưu đãi khách sạn dành cho bạn',
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF111827),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              ListView.builder(
                shrinkWrap: true,
                physics:
                const NeverScrollableScrollPhysics(),
                itemCount: _hotels.length,
                itemBuilder: (context, index) {
                  final h = _hotels[index];
                  return _buildHotelCard(
                    context: context,
                    hotel: h,
                    isDark: isDark,
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: isDark ? Colors.white54 : Colors.grey[500],
            ),
            const SizedBox(height: 12),
            Text(
              _tr(context, 'hotel_error_title', 'Không tải được dữ liệu'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _tr(
                context,
                'hotel_error_subtitle',
                'Vui lòng kiểm tra kết nối và thử lại.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadHotels,
              icon: const Icon(Icons.refresh),
              label: Text(
                _tr(context, 'retry', 'Thử lại'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hotel_class_rounded,
              size: 48,
              color: isDark ? Colors.white54 : Colors.grey[500],
            ),
            const SizedBox(height: 12),
            Text(
              _tr(
                context,
                'hotel_empty_title',
                'Chưa có khách sạn nào',
              ),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelCard({
    required BuildContext context,
    required Map<String, dynamic> hotel,
    required bool isDark,
  }) {
    final title = hotel['title']?.toString() ?? '';
    final location = hotel['location']?.toString() ?? '';
    final address = hotel['address']?.toString() ?? '';
    final thumb = hotel['thumbnail']?.toString() ?? '';
    final rating = double.tryParse(hotel['review_score']?.toString() ?? '');
    final price = _formatPrice(hotel['price']?.toString());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF020617) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          _moveToHotel(hotel);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: thumb.isNotEmpty
                      ? Image.network(
                    thumb,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child:
                      const Icon(Icons.image_not_supported),
                    ),
                  )
                      : Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 32),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: Color(0xFF0EA5E9),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white70
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                        isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (rating != null) ...[
                          Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Colors.amber[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _tr(
                              context,
                              'hotel_rating_label',
                              'Điểm đánh giá',
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (price.isNotEmpty) ...[
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0EA5E9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _tr(context, 'hotel_per_night', 'mỗi đêm'),
                      style: TextStyle(
                        fontSize: 11,
                        color:
                        isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: () {
                      final mapData = _buildMapDataFromHotels();
                      if (mapData.isEmpty) return;

                      final id = hotel['id'];
                      Map<String, dynamic>? initial;
                      try {
                        initial = mapData.firstWhere(
                              (h) => h['id'] == id,
                        );
                      } catch (_) {
                        initial = mapData.first;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HotelMapScreen(
                            hotels: mapData,
                            initialHotel: initial,
                            autoLocateOnStart: true,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      side: BorderSide(
                        color:
                        const Color(0xFF0EA5E9).withOpacity(0.8),
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(
                      Icons.map_rounded,
                      size: 14,
                    ),
                    label: Text(
                      _tr(
                        context,
                        'hotel_view_on_map',
                        'Xem bản đồ',
                      ),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}