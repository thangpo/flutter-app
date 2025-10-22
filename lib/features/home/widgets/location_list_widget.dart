import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/services/location_service.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

class LocationListWidget extends StatefulWidget {
  const LocationListWidget({super.key});

  @override
  State<LocationListWidget> createState() => _LocationListWidgetState();
}

class _LocationListWidgetState extends State<LocationListWidget> {
  late Future<List<LocationModel>> _locationsFuture;
  late PageController _pageController;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _locationsFuture = LocationService.fetchLocations();
    _pageController = PageController(
      viewportFraction: 0.75,
      initialPage: 0,
    );

    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!,
            Colors.purple[50]!,
            Colors.pink[50]!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Text(
              getTranslated('popular_locations', context) ?? 'Popular Locations',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          FutureBuilder<List<LocationModel>>(
            future: _locationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: Colors.blue),
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "${getTranslated('error', context) ?? 'Error'}: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      getTranslated('no_locations', context) ?? 'No locations available',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              final locations = snapshot.data!;

              return SizedBox(
                height: 320,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    return _buildCarouselItem(
                      context,
                      locations[index],
                      index,
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 16), // Padding bottom cho gradient
        ],
      ),
    );
  }

  Widget _buildCarouselItem(BuildContext context, LocationModel location, int index) {
    // Tính toán scale và opacity dựa trên vị trí
    double diff = (_currentPage - index).abs();
    double scale = 1.0 - (diff * 0.25).clamp(0.0, 0.25);
    double opacity = 1.0 - (diff * 0.5).clamp(0.0, 0.7);

    // Item ở giữa sẽ có scale = 1.0, các item bên cạnh nhỏ hơn
    bool isCenter = diff < 0.5;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: scale, end: scale),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: opacity,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: isCenter ? 15 : 35,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(isCenter ? 0.3 : 0.1),
                    blurRadius: isCenter ? 20 : 10,
                    offset: const Offset(0, 8),
                    spreadRadius: isCenter ? 2 : 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hình ảnh
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            location.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image,
                                size: 60,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                          // Badge cho item ở giữa
                          if (isCenter)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Popular',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Thông tin
                    Container(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            location.name,
                            style: TextStyle(
                              fontSize: isCenter ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.tour,
                                size: 16,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  "${location.toursCount} ${getTranslated('tours', context) ?? 'tours'}",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
        );
      },
    );
  }
}