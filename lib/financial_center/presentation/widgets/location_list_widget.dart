import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/services/location_service.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/widgets/half_circle_tour_screen.dart';

class LocationListWidget extends StatefulWidget {
  const LocationListWidget({super.key});

  @override
  State<LocationListWidget> createState() => _LocationListWidgetState();
}

class _LocationListWidgetState extends State<LocationListWidget> {
  List<LocationModel> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocationsWithCache();
  }

  Future<void> _loadLocationsWithCache() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    try {
      final cachedData = prefs.getString('cached_locations');
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        final cachedLocations =
        jsonList.map((e) => LocationModel.fromJson(e)).toList();

        if (cachedLocations.isNotEmpty && mounted) {
          setState(() {
            _locations = cachedLocations;
            _isLoading = false;
          });
        }
      }

      final data = await LocationService.fetchLocations();
      final jsonList = data.map((e) => e.toJson()).toList();
      await prefs.setString('cached_locations', jsonEncode(jsonList));

      if (mounted) {
        setState(() {
          _locations = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi tải location: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openTourSpotlight(BuildContext context, LocationModel location) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) {
          return FadeTransition(
            opacity: animation,
            child: HalfCircleTourScreen(location: location),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return _SkeletonLocationGrid(isDark: isDark);
    }

    if (_locations.isEmpty) {
      return const _EmptyState();
    }

    final String title =
        getTranslated('popular_destinations', context) ?? 'Địa điểm nổi bật';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildStaggeredGrid(isDark),
        ],
      ),
    );
  }

  Widget _buildStaggeredGrid(bool isDark) {
    const double tallHeight = 240;
    const double shortHeight = 170;

    final List<LocationModel> leftColumn = [];
    final List<LocationModel> rightColumn = [];
    final List<double> leftHeights = [];
    final List<double> rightHeights = [];

    for (int i = 0; i < _locations.length; i++) {
      final int columnIndex = i ~/ 2;
      final bool isLeftColumn = i.isEven;

      if (isLeftColumn) {
        leftColumn.add(_locations[i]);
        leftHeights.add(columnIndex.isEven ? tallHeight : shortHeight);
      } else {
        rightColumn.add(_locations[i]);
        rightHeights.add(columnIndex.isEven ? shortHeight : tallHeight);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: List.generate(leftColumn.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < leftColumn.length - 1 ? 8 : 0,
                ),
                child: _LocationCard(
                  location: leftColumn[index],
                  isDark: isDark,
                  height: leftHeights[index],
                  onTap: () => _openTourSpotlight(context, leftColumn[index]),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: List.generate(rightColumn.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < rightColumn.length - 1 ? 8 : 0,
                ),
                child: _LocationCard(
                  location: rightColumn[index],
                  isDark: isDark,
                  height: rightHeights[index],
                  onTap: () => _openTourSpotlight(context, rightColumn[index]),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _LocationCard extends StatefulWidget {
  final LocationModel location;
  final bool isDark;
  final double height;
  final VoidCallback onTap;

  const _LocationCard({
    required this.location,
    required this.isDark,
    required this.height,
    required this.onTap,
  });

  @override
  State<_LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<_LocationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  double _getRating() {
    return 4.8;
  }

  String _getSubtitle(BuildContext context) {
    final toursCount = widget.location.toursCount;
    final toursLabel = getTranslated('tours', context) ?? 'Tours';
    return '$toursCount $toursLabel';
  }

  @override
  Widget build(BuildContext context) {
    final rating = _getRating();
    final subtitle = _getSubtitle(context);
    final imageUrl = widget.location.imageUrl;

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(widget.isDark ? 0.4 : 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: _imageLoaded ? 1 : 0,
                    duration: const Duration(milliseconds: 400),
                    child: Image.network(
                      imageUrl.isNotEmpty
                          ? imageUrl
                          : 'https://via.placeholder.com/200x200.png?text=Location',
                      fit: BoxFit.cover,
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded || frame != null) {
                          if (!_imageLoaded) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() => _imageLoaded = true);
                              }
                            });
                          }
                          return child;
                        }
                        return const SizedBox.shrink();
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: widget.isDark
                            ? const Color(0xFF30364A)
                            : Colors.grey[300],
                        child: Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: widget.isDark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),

                if (!_imageLoaded)
                  Positioned.fill(
                    child: Container(
                      color: widget.isDark
                          ? const Color(0xFF30364A)
                          : Colors.grey[300],
                    ),
                  ),

                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF0052A4).withOpacity(0.15),
                          const Color(0xFF0052A4).withOpacity(0.25),
                        ],
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
                          Colors.black.withOpacity(0.65),
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: 12,
                  top: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.location.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          shadows: [
                            Shadow(
                              color: Colors.black38,
                              offset: Offset(0, 1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Positioned(
                  left: 12,
                  bottom: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFFFFB300),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  right: 12,
                  bottom: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: Color(0xFF1A1A1A),
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
    );
  }
}

class _SkeletonLocationGrid extends StatelessWidget {
  final bool isDark;
  const _SkeletonLocationGrid({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 22,
                width: 160,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSkeletonStaggeredGrid(isDark),
        ],
      ),
    );
  }

  Widget _buildSkeletonStaggeredGrid(bool isDark) {
    const double tallHeight = 180;
    const double shortHeight = 145;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SkeletonCard(isDark: isDark, height: tallHeight),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SkeletonCard(isDark: isDark, height: shortHeight),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SkeletonCard(isDark: isDark, height: shortHeight),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SkeletonCard(isDark: isDark, height: tallHeight),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final bool isDark;
  final double height;

  const _SkeletonCard({
    required this.isDark,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF30364A) : Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const _Shimmer(),
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer();

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
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _controller.value * 2, 0),
              end: Alignment(1.0 + _controller.value * 2, 0),
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.5),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
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
                    Icons.location_off,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  getTranslated('no_locations', context) ??
                      'Không có địa điểm nào',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
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
}