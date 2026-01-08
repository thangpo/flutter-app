import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/hotel_service.dart';
import '../widgets/hotel_map_preview.dart';
import '../widgets/hotel_highlight_carousel.dart';
import '../widgets/hotel_list_section.dart';
import 'hotel_map_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

class HotelHomeShell extends StatefulWidget {
  const HotelHomeShell({super.key});

  @override
  State<HotelHomeShell> createState() => _HotelHomeShellState();
}

class _HotelHomeShellState extends State<HotelHomeShell> {
  final HotelService _hotelService = HotelService();

  int _tabIndex = 0;

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

  String _tr(BuildContext context, String key, String fallback) {
    return getTranslated(key, context) ?? fallback;
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

          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lng = double.tryParse(item['lng']?.toString() ?? '');

          if (firstValid == null && lat != null && lng != null && !(lat == 0 && lng == 0)) {
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
      if (lat == null || lng == null || (lat == 0 && lng == 0)) continue;

      result.add({
        'id': h['id'],
        'type': 'hotel',
        'title': h['title'] ?? '',
        'slug': h['slug'] ?? '',
        'lat': lat,
        'lng': lng,
        'thumbnail': h['thumbnail'] ?? h['image_url'] ?? '',
        'location': h['location'] ?? '',
        'address': h['address'] ?? '',
        'review_score': h['review_score'],
        'price': h['price']?.toString(),
      });
    }

    return result;
  }

  void _moveToHotel(Map<String, dynamic> hotel) {
    final lat = double.tryParse(hotel['lat']?.toString() ?? '');
    final lng = double.tryParse(hotel['lng']?.toString() ?? '');
    if (lat == null || lng == null) return;

    final target = LatLng(lat, lng);

    setState(() {
      _mapCenter = target;
      _mapZoom = 12;
      _tabIndex = 0; // chuyển về tab Map luôn nếu muốn
    });

    _mapController.move(target, 12);
  }

  void _openFullMapScreen(BuildContext context, List<Map<String, dynamic>> mapData) {
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
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context, listen: true);
    final isDark = themeController.darkTheme;
    final mapData = _buildMapDataFromHotels();

    final bgColor = isDark ? const Color(0xFF020617) : const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: bgColor,

      // Nếu Bố muốn AppBar chung (optional)
      appBar: AppBar(
        title: Text(
          _tabIndex == 0
              ? _tr(context, 'hotel_map_title', 'Bản đồ')
              : _tabIndex == 1
              ? _tr(context, 'hotel_banner_title', 'Nổi bật')
              : _tr(context, 'hotel_list_title', 'Danh sách'),
        ),
        backgroundColor: isDark ? const Color(0xFF020617) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: isDark ? 0 : 0.5,
        actions: [
          IconButton(
            onPressed: _loadHotels,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isError
          ? _buildError(context, isDark)
          : _hotels.isEmpty
          ? _buildEmpty(context, isDark)
          : IndexedStack(
        index: _tabIndex,
        children: [
          // ===== TAB 1: MAP FULL SCREEN =====
          // Map full màn hình: dùng Positioned.fill / Expanded
          Stack(
            children: [
              Positioned.fill(
                child: HotelMapPreview(
                  hotels: _hotels,
                  center: _mapCenter,
                  zoom: _mapZoom,
                  controller: _mapController,
                  onOpenMap: null, // full screen thì không cần tap open
                  borderRadius: BorderRadius.zero,
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    if (mapData.isEmpty) return;
                    _openFullMapScreen(context, mapData);
                  },
                  icon: const Icon(Icons.open_in_full),
                  label: Text(_tr(context, 'open_full_map', 'Mở bản đồ')),
                ),
              ),
            ],
          ),

          // ===== TAB 2: BANNER/CAROUSEL FULL SCREEN =====
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: HotelHighlightCarousel(
                hotels: _hotels,
                onTap: (hotel) => _moveToHotel(hotel),
              ),
            ),
          ),

          // ===== TAB 3: LIST FULL SCREEN =====
          RefreshIndicator(
            onRefresh: _loadHotels,
            color: const Color(0xFF0EA5E9),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: HotelListSection(
                hotels: _hotels,
                mapData: mapData,
                isDark: isDark,
                tr: _tr,
                onHotelTap: (hotel) => _moveToHotel(hotel),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Banner',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'List',
          ),
        ],
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
            Icon(Icons.wifi_off_rounded, size: 48, color: isDark ? Colors.white54 : Colors.grey[500]),
            const SizedBox(height: 12),
            Text(
              _tr(context, 'hotel_error_title', 'Không tải được dữ liệu'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 6),
            Text(
              _tr(context, 'hotel_error_subtitle', 'Vui lòng kiểm tra kết nối và thử lại.'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadHotels,
              icon: const Icon(Icons.refresh),
              label: Text(_tr(context, 'retry', 'Thử lại')),
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
            Icon(Icons.hotel_class_rounded, size: 48, color: isDark ? Colors.white54 : Colors.grey[500]),
            const SizedBox(height: 12),
            Text(
              _tr(context, 'hotel_empty_title', 'Chưa có khách sạn nào'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}