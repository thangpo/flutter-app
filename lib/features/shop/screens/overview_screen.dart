import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/clearance_sale/widgets/clearance_sale_shop_list_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/seller_product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/coupon/controllers/coupon_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/title_row_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/widgets/shop_coupon_item_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/widgets/shop_featured_product_list_view.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/widgets/shop_recommanded_product_list.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class ShopOverviewScreen extends StatefulWidget {
  final int sellerId;
  final ScrollController scrollController;
  const ShopOverviewScreen({super.key, required this.sellerId, required this.scrollController});

  @override
  State<ShopOverviewScreen> createState() => _ShopOverviewScreenState();
}

class _ShopOverviewScreenState extends State<ShopOverviewScreen> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        Consumer<CouponController>(
            builder: (context, couponController, _) {

              return  Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    couponController.couponItemModel != null ? (couponController.couponItemModel!.coupons != null && couponController.couponItemModel!.coupons!.isNotEmpty)
                      ? Stack(children: [
                        CarouselSlider.builder(
                          options: CarouselOptions(
                              viewportFraction: 1,
                              aspectRatio: 16 / (size.width > 380 ? 7 : 7.5),
                              autoPlay: couponController.couponItemModel!.coupons!.length > 1 ? true : false,
                              scrollPhysics: couponController.couponItemModel!.coupons!.length > 1 ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                              enlargeCenterPage: true,
                              disableCenter: true,
                              onPageChanged: (index, reason) {
                                couponController.setCurrentIndex(index);
                              }
                          ),
                          itemCount: couponController.couponItemModel!.coupons!.length,
                          itemBuilder: (context, index, _)=> ShopCouponItem(coupons: couponController.couponItemModel!.coupons![index]),
                        ),

                      Positioned.fill(child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault,),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Consumer<CouponController>(
                              builder: (context, couponController, _) {
                                return Row(mainAxisAlignment: MainAxisAlignment.center,
                                    children: couponController.couponItemModel!.coupons!.map((banner) {
                                      int index = couponController.couponItemModel!.coupons!.indexOf(banner);
                                      return TabPageSelectorIndicator(backgroundColor: index == couponController.couponCurrentIndex ?
                                      Theme.of(context).primaryColor : Theme.of(context).primaryColor.withValues(alpha:.25),
                                          borderColor: index == couponController.couponCurrentIndex ?
                                          Theme.of(context).primaryColor : Theme.of(context).primaryColor.withValues(alpha:.25), size: 5);
                                    }).toList());
                              }
                          ),
                        ),
                      )),

                      Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeThirtyFive, vertical: Dimensions.paddingSizeDefault),
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Text('${couponController.couponCurrentIndex+1}',
                                  style: textMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeExtraSmall),),
                                Text('/${couponController.couponItemModel!.coupons!.length}',
                                  style: textRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeExtraSmall),),
                              ]),
                            ),
                          )
                      ),]
                    ) : const SizedBox.shrink() : Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        enabled: couponController.couponItemModel?.coupons == null,
                        child: Container(margin: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10), color:  Theme.of(context).colorScheme.secondaryContainer))),

                    ClearanceShopListWidget(sellerId: widget.sellerId.toString(), isHomeScreen: false,),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    Consumer<SellerProductController>(
                        builder: (context, productController, _) {
                          return TitleRowWidget(title: productController.sellerWiseFeaturedProduct != null ?
                          (productController.sellerWiseFeaturedProduct!.products != null &&
                              productController.sellerWiseFeaturedProduct!.products!.isNotEmpty) ?
                          getTranslated('featured_products', context) : getTranslated('recommanded_products', context) : '');
                        }),


                    Consumer<SellerProductController>(
                        builder: (context, productController, _) {
                          return Padding(padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeSmall,
                              Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, 0),
                              child: ShopFeaturedProductViewList(scrollController: widget.scrollController, sellerId: widget.sellerId));
                        }
                    ),


                    Consumer<SellerProductController>(
                        builder: (context, productController, _) {
                          return (productController.sellerWiseFeaturedProduct != null &&
                              productController.sellerWiseFeaturedProduct!.products != null &&
                              productController.sellerWiseFeaturedProduct!.products!.isEmpty)?
                          Padding(padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeSmall,
                              Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, 0),
                            child: ShopRecommandedProductViewList(scrollController: widget.scrollController,
                                sellerId: widget.sellerId),): const SizedBox();
                        })]);
            }
        ),



      ],
    );
  }
}
