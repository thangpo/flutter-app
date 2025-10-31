import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/styles.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/screens/flight_booking_screen.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/screens/tour_list_screen.dart';

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
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        ),
      );

      final radiusAnimation = Tween<double>(
        begin: 100.0,
        end: 0.0,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
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
                borderRadius: BorderRadius.circular(radiusAnimation.value),
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

    _fadeAnimations = List.generate(3, (index) {
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

    _slideAnimations = List.generate(3, (index) {
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
    final themeController = Provider.of<ThemeController>(context, listen: false);
    final bool darkTheme = themeController.darkTheme;

    final Color bgColor = darkTheme ? Colors.grey[850]! : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAnimatedItem(
            context: context,
            index: 0,
            icon: Icons.flight_takeoff,
            title: getTranslated('flight', context) ?? 'Đặt vé máy bay',
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFFFFC371)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
            index: 1,
            icon: Icons.hotel,
            title: getTranslated('hotel', context) ?? 'Đặt khách sạn',
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9A56), Color(0xFFFFD15C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: (position) {
              // TODO: chuyển sang trang khách sạn với hiệu ứng iOS
            },
          ),
          _buildAnimatedItem(
            context: context,
            index: 2,
            icon: Icons.tour,
            title: getTranslated('tour', context) ?? 'Tour du lịch',
            gradient: const LinearGradient(
              colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
    required Gradient gradient,
    required Function(Offset) onTap,
  }) {
    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(
        position: _slideAnimations[index],
        child: _TravelItem(
          icon: icon,
          title: title,
          gradient: gradient,
          onTap: onTap,
        ),
      ),
    );
  }
}

class _TravelItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final Gradient gradient;
  final Function(Offset) onTap;

  const _TravelItem({
    required this.icon,
    required this.title,
    required this.gradient,
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
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
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
    _buttonKey.currentContext?.findRenderObject() as RenderBox?;
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
    return GestureDetector(
      onTapDown: (_) => _rippleController.forward(),
      onTapUp: (_) {
        _rippleController.reverse();
        widget.onTap(_getButtonPosition());
      },
      onTapCancel: () => _rippleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          key: _buttonKey,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: widget.gradient.colors.first.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 12,
                  right: 12,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 85,
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}