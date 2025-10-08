import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_asset_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/not_logged_in_bottom_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/controllers/chat_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/helper/responsive_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/controllers/shop_controller.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/screens/chat_screen.dart';
import 'package:provider/provider.dart';

class ShopInfoWidget extends StatelessWidget {
  final bool vacationIsOn;
  final bool temporaryClose;
  final String sellerName;
  final int sellerId;
  final String banner;
  final String shopImage;
  const ShopInfoWidget({super.key, required this.vacationIsOn, required this.sellerName,
    required this.sellerId, required this.banner, required this.shopImage, required this.temporaryClose});

  @override
  Widget build(BuildContext context) {
    var splashController = Provider.of<SplashController>(context, listen: false);
    return Column(children: [
      Stack(
        children: [
          CustomImageWidget(image:
          sellerId == 0 ?
          splashController.configModel?.inHouseShop?.bannerFullUrl?.path ?? '' : banner,
              placeholder: Images.placeholder_3x1,width: MediaQuery.of(context).size.width, height: ResponsiveHelper.isTab(context)? 250 : 120),

          if(Platform.isIOS)
          Positioned(
            top: 40,
            left: 15,
            child: InkWell(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).cardColor
                ),
                height: 40, width: 40,
                child: Center(child: const Icon(Icons.arrow_back_ios)),
              ),
            ),
          ),
        ],
      ),


        Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Container(transform: Matrix4.translationValues(0, -20, 0),
            padding: const EdgeInsets.symmetric(horizontal : Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeDefault ),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).cardColor,
                boxShadow: Provider.of<ThemeController>(context,listen: false).darkTheme? null:
                [BoxShadow(color: Colors.grey.withValues(alpha:0.3), spreadRadius: 1, blurRadius: 5)]),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stack(children: [
                Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).highlightColor,
                    boxShadow: Provider.of<ThemeController>(context,listen: false).darkTheme? null:
                    [BoxShadow(color: Colors.grey.withValues(alpha:0.3), spreadRadius: 1, blurRadius: 5)]),
                  child: ClipRRect(borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                    child: CustomImageWidget(height: 80, width: 80, fit: BoxFit.cover,
                      image: sellerId == 0 ?
                      splashController.configModel?.inHouseShop?.imageFullUrl?.path ?? '' :
                      shopImage,
                    ))),
                if(temporaryClose || vacationIsOn)
                  Container(width: 80,height: 80,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha:.5),
                        borderRadius: const BorderRadius.all(Radius.circular(Dimensions.paddingSizeExtraSmall)),)),

                temporaryClose?
                Positioned(top: 0,bottom: 0,left: 0,right: 0,
                  child: Align(alignment: Alignment.center,
                      child: Center(child: Text(getTranslated('temporary_closed', context)!.replaceAll(' ', '\n'), textAlign: TextAlign.center,
                          style: textRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraSmall))))):

                vacationIsOn?
                Positioned(top: 0,bottom: 0,left: 0,right: 0,
                  child: Align(alignment: Alignment.center,
                      child: Center(child: Text(getTranslated('close_for_now', context)!, textAlign: TextAlign.center,
                          style: textRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraSmall))))):
                const SizedBox()]),

              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(child: Consumer<ShopController>(
                  builder: (context, sellerProvider,_) {
                    String ratting = sellerProvider.sellerInfoModel != null && sellerProvider.sellerInfoModel!.avgRating != null?
                    sellerProvider.sellerInfoModel!.avgRating.toString() : "0";

                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(sellerName, style: textMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color),
                            maxLines: 2, overflow: TextOverflow.ellipsis,),),

                          Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                            child: InkWell(onTap: () {
                              if(temporaryClose) {
                                showCustomSnackBar("${getTranslated("this_shop_is_close_now", context)}", context);
                              }else{
                                if(!Provider.of<AuthController>(context, listen: false).isLoggedIn()) {
                                  showModalBottomSheet(context: context, builder: (_) => const NotLoggedInBottomSheetWidget());
                                }else  {
                                  Provider.of<ChatController>(context, listen: false).setUserTypeIndex(context, 1);
                                  Navigator.push(context, MaterialPageRoute(builder: (_) =>
                                      ChatScreen(id: sellerId, name: sellerName, userType: 1, isShopOnVacation: vacationIsOn,
                                        image: sellerId == 0 ? splashController.configModel?.inHouseShop?.imageFullUrl?.path ?? '' : shopImage,
                                      )));
                                }
                              }
                            }, child : const CustomAssetImageWidget(Images.storeChatIcon, height: 20, width: 20)),
                          )]),


                        sellerProvider.sellerInfoModel != null?
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Icon(Icons.star_rate_rounded, color: Colors.orange),
                            Text(double.parse(ratting).toStringAsFixed(1), style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),

                            if(sellerProvider.sellerInfoModel!.minimumOrderAmount != null && sellerProvider.sellerInfoModel!.minimumOrderAmount! > 0)
                            Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                              child: Text('|', style: textRegular.copyWith(color: Theme.of(context).primaryColor),),),

                            if(sellerProvider.sellerInfoModel!.minimumOrderAmount != null && sellerProvider.sellerInfoModel!.minimumOrderAmount! > 0)
                            Text('${sellerProvider.sellerInfoModel!.totalReview} ${getTranslated('reviews', context)}',
                              style: titleRegular.copyWith(fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).primaryColor),
                              maxLines: 1, overflow: TextOverflow.ellipsis)]),
                          const SizedBox(height: Dimensions.paddingSizeSmall),


                          Row(children: [

                            (sellerProvider.sellerInfoModel!.minimumOrderAmount != null && sellerProvider.sellerInfoModel!.minimumOrderAmount! > 0)?
                            Text('${PriceConverter.convertPrice(context, sellerProvider.sellerInfoModel!.minimumOrderAmount)} '
                                '${getTranslated('minimum_order', context)}',
                              style: titleRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
                              maxLines: 1, overflow: TextOverflow.ellipsis,):
                            Text('${sellerProvider.sellerInfoModel!.totalReview} ${getTranslated('reviews', context)}',
                              style: titleRegular.copyWith(fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).primaryColor), maxLines: 1, overflow: TextOverflow.ellipsis,),


                            Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                              child: Text('|', style: textRegular.copyWith(color: Theme.of(context).primaryColor),),),

                            Text('${sellerProvider.sellerInfoModel!.totalProduct} ${getTranslated('products', context)}',
                              style: titleRegular.copyWith(fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).primaryColor), maxLines: 1, overflow: TextOverflow.ellipsis)]),
                        ]):const SizedBox(),
                      ],
                      );
                    }
                ),
              ),

            ]),
          ),
        ),
      ],
    );
  }
}
