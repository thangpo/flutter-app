import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/controllers/checkout_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/payment_method_bottom_sheet_widget.dart';
import 'package:provider/provider.dart';

class ChoosePaymentWidget extends StatelessWidget {
  final bool onlyDigital;
  const ChoosePaymentWidget({super.key, required this.onlyDigital});

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckoutController>(
      builder: (context, orderProvider,_) {
        return Consumer<SplashController>(
          builder: (context, configProvider, _) {
            return Card(child: Container(padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
                  color: Theme.of(context).cardColor),
                child: Column(crossAxisAlignment:CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment:MainAxisAlignment.start, crossAxisAlignment:CrossAxisAlignment.start, children: [
                        Expanded(child: Text('${getTranslated('payment_method', context)}',
                            style: textMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color))),


                      InkWell(onTap: () => showModalBottomSheet(context: context,
                          isScrollControlled: true, backgroundColor: Colors.transparent,
                          builder: (c) => PaymentMethodBottomSheetWidget(onlyDigital: onlyDigital,)),
                          child: SizedBox(width: 20, child: Image.asset(Images.edit, scale: 3)))]),
                    const SizedBox(height: Dimensions.paddingSizeDefault,),

                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Divider(thickness: .200),
                      (orderProvider.paymentMethodIndex != -1)?
                      Row(children: [
                        SizedBox(width: 40, child: CustomImageWidget(
                            image: '${configProvider.configModel?.paymentMethodImagePath}/${configProvider.configModel!.paymentMethods![orderProvider.paymentMethodIndex].additionalDatas!.gatewayImage??''}')),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                          child: Text(configProvider.configModel!.paymentMethods![orderProvider.paymentMethodIndex].additionalDatas!.gatewayTitle??'', style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),),),
                      ],):orderProvider.isCODChecked?
                      Text(getTranslated('cash_on_delivery', context)??'', style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)) :orderProvider.isOfflineChecked?
                      Text(getTranslated('offline_payment', context)??'', style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)) :orderProvider.isWalletChecked?
                      Text(getTranslated('wallet_payment', context)??'', style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)
                      ) :

                      InkWell(onTap: () => showModalBottomSheet(context: context,
                          isScrollControlled: true, backgroundColor: Colors.transparent,
                          builder: (c) =>   PaymentMethodBottomSheetWidget(onlyDigital: onlyDigital,)),
                        child: Row(children: [
                          Padding(padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                            child: Icon(Icons.add_circle_outline_outlined, size: 20, color: Theme.of(context).primaryColor),),
                            Text('${getTranslated('add_payment_method', context)}',
                              style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge?.color),
                              maxLines: 3, overflow: TextOverflow.fade)]))]),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }
}
