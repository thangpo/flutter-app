import 'dart:developer' as developer;
import 'dart:math';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
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
  int _previousPageIndex = 1;
  int? _draggingIndex;
  bool _isDragging = false;
  // Hu?ng chuy?n tab: -1 = sang trái, 1 = sang ph?i, 0 = không anim
  int _pageDirection = 0;
  late List<NavigationModel> _screens;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey();
  final PageStorageBucket bucket = PageStorageBucket();
  final GlobalKey<SocialFeedScreenState> _socialFeedKey =
      GlobalKey<SocialFeedScreenState>();
  int? _socialTabIndex;
  bool _showBottomNav = true;

  bool singleVendor = false;
  bool? _navBehindDark;
  bool _samplingNav = false;
  double _lastNavSampleOffset = 0.0;
  DateTime _lastNavSampleTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const String _navLogName = "DashboardNav";
  final GlobalKey _dashboardRepaintKey = GlobalKey();

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _sampleNavBackground());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navBehindDark ??=
        Theme.of(context).brightness == Brightness.dark; // default theo theme
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    if (_navBehindDark == null) {
      // Kích ho?t sample ? frame d?u n?u chua có d? li?u
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _sampleNavBackground());
    }

    // Nen phia sau dashboard quyet dinh sang/toi
    final Color behindColor = theme.scaffoldBackgroundColor;
    final bool navBehindDark = _navBehindDark ??
        ((theme.brightness == Brightness.dark)
            ? true
            : behindColor.computeLuminance() < 0.5);

    // Kich thuoc/nav inset
    const double navHeight = 60;
    final double bottomInset = mediaQuery.viewPadding.bottom;

    // Glass settings cho bottom bar
    final LiquidGlassSettings bottomGlassSettings = navBehindDark
        ? const LiquidGlassSettings(
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
            blur: 6,
            thickness: 18,
            refractiveIndex: 1.25,
            lightAngle: 0.5 * pi,
            lightIntensity: 1.0,
            ambientStrength: 0.35,
            saturation: 1.02,
            glassColor: Color(0x22000000),
          );

    final Color bottomBorderColor = navBehindDark
        ? Colors.white.withOpacity(0.70)
        : Colors.white.withOpacity(0.45);

    final Color bottomFillColor = navBehindDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.05);
    // Icon/text: inactive theo n?n (tr?ng/den), active luôn dùng primary
    final Color navInactiveColor = navBehindDark
        ? Colors.white.withOpacity(0.9)
        : Colors.black.withOpacity(0.9);
    final Color navActiveColor = cs.primary;
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
          body: ColoredBox(
            color: theme.scaffoldBackgroundColor,
            child: Stack(
              children: [
                RepaintBoundary(
                  key: _dashboardRepaintKey,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _handleScrollNotification,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      reverseDuration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (currentChild, previousChildren) {
                        // Gi? previousChild l?i trong Stack d? out-animation mu?t
                        return Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      transitionBuilder: (child, animation) {
                        // N?u l?n d?u ho?c không xác d?nh hu?ng thì ch? fade
                        if (_pageDirection == 0) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        }

                        final offsetTween = Tween<Offset>(
                          begin: Offset(0.14 * _pageDirection * -1.0, 0),
                          end: Offset.zero,
                        );

                        final fade = CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutQuad,
                        );

                        return FadeTransition(
                          opacity: fade,
                          child: SlideTransition(
                            position: offsetTween.animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: PageStorage(
                        key: ValueKey<int>(_pageIndex),
                        bucket: bucket,
                        child: _screens[_pageIndex].screen,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    offset: hideNav ? const Offset(0, 1.2) : Offset.zero,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: hideNav ? 0 : 1,
                      child: IgnorePointer(
                        child: Container(
                          height: navHeight + 20,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0),
                                Colors.white,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double itemWidth =
                                constraints.maxWidth / _screens.length;
                            final int currentIndicatorIndex =
                                _draggingIndex ?? _pageIndex;
                            final int travelDistance =
                                (currentIndicatorIndex - _previousPageIndex).abs();
                            const double indicatorTop = 6;
                            final double baseWidth =
                                min(itemWidth * 1.40, itemWidth * 1.82);
                            final bool isEdgeTab =
                                _pageIndex == 0 || _pageIndex == _screens.length - 1;
                            // Thu nhỏ nhẹ ở tab rìa để không tràn quá xa ra ngoài
                            final double baseWidthFactor =
                                isEdgeTab ? 0.78 : 1.0;
                            final double sweepBonus = travelDistance > 0
                                ? min(itemWidth * (travelDistance - 0.2),
                                    itemWidth * 0.9)
                                : 0;
                            final double indicatorWidth = min(
                              (baseWidth * baseWidthFactor) + sweepBonus,
                              itemWidth * (isEdgeTab ? 2.0 : 2.6),
                            );
                            final double indicatorLeft = max(
                              0,
                              (itemWidth * currentIndicatorIndex) +
                                  (itemWidth - indicatorWidth) / 2,
                            );
                            final bool useGlassIndicator =
                                !kIsWeb && Platform.isIOS;
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (_) {
                                setState(() {
                                  _isDragging = true;
                                  _draggingIndex = _pageIndex;
                                  _previousPageIndex = _pageIndex;
                                });
                              },
                              onPanUpdate: (details) => _handleNavDragUpdate(
                                details,
                                constraints.maxWidth,
                              ),
                              onPanEnd: (_) => _handleNavDragEnd(),
                              onPanCancel: () => _handleNavDragEnd(),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 420),
                                    curve: Curves.easeOutQuint,
                                    left: indicatorLeft,
                                    top: indicatorTop,
                                    child: IgnorePointer(
                                      ignoring: true,
                                      child: useGlassIndicator
                                          ? LiquidGlassLayer(
                                              settings: navBehindDark
                                                  ? const LiquidGlassSettings(
                                                      blur: 12,
                                                      thickness: 18,
                                                      refractiveIndex: 1.18,
                                                      lightAngle: 0.6 * pi,
                                                      lightIntensity: 1.1,
                                                      ambientStrength: 0.4,
                                                      saturation: 1.05,
                                                      glassColor:
                                                          Color(0x1AFFFFFF),
                                                    )
                                                  : const LiquidGlassSettings(
                                                      blur: 12,
                                                      thickness: 18,
                                                      refractiveIndex: 1.18,
                                                      lightAngle: 0.6 * pi,
                                                      lightIntensity: 1.0,
                                                      ambientStrength: 0.42,
                                                      saturation: 1.03,
                                                      glassColor:
                                                          Color(0x14000000),
                                                    ),
                                              child: LiquidGlass(
                                                shape:
                                                    const LiquidRoundedSuperellipse(
                                                        borderRadius: 28),
                                                glassContainsChild: false,
                                                clipBehavior: Clip.antiAlias,
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 420),
                                                  curve: Curves.easeOutQuint,
                                                  width: indicatorWidth,
                                                  height: navHeight -
                                                      (indicatorTop * 2),
                                                  decoration: BoxDecoration(
                                                    color: navBehindDark
                                                        ? Colors.white
                                                            .withOpacity(0.10)
                                                        : Colors.black
                                                            .withOpacity(0.04),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            28),
                                                    border: Border.all(
                                                      color: navBehindDark
                                                          ? Colors.white
                                                              .withOpacity(
                                                                  0.32)
                                                          : Colors.black
                                                              .withOpacity(
                                                                  0.16),
                                                      width: 1,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: navBehindDark
                                                            ? Colors.white
                                                                .withOpacity(
                                                                    0.18)
                                                            : Colors.black
                                                                .withOpacity(
                                                                    0.12),
                                                        blurRadius: 14,
                                                        spreadRadius: 1,
                                                        offset: const Offset(
                                                            0, 7),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            )
                                          : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(28),
                                              child: BackdropFilter(
                                                filter: ui.ImageFilter.blur(
                                                    sigmaX: 10, sigmaY: 10),
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 360),
                                                  curve: Curves.easeOutQuint,
                                                  width: indicatorWidth,
                                                  height: navHeight -
                                                      (indicatorTop * 2),
                                                  decoration: BoxDecoration(
                                                    color: navBehindDark
                                                        ? Colors.white
                                                            .withOpacity(0.12)
                                                        : Colors.black
                                                            .withOpacity(0.06),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            28),
                                                    border: Border.all(
                                                      color: navBehindDark
                                                          ? Colors.white
                                                              .withOpacity(
                                                                  0.22)
                                                          : Colors.black
                                                              .withOpacity(
                                                                  0.14),
                                                      width: 1,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: navBehindDark
                                                            ? Colors.white
                                                                .withOpacity(
                                                                    0.12)
                                                            : Colors.black
                                                                .withOpacity(
                                                                    0.10),
                                                        blurRadius: 12,
                                                        spreadRadius: 1,
                                                        offset: const Offset(
                                                            0, 6),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: _getBottomWidget(
                                      singleVendor,
                                      navActiveColor,
                                      navInactiveColor,
                                      usePillBackground: false,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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

  void _scheduleNavSample() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _sampleNavBackground());
  }

  Future<void> _sampleNavBackground() async {
    if (_samplingNav) {
      developer.log(
        'Skip nav sampling because previous run is in progress.',
        name: _navLogName,
      );
      return;
    }
    _samplingNav = true;
    try {
      final BuildContext? ctx = _dashboardRepaintKey.currentContext;
      if (ctx == null) {
        developer.log('Nav sample skipped: context is null.',
            name: _navLogName);
        return;
      }
      final RenderRepaintBoundary? boundary =
          ctx.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || boundary.debugNeedsPaint) {
        developer.log(
          'Nav boundary not ready (needsPaint=${boundary?.debugNeedsPaint ?? true}), retry next frame.',
          name: _navLogName,
        );
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _sampleNavBackground());
        return;
      }

      const double targetRatio = 0.2;
      final double pixelRatio =
          (targetRatio.clamp(0.05, 1.0) as num).toDouble();
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? data =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) {
        developer.log('Nav sampling failed: no pixel buffer.',
            name: _navLogName);
        image.dispose();
        return;
      }
      if (!mounted) {
        image.dispose();
        return;
      }

      const double navHeight = 60;
      final double bottomInset = MediaQuery.of(context).viewPadding.bottom;
      final double sampleHeight = navHeight + max(8, bottomInset) + 12;
      final int rows = max(
        1,
        min(image.height, (sampleHeight * pixelRatio).ceil()),
      );
      final int startRow = max(0, image.height - rows);
      final int width = image.width;
      final int height = image.height;

      double luminanceSum = 0;
      int count = 0;
      for (int y = startRow; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int offset = (y * width + x) * 4;
          final int r = data.getUint8(offset);
          final int g = data.getUint8(offset + 1);
          final int b = data.getUint8(offset + 2);
          luminanceSum += (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0;
          count++;
        }
      }
      image.dispose();
      if (count == 0 || !mounted) return;

      final double avgLum = luminanceSum / count;
      final bool navDark = avgLum < 0.42;
      final bool themeDark = Theme.of(context).brightness == Brightness.dark;
      final bool useDarkChrome = navDark || themeDark;
      developer.log(
        'Sampled nav bg -> avgLum=${avgLum.toStringAsFixed(3)}, behindDark=$navDark, icons=${useDarkChrome ? 'white' : 'black'} (pixelRatio=$pixelRatio, rows=$rows, size=${width}x$height).',
        name: _navLogName,
      );
      setState(() {
        _navBehindDark = navDark;
      });
    } catch (e, st) {
      developer.log(
        'Nav sampling failed: $e',
        name: _navLogName,
        error: e,
        stackTrace: st,
      );
    } finally {
      _samplingNav = false;
    }
  }

  bool _handleScrollNotification(ScrollNotification n) {
    if (!_showBottomNav) return false;
    final double offset = n.metrics.pixels;
    const double offsetThreshold = 28.0;
    const int timeMs = 140;
    final DateTime now = DateTime.now();
    final bool movedFar =
        (offset - _lastNavSampleOffset).abs() >= offsetThreshold;
    final bool enoughTime =
        now.difference(_lastNavSampleTime).inMilliseconds >= timeMs;
    if (movedFar || enoughTime) {
      _lastNavSampleOffset = offset;
      _lastNavSampleTime = now;
      developer.log(
        'Re-sample nav on scroll (offset=${offset.toStringAsFixed(1)}).',
        name: _navLogName,
      );
      _scheduleNavSample();
    }
    return false;
  }

  void _setPage(int pageIndex) {
    // N?u b?m l?i cùng tab thì thôi, tránh trigger animation
    if (pageIndex == _pageIndex) {
      return;
    }

    setState(() {
      _previousPageIndex = _pageIndex;
      _draggingIndex = null;
      _isDragging = false;
      // Xác d?nh hu?ng d? làm slide trái/ph?i gi?ng iOS
      if (pageIndex > _pageIndex) {
        _pageDirection = 1;
      } else if (pageIndex < _pageIndex) {
        _pageDirection = -1;
      } else {
        _pageDirection = 0;
      }

      _pageIndex = pageIndex;

      if (_socialTabIndex != null && pageIndex != _socialTabIndex) {
        _showBottomNav = true;
      }
    });

    _scheduleNavSample();

    // Co giãn pill rồi thu hẹp lại sau frame để chỉ quét khi di chuyển xa
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_pageIndex != pageIndex) return;
      setState(() {
      _previousPageIndex = _pageIndex;
      _draggingIndex = null;
      _isDragging = false;
      });
    });
  }

  void _handleChromeVisibilityChanged(bool visible) {
    if (_pageIndex != _socialTabIndex) return;
    if (_showBottomNav == visible) return;
    setState(() {
      _showBottomNav = visible;
    });
    if (visible) _scheduleNavSample();
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

  void _handleNavDragUpdate(DragUpdateDetails details, double maxWidth) {
    final double dx = details.localPosition.dx.clamp(0, maxWidth - 0.01);
    final double itemWidth = maxWidth / _screens.length;
    final int targetIndex = (dx / itemWidth).floor().clamp(0, _screens.length - 1);
    if (targetIndex != _draggingIndex) {
      setState(() {
        _draggingIndex = targetIndex;
      });
    }
  }

  void _handleNavDragEnd() {
    final int? target = _draggingIndex;
    setState(() {
      _isDragging = false;
      _draggingIndex = null;
    });
    if (target != null && target != _pageIndex) {
      _setPage(target);
    }
  }

  List<Widget> _getBottomWidget(
    bool isSingleVendor,
    Color activeColor,
    Color inactiveColor, {
    bool usePillBackground = true,
  }) {
    final int currentIndicatorIndex = _draggingIndex ?? _pageIndex;
    List<Widget> list = [];
    for (int index = 0; index < _screens.length; index++) {
      final item = _screens[index];

      // =ƒƒó Nß¦+u l+á tab Th+¦ng b+ío GåÆ hiß+ân thß+ï chß¦Ñm -æß+Å khi c+¦ th+¦ng b+ío ch¦¦a -æß+ìc
      if (item.name == 'notifications') {
        list.add(
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomMenuWidget(
                  isSelected: currentIndicatorIndex == index,
                  name: item.name,
                  icon: item.icon,
                  showCartCount: item.showCartIcon ?? false,
                  activeColorOverride: activeColor,
                  inactiveColorOverride: inactiveColor,
                  usePillBackground: usePillBackground,
                  onTap: () => _handleNavigationTap(item, index),
                ),
                // =ƒö¦ Chß¦Ñm -æß+Å (d+¦ng Selector -æß+â tr+ính rebuild to+án bß+Ö)
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
        // =ƒö¦ C+íc tab kh+íc giß+» nguy+¬n
        list.add(
          Expanded(
            child: CustomMenuWidget(
              isSelected: currentIndicatorIndex == index,
              name: item.name,
              icon: item.icon,
              showCartCount: item.showCartIcon ?? false,
              activeColorOverride: activeColor,
              inactiveColorOverride: inactiveColor,
              usePillBackground: usePillBackground,
              onTap: () => _handleNavigationTap(item, index),
            ),
          ),
        );
      }
    }

    return list;
  }
}


