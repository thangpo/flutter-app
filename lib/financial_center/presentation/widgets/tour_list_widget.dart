import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/services/tour_service.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import '../screens/tour_detail_screen.dart';

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

  @override
  void dispose() {
    super.dispose();
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
      final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
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
    if (_isLoading) {
      return const _SkeletonGrid();
    }

    if (_tours.isEmpty) {
      return Center(
        child: Text(getTranslated('no_tours_found', context) ?? 'Không có tour nào.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            getTranslated('recommended_tours', context) ?? 'Tour đề xuất',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          itemCount: _tours.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final tour = _tours[index];
            final gallery = List<String>.from(tour['gallery_urls'] ?? []);
            final currentIndex = _imageIndexes[index] ?? 0;
            final imageUrl = gallery.isNotEmpty
                ? gallery[currentIndex]
                : (tour['image_url'] ?? '');

            final title = tour['title'] ?? 'Tour';
            final location = tour['location'] ?? '';
            final price = formatCurrency(tour['price']);

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TourDetailScreen(tourId: tour['id'])),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ẢNH + NHẤN ĐỂ ĐỔI
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: GestureDetector(
                        onTap: () => _nextImage(index),
                        child: Stack(
                          children: [
                            CachedNetworkImage(
                              imageUrl: imageUrl.isNotEmpty
                                  ? imageUrl
                                  : 'https://via.placeholder.com/300x200.png?text=Tour',
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _ShimmerPlaceholder(),
                              errorWidget: (_, __, ___) => Container(
                                height: 120,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported, size: 40),
                              ),
                              fadeInDuration: const Duration(milliseconds: 600),
                            ),
                            // Icon "nhấn để đổi ảnh"
                            if (gallery.length > 1)
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.refresh, size: 16, color: Colors.white),
                                ),
                              ),
                            // Dots nhỏ nếu có nhiều ảnh
                            if (gallery.length > 1)
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Row(
                                  children: List.generate(
                                    gallery.length,
                                        (i) => AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.only(right: 4),
                                      width: i == currentIndex ? 12 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: i == currentIndex ? Colors.white : Colors.white54,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Nội dung
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            Text(
                              price,
                              style: TextStyle(
                                fontSize: 15,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// === SKELETON LOADING ===
class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 24, width: 180, color: Colors.grey[300]),
          const SizedBox(height: 12),
          GridView.builder(
            itemCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (_, __) => const _SkeletonCard(),
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: const BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: _ShimmerPlaceholder(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, width: double.infinity, color: Colors.grey[300]),
                  const SizedBox(height: 6),
                  Container(height: 12, width: 80, color: Colors.grey[300]),
                  const Spacer(),
                  Container(height: 16, width: 60, color: Colors.grey[300]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerPlaceholder extends StatefulWidget {
  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
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
              colors: [Colors.transparent, Colors.white.withOpacity(0.3), Colors.transparent],
            ),
          ),
        );
      },
    );
  }
}