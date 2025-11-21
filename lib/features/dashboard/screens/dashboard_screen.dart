import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/screens/cart_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/controllers/chat_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/models/navigation_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/widgets/dashboard_menu_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/deal/controllers/flash_deal_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/restock/controllers/restock_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/controllers/search_product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/wishlist/controllers/wishlist_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/network_info.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/app_globals.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/widgets/app_exit_card_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/screens/inbox_screen.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/screens/aster_theme_home_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/screens/fashion_theme_home_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/screens/home_screens.dart';
import 'package:flutter_sixvalley_ecommerce/features/more/screens/more_screen_view.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/screens/order_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/main_home/screens/main_home_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/friends_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_notifications_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/notifications_screen.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/screens/travel_screen.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:flutter/cupertino.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});
  @override
  DashBoardScreenState createState() => DashBoardScreenState();
}

class DashBoardScreenState extends State<DashBoardScreen> {
  int _pageIndex = 1;
  late List<NavigationModel> _screens;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey();
  final PageStorageBucket bucket = PageStorageBucket();
  final GlobalKey<SocialFeedScreenState> _socialFeedKey =
      GlobalKey<SocialFeedScreenState>();
  int? _socialTabIndex;
  bool _showBottomNav = true;

  bool singleVendor = false;

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
    singleVendor = splashController.configModel?.businessMode == "single";
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

      // NavigationModel(
      //   name: 'friends',
      //   icon: Images.friendImage,
      //   screen: const FriendsScreen(),
      // ),
      // NavigationModel(
      //     name: 'friends',
      //     icon: Images.friendImage,
      //     screen: const InboxScreen(isBackButtonExist: false)),

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
          screen: const NotificationsScreen(isBackButtonExist: false)),

      // NavigationModel(name: 'inbox', icon: Images.messageImage, screen: const InboxScreen(isBackButtonExist: false)),
      // NavigationModel(name: 'cart', icon: Images.cartArrowDownImage, screen: const CartScreen(showBackButton: false), showCartIcon: true),
      // NavigationModel(name: 'orders', icon: Images.shoppingImage, screen:  const OrderScreen(isBacButtonExist: false)),
      NavigationModel(
          name: 'more', icon: Images.moreImage, screen: const MoreScreen()),
    ];

    _socialTabIndex =
        _screens.indexWhere((element) => element.name == 'social');

    NetworkInfo.checkConnectivity(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bool isDarkTheme = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    // Chiß╗üu cao cß╗æ ─æß╗ïnh cß╗ºa thanh nav
    const double navHeight = 60;

    // Phß║ºn lß╗ü ph├¡a d╞░ß╗¢i do hß╗ç thß╗æng (thanh gesture / 3 n├║t ─æiß╗üu h╞░ß╗¢ng)
    final double bottomInset = mediaQuery.viewPadding.bottom;

    // ≡ƒæë m├áu nß╗ün ph├¡a sau dashboard ─æß╗â quyß║┐t ─æß╗ïnh s├íng / tß╗æi
    final Color behindColor = theme.scaffoldBackgroundColor;
    final bool isBehindDark = behindColor.computeLuminance() < 0.5;

    // ≡ƒö╣ Glass settings cho bottom bar
    final LiquidGlassSettings bottomGlassSettings = isBehindDark
        ? const LiquidGlassSettings(
            // nß╗ün tß╗æi -> k├¡nh s├íng
            blur: 6,
            thickness: 18,
            refractiveIndex: 1.25,
            lightAngle: 0.5 * pi,
            lightIntensity: 1.1,
            ambientStrength: 0.35,
            saturation: 1.06,
            glassColor: Color(0x22FFFFFF),
          )
        : const LiquidGlassSettings(
            // nß╗ün s├íng -> k├¡nh h╞íi tß╗æi
            blur: 6,
            thickness: 18,
            refractiveIndex: 1.25,
            lightAngle: 0.5 * pi,
            lightIntensity: 1.0,
            ambientStrength: 0.35,
            saturation: 1.02,
            glassColor: Color(0x22000000),
          );

    final Color bottomBorderColor = isBehindDark
        ? Colors.white.withOpacity(0.70)
        : Colors.white.withOpacity(0.45);

    final Color bottomFillColor = isBehindDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.05);
    final bool hideNav = (_socialTabIndex != null &&
        _pageIndex == _socialTabIndex &&
        !_showBottomNav);
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
                    builder: (_) => const AppExitCard());
              }
            }
          }
          return;
        },
        child: Scaffold(
          extendBody: true,
          key: _scaffoldKey,
          body: PageStorage(
            bucket: bucket,
            child: _screens[_pageIndex].screen,
          ),
          bottomNavigationBar: AnimatedSlide(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            offset: hideNav ? const Offset(0, 1.2) : Offset.zero,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: hideNav ? 0 : 1,
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, max(8, bottomInset)),
                child: LiquidGlassLayer(
                  useBackdropGroup: true,
                  settings: bottomGlassSettings,
                  child: LiquidGlass(
                    shape: const LiquidRoundedSuperellipse(borderRadius: 28),
                    clipBehavior: Clip.antiAlias,
                    glassContainsChild: false,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: bottomBorderColor,
                          width: 1.4,
                        ),
                        color: bottomFillColor,
                      ),
                      child: SizedBox(
                        height: navHeight,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: _getBottomWidget(singleVendor),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  void _setPage(int pageIndex) {
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

  List<Widget> _getBottomWidget(bool isSingleVendor) {
    List<Widget> list = [];
    for (int index = 0; index < _screens.length; index++) {
      final item = _screens[index];

      // ≡ƒƒó Nß║┐u l├á tab Th├┤ng b├ío ΓåÆ hiß╗ân thß╗ï chß║Ñm ─æß╗Å khi c├│ th├┤ng b├ío ch╞░a ─æß╗ìc
      if (item.name == 'notifications') {
        list.add(
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomMenuWidget(
                  isSelected: _pageIndex == index,
                  name: item.name,
                  icon: item.icon,
                  showCartCount: item.showCartIcon ?? false,
                  onTap: () => _handleNavigationTap(item, index),
                ),
                // ≡ƒö┤ Chß║Ñm ─æß╗Å (d├╣ng Selector ─æß╗â tr├ính rebuild to├án bß╗Ö)
                Selector<SocialNotificationsController, bool>(
                  selector: (_, ctrl) =>
                      ctrl.notifications.any((n) => n.seen == "0"),
                  builder: (_, hasUnread, __) {
                    if (!hasUnread) return const SizedBox.shrink();
                    return Positioned(
                      top: 6,
                      right: MediaQuery.of(context).size.width / 12 - 10,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      } else {
        // ≡ƒö╣ C├íc tab kh├íc giß╗» nguy├¬n
        list.add(
          Expanded(
            child: CustomMenuWidget(
              isSelected: _pageIndex == index,
              name: item.name,
              icon: item.icon,
              showCartCount: item.showCartIcon ?? false,
              onTap: () => _handleNavigationTap(item, index),
            ),
          ),
        );
      }
    }

    return list;
  }
}
