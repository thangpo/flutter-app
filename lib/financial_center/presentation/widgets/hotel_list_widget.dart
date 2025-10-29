import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import '../services/hotel_service.dart';
import '../screens/hotel_detail_screen.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.blue, Colors.purple],
            ).createShader(bounds),
            child: Text(
              getTranslated("featured_hotels", context) ?? "Khách sạn nổi bật",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          _isLoading
              ? _buildSkeletonLoader()
              : _hotels.isEmpty
              ? _buildEmptyState()
              : _buildHotelList(isDark),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Column(
      children: List.generate(3, (_) => const _SkeletonHotelCard()),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.hotel_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            getTranslated("no_hotels", context) ?? "Không có khách sạn nào",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
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
                position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
                    .animate(animation),
                child: _HotelCardItem(hotel: hotel, isDark: isDark),
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

class _HotelCardItemState extends State<_HotelCardItem> {
  bool _isTapped = false;

  List<Widget> _buildStarRating(double score) {
    const int maxStars = 5;
    final List<Widget> stars = [];
    final double roundedScore = (score * 2).round() / 2;

    for (int i = 1; i <= maxStars; i++) {
      if (i <= roundedScore) {
        stars.add(const Icon(Icons.star, size: 16, color: Colors.amber));
      } else if (i - 0.5 <= roundedScore) {
        stars.add(const Icon(Icons.star_half, size: 16, color: Colors.amber));
      } else {
        stars.add(const Icon(Icons.star_border, size: 16, color: Colors.amber));
      }
    }
    return stars;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HotelDetailScreen(slug: widget.hotel['slug']),
          ),
        );
      },
      onTapCancel: () => setState(() => _isTapped = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        transform: Matrix4.identity()..scale(_isTapped ? 0.98 : 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: widget.isDark ? const Color(0xFF2A2A2A) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.blue.withOpacity(_isTapped ? 0.6 : 0.3),
                blurRadius: _isTapped ? 30 : 20,
                spreadRadius: _isTapped ? 2 : 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.05),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'hotel-${widget.hotel['slug']}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            widget.hotel['thumbnail'] ?? '',
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 76,
                              height: 76,
                              color: Colors.grey[300],
                              child: const Icon(Icons.hotel, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.hotel['title'] ??
                                  getTranslated("no_title", context) ??
                                  "Không có tiêu đề",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  widget.hotel['location'] ?? '',
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ..._buildStarRating(double.tryParse(widget.hotel['review_score'] ?? '0') ?? 0),
                                const SizedBox(width: 8),
                                Text(
                                  widget.hotel['review_score'] ?? '0.0',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Colors.purple],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${widget.hotel['price'] ?? '??'} ₫",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
    );
  }
}

class _SkeletonHotelCard extends StatelessWidget {
  const _SkeletonHotelCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          _shimmer(Container(width: 76, height: 76, color: Colors.grey[300])),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmer(Container(width: 180, height: 16, color: Colors.grey[300])),
                const SizedBox(height: 8),
                _shimmer(Container(width: 120, height: 12, color: Colors.grey[300])),
                const SizedBox(height: 12),
                _shimmer(Container(width: 80, height: 12, color: Colors.grey[300])),
              ],
            ),
          ),
          _shimmer(Container(width: 60, height: 30, color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _shimmer(Widget child) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1000),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: child is Container ? (child).color : Colors.grey[300],
      ),
      child: child,
    );
  }
}