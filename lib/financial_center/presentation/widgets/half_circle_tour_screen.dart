import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/location_service.dart';
import '../services/tour_service.dart';

import '../screens/tour_detail_screen.dart';
import '../screens/location_tours_map_screen.dart';

import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';


class HalfCircleTourScreen extends StatefulWidget {
  final LocationModel location;

  const HalfCircleTourScreen({super.key, required this.location});

  @override
  State<HalfCircleTourScreen> createState() => _HalfCircleTourScreenState();
}

class _HalfCircleTourScreenState extends State<HalfCircleTourScreen>
    with SingleTickerProviderStateMixin {

  List<dynamic> tours = [];
  bool isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  late PageController _cardPageController;
  double _currentCardPage = 0.0;


  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _cardPageController = PageController(viewportFraction: 0.9);
    _cardPageController.addListener(() {
      setState(() {
        _currentCardPage = _cardPageController.page ?? 0.0;
      });
    });

    _animController.forward();
    _loadTours();
  }


  @override
  void dispose() {
    _animController.dispose();
    _cardPageController.dispose();
    super.dispose();
  }


  Future<void> _loadTours() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      final data = await TourService.fetchToursByLocation(widget.location.id);
      if (!mounted) return;

      setState(() => tours = data);

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${getTranslated('tour_loading_error', context) ?? 'Lỗi tải tours'}: $e',
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }


  void _openTourDetail(dynamic tour) {
    final id = tour['id'];
    if (id == null) return;

    final int tourId =
    id is int ? id : int.tryParse(id.toString()) ?? 0;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) =>
            TourDetailScreen(tourId: tourId),
        transitionsBuilder: (context, animation, sec, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }


  void _openMap() {
    final coords = tours
        .where((t) => t['lat'] != null && t['lng'] != null)
        .map((t) {
      final lat = double.tryParse(t['lat'].toString());
      final lng = double.tryParse(t['lng'].toString());

      return {
        'id': t['id'],
        'title': t['title'],
        'price': t['price'],
        'lat': lat,
        'lng': lng,
        'image': t['banner_image_url'] ?? t['image_url'] ?? '',
      };
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationToursMapScreen(
          locationName: widget.location.name,
          imageUrl: widget.location.imageUrl,
          centerLat: widget.location.mapLat,
          centerLng: widget.location.mapLng,
          mapZoom: widget.location.mapZoom,
          tours: coords,
        ),
      ),
    );
  }


  String _formatPrice(dynamic raw) {
    if (raw == null) {
      return getTranslated('contact_for_price', context) ?? 'Liên hệ';
    }

    num? number =
    raw is num ? raw : num.tryParse(raw.toString());

    if (number == null) return raw.toString();

    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(number);
  }


  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<ThemeController>(context, listen: true).darkTheme;

    final bgImage = widget.location.imageUrl;
    final toursLabel =
        getTranslated('tours_available', context) ?? 'tours available';

    final mapText =
        getTranslated('view_map', context) ?? 'Xem bản đồ';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          /// BACKGROUND
          Positioned.fill(
            child: bgImage.isNotEmpty
                ? Image.network(bgImage, fit: BoxFit.cover)
                : Container(color: Colors.black),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Stack(
                  children: [

                    /// HEADER
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          Text(
                            widget.location.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            '${widget.location.toursCount} $toursLabel',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// LIST 2-CARD STACK
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: isLoading
                            ? _buildLoadingCard()
                            : _buildBottomCard(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// MAP BUTTON
          if (!isLoading && tours.isNotEmpty)
            Positioned(
              right: 16,
              top: 90,
              child: GestureDetector(
                onTap: _openMap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        mapText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.map_rounded,
                          size: 14, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }


  /// LOADING CARD
  Widget _buildLoadingCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 190, // thêm chiều cao tối thiểu (lớn hơn bản cũ)
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }


  /// ⭐⭐⭐ HIỂN THỊ 2 TOUR 1 LẦN Ở ĐÂY ⭐⭐⭐
  Widget _buildBottomCard(bool isDark) {
    if (tours.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          color: Colors.white.withOpacity(isDark ? 0.95 : 0.98),
          child: Text(
            getTranslated('no_tours_here', context)
                ?? 'Không có tour nào tại đây.',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
      );
    }

    return SizedBox(
      height: 560, // tăng chiều cao tổng
      child: PageView.builder(
        controller: _cardPageController,
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        itemCount: (tours.length / 2).ceil(),
        itemBuilder: (_, index) {
          final int first = index * 2;
          final int second = first + 1;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8), // giảm khoảng trắng dưới
            child: Column(
              children: [
                Expanded(
                  flex: 52, // thẻ trên chiếm cao hơn
                  child: _buildTourStackCard(first),
                ),

                const SizedBox(height: 12), // khoảng cách đẹp hơn

                if (second < tours.length)
                  Expanded(
                    flex: 48, // thẻ dưới nhỏ hơn chút → cân đối
                    child: _buildTourStackCard(second),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }



  /// ⭐ CARD CHI TIẾT TOUR (giữ nguyên animation scale + translate)
  Widget _buildTourStackCard(int index) {
    final tour = tours[index];

    final double distance = (index - _currentCardPage);
    final double scale = (1 - (distance.abs() * 0.05)).clamp(0.9, 1.0);
    final double translateY = distance * 18;

    final String title = tour['title'] ?? '';
    final String durationLabel =
        tour['duration'] ??
            getTranslated('six_days_five_nights', context) ??
            "Six days five nights";

    final String priceText = _formatPrice(tour['price']);

    final String imageUrl =
        tour['banner_image_url'] ??
            tour['image_url'] ??
            widget.location.imageUrl ??
            '';

    final subTitle =
        getTranslated('fire_ice_trip', context) ?? "Fire & Ice Trip";

    final forOnePerson =
        getTranslated('for_one_person', context) ?? "for 1 person";

    return Transform.translate(
      offset: Offset(0, translateY),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () => _openTourDetail(tour),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [

                  /// IMAGE
                  Positioned.fill(
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl, fit: BoxFit.cover)
                        : Container(color: Colors.grey[400]),
                  ),

                  /// GRADIENT OVERLAY
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.15),
                            Colors.black.withOpacity(0.35),
                            Colors.black.withOpacity(0.75),
                          ],
                        ),
                      ),
                    ),
                  ),

                  /// small badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.96),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        durationLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),

                  /// TOP RIGHT BUTTON
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.96),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_outward_rounded,
                        size: 18,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),

                  /// TEXT CONTENT
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Row(
                      children: [

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),

                              const SizedBox(height: 2),

                              Text(
                                subTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              priceText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              forOnePerson,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 11,
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
        ),
      ),
    );
  }
}