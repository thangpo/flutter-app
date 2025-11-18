import 'dart:ui'; // THÊM import này cho BackdropFilter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import '../services/hotel_service.dart';
import '../screens/hotel_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/hotel_flip_transition.dart';

class HotelListWidget extends StatefulWidget {
  const HotelListWidget({super.key});

  @override
  State<HotelListWidget> createState() => _HotelListWidgetState();
}

class _HotelListWidgetState extends State<HotelListWidget>
    with TickerProviderStateMixin {
  final HotelService _hotelService = HotelService();
  bool _isLoading = true;
  List<dynamic> _hotels = [];
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadHotels();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadHotels() async {
    try {
      final hotels = await _hotelService.fetchHotels(limit: 10);
      setState(() {
        _hotels = hotels;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      debugPrint('Error loading hotels: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeController>(context, listen: true).darkTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Glass Header
          Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.blue, Colors.purple],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                  ).createShader(bounds),
                  child: Text(
                    getTranslated("featured_hotels", context) ?? "Khách sạn nổi bật",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _isLoading
              ? _SkeletonHotelList(isDark: isDark)
              : _hotels.isEmpty
              ? _buildEmptyState(isDark)
              : _buildHotelList(isDark),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.04),
                ]
                    : [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.15 : 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey[400]!.withOpacity(0.3),
                        Colors.grey[300]!.withOpacity(0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.hotel_outlined,
                    size: 48,
                    color: isDark ? Colors.white70 : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  getTranslated("no_hotels", context) ?? "Không có khách sạn nào",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHotelList(bool isDark) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Column(
          children: _hotels.asMap().entries.map((entry) {
            final index = entry.key;
            final hotel = entry.value;
            final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
              ),
            );

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(animation),
                child: _HotelCardItem(hotel: hotel, isDark: isDark),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// === HOTEL CARD với Liquid Glass Effect ===
class _HotelCardItem extends StatefulWidget {
  final dynamic hotel;
  final bool isDark;

  const _HotelCardItem({required this.hotel, required this.isDark});

  @override
  State<_HotelCardItem> createState() => _HotelCardItemState();
}

class _HotelCardItemState extends State<_HotelCardItem> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  List<Widget> _buildStarRating(double score) {
    const int maxStars = 5;
    final List<Widget> stars = [];
    final double roundedScore = (score * 2).round() / 2;

    for (int i = 1; i <= maxStars; i++) {
      if (i <= roundedScore) {
        stars.add(const Icon(Icons.star, size: 15, color: Colors.amber));
      } else if (i - 0.5 <= roundedScore) {
        stars.add(const Icon(Icons.star_half, size: 15, color: Colors.amber));
      } else {
        stars.add(const Icon(Icons.star_border, size: 15, color: Colors.amber));
      }
    }
    return stars;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        Navigator.push(
          context,
          IOSAppOpenTransition(
            page: HotelDetailScreen(slug: widget.hotel['slug']),
          ),
        );
      },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(widget.isDark ? 0.3 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.blue.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(widget.isDark ? 0.05 : 0.3),
                blurRadius: 12,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isDark
                        ? [
                      Colors.grey[850]!.withOpacity(0.9),
                      Colors.grey[900]!.withOpacity(0.85),
                    ]
                        : [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(widget.isDark ? 0.15 : 0.5),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  children: [
                    // Background gradient effect
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 150,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.withOpacity(widget.isDark ? 0.08 : 0.06),
                              Colors.purple.withOpacity(widget.isDark ? 0.06 : 0.04),
                              Colors.transparent,
                            ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          // Image with glass frame
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  Hero(
                                    tag: 'hotel-${widget.hotel['slug']}',
                                    child: Image.network(
                                      widget.hotel['thumbnail'] ?? '',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.hotel, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  // Glass overlay on image
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 30,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.white.withOpacity(0.2),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Hotel Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.hotel['title'] ?? getTranslated("no_title", context) ?? "Không có tiêu đề",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: widget.isDark ? Colors.white : Colors.black87,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                // Location with glass badge
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: widget.isDark
                                              ? [
                                            Colors.white.withOpacity(0.08),
                                            Colors.white.withOpacity(0.04),
                                          ]
                                              : [
                                            Colors.grey[200]!.withOpacity(0.6),
                                            Colors.grey[100]!.withOpacity(0.4),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(widget.isDark ? 0.15 : 0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 13,
                                            color: widget.isDark ? Colors.white60 : Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              widget.hotel['location'] ?? '',
                                              style: TextStyle(
                                                color: widget.isDark ? Colors.white70 : Colors.grey[700],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Rating with glass badge
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.amber.withOpacity(0.15),
                                            Colors.amber.withOpacity(0.08),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.amber.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ..._buildStarRating(double.tryParse(widget.hotel['review_score'] ?? '0') ?? 0),
                                          const SizedBox(width: 6),
                                          Text(
                                            widget.hotel['review_score'] ?? '0.0',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: widget.isDark ? Colors.white : Colors.black87,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Price Badge with Glass Effect
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF2196F3),
                                      Color(0xFF9C27B0),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "${widget.hotel['price'] ?? '??'}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const Text(
                                      "₫",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
      ),
    );
  }
}

// === SKELETON LOADING với Glass Effect ===
class _SkeletonHotelList extends StatelessWidget {
  final bool isDark;

  const _SkeletonHotelList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (_) => _SkeletonHotelCard(isDark: isDark)),
    );
  }
}

class _SkeletonHotelCard extends StatelessWidget {
  final bool isDark;

  const _SkeletonHotelCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                  Colors.grey[850]!.withOpacity(0.8),
                  Colors.grey[900]!.withOpacity(0.7),
                ]
                    : [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.15 : 0.5),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _ShimmerBox(height: 80, width: 80, borderRadius: 16, isDark: isDark),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShimmerBox(height: 16, width: 180, borderRadius: 8, isDark: isDark),
                        const SizedBox(height: 8),
                        _ShimmerBox(height: 28, width: 120, borderRadius: 8, isDark: isDark),
                        const SizedBox(height: 8),
                        _ShimmerBox(height: 28, width: 100, borderRadius: 8, isDark: isDark),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ShimmerBox(height: 56, width: 70, borderRadius: 16, isDark: isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// === SHIMMER BOX ===
class _ShimmerBox extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;
  final bool isDark;

  const _ShimmerBox({
    required this.height,
    required this.width,
    required this.borderRadius,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: _Shimmer(isDark: isDark),
    );
  }
}

// === SHIMMER EFFECT ===
class _Shimmer extends StatefulWidget {
  final bool isDark;

  const _Shimmer({required this.isDark});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
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
              colors: widget.isDark
                  ? [
                Colors.transparent,
                Colors.white.withOpacity(0.1),
                Colors.transparent,
              ]
                  : [
                Colors.transparent,
                Colors.white.withOpacity(0.4),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
}