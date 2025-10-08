import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/controllers/order_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/amount_widget.dart';

class OrderAmountCalculation extends StatelessWidget {
  final double itemTotalAmount;
  final double discount;
  final double? eeDiscount;
  final double tax;
  final double shippingCost;
  final double referAndEarnDiscount;
  final OrderDetailsController orderProvider;
  const OrderAmountCalculation({super.key, required this.itemTotalAmount, required this.discount, this.eeDiscount, required this.tax, required this.shippingCost, required this.orderProvider, required this.referAndEarnDiscount});

  @override
  Widget build(BuildContext context) {
    return  Container(padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        color: Theme.of(context).highlightColor,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          AmountWidget(title: getTranslated('sub_total', context),
              amount: PriceConverter.convertPrice(context, itemTotalAmount)),


          orderProvider.orders!.orderType == "POS"? const SizedBox():
          AmountWidget(title: getTranslated('shipping_fee', context),
              amount: PriceConverter.convertPrice(context, shippingCost)),


          AmountWidget(title: getTranslated('discount', context),
              amount: PriceConverter.convertPrice(context, discount)),


          orderProvider.orders!.orderType == "POS"?
          AmountWidget(title: getTranslated('extra_discount', context),
              amount: PriceConverter.convertPrice(context, eeDiscount)):const SizedBox(),


          AmountWidget(title: getTranslated('coupon_voucher', context),
            amount: PriceConverter.convertPrice(context, orderProvider.orders!.discountAmount),),


          AmountWidget(title: getTranslated('tax', context),
              amount: PriceConverter.convertPrice(context, tax)),

          if(referAndEarnDiscount > 0)
          AmountWidget(title: getTranslated('referral_discount', context),
              amount: PriceConverter.convertPrice(context, referAndEarnDiscount)),

          Padding(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
            child: Divider(height: 2, color: Theme.of(context).hintColor),),


          AmountWidget(title: getTranslated('total_payable', context),
            amount: PriceConverter.convertPrice(context, (itemTotalAmount + shippingCost - referAndEarnDiscount - eeDiscount! - orderProvider.orders!.discountAmount! - discount  + tax)),),


          // && orderProvider.orders!.paymentMethod  == "cash" && orderProvider.orders!.paidAmount! > (itemTotalAmount + shippingCost - eeDiscount! - orderProvider.orders!.discountAmount! - discount  + tax)
          if (orderProvider.orders!.orderType == 'POS')
          AmountWidget(title: getTranslated('paid_amount', context),
            amount: PriceConverter.convertPrice(context, orderProvider.orders!.paidAmount)),

          if (orderProvider.orders!.orderType == 'POS')
          AmountWidget(title: getTranslated('change_amount', context),
            amount: PriceConverter.convertPrice(context, orderProvider.orders!.paidAmount! - double.parse((itemTotalAmount + shippingCost - eeDiscount! - orderProvider.orders!.discountAmount! - discount  + tax).toStringAsFixed(2)))),


        ]));
  }
}
