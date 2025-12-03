import 'package:intl/intl.dart';
import 'tour_detail_screen.dart';
import 'hotel_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../widgets/hotel_map_widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';


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
  late MapController _mapController;
  late TextEditingController _searchController;

  LatLng _center = const LatLng(21.0278, 105.8342);
  double _zoom = 12;

  List<Map<String, dynamic>> _searchSuggestions = [];
  bool _showSearchSuggestions = false;

  Map<String, dynamic>? _selectedHotel;
  LatLng? _userLocation;

  bool _showNearbyStrip = false;
  bool _isPopupVisible = true;
  List<Map<String, dynamic>> _nearbyHotels = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _searchController = TextEditingController();
    _initCenterAndSelected();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoLocateOnStart) {
        _goToMyLocation(showNearbyStrip: true);
      }
    });
  }

  bool _isTour(Map<String, dynamic>? item) {
    if (item == null) return false;
    return item['type']?.toString() == 'tour';
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadNearbyForSelected();
        });
      }
    }
  }

  void _loadNearbyForSelected() {
    if (_selectedHotel == null) return;

    final baseLat = double.tryParse(_selectedHotel!['lat']?.toString() ?? '');
    final baseLng = double.tryParse(_selectedHotel!['lng']?.toString() ?? '');
    if (baseLat == null || baseLng == null) return;

    final base = LatLng(baseLat, baseLng);
    final distance = const Distance();

    final List<Map<String, dynamic>> nearby = [];

    for (final h in widget.hotels) {
      final lat = double.tryParse(h['lat']?.toString() ?? '');
      final lng = double.tryParse(h['lng']?.toString() ?? '');
      if (lat == null || lng == null) continue;

      final d = distance(base, LatLng(lat, lng));

      if (d <= 5000 && h['id'] != _selectedHotel!['id']) {
        final copy = Map<String, dynamic>.from(h);
        copy['_distance'] = d;
        nearby.add(copy);
      }
    }

    nearby.sort((a, b) {
      final da = (a['_distance'] as double?) ?? double.infinity;
      final db = (b['_distance'] as double?) ?? double.infinity;
      return da.compareTo(db);
    });

    setState(() {
      _nearbyHotels = nearby;
      _showNearbyStrip = nearby.isNotEmpty;
    });
  }

  void _updateSearchSuggestions(String query) {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      setState(() {
        _searchSuggestions = [];
        _showSearchSuggestions = false;
      });
      return;
    }

    final distanceCalc = const Distance();
    final List<Map<String, dynamic>> matched = [];

    for (final h in widget.hotels) {
      final title = h['title']?.toString().toLowerCase() ?? '';

      if (title.contains(q)) {
        final copy = Map<String, dynamic>.from(h);

        if (_userLocation != null) {
          final lat = double.tryParse(h['lat']?.toString() ?? '');
          final lng = double.tryParse(h['lng']?.toString() ?? '');
          if (lat != null && lng != null) {
            final d = distanceCalc(_userLocation!, LatLng(lat, lng));
            copy['_distance'] = d;
          }
        }

        matched.add(copy);
      }
    }

    matched.sort((a, b) {
      final da = (a['_distance'] as double?) ?? double.infinity;
      final db = (b['_distance'] as double?) ?? double.infinity;
      return da.compareTo(db);
    });

    final limited = matched.take(8).toList();

    setState(() {
      _searchSuggestions = limited;
      _showSearchSuggestions = limited.isNotEmpty;
    });
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
      _isPopupVisible = true;
      _showNearbyStrip = false;
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
            _tr(
              context,
              'hotel_map_not_found',
              'Không tìm thấy địa điểm phù hợp.',
            ),
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
              _tr(
                context,
                'location_service_disabled',
                'Vui lòng bật dịch vụ vị trí của thiết bị.',
              ),
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
              _tr(
                context,
                'location_permission_denied',
                'Ứng dụng không được cấp quyền vị trí.',
              ),
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
            _isPopupVisible = false;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Có ${nearbyHotels.length} địa điểm quanh vị trí của bạn.',
            ),
          ),
        );
      } else {
        setState(() {
          _nearbyHotels = [];
          _showNearbyStrip = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _tr(
                context,
                'hotel_nearby_not_found',
                'Không tìm thấy địa điểm nào gần vị trí của bạn.',
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
            _tr(
              context,
              'location_error',
              'Không lấy được vị trí hiện tại.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _openNavigationToSelected() async {
    final h = _selectedHotel;
    if (h == null) return;

    final lat = double.tryParse(h['lat']?.toString() ?? '');
    final lng = double.tryParse(h['lng']?.toString() ?? '');
    if (lat == null || lng == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không xác định được tọa độ địa điểm.'),
        ),
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Lỗi mở Google Maps: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được ứng dụng bản đồ.')),
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
      final shortTitle = title.length > 18 ? '${title.substring(0, 18)}…' : title;
      final rating = double.tryParse(h['review_score']?.toString() ?? '');
      final isTour = _isTour(h);

      return Marker(
        point: LatLng(lat, lng),
        width: 130,
        height: 90,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        shortTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      if (rating != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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
                  isTour ? Icons.flag_rounded : Icons.location_on_rounded,
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
    final rating = double.tryParse(selected?['review_score']?.toString() ?? '');
    final rawPrice = selected?['price']?.toString();
    final priceVnd = _formatPriceVnd(rawPrice);
    final isTour = _isTour(selected);
    final markers = _buildHotelMarkers();
    final userMarker = _buildUserMarker();
    if (userMarker != null) markers.add(userMarker);

    final bool showPopup = selected != null && !_showNearbyStrip && _isPopupVisible;
    final viewText = isTour ? _tr(context, 'tour_map_view_tour_btn', 'Xem tour') : _tr(context, 'hotel_map_view_hotel_btn', 'Xem khách sạn');

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
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                          'Tìm khách sạn / tour hoặc vị trí',
                        ),
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                      onChanged: _updateSearchSuggestions,
                      onSubmitted: (value) {
                        _updateSearchSuggestions('');
                        _searchHotel(value);
                      },
                    ),
                  ),
                ),
                if (_showSearchSuggestions && _searchSuggestions.isNotEmpty)
                  Positioned(
                    top: 60,
                    right: 12,
                    left: 60,
                    child: Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(12),
                      color: isDark ? const Color(0xFF020617) : Colors.white,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 260,
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          shrinkWrap: true,
                          itemCount: _searchSuggestions.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            thickness: 0.5,
                            color: isDark ? Colors.white10 : Colors.grey[300],
                          ),
                          itemBuilder: (context, index) {
                            final h = _searchSuggestions[index];
                            final name = h['title']?.toString() ?? '';
                            final d = (h['_distance'] as double?);
                            String distanceText = '';
                            if (d != null) {
                              final km = (d / 1000).toStringAsFixed(1);
                              distanceText = '$km km từ vị trí của bạn';
                            }

                            return ListTile(
                              dense: true,
                              onTap: () {
                                _searchController.text = name;
                                _selectHotel(h, moveCamera: true);
                                setState(() {
                                  _showSearchSuggestions = false;
                                  _searchSuggestions = [];
                                });
                              },
                              leading: Icon(
                                Icons.apartment_rounded,
                                size: 20,
                                color: isDark
                                    ? const Color(0xFF6EE7B7)
                                    : const Color(0xFF10B981),
                              ),
                              title: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              subtitle: distanceText.isNotEmpty
                                  ? Text(
                                distanceText,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey[600],
                                ),
                              )
                                  : null,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
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
                              _tr(
                                context,
                                'hotel_suggest_button',
                                'Gợi ý gần tôi',
                              ),
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

                HotelNearbyStrip(
                  show: _showNearbyStrip,
                  isDark: isDark,
                  nearbyHotels: _nearbyHotels,
                  onClose: () {
                    setState(() {
                      _showNearbyStrip = false;
                    });
                  },
                  onTapHotel: (h) => _selectHotel(h, moveCamera: true),
                ),

                if (showPopup)
                  HotelInfoBottomSheet(
                    isDark: isDark,
                    title: title,
                    thumb: thumb,
                    location: location,
                    address: address,
                    rating: rating,
                    priceVnd: priceVnd,
                    viewHotelText: viewText,
                    navigateText: _tr(
                      context,
                      'hotel_map_navigate_btn',
                      'Dẫn đường',
                    ),
                    onClose: () {
                      setState(() {
                        _isPopupVisible = false;
                      });
                      _loadNearbyForSelected();
                    },
                    onViewDetail: () {
                      final item = _selectedHotel;
                      if (item == null) return;

                      final isTourItem = _isTour(item);

                      if (isTourItem) {
                        final tourId = item['id'];
                        if (tourId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Không tìm thấy thông tin tour.'),
                            ),
                          );
                          return;
                        }

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TourDetailScreen(
                              tourId: tourId,
                            ),
                          ),
                        );
                        return;
                      }

                      final slug = item['slug']?.toString() ?? '';
                      if (slug.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Không tìm thấy thông tin khách sạn.'),
                          ),
                        );
                        return;
                      }

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HotelDetailScreen(slug: slug),
                        ),
                      );
                    },
                    onNavigate: _openNavigationToSelected,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}