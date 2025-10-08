import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_loader_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/screens/product_details_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/restock/controllers/restock_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/restock/domain/models/restock_product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';

import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

class RestockListItemWidget extends StatelessWidget {
  final Product? product;
  final double? ratting;
  final Data? data;
  final int index;
  const RestockListItemWidget({super.key, this.product, this.ratting, this.data, required this.index});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      InkWell(
        onTap: () {
          Navigator.push(context, PageRouteBuilder(transitionDuration: const Duration(milliseconds: 1000),
              pageBuilder: (context, anim1, anim2) => ProductDetails(productId: product?.id,
                  slug: product?.slug)),
          );
        },

        child: Padding(
          padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, 0),
          child: Container(padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(color: Theme.of(context).highlightColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha:0.15), width: .75)
            ),

            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stack(children: [

                Container(decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                    border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha:.10),width: 0.5)),
                    child: ClipRRect(borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                        child: CustomImageWidget(image: product?.thumbnailFullUrl?.path ?? '', height: 80, width: 80))
                ),


                product!.discount! > 0 ?
                Positioned(top: 0, left: 0, child: Container(
                    transform: Matrix4.translationValues(-1, 0, 0),
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 3),
                    decoration: BoxDecoration(color: Theme.of(context).primaryColor,
                      borderRadius: const BorderRadius.only(topRight: Radius.circular(Dimensions.paddingSizeExtraSmall),
                          bottomRight: Radius.circular(Dimensions.paddingSizeExtraSmall)),),

                    child: Center(
                        child: Directionality(textDirection: TextDirection.ltr,
                          child: Text(PriceConverter.percentageCalculation(context, product?.unitPrice,
                              product?.discount, product?.discountType),
                            style: textBold.copyWith(color: Colors.white,
                                fontSize: Dimensions.fontSizeExtraSmall), textAlign: TextAlign.center,),
                        )))
                ) : const SizedBox(),




              ],
              ),

              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  if(ratting! > 0)
                    Row(
                      children: [
                        const Icon(Icons.star_rate_rounded, color: Colors.orange,size: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: Text(ratting!.toStringAsFixed(1), style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color,)),
                        ),

                        Text('(${product?.reviewCount.toString()})',
                            style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)
                        )
                      ],
                    ),

                  if(ratting! > 0)
                    const SizedBox(height: Dimensions.paddingSizeSmall),



                  Row(
                    children: [
                      Flexible(
                        child: Text(product?.name ?? '', maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textBold.copyWith(fontWeight: FontWeight.w500, fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color)
                        ),
                      ),
                    ],
                  ),




                  // variation
                  (data?.variant != null && data!.variant!.isNotEmpty) ?
                  Padding(padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                    child: Row(children: [
                      Text('${getTranslated('variant', context)!} : ',
                          style: textMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color,)
                      ),

                      Text(data?.variant ??'',maxLines: 1,overflow: TextOverflow.ellipsis,
                        style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault,
                            color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                    ]),
                  ) : const SizedBox(),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),


                  // Price
                  Row(children: [
                    Text(PriceConverter.convertPrice(context,
                        product?.unitPrice, discountType: product?.discountType,
                        discount: product?.discount),
                        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)
                    ),
                    const SizedBox(width: 2),

                    product?.discount!= null && product!.discount! > 0 ?
                    Text(PriceConverter.convertPrice(context, product?.unitPrice),
                        style: titleRegular.copyWith(color: Theme.of(context).hintColor,
                            decoration: TextDecoration.lineThrough, fontSize: Dimensions.fontSizeSmall)
                    )
                        : const SizedBox.shrink(),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ),

      Positioned(
          top: 7, right: 7,
          child: InkWell(
            onTap: () async {
              showDialog(context: context, builder: (ctx)  => const CustomLoaderWidget());
              await Provider.of<RestockController>(context, listen: false).deleteRestockProduct(data!.id.toString(), '', index);
              Navigator.of(Get.context!).pop();
            },
            child: Container(
              height: 20, width: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.error,
              ),
              child: Center(
                child: Icon(Icons.close, color: Theme.of(context).cardColor, weight: 15, size: 15),
              ),
            ),
          )
      ),
    ]);
  }
}
