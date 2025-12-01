import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../screens/tours_list_screen.dart';
import '../screens/tour_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/services/tour_service.dart';


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

    _cardPageController = PageController(
      viewportFraction: 0.9,
    );
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _openAllTours() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) =>
            TourListScreen(location: widget.location),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
      ),
    );
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
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  String _formatPrice(dynamic priceRaw) {
    if (priceRaw == null) {
      return getTranslated('contact_for_price', context) ??
          'Contact for price';
    }

    num? value;
    if (priceRaw is num) {
      value = priceRaw;
    } else {
      value = num.tryParse(priceRaw.toString());
    }

    if (value == null) {
      return priceRaw.toString();
    }

    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
    );
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<ThemeController>(context, listen: true).darkTheme;

    final bgImage = widget.location.imageUrl;
    final toursLabel =
        getTranslated('tours_available', context) ?? 'tours available';
    final toursCountText = '${widget.location.toursCount} $toursLabel';

    final allToursText =
        getTranslated('all_tours', context) ?? 'All tours';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: bgImage.isNotEmpty
                ? Image.network(
              bgImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.black,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.white38,
                    size: 60,
                  ),
                ),
              ),
            )
                : Container(
              color: Colors.black,
              child: const Center(
                child: Icon(
                  Icons.image_outlined,
                  color: Colors.white38,
                  size: 60,
                ),
              ),
            ),
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
                  stops: const [0.0, 0.4, 1.0],
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
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),

                          Text(
                            toursCountText,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: isLoading
                            ? _buildLoadingCard()
                            : _buildBottomCard(context, isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (!isLoading && tours.isNotEmpty)
            Positioned(
              right: 16,
              top: 90,
              child: GestureDetector(
                onTap: _openAllTours,
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
                        allToursText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 130,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCard(BuildContext context, bool isDark) {
    final noToursText = getTranslated('no_tours_here', context) ??
        'Hiện tại địa điểm này chưa có tour nào được mở bán.';

    if (tours.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isDark ? 0.95 : 0.98),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              noToursText,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: PageView.builder(
        controller: _cardPageController,
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        itemCount: tours.length,
        itemBuilder: (context, index) {
          return _buildTourStackCard(context, index);
        },
      ),
    );
  }

  Widget _buildTourStackCard(BuildContext context, int index) {
    final tour = tours[index];

    final String title =
    (tour['title'] ?? widget.location.name).toString();

    final String durationLabel =
    (tour['duration'] ??
        getTranslated('six_days_five_nights', context) ??
        'Six days five nights')
        .toString();

    final dynamic priceRaw = tour['price'];
    final String priceText = _formatPrice(priceRaw);

    final String imageUrl =
    (tour['banner_image_url'] ?? widget.location.imageUrl ?? '')
        .toString();

    final subTitle =
        getTranslated('fire_ice_trip', context) ?? 'Fire & Ice Trip';

    final forOnePerson =
        getTranslated('for_one_person', context) ?? 'for 1 person';

    final double distance = (index - _currentCardPage);
    final double scale = (1 - (distance.abs() * 0.05)).clamp(0.9, 1.0);
    final double translateY = distance * 18;

    return Transform.translate(
      offset: Offset(0, translateY),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () => _openTourDetail(tour),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
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
                  Positioned.fill(
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[400],
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white,
                        ),
                      ),
                    )
                        : Container(
                      color: Colors.grey[400],
                      child: const Icon(
                        Icons.image_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ),

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

                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
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

                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
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
                          mainAxisSize: MainAxisSize.min,
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