import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

class FlightPromoBanner extends StatelessWidget {
  const FlightPromoBanner({super.key});

  String tr(BuildContext context, String key, String fallback) {
    return getTranslated(key, context) ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Gradient bgGradient = isDark
        ? const LinearGradient(
      colors: [
        Color(0xFF0F172A),
        Color(0xFF1E293B),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    )
        : LinearGradient(
      colors: [
        Colors.pink[50]!,
        Colors.orange[50]!,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final Color titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final Color subtitleColor =
    isDark ? Colors.white70 : const Color(0xFF4B5563);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context, 'flight_promo_title', 'Vé bay quốc tế'),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tr(context, 'flight_promo_subtitle', 'Chill thư thả, săn deal xả láng!'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFFEC4899) : Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tr(context, 'flight_promo_badge', 'Giảm 50%'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://images.unsplash.com/photo-1528127269322-539801943592?w=200',
              width: 100,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 100,
                  height: 70,
                  color: isDark ? const Color(0xFF0F172A) : Colors.cyan[100],
                  child: Icon(
                    Icons.flight_takeoff_rounded,
                    color: isDark ? Colors.white70 : Colors.white,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}