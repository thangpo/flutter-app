
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_directionality_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/controllers/product_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/domain/models/product_details_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/review/controllers/review_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/color_helper.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/helper/product_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/app_localization.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/rating_bar_widget.dart';
import 'package:provider/provider.dart';


class ProductTitleWidget extends StatelessWidget {
  final ProductDetailsModel? productModel;
  final String? averageRatting;
  const ProductTitleWidget({super.key, required this.productModel, this.averageRatting});

  @override
  Widget build(BuildContext context) {

    ({double? end, double? start})? priceRange = ProductHelper.getProductPriceRange(productModel);
    double? startingPrice = priceRange.start;
    double? endingPrice = priceRange.end;

    return productModel != null? Container(
      padding: const EdgeInsets.symmetric(horizontal : Dimensions.homePagePadding),
      child: Consumer<ProductDetailsController>(
        builder: (context, details, child) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            Text(
                productModel!.name ?? '',
                style: titleRegular.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color), maxLines: 2,
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              CustomDirectionalityWidget(
                child: Text('${startingPrice != null ?
                    PriceConverter.convertPrice(context, startingPrice,
                    discount: (productModel?.clearanceSale?.discountAmount ?? 0) > 0
                      ?  productModel?.clearanceSale?.discountAmount
                      : productModel?.discount,
                      discountType: (productModel?.clearanceSale?.discountAmount ?? 0)  > 0
                        ? productModel?.clearanceSale?.discountType
                        : productModel?.discountType):''}'

                    '${endingPrice !=null ? ' - ${PriceConverter.convertPrice(context, endingPrice,
                    discount: (productModel?.clearanceSale?.discountAmount ?? 0) > 0
                      ?  productModel?.clearanceSale?.discountAmount
                      : productModel?.discount,
                    discountType: (productModel?.clearanceSale?.discountAmount ?? 0)  > 0
                      ? productModel?.clearanceSale?.discountType
                      : productModel?.discountType)}' : ''}',

                    style: titilliumBold.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontSize: Dimensions.fontSizeLarge,
                    ),
                ),
              ),

              if((productModel!.discount != null && productModel!.discount! > 0) || (productModel!.clearanceSale != null && productModel!.clearanceSale!.discountAmount! > 0) )...[
                const SizedBox(width: Dimensions.paddingSizeSmall),

                CustomDirectionalityWidget(
                  child: Text('${PriceConverter.convertPrice(context, startingPrice)}'
                      '${endingPrice!= null ? ' - ${PriceConverter.convertPrice(context, endingPrice)}' : ''}',
                      style: titilliumRegular.copyWith(color: Theme.of(context).hintColor,
                          decoration: TextDecoration.lineThrough)),
                ),
              ],
            ]),
            const SizedBox(height: Dimensions.paddingSizeSmall),


            Row(children: [
               RatingBar(rating: productModel!.reviews != null ? productModel!.reviews!.isNotEmpty ?
               double.parse(averageRatting!) : 0.0 : 0.0),
              Text('(${productModel?.reviewsCount})')]),
            const SizedBox(height: Dimensions.paddingSizeSmall),



            Consumer<ReviewController>(
              builder: (context, reviewController, _) {
                return Row(children: [
                  Text.rich(TextSpan(children: [
                    TextSpan(
                      text: '${reviewController.reviewList != null ? reviewController.reviewList!.length : 0} ',
                      style: textMedium.copyWith(
                          color: Provider.of<ThemeController>(context, listen: false).darkTheme?
                          Theme.of(context).hintColor : Theme.of(context).primaryColor,
                          fontSize: Dimensions.fontSizeDefault,
                      ),
                    ),

                    TextSpan(
                        text: '${getTranslated('reviews', context)} | ',
                        style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                  ])),


                  Text.rich(TextSpan(children: [
                    TextSpan(text: '${details.orderCount} ', style: textMedium.copyWith(
                        color: Provider.of<ThemeController>(context, listen: false).darkTheme?
                        Theme.of(context).hintColor : Theme.of(context).primaryColor,
                        fontSize: Dimensions.fontSizeDefault,
                    )),

                    TextSpan(text: '${getTranslated('orders', context)} | ',
                        style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                  ])),

                  Text.rich(TextSpan(children: [
                    TextSpan(text: '${details.wishCount} ', style: textMedium.copyWith(
                        color: Provider.of<ThemeController>(context, listen: false).darkTheme?
                        Theme.of(context).hintColor : Theme.of(context).primaryColor,
                        fontSize: Dimensions.fontSizeDefault,
                    )),

                    TextSpan(
                        text: '${getTranslated('wish_listed', context)}',
                        style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                  ])),
                ]);
              }),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            if(_isVariationAvailable()) ...[
              Text(
                '${getTranslated('available', context)}',
                style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
            ],

            /// Available color
            productModel!.colors != null && productModel!.colors!.isNotEmpty ?
            Row(children: [

              Text('${getTranslated('color', context)} : ', style: titilliumRegular.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              )),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),

              Expanded(child: SizedBox(height: Dimensions.paddingSizeLarge, child: ListView.separated(
                itemCount: productModel!.colors!.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return Center(child: Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)),
                      child: Container(
                        width: Dimensions.marginSizeAuthSmall,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ColorHelper.hexCodeToColor(productModel?.colors?[index].code),
                          borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraExtraSmall)
                        ),
                      ),
                  ));
                },
                separatorBuilder: (BuildContext context, int index) => const SizedBox(width: Dimensions.paddingSizeDefaultAddress),
              ))),
            ]) : const SizedBox(),

            productModel!.colors != null &&  productModel!.colors!.isNotEmpty ?
            const SizedBox(height: Dimensions.paddingSizeSmall) : const SizedBox(),

            productModel!.choiceOptions != null && productModel!.choiceOptions!.isNotEmpty ?
            ListView.builder(
              shrinkWrap: true,
              itemCount: productModel!.choiceOptions!.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Text('${productModel!.choiceOptions![index].title?.toCapitalized()} : ', style: titilliumRegular.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    )),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                    Expanded(child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                      child: SizedBox(height: Dimensions.paddingSizeExtraLarge, child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: productModel!.choiceOptions![index].options!.length,
                        itemBuilder: (context, i) {
                          return Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                              vertical: Dimensions.paddingSizeExtraExtraSmall,
                              horizontal: Dimensions.paddingSizeSmall
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).hintColor.withValues(alpha: 0.125),
                              borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraExtraSmall),
                            ),
                            child: Text(
                                productModel!.choiceOptions![index].options![i].trim(),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: textRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) => const SizedBox(width: Dimensions.paddingSizeDefaultAddress),
                      )),
                    )),

                  ],
                );
              },
            ) : const SizedBox(),
          ]);
        },
      ),
    ) : const SizedBox();
  }

  bool _isVariationAvailable() => ((productModel!.colors != null && productModel!.colors!.isNotEmpty) && productModel!.choiceOptions != null && productModel!.choiceOptions!.isNotEmpty);
}


