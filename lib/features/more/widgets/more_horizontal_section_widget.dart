import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/more/widgets/square_item_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/screens/wallet_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/wishlist/controllers/wishlist_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/wishlist/screens/wishlist_screen.dart';
import 'package:flutter_sixvalley_ecommerce/helper/responsive_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/screens/cart_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/loyaltyPoint/screens/loyalty_point_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/banner/screens/offers_product_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/screens/order_screen.dart';
import 'package:provider/provider.dart';

class MoreHorizontalSection extends StatelessWidget {
  const MoreHorizontalSection({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isGuestMode = !Provider.of<AuthController>(context, listen: false).isLoggedIn();
    final ConfigModel? configModel = Provider.of<SplashController>(context, listen: false).configModel;

    return Consumer<ProfileController>(builder: (context, profileProvider,_) {
      return SizedBox(height: ResponsiveHelper.isTab(context)? 135 :130, child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
        child: Center(child: ListView(
          scrollDirection:Axis.horizontal,
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          children: [
            SquareButtonWidget(
              image: Images.offerIcon,
              title: getTranslated('offers', context),
              navigateTo: const OfferProductListScreen(),
              count: 0,
              hasCount: false,
            ),

            if(!isGuestMode && configModel?.walletStatus == 1)SquareButtonWidget(
              image: Images.wallet,
              title: getTranslated('wallet', context),
              navigateTo: const WalletScreen(),
              count: 1,
              hasCount: false,
              subTitle: 'amount',
              isWallet: true,
              balance: profileProvider.balance,
            ),


            if(!isGuestMode && configModel?.loyaltyPointStatus == 1) SquareButtonWidget(
              image: Images.loyaltyPoint,
              title: getTranslated('loyalty_point', context),
              navigateTo: const LoyaltyPointScreen(),
              count: 1,
              hasCount: false,
              isWallet: true,
              subTitle: 'point',
              balance: profileProvider.loyaltyPoint, isLoyalty: true,
            ),


            if(!isGuestMode) SquareButtonWidget(
              image: Images.shoppingImage,
              title: getTranslated('orders', context),
              navigateTo: const OrderScreen(),
              count: 1,
              hasCount: false,
              isWallet: true,
              subTitle: 'orders',
              balance: profileProvider.userInfoModel?.totalOrder ?? 0,
              isLoyalty: true,
            ),

            SquareButtonWidget(
              image: Images.cartImage,
              title: getTranslated('cart', context),
              navigateTo: const CartScreen(),
              count: Provider.of<CartController>(context,listen: false).cartList.length,
              hasCount: true,
            ),

            Consumer<WishListController>(builder: (context, wishListController, _) {
              return SquareButtonWidget(
                image: Images.wishlist, title: getTranslated('wishlist', context),
                navigateTo: const WishListScreen(),
                count: wishListController.wishList?.length ?? 0,
                hasCount: (!isGuestMode  && (wishListController.wishList?.length ?? 0) > 0),
              );
            }),

          ],
        )),
      ));
    });
  }
}
