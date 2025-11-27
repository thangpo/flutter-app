import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/controllers/chat_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/models/navigation_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/deal/controllers/flash_deal_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/restock/controllers/restock_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/controllers/search_product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/wishlist/controllers/wishlist_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/network_info.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/app_globals.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/widgets/app_exit_card_widget.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/screens/aster_theme_home_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/screens/fashion_theme_home_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/screens/home_screens.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/more/screens/more_screen_view.dart';
import 'package:flutter_sixvalley_ecommerce/features/main_home/screens/main_home_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_notifications_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/notifications_screen.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/screens/travel_screen.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});

  @override
  DashBoardScreenState createState() => DashBoardScreenState();
}

class DashBoardScreenState extends State<DashBoardScreen> {
  int _pageIndex = 1;
  late List<NavigationModel> _screens;
  final PageStorageBucket bucket = PageStorageBucket();
  final GlobalKey<SocialFeedScreenState> _socialFeedKey =
  GlobalKey<SocialFeedScreenState>();
  int? _socialTabIndex;
  bool _showBottomNav = true;

  @override
  void initState() {
    super.initState();

    Provider.of<FlashDealController>(context, listen: false)
        .getFlashDealList(true, true);
    Provider.of<SplashController>(context, listen: false)
        .getBusinessPagesList('default');
    Provider.of<SplashController>(context, listen: false)
        .getBusinessPagesList('pages');

    if (Provider.of<AuthController>(context, listen: false).isLoggedIn()) {
      Provider.of<CartController>(context, listen: false).mergeGuestCart();
      Provider.of<WishListController>(context, listen: false).getWishList();
      Provider.of<ChatController>(context, listen: false)
          .getChatList(1, reload: false, userType: 0);
      Provider.of<ChatController>(context, listen: false)
          .getChatList(1, reload: false, userType: 1);
      Provider.of<RestockController>(context, listen: false)
          .getRestockProductList(1, getAll: true);
    }

    final SplashController splashController =
    Provider.of<SplashController>(context, listen: false);

    Provider.of<SearchProductController>(context, listen: false)
        .getAuthorList(null);
    Provider.of<SearchProductController>(context, listen: false)
        .getPublishingHouseList(null);

    if (splashController.configModel!.activeTheme == "default") {
      HomePage.loadData(false);
    } else if (splashController.configModel!.activeTheme == "theme_aster") {
      AsterThemeHomeScreen.loadData(false);
    } else {
      FashionThemeHomePage.loadData(false);
    }

    _screens = [
      NavigationModel(
        name: 'home',
        icon: Images.homeImage,
        screen: const MainHomeScreen(),
      ),
      NavigationModel(
        name: 'travel',
        icon: Images.TravelIcon,
        screen: const TravelScreen(isBackButtonExist: false),
      ),
      NavigationModel(
        name: 'social',
        icon: Images.SocialIcon,
        screen: SocialFeedScreen(
          key: _socialFeedKey,
          onChromeVisibilityChanged: _handleChromeVisibilityChanged,
        ),
      ),
      NavigationModel(
        name: 'shop',
        icon: Images.storeIcon,
        screen: (splashController.configModel!.activeTheme == "default")
            ? const HomePage()
            : (splashController.configModel!.activeTheme == "theme_aster")
            ? const AsterThemeHomeScreen()
            : const FashionThemeHomePage(),
      ),
      NavigationModel(
        name: 'notifications',
        icon: Images.notification,
        screen: const NotificationsScreen(isBackButtonExist: false),
      ),
      NavigationModel(
        name: 'more',
        icon: Images.moreImage,
        screen: const MoreScreen(),
      ),
    ];

    _socialTabIndex =
        _screens.indexWhere((element) => element.name == 'social');

    NetworkInfo.checkConnectivity(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final bool isIOSPlatform = !kIsWeb && Platform.isIOS;

    final bool hideNav = (_socialTabIndex != null &&
        _pageIndex == _socialTabIndex &&
        !_showBottomNav);

    final int unreadNotifications =
    context.select<SocialNotificationsController, int>(
          (ctrl) => ctrl.notifications.where((n) => n.seen == "0").length,
    );

    String t(String key) => getTranslated(key, context) ?? key;

    Color navActiveColor = cs.primary;
    if (isIOSPlatform && platformBrightness == Brightness.dark) {
      navActiveColor = _boostLightness(navActiveColor, 0.20);
    }

    // iOS destinations
    final List<AdaptiveNavigationDestination> iosDestinations = [
      AdaptiveNavigationDestination(
        icon: 'house.fill',
        selectedIcon: 'house',
        label: t('home'),
      ),
      AdaptiveNavigationDestination(
        icon: 'map.fill',
        selectedIcon: 'airplane',
        label: t('travel'),
      ),
      AdaptiveNavigationDestination(
        icon: 'globe.fill',
        selectedIcon: 'person.2.fill',
        label: t('social'),
      ),
      AdaptiveNavigationDestination(
        icon: 'basket.fill',
        selectedIcon: 'bag.fill',
        label: t('shop'),
      ),
      AdaptiveNavigationDestination(
        icon: 'bell.fill',
        selectedIcon: 'bell.fill',
        label: t('notifications'),
        badgeCount: unreadNotifications > 0 ? unreadNotifications : null,
      ),
      AdaptiveNavigationDestination(
        icon: 'ellipsis.circle.fill',
        selectedIcon: 'ellipsis.circle.fill',
        label: t('more'),
      ),
    ];

    // Android neumorphic items
    final List<NeuBottomItem> androidItems = [
      NeuBottomItem(
        icon: Icons.home_rounded,
        label: t('home'),
      ),
      NeuBottomItem(
        icon: Icons.travel_explore_rounded,
        label: t('travel'),
      ),
      NeuBottomItem(
        icon: Icons.public_rounded,
        label: t('social'),
      ),
      NeuBottomItem(
        icon: Icons.storefront_rounded,
        label: t('shop'),
      ),
      NeuBottomItem(
        icon: Icons.notifications_rounded,
        label: t('notifications'),
        badgeCount: unreadNotifications,
      ),
      NeuBottomItem(
        icon: Icons.more_horiz_rounded,
        label: t('more'),
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (_pageIndex != 0) {
          _setPage(0);
          return;
        } else {
          await Future.delayed(const Duration(milliseconds: 150));
          if (context.mounted) {
            if (!Navigator.of(context).canPop()) {
              showModalBottomSheet(
                backgroundColor: Colors.transparent,
                context: Get.context!,
                builder: (_) => const AppExitCard(),
              );
            }
          }
        }
        return;
      },
      child: AdaptiveScaffold(
        minimizeBehavior: TabBarMinimizeBehavior.never,
        enableBlur: isIOSPlatform,
        bottomNavigationBar: (hideNav || !isIOSPlatform)
            ? null
            : AdaptiveBottomNavigationBar(
          items: iosDestinations,
          selectedIndex: _pageIndex,
          onTap: (index) => _handleNavigationTap(
            _screens[index],
            index,
          ),
          useNativeBottomBar: true,
          selectedItemColor: navActiveColor,
        ),
        body: Stack(
          children: [
            PageStorage(
              key: ValueKey<int>(_pageIndex),
              bucket: bucket,
              child: _screens[_pageIndex].screen,
            ),
            // Android: overlay thanh neumorphic
            if (!isIOSPlatform && !hideNav)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NeumorphicBottomNavBar(
                  items: androidItems,
                  currentIndex: _pageIndex,
                  onTap: (index) => _handleNavigationTap(
                    _screens[index],
                    index,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _setPage(int pageIndex) {
    if (pageIndex == _pageIndex) return;
    setState(() {
      _pageIndex = pageIndex;
      if (_socialTabIndex != null && pageIndex != _socialTabIndex) {
        _showBottomNav = true;
      }
    });
  }

  void _handleChromeVisibilityChanged(bool visible) {
    if (_pageIndex != _socialTabIndex) return;
    if (_showBottomNav == visible) return;
    setState(() {
      _showBottomNav = visible;
    });
  }

  void _handleNavigationTap(NavigationModel item, int index) {
    final bool isSocialTab =
        _socialTabIndex != null && index == _socialTabIndex;
    final bool isCurrent = _pageIndex == index;

    if (isSocialTab && isCurrent) {
      final SocialFeedScreenState? state = _socialFeedKey.currentState;
      if (state == null) return;

      if (!state.isAtTop) {
        state.scrollToTop();
      } else {
        state.refreshFeed();
      }
      return;
    }

    _setPage(index);
  }

  Color _boostLightness(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final double newLightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }
}

// ---------------- Neumorphic bottom bar for Android ----------------

class NeuBottomItem {
  final IconData icon;
  final String label;
  final int badgeCount;

  const NeuBottomItem({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
  });
}

class NeumorphicBottomNavBar extends StatelessWidget {
  final List<NeuBottomItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const NeumorphicBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Nền xám mờ bán trong suốt với blur effect
    final Color bgColor = isDark
        ? const Color(0xFF1C1C1E).withOpacity(0.85)
        : const Color(0xFFF5F7FA).withOpacity(0.88);

    // Shadow cho neumorphic effect
    final Color shadowDark = isDark
        ? Colors.black.withOpacity(0.6)
        : Colors.black.withOpacity(0.15);
    final Color shadowLight = isDark
        ? Colors.white.withOpacity(0.03)
        : Colors.white.withOpacity(0.95);

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 96,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.white.withOpacity(0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowDark,
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: shadowLight,
                    blurRadius: 16,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    items.length,
                        (index) => Flexible(
                      child: _NeuBottomNavItem(
                        item: items[index],
                        selected: index == currentIndex,
                        onTap: () => onTap(index),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NeuBottomNavItem extends StatefulWidget {
  final NeuBottomItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NeuBottomNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NeuBottomNavItem> createState() => _NeuBottomNavItemState();
}

class _NeuBottomNavItemState extends State<_NeuBottomNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Màu xanh dương (blue) làm màu điểm nhấn
    const Color blueAccent = Color(0xFF2196F3);
    const Color blueLight = Color(0xFF42A5F5);

    final Color iconColor = widget.selected
        ? Colors.white
        : (isDark ? cs.onSurface.withOpacity(0.6) : cs.onSurface.withOpacity(0.5));

    final Color labelColor = widget.selected
        ? (isDark ? blueLight : blueAccent)
        : cs.onSurface.withOpacity(0.65);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon container với hiệu ứng neumorphic và gradient
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                height: 49,
                width: 49,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: widget.selected
                      ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      blueAccent,
                      blueLight,
                    ],
                  )
                      : null,
                  color: widget.selected
                      ? null
                      : (isDark
                      ? const Color(0xFF2C2C2E).withOpacity(0.7)
                      : Colors.white.withOpacity(0.85)),
                  boxShadow: widget.selected
                      ? [
                    BoxShadow(
                      color: blueAccent.withOpacity(0.45),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                      : [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.4)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(2, 3),
                    ),
                    BoxShadow(
                      color: isDark
                          ? Colors.white.withOpacity(0.02)
                          : Colors.white.withOpacity(0.9),
                      blurRadius: 8,
                      offset: const Offset(-2, -2),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 250),
                        scale: widget.selected ? 1.1 : 0.95,
                        curve: Curves.easeOutBack,
                        child: Icon(
                          widget.item.icon,
                          size: 21,
                          color: iconColor,
                        ),
                      ),
                    ),
                    // Badge thông báo với hiệu ứng pulsing
                    if (widget.item.badgeCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: _PulsatingBadge(
                          count: widget.item.badgeCount,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              // Label với fixed height để không bị xuống dòng
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: widget.selected ? 10 : 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: widget.selected ? 1.0 : 0.0,
                  child: widget.selected
                      ? Text(
                    widget.item.label,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                      letterSpacing: 0.1,
                      height: 1.0,
                    ),
                  )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget badge với hiệu ứng pulsing
class _PulsatingBadge extends StatefulWidget {
  final int count;

  const _PulsatingBadge({required this.count});

  @override
  State<_PulsatingBadge> createState() => _PulsatingBadgeState();
}

class _PulsatingBadgeState extends State<_PulsatingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF1744),
              Color(0xFFF50057),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF1744).withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        constraints: const BoxConstraints(
          minWidth: 18,
          minHeight: 18,
        ),
        child: Center(
          child: Text(
            widget.count > 99 ? '99+' : widget.count.toString(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}