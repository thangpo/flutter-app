import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/services/tour_service.dart';

import '../screens/tour_detail_screen.dart';

class TravelBannerWidget extends StatefulWidget {
  const TravelBannerWidget({super.key});

  @override
  State<TravelBannerWidget> createState() => _TravelBannerWidgetState();
}

class _TravelBannerWidgetState extends State<TravelBannerWidget>
    with TickerProviderStateMixin {
  List<dynamic> tours = [];
  bool isLoading = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    _loadTours();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadTours() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    try {
      // Lấy cache nếu có
      final cachedData = prefs.getString('cached_tours');
      if (cachedData != null) {
        final List cachedList = jsonDecode(cachedData);
        setState(() {
          tours = cachedList.take(5).toList();
          isLoading = false;
        });
        _fadeController.forward();
      }

      // Load API
      final data = await TourService.fetchTours();

      final jsonList = data.map((e) => Map<String, dynamic>.from(e)).toList();
      await prefs.setString('cached_tours', jsonEncode(jsonList));

      setState(() {
        tours = data.take(5).toList();
        isLoading = false;
      });

      _fadeController.forward();
    } catch (e) {
      debugPrint('Lỗi khi tải tour: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<ThemeController>(context, listen: true).darkTheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: isLoading
          ? _SkeletonBanner(key: UniqueKey(), isDark: isDark)
          : tours.isEmpty
          ? const Center(
        child: Text(
          'Không có tour nào để hiển thị',
          style: TextStyle(color: Colors.grey),
        ),
      )
          : _buildCarousel(isDark),
    );
  }

  Widget _buildCarousel(bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CarouselSlider.builder(
        itemCount: tours.length,
        itemBuilder: (context, index, realIdx) {
          final tour = tours[index];

          // FIX KEY ẢNH: dùng đúng image_url
          String rawUrl = tour["image_url"]?.toString() ?? "";
          if (rawUrl.isEmpty) {
            rawUrl =
            "https://via.placeholder.com/400x240.png?text=Tour"; // fallback
          }

          // preload ảnh để load nhanh hơn
          precacheImage(CachedNetworkImageProvider(rawUrl), context);

          return _BannerItem(
            key: ValueKey('tour_${tour['id']}'),
            imageUrl: rawUrl,
            title: tour["title"] ?? "",
            country: tour["location"] ?? "",
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TourDetailScreen(tourId: tour['id']),
                ),
              );
            },
          );
        },
        options: CarouselOptions(
          height: 350,
          autoPlay: true,
          enlargeCenterPage: true,
          viewportFraction: 0.8,
          autoPlayInterval: const Duration(seconds: 4),
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          enlargeStrategy: CenterPageEnlargeStrategy.height,
        ),
      ),
    );
  }
}

class _BannerItem extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String country;
  final bool isDark;
  final VoidCallback onTap;

  const _BannerItem({
    required Key key,
    required this.imageUrl,
    required this.title,
    required this.country,
    required this.isDark,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgShadow = isDark
        ? Colors.black.withOpacity(0.6)
        : Colors.black.withOpacity(0.15);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: bgShadow,
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: -6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 600),
                  fadeOutDuration: const Duration(milliseconds: 300),
                  placeholder: (_, __) => Container(
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                    child: const Center(child: _ShimmerPlaceholder()),
                  ),
                  errorWidget: (_, __, ___) => Icon(
                    Icons.broken_image_rounded,
                    color: Colors.grey[500],
                    size: 40,
                  ),
                ),
              ),

              /// Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(isDark ? 0.85 : 0.65),
                        Colors.black.withOpacity(0.2),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.5, 1],
                    ),
                  ),
                ),
              ),

              /// Nội dung
              Positioned(
                left: 18,
                right: 18,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (country.isNotEmpty)
                      Text(
                        country,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                    const SizedBox(height: 6),

                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    /// Nút xem thêm
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(isDark ? 0.15 : 0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'See More',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------- SHIMMER LOADING --------------------

class _SkeletonBanner extends StatelessWidget {
  final bool isDark;

  const _SkeletonBanner({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider.builder(
      itemCount: 3,
      itemBuilder: (_, __, ___) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: isDark ? const Color(0xFF222733) : Colors.white,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: const _ShimmerEffect(),
        ),
      ),
      options: CarouselOptions(
        height: 260,
        enlargeCenterPage: true,
        viewportFraction: 0.8,
      ),
    );
  }
}

class _ShimmerEffect extends StatefulWidget {
  const _ShimmerEffect();

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 3, 0),
              end: Alignment(1 + _controller.value * 3, 0),
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerPlaceholder extends StatelessWidget {
  const _ShimmerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 40, height: 40, child: _ShimmerEffect());
  }
}