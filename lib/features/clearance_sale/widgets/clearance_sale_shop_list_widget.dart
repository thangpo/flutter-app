import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/clearance_sale/screens/clearance_sale_shop_all_product_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/clearance_sale/widgets/clearance_sale_card.dart';
import 'package:flutter_sixvalley_ecommerce/features/clearance_sale/widgets/clearance_title_row_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/controllers/shop_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/aster_theme/find_what_you_need_shimmer.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

class ClearanceShopListWidget extends StatelessWidget {
  final bool isHomeScreen;
  final String? sellerId;
  const ClearanceShopListWidget({super.key, this.sellerId, this.isHomeScreen = true});

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopController>(
      builder: (context, shopController, child) {
      return shopController.clearanceProductModel != null ? (shopController.clearanceProductModel?.products != null
        && shopController.clearanceProductModel!.products!.isNotEmpty) ?
          Column (
            children: [
              Stack(children: [
                Container(
                  height: 150, width: MediaQuery.of(context).size.width,
                  color: Theme.of(context).colorScheme.onTertiary,
                ),
                Consumer<ShopController>(builder: (context, shopController, child) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                        child: ClearanceTitleRowWidget(
                          isHomeScreen: isHomeScreen,
                          title: '${getTranslated('clearance_sale_banner', context)}',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClearanceSaleShopProductScreen(sellerId: sellerId!))),
                        ),
                      ),
                      CarouselSlider.builder(
                        options: CarouselOptions(
                          aspectRatio: 2.5,
                          viewportFraction: 0.86,
                          autoPlay: true,
                          pauseAutoPlayOnTouch: true,
                          pauseAutoPlayOnManualNavigate: true,
                          pauseAutoPlayInFiniteScroll: true,
                          enlargeFactor: 0.2,
                          enlargeCenterPage: true,
                          enableInfiniteScroll: true,
                          disableCenter: true,
                          onPageChanged: (index, reason) => shopController.changeSelectedIndex(index)
                        ),
                        itemCount: shopController.clearanceProductModel?.products?.length,

                        itemBuilder: (context, index, _) =>
                          ClearanceSaleWidget(
                            product: shopController.clearanceProductModel!.products![index],
                            isCenterElement: index == shopController.clearanceSaleProductSelectedIndex,
                        )
                      ),
                    ],
                  );
                }),
              ]),
              const SizedBox(height: Dimensions.paddingSizeDefault),
            ],
          ) : const SizedBox() : const FindWhatYouNeedShimmer();
     }
    );
  }
}
