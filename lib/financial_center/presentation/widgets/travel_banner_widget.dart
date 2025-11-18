import 'dart:convert';
import 'dart:ui'; // THÊM import này cho BackdropFilter
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
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
      // 1. Ưu tiên cache
      final cachedData = prefs.getString('cached_tours');
      if (cachedData != null) {
        final cachedList = jsonDecode(cachedData) as List<dynamic>;
        setState(() {
          tours = cachedList.take(5).toList();
          isLoading = false;
        });
        _fadeController.forward();
      }

      // 2. Load API (luôn cập nhật cache)
      final data = await TourService.fetchTours();
      final jsonList = data.map((e) => e is Map ? e : (e as Map).cast<String, dynamic>()).toList();

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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
      child: isLoading
          ? const _SkeletonBanner(key: ValueKey('skeleton'))
          : tours.isEmpty
          ? const Center(
        key: ValueKey('empty'),
        child: Text('Không có tour nào để hiển thị', style: TextStyle(color: Colors.grey)),
      )
          : _buildCarousel(),
    );
  }

  Widget _buildCarousel() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CarouselSlider.builder(
        key: const ValueKey('carousel'),
        itemCount: tours.length,
        itemBuilder: (context, index, realIndex) {
          final tour = tours[index];
          final imageUrl = tour['banner_image_url'] ?? '';
          final title = tour['title'] ?? 'Tour du lịch';

          return _BannerItem(
            key: ValueKey('banner_${tour['id'] ?? index}'),
            imageUrl: imageUrl,
            title: title,
          );
        },
        options: CarouselOptions(
          height: 200, // Tăng height để chứa glass effect
          autoPlay: true,
          enlargeCenterPage: true,
          viewportFraction: 0.9,
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

  const _BannerItem({required Key key, required this.imageUrl, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // Liquid Glass Effect - Outer shadow
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -8,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: imageUrl.isNotEmpty ? imageUrl : 'https://via.placeholder.com/400x200.png?text=Banner',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: _ShimmerPlaceholder(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                ),
                fadeInDuration: const Duration(milliseconds: 600),
                fadeOutDuration: const Duration(milliseconds: 300),
              ),
            ),

            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Liquid Glass Title Container
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Icon với glass effect
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.tour,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              shadows: [
                                Shadow(
                                  blurRadius: 8,
                                  color: Colors.black45,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Glossy Highlight (Top)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBanner extends StatelessWidget {
  const _SkeletonBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CarouselSlider.builder(
      itemCount: 3,
      itemBuilder: (_, __, ___) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          // Liquid Glass Effect cho skeleton
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[300]!.withOpacity(0.8),
              Colors.grey[200]!.withOpacity(0.6),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
              spreadRadius: -6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Stack(
              children: [
                const _ShimmerEffect(),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: 180,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 14,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(8),
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
      options: CarouselOptions(
        height: 200,
        autoPlay: false,
        enlargeCenterPage: true,
        viewportFraction: 0.9,
      ),
    );
  }
}

class _ShimmerEffect extends StatefulWidget {
  const _ShimmerEffect();

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
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
              colors: [Colors.transparent, Colors.white.withOpacity(0.4), Colors.transparent],
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