import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/hotel_service.dart';
import '../screens/hotel_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
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
    final isDark =
        Provider.of<ThemeController>(context, listen: true).darkTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    getTranslated("featured_hotels", context) ??
                        "Khách sạn nổi bật",
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
                  getTranslated("no_hotels", context) ??
                      "Không có khách sạn nào",
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
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: _HotelCardItem(
                  hotel: hotel,
                  isDark: isDark,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _HotelCardItem extends StatefulWidget {
  final dynamic hotel;
  final bool isDark;

  const _HotelCardItem({required this.hotel, required this.isDark});

  @override
  State<_HotelCardItem> createState() => _HotelCardItemState();
}

class _HotelCardItemState extends State<_HotelCardItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
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

  String _formatPrice(dynamic raw) {
    if (raw == null) return '—';
    final rawStr = raw.toString().replaceAll(',', '');
    final value = double.tryParse(rawStr);
    if (value == null) return raw.toString();
    final format = NumberFormat('#,###');
    return '${format.format(value)} ₫';
  }

  String _getLocation(dynamic loc) {
    if (loc is Map && loc['name'] != null) {
      return loc['name'].toString();
    }
    return (loc ?? '').toString();
  }

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;

    final imageUrl = (hotel['thumbnail'] ??
        hotel['banner'] ??
        hotel['image'] ??
        '')
        .toString();

    final title =
    (hotel['title'] ?? hotel['name'] ?? 'Hotel').toString();

    final location = _getLocation(hotel['location']);
    final price = _formatPrice(hotel['price']);

    final outerShadowColor = widget.isDark
        ? Colors.black.withOpacity(0.7)
        : Colors.black.withOpacity(0.12);

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        Navigator.push(
          context,
          IOSAppOpenTransition(
            page: HotelDetailScreen(slug: hotel['slug']),
          ),
        );
      },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: outerShadowColor,
                blurRadius: 16,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              height: 220,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      imageUrl.isNotEmpty
                          ? imageUrl
                          : 'https://via.placeholder.com/400x260.png?text=Hotel',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: widget.isDark
                            ? const Color(0xFF30364A)
                            : Colors.grey[300],
                        child: Icon(
                          Icons.hotel,
                          color: widget.isDark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                          size: 40,
                        ),
                      ),
                    ),
                  ),

                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.black.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.95),
                        boxShadow: [
                          BoxShadow(
                            color:
                            Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.favorite_border_rounded,
                        size: 18,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),

                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isDark
                            ? const Color(0xFF1E2330)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                                widget.isDark ? 0.3 : 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: widget.isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (location.isNotEmpty)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        size: 14,
                                        color: widget.isDark
                                            ? Colors.white70
                                            : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          location,
                                          maxLines: 1,
                                          overflow:
                                          TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: widget.isDark
                                                ? Colors.white70
                                                : Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            price,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: widget.isDark
                                  ? Colors.white
                                  : Colors.black87,
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
      ),
    );
  }
}

class _SkeletonHotelList extends StatelessWidget {
  final bool isDark;

  const _SkeletonHotelList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
            (_) => _SkeletonHotelCard(isDark: isDark),
      ),
    );
  }
}

class _SkeletonHotelCard extends StatelessWidget {
  final bool isDark;

  const _SkeletonHotelCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bgColor =
    isDark ? const Color(0xFF1E2330) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(isDark ? 0.7 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 220,
          child: Stack(
            children: [
              Container(color: isDark ? const Color(0xFF30364A) : Colors.grey[300]),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const _Shimmer(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({super.key});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
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