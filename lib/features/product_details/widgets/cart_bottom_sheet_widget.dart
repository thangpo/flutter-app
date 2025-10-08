

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_directionality_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/not_logged_in_bottom_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/screens/checkout_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/widgets/color_selection_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/controllers/product_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/domain/models/product_details_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/widgets/min_order_quanty_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/widgets/shipping_method_dialog.dart';
import 'package:flutter_sixvalley_ecommerce/features/shipping/domain/models/shipping_method_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/helper/product_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:provider/provider.dart';


class CartBottomSheetWidget extends StatefulWidget {
  final ProductDetailsModel? product;
  final Function? callback;
  const CartBottomSheetWidget({super.key, required this.product, this.callback});

  @override
  CartBottomSheetWidgetState createState() => CartBottomSheetWidgetState();
}

class CartBottomSheetWidgetState extends State<CartBottomSheetWidget> {

  @override
  void initState() {
    Provider.of<ProductDetailsController>(context, listen: false).initData(widget.product!, 1, context);
    Provider.of<ProductDetailsController>(context, listen: false).initDigitalVariationIndex();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ({double? end, double? start})? priceRange = ProductHelper.getProductPriceRange(widget.product);
    double? startingPrice = priceRange.start;
    double? endingPrice = priceRange.end;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.only(top : Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(color: Theme.of(context).highlightColor,
            borderRadius: const BorderRadius.only(topRight: Radius.circular(20), topLeft: Radius.circular(20))),
        child: Consumer<ProductDetailsController>(
          builder: (ctx, productDetailsController, child) {
            List<String> variationFileType = [];
            List<List<String>> extensions = [];
            String? variantKey;
            double? digitalVariantPrice;
            String? colorWiseSelectedImage = '';
            bool variationRestockRequested = false;


            if(widget.product != null && widget.product!.colorImagesFullUrl != null && widget.product!.colorImagesFullUrl!.isNotEmpty){
              for(int i=0; i< widget.product!.colorImagesFullUrl!.length; i++){
                if(widget.product!.colorImagesFullUrl![i].color == '${widget.product!.colors?[productDetailsController.variantIndex??0].code?.substring(1, 7)}'){
                  colorWiseSelectedImage = widget.product!.colorImagesFullUrl![i].imageName?.path;
                }
              }
            }



            Variation? variation;
            String? variantName = (widget.product!.colors != null && widget.product!.colors!.isNotEmpty) ?
            widget.product!.colors![productDetailsController.variantIndex!].name : null;
            List<String> variationList = [];
            for(int index=0; index < widget.product!.choiceOptions!.length; index++) {
              variationList.add(widget.product!.choiceOptions![index].options![productDetailsController.variationIndex![index]].trim());

            }
            String variationType = '';
            if(variantName != null) {
              variationType = variantName;
              for (var variation in variationList) {
                variationType = '$variationType-$variation';
              }
            }else {
              bool isFirst = true;
              for (var variation in variationList) {
                if(isFirst) {
                  variationType = '$variationType$variation';
                  isFirst = false;
                }else {
                  variationType = '$variationType-$variation';
                }
              }
            }

            if(widget.product?.digitalProductExtensions != null){
              widget.product?.digitalProductExtensions?.keys.forEach((key) {
                variationFileType.add(key);
                extensions.add(widget.product?.digitalProductExtensions?[key]);
              }
              );
            }

            double? price = widget.product!.unitPrice;
            int? stock = widget.product!.currentStock;
            variationType = variationType.replaceAll(' ', '');
            for(Variation variation in widget.product!.variation!) {
              if(variation.type == variationType) {
                price = variation.price;
                variation = variation;
                stock = variation.qty;
                break;
              }
            }

            if(variationFileType.isNotEmpty && extensions.isNotEmpty) {
              variantKey = '${variationFileType[productDetailsController.digitalVariationIndex!]}-${extensions[productDetailsController.digitalVariationIndex!][productDetailsController.digitalVariationSubindex!]}';
              for (int i=0; i<widget.product!.digitalVariation!.length; i++) {
                if(widget.product!.digitalVariation?[i].variantKey == variantKey){
                  price = double.tryParse(widget.product!.digitalVariation![i].price.toString());
                }
              }
            }
            digitalVariantPrice = variantKey != null ? price : null;

            double priceWithDiscount = PriceConverter.convertWithDiscount(context,
                price,
                (widget.product?.clearanceSale?.discountAmount ?? 0) > 0 ?
                widget.product?.clearanceSale?.discountAmount :
                widget.product!.discount,

                (widget.product?.clearanceSale?.discountAmount ?? 0) > 0 ?
                widget.product?.clearanceSale?.discountType :
                widget.product!.discountType
            )!;

            double priceWithQuantity = priceWithDiscount * productDetailsController.quantity!;

            double total = 0, avg = 0;
            for (var review in widget.product!.reviews!) {
              total += review.rating!;
            }
            avg = total /widget.product!.reviews!.length;
            String ratting = widget.product!.reviews != null && widget.product!.reviews!.isNotEmpty?
            avg.toString() : "0";

            CartModelBody cart = CartModelBody(
                productId: widget.product!.id,
                variant: (widget.product!.colors != null && widget.product!.colors!.isNotEmpty) ?
                widget.product!.colors![productDetailsController.variantIndex!].name : '',
                color: (widget.product!.colors != null && widget.product!.colors!.isNotEmpty) ?
                widget.product!.colors![productDetailsController.variantIndex!].code : '',
                variation : variation,
                quantity: productDetailsController.quantity,
                variantKey: variantKey,
                digitalVariantPrice: digitalVariantPrice
            );


            if(widget.product?.productType == 'physical' && widget.product?.variation != null
                && widget.product!.variation!.isNotEmpty && widget.product?.isRestockRequested == 1) {
              variationRestockRequested = widget.product!.restockRequestedList!.contains(variationType);
            } else {
              variationRestockRequested = false;
            }


            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              Align(alignment: Alignment.centerRight, child: InkWell(
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                  child: Icon(Icons.cancel, color: Theme.of(context).hintColor, size: 30),
                ),
              )),

              // Product details
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.homePagePadding),
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(children: [
                        Stack(children: [

                          Container(width: 100, height: 100,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(5),
                              border: Border.all(width: .5,color: Theme.of(context).primaryColor.withValues(alpha:.20))),
                            child: ClipRRect(borderRadius: BorderRadius.circular(5),
                              child: CustomImageWidget(image: (widget.product!.colors != null && widget.product!.colors!.isNotEmpty &&
                                  widget.product!.imagesFullUrl != null && widget.product!.imagesFullUrl!.isNotEmpty) ?
                              '$colorWiseSelectedImage':
                              '${widget.product!.thumbnailFullUrl?.path}'))
                          ),

                          widget.product!.discount! > 0 ?
                          Container(width: 100,
                            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color:Theme.of(context).colorScheme.primary,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.paddingSizeExtraSmall))),
                            child: Padding(padding: const EdgeInsets.all(5),
                              child: CustomDirectionalityWidget(
                                child: Text(PriceConverter.percentageCalculation(context,
                                  widget.product!.unitPrice,
                                  (widget.product?.clearanceSale?.discountAmount ?? 0) > 0 ?
                                  widget.product?.clearanceSale?.discountAmount :
                                  widget.product!.discount,
                                  (widget.product?.clearanceSale?.discountAmount ?? 0) > 0 ?
                                  widget.product?.clearanceSale?.discountType :
                                  widget.product!.discountType),
                                  style: titilliumRegular.copyWith(color: const Color(0xFFFFFFFF),
                                    fontSize: Dimensions.fontSizeDefault)),
                              )),
                          ) : const SizedBox(width: 93)
                        ]),
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        if(widget.product!.productType != "digital") Text(
                          '$stock ${getTranslated('in_stock', context)}',
                          style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color), maxLines: 1,
                        ),

                      ]),
                      const SizedBox(width: Dimensions.paddingSizeLarge),

                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.product!.name ?? '',
                              style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: Dimensions.paddingSizeSmall),

                          Row(children: [
                            Icon(Icons.star_rate_rounded, color: Theme.of(context).colorScheme.tertiary),

                            Text(
                              double.parse(ratting).toStringAsFixed(1),
                              style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                          ]),
                          const SizedBox(height:  Dimensions.paddingSizeSmall),

                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                            CustomDirectionalityWidget(
                              child: Text('${startingPrice != null ? PriceConverter.convertPrice(
                                context, startingPrice,
                                discount: (widget.product?.clearanceSale?.discountAmount ?? 0) > 0
                                    ? widget.product?.clearanceSale?.discountAmount
                                    : widget.product?.discount,
                                discountType: (widget.product?.clearanceSale?.discountAmount ?? 0) > 0
                                    ? widget.product?.clearanceSale?.discountType
                                    : widget.product?.discountType,
                              ):''}' '${endingPrice !=null ? ' - ${PriceConverter.convertPrice(
                                context, endingPrice,
                                discount: (widget.product?.clearanceSale?.discountAmount ?? 0) > 0
                                    ? widget.product?.clearanceSale?.discountAmount
                                    : widget.product?.discount,
                                discountType: widget.product?.discountType,
                              )}' : ''}', style: titilliumRegular.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontSize: Dimensions.fontSizeExtraLarge,
                              )),
                            ),

                            (widget.product?.discount != null && (widget.product?.discount ?? 0) > 0) || (widget.product?.clearanceSale?.discountAmount ?? 0) > 0 ?
                            CustomDirectionalityWidget(
                              child: Text('${PriceConverter.convertPrice(context, startingPrice)}'
                                  '${endingPrice!= null ? ' - ${PriceConverter.convertPrice(context, endingPrice)}' : ''}',
                                  style: titilliumRegular.copyWith(color: Theme.of(context).hintColor,
                                      decoration: TextDecoration.lineThrough)),
                            ) : const SizedBox(),

                          ]),
                        ],
                      )),
                    ],
                  ),
                ]),
              ),


              const SizedBox(height: Dimensions.paddingSizeDefault),

              (widget.product!.colors != null && widget.product!.colors!.isNotEmpty) ?
              ColorSelectionWidget(product: widget.product!, detailsController: productDetailsController) : const SizedBox(),



              (widget.product!.colors != null && widget.product!.colors!.isNotEmpty) ?
              const SizedBox(height: Dimensions.paddingSizeSmall) : const SizedBox(),


              // Variation
              Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.homePagePadding),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.product!.choiceOptions!.length,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (ctx, index) {
                    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Text('${getTranslated('available', context)}  ${widget.product!.choiceOptions![index].title} : ',
                          style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeDefault)),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),


                      Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: SizedBox(height: 40,
                          child: RepaintBoundary(
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.product!.choiceOptions![index].options!.length,
                              itemBuilder: (ctx, i) {
                                return Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                                  child: InkWell(onTap: () => productDetailsController.setCartVariationIndex(1, index, i, context),
                                    child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(5),
                                        color: productDetailsController.variationIndex![index] == i?
                                        Theme.of(context).primaryColor: Theme.of(context).colorScheme.onTertiary),
                                      child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(5),
                                          border: Border.all(width: 2,color: productDetailsController.variationIndex![index] == i?
                                          Theme.of(context).cardColor: const Color(0x00FFFFFF))),
                                        child: Padding(padding: const EdgeInsets.symmetric(horizontal : Dimensions.paddingSizeDefault),
                                          child: Center(child: Text(widget.product!.choiceOptions![index].options![i].trim(), maxLines: 1,
                                              overflow: TextOverflow.ellipsis, style: titilliumRegular.copyWith(
                                                  fontSize: Dimensions.fontSizeDefault,
                                                  color: (productDetailsController.variationIndex![index] != i &&
                                                      !Provider.of<ThemeController>(context, listen: false).darkTheme) ?
                                                  Theme.of(context).primaryColor :  const Color(0xFFFFFFFF)))),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      ),
                    ]);
                  },
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall,),


              // Digital Product Variation
              variationFileType.isNotEmpty ?
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.homePagePadding),
                child: RepaintBoundary(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: variationFileType.length,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (ctx, index) {
                      return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        Text('${variationFileType[index][0].toUpperCase() + variationFileType[index].substring(1)} : ',
                            style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeDefault)),
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        Expanded(
                          child: Padding(padding: const EdgeInsets.all(2.0),
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 5,
                                mainAxisSpacing: 5,
                                childAspectRatio: (1 / .5),
                              ),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: extensions[index].length,
                              itemBuilder: (ctx, i) {
                                bool isSelect = (productDetailsController.digitalVariationIndex == index && productDetailsController.digitalVariationSubindex == i);
                                return InkWell(
                                  splashColor: Colors.transparent,
                                  onTap: () => productDetailsController.setDigitalVariationIndex(widget.product!.minimumOrderQty, index, i, context),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelect ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withValues(alpha:0.10),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Center(
                                      child: Text(extensions[index][i].trim(), maxLines: 1,
                                          overflow: TextOverflow.ellipsis, style: titilliumRegular.copyWith(
                                            fontSize: Dimensions.fontSizeDefault,
                                            color: isSelect ?  Colors.white : Theme.of(context).primaryColor.withValues(alpha:0.85),
                                          )),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ]);
                    },
                  ),
                ),
              ) : const SizedBox(),
              variationFileType.isNotEmpty ? const SizedBox(height: Dimensions.paddingSizeSmall) : const SizedBox(),


              // Quantity
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.homePagePadding),
                child: Row(children: [
                  Text(getTranslated('quantity', context)!, style: textMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(width: Dimensions.paddingSizeSmall),

                  QuantityButton(
                    isIncrement: false,
                    quantity: productDetailsController.quantity,
                    stock: stock,
                    minimumOrderQuantity: widget.product!.minimumOrderQty,
                    digitalProduct: widget.product!.productType == "digital",
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                    child: Text(productDetailsController.quantity.toString(), style: textMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
                  ),

                  QuantityButton(
                    isIncrement: true,
                    quantity: productDetailsController.quantity,
                    stock: stock,
                    minimumOrderQuantity: widget.product!.minimumOrderQty,
                    digitalProduct: widget.product!.productType == "digital",
                  ),
                ]),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),


              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.homePagePadding),
                child: MinOrderQuantityWidget(minOrderQty: widget.product?.minimumOrderQty),
              ),


              Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [

                    Text(getTranslated('total_price', context)!, style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    CustomDirectionalityWidget(
                      child: Text(PriceConverter.convertPrice(context, priceWithQuantity),
                          style: titilliumBold.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: Dimensions.fontSizeLarge)),
                    ),
                    widget.product!.taxModel == 'exclude' ?
                    Padding(
                      padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                      child: Row(
                        children: [
                          Text('(', style: titilliumRegular.copyWith(
                            color: Theme.of(context).hintColor,
                            fontSize: Dimensions.fontSizeDefault,
                          )),

                          Text('${getTranslated('tax', context)} : ', style: titilliumRegular.copyWith(
                            color: Theme.of(context).hintColor,
                            fontSize: Dimensions.fontSizeDefault,
                          )),

                          CustomDirectionalityWidget(
                            child: Text('${widget.product?.tax}%', style: titilliumRegular.copyWith(
                              color: Theme.of(context).hintColor,
                              fontSize: Dimensions.fontSizeDefault,
                            )),
                          ),

                          Text(')', style: titilliumRegular.copyWith(
                            color: Theme.of(context).hintColor,
                            fontSize: Dimensions.fontSizeDefault,
                          )),
                        ],
                      ),

                    ):
                    Padding(padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                        child: Text('(${getTranslated('tax', context)} ${widget.product?.tax})',
                            style: titilliumRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeDefault)))])),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              (stock! <= 0 && widget.product!.productType == "physical") ?  Provider.of<AuthController>(context, listen: false).isLoggedIn() ?
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
                child: CustomButton(
                  isLoading: Provider.of<CartController>(context).addToCartLoading,
                  backgroundColor: Colors.white,
                  textColor: Theme.of(context).primaryColor,
                  isBorder: true,
                  borderColor: Theme.of(context).primaryColor,
                  loadingColor : Theme.of(context).primaryColor,
                  radius: Dimensions.radiusDefault,
                  buttonText: ((widget.product!.choiceOptions!.isEmpty && widget.product!.colors!.isEmpty) ? widget.product!.isRestockRequested == 1 : variationRestockRequested) ?
                  getTranslated('restock_requested', context) : getTranslated('request_restock', context),
                  onTap: ((widget.product!.choiceOptions!.isEmpty && widget.product!.colors!.isEmpty) ? widget.product!.isRestockRequested == 1 : variationRestockRequested) ? null : () {
                    Provider.of<CartController>(context, listen: false).restockRequest(
                        cart, context, widget.product!.choiceOptions!, productDetailsController.variationIndex, variationType: variationType);
                  },
                ),
              ) :

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
                child: CustomButton(
                  textColor: Colors.white,
                  buttonText: getTranslated('request_restock', context),
                  onTap: () {
                    Navigator.of(context).pop();
                    showCustomSnackBar(getTranslated('to_request_the_restock', Get.context!), Get.context!);
                  },
                ),
              ) :
              Provider.of<CartController>(context).addToCartLoading ? const Center(child: Padding(padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator())):

              Container(color: Theme.of(context).colorScheme.onTertiary,
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.homePagePadding,
                    vertical: Dimensions.paddingSizeSmall),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [


                    Expanded(child: Consumer<SplashController>(builder: (context, configProvider,_) {
                      return CustomButton(
                        isBuy:true, radius: 6,
                        buttonText: getTranslated(stock == 0  && widget.product!.productType == "physical" ? 'out_of_stock' : 'buy_now', context),
                        onTap:() async {
                          final bool isLoggedIn = Provider.of<AuthController>(context, listen: false).isLoggedIn();

                          if(configProvider.configModel?.guestCheckOut == 0 && !isLoggedIn){
                            showModalBottomSheet(
                              backgroundColor: Colors.transparent,
                              context:context, builder: (_)=> const NotLoggedInBottomSheetWidget(),
                            );

                          }else if( stock! < widget.product!.minimumOrderQty!  &&  widget.product!.productType == "physical" ){
                            showCustomSnackBar(getTranslated('out_of_stock', context), context);

                          } else if(stock >= widget.product!.minimumOrderQty! || widget.product!.productType == "digital") {
                            final ApiResponseModel apiResponse = await  Provider.of<CartController>(context, listen: false).addToCartAPI(
                              cart, context, widget.product!.choiceOptions!,
                              productDetailsController.variationIndex, buyNow: 1,
                            );

                            if(apiResponse.response?.statusCode == 200){
                              _onTapBuyNow(cart, Get.context!, widget.product!.choiceOptions!, productDetailsController.variationIndex, apiResponse.response);

                            }}},
                      );
                    })),
                    const SizedBox(width: Dimensions.paddingSizeDefault),

                    Expanded(child: CustomButton(
                      radius: 6,
                      buttonText: getTranslated(stock == 0 && widget.product!.productType == "physical"? 'out_of_stock' : 'add_to_cart', context),
                      onTap: () {

                        if((productDetailsController.quantity ?? 0) < (widget.product?.minimumOrderQty ?? 1) ) {
                          showCustomSnackBar('${getTranslated('to_order_this_item_minimum_order_quantity_is', context)} ${widget.product?.minimumOrderQty}', context);
                          return;
                        }

                        if( stock! < widget.product!.minimumOrderQty!  &&  widget.product!.productType == "physical" ){
                          showCustomSnackBar(getTranslated('out_of_stock', context), context);

                        } else if(stock >= widget.product!.minimumOrderQty!  || widget.product!.productType == "digital") {
                          Provider.of<CartController>(context, listen: false).addToCartAPI(
                            cart, context, widget.product!.choiceOptions!,
                            productDetailsController.variationIndex,
                          );
                        }},
                    )),
                  ]),
                ),
              ),
            ]);
          },
        ),
      ),
    ]);
  }

  void _onTapBuyNow(CartModelBody cart, BuildContext context, List<ChoiceOptions> choices, List<int>? variationIndexes, Response<dynamic>? response) {
    if(_isSelectShippingMethod(response)){
      List<ShippingMethodModel>? shippingMethodList = [];

      response?.data['shipping_method_list'].forEach((element) {
        shippingMethodList.add(ShippingMethodModel.fromJson(element));
      });

      showDialog(context: Get.context!, builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ChooseShippingMethodDialog(shippingMethodList, cart, choices, variationIndexes, _navigateToCheckoutScreen),
      ));

    } else {
      CartModel cart = CartModel.fromJson(response?.data['cart']);
      _navigateToCheckoutScreen(context, cart, 0);
    }
  }

  bool _isSelectShippingMethod(Response<dynamic>? response) => response?.data['status'] == 2;

  void _navigateToCheckoutScreen(BuildContext context, CartModel cart, double shippingCost) {
    final double discount = cart.discount! * cart.quantity!;
    final double amount = (cart.price! - cart.discount!) * cart.quantity!;
    final int totalQuantity = cart.quantity ?? 0;
    final bool hasPhysical = cart.productType == "physical";
    double tax = 0.0;
    double shippingAmount = (shippingCost + cart.shippingCost!);

    if(cart.taxModel == "exclude") {
      tax += cart.tax! * cart.quantity!;
    }

    if(cart.freeDeliveryOrderAmount != null  ){
      shippingAmount = shippingAmount - cart.freeDeliveryOrderAmount!.shippingCostSaved!;
    }

    Navigator.of(Get.context!).push(MaterialPageRoute(
        builder: (context) => CheckoutScreen(
            cartList: [cart],
            discount: discount,
            tax: tax,
            totalOrderAmount: amount,
            shippingFee: shippingAmount,
            quantity: totalQuantity,
            onlyDigital: !hasPhysical,
            hasPhysical: hasPhysical
        )
    )
    );
  }


}


class QuantityButton extends StatelessWidget {
  final bool isIncrement;
  final int? quantity;
  final bool isCartWidget;
  final int? stock;
  final int? minimumOrderQuantity;
  final bool digitalProduct;

  const QuantityButton({super.key,
    required this.isIncrement,
    required this.quantity,
    required this.stock,
    this.isCartWidget = false,required this.minimumOrderQuantity,required this.digitalProduct,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (!isIncrement && quantity! > 1 ) {
          if(quantity! > minimumOrderQuantity! ) {
            Provider.of<ProductDetailsController>(context, listen: false).setQuantity(quantity! - 1);
          }else{
            showCustomSnackBar('${getTranslated('minimum_quantity_is', context)}$minimumOrderQuantity', context, isToaster: true);
          }
        }else if(isIncrement && quantity! >= stock! && !digitalProduct) {
          showCustomSnackBar(getTranslated('out_of_stock', context), context, isToaster: true);

        } else if (isIncrement && quantity! < stock! || digitalProduct) {
          Provider.of<ProductDetailsController>(context, listen: false).setQuantity(quantity! + 1);
        }

      },
      child: Container(width: 40,height: 40,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(width: 1, color: Theme.of(context).primaryColor)),
        child: Icon(isIncrement ? Icons.add : Icons.remove,
          color: isIncrement ? quantity! >= stock! && !digitalProduct?
          Provider.of<ThemeController>(context).darkTheme ?
          Theme.of(context).cardColor.withValues(alpha: 0.50) :
          Theme.of(context).disabledColor :
          Theme.of(context).textTheme.bodyMedium?.color

              : quantity! > 1
              ? Theme.of(context).textTheme.bodyMedium?.color
              : Theme.of(context).textTheme.bodyLarge?.color,
          size: isCartWidget?26:20,
        ),
      ),
    );
  }
}


