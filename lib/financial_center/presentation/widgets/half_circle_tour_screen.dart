import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/services/tour_service.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/screens/tours_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../screens/tour_detail_screen.dart';

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
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    );
    _headerController.forward();
    _loadTours();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _loadTours() async {
    if (isLoading) return;

    setState(() => isLoading = true);
    try {
      final data = await TourService.fetchToursByLocation(widget.location.id);
      setState(() => tours = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _navigateToAllTours() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TourListScreen(location: widget.location),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeController>(context, listen: true).darkTheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FD),
      body: Stack(
        children: [
          // Animated gradient background
          Positioned.fill(
            child: TweenAnimationBuilder(
              duration: const Duration(seconds: 3),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, value, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                        Color.lerp(const Color(0xFF0A0E27), const Color(0xFF1A1A2E), value)!,
                        const Color(0xFF000000),
                        Color.lerp(const Color(0xFF1A0E27), const Color(0xFF0A1E27), value)!,
                      ]
                          : [
                        Color.lerp(const Color(0xFFE8F1FF), const Color(0xFFF0E8FF), value)!,
                        const Color(0xFFF8F9FD),
                        Color.lerp(const Color(0xFFFFE8F0), const Color(0xFFE8F1FF), value)!,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),

          ..._buildFloatingShapes(isDark),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark),
                Expanded(
                  child: isLoading
                      ? _buildLoadingState(isDark)
                      : tours.isEmpty
                      ? _emptyState(isDark)
                      : _buildGrid(isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingShapes(bool isDark) {
    return [
      Positioned(
        top: 100,
        right: -50,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                (isDark ? const Color(0xFF5A7CFF) : const Color(0xFF4A6CFA))
                    .withOpacity(isDark ? 0.15 : 0.1),
                (isDark ? const Color(0xFF5A7CFF) : const Color(0xFF4A6CFA))
                    .withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 150,
        left: -80,
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFF6B9D).withOpacity(isDark ? 0.12 : 0.08),
                const Color(0xFFFF6B9D).withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.white).withOpacity(isDark ? 0.1 : 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isDark ? Colors.white : const Color(0xFF4A6CFA)).withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : const Color(0xFF4A6CFA)).withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CircularProgressIndicator(
                  color: isDark ? const Color(0xFF5A7CFF) : const Color(0xFF4A6CFA),
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Đang tải tours...',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return FadeTransition(
      opacity: _headerAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.5),
          end: Offset.zero,
        ).animate(_headerAnimation),
        child: Container(
          margin: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.white)
                      .withOpacity(isDark ? 0.08 : 0.7),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.white)
                        .withOpacity(isDark ? 0.15 : 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : Colors.black)
                          .withOpacity(isDark ? 0.3 : 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                (isDark ? const Color(0xFF5A7CFF) : const Color(0xFF4A6CFA))
                                    .withOpacity(isDark ? 0.2 : 0.1),
                                (isDark ? const Color(0xFF5A7CFF) : const Color(0xFF4A6CFA))
                                    .withOpacity(isDark ? 0.1 : 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: isDark ? const Color(0xFF5A7CFF) : const Color(0xFF4A6CFA),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.location.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [const Color(0xFF5A7CFF), const Color(0xFF7B9CFF)]
                                        : [const Color(0xFF4A6CFA), const Color(0xFF6B8CFF)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${widget.location.toursCount}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'tours khả dụng',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _navigateToAllTours,
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [const Color(0xFF5A7CFF), const Color(0xFF7B9CFF)]
                                  : [const Color(0xFF4A6CFA), const Color(0xFF6B8CFF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (isDark ? const Color(0xFF5A7CFF) : const Color(0xFF4A6CFA))
                                    .withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Tất cả',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                              ],
                            ),
                          ),
                        ),
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

  Widget _emptyState(bool isDark) {
    return Center(
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 600),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.white)
                        .withOpacity(isDark ? 0.1 : 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isDark ? Colors.white : const Color(0xFF4A6CFA))
                          .withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : Colors.black)
                            .withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.explore_off_outlined,
                    size: 80,
                    color: isDark ? const Color(0xFF5A7CFF) : const Color(0xFF4A6CFA),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Không có tour nào",
              style: TextStyle(
                fontSize: 20,
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Vui lòng quay lại sau",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: tours.length,
      itemBuilder: (_, i) => _buildTourCard(tours[i], i, isDark),
    );
  }

  Widget _buildTourCard(dynamic tour, int index, bool isDark) {
    final imageUrl = tour['banner_image_url'];
    final title = tour['title'];
    final price = tour['price'];

    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + index * 100),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: child,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    TourDetailScreen(tourId: tour['id']),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                      ),
                      child: child,
                    ),
                  );
                },
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.05),
                    ]
                        : [
                      Colors.white,
                      Colors.white.withOpacity(0.95),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.white)
                        .withOpacity(isDark ? 0.15 : 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : Colors.black)
                          .withOpacity(isDark ? 0.4 : 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                  const Color(0xFF1A2540),
                                  const Color(0xFF2A1A40),
                                ]
                                    : [
                                  const Color(0xFFE1E9FF),
                                  const Color(0xFFF0E8FF),
                                ],
                              ),
                            ),
                            child: imageUrl != null
                                ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 50,
                                  color: isDark ? Colors.white24 : Colors.black26,
                                ),
                              ),
                            )
                                : Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 50,
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: (isDark ? Colors.black : Colors.white)
                                        .withOpacity(isDark ? 0.3 : 0.7),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.favorite_border_rounded,
                                    color: Color(0xFFFF6B9D),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                title ?? "Tour du lịch",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  height: 1.3,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            if (price != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [
                                      const Color(0xFF5A7CFF).withOpacity(0.25),
                                      const Color(0xFF7B9CFF).withOpacity(0.15),
                                    ]
                                        : [
                                      const Color(0xFF4A6CFA).withOpacity(0.15),
                                      const Color(0xFF6B8CFF).withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (isDark
                                        ? const Color(0xFF5A7CFF)
                                        : const Color(0xFF4A6CFA))
                                        .withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.payments_rounded,
                                      size: 14,
                                      color: isDark
                                          ? const Color(0xFF7B9CFF)
                                          : const Color(0xFF4A6CFA),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        "${price.toString()} VNĐ",
                                        style: TextStyle(
                                          color: isDark
                                              ? const Color(0xFF7B9CFF)
                                              : const Color(0xFF4A6CFA),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          letterSpacing: 0.3,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
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
      ),
    );
  }
}