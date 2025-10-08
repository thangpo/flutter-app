import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/controllers/checkout_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

class ChangeAmountWidget extends StatelessWidget {
  final TextEditingController changeAmountTextController;
  const ChangeAmountWidget({super.key, required this.changeAmountTextController});

  @override
  Widget build(BuildContext context) {
    final SplashController splashController = Provider.of<SplashController>(context, listen: false);

    return Selector<CheckoutController, bool>(
      selector: (context, checkoutController)=> checkoutController.isCODChecked,
      builder: (context, isCodeChecked, _) {
        return isCodeChecked ? Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
          child: Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
                color: Theme.of(context).hintColor.withValues(alpha: .05),
                border: Border.all(width: 1, color: Theme.of(context).hintColor.withValues(alpha: .125),),
                borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start, children: [

              Row(children: [
                Text(getTranslated('change_amount', context) ?? '', style: textBold,),

                Text('(${splashController.myCurrency?.symbol ?? ''})', style: titilliumSemiBold,),
              ]),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              Text(getTranslated('insert_amount_if_you_need', context) ?? '', style: textRegular.copyWith(
                color: Theme.of(context).hintColor,
                fontSize: Dimensions.fontSizeSmall,
              )),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              SizedBox(height: 40, child: Center(
                child: TextField(
                  controller: changeAmountTextController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      // RegExp(r'^\d*\.?\d{0,2}$'), // Allows up to 2 decimal places
                        RegExp(r'^\d*\.?\d{0,' + (splashController.configModel?.decimalPointSettings ?? 0).toString() + r'}$'),
                    ),
                  ],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).highlightColor,
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).hintColor.withValues(alpha: .5), width: 1)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).hintColor.withValues(alpha: .5), width: 1)),
                    hintText: getTranslated('amount', context) ?? '',
                    hintStyle: textRegular.copyWith(color: Theme.of(context).hintColor),
                    contentPadding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall, horizontal: Dimensions.paddingSizeDefault),
                  ),
                ),
              ))
            ]),
          ),
        ) : const SizedBox();
      }
    );
  }
}
