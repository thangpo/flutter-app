import 'package:flutter/material.dart';
import 'hotel_fullscreen_gallery.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/wishlist/services/wishlist_service.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/not_logged_in_bottom_sheet_widget.dart';

class HotelDetailAppBar extends StatefulWidget {
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
  State<HotelDetailAppBar> createState() => _HotelDetailAppBarState();
}

class _HotelDetailAppBarState extends State<HotelDetailAppBar> {
  late final WishlistService _wishlist;

  bool _isFav = false;
  bool _favLoading = false;
  bool _didInit = false;

  int _hotelId() {
    final raw = widget.hotel['id'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    _wishlist = WishlistService(
      baseUrl: 'https://vietnamtoure.com/api',
      getAccessToken: () async {
        final auth = Provider.of<AuthController>(context, listen: false);
        return auth.getUserToken();
      },
    );

    _loadFavState();
  }

  Future<void> _loadFavState() async {
    final id = _hotelId();
    if (id <= 0) return;

    try {
      final active = await _wishlist.check(objectId: id, objectModel: 'hotel');
      if (!mounted) return;
      setState(() => _isFav = active);
    } catch (_) {

    }
  }

  Future<void> _toggleFav() async {
    if (_favLoading) return;
    final auth = Provider.of<AuthController>(context, listen: false);
    if (!auth.isLoggedIn()) {
      showModalBottomSheet(
        backgroundColor: const Color(0x00FFFFFF),
        context: context,
        builder: (_) => const NotLoggedInBottomSheetWidget(),
      );
      return;
    }

    final id = _hotelId();
    if (id <= 0) return;

    setState(() => _favLoading = true);

    try {
      final active = await _wishlist.toggle(objectId: id, objectModel: 'hotel');
      if (!mounted) return;
      setState(() => _isFav = active);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể cập nhật yêu thích: $e')),
      );
    } finally {
      if (mounted) setState(() => _favLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeController>(context, listen: true);
    final isDark = theme.darkTheme;
    final gallery = widget.hotel['gallery'] as List<dynamic>?;
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
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
                  icon: _isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  background: overlayBg,
                  iconColor: _isFav ? Colors.red : iconColor,
                  loading: _favLoading,
                  onTap: _toggleFav,
                ),

                const SizedBox(width: 8),

                _roundIconButton(
                  icon: Icons.ios_share_rounded,
                  background: overlayBg,
                  iconColor: iconColor,
                  onTap: () {
                    final name = (widget.hotel['name'] ?? widget.hotel['title'] ?? 'Hotel').toString();
                    final link = (widget.hotel['share_url'] ?? widget.hotel['url'] ?? '').toString();
                    final g = widget.hotel['gallery'] as List<dynamic>?;
                    final firstImg = (g != null && g.isNotEmpty)
                        ? ((g.first['large'] ?? g.first['thumb'] ?? '') as String)
                        : '';

                    final text = [
                      name,
                      if (link.isNotEmpty) link,
                      if (firstImg.isNotEmpty) firstImg,
                    ].join('\n');

                    Share.share(text);
                  },
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${widget.currentImageIndex + 1}/${gallery?.length ?? 1}',
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
        onPageChanged: (index, reason) => widget.onImageIndexChanged(index),
      ),
      items: gallery.asMap().entries.map<Widget>((entry) {
        final index = entry.key;
        final img = entry.value;
        final url = img['large'] ?? img['thumb'] ?? '';

        return GestureDetector(
          onTap: () {
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
    bool loading = false,
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
        icon: loading
            ? SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: iconColor,
          ),
        )
            : Icon(icon, size: 18, color: iconColor),
        onPressed: loading ? null : onTap,
      ),
    );
  }
}