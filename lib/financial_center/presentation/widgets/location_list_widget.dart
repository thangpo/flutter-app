import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/services/location_service.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/widgets/half_circle_tour_screen.dart';

class LocationListWidget extends StatefulWidget {
  const LocationListWidget({super.key});

  @override
  State<LocationListWidget> createState() => _LocationListWidgetState();
}

class _LocationListWidgetState extends State<LocationListWidget>
    with TickerProviderStateMixin {
  List<LocationModel> allLocations = [];
  List<LocationModel> currentLocations = [];
  int currentIndex = 0;
  bool isLoading = true;
  bool isAnimating = false;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadLocationsWithCache();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOutCubic,
    ));

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadLocationsWithCache() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    try {
      final cachedData = prefs.getString('cached_locations');
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        final cachedLocations = jsonList.map((e) => LocationModel.fromJson(e)).toList();

        if (cachedLocations.isNotEmpty) {
          setState(() {
            allLocations = cachedLocations;
            currentLocations = cachedLocations.take(3).toList();
            isLoading = false;
          });
          _fadeController.forward();
          _startAutoSlideTimer();
          return;
        }
      }

      final data = await LocationService.fetchLocations();
      final jsonList = data.map((e) => e.toJson()).toList();

      await prefs.setString('cached_locations', jsonEncode(jsonList));

      setState(() {
        allLocations = data;
        currentLocations = data.take(3).toList();
        isLoading = false;
      });
      _fadeController.forward();
      _startAutoSlideTimer();
    } catch (e) {
      debugPrint('Lỗi khi tải location: $e');
      setState(() => isLoading = false);
    }
  }

  void _startAutoSlideTimer() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !isAnimating) {
        _nextLocations();
      }
    });
  }

  void _resetAutoSlideTimer() {
    _startAutoSlideTimer();
  }

  Future<void> _nextLocations() async {
    if (allLocations.isEmpty || !mounted || isAnimating) return;

    setState(() => isAnimating = true);

    await _slideController.forward();

    if (mounted) {
      setState(() {
        currentIndex = (currentIndex + 3) % allLocations.length;
        final nextIndex = currentIndex;

        currentLocations = [];
        for (int i = 0; i < 3; i++) {
          final index = (nextIndex + i) % allLocations.length;
          currentLocations.add(allLocations[index]);
        }
      });

      _slideController.value = 0;
      setState(() => isAnimating = false);

      _startAutoSlideTimer();
    }
  }

  Future<void> _previousLocations() async {
    if (allLocations.isEmpty || !mounted || isAnimating) return;

    setState(() => isAnimating = true);

    _slideController.value = 1.0;

    setState(() {
      currentIndex = (currentIndex - 3) % allLocations.length;
      if (currentIndex < 0) currentIndex += allLocations.length;

      final nextIndex = currentIndex;
      currentLocations = [];
      for (int i = 0; i < 3; i++) {
        final index = (nextIndex + i) % allLocations.length;
        currentLocations.add(allLocations[index]);
      }
    });

    await _slideController.reverse();

    if (mounted) {
      setState(() => isAnimating = false);
      _resetAutoSlideTimer();
    }
  }

  void _openTourSpotlight(BuildContext context, LocationModel location) {
    _autoSlideTimer?.cancel();

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, animation, __) {
          return FadeTransition(
            opacity: animation,
            child: HalfCircleTourScreen(location: location),
          );
        },
      ),
    ).then((_) {
      _startAutoSlideTimer();
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: isLoading
          ? const _SkeletonLocationList(key: ValueKey('skeleton'))
          : allLocations.isEmpty
          ? const _EmptyState(key: ValueKey('empty'))
          : _buildLocationList(),
    );
  }

  Widget _buildLocationList() {
    final title = getTranslated('popular_destinations', context) ?? 'Địa điểm nổi bật';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;

          if (details.primaryVelocity! > 300) {
            _previousLocations();
          } else if (details.primaryVelocity! < -300) {
            _nextLocations();
          }
        },
        child: Container(
          key: const ValueKey('content'),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
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
                            Theme.of(context).primaryColor.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
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
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios, size: 18),
                          onPressed: isAnimating ? null : _previousLocations,
                          color: Theme.of(context).primaryColor,
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_forward_ios, size: 18),
                          onPressed: isAnimating ? null : _nextLocations,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              ClipRect(
                child: AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        Transform.translate(
                          offset: Offset(
                            _slideAnimation.value.dx * MediaQuery.of(context).size.width,
                            0,
                          ),
                          child: Column(
                            children: List.generate(currentLocations.length, (index) {
                              return _LocationCard(
                                key: ValueKey('current_${currentLocations[index].name}_$index'),
                                location: currentLocations[index],
                                onTap: () => _openTourSpotlight(context, currentLocations[index]),
                              );
                            }),
                          ),
                        ),

                        if (_slideController.value > 0)
                          Transform.translate(
                            offset: Offset(
                              (_slideAnimation.value.dx + 1.0) * MediaQuery.of(context).size.width,
                              0,
                            ),
                            child: Column(
                              children: List.generate(currentLocations.length, (index) {
                                return _LocationCard(
                                  key: ValueKey('next_${currentLocations[index].name}_$index'),
                                  location: currentLocations[index],
                                  onTap: () => _openTourSpotlight(context, currentLocations[index]),
                                );
                              }),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    (allLocations.length / 3).ceil(),
                        (index) {
                      final isActive = (currentIndex ~/ 3) == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).primaryColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationCard extends StatefulWidget {
  final LocationModel location;
  final VoidCallback onTap;

  const _LocationCard({required Key key, required this.location, required this.onTap})
      : super(key: key);

  @override
  State<_LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<_LocationCard> with SingleTickerProviderStateMixin {
  bool _imageLoaded = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) {
          _scaleController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _scaleController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  AnimatedOpacity(
                    opacity: _imageLoaded ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    child: Container(color: Colors.grey[300]),
                  ),

                  AnimatedOpacity(
                    opacity: _imageLoaded ? 1 : 0,
                    duration: const Duration(milliseconds: 600),
                    child: Image.network(
                      widget.location.imageUrl.isNotEmpty
                          ? widget.location.imageUrl
                          : 'https://via.placeholder.com/140x110.png?text=No+Image',
                      width: double.infinity,
                      height: 110,
                      fit: BoxFit.cover,
                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded || frame != null) {
                          if (!_imageLoaded) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() => _imageLoaded = true);
                            });
                          }
                          return child;
                        }
                        return const SizedBox.shrink();
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.location_on, size: 40, color: Colors.grey[400]),
                      ),
                    ),
                  ),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      const SizedBox(width: 180),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.location.name,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                  shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.tour, size: 14, color: Theme.of(context).primaryColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${widget.location.toursCount} ${getTranslated('tours', context) ?? 'Tours'}',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
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

class _SkeletonLocationList extends StatelessWidget {
  const _SkeletonLocationList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Container(width: 4, height: 24, color: Colors.grey[400]),
              const SizedBox(width: 12),
              Container(width: 180, height: 24, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (_) => const _SkeletonCard()),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          _Shimmer(),
          Row(
            children: [
              Container(width: 180, height: 110, color: Colors.grey[400]),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(height: 20, width: 140, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Container(height: 28, width: 100, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
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
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _controller.value * 2, 0),
              end: Alignment(1.0 + _controller.value * 2, 0),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Không có địa điểm nào',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}