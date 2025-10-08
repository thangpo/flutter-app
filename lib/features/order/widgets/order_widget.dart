import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/domain/models/order_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/screens/order_details_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/date_converter.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/controllers/localization_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';


class OrderWidget extends StatelessWidget {
  final Orders? orderModel;
  const OrderWidget({super.key, this.orderModel});

  @override
  Widget build(BuildContext context) {

    double orderAmount = 0;

    if(orderModel?.orderType == 'POS') {
      double itemsPrice = 0;
      double discount = 0;
      double? eeDiscount = 0;
      double tax = 0;
      double coupon = 0;
      double shipping = 0;
      if (orderModel?.details != null && orderModel!.details!.isNotEmpty ) {
        coupon = orderModel?.discountAmount ?? 0;
        shipping = orderModel?.shippingCost ?? 0;
        for (var orderDetails in orderModel!.details!) {
          itemsPrice = itemsPrice + (orderDetails.price! * orderDetails.qty!);
          discount = discount + orderDetails.discount!;
          tax = tax + orderDetails.tax!;

        }
        if(orderModel!.orderType == 'POS'){
          if(orderModel!.extraDiscountType == 'percent'){
            eeDiscount = itemsPrice * (orderModel!.extraDiscount!/100);
          }else{
            eeDiscount = orderModel!.extraDiscount;
          }
        }
      }
      double subTotal = itemsPrice +tax - discount;

      orderAmount = subTotal + shipping - coupon - eeDiscount!;




      // double ? _extraDiscountAnount = 0;
      // if(orderModel.extraDiscount != null){
      //   _extraDiscountAnount = PriceConverter.convertWithDiscount(context, orderModel.totalProductPrice, orderModel.extraDiscount, orderModel.extraDiscountType == 'percent' ? 'percent' : 'amount' );
      //   if(_extraDiscountAnount != null) {
      //     double percentAmount = _extraDiscountAnount!;
      //     _extraDiscountAnount = orderModel.totalProductPrice! - percentAmount;
      //   }
      // }
      //
      // double totalDiscount = (_extraDiscountAnount! + orderModel.totalProductDiscount!);
      // double totalOrderAmount = (orderModel.totalProductPrice! + orderModel.totalTaxAmount!);
      //
      // orderAmount = totalOrderAmount - totalDiscount;
      //
      // orderAmount = orderModel.orderAmount! - orderModel.totalTaxAmount!;


    }



    return InkWell(onTap: () {Navigator.of(context).push(MaterialPageRoute(builder: (context) => OrderDetailsScreen(orderId: orderModel!.id)));},

      child: Stack(children: [
          Container(margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall,
              left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall),
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(color: Theme.of(context).highlightColor,
              borderRadius: BorderRadius.circular(5),
              boxShadow:  [BoxShadow(color: Colors.grey.withValues(alpha:.2), spreadRadius: 1, blurRadius: 7, offset: const Offset(0, 1))],),

            child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 82,height: 82,
                  child: Column(children: [
                    Container(decoration: BoxDecoration(color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                      border: Border.all(width: 1, color: Theme.of(context).primaryColor.withValues(alpha:.25)),
                      boxShadow: Provider.of<ThemeController>(context, listen: false).darkTheme? null :[BoxShadow(color: Colors.grey.withValues(alpha:.2), spreadRadius: 1, blurRadius: 7, offset: const Offset(0, 1))],),

                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                        child: CustomImageWidget(
                          placeholder: Images.placeholder, fit: BoxFit.scaleDown, width: 70, height: 70,
                          image: orderModel?.sellerIs == 'admin' ? Provider.of<SplashController>(context, listen: false).configModel?.inHouseShop?.imageFullUrl?.path ?? '' : '${orderModel?.seller?.shop?.imageFullUrl?.path}',
                          )),),]),),
                const SizedBox(width: Dimensions.paddingSizeLarge),



                Expanded(flex: 5,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text('${getTranslated('order', context)!}# ${orderModel!.id.toString()}',
                          style: textBold.copyWith(fontSize: Dimensions.fontSizeDefault, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color )))]),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    Text(DateConverter.localDateToIsoStringAMPMOrder(DateTime.parse(orderModel!.createdAt!)),
                        style: textMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    Text(PriceConverter.convertPrice(context, orderModel!.orderType == 'POS' ? orderAmount : orderModel!.orderAmount),
                      style: textBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyMedium?.color )),])),



                Container(alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall,vertical: Dimensions.paddingSizeExtraSmall),
                    decoration: BoxDecoration(
                      color: orderModel!.orderStatus == 'delivered'? Theme.of(context).colorScheme.onTertiaryContainer.withValues(alpha:.10) :
                      orderModel!.orderStatus == 'pending'? Theme.of(context).primaryColor.withValues(alpha:.10) :
                      orderModel!.orderStatus == 'confirmed'? Theme.of(context).colorScheme.onTertiaryContainer.withValues(alpha:.10)
                          :orderModel!.orderStatus == 'processing'? Theme.of(context).colorScheme.outline.withValues(alpha:.10):
                      orderModel!.orderStatus == 'canceled'? Theme.of(context).colorScheme.error.withValues(alpha: 0.10) :
                      Theme.of(context).colorScheme.secondary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(50)),

                    child: Text(getTranslated('${orderModel!.orderStatus}', context)??'',
                        style: textMedium.copyWith(fontSize: Dimensions.fontSizeSmall, fontWeight: FontWeight.w500,
                      color: orderModel!.orderStatus == 'delivered'?  Theme.of(context).colorScheme.onTertiaryContainer :
                      orderModel!.orderStatus == 'pending'? Theme.of(context).primaryColor :
                      orderModel!.orderStatus == 'confirmed'? Theme.of(context).colorScheme.onTertiaryContainer
                          :orderModel!.orderStatus == 'processing'? Theme.of(context).colorScheme.outline :
                      (orderModel!.orderStatus == 'canceled' || orderModel!.orderStatus == "failed")? Theme.of(context).colorScheme.error :
                      Theme.of(context).colorScheme.secondary))),

              ]),
            ),
          ),

        Positioned(top: 2, left: Provider.of<LocalizationController>(context, listen: false).isLtr? 90 : MediaQuery.of(context).size.width-50, child: Container(
          height: 22,
          width: 22,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
          child: FittedBox(child: Text(
            "${orderModel?.orderDetailsCount}",
            style: textRegular.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          )),
        )),
        ],
      ),
    );
  }
}
