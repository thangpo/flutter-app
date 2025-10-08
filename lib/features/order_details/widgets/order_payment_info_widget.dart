import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/shipping_details_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/controllers/order_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

class OrderPaymentInfoWidget extends StatelessWidget {
  const OrderPaymentInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderDetailsController>(
      builder: (context, orderProvider, child) {
        ConfigModel? configModel = Provider.of<SplashController>(context, listen: false).configModel;

        return Column(
          children: [
            const SizedBox(height: Dimensions.paddingSizeDefault),

            if(configModel?.orderVerification == 1 && orderProvider.orders!.orderType != 'POS')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        getTranslated('order_verification_code', context) ?? '',
                        style: textRegular.copyWith(color: Theme.of(context).textTheme.titleMedium?.color)
                    ),

                    Text(
                        orderProvider.orders?.verificationCode ?? '',
                        style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)
                    ),
                  ],
                ),
              ),

            if(configModel?.orderVerification == 1 && orderProvider.orders!.orderType != 'POS')
              const SizedBox(height: Dimensions.paddingSizeSmall),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      getTranslated('order_type', context) ?? '',
                      style: textRegular.copyWith(color: Theme.of(context).textTheme.titleMedium?.color)
                  ),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
                    ),
                    padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                    child: Text(
                        orderProvider.orders!.orderType == 'POS' ?
                        getTranslated('pos_order_small', context) ?? '' :
                        getTranslated('regular', context) ?? ' ',
                        style: textBold.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall)
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),


            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      getTranslated('PAYMENT_STATUS', context) ?? '',
                      style: textRegular.copyWith(color: Theme.of(context).textTheme.titleMedium?.color)
                  ),


                  Text((orderProvider.orders?.paymentStatus != null && orderProvider.orders!.paymentStatus!.isNotEmpty) ?
                  getTranslated(orderProvider.orders!.paymentStatus, context) ?? orderProvider.orders!.paymentStatus!
                    : 'Digital Payment',
                    style: titilliumSemiBold.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: orderProvider.orders?.paymentStatus == 'paid' ?
                      Theme.of(context).colorScheme.onTertiaryContainer : Theme.of(context).colorScheme.error
                    )
                  )
                ],
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),


            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      getTranslated('payment_method', context) ?? '',
                      style: textRegular.copyWith(color: Theme.of(context).textTheme.titleMedium?.color)
                  ),

                  Text(orderProvider.orders!.paymentMethod!.replaceAll('_', ' ').capitalize(),
                      style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor)
                  )
                ],
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),


          ],
        );
      }
    );
  }
}
