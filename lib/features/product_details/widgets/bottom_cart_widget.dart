import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/domain/models/product_details_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/widgets/cart_bottom_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/responsive_helper.dart';
import 'package:flutter_sixvalley_ecommerce/helper/shop_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/screens/cart_screen.dart';
import 'package:provider/provider.dart';

class BottomCartWidget extends StatefulWidget {
  final ProductDetailsModel? product;
  const BottomCartWidget({super.key, required this.product});

  @override
  State<BottomCartWidget> createState() => _BottomCartWidgetState();
}

class _BottomCartWidgetState extends State<BottomCartWidget> {
  bool vacationIsOn = false;
  bool temporaryClose = false;

  @override
  void initState() {
    super.initState();

    vacationIsOn = ShopHelper.isVacationActive(
      context,
      startDate: widget.product?.seller?.shop?.vacationStartDate,
      endDate: widget.product?.seller?.shop?.vacationEndDate,
      vacationDurationType: widget.product?.seller?.shop?.vacationDurationType,
      vacationStatus: widget.product?.seller?.shop?.vacationStatus,
      isInHouseSeller: widget.product?.addedBy == 'admin',
    );


    if(widget.product?.addedBy == 'admin') {
      if(widget.product != null && (Provider.of<SplashController>(context, listen: false).configModel?.inhouseTemporaryClose?.status ?? false)){
        temporaryClose = true;
      }else{
        temporaryClose = false;
      }
    } else {
      if(widget.product != null && widget.product!.seller != null && widget.product!.seller!.shop!.temporaryClose!){
        temporaryClose = true;
      }else{
        temporaryClose = false;
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(height: 70,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(color: Theme.of(context).highlightColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
        boxShadow: [BoxShadow(color: Theme.of(context).hintColor, blurRadius: .5, spreadRadius: .1)]),
      child: Row(children: [
        Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
          child: Stack(children: [
            InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context)=>const CartScreen())),
              child: Image.asset(Images.cartArrowDownImage, color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            Positioned.fill(
              child: Container(
                transform: Matrix4.translationValues(10, -3, 0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Consumer<CartController>(builder: (context, cart, child) {
                    return Container(height: ResponsiveHelper.isTab(context)? 25 : 20, width: ResponsiveHelper.isTab(context)? 25 : 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).textTheme.bodyMedium?.color),
                      child: Center(
                        child: Text(cart.cartList.length.toString(),
                          style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall,
                              color:Theme.of(context).highlightColor)),
                      ),
                    );}),
                ),
              ))])),
        const SizedBox(width: Dimensions.paddingSizeDefaultAddress),

        Expanded(child: InkWell(onTap: () {
            if(vacationIsOn || temporaryClose ) {
              showCustomSnackBar(getTranslated('this_shop_is_close_now', context), context, isToaster: true);
            }else{
              showModalBottomSheet(context: context, isScrollControlled: true,
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha:0),
                builder: (con) => CartBottomSheetWidget(product: widget.product, callback: (){
                  showCustomSnackBar(getTranslated('added_to_cart', context), context, isError: false);
                },)
              );
            }},
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
            alignment: Alignment.center,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).primaryColor),
            child: Text(getTranslated('add_to_cart', context)!,
              style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge,
                  color: Provider.of<ThemeController>(context, listen: false).darkTheme?
                  Theme.of(context).hintColor : Theme.of(context).highlightColor),),
          ),
        )),
      ]),
    );
  }
}
