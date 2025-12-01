import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/services/tour_service.dart';



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
      final cachedData = prefs.getString('cached_tours');
      if (cachedData != null) {
        final cachedList = jsonDecode(cachedData) as List<dynamic>;
        setState(() {
          tours = cachedList.take(5).toList();
          isLoading = false;
        });
        _fadeController.forward();
      }

      final data = await TourService.fetchTours();
      final jsonList = data
          .map((e) => e is Map ? e : (e as Map).cast<String, dynamic>())
          .toList();

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
          ? _SkeletonBanner(
        key: const ValueKey('skeleton'),
        isDark: isDark,
      )
          : tours.isEmpty
          ? const Center(
        key: ValueKey('empty'),
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
        key: const ValueKey('carousel'),
        itemCount: tours.length,
        itemBuilder: (context, index, realIndex) {
          final tour = tours[index];

          final imageUrl = (tour['banner_image_url'] ?? '').toString();
          final title = (tour['title'] ?? 'Bali').toString();

          final country = (tour['country'] ??
              tour['location'] ??
              tour['destination'] ??
              'Indonesia')
              .toString();

          final double rating = double.tryParse(
              (tour['rating'] ?? tour['review_score'] ?? '5.0')
                  .toString()) ??
              5.0;

          final int reviewCount = int.tryParse(
              (tour['review_count'] ?? tour['reviews'] ?? '213')
                  .toString()) ??
              0;

          return _BannerItem(
            key: ValueKey('banner_${tour['id'] ?? index}'),
            imageUrl: imageUrl,
            title: title,
            country: country,
            rating: rating,
            reviewCount: reviewCount,
            isDark: isDark,
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
  final double rating;
  final int reviewCount;
  final bool isDark;

  const _BannerItem({
    required Key key,
    required this.imageUrl,
    required this.title,
    required this.country,
    required this.rating,
    required this.reviewCount,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgShadowColor =
    isDark ? Colors.black.withOpacity(0.6) : Colors.black.withOpacity(0.15);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: bgShadowColor,
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
                imageUrl: imageUrl.isNotEmpty
                    ? imageUrl
                    : 'https://via.placeholder.com/400x240.png?text=Tour',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                  child: const Center(
                    child: _ShimmerPlaceholder(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                  child: Icon(
                    Icons.image_not_supported,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                    size: 40,
                  ),
                ),
                fadeInDuration: const Duration(milliseconds: 600),
                fadeOutDuration: const Duration(milliseconds: 300),
              ),
            ),

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
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            Positioned(
              top: 14,
              right: 14,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.7),
                    width: 1.4,
                  ),
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),

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
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: Color(0xFFFFD54F),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (reviewCount > 0)
                        Text(
                          '$reviewCount Reviews',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isDark ? 0.15 : 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'See More',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF222222),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? Colors.white
                                : Colors.white,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: isDark
                                ? Colors.black87
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBanner extends StatelessWidget {
  final bool isDark;

  const _SkeletonBanner({required Key? key, required this.isDark})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CarouselSlider.builder(
      itemCount: 3,
      itemBuilder: (_, __, ___) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: isDark ? const Color(0xFF222733) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Container(
                color: isDark ? const Color(0xFF30364A) : Colors.grey[300],
              ),
              const _ShimmerEffect(),
              Positioned(
                left: 18,
                right: 18,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[500],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 18,
                      width: 140,
                      decoration: BoxDecoration(
                        color: Colors.grey[500],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[500]!.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      options: CarouselOptions(
        height: 260,
        autoPlay: false,
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
              begin: Alignment(-1.0 + _controller.value * 3, 0),
              end: Alignment(1.0 + _controller.value * 3, 0),
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.35),
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
    return const SizedBox(
      width: 40,
      height: 40,
      child: _ShimmerEffect(),
    );
  }
}