import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/controllers/order_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/domain/models/order_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/reorder/controllers/re_order_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/date_converter.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/image_diaglog_widget.dart';
import 'package:provider/provider.dart';

class OrderAgainView extends StatelessWidget {
  const OrderAgainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderController>(
      builder: (context, orderProvider,_) {
        return Container(width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha:0.125),
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,mainAxisSize: MainAxisSize.min, children: [

            Text(getTranslated('order_again', context)!, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor)),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Text(getTranslated('want_to_order_your_usuals_just_reorder_from_your_previous_orders', context)!,
                style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge?.color)),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            if(orderProvider.deliveredOrderModel != null && orderProvider.deliveredOrderModel!.orders != null && orderProvider.deliveredOrderModel!.orders!.isNotEmpty)
            ListView.builder(
              itemCount: orderProvider.deliveredOrderModel!.orders!.length > 2? 2 : orderProvider.deliveredOrderModel!.orders!.length,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index){
              return OrderAgainCard(orders: orderProvider.deliveredOrderModel!.orders![index]);})

          ],
          ),
        );
      }
    );
  }
}


class OrderAgainCard extends StatelessWidget {
  final Orders orders;
  const OrderAgainCard({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Container(decoration: BoxDecoration(color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.homePagePadding)),
          child: Padding(padding: const EdgeInsets.all(Dimensions.homePagePadding),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(getTranslated('delivered', context)!, style: robotoBold.copyWith(color: Theme.of(context).colorScheme.onTertiaryContainer)),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Text("${getTranslated('on', context)} ${DateConverter.dateTimeStringToDateTime(orders.createdAt!)}", style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              if(orders.details!= null && orders.details!.isNotEmpty)
                Container(height: 65,width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(color: Theme.of(context).hintColor.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)),
                  child: Row(children: [

                      Expanded(child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: orders.details!.length> 3? 3 : orders.details!.length,
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, detailsIndex) {
                            return Padding(padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                              child: InkWell(onTap: (){
                                  showDialog(context: context, builder: (_) => ImageDialog(imageUrl: orders.details?[detailsIndex].product?.thumbnailFullUrl?.path??''));
                                } ,
                                child: CustomImageWidget(fit: BoxFit.cover, width: 45, height: 45, image: orders.details?[detailsIndex].product?.thumbnailFullUrl?.path ?? ''),),);}),),

                      if(orders.details!.length> 3)
                      Text('+${orders.details!.length-3}\n ${getTranslated('more', context)}', style: textRegular),
                    ],
                  ),
                ),
              const SizedBox(height: Dimensions.homePagePadding),

              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("${getTranslated('order_id', context)} : #${orders.id}", style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge?.color)),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Text("${getTranslated('final_total', context)} : ${PriceConverter.convertPrice(context, orders.orderAmount)}", style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color)),])),

                SizedBox(height: 36, width: 100,
                    child: Consumer<ReOrderController>(
                      builder: (context, reOrderController,_) {
                        return CustomButton(
                          backgroundColor: reOrderController.isLoading  ? Theme.of(context).disabledColor : Theme.of(context).primaryColor,
                          buttonText: getTranslated('order_again', context)!,
                          fontSize: Dimensions.fontSizeDefault,
                          onTap: reOrderController.isLoading ? null : () {
                            reOrderController.reorder(orderId: orders.id.toString());
                          },
                        );
                      }
                    )
                )]),
            ],
            ),
          )
      ),
    );
  }
}
