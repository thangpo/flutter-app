import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/hotel_service.dart';
import '../widgets/hotel_map_preview.dart';
import '../widgets/hotel_list_section.dart';
import '../widgets/hotel_highlight_carousel.dart';
import 'hotel_map_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

class HotelListScreen extends StatefulWidget {
  const HotelListScreen({super.key});

  @override
  State<HotelListScreen> createState() => _HotelListScreenState();
}

class _HotelListScreenState extends State<HotelListScreen> {
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

  String _tr(BuildContext context, String key, String fallback) {
    return getTranslated(key, context) ?? fallback;
  }

  void _moveToHotel(Map<String, dynamic> hotel) {
    final lat = double.tryParse(hotel['lat']?.toString() ?? '');
    final lng = double.tryParse(hotel['lng']?.toString() ?? '');
    if (lat == null || lng == null) return;

    final target = LatLng(lat, lng);

    setState(() {
      _mapCenter = target;
      _mapZoom = 12;
      _tabIndex = 0; // nhảy về tab Map luôn
    });

    _mapController.move(target, 12);
  }

  void _openFullMap(BuildContext context, List<Map<String, dynamic>> mapData, Map<String, dynamic> initial) {
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
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context, listen: true);
    final isDark = themeController.darkTheme;

    final mapData = _buildMapDataFromHotels();
    final isMapTab = _tabIndex == 0;

    return Scaffold(
      // Tab Map cần full màn hình => không AppBar, và extend body
      extendBodyBehindAppBar: isMapTab,
      appBar: isMapTab
          ? null
          : AppBar(
        title: Text(
          _tabIndex == 1
              ? _tr(context, 'hotel_banner_title', 'Nổi bật')
              : _tr(context, 'hotel_list_title', 'Danh sách khách sạn'),
        ),
        backgroundColor: isDark ? const Color(0xFF020617) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: isDark ? 0 : 0.5,
        actions: [
          IconButton(
            onPressed: _loadHotels,
            icon: const Icon(Icons.refresh),
          )
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
        // TAB 1: MAP (giữ nguyên của bố)
        Stack(
          children: [
            Positioned.fill(
              child: HotelMapPreview(
                hotels: _hotels,
                center: _mapCenter,
                zoom: _mapZoom,
                controller: _mapController,
                onOpenMap: null,
                borderRadius: BorderRadius.zero,
                showTopLabel: false,
              ),
            ),
            // ... phần buttons của bố giữ nguyên ...
          ],
        ),

        // TAB 2: BANNER (đã sửa)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: HotelHighlightCarousel(
              hotels: _hotels,
            ),
          ),
        ),

        // TAB 3: LIST (đã sửa)
        RefreshIndicator(
          onRefresh: _loadHotels,
          color: const Color(0xFF0EA5E9),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: HotelListSection(
              hotels: _hotels,
              isDark: isDark,
              tr: _tr,
            ),
          ),
        ),
      ],
    ),

    bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: _tr(context, 'tab_map', 'Map'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_awesome_outlined),
            selectedIcon: const Icon(Icons.auto_awesome),
            label: _tr(context, 'tab_banner', 'Banner'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt),
            label: _tr(context, 'tab_list', 'List'),
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

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.95),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 22, color: Colors.black87),
        ),
      ),
    );
  }
}