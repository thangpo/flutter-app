import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/discount_tag_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/screens/product_details_screen.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/controllers/localization_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/widgets/favourite_button_widget.dart';
import 'package:provider/provider.dart';

class ProductWidget extends StatelessWidget {
  final Product productModel;
  final int productNameLine;
  const ProductWidget({super.key, required this.productModel, this.productNameLine = 2});

  @override
  Widget build(BuildContext context) {
    final bool isLtr  = Provider.of<LocalizationController>(context, listen: false).isLtr;
    double ratting = (productModel.rating?.isNotEmpty ?? false) ?  double.parse('${productModel.rating?[0].average}') : 0;

    return InkWell(onTap: () {
      Navigator.push(context, PageRouteBuilder(transitionDuration: const Duration(milliseconds: 1000),
          pageBuilder: (context, anim1, anim2) => ProductDetails(productId: productModel.id,
              slug: productModel.slug)));
    },
      child: Container(
        margin: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall), border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha:.10), width: 1),
          color: Theme.of(context).highlightColor,
          boxShadow: [BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha:0.05),
            spreadRadius: 0, blurRadius: 10,
            offset: const Offset(9, 5),
          )],),
        child: Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            LayoutBuilder(builder: (context, boxConstraint)=> ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(Dimensions.radiusDefault),
                topRight: Radius.circular(Dimensions.radiusDefault),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall), border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha:.10), width: 1),
                      color: Theme.of(context).highlightColor,
                      boxShadow: [BoxShadow(
                        color: Theme.of(context).primaryColor.withValues(alpha:0.05),
                        spreadRadius: 0, blurRadius: 10,
                        offset: const Offset(0, 0),
                      )],
                    ),
                    margin: const EdgeInsets.only(left: Dimensions.paddingSizeSmall, top: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.paddingSizeEight),
                      child: CustomImageWidget(
                        image: '${productModel.thumbnailFullUrl?.path}',
                        fit: BoxFit.cover,
                        height: boxConstraint.maxWidth * 0.82,
                        width: boxConstraint.maxWidth,
                      ),
                    ),
                  ),

                  if(productModel.currentStock! == 0 && productModel.productType == 'physical')...[
                    Container(
                      height: boxConstraint.maxWidth * 0.82,
                      width: boxConstraint.maxWidth,
                      color: Colors.black.withValues(alpha:0.4),
                    ),

                    Positioned.fill(child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: boxConstraint.maxWidth,
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error.withValues(alpha:0.4),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(Dimensions.radiusSmall),
                              topRight: Radius.circular(Dimensions.radiusSmall),
                            )
                        ),
                        child: Text(
                          getTranslated('out_of_stock', context)??'',
                          style: textBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )),

                  ],

                ],
              ),
            )),

            // Product Details
            Center(child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center, children: [

                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                if(ratting > 0) Row(mainAxisAlignment: MainAxisAlignment.center, children: [

                  const Icon(Icons.star_rate_rounded, color: Colors.orange,size: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Text(ratting.toStringAsFixed(1), style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault)),
                  ),



                  Text('(${productModel.reviewCount.toString()})',
                      style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor))]),

                Padding(padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: Dimensions.paddingSizeSmall),
                    child: Text(productModel.name ?? '', textAlign: TextAlign.center, style: textMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge?.color
                    ), maxLines: productNameLine, overflow: TextOverflow.ellipsis)),


                Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  ((productModel.discount != null && productModel.discount! > 0) || (productModel.clearanceSale?.discountAmount ?? 0) > 0) ?
                  Text(PriceConverter.convertPrice(context, productModel.unitPrice),
                      style: titleRegular.copyWith(color: Theme.of(context).hintColor,
                          decoration: TextDecoration.lineThrough, fontSize: Dimensions.fontSizeSmall)) : const SizedBox.shrink(),

                  ((productModel.discount!= null && productModel.discount! > 0) || (productModel.clearanceSale?.discountAmount ?? 0) > 0)
                      ? const SizedBox(width: Dimensions.paddingSizeExtraSmall): const SizedBox(),

                  Text(
                    PriceConverter.convertPrice(
                      context, productModel.unitPrice,
                      discountType: (productModel.clearanceSale?.discountAmount ?? 0)  > 0
                          ? productModel.clearanceSale?.discountType
                          : productModel.discountType,
                      discount: (productModel.clearanceSale?.discountAmount ?? 0)  > 0
                          ? productModel.clearanceSale?.discountAmount
                          : productModel.discount,
                    ),
                    style: robotoBold.copyWith(color: Theme.of(context).primaryColor),
                  ),
                ]),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              ])),
          ]),

          // Off

          ((productModel.discount! > 0) || (productModel.clearanceSale != null)) ?
          DiscountTagWidget(productModel: productModel) : const SizedBox.shrink(),

          Positioned(top: 18, right: isLtr ? 16 : null, left: !isLtr ? 16 : null,
            child: FavouriteButtonWidget(
              backgroundColor: Provider.of<ThemeController>(context).darkTheme
                  ? Theme.of(context).cardColor
                  : Theme.of(context).primaryColor,
              productId: productModel.id,
            ),
          ),
        ]),
      ),
    );
  }
}


