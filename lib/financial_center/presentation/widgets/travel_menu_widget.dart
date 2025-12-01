import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/utill/styles.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/screens/tour_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/screens/flight_booking_screen.dart';


class IOSAppLaunchPageRoute extends PageRouteBuilder {
  final Widget page;
  final Offset startPosition;

  IOSAppLaunchPageRoute({
    required this.page,
    required this.startPosition,
  }) : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder:
        (context, animation, secondaryAnimation, child) {
      final scaleAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.25, 0.1, 0.25, 1.0),
        ),
      );

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve:
          const Interval(0.0, 0.5, curve: Curves.easeOut),
        ),
      );

      final radiusAnimation = Tween<double>(
        begin: 100.0,
        end: 0.0,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve:
          const Interval(0.3, 1.0, curve: Curves.easeInOut),
        ),
      );

      return Stack(
        children: [
          FadeTransition(
            opacity: fadeAnimation,
            child: Container(color: Colors.black),
          ),
          ScaleTransition(
            scale: scaleAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                    radiusAnimation.value),
                child: child,
              ),
            ),
          ),
        ],
      );
    },
  );
}

class TravelMenuWidget extends StatefulWidget {
  const TravelMenuWidget({super.key});

  @override
  State<TravelMenuWidget> createState() => _TravelMenuWidgetState();
}

class _TravelMenuWidgetState extends State<TravelMenuWidget>
    with SingleTickerProviderStateMixin {
  static const int _itemCount = 3;

  late AnimationController _controller;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimations = List.generate(_itemCount, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.15,
            0.6 + (index * 0.15),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _slideAnimations = List.generate(_itemCount, (index) {
      return Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.15,
            0.6 + (index * 0.15),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<ThemeController>(context, listen: true).darkTheme;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAnimatedItem(
            context: context,
            index: 0,
            icon: Icons.hotel_rounded,
            title: getTranslated('hotel', context) ?? 'Hotels',
            subtitle: 'Deals',
            accentColor: const Color(0xFF7C6EFF),
            isDark: isDark,
            onTap: (position) {
              // TODO: chuyển sang màn khách sạn
            },
          ),
          _buildAnimatedItem(
            context: context,
            index: 1,
            icon: Icons.flight_takeoff_rounded,
            title: getTranslated('flight', context) ?? 'Flights',
            subtitle: 'Deals',
            accentColor: const Color(0xFF00C48C),
            isDark: isDark,
            onTap: (position) {
              Navigator.push(
                context,
                IOSAppLaunchPageRoute(
                  page: const FlightBookingScreen(),
                  startPosition: position,
                ),
              );
            },
          ),
          _buildAnimatedItem(
            context: context,
            index: 2,
            icon: Icons.tour_rounded,
            title: getTranslated('tour', context) ?? 'Tours',
            subtitle: 'Deals',
            accentColor: const Color(0xFF29B6F6),
            isDark: isDark,
            onTap: (position) {
              Navigator.push(
                context,
                IOSAppLaunchPageRoute(
                  page: const TourListScreen(),
                  startPosition: position,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required bool isDark,
    required Function(Offset) onTap,
  }) {
    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(
        position: _slideAnimations[index],
        child: _TravelItem(
          icon: icon,
          title: title,
          subtitle: subtitle,
          accentColor: accentColor,
          isDark: isDark,
          onTap: onTap,
        ),
      ),
    );
  }
}

class _TravelItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool isDark;
  final Function(Offset) onTap;

  const _TravelItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_TravelItem> createState() => _TravelItemState();
}

class _TravelItemState extends State<_TravelItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;
  final GlobalKey _buttonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 160),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  Offset _getButtonPosition() {
    final RenderBox? renderBox =
    _buttonKey.currentContext?.findRenderObject()
    as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      return Offset(
        position.dx + size.width / 2,
        position.dy + size.height / 2,
      );
    }
    return Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.isDark
        ? const Color(0xFF1E2230)
        : Colors.white;

    return GestureDetector(
      onTapDown: (_) => _rippleController.forward(),
      onTapUp: (_) {
        _rippleController.reverse();
        widget.onTap(_getButtonPosition());
      },
      onTapCancel: () => _rippleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          key: _buttonKey,
          width: 100,
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: widget.isDark
                ? []
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.accentColor.withOpacity(0.12),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark
                      ? Colors.white
                      : const Color(0xFF1D1D26),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeExtraSmall,
                  color: widget.isDark
                      ? Colors.white
                      : const Color(0xFF9E9EAE),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}