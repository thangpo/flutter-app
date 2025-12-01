import 'package:flutter/material.dart';
import 'hotel_fullscreen_gallery.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';



class HotelDetailAppBar extends StatelessWidget {
  final Map<String, dynamic> hotel;
  final int currentImageIndex;
  final ValueChanged<int> onImageIndexChanged;

  const HotelDetailAppBar({
    super.key,
    required this.hotel,
    required this.currentImageIndex,
    required this.onImageIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeController>(context, listen: true);
    final isDark = theme.darkTheme;

    final gallery = hotel['gallery'] as List<dynamic>?;

    final Color overlayBg =
    isDark ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.9);
    final Color iconColor = isDark ? Colors.white : Colors.black87;

    return SliverAppBar(
      expandedHeight: 400,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? Colors.black : Colors.white,
      foregroundColor: iconColor,
      automaticallyImplyLeading: false,
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          _buildImageCarousel(context, gallery),

          // gradient trên
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height:
              MediaQuery.of(context).padding.top + kToolbarHeight + 16,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(isDark ? 0.75 : 0.45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // gradient dưới
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(isDark ? 0.8 : 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // nút back + tim + share
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _roundIconButton(
                  icon: Icons.arrow_back_rounded,
                  background: overlayBg,
                  iconColor: iconColor,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                _roundIconButton(
                  icon: Icons.favorite_border_rounded,
                  background: overlayBg,
                  iconColor: iconColor,
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                _roundIconButton(
                  icon: Icons.ios_share_rounded,
                  background: overlayBg,
                  iconColor: iconColor,
                  onTap: () {},
                ),
              ],
            ),
          ),

          // chỉ số ảnh
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${currentImageIndex + 1}/${gallery?.length ?? 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 THÊM context VÀ WRAP GestureDetector
  Widget _buildImageCarousel(BuildContext context, List<dynamic>? gallery) {
    if (gallery == null || gallery.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.hotel, size: 80, color: Colors.grey),
        ),
      );
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 440,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 4),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        enlargeCenterPage: false,
        viewportFraction: 1.0,
        onPageChanged: (index, reason) {
          onImageIndexChanged(index);
        },
      ),
      items: gallery.asMap().entries.map<Widget>((entry) {
        final index = entry.key;
        final img = entry.value;
        final url = img['large'] ?? img['thumb'] ?? '';

        return GestureDetector(
          onTap: () {
            // mở gallery full screen
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FullScreenImageGallery(
                  images: gallery,
                  initialIndex: index,
                ),
              ),
            );
          },
          child: Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[300],
              child: const Icon(
                Icons.broken_image_rounded,
                size: 50,
                color: Colors.grey,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required Color background,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18, color: iconColor),
        onPressed: onTap,
      ),
    );
  }
}