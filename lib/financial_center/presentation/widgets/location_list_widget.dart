import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/services/location_service.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/widgets/half_circle_tour_screen.dart';
import 'package:http/http.dart' as http;

class LocationListWidget extends StatefulWidget {
  const LocationListWidget({super.key});

  @override
  State<LocationListWidget> createState() => _LocationListWidgetState();
}

class _LocationListWidgetState extends State<LocationListWidget>
    with TickerProviderStateMixin {
  List<LocationModel> allLocations = [];
  List<LocationModel> currentLocations = [];
  List<LocationModel> nextLocations = [];
  int currentIndex = 0;

  late List<AnimationController> _controllers;
  late List<Animation<double>> _flipAnimations;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
          (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _flipAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic),
      );
    }).toList();

    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final data = await LocationService.fetchLocations();
      setState(() {
        allLocations = data;
        currentLocations = data.take(3).toList();
        _updateNextLocations();
      });

      _timer = Timer.periodic(const Duration(seconds: 25), (timer) {
        _nextLocations();
      });
    } catch (e) {
      debugPrint('Lỗi khi tải location: $e');
    }
  }

  void _updateNextLocations() {
    final nextIndex = (currentIndex + 3) % allLocations.length;
    nextLocations = allLocations.skip(nextIndex).take(3).toList();

    while (nextLocations.length < 3 && allLocations.isNotEmpty) {
      final remaining = 3 - nextLocations.length;
      nextLocations.addAll(allLocations.take(remaining));
    }
  }

  void _openTourSpotlight(BuildContext context, LocationModel location) {
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
    );
  }

  Future<void> _nextLocations() async {
    if (allLocations.isEmpty) return;

    for (int i = 0; i < 3; i++) {
      await Future.delayed(Duration(milliseconds: i * 150));
      if (mounted) {
        await _controllers[i].forward(from: 0);
      }
    }

    if (mounted) {
      setState(() {
        currentIndex = (currentIndex + 3) % allLocations.length;
        currentLocations = List.from(nextLocations);
        _updateNextLocations();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (allLocations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final title =
        getTranslated('popular_destinations', context) ?? 'Địa điểm nổi bật';

    return Container(
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          ...List.generate(currentLocations.length, (index) {
            return _buildAnimatedLocationCard(
              currentLocations[index],
              index < nextLocations.length ? nextLocations[index] : currentLocations[index],
              index,
            );
          }),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildAnimatedLocationCard(
      LocationModel currentLocation,
      LocationModel nextLocation,
      int index,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: AnimatedBuilder(
        animation: _flipAnimations[index],
        builder: (context, child) {
          final angle = _flipAnimations[index].value * 3.14159;
          final isSecondHalf = angle > 3.14159 / 2;

          final displayLocation = isSecondHalf ? nextLocation : currentLocation;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateY(angle),
            child: isSecondHalf
                ? Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(3.14159),
              child: _buildLocationCard(displayLocation, onTap: () {
                _openTourSpotlight(context, displayLocation);
              }),
            )
                : _buildLocationCard(displayLocation, onTap: () {
              _openTourSpotlight(context, displayLocation);
            }),
          );
        },
      ),
    );
  }

  Widget _buildLocationCard(LocationModel location, {VoidCallback? onTap}) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardColor,
            Theme.of(context).cardColor.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      Theme.of(context).primaryColor.withOpacity(0.03),
                    ],
                  ),
                ),
              ),
            ),

            Row(
              children: [
                Container(
                  width: 180,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(2, 0),
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        location.imageUrl.isNotEmpty
                            ? location.imageUrl
                            : 'https://via.placeholder.com/140x110.png?text=No+Image',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.location_on,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),

                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.2),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),


                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          location.name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            letterSpacing: 0.3,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).primaryColor.withOpacity(0.15),
                                    Theme.of(context).primaryColor.withOpacity(0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tour,
                                    size: 14,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${location.toursCount} ${getTranslated('tours', context) ?? 'Tours'}',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
        ),
    );
  }
}