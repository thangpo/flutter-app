import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_directionality_widget.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';

class OrderedChangeAmountWidget extends StatelessWidget {
  final double amount;
  final String currency;
  const OrderedChangeAmountWidget({super.key, required this.amount, required this.currency});

  @override
  Widget build(BuildContext context) {

    return amount == 0 ? const SizedBox() : Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault, horizontal: Dimensions.paddingSizeExtraSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onTertiaryContainer.withValues(alpha: .15),
              border: Border.all(width: 1, color: Theme.of(context).hintColor.withValues(alpha: .125),),
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)
          ),
          child: CustomDirectionalityWidget(child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: getTranslated('please_ensure_the_deliveryman_has', context), style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),

                TextSpan(text: ' $amount $currency ', style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),

                TextSpan(text: getTranslated('in_change_ready_for_the_customer', context), style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
              ],
            ),
          )),
        ),
      );
  }
}
