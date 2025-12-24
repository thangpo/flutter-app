import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../screens/tour_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

class TourExpandedCard extends StatefulWidget {
  final Map<String, dynamic> tour;
  final VoidCallback onClose;

  const TourExpandedCard({
    super.key,
    required this.tour,
    required this.onClose,
  });

  @override
  State<TourExpandedCard> createState() => _TourExpandedCardState();
}

class _TourExpandedCardState extends State<TourExpandedCard>
    with SingleTickerProviderStateMixin {
  double dragOffset = 0;

  String _formatPrice(dynamic price) {
    if (price == null) return getTranslated('contact_for_price', context) ?? "Liên hệ";
    final p = double.tryParse(price.toString()) ?? 0;
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(p);
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<ThemeController>(context, listen: true).darkTheme;

    final priceText = _formatPrice(widget.tour['price']);

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          dragOffset += details.delta.dy;
          if (dragOffset < 0) dragOffset = 0;
        });
      },
      onVerticalDragEnd: (details) {
        if (dragOffset > 120) {
          widget.onClose();
        } else {
          setState(() => dragOffset = 0);
        }
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, dragOffset, 0),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              height: 360,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.65)
                    : Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Handle + hint
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black26,
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        Text(
                          getTranslated('swipe_down_to_close', context) ??
                              "Vuốt xuống để đóng",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// IMAGE
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      widget.tour['image'],
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// TITLE
                  Text(
                    widget.tour['title'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),

                  const SizedBox(height: 6),

                  /// PRICE
                  Text(
                    "$priceText / ${getTranslated('per_person', context) ?? "người"}",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 14),

                  /// BUTTONS
                  Row(
                    children: [
                      _btn(
                        getTranslated('navigate', context) ?? "Dẫn đường",
                        Colors.green,
                            () => _openMap(widget.tour['lat'], widget.tour['lng']),
                      ),
                      const SizedBox(width: 10),
                      _btn(
                        getTranslated('view_tour', context) ?? "Xem tour",
                        Colors.deepPurple,
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TourDetailScreen(
                                  tourId: widget.tour['id']),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _btn(String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _openMap(double? lat, double? lng) {
    if (lat == null || lng == null) return;
    launchUrl(Uri.parse("https://www.google.com/maps?q=$lat,$lng"));
  }
}