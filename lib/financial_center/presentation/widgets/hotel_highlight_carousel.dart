import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/screens/hotel_detail_screen.dart';

class HotelHighlightCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> hotels;

  const HotelHighlightCarousel({
    super.key,
    required this.hotels,
  });

  @override
  State<HotelHighlightCarousel> createState() => _HotelHighlightCarouselState();
}

class _HotelHighlightCarouselState extends State<HotelHighlightCarousel> {
  late final PageController _controller;
  int _index = 0;

  bool _showSwipeHint = true;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.90);

    _hintTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _showSwipeHint = false);
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _tr(BuildContext context, String key, String fallback) {
    return getTranslated(key, context) ?? fallback;
  }

  void _openHotel(BuildContext context, Map<String, dynamic> hotel) {
    final slug = hotel['slug']?.toString() ?? '';
    if (slug.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr(context, 'hotel_missing_slug', 'Cannot open details (missing slug).')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HotelDetailScreen(slug: slug)),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (widget.hotels.isEmpty) return const SizedBox.shrink();

    final line1 = _tr(context, 'hotel_banner_headline_1', 'Explore.');
    final line2 = _tr(context, 'hotel_banner_headline_2', 'Travel.');
    final line3 = _tr(context, 'hotel_banner_headline_3', 'Inspire.');
    final subtitle = _tr(context, 'hotel_banner_subtitle_short', 'Life is all about the journey.\nFind yours.');
    final cta = _tr(context, 'hotel_banner_get_started', 'Get Started');
    final swipe = _tr(context, 'hotel_banner_swipe_hint', 'Swipe');

    return LayoutBuilder(
      builder: (context, constraints) {
        // Trừ bớt chút cho cảm giác “thoáng” ở tab, nhưng không tạo khoảng trống lớn
        final height = constraints.maxHeight;

        return SizedBox(
          height: height,
          child: Stack(
            children: [
              // PageView full height
              Positioned.fill(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.hotels.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final hotel = widget.hotels[i];
                    final image = (hotel['thumbnail'] ?? hotel['image_url'] ?? '').toString();

                    return Padding(
                      // padding đều 2 bên + trên/dưới nhẹ, tránh sát mép
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: _BannerCard(
                        imageUrl: image,
                        line1: line1,
                        line2: line2,
                        line3: line3,
                        subtitle: subtitle,
                        ctaText: cta,
                        onCta: () => _openHotel(context, hotel),
                      ),
                    );
                  },
                ),
              ),

              // Swipe hint: đặt cao hơn CTA + dots, để không đụng
              Positioned(
                left: 0,
                right: 0,
                bottom: 140,
                child: AnimatedOpacity(
                  opacity: _showSwipeHint ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.28),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withOpacity(0.10)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chevron_left, size: 18, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              swipe,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right, size: 18, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Dots: đặt sát đáy an toàn, không dính CTA nữa
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: _Dots(count: widget.hotels.length, active: _index),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  final String imageUrl;

  final String line1;
  final String line2;
  final String line3;
  final String subtitle;

  final String ctaText;
  final VoidCallback onCta;

  const _BannerCard({
    required this.imageUrl,
    required this.line1,
    required this.line2,
    required this.line3,
    required this.subtitle,
    required this.ctaText,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 32.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          // Image
          Positioned.fill(
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
            )
                : Container(color: Colors.grey[300]),
          ),

          // Overlay: top mist + bottom dark for CTA readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.40, 0.72, 1.0],
                  colors: [
                    Colors.white.withOpacity(0.78),
                    Colors.white.withOpacity(0.30),
                    Colors.black.withOpacity(0.22),
                    Colors.black.withOpacity(0.62),
                  ],
                ),
              ),
            ),
          ),

          // Text (top-left)
          Positioned(
            left: 22,
            top: 26,
            right: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line1,
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -0.6,
                    color: Colors.white.withOpacity(0.98),
                  ),
                ),
                Text(
                  line2,
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -0.6,
                    color: Colors.black,
                  ),
                ),
                Text(
                  line3,
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -0.6,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),

          // CTA (bottom)
          Positioned(
            left: 18,
            right: 18,
            bottom: 54, // ✅ nâng CTA lên để chừa chỗ dots
            child: _CtaButton(
              text: ctaText,
              onTap: onCta,
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _CtaButton({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF23C7B7),
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int active;

  const _Dots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}