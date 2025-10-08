import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/models/shop_again_from_recent_store_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/screens/shop_screen.dart';
import 'package:provider/provider.dart';

class ShopAgainFromRecentStoreWidget extends StatelessWidget {
  final ShopAgainFromRecentStoreModel? shopAgainFromRecentStoreModel;
  final int? length;
  final int? index;
  const ShopAgainFromRecentStoreWidget({super.key, this.shopAgainFromRecentStoreModel, this.length,  this.index});

  @override
  Widget build(BuildContext context) {
    final ConfigModel? configModel = Provider.of<SplashController>(context, listen: false).configModel;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Container(width: 260,
        margin:  const EdgeInsets.only( bottom: Dimensions.paddingSizeSmall),
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
          boxShadow: Provider.of<ThemeController>(context).darkTheme ? null :
          [BoxShadow(color: Colors.grey.withValues(alpha:0.2), spreadRadius: 1, blurRadius: 7, offset: const Offset(0, 1))],),
        child: Row(children: [


          Container(
            decoration: const BoxDecoration(shape: BoxShape.rectangle,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusSmall),
                  bottomLeft: Radius.circular(Dimensions.radiusSmall))),
            child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Container(width: 80, height: 80, decoration:  BoxDecoration(color: Theme.of(context).cardColor,
                    border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha:0.1), width: 1),
                    borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusDefault))),
                  child: ClipRRect(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                    child: CustomImageWidget(image: "${shopAgainFromRecentStoreModel?.thumbnailFullUrl?.path}"))),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                Text(PriceConverter.convertPrice(context, shopAgainFromRecentStoreModel?.unitPrice),
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge,
                        color: Theme.of(context).primaryColor))]),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row( mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 30, height: 30,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: CustomImageWidget(
                  image: '${(shopAgainFromRecentStoreModel?.isAddedByAdmin ?? false)
                      ? configModel?.inHouseShop?.bannerFullUrl?.path
                      : shopAgainFromRecentStoreModel?.seller?.shop?.imageFullUrl?.path}',
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              Expanded(child: Text(
                '${(shopAgainFromRecentStoreModel?.isAddedByAdmin ?? false)
                    ? configModel?.inHouseShop?.name
                    :  shopAgainFromRecentStoreModel?.seller?.shop?.name}',
                overflow: TextOverflow.ellipsis,
                style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
              )),
            ]),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            OutlinedButton(
              onPressed: () {
                if(shopAgainFromRecentStoreModel?.isAddedByAdmin ?? false) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TopSellerProductScreen(
                      sellerId: 0,
                      fromMore: true,
                      temporaryClose: Provider.of<SplashController>(context, listen: false).configModel?.inhouseTemporaryClose?.status ?? false,
                      vacationStatus: Provider.of<SplashController>(context, listen: false).configModel?.inhouseVacationAdd?.status,
                      vacationEndDate: Provider.of<SplashController>(context, listen: false).configModel?.inhouseVacationAdd?.vacationEndDate,
                      vacationStartDate: Provider.of<SplashController>(context, listen: false).configModel?.inhouseVacationAdd?.vacationStartDate,
                      vacationDurationType: Provider.of<SplashController>(context, listen: false).configModel?.inhouseVacationAdd?.vacationDurationType,
                      name: Provider.of<SplashController>(context, listen: false).configModel?.inHouseShop?.name,
                      banner: Provider.of<SplashController>(context, listen: false).configModel?.inHouseShop?.bannerFullUrl?.path,
                      image: Provider.of<SplashController>(context, listen: false).configModel?.inHouseShop?.imageFullUrl?.path))
                  );
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TopSellerProductScreen(
                    sellerId: shopAgainFromRecentStoreModel?.seller?.id,
                    temporaryClose: shopAgainFromRecentStoreModel?.seller?.shop?.temporaryClose??false,
                    vacationStatus: shopAgainFromRecentStoreModel?.seller?.shop?.vacationStatus,
                    vacationDurationType: shopAgainFromRecentStoreModel?.seller?.shop?.vacationDurationType,
                    vacationEndDate: null,
                    vacationStartDate: null,
                    name: shopAgainFromRecentStoreModel?.seller?.shop?.name,
                    banner: shopAgainFromRecentStoreModel?.seller?.shop?.bannerFullUrl?.path,
                    image: shopAgainFromRecentStoreModel?.seller?.shop?.imageFullUrl?.path
                  )));
                }
              },
              child: Text(getTranslated("visit_again", context)!, style: textMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color))
            ),
          ])),
        ],
        ),
      ),
    );
  }
}
