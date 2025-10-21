import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/screens/address_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/screens/cart_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/screens/inbox_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/coupon/screens/coupon_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/loyaltyPoint/screens/loyalty_point_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/screens/order_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/screens/profile_screen1.dart';
import 'package:flutter_sixvalley_ecommerce/features/setting/screens/settings_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/screens/wallet_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/wishlist/controllers/wishlist_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/wishlist/screens/wishlist_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/banner/screens/offers_product_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  void _showMenu() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isMenuOpen = true;
    });
    _animationController.forward();
  }

  void _hideMenu() {
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
    final menuWidth = screenWidth * 0.75;
    final topPadding = MediaQuery.of(context).padding.top;

    return OverlayEntry(
      builder: (context) => Consumer<ProfileController>(
        builder: (context, profileProvider, _) {
          final bool isGuestMode = !Provider.of<AuthController>(context, listen: false).isLoggedIn();
          final ConfigModel? configModel = Provider.of<SplashController>(context, listen: false).configModel;

          final List<Map<String, dynamic>> menuItems = [
            {
              'title': getTranslated('notifications', context),
              'icon': Images.notification,
              'navigateTo': const InboxScreen(isBackButtonExist: false),
              'isSquare': false,
            },
            {
              'title': getTranslated('profile', context),
              'icon': Images.user,
              'navigateTo': const ProfileScreen1(),
              'isSquare': false,
            },
            {
              'title': getTranslated('addresses', context),
              'icon': Images.address,
              'navigateTo': const AddressListScreen(),
              'isSquare': false,
            },
            {
              'title': getTranslated('coupons', context),
              'icon': Images.coupon,
              'navigateTo': const CouponList(),
              'isSquare': false,
            },
            {
              'title': getTranslated('settings', context),
              'icon': Images.settings,
              'navigateTo': const SettingsScreen(),
              'isSquare': false,
            },
            {
              'title': getTranslated('offers', context),
              'icon': Images.offerIcon,
              'navigateTo': const OfferProductListScreen(),
              'count': 0,
              'hasCount': false,
              'isSquare': true,
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
                'isSquare': true,
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
                'isSquare': true,
              },
            if (!isGuestMode)
              {
                'title': getTranslated('orders', context),
                'icon': Images.shoppingImage,
                'navigateTo': const OrderScreen(),
                'count': profileProvider.userInfoModel?.totalOrder ?? 0,
                'hasCount': (profileProvider.userInfoModel?.totalOrder ?? 0) > 0,
                'isSquare': true,
              },
            {
              'title': getTranslated('cart', context),
              'icon': Images.cartImage,
              'navigateTo': const CartScreen(),
              'count': Provider.of<CartController>(context, listen: false).cartList.length,
              'hasCount': true,
              'isSquare': true,
            },
            {
              'title': getTranslated('wishlist', context),
              'icon': Images.wishlist,
              'navigateTo': const WishListScreen(),
              'count': Provider.of<WishListController>(context, listen: false).wishList?.length ?? 0,
              'hasCount': !isGuestMode && (Provider.of<WishListController>(context, listen: false).wishList?.length ?? 0) > 0,
              'isSquare': true,
            },
          ];

          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _hideMenu,
                      child: Container(
                        color: Colors.black.withOpacity(0.3 * _fadeAnimation.value),
                      ),
                    ),
                  ),
                  Positioned(
                    left: screenWidth - menuWidth + (menuWidth * _slideAnimation.value),
                    top: topPadding,
                    width: menuWidth,
                    height: screenHeight - topPadding,
                    child: Material(
                      elevation: 8,
                      shadowColor: Colors.blue.withOpacity(0.3),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade600,
                                    Colors.blue.shade400,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Menu',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: _hideMenu,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: menuItems.length,
                                itemBuilder: (context, index) {
                                  final item = menuItems[index];
                                  return TweenAnimationBuilder<double>(
                                    duration: Duration(milliseconds: 300 + (index * 50)),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    curve: Curves.easeOutBack,
                                    builder: (context, value, child) {
                                      final opacity = value.clamp(0.0, 1.0);
                                      return Transform.translate(
                                        offset: Offset(50 * (1 - value), 0),
                                        child: Opacity(
                                          opacity: opacity,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(12),
                                          onTap: () {
                                            _hideMenu();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => item['navigateTo'],
                                              ),
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade50,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Image.asset(
                                                    item['icon'],
                                                    width: 24,
                                                    height: 24,
                                                    color: Colors.blue.shade600,
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
                                                          color: Colors.grey.shade800,
                                                        ),
                                                      ),
                                                      if (item['subTitle'] != null)
                                                        Padding(
                                                          padding: const EdgeInsets.only(top: 4),
                                                          child: Text(
                                                            '${item['subTitle']}: ${item['balance']}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey.shade600,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                if (item['hasCount'] == true && item['count'] > 0)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          Colors.blue.shade600,
                                                          Colors.blue.shade400,
                                                        ],
                                                      ),
                                                      borderRadius: BorderRadius.circular(20),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.blue.withOpacity(0.3),
                                                          blurRadius: 4,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      item['count'].toString(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
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
    return Row(
      children: [
        InkWell(
          onTap: _isMenuOpen ? _hideMenu : _showMenu,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Icon(
              _isMenuOpen ? Icons.close : Icons.menu,
              size: 30,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ],
    );
  }
}