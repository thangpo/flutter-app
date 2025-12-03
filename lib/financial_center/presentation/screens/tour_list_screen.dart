import 'dart:async';
import '../widgets/tour_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/tour_service.dart';
import '../widgets/tour_filter_bar.dart';
import '../services/location_service.dart';
import '../widgets/tour_card_skeleton.dart';
import '../widgets/article_list_widget.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/screens/hotel_map_screen.dart';

class TourListScreen extends StatefulWidget {
  const TourListScreen({super.key});
  @override
  State<TourListScreen> createState() => _TourListScreenState();
}

class _TourListScreenState extends State<TourListScreen> {
  List<dynamic> tours = [];
  bool isLoading = false;
  static const Color oceanBlue = Color(0xFF0077BE);
  static const Color lightOceanBlue = Color(0xFF4DA8DA);
  final List<String> _headerImages = [];
  int _currentHeaderIndex = 0;
  Timer? _headerTimer;

  List<LocationModel> _locations = [];
  bool _isLoadingLocations = false;
  int? _selectedQuickLocationId;

  @override
  void initState() {
    super.initState();
    _loadTours();
    _loadLocations();
  }

  @override
  void dispose() {
    _headerTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTours({
    String? title,
    int? locationId,
    String? startDate,
    String? endDate,
  }) async {
    setState(() => isLoading = true);
    try {
      List<dynamic> data;
      if ((title == null || title.isEmpty) &&
          locationId == null &&
          startDate == null &&
          endDate == null) {
        data = await TourService.fetchTours();
      } else {
        data = await TourService.searchTours(
          title: title,
          locationId: locationId,
        );
      }

      setState(() => tours = data);
      _prepareHeaderImages();
    } catch (e) {
      debugPrint("Lỗi tải tour: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoadingLocations = true);
    try {
      final data = await LocationService.fetchLocations();
      setState(() => _locations = data);
    } catch (e) {
      debugPrint('Lỗi tải địa điểm: $e');
    } finally {
      if (mounted) setState(() => _isLoadingLocations = false);
    }
  }

  void _prepareHeaderImages() {
    _headerImages.clear();
    for (final t in tours.take(5)) {
      if (t is Map) {
        final url = (t['image'] ??
            t['banner'] ??
            t['image_url'] ??
            t['thumbnail'])
        as String?;
        if (url != null && url.isNotEmpty) _headerImages.add(url);
      }
    }

    if (_headerImages.isEmpty) {
      _headerTimer?.cancel();
      _currentHeaderIndex = 0;
    } else {
      _currentHeaderIndex = 0;
      _startHeaderTimer();
    }
  }

  void _startHeaderTimer() {
    _headerTimer?.cancel();
    _headerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _headerImages.isEmpty) return;
      setState(() {
        _currentHeaderIndex =
            (_currentHeaderIndex + 1) % _headerImages.length;
      });
    });
  }

  String? _getCurrentHeaderImage() {
    if (_headerImages.isEmpty) return null;
    final safeIndex =
    _currentHeaderIndex.clamp(0, _headerImages.length - 1);
    return _headerImages[safeIndex];
  }

  String? _getLocationImageUrl(LocationModel loc) {
    if (loc.imageUrl.isEmpty) return null;
    return loc.imageUrl;
  }

  double? _safeDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  List<Map<String, dynamic>> _buildMapDataFromTours() {
    final valid = tours.whereType<Map>().where((t) {
      final lat = _safeDouble(t['lat']) ?? 0;
      final lng = _safeDouble(t['lng']) ?? 0;
      return lat != 0 && lng != 0;
    }).toList();

    return valid.map<Map<String, dynamic>>((t) {
      final price = t['price']?.toString();

      return {
        'id': t['id'],
        'type': 'tour',
        'title': t['title'] ?? '',
        'slug': t['slug'] ?? '',
        'lat': _safeDouble(t['lat']),
        'lng': _safeDouble(t['lng']),
        'thumbnail': t['image_url'] ?? t['thumbnail'] ?? '',
        'location': t['location'] ?? '',
        'address': t['location'] ?? '',
        'review_score': null,
        'price': price,
      };
    }).toList();
  }

  Future<void> _openTourMap() async {
    final mapData = _buildMapDataFromTours();

    if (mapData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có tour nào có tọa độ để hiển thị bản đồ.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleText =
        getTranslated('explore_tours', context) ?? 'Khám phá Tour';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? const Color(0xFF050816) : Colors.grey[100],
      appBar: AppBar(
        title: Text(
          titleText,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Xem bản đồ tour',
            icon: const Icon(Icons.map_rounded),
            onPressed: _openTourMap,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: oceanBlue,
        onRefresh: () async {
          await _loadTours(locationId: _selectedQuickLocationId);
          await _loadLocations();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderWithFilter(context),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildLocationQuickFilter(context),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: isLoading
                    ? const Column(
                  children: [
                    SizedBox(height: 12),
                    TourCardSkeleton(),
                    TourCardSkeleton(),
                    TourCardSkeleton(),
                  ],
                )
                    : (tours.isNotEmpty
                    ? Column(
                  children: [
                    ...tours.map((tour) => TourCard(tour: tour)),
                  ],
                )
                    : Column(
                  children: [
                    const SizedBox(height: 40),
                    Icon(
                      Icons.search_off_rounded,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      getTranslated('no_tour_found', context) ??
                          "Không tìm thấy tour nào",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                )),
              ),

              const SizedBox(height: 24),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ArticleListWidget(),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationQuickFilter(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String tr(String key, String fallback) =>
        getTranslated(key, context) ?? fallback;

    if (_isLoadingLocations) {
      return SizedBox(
        height: 72,
        child: Row(
          children: List.generate(
            3,
                (_) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color:
                  isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 48,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_locations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('destination_filter_title', 'Địa điểm nổi bật'),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _locations.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildLocationChip(
                  context: context,
                  label: tr('all_destinations', 'Tất cả'),
                  icon: Icons.public_rounded,
                  isSelected: _selectedQuickLocationId == null,
                  imageUrl: null,
                  onTap: () {
                    setState(() => _selectedQuickLocationId = null);
                    _loadTours();
                  },
                );
              }

              final loc = _locations[index - 1];
              return _buildLocationChip(
                context: context,
                label: loc.name.isNotEmpty
                    ? loc.name
                    : tr('unknown_location', 'Đang cập nhật'),
                icon: Icons.location_on_rounded,
                isSelected: _selectedQuickLocationId == loc.id,
                imageUrl: _getLocationImageUrl(loc),
                onTap: () {
                  setState(() => _selectedQuickLocationId = loc.id);
                  _loadTours(locationId: loc.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required String? imageUrl,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color textColor = isSelected
        ? Colors.white
        : (isDark ? Colors.white70 : const Color(0xFF111827));

    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 140,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withOpacity(0.8)
                  : (isDark ? Colors.white12 : Colors.grey.shade200),
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl != null && imageUrl.isNotEmpty)
                  Positioned.fill(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: isDark
                            ? const Color(0xFF020617)
                            : Colors.grey.shade200,
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color:
                      isDark ? const Color(0xFF020617) : Colors.white,
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(isSelected ? 0.55 : 0.35),
                        Colors.black.withOpacity(isSelected ? 0.30 : 0.15),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderWithFilter(BuildContext context) {
    final headerImage = _getCurrentHeaderImage();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 530,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
              child: headerImage != null && headerImage.isNotEmpty
                  ? Image.network(
                headerImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildHeaderFallbackBg(isDark),
              )
                  : _buildHeaderFallbackBg(isDark),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.25),
                    Colors.black.withOpacity(0.65),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: TourFilterBar(
              onFilter: ({
                String? title,
                String? location,
                int? locationId,
                String? startDate,
                String? endDate,
              }) {
                setState(() => _selectedQuickLocationId = locationId);
                _loadTours(
                  title: title,
                  locationId: locationId,
                  startDate: startDate,
                  endDate: endDate,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderFallbackBg(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF020617)]
              : [oceanBlue, lightOceanBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}