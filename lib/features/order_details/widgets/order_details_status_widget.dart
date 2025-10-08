import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_asset_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/controllers/order_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/date_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';

class OrderDetailsStatusWidget extends StatelessWidget {
  const OrderDetailsStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return
    Consumer<OrderDetailsController>(
      builder: (context, orderProvider, _) {
        return  Stack(children: [

          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Column(mainAxisAlignment: MainAxisAlignment.center,crossAxisAlignment: CrossAxisAlignment.center, children: [
                  RichText(text: TextSpan(
                      text: '${getTranslated('order', context)}# ',
                      style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: Dimensions.fontSizeDefault), children:[
                        TextSpan(text: orderProvider.orders?.id.toString(),
                            style: textBold.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontSize: Dimensions.fontSizeLarge)),
                      ],
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall,),

                  RichText(text: TextSpan(
                      text: getTranslated('your_order_is', context),
                      style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeLarge,
                          color: Theme.of(context).hintColor), children:[
                        TextSpan(text: ' ${getTranslated('${orderProvider.orders?.orderStatus}', context)}',
                            style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge,
                                color: orderProvider.orders?.orderStatus == 'delivered'?  Theme.of(context).colorScheme.onTertiaryContainer :
                                orderProvider.orders?.orderStatus == 'pending'? Theme.of(context).primaryColor :
                                orderProvider.orders?.orderStatus == 'confirmed'? Theme.of(context).colorScheme.onTertiaryContainer
                                    :orderProvider.orders?.orderStatus == 'processing'? Theme.of(context).colorScheme.outline :
                                (orderProvider.orders?.orderStatus == 'canceled' || orderProvider.orders?.orderStatus == "failed")? Theme.of(context).colorScheme.error :
                                Theme.of(context).colorScheme.secondary))]),),
                  const SizedBox(height: Dimensions.paddingSizeSmall,),

                  Text(DateConverter.localDateToIsoStringAMPMOrder(DateTime.parse(orderProvider.orders!.createdAt!)),
                      style: titilliumRegular.copyWith(color: Theme.of(context).hintColor,
                          fontSize: Dimensions.fontSizeSmall)),
                ],
              ),
            ],
          ),
          InkWell(onTap: (){
            if(Navigator.of(context).canPop()){
              Navigator.of(context).pop();
            }else{
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => const DashBoardScreen()), (route) => false);
            }
          }, child: const Padding(padding: EdgeInsets.symmetric(vertical : Dimensions.paddingSizeDefault, horizontal: Dimensions.paddingSizeDefault),
              child: Icon(CupertinoIcons.back))),

          Positioned(
            right: 0,
            child: Consumer<OrderDetailsController>(
              builder: (context, orderProvider, _) {
                return (orderProvider.orders!.orderType != 'POS'  ? InkWell(
                  onTap: () {
                    orderProvider.getOrderInvoice(orderProvider.orders!.id.toString(), context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      color: Theme.of(context).primaryColor,
                    ),
                    child:  orderProvider.isInvoiceLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator()) :const Padding(
                      padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                      child: CustomAssetImageWidget(Images.downloadInvoice, height: 20, width: 20),
                    ),
                  ),
                ) : const SizedBox());

              }
            )
          ),

        ]);
      }
    );
  }
}
