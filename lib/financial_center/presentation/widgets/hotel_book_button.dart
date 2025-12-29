import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

class HotelBookButton extends StatelessWidget {
  final int totalRoomsSelected;
  final VoidCallback onPressed;

  const HotelBookButton({
    super.key,
    required this.totalRoomsSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = totalRoomsSelected > 0;

    final bookNow = getTranslated('hotel_book_now', context) ?? 'Đặt phòng ngay';
    final roomText = getTranslated('hotel_room', context) ?? 'phòng';

    final label = hasSelection
        ? '$bookNow ($totalRoomsSelected $roomText)'
        : bookNow;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
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