import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import '../screens/hotel_detail_screen.dart';

// Transition iOS style
class IOSAppOpenTransition extends PageRouteBuilder {
  final Widget page;
  IOSAppOpenTransition({required this.page})
      : super(
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const curve = Curves.easeOutCubic;
      final tween =
      Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: curve));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

class HotelPopup extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onClose;

  const HotelPopup({
    super.key,
    required this.data,
    required this.onClose,
  });

  @override
  State<HotelPopup> createState() => _HotelPopupState();
}

class _HotelPopupState extends State<HotelPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _scale;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.94,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  // mở Google Maps
  Future<void> _navigateGoogleMap() async {
    final lat = widget.data['lat']?.toString();
    final lng = widget.data['lng']?.toString();

    if (lat == null || lng == null) return;

    final Uri url = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = widget.data['title'] ?? '';
    final thumb = widget.data['thumbnail'] ?? widget.data['image_url'] ?? '';
    final address = widget.data['address'] ?? widget.data['location'] ?? '';
    final price = widget.data['price']?.toString() ?? '';
    final rating = double.tryParse(widget.data['review_score']?.toString() ?? '');

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0f172a) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HANDLE + CLOSE BUTTON
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      width: 45,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 22,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  ),
                  onPressed: widget.onClose,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 170,
                width: double.infinity,
                child: thumb.isNotEmpty
                    ? Image.network(
                  thumb,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  ),
                )
                    : Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // INFO
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.place, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    if (rating != null) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 10),
                if (price.isNotEmpty)
                  Text(
                    "${getTranslated('from_price', context) ?? 'Giá từ'}: $price đ",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // BUTTON: VIEW DETAILS
            GestureDetector(
              onTapDown: (_) => _scale.forward(),
              onTapUp: (_) {
                _scale.reverse();

                Navigator.push(
                  context,
                  IOSAppOpenTransition(
                    page: HotelDetailScreen(slug: widget.data['slug']),
                  ),
                );
              },
              child: AnimatedScale(
                scale: _scale.value,
                duration: const Duration(milliseconds: 120),
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(
                    child: Text(
                      getTranslated('view_hotel', context) ?? "Xem khách sạn",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // BUTTON: GOOGLE MAPS
            SizedBox(
              height: 50,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _navigateGoogleMap,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF10B981)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                icon: const Icon(Icons.directions, color: Color(0xFF10B981)),
                label: Text(
                  getTranslated('navigate', context) ?? "Dẫn đường",
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}