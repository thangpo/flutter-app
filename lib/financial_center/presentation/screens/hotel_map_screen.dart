import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

class HotelMapScreen extends StatefulWidget {
  final List<Map<String, dynamic>> hotels;
  final Map<String, dynamic>? initialHotel;

  const HotelMapScreen({
    super.key,
    required this.hotels,
    this.initialHotel,
  });

  @override
  State<HotelMapScreen> createState() => _HotelMapScreenState();
}

class _HotelMapScreenState extends State<HotelMapScreen> {
  late MapController _mapController;
  late TextEditingController _searchController;

  LatLng _center = const LatLng(21.0278, 105.8342);
  double _zoom = 12;

  Map<String, dynamic>? _selectedHotel;
  LatLng? _userLocation;

  bool _showNearbyStrip = false;
  bool _isPopupVisible = true; // chỉ điều khiển ẩn/hiện popup, không xoá selected
  List<Map<String, dynamic>> _nearbyHotels = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _searchController = TextEditingController();
    _initCenterAndSelected();
  }

  void _initCenterAndSelected() {
    Map<String, dynamic>? hotel = widget.initialHotel;
    hotel ??= widget.hotels.isNotEmpty ? widget.hotels.first : null;

    if (hotel != null) {
      final lat = double.tryParse(hotel['lat']?.toString() ?? '');
      final lng = double.tryParse(hotel['lng']?.toString() ?? '');
      if (lat != null && lng != null) {
        _center = LatLng(lat, lng);
        _zoom = 14;
        _selectedHotel = hotel;
        _isPopupVisible = true;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  String _tr(BuildContext context, String key, String fallback) {
    try {
      return getTranslated(key, context) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  String _formatPriceVnd(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final value = double.tryParse(raw.replaceAll(',', '')) ?? 0;
      final vnd = (value * 1000).round();
      final f = NumberFormat('#,###', 'vi_VN');
      return '${f.format(vnd)} đ';
    } catch (_) {
      return '';
    }
  }

  void _selectHotel(Map<String, dynamic> hotel, {bool moveCamera = true}) {
    if (!mounted) return;

    setState(() {
      _selectedHotel = hotel;
      _isPopupVisible = true;   // mỗi lần chọn thì hiện popup
      _showNearbyStrip = false; // tắt strip đề xuất
    });

    if (moveCamera) {
      final lat = double.tryParse(hotel['lat']?.toString() ?? '');
      final lng = double.tryParse(hotel['lng']?.toString() ?? '');
      if (lat != null && lng != null) {
        final target = LatLng(lat, lng);
        _center = target;
        _zoom = 15;
        _mapController.move(target, _zoom);
      }
    }
  }

  void _searchHotel(String query) {
    if (query.trim().isEmpty) return;

    final q = query.toLowerCase();
    final hotel = widget.hotels.firstWhere(
          (h) {
        final title = h['title']?.toString().toLowerCase() ?? '';
        final location = h['location']?.toString().toLowerCase() ?? '';
        return title.contains(q) || location.contains(q);
      },
      orElse: () => {},
    );

    if (hotel.isNotEmpty) {
      _selectHotel(hotel);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(context, 'hotel_map_not_found',
                'Không tìm thấy khách sạn phù hợp.'),
          ),
        ),
      );
    }
  }

  Future<void> _goToMyLocation({required bool showNearbyStrip}) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _tr(context, 'location_service_disabled',
                  'Vui lòng bật dịch vụ vị trí của thiết bị.'),
            ),
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _tr(context, 'location_permission_denied',
                  'Ứng dụng không được cấp quyền vị trí.'),
            ),
          ),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      if (!mounted) return;

      final userLatLng = LatLng(pos.latitude, pos.longitude);

      setState(() {
        _userLocation = userLatLng;
        _center = userLatLng;
        _zoom = 15;
      });
      _mapController.move(userLatLng, _zoom);

      // Tính khách sạn gần trong bán kính 5km
      final distance = const Distance();
      final List<Map<String, dynamic>> nearbyHotels = [];

      for (final h in widget.hotels) {
        final lat = double.tryParse(h['lat']?.toString() ?? '');
        final lng = double.tryParse(h['lng']?.toString() ?? '');
        if (lat == null || lng == null) continue;

        final d = distance(userLatLng, LatLng(lat, lng));
        if (d <= 5000) {
          final copy = Map<String, dynamic>.from(h);
          copy['_distance'] = d;
          nearbyHotels.add(copy);
        }
      }

      nearbyHotels.sort((a, b) {
        final da = (a['_distance'] as double?) ?? double.infinity;
        final db = (b['_distance'] as double?) ?? double.infinity;
        return da.compareTo(db);
      });

      if (!mounted) return;

      if (nearbyHotels.isNotEmpty) {
        setState(() {
          _nearbyHotels = nearbyHotels;
          _showNearbyStrip = showNearbyStrip;
          if (showNearbyStrip) {
            // Khi đang xem strip đề xuất thì ẩn popup
            _isPopupVisible = false;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Có ${nearbyHotels.length} khách sạn quanh vị trí của bạn.',
            ),
          ),
        );
      } else {
        setState(() {
          _nearbyHotels = [];
          _showNearbyStrip = false;
          _isPopupVisible = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _tr(
                context,
                'hotel_nearby_not_found',
                'Không tìm thấy khách sạn nào gần vị trí của bạn.',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Lỗi lấy vị trí: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(context, 'location_error', 'Không lấy được vị trí hiện tại.'),
          ),
        ),
      );
    }
  }

  List<Marker> _buildHotelMarkers() {
    return widget.hotels.map((h) {
      final lat = double.tryParse(h['lat']?.toString() ?? '');
      final lng = double.tryParse(h['lng']?.toString() ?? '');
      if (lat == null || lng == null) return null;

      final isSelected =
          _selectedHotel != null && _selectedHotel!['id'] == h['id'];

      final title = (h['title']?.toString() ?? '').trim();
      final shortTitle =
      title.length > 18 ? '${title.substring(0, 18)}…' : title;

      return Marker(
        point: LatLng(lat, lng),
        width: 120,
        height: 70,
        child: GestureDetector(
          onTap: () => _selectHotel(h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (shortTitle.isNotEmpty)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
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
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF10B981) : Colors.white,
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
                  Icons.location_on_rounded,
                  size: isSelected ? 28 : 24,
                  color: isSelected ? Colors.white : const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }

  Marker? _buildUserMarker() {
    if (_userLocation == null) return null;
    return Marker(
      point: _userLocation!,
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.person_pin_circle_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildNearbyStrip(bool isDark) {
    if (!_showNearbyStrip || _nearbyHotels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _tr(context, 'hotel_nearby_title', 'Khách sạn gần bạn'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _showNearbyStrip = false;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _nearbyHotels.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final h = _nearbyHotels[index];
                  final title = h['title']?.toString() ?? '';
                  final thumb = h['thumbnail']?.toString() ?? '';
                  final rating =
                  double.tryParse(h['review_score']?.toString() ?? '');
                  final d = (h['_distance'] as double?) ?? 0;
                  final km = (d / 1000).toStringAsFixed(1);

                  return GestureDetector(
                    onTap: () {
                      _selectHotel(h, moveCamera: true);
                    },
                    child: SizedBox(
                      width: 180,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            thumb.isNotEmpty
                                ? Image.network(
                              thumb,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white,
                                ),
                              ),
                            )
                                : Container(
                              color: Colors.grey[400],
                              child: const Icon(
                                Icons.image,
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.65),
                                    Colors.black.withOpacity(0.15),
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (rating != null) ...[
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 14,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Icon(
                                        Icons.place_rounded,
                                        size: 13,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '$km km',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<ThemeController>(context, listen: true).darkTheme;

    final bgColor =
    isDark ? const Color(0xFF020617) : const Color(0xFFF0FDF4);

    final selected = _selectedHotel;

    final title = selected?['title']?.toString() ?? '';
    final thumb = selected?['thumbnail']?.toString() ?? '';
    final location = selected?['location']?.toString() ?? '';
    final address = selected?['address']?.toString() ?? '';
    final rating =
    double.tryParse(selected?['review_score']?.toString() ?? '');
    final rawPrice = selected?['price']?.toString();
    final priceVnd = _formatPriceVnd(rawPrice);

    final markers = _buildHotelMarkers();
    final userMarker = _buildUserMarker();
    if (userMarker != null) markers.add(userMarker);

    final bool showPopup =
        selected != null && !_showNearbyStrip && _isPopupVisible;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
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
                  markers: markers,
                ),
              ],
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                // nút back
                Positioned(
                  top: 12,
                  left: 12,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.95),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                // ô tìm kiếm
                Positioned(
                  top: 12,
                  right: 12,
                  left: 60,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isDark ? 0.98 : 1),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                      cursorColor: const Color(0xFF10B981),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        icon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: Colors.black54,
                        ),
                        hintText: _tr(
                          context,
                          'hotel_map_search_hint',
                          'Tìm khách sạn hoặc vị trí',
                        ),
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                      onSubmitted: _searchHotel,
                    ),
                  ),
                ),
                // nút định vị
                Positioned(
                  right: 12,
                  top: 80,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: IconButton(
                      icon: const Icon(
                        Icons.my_location_rounded,
                        color: Color(0xFF2563EB),
                      ),
                      onPressed: () =>
                          _goToMyLocation(showNearbyStrip: false),
                    ),
                  ),
                ),
                // nút gợi ý gần tôi
                Positioned(
                  right: 12,
                  top: 140,
                  child: Material(
                    color: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 4,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () =>
                          _goToMyLocation(showNearbyStrip: true),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.recommend_rounded,
                              size: 18,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _tr(context, 'hotel_suggest_button',
                                  'Gợi ý gần tôi'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // strip khách sạn gần bạn
                _buildNearbyStrip(isDark),

                // popup khách sạn (chỉ hiện khi showPopup = true)
                if (showPopup)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      decoration: BoxDecoration(
                        color:
                        isDark ? const Color(0xFF020617) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, -6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Center(
                                  child: Container(
                                    width: 42,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white24
                                          : Colors.grey[300],
                                      borderRadius:
                                      BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPopupVisible = false;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              height: 150,
                              width: double.infinity,
                              child: thumb.isNotEmpty
                                  ? Image.network(
                                thumb,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                  ),
                                ),
                              )
                                  : Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 18,
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
                                          size: 16,
                                          color: Color(0xFF10B981),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            location,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                        if (rating != null) ...[
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.star_rounded,
                                            size: 16,
                                            color: Colors.amber[400],
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            rating.toStringAsFixed(1),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF111827),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (address.isNotEmpty)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          if (priceVnd.isNotEmpty)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                priceVnd,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 50,
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // TODO: mở màn chi tiết khách sạn
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(
                                Icons.hotel_rounded,
                                color: Colors.white,
                              ),
                              label: Text(
                                _tr(
                                  context,
                                  'hotel_map_view_hotel_btn',
                                  'Xem khách sạn',
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}