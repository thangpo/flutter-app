import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/controllers/localization_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:provider/provider.dart';


class DiscountTagWidget extends StatelessWidget {
  const DiscountTagWidget({
    super.key,
    required this.productModel,
    this.positionedTop = 10,
    this.positionedLeft = 0,
    this.positionedRight = 0,
  });

  final Product productModel;
  final double positionedTop;
  final double positionedLeft;
  final double positionedRight;

  @override
  Widget build(BuildContext context) {
    final bool isLtr  = Provider.of<LocalizationController>(context, listen: false).isLtr;

    return Positioned(
      top: positionedTop, left: isLtr ? positionedLeft : null, right: !isLtr ? positionedRight : null,
      child: Container(
        transform: Matrix4.translationValues(-1, 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 3),
        decoration: BoxDecoration(color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.only (
            bottomRight: Radius.circular( isLtr ? Dimensions.paddingSizeExtraSmall : 0),
            topRight: Radius.circular( isLtr ? Dimensions.paddingSizeExtraSmall : 0),
            bottomLeft: Radius.circular( isLtr ? 0 : Dimensions.paddingSizeExtraSmall),
            topLeft: Radius.circular( isLtr ? 0 : Dimensions.paddingSizeExtraSmall)
          )
        ),

        child: Center(
          child: Directionality(textDirection: TextDirection.ltr,
            child: Text(
              productModel.clearanceSale != null ?
              PriceConverter.percentageCalculation(context, productModel.unitPrice, productModel.clearanceSale?.discountAmount, productModel.clearanceSale?.discountType) :
              PriceConverter.percentageCalculation(context, productModel.unitPrice, productModel.discount, productModel.discountType),

              style: textBold.copyWith(color: Colors.white,
                  fontSize: Dimensions.fontSizeSmall), textAlign: TextAlign.center,
            ),
          )
        )

      )
    );
  }
}