import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';

class MinOrderQuantityWidget extends StatelessWidget {
  const MinOrderQuantityWidget({
    super.key,
    required this.minOrderQty,
    this.currentQty,
  });

  final int? minOrderQty;
  final int? currentQty;

  @override
  Widget build(BuildContext context) {
    return (minOrderQty ?? 0) > 1 &&
        (currentQty == null || currentQty! < (minOrderQty ?? 1)) ? Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
      ),

      child: Row(
        children: [
          Text(getTranslated('minimum_order_quantity', context)!, style: titleRegular.copyWith(
            fontSize: Dimensions.fontSizeExtraSmall,
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
          )),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),

          Text('$minOrderQty', style: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeExtraSmall,
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),

          )),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),

          Text(getTranslated('quantity', context)!, style: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeExtraSmall,
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),

          )),
        ],
      ),
    ) : const SizedBox();
  }
}
