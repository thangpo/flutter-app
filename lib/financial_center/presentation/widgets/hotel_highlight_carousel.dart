import 'package:flutter/material.dart';

class HotelHighlightCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> hotels;
  final void Function(Map<String, dynamic>)? onTap;

  const HotelHighlightCarousel({
    super.key,
    required this.hotels,
    this.onTap,
  });

  @override
  State<HotelHighlightCarousel> createState() =>
      _HotelHighlightCarouselState();
}

class _HotelHighlightCarouselState extends State<HotelHighlightCarousel> {
  late final PageController _controller;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      viewportFraction: 0.72,
    );

    _controller.addListener(() {
      setState(() => _page = _controller.page ?? 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hotels.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 400,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.hotels.length,
        itemBuilder: (context, index) {
          final hotel = widget.hotels[index];
          final image = hotel['thumbnail'] ?? hotel['image_url'];
          final title = hotel['title'] ?? '';
          final price = hotel['price']?.toString();
          final rawDiff = index - _page;
          final diff = rawDiff.abs();
          final scale = (1 - diff * 0.12).clamp(0.86, 1.0);

          double translateY;
          if (rawDiff < 0) {
            translateY = diff * 52;
          } else if (rawDiff > 0) {
            translateY = diff * 16;
          } else {
            translateY = 0;
          }

          return Transform.translate(
            offset: Offset(0, translateY),
            child: Transform.scale(
              scale: scale,
              child: GestureDetector(
                onTap: () => widget.onTap?.call(hotel),
                child: _HotelCard(
                  image: image,
                  title: title,
                  price: price,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HotelCard extends StatelessWidget {
  final String? image;
  final String title;
  final String? price;

  const _HotelCard({
    required this.image,
    required this.title,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        children: [
          /// IMAGE
          Positioned.fill(
            child: image != null && image!.isNotEmpty
                ? Image.network(
              image!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: Colors.grey[300]),
            )
                : Container(color: Colors.grey[300]),
          ),

          /// GRADIENT
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.75),
                  ],
                ),
              ),
            ),
          ),

          /// TEXT
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (price != null && price!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '$price \$ / đêm',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}