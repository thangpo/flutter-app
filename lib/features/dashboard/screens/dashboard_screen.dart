import 'dart:io' show Platform;

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

    // iOS destinations (giữ nguyên)
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

    // Android nav items (icon + label + badge)
    final List<_AndroidNavItem> androidItems = [
      _AndroidNavItem(
        icon: Icons.home_outlined,
        label: t('home'),
      ),
      _AndroidNavItem(
        icon: Icons.chat_bubble_outline,
        label: t('social'),
      ),
      _AndroidNavItem(
        icon: Icons.event_note_outlined,
        label: t('travel'),
      ),
      _AndroidNavItem(
        icon: Icons.medication_outlined,
        label: t('shop'),
      ),
      _AndroidNavItem(
        icon: Icons.monitor_heart_outlined,
        label: t('notifications'),
        badgeCount: unreadNotifications,
      ),
      _AndroidNavItem(
        icon: Icons.more_horiz,
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
        // iOS dùng bottom bar native
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
        // Android: overlay bottom bar custom giống ảnh
        body: isIOSPlatform
            ? PageStorage(
          key: ValueKey<int>(_pageIndex),
          bucket: bucket,
          child: _screens[_pageIndex].screen,
        )
            : Stack(
          children: [
            PageStorage(
              key: ValueKey<int>(_pageIndex),
              bucket: bucket,
              child: _screens[_pageIndex].screen,
            ),
            if (!hideNav)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AndroidCurvedBottomBar(
                  items: androidItems,
                  currentIndex: _pageIndex,
                  onTap: (index) =>
                      _handleNavigationTap(_screens[index], index),
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

// ------------------------------------------------------------------
// Android bottom bar giống ảnh: thanh xám bo góc + avatar tròn chọc vào
// ------------------------------------------------------------------

class _AndroidNavItem {
  final IconData icon;
  final String label;
  final int badgeCount;

  _AndroidNavItem({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
  });
}

class AndroidCurvedBottomBar extends StatelessWidget {
  final List<_AndroidNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AndroidCurvedBottomBar({
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

    final Color barColor = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFF2F3F7); // xám nhạt như ảnh

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Thanh bottom bar
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(
                  items.length,
                      (index) => Expanded(
                    child: _AndroidNavItemWidget(
                      item: items[index],
                      selected: index == currentIndex,
                      onTap: () => onTap(index),
                    ),
                  ),
                ),
              ),
            ),
            // Nút tròn chọc vào thanh (avatar / quick action)
            Positioned(
              left: 18,
              top: -18,
              child: Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3A3A3C)
                      : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person,
                  color:
                  isDark ? cs.onSurface : cs.primary.withOpacity(0.9),
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AndroidNavItemWidget extends StatelessWidget {
  final _AndroidNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _AndroidNavItemWidget({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final Color iconColor =
    selected ? cs.primary : cs.onSurface.withOpacity(0.7);
    final FontWeight labelWeight =
    selected ? FontWeight.w600 : FontWeight.w400;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  item.icon,
                  size: 22,
                  color: iconColor,
                ),
                if (item.badgeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Center(
                        child: Text(
                          item.badgeCount > 9
                              ? '9+'
                              : item.badgeCount.toString(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: labelWeight,
                color: cs.onSurface.withOpacity(selected ? 0.9 : 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}