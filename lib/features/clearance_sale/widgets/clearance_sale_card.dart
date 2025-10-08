import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';

import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/screens/product_details_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/widgets/favourite_button_widget.dart';
import 'package:provider/provider.dart';

class ClearanceSaleWidget extends StatelessWidget {
  final Product product;
  final bool? isCenterElement;
  const ClearanceSaleWidget({super.key, required this.product, this.isCenterElement});

  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: () => Navigator.push(context, PageRouteBuilder(transitionDuration: const Duration(milliseconds: 1000),
        pageBuilder: (context, anim1, anim2) => ProductDetails(productId: product.id,slug: product.slug))),

      child: LayoutBuilder(
          builder: (context, constrains) {
            return AnimatedContainer(
              margin: isCenterElement == null ? null :  EdgeInsets.symmetric(vertical : isCenterElement! ? 0 : Dimensions.paddingSizeEight),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: Theme.of(context).colorScheme.onTertiary),
                  boxShadow: [
                    BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha:0.05), spreadRadius: 0, blurRadius: 10, offset: const Offset(0, 5)),
                  ]),

              duration: const Duration(milliseconds: 600),
              child: Stack(children: [
                Row(children: [

                  Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                      child: CustomImageWidget(
                        image: '${product.thumbnailFullUrl?.path}',
                        height: constrains.maxHeight * 0.6,
                        width: constrains.maxHeight * 0.6,
                      ),
                    ),
                  ),

                  Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        if(product.currentStock! == 0 && product.productType == 'physical')
                          Text(getTranslated('out_of_stock', context)??'',
                              style: textRegular.copyWith(color: const Color(0xFFF36A6A))),

                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        Row(children: [

                          Icon(Icons.star_rate_rounded, color: Provider.of<ThemeController>(context).darkTheme ?
                          Colors.white : Colors.orange, size: 15),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              product.rating != null && product.rating!.isNotEmpty ? double.parse(product.rating![0].average!).toStringAsFixed(1) : '0.0',
                              style: textMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall),
                            ),
                          ),

                          Text('(${product.reviewCount.toString()})', style: textMedium.copyWith(
                            color: Theme.of(context).hintColor,
                            fontSize: Dimensions.fontSizeExtraSmall,
                          )),

                        ]),
                        const SizedBox(height: Dimensions.paddingSizeSmall),


                        Row(children: [
                          Flexible(child: Text(
                            product.name ?? '', style: textMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          )),

                          const SizedBox(width: Dimensions.paddingSizeDefault),
                        ]),
                        const SizedBox(height: Dimensions.paddingSizeSmall),


                        FittedBox(child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          ((product.discount != null && product.discount! > 0) || (product.clearanceSale?.discountAmount ?? 0) > 0) ?
                          Text(PriceConverter.convertPrice(context, product.unitPrice),
                              style: titleRegular.copyWith(color: Theme.of(context).hintColor,
                                  decoration: TextDecoration.lineThrough, fontSize: Dimensions.fontSizeSmall)) : const SizedBox.shrink(),

                          (product.discount! > 0 || product.clearanceSale!.discountAmount! > 0) ? const SizedBox(width: Dimensions.paddingSizeExtraSmall) : const SizedBox(),

                          Text(
                            PriceConverter.convertPrice(
                              context, product.unitPrice,
                              discountType: (product.clearanceSale?.discountAmount ?? 0)  > 0
                                  ? product.clearanceSale?.discountType
                                  : product.discountType,
                              discount: (product.clearanceSale?.discountAmount ?? 0)  > 0
                                  ?  product.clearanceSale?.discountAmount
                                  : product.discount,
                            ),
                            style: robotoBold.copyWith(color: Theme.of(context).primaryColor),
                          ),

                          const SizedBox(width: Dimensions.paddingSizeSmall),

                        ]))],
                    ),
                  )),
                ]),


                ((product.discount != null && product.discount! > 0) || (product.clearanceSale?.discountAmount ?? 0) > 0) ? Positioned(top: 20, left: 10,
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Theme.of(context).textTheme.bodyMedium?.color,
                          borderRadius: const BorderRadius.only(topRight: Radius.circular(4), bottomRight: Radius.circular(4))),
                      child: Directionality(textDirection: TextDirection.ltr,
                        child: Text(product.clearanceSale != null ?
                        PriceConverter.percentageCalculation(context, product.unitPrice, product.clearanceSale?.discountAmount, product.clearanceSale?.discountType) :
                        PriceConverter.percentageCalculation(context, product.unitPrice, product.discount, product.discountType),
                            style: textRegular.copyWith(color: Theme.of(context).highlightColor, fontSize: Dimensions.fontSizeSmall)),
                      )),
                ) : const SizedBox.shrink(),

                Positioned(top: 10, right: 10, child: FavouriteButtonWidget(
                    backgroundColor:  Provider.of<ThemeController>(context).darkTheme ?
                    Theme.of(context).cardColor : Theme.of(context).primaryColor, productId: product.id)),
              ]),
            );
          }
      ),
    );
  }
}
