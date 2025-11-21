import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/screens/cart_screen.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/screens/inbox_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/screens/order_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/coupon/screens/coupon_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/screens/wallet_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/screens/profile_screen1.dart';
import 'package:flutter_sixvalley_ecommerce/features/setting/screens/settings_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/wishlist/screens/wishlist_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/screens/address_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/wishlist/controllers/wishlist_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/banner/screens/offers_product_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/loyaltyPoint/screens/loyalty_point_screen.dart';




class MenuWidget extends StatefulWidget {
  const MenuWidget({super.key});

  @override
  State<MenuWidget> createState() => _MenuWidgetState();
}

class _MenuWidgetState extends State<MenuWidget> with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  bool _isMenuOpen = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutExpo,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
  }

  void _showMenu() {
    HapticFeedback.mediumImpact();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isMenuOpen = true;
    });
    _animationController.forward();
  }

  void _hideMenu() {
    HapticFeedback.lightImpact();
    _animationController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() {
        _isMenuOpen = false;
      });
    });
  }

  OverlayEntry _createOverlayEntry() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final menuWidth = screenWidth * 0.82;

    return OverlayEntry(
      builder: (context) => Consumer2<ProfileController, ThemeController>(
        builder: (context, profileProvider, themeController, _) {
          final bool isDark = themeController.darkTheme;
          final bool isGuestMode = !Provider.of<AuthController>(context, listen: false).isLoggedIn();
          final ConfigModel? configModel = Provider.of<SplashController>(context, listen: false).configModel;
          final LiquidGlassSettings mainPanelSettings = isDark
              ? const LiquidGlassSettings(
            blur: 16,
            thickness: 20,
            refractiveIndex: 1.28,
            lightAngle: 0.5 * pi,
            lightIntensity: 1.8,
            ambientStrength: 0.4,
            saturation: 1.15,
            glassColor: Color(0x1AFFFFFF),
          )
              : const LiquidGlassSettings(
            blur: 14,
            thickness: 18,
            refractiveIndex: 1.25,
            lightAngle: 0.5 * pi,
            lightIntensity: 1.5,
            ambientStrength: 0.35,
            saturation: 1.08,
            glassColor: Color(0x38FFFFFF),
          );

          final LiquidGlassSettings menuItemSettings = isDark
              ? const LiquidGlassSettings(
            blur: 10,
            thickness: 12,
            refractiveIndex: 1.22,
            lightAngle: 0.5 * pi,
            lightIntensity: 1.4,
            ambientStrength: 0.3,
            saturation: 1.05,
            glassColor: Color(0x14FFFFFF),
          )
              : const LiquidGlassSettings(
            blur: 10,
            thickness: 12,
            refractiveIndex: 1.25,
            lightAngle: 0.5 * pi,
            lightIntensity: 1.2,
            ambientStrength: 0.35,
            saturation: 1.05,
            glassColor: Color(0xD9FFFFFF),
          );

          final List<Map<String, dynamic>> menuItems = [
            {
              'title': getTranslated('notifications', context),
              'icon': Images.notification,
              'navigateTo': const InboxScreen(isBackButtonExist: false),
              'iconData': Icons.notifications_rounded,
            },
            {
              'title': getTranslated('profile', context),
              'icon': Images.user,
              'navigateTo': const ProfileScreen1(),
              'iconData': Icons.person_rounded,
            },
            {
              'title': getTranslated('addresses', context),
              'icon': Images.address,
              'navigateTo': const AddressListScreen(),
              'iconData': Icons.location_on_rounded,
            },
            {
              'title': getTranslated('coupons', context),
              'icon': Images.coupon,
              'navigateTo': const CouponList(),
              'iconData': Icons.local_offer_rounded,
            },
            {
              'title': getTranslated('settings', context),
              'icon': Images.settings,
              'navigateTo': const SettingsScreen(),
              'iconData': Icons.settings_rounded,
            },
            {
              'title': getTranslated('offers', context),
              'icon': Images.offerIcon,
              'navigateTo': const OfferProductListScreen(),
              'count': 0,
              'hasCount': false,
              'iconData': Icons.local_fire_department_rounded,
            },
            if (!isGuestMode && configModel?.walletStatus == 1)
              {
                'title': getTranslated('wallet', context),
                'icon': Images.wallet,
                'navigateTo': const WalletScreen(),
                'count': 1,
                'hasCount': false,
                'isWallet': true,
                'subTitle': 'amount',
                'balance': profileProvider.balance ?? 0,
                'iconData': Icons.account_balance_wallet_rounded,
              },
            if (!isGuestMode && configModel?.loyaltyPointStatus == 1)
              {
                'title': getTranslated('loyalty_point', context),
                'icon': Images.loyaltyPoint,
                'navigateTo': const LoyaltyPointScreen(),
                'count': 1,
                'hasCount': false,
                'isWallet': true,
                'subTitle': 'point',
                'balance': profileProvider.loyaltyPoint ?? 0,
                'isLoyalty': true,
                'iconData': Icons.stars_rounded,
              },
            if (!isGuestMode)
              {
                'title': getTranslated('orders', context),
                'icon': Images.shoppingImage,
                'navigateTo': const OrderScreen(),
                'count': profileProvider.userInfoModel?.totalOrder ?? 0,
                'hasCount': (profileProvider.userInfoModel?.totalOrder ?? 0) > 0,
                'iconData': Icons.shopping_bag_rounded,
              },
            {
              'title': getTranslated('cart', context),
              'icon': Images.cartImage,
              'navigateTo': const CartScreen(),
              'count': Provider.of<CartController>(context, listen: false).cartList.length,
              'hasCount': true,
              'iconData': Icons.shopping_cart_rounded,
            },
            {
              'title': getTranslated('wishlist', context),
              'icon': Images.wishlist,
              'navigateTo': const WishListScreen(),
              'count': Provider.of<WishListController>(context, listen: false).wishList?.length ?? 0,
              'hasCount': !isGuestMode && (Provider.of<WishListController>(context, listen: false).wishList?.length ?? 0) > 0,
              'iconData': Icons.favorite_rounded,
            },
          ];

          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return LiquidGlassLayer(
                useBackdropGroup: true,
                settings: mainPanelSettings,
                child: Stack(
                  children: [
                    Positioned(
                      right: -(menuWidth * _slideAnimation.value),
                      top: 0,
                      width: menuWidth,
                      height: screenHeight,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        alignment: Alignment.centerRight,
                        child: LiquidStretch(
                          child: LiquidGlass(
                            shape: const LiquidRoundedSuperellipse(
                              borderRadius: 32,
                            ),
                            clipBehavior: Clip.antiAlias,
                            glassContainsChild: false,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isDark
                                      ? [
                                    Colors.black.withOpacity(0.45),
                                    Colors.grey[900]!.withOpacity(0.60),
                                  ]
                                      : [
                                    Colors.white.withOpacity(0.70),
                                    Colors.grey[100]!.withOpacity(0.80),
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(32),
                                  bottomLeft: Radius.circular(32),
                                ),
                              ),
                              child: SafeArea(
                                child: Column(
                                  children: [
                                    _buildHeader(isDark),
                                    Expanded(
                                      child: ListView.builder(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        itemCount: menuItems.length,
                                        physics: const BouncingScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          return _buildAnimatedMenuItem(
                                            context,
                                            menuItems[index],
                                            isDark,
                                            index,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return GlassGlow(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Menu',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            GestureDetector(
              onTap: _hideMenu,
              child: LiquidStretch(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.close_rounded,
                    size: 22,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedMenuItem(
      BuildContext context,
      Map<String, dynamic> item,
      bool isDark,
      int index,
      ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 40)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: LiquidStretch(
          child: GlassGlow(
            glowColor: isDark ? Colors.blue[300]! : Colors.blue[500]!,
            child: LiquidGlassBlendGroup(
              child: LiquidGlass.grouped(
                shape: const LiquidRoundedSuperellipse(
                  borderRadius: 16,
                ),
                clipBehavior: Clip.antiAlias,
                glassContainsChild: false,
                child: _buildMenuItemRow(
                  context,
                  item: item,
                  isDark: isDark,
                  index: index,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItemRow(
      BuildContext context, {
        required Map<String, dynamic> item,
        required bool isDark,
        required int index,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          _hideMenu();
          Future.delayed(const Duration(milliseconds: 200), () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                item['navigateTo'],
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                      Colors.blue[400]!.withOpacity(0.25),
                      Colors.blue[600]!.withOpacity(0.15),
                    ]
                        : [
                      Colors.blue[50]!,
                      Colors.blue[100]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  item['iconData'],
                  size: 24,
                  color: isDark ? Colors.blue[300] : Colors.blue[700],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (item['subTitle'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${item['subTitle']}: ${item['balance']}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              if (item['hasCount'] == true && item['count'] > 0)
                Container(
                  constraints: const BoxConstraints(minWidth: 28),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue[600]!,
                        Colors.blue[400]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    item['count'].toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_isMenuOpen) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeController>(context);
    final isDark = theme.darkTheme;

    return GestureDetector(
      onTap: () {
        if (_isMenuOpen) {
          _hideMenu();
        } else {
          _showMenu();
        }
      },
      child: LiquidStretch(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _isMenuOpen ? Icons.close_rounded : Icons.menu_rounded,
            size: 24,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}