import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/tour_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/services/tour_service.dart';



class TourListWidget extends StatefulWidget {
  final int? locationId;
  const TourListWidget({super.key, this.locationId});

  @override
  State<TourListWidget> createState() => _TourListWidgetState();
}

class _TourListWidgetState extends State<TourListWidget> {
  bool _isLoading = true;
  List<dynamic> _tours = [];
  final Map<int, int> _imageIndexes = {};

  @override
  void initState() {
    super.initState();
    _loadTours();
  }

  Future<void> _loadTours() async {
    try {
      List<dynamic> data;
      if (widget.locationId != null) {
        data = await TourService.fetchToursByLocation(widget.locationId!);
      } else {
        data = await TourService.fetchTours();
      }

      setState(() {
        _tours = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Lỗi tải tour: $e');
      setState(() => _isLoading = false);
    }
  }

  String formatCurrency(String? priceString) {
    if (priceString == null) return '—';
    try {
      final double price = double.parse(priceString);
      final format =
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
      return format.format(price);
    } catch (_) {
      return '${priceString}₫';
    }
  }

  void _nextImage(int tourIndex) {
    final gallery = List<String>.from(_tours[tourIndex]['gallery_urls'] ?? []);
    if (gallery.isEmpty) return;

    setState(() {
      final current = _imageIndexes[tourIndex] ?? 0;
      _imageIndexes[tourIndex] = (current + 1) % gallery.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<ThemeController>(context, listen: true).darkTheme;

    if (_isLoading) {
      return _SkeletonGrid(isDark: isDark);
    }

    if (_tours.isEmpty) {
      return Center(
        child: Text(
          getTranslated('no_tours_found', context) ?? 'Không có tour nào.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            getTranslated('recommended_tours', context) ??
                'Tour đề xuất',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.builder(
          itemCount: _tours.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.88,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final tour = _tours[index];

            final gallery =
            List<String>.from(tour['gallery_urls'] ?? []);
            final currentIndex = _imageIndexes[index] ?? 0;
            final imageUrl = gallery.isNotEmpty
                ? gallery[currentIndex]
                : (tour['image_url'] ?? '');

            final title = (tour['title'] ?? 'Tour').toString();
            final location =
            (tour['location'] ?? tour['address'] ?? '').toString();

            final price = formatCurrency(
              tour['price']?.toString(),
            );

            final double rating = double.tryParse(
              (tour['rating'] ?? tour['review_score'] ?? '4.5')
                  .toString(),
            ) ??
                4.5;
            final int reviewCount = int.tryParse(
              (tour['review_count'] ?? '120').toString(),
            ) ??
                0;

            return _TourCard(
              imageUrl: imageUrl,
              title: title,
              location: location,
              price: price,
              rating: rating,
              reviewCount: reviewCount,
              isDark: isDark,
              hasMultipleImages: gallery.length > 1,
              onTapChangeImage: () => _nextImage(index),
              onTapCard: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TourDetailScreen(tourId: tour['id']),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _TourCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String location;
  final String price;
  final double rating;
  final int reviewCount;
  final bool isDark;
  final bool hasMultipleImages;
  final VoidCallback onTapChangeImage;
  final VoidCallback onTapCard;

  const _TourCard({
    required this.imageUrl,
    required this.title,
    required this.location,
    required this.price,
    required this.rating,
    required this.reviewCount,
    required this.isDark,
    required this.hasMultipleImages,
    required this.onTapChangeImage,
    required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.7)
        : Colors.black.withOpacity(0.15);

    return GestureDetector(
      onTap: onTapCard,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 18,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: imageUrl.isNotEmpty
                      ? imageUrl
                      : 'https://via.placeholder.com/300x220.png?text=Tour',
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const _ShimmerPlaceholder(),
                  errorWidget: (_, __, ___) => Container(
                    color: isDark
                        ? const Color(0xFF30364A)
                        : Colors.grey[300],
                    child: Icon(
                      Icons.image_not_supported,
                      color: isDark
                          ? Colors.grey[500]
                          : Colors.grey[600],
                      size: 36,
                    ),
                  ),
                  fadeInDuration:
                  const Duration(milliseconds: 500),
                ),
              ),

              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.75),
                        Colors.black.withOpacity(0.15),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: hasMultipleImages ? onTapChangeImage : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.30),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$price / Month',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.7),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFD54F),
                                size: 16,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        if (location.isNotEmpty)
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  final bool isDark;
  const _SkeletonGrid({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 24,
            width: 180,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            itemCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.88,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (_, __) =>
                _SkeletonCard(isDark: isDark),
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final bool isDark;
  const _SkeletonCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final baseColor =
    isDark ? const Color(0xFF30364A) : Colors.grey[300];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: isDark ? const Color(0xFF222733) : Colors.white,
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(isDark ? 0.6 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Container(color: baseColor),
            const _ShimmerPlaceholder(),
          ],
        ),
      ),
    );
  }
}

class _ShimmerPlaceholder extends StatefulWidget {
  const _ShimmerPlaceholder();

  @override
  State<_ShimmerPlaceholder> createState() =>
      _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
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