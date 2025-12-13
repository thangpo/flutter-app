import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/traveloka_side_menu.dart';


class MenuWidget extends StatelessWidget {
  const MenuWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeController>(context).darkTheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();

        Navigator.of(context).push(PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black54,
          pageBuilder: (_, __, ___) => const TravelokaSideMenu(),
          transitionsBuilder: (context, animation, secondary, child) {
            final offset = Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));
            return SlideTransition(position: offset, child: child);
          },
        ));
      },
      child: Icon(
        Icons.menu_rounded,
        size: 28,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }
}