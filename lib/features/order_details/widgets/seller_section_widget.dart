import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_asset_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/controllers/chat_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/controllers/order_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/shop_helper.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/not_logged_in_bottom_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/screens/chat_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:provider/provider.dart';

class SellerSectionWidget extends StatelessWidget {
  final OrderDetailsController? order;
  const SellerSectionWidget({super.key, this.order});

  @override
  Widget build(BuildContext context) {

    bool isVacationActive = false;

    if (order!.orderDetails![0].seller != null) {
      isVacationActive = ShopHelper.isVacationActive(
        context, startDate: order!.orderDetails![0].seller?.shop?.vacationStartDate,
        endDate: order!.orderDetails![0].seller?.shop?.vacationEndDate,
        vacationDurationType: order!.orderDetails![0].seller?.shop?.vacationDurationType,
        vacationStatus: order!.orderDetails![0].seller?.shop?.vacationStatus,
        isInHouseSeller: order!.orderDetails![0].order?.sellerIs == 'admin'
      );
    }



    return Container(
      color: Theme.of(context).highlightColor,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: InkWell(onTap: () {
            if(Provider.of<AuthController>(context, listen: false).isLoggedIn()){
              Provider.of<ChatController>(context, listen: false).setUserTypeIndex(context, 1);
              if((order!.orderDetails![0].seller != null && ((order!.orderDetails![0].seller?.shop?.temporaryClose ?? false)))){
                showCustomSnackBar("${getTranslated("this_shop_is_close_now", context)}", context);
              } else if(order!.orderDetails![0].seller != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                  id: order!.orderDetails![0].order?.sellerIs == 'admin'
                      ? 0
                      : order!.orderDetails![0].seller!.id,
                  name: order!.orderDetails![0].order?.sellerIs == 'admin'
                      ? "${Provider.of<SplashController>(context, listen: false).configModel?.inHouseShop?.name}"
                      : order!.orderDetails![0].seller!.shop!.name,
                  image: order!.orderDetails![0].order?.sellerIs == 'admin'
                      ? "${Provider.of<SplashController>(context, listen: false).configModel?.inHouseShop?.imageFullUrl?.path}"
                      : order!.orderDetails![0].seller?.imageFullUrl?.path,
                  isShopOnVacation: isVacationActive,
                  isShopTemporaryClosed: order!.orderDetails![0].seller?.shop?.temporaryClose ?? false,
                )));
              } else {
                showCustomSnackBar(getTranslated('seller_not_available', context), context,isToaster: true);
              }
            }else{
              showModalBottomSheet(backgroundColor: Colors.transparent, context: context, builder: (_)=> const NotLoggedInBottomSheetWidget());}
            },
              child: Padding(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                child: Row(children: [
                  Icon(Icons.storefront_outlined, color: Theme.of(context).primaryColor, size: 20),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  if( order != null && order!.orderDetails != null && order!.orderDetails != null && order!.orderDetails!.isNotEmpty)
                  SizedBox(width: MediaQuery.of(context).size.width * 0.6,
                    child: Text(maxLines: 1, overflow: TextOverflow.ellipsis,
                      (order?.orderDetails != null && order!.orderDetails!.isNotEmpty && order!.orderDetails![0].order?.sellerIs == 'admin' ) ? '${Provider.of<SplashController>(context, listen: false).configModel?.inHouseShop?.name}' :
                      '${order?.orderDetails?[0].seller?.shop?.name??'${getTranslated('seller_not_available', context)}'} ',
                      style: textRegular.copyWith())),
                  const Spacer(),
                  const SizedBox(width: Dimensions.iconSizeDefault, child: CustomAssetImageWidget(Images.storeChatIcon, height: 20, width: 20))

                ]),
              ),
            ),
        ),

        Divider(thickness: .25, color: Theme.of(context).primaryColor.withValues(alpha:0.50)),

      ]),
    );
  }
}
