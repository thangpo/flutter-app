import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

import 'checkout_transition_video.dart';

class FlightCheckoutScreen extends StatelessWidget {
  final FlightCheckoutArgs args;

  const FlightCheckoutScreen({super.key, required this.args});

  String _formatVnd(double value) {
    final n = value.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < n.length; i++) {
      final pos = n.length - i;
      buf.write(n[i]);
      if (pos > 1 && pos % 3 == 1) buf.write('.');
    }
    return '${buf.toString()} ₫';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeController>(context, listen: true).darkTheme;

    final bg = isDark ? const Color(0xFF0E1621) : const Color(0xFFF6F6F7);
    final card = isDark ? const Color(0xFF121E2C) : Colors.white;
    final textMain = isDark ? Colors.white : Colors.black;
    final textSub = (isDark ? Colors.white : Colors.black).withOpacity(0.6);
    final accent = isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);

    final title = getTranslated('checkout', context) ?? 'Thanh toán';
    final passengersLabel = getTranslated('passengers', context) ?? 'Số hành khách';
    final unitLabel = getTranslated('price', context) ?? 'Giá vé';
    final totalLabel = getTranslated('total', context) ?? 'Tổng tiền';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textMain,
        title: Text(title, style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(args.airlineName, style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 6),
                Text(
                  '${args.flightCode} • ${args.fromCode} → ${args.toCode}',
                  style: TextStyle(color: textSub, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${args.departTimeText} (${args.fromCode})',
                        style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${args.arriveTimeText} (${args.toCode})',
                        textAlign: TextAlign.right,
                        style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(color: isDark ? Colors.white12 : Colors.black12),
                const SizedBox(height: 10),
                Text(
                  '$passengersLabel: ${args.passengers}',
                  style: TextStyle(color: textMain, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  '$unitLabel: ${_formatVnd(args.unitPrice)} / 1',
                  style: TextStyle(color: textSub, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalLabel: ${_formatVnd(args.totalPrice)}',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                // TODO: gọi API thanh toán / tạo booking...
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(getTranslated('coming_soon', context) ?? 'Coming soon')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                getTranslated('pay_now', context) ?? 'Thanh toán ngay',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}