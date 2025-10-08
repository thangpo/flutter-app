import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/discount_tag_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/controllers/localization_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/screens/product_details_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/widgets/favourite_button_widget.dart';
import 'package:provider/provider.dart';


class SliderProductWidget extends StatelessWidget {
  final Product product;
  final bool isCurrentIndex;
  const SliderProductWidget({super.key, required this.product, this.isCurrentIndex = true});

  @override
  Widget build(BuildContext context) {
    bool isLtr = Provider.of<LocalizationController>(context, listen: false).isLtr;

    return InkWell(onTap: () {
      Navigator.push(context, PageRouteBuilder(transitionDuration: const Duration(milliseconds: 1000),
          pageBuilder: (context, anim1, anim2) => ProductDetails(productId: product.id, slug: product.slug)));
    },
      child: AnimatedContainer(
        margin:  EdgeInsets.symmetric(vertical : isCurrentIndex ? Dimensions.paddingSizeExtraSmall : 45),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
          color: Theme.of(context).cardColor,
          border: Border.all(color: Theme.of(context).colorScheme.onTertiary),
          boxShadow: [
            BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha:0.05), blurRadius: 10, spreadRadius: 0, offset: const Offset(0, 0) )
          ],
        ),
        duration: const Duration(milliseconds: 500),
        // curve: Curves.easeInCubic,
        child: Stack(children: [
          SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

              Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: LayoutBuilder(
                    builder: (context, constrains) {
                      return Stack(children: [
                        Container(
                          width: constrains.maxWidth,
                          height:constrains.maxWidth * 0.9,
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha:.1)),
                            color: Theme.of(context).highlightColor,
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.all( Radius.circular(10)),
                            child: Stack(
                              children: [
                                CustomImageWidget(
                                  image: '${product.thumbnailFullUrl?.path}',
                                  width: constrains.maxWidth,
                                  height:constrains.maxWidth * 0.9,
                                ),

                                if(product.currentStock! == 0 && product.productType == 'physical')...[
                                  Container(
                                    color: Colors.black.withValues(alpha:0.4),
                                  ),

                                  Positioned.fill(child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: constrains.maxWidth,
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
                          ),
                        ),



                        if(isCurrentIndex) ...[
                          ((product.discount! > 0) || (product.clearanceSale != null)) ?
                          DiscountTagWidget(productModel: product) : const SizedBox.shrink(),

                          Positioned.fill(child: Align(
                            alignment: isLtr ? Alignment.topRight : Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: Dimensions.paddingSizeSmall),
                              child: FavouriteButtonWidget(
                                backgroundColor: Provider.of<ThemeController>(context).darkTheme
                                  ? Theme.of(context).cardColor
                                  : Theme.of(context).primaryColor,
                                productId: product.id,
                              ),
                            ),
                          )),
                        ],

                      ]);
                    }
                ),
              ),


              if(isCurrentIndex ) Column(mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center, children: [

                   if((product.rating?.isNotEmpty ?? false)) Padding(padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [

                          Icon(Icons.star, color: Provider.of<ThemeController>(context).darkTheme ?
                          Colors.white : Colors.orange, size: 15),

                          Text(product.rating!.isNotEmpty ?
                          double.parse(product.rating![0].average!).toStringAsFixed(1) : '0.0',
                              style: textRegular.copyWith( fontSize: Dimensions.fontSizeSmall)),
                          const SizedBox(width: Dimensions.paddingSizeExtraExtraSmall),

                          Text('(${product.reviewCount.toString()})', style: textRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).hintColor,
                          ))])),


                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                      child: Text(product.name!, style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color), maxLines: 1,
                          overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),


                    Row( mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(((product.discount!= null && product.discount! > 0) || (product.clearanceSale?.discountAmount ?? 0) > 0) ?
                      PriceConverter.convertPrice(context, product.unitPrice) : '',
                        style: robotoBold.copyWith(color: Theme.of(context).hintColor,
                        decoration: TextDecoration.lineThrough, fontSize: Dimensions.fontSizeExtraSmall)),
                      const SizedBox(width: Dimensions.paddingSizeSmall),


                      Text(PriceConverter.convertPrice(context, product.unitPrice,
                        discountType: (product.clearanceSale?.discountAmount ?? 0)  > 0
                          ? product.clearanceSale?.discountType
                          : product.discountType,
                        discount: (product.clearanceSale?.discountAmount ?? 0)  > 0
                          ?  product.clearanceSale?.discountAmount
                          : product.discount,
                        ),
                        style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color)
                      )


                    ])])]),
          ),

        ]),
      ),
    );
  }
}




// Positioned(
//   top: Dimensions.paddingSizeDefault,
//   child: Container(
//     padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
//     alignment: Alignment.center,
//     decoration: BoxDecoration(
//       color: ColorResources.getPrimary(context),
//       borderRadius: BorderRadius.only(
//         topRight: isLtr ? const Radius.circular(5) : Radius.zero,
//         bottomRight: isLtr ? const Radius.circular(5) : Radius.zero,
//         topLeft: !isLtr ? const Radius.circular(5) : Radius.zero,
//         bottomLeft: !isLtr ? const Radius.circular(5) : Radius.zero,
//       ),
//     ),
//     child: Directionality(
//       textDirection: TextDirection.ltr,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
//         child: Text(
//           PriceConverter.percentageCalculation(context, product.unitPrice, product.discount, product.discountType),
//           style: textBold.copyWith(color: Theme.of(context).highlightColor, fontSize: Dimensions.fontSizeExtraSmall),
//         ),
//       ),
//     ),
//   ),
// ),