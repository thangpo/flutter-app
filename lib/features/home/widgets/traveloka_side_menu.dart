import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/wishlist/controllers/wishlist_controller.dart';

// Screens
import 'package:flutter_sixvalley_ecommerce/features/order/screens/order_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/screens/address_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/wishlist/screens/wishlist_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/screens/cart_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/screens/inbox_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/contact_us/screens/contact_us_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/setting/screens/settings_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/event_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/saved_posts_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_groups_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_page_screen.dart';

class TravelokaSideMenu extends StatelessWidget {
  const TravelokaSideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final themeDark = Provider.of<ThemeController>(context).darkTheme;

    final auth = Provider.of<AuthController>(context, listen: false);
    final profile = Provider.of<ProfileController>(context, listen: true);
    final cart = Provider.of<CartController>(context, listen: true);
    final wishlist = Provider.of<WishListController>(context, listen: true);

    final user = profile.userInfoModel;
    final bool loggedIn = auth.isLoggedIn();

    final name = loggedIn
        ? "${user?.fName ?? ''} ${user?.lName ?? ''}".trim()
        : getTranslated('guest', context) ?? 'Guest';

    final email = loggedIn ? (user?.email ?? '') : "Tap to login";
    final avatar = user?.imageFullUrl?.path ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // MENU TRÁI (FULL CHIỀU CAO)
          Container(
            width: MediaQuery.of(context).size.width * 0.78,
            color: themeDark ? const Color(0xFF121212) : Colors.white,
            child: Column(
              children: [
                _header(context, name, email, avatar, themeDark),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle("General", context),
                        _menuCard(context,
                            icon: Icons.receipt_long,
                            color: Colors.blue,
                            title: "My Bookings",
                            onTap: () => _go(context, const OrderScreen())),
                        _menuCard(context,
                            icon: Icons.location_on_rounded,
                            color: Colors.purple,
                            title: "Addresses",
                            onTap: () => _go(context, const AddressListScreen())),
                        _menuCard(context,
                            icon: Icons.favorite_rounded,
                            color: Colors.pinkAccent,
                            title: "Wishlist",
                            badge: wishlist.wishList?.length ?? 0,
                            onTap: () => _go(context, const WishListScreen())),
                        _menuCard(context,
                            icon: Icons.shopping_cart_rounded,
                            color: Colors.green,
                            title: "My Cart",
                            badge: cart.cartList.length,
                            onTap: () => _go(context, const CartScreen())),
                        _menuCard(context,
                            icon: Icons.notifications_rounded,
                            color: Colors.orange,
                            title: "Notifications",
                            onTap: () => _go(context, const InboxScreen())),

                        _sectionTitle("Social", context),
                        _menuCard(context,
                            icon: Icons.event_available,
                            color: Colors.teal,
                            title: "Events",
                            onTap: () => _go(context, const EventScreen())),
                        _menuCard(context,
                            icon: Icons.bookmark_rounded,
                            color: Colors.indigo,
                            title: "Saved Posts",
                            onTap: () => _go(context, const SavedPostsScreen())),
                        _menuCard(context,
                            icon: Icons.group_rounded,
                            color: Colors.deepOrange,
                            title: "Groups",
                            onTap: () => _go(context, const SocialGroupsScreen())),
                        _menuCard(context,
                            icon: Icons.pages_rounded,
                            color: Colors.lightBlue,
                            title: "Pages",
                            onTap: () => _go(context, const SocialPagesScreen())),

                        _sectionTitle("Support", context),
                        _menuCard(context,
                            icon: Icons.support_agent_rounded,
                            color: Colors.redAccent,
                            title: "Contact Us",
                            onTap: () => _go(context, const ContactUsScreen())),
                        _menuCard(context,
                            icon: Icons.settings,
                            color: Colors.grey,
                            title: "Settings",
                            onTap: () => _go(context, const SettingsScreen())),

                        if (loggedIn)
                          _menuCard(context,
                              icon: Icons.logout_rounded,
                              color: Colors.red,
                              title: "Logout",
                              isDestructive: true,
                              onTap: () async {
                                await auth.clearSharedData();
                                Navigator.pop(context);
                              }),

                        const SizedBox(height: 26),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),

          // PHẦN BÊN PHẢI ĐỂ ĐÓNG MENU
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String name, String email,
      String? avatarUrl, bool dark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [Colors.black87, Colors.black54]
              : [const Color(0xFF0288D1), const Color(0xFF26C6DA)],
        ),
      ),
      child: Row(
        children: [
          // Ảnh user 20%
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              image: avatarUrl != null && avatarUrl.isNotEmpty
                  ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: avatarUrl == null || avatarUrl.isEmpty
                ? const Icon(Icons.person, size: 38)
                : null,
          ),
          const SizedBox(width: 14),

          // Thông tin user 70%
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(email,
                    style: const TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ),

          // Nút close 10%
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 26),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 20, 6, 10),
      child: Text(title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: dark ? Colors.white70 : Colors.black54)),
    );
  }

  Widget _menuCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        int badge = 0,
        required Color color,
        bool isDestructive = false,
      }) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: dark ? Colors.black45 : Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.18),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDestructive
                    ? Colors.red
                    : (dark ? Colors.white : Colors.black))),
        trailing: badge > 0
            ? CircleAvatar(
          radius: 12,
          backgroundColor: Colors.blue,
          child: Text("$badge",
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        )
            : null,
        onTap: onTap,
      ),
    );
  }

  void _go(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}