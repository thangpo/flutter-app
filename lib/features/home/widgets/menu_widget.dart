import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/screens/profile_screen1.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/screens/inbox_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/setting/screens/settings_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/screens/address_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/screens/order_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/screens/cart_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/screens/wallet_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/wishlist/screens/wishlist_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/coupon/screens/coupon_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/banner/screens/offers_product_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/loyaltyPoint/screens/loyalty_point_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/wishlist/controllers/wishlist_controller.dart';

const Color _kPrimaryBlue = Color(0xFF0077BE);
const Color _kLightBlue = Color(0xFF4DA8DA);

class MenuWidget extends StatelessWidget {
  const MenuWidget({super.key});

  void _openMenu(BuildContext context) {
    HapticFeedback.mediumImpact();

    showGeneralDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      barrierLabel: 'Menu',
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        final width = MediaQuery.of(ctx).size.width * 0.82;

        return SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(),
                  child: Container(color: Colors.transparent),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: width,
                  child: _SideMenu(
                    onClose: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<ThemeController>(context, listen: true).darkTheme;

    return GestureDetector(
      onTap: () => _openMenu(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.menu_rounded,
          size: 24,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

class _SideMenu extends StatelessWidget {
  final VoidCallback onClose;

  const _SideMenu({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final themeController =
    Provider.of<ThemeController>(context, listen: true);
    final profileController =
    Provider.of<ProfileController>(context, listen: true);
    final authController = Provider.of<AuthController>(context, listen: false);
    final splashController =
    Provider.of<SplashController>(context, listen: false);
    final cartController =
    Provider.of<CartController>(context, listen: true);
    final wishListController =
    Provider.of<WishListController>(context, listen: true);

    final bool isDark = themeController.darkTheme;
    final bool isGuest = !authController.isLoggedIn();
    final ConfigModel? configModel = splashController.configModel;
    final user = profileController.userInfoModel;
    final String fullName = isGuest
        ? (getTranslated('guest', context) ?? 'Guest')
        : [
      user?.fName,
      user?.lName,
    ].where((e) => (e ?? '').isNotEmpty).join(' ').ifEmpty(
      user?.phone ?? user?.email ?? 'User',
    );

    final String subtitle = isGuest
        ? (getTranslated('tap_to_login', context) ?? '')
        : (user?.phone ?? user?.email ?? '');

    final int totalOrders = ((user?.totalOrder ?? 0) as num).toInt();
    final int cartCount = cartController.cartList.length;
    final int wishCount = wishListController.wishList?.length ?? 0;
    final List<_MenuItemData> items = [
      _MenuItemData(
        icon: Icons.home_rounded,
        title: getTranslated('home', context) ?? 'Home',
        onTap: () {
          onClose();
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
      if (!isGuest && configModel?.walletStatus == 1)
        _MenuItemData(
          icon: Icons.account_balance_wallet_rounded,
          title: getTranslated('wallet', context) ?? 'My Wallet',
          onTap: () {
            onClose();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WalletScreen()),
            );
          },
        ),
      _MenuItemData(
        icon: Icons.history_rounded,
        title: getTranslated('orders', context) ?? 'History',
        onTap: () {
          onClose();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const OrderScreen()),
          );
        },
      ),
      _MenuItemData(
        icon: Icons.notifications_rounded,
        title: getTranslated('notifications', context) ?? 'Notifications',
        onTap: () {
          onClose();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const InboxScreen(isBackButtonExist: false),
            ),
          );
        },
      ),
      _MenuItemData(
        icon: Icons.card_giftcard_rounded,
        title:
        getTranslated('offers', context) ?? 'Invite Friends / Offers',
        onTap: () {
          onClose();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const OfferProductListScreen()),
          );
        },
      ),
      _MenuItemData(
        icon: Icons.location_on_rounded,
        title: getTranslated('addresses', context) ?? 'Addresses',
        onTap: () {
          onClose();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddressListScreen(),
            ),
          );
        },
      ),
      _MenuItemData(
        icon: Icons.favorite_rounded,
        title: getTranslated('wishlist', context) ?? 'Wishlist',
        trailingCount: wishCount,
        onTap: () {
          onClose();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WishListScreen()),
          );
        },
      ),
      _MenuItemData(
        icon: Icons.shopping_cart_rounded,
        title: getTranslated('cart', context) ?? 'Cart',
        trailingCount: cartCount,
        onTap: () {
          onClose();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CartScreen()),
          );
        },
      ),
      if (!isGuest && configModel?.loyaltyPointStatus == 1)
        _MenuItemData(
          icon: Icons.stars_rounded,
          title: getTranslated('loyalty_point', context) ?? 'Loyalty',
          onTap: () {
            onClose();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoyaltyPointScreen()),
            );
          },
        ),
      _MenuItemData(
        icon: Icons.settings_rounded,
        title: getTranslated('settings', context) ?? 'Settings',
        onTap: () {
          onClose();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
      ),
      _MenuItemData(
        icon: Icons.logout_rounded,
        title: getTranslated('logout', context) ?? 'Logout',
        isDestructive: true,
        onTap: () async {
          onClose();
          await authController.clearSharedData();
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: Material(
        color: isDark ? const Color(0xFF101218) : Colors.white,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kPrimaryBlue, _kLightBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Gold Member',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _HeaderStatItem(
                        icon: Icons.access_time_filled_rounded,
                        label: 'Orders',
                        value: totalOrders.toString(),
                      ),
                      _HeaderStatItem(
                        icon: Icons.favorite_rounded,
                        label: 'Wishlist',
                        value: wishCount.toString(),
                      ),
                      _HeaderStatItem(
                        icon: Icons.shopping_cart_rounded,
                        label: 'In Cart',
                        value: cartCount.toString(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: isDark ? const Color(0xFF101218) : Colors.white,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _MenuTile(
                      data: item,
                      isDark: isDark,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeaderStatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final int? trailingCount;
  final bool isDestructive;

  _MenuItemData({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingCount,
    this.isDestructive = false,
  });
}

class _MenuTile extends StatelessWidget {
  final _MenuItemData data;
  final bool isDark;

  const _MenuTile({
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bool showBadge =
        data.trailingCount != null && data.trailingCount! > 0;

    final Color baseIconColor =
    isDark ? Colors.white70 : const Color(0xFF6B7280);
    final Color textColor =
    isDark ? Colors.white : const Color(0xFF111827);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          data.onTap();
        },
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                data.icon,
                size: 22,
                color: data.isDestructive
                    ? Colors.redAccent
                    : baseIconColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: data.isDestructive
                        ? Colors.redAccent
                        : textColor,
                  ),
                ),
              ),
              if (showBadge)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _kPrimaryBlue,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    data.trailingCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _StringHelpers on String {
  String ifEmpty(String fallback) =>
      trim().isEmpty ? fallback : this;
}