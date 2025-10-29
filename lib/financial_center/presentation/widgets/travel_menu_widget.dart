import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/styles.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

class TravelMenuWidget extends StatelessWidget {
  const TravelMenuWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context, listen: false);
    final bool darkTheme = themeController.darkTheme;

    final Color bgColor = darkTheme
        ? Colors.grey[850]!
        : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      color: bgColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TravelItem(
            icon: Icons.flight_takeoff,
            title: getTranslated('flight', context) ?? 'Đặt vé máy bay',
            color: Colors.pinkAccent,
            onTap: () {
              // TODO: chuyển sang trang đặt vé máy bay
            },
          ),
          _TravelItem(
            icon: Icons.hotel,
            title: getTranslated('hotel', context) ?? 'Đặt khách sạn',
            color: Colors.orangeAccent,
            onTap: () {
              // TODO: chuyển sang trang khách sạn
            },
          ),
          _TravelItem(
            icon: Icons.tour,
            title: getTranslated('tour', context) ?? 'Tour du lịch',
            color: Colors.lightBlueAccent,
            onTap: () {
              // TODO: chuyển sang trang tour
            },
          ),
        ],
      ),
    );
  }
}

class _TravelItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _TravelItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              Positioned(
                top: -10,
                right: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 80,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
