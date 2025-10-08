import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_loader_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/domain/models/cart_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/shipping/controllers/shipping_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/screens/shop_screen.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/helper/shop_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/not_logged_in_bottom_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/widgets/cart_page_shimmer_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/widgets/cart_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/screens/checkout_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/shipping/widgets/shipping_method_bottom_sheet_widget.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatefulWidget {
  final bool fromCheckout;
  final int sellerId;
  final bool showBackButton;
  const CartScreen({super.key, this.fromCheckout = false, this.sellerId = 1, this.showBackButton = true});

  @override
  CartScreenState createState() => CartScreenState();
}

class CartScreenState extends State<CartScreen> {
  Future<void> _loadData() async{
    await Provider.of<CartController>(Get.context!, listen: false).getCartData(Get.context!);
     Provider.of<CartController>(Get.context!, listen: false).setCartData();
      if( Provider.of<SplashController>(Get.context!,listen: false).configModel!.shippingMethod != 'sellerwise_shipping'){
        Provider.of<ShippingController>(Get.context!, listen: false).getAdminShippingMethodList(Get.context!);
      }
  }

  Color _currentColor = Theme.of(Get.context!).cardColor; // Initial color
  final Duration duration = const Duration(milliseconds: 500);
  void changeColor() {
    setState(() {
      _currentColor = (_currentColor == Theme.of(Get.context!).cardColor) ? Colors.grey.withValues(alpha:.15) : Theme.of(Get.context!).cardColor;
      Future.delayed(const Duration(milliseconds: 500)).then((value){
        reBackColor();
      });
    });
  }

  void reBackColor() {
    setState(() {
      _currentColor = (_currentColor == Theme.of(Get.context!).cardColor) ? Colors.grey.withValues(alpha:.15) : Theme.of(Get.context!).cardColor;
    });
  }


  @override
  void initState() {
    _loadData();
    super.initState();
  }
  final tooltipController = JustTheController();

  @override
  Widget build(BuildContext context) {
    return Consumer<SplashController>(
      builder: (context, configProvider,_) {
        return Consumer<ShippingController>(
          builder: (context, shippingController,_) {
            return Consumer<CartController>(builder: (context, cart, child) {
              double amount = 0.0;
              double shippingAmount = 0.0;
              double discount = 0.0;
              double tax = 0.0;
              int totalQuantity = 0;
              int totalPhysical = 0;
              bool onlyDigital= true;
              List<CartModel> cartList = [];
              cartList.addAll(cart.cartList);
              bool isItemChecked = false;

              for(CartModel cart in cartList) {
                if(cart.productType == "physical" && cart.isChecked!) {
                  onlyDigital = false;
                }
              }

              List<String?> orderTypeShipping = [];
              List<String?> sellerList = [];
              List<List<String>> productType = [];
              List<CartModel> sellerGroupList = [];
              List<List<CartModel>> cartProductList = [];
              List<List<int>> cartProductIndexList = [];

              for(CartModel cart in cartList) {
                if(cart.isChecked! && !isItemChecked) {
                  isItemChecked = true;
                }
                if(!sellerList.contains(cart.cartGroupId)) {
                  sellerList.add(cart.cartGroupId);
                  cart.isGroupChecked = false;
                  sellerGroupList.add(cart);
                }
              }

              for(CartModel? seller in sellerGroupList) {
                List<CartModel> cartLists = [];
                List<int> indexList = [];
                List<String> productTypeList = [];
                bool isSellerChecked = true;
                for(CartModel cart in cartList) {
                  if(seller?.cartGroupId == cart.cartGroupId) {
                    cartLists.add(cart);
                    indexList.add(cartList.indexOf(cart));
                    productTypeList.add(cart.productType!);
                    if(!cart.isChecked!){
                      isSellerChecked = false;
                    } else if (cart.isChecked!) {
                      seller?.isGroupItemChecked = true;
                    }
                  }
                }

                cartProductList.add(cartLists);
                productType.add(productTypeList);
                cartProductIndexList.add(indexList);
                if(isSellerChecked){
                  seller?.isGroupChecked = true;
                }
              }

              double freeDeliveryAmountDiscount = 0;
              for (var seller in sellerGroupList) {
                if(seller.freeDeliveryOrderAmount?.status == 1 && seller.isGroupItemChecked!){
                  freeDeliveryAmountDiscount += seller.freeDeliveryOrderAmount!.shippingCostSaved!;
                }
                if(seller.shippingType == 'order_wise'){
                  orderTypeShipping.add(seller.shippingType);
                }
              }

              if(cart.getData && configProvider.configModel!.shippingMethod == 'sellerwise_shipping') {
                shippingController.getShippingMethod(context, cartProductList);
              }

              for(int i=0; i<cart.cartList.length; i++) {
                if(cart.cartList[i].isChecked!){
                  totalQuantity += cart.cartList[i].quantity!;
                  amount += (cart.cartList[i].price! - cart.cartList[i].discount!) * cart.cartList[i].quantity!;
                  discount += cart.cartList[i].discount! * cart.cartList[i].quantity!;
                  if (kDebugMode) {
                    print('====TaxModel == ${cart.cartList[i].taxModel}');
                  }
                  if(cart.cartList[i].taxModel == "exclude"){
                    tax += cart.cartList[i].tax! * cart.cartList[i].quantity!;
                  }
                }
              }
              for(int i=0; i<shippingController.chosenShippingList.length; i++){
                if(shippingController.chosenShippingList[i].isCheckItemExist == 1 && !onlyDigital) {
                  shippingAmount += shippingController.chosenShippingList[i].shippingCost!;
                }
              }

              for(int j = 0; j< cartList.length; j++){
                if(cartList[j].isChecked!) {
                  shippingAmount += cart.cartList[j].shippingCost ?? 0;
                }
              }

              final requiredMinOrderQtyCart = _getRequiredMinOrderQtyCartModel(sellerGroupList, cartProductList);

              return Scaffold(
                bottomNavigationBar: (!cart.cartLoading && cartList.isNotEmpty) ?
                Consumer<SplashController>(
                  builder: (context, configProvider,_) {


                    return Container(height: cartList.isNotEmpty ? 110 : 0, padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: Dimensions.paddingSizeSmall
                     ),

                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: cartList.isNotEmpty ?
                      Column(children: [

                        Padding(padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

                            Row(children: [
                                Text('${getTranslated('total_price', context)} ', style: titilliumSemiBold.copyWith(
                                    fontSize: Dimensions.fontSizeLarge,
                                    color: Provider.of<ThemeController>(context, listen: false).darkTheme? Theme.of(context).hintColor : Theme.of(context).primaryColor)),
                                Text('${getTranslated('inc_vat_tax', context)}', style: titilliumSemiBold.copyWith(
                                    fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
                            ]),

                            Text(PriceConverter.convertPrice(context, amount+tax+shippingAmount-freeDeliveryAmountDiscount), style: titilliumSemiBold.copyWith(
                                color: Provider.of<ThemeController>(context, listen: false).darkTheme? Theme.of(context).hintColor : Theme.of(context).primaryColor,
                                fontSize: Dimensions.fontSizeLarge)),
                          ]),
                        ),




                        InkWell(onTap: () {
                              bool hasNull = false;
                              bool minimum = false;
                              bool stockOutProduct = false;
                              bool closeShop = false;
                              double total = 0;



                              //  if(configProvider.configModel!.shippingMethod =='sellerwise_shipping'){
                              //   for(int index = 0; index < cartProductList.length; index++) {
                              //     for(CartModel cart in cartProductList[index]) {
                              //       if(cart.productType == 'physical' && sellerGroupList[index].shippingType == 'order_wise'  &&
                              //           Provider.of<ShippingController>(context, listen: false).shippingList![index].shippingIndex == -1) {
                              //         hasNull = true;
                              //         break;
                              //       }
                              //     }
                              //   }
                              // }

                               if (configProvider.configModel!.shippingMethod =='sellerwise_shipping') {
                                 for (int index = 0; index < sellerGroupList.length; index++) {
                                   bool hasPhysical = false;
                                   for(CartModel cart in cartProductList[index]) {
                                     if(cart.productType == 'physical') {
                                       hasPhysical = true;
                                       break;
                                     }
                                   }

                                   if(hasPhysical && sellerGroupList[index].isGroupItemChecked! && sellerGroupList[index].shippingType == 'order_wise'  &&
                                       Provider.of<ShippingController>(context, listen: false).shippingList![index].shippingIndex == -1 && sellerGroupList[index].isGroupItemChecked!){
                                     hasNull = true;
                                     break;
                                   }
                                 }
                               }

                                for(int index = 0; index < sellerGroupList.length; index++) {
                                  total = 0;
                                  for(CartModel cart in cartProductList[index]) {
                                    total += (cart.price! - cart.discount!) * cart.quantity! ;

                                  }
                                  log("===Here===>$total======${sellerGroupList[index].minimumOrderAmountInfo!}>");
                                  if(total< sellerGroupList[index].minimumOrderAmountInfo!) {
                                    minimum = true;
                                  }

                                }

                              for(int index = 0; index < sellerGroupList.length; index++) {
                                for(CartModel cart in cartProductList[index]) {
                                  if(cart.isChecked == true && cart.quantity! > cart.productInfo!.totalCurrentStock! && cart.productType =="physical") {
                                    stockOutProduct = true;
                                    break;
                                  }
                                }
                              }



                              for(int index = 0; index < sellerGroupList.length; index++) {
                                if (sellerGroupList[index].shop?.vacationEndDate != null) {
                                  bool vacationIsOn = ShopHelper.isVacationActive(
                                    context,
                                    startDate: sellerGroupList[index].shop?.vacationStartDate,
                                    endDate: sellerGroupList[index].shop?.vacationEndDate,
                                    vacationDurationType: sellerGroupList[index].shop?.vacationDurationType,
                                    vacationStatus: sellerGroupList[index].shop?.vacationStatus,
                                    isInHouseSeller: sellerGroupList[index].shop?.id == 0,
                                  );

                                  if ((vacationIsOn || (sellerGroupList[index].shop?.temporaryClose ?? false)) && (sellerGroupList[index].isGroupItemChecked ?? false)) {
                                    closeShop = true;
                                    break;
                                  }
                                }
                              }


                              if(configProvider.configModel?.guestCheckOut == 0 && !Provider.of<AuthController>(context, listen: false).isLoggedIn()){
                                showModalBottomSheet(backgroundColor: Colors.transparent,context:context, builder: (_)=> const NotLoggedInBottomSheetWidget());
                              }
                              else if (cart.cartList.isEmpty) {
                                showCustomSnackBar(getTranslated('select_at_least_one_product', context), context);
                              } else if (stockOutProduct) {
                                showCustomSnackBar(getTranslated('stock_out_product_in_your_cart', context), context);
                              }
                              else if (closeShop) {
                                showCustomSnackBar(getTranslated('unavailable_shop_product_in_your_cart', context), context);
                              }
                              else if(hasNull && configProvider.configModel!.shippingMethod =='sellerwise_shipping' && !onlyDigital){
                                changeColor();
                                showCustomSnackBar(getTranslated('select_all_shipping_method', context), context);
                              }

                              else if(shippingController.chosenShippingList.isEmpty &&
                                  configProvider.configModel!.shippingMethod !='sellerwise_shipping' &&
                                  configProvider.configModel!.inhouseSelectedShippingType =='order_wise' && !onlyDigital){

                                showCustomSnackBar(getTranslated('select_all_shipping_method', context), context);
                              }else if(minimum){
                                changeColor();
                                showCustomSnackBar(getTranslated('some_shop_not_full_fill_minimum_order_amount', context), context);
                              }else if (!isItemChecked){
                                showCustomSnackBar(getTranslated('please_select_items', context), context);
                              }else if(requiredMinOrderQtyCart != null) {
                                changeColor();
                                showCustomSnackBar('${getTranslated('to_order', context)} ${requiredMinOrderQtyCart.productCart.name} ${getTranslated('min_order_quantity_is', context)} ${requiredMinOrderQtyCart.productCart.productInfo?.minimumOrderQty}', context);
                              } else {

                                int sellerGroupLenght = 0;

                                for(CartModel seller in sellerGroupList) {
                                  if(seller.isGroupItemChecked!) {
                                    sellerGroupLenght += 1;
                                  }
                                }

                                Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutScreen(quantity: totalQuantity,
                                  cartList: cartList,totalOrderAmount: amount, shippingFee: shippingAmount-freeDeliveryAmountDiscount, discount: discount,
                                  tax: tax, onlyDigital: sellerGroupLenght != totalPhysical, hasPhysical: totalPhysical > 0)));
                              }
                          },
                          child: Container(decoration: BoxDecoration(color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)),

                            child: Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall,
                                  vertical: Dimensions.fontSizeSmall),
                                child: Text(getTranslated('checkout', context)!,
                                    style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.white)),
                              ),
                            ),
                          ),
                        ),
                      ]) : const SizedBox());
                  }
                ) : null,


                appBar: CustomAppBar(title: getTranslated('my_cart', context), isBackButtonExist: widget.showBackButton),
                body: Column(children: [

                  cart.cartLoading ? const Expanded(child: CartPageShimmerWidget()) : sellerList.isNotEmpty ?
                  Expanded(child: Column(children: [
                    Expanded(child: RefreshIndicator(
                        onRefresh: () async {
                          if(Provider.of<AuthController>(context, listen: false).isLoggedIn()) {
                            await Provider.of<CartController>(context, listen: false).getCartData(context);
                          }
                        },
                        child: RepaintBoundary(
                          child: ListView.builder(
                            itemCount: sellerList.length,
                            padding: const EdgeInsets.all(0),
                            itemBuilder: (context, index) {
                              bool hasPhysical = false;
                              double totalCost = 0;
                              bool shopClose = false;
                              for(CartModel cart in cartProductList[index]) {
                                if(cart.isChecked ?? false) {
                                  totalCost += (cart.price! - cart.discount!) * cart.quantity!;
                                }
                              }

                              for(CartModel cart in cartProductList[index]) {
                                if(cart.productType == 'physical' && cart.isChecked!) {
                                  hasPhysical = true;
                                  totalPhysical += 1;
                                  break;
                                }
                              }


                              if (sellerGroupList[index].shop?.vacationEndDate != null) {
                                bool vacationIsOn = ShopHelper.isVacationActive(
                                  context,
                                  startDate: sellerGroupList[index].shop?.vacationStartDate,
                                  endDate: sellerGroupList[index].shop?.vacationEndDate,
                                  vacationDurationType: sellerGroupList[index].shop?.vacationDurationType,
                                  vacationStatus: sellerGroupList[index].shop?.vacationStatus,
                                  isInHouseSeller: sellerGroupList[index].shop?.id == 0,
                                );

                                if (vacationIsOn || (sellerGroupList[index].shop?.temporaryClose ?? false)) {
                                  shopClose = true;
                                }
                              }

                              return AnimatedContainer(
                                color:
                                //  sellerGroupList[index].id == requiredMinOrderQtyCart?.sellerCart.id ||
                                  ((sellerGroupList[index].minimumOrderAmountInfo! > totalCost) || (configProvider.configModel!.shippingMethod == 'sellerwise_shipping' &&
                                  sellerGroupList[index].shippingType == 'order_wise' &&
                                  Provider.of<ShippingController>(context, listen: false).shippingList != null &&  Provider.of<ShippingController>(context, listen: false).shippingList!.isNotEmpty &&
                                  Provider.of<ShippingController>(context, listen: false).shippingList?[index].shippingIndex == -1 && sellerGroupList[index].isGroupItemChecked == true)) ? _currentColor :

                                index.floor().isOdd ? Theme.of(context).colorScheme.onSecondaryContainer : Theme.of(context).canvasColor,

                                duration: duration,
                                child: Padding(padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    sellerGroupList[index].shopInfo!.isNotEmpty ?

                                    Padding(padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                          Expanded(
                                            child: Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                                              child: Row(children: [
                                                    SizedBox(
                                                      height: 24, width: 30,
                                                      child: Checkbox(
                                                        visualDensity: VisualDensity.compact,
                                                        side: WidgetStateBorderSide.resolveWith(
                                                          (states) => BorderSide(width: 2, color: Theme.of(context).colorScheme.tertiaryContainer)),
                                                        checkColor: Colors.white,
                                                        value: sellerGroupList[index].isGroupChecked,
                                                        onChanged: (bool? value)  async {
                                                          List<int> ids = [];
                                                          for (CartModel cart in cartProductList[index]) {

                                                            ids.add(cart.id!);
                                                          }
                                                          showDialog(context: context, builder: (ctx)  => const CustomLoaderWidget());
                                                          await cart.addRemoveCartSelectedItem(ids, sellerGroupList[index].isGroupChecked! ? false : true);
                                                          Navigator.of(Get.context!).pop();
                                                        },
                                                      ),
                                                    ),

                                                  Flexible(child:  InkWell(
                                                    onTap: () => _storeScreenRouteCall(sellerGroupList[index]),
                                                    child: Text(sellerGroupList[index].shopInfo!, maxLines: 1, overflow: TextOverflow.ellipsis,
                                                      textAlign: TextAlign.start, style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge,
                                                        color: Provider.of<ThemeController>(context, listen: false).darkTheme?
                                                        Theme.of(context).hintColor : Theme.of(context).primaryColor)),
                                                  ),
                                                  ),



                                                    Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                                                      child: Text('(${cartProductList[index].length})',
                                                        style: textBold.copyWith(color: Provider.of<ThemeController>(context, listen: false).darkTheme?
                                                        Theme.of(context).hintColor : Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeLarge))),

                                                  if(shopClose)
                                                    JustTheTooltip(
                                                      backgroundColor: Colors.black87,
                                                      controller: tooltipController,
                                                      preferredDirection: AxisDirection.down,
                                                      tailLength: 10,
                                                      tailBaseWidth: 20,
                                                      content: Container(width: 150,
                                                          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                                          child: Text(getTranslated('store_is_closed', context)!,
                                                              style: textRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeDefault))),
                                                      child: InkWell(onTap: ()=>  tooltipController.showTooltip(),
                                                        child: Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                                                          child: SizedBox(width: 30, child: Image.asset(Images.warning, color: Theme.of(context).colorScheme.error,)),
                                                        ),
                                                      ),
                                                    )


                                                  ]
                                              ))
                                          ),

                                        SizedBox(width: 200, child: configProvider.configModel!.shippingMethod =='sellerwise_shipping' &&
                                            sellerGroupList[index].shippingType == 'order_wise' && hasPhysical ?

                                        Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                                          child: InkWell(onTap: () {
                                            showModalBottomSheet(
                                              context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                                              builder: (context) => ShippingMethodBottomSheetWidget(groupId: sellerGroupList[index].cartGroupId,
                                                  sellerIndex: index, sellerId: sellerGroupList[index].id),
                                            );
                                          },
                                            child: Container(decoration: BoxDecoration(
                                                border: Border.all(width: 0.5,color: Colors.grey),
                                                borderRadius: const BorderRadius.all(Radius.circular(10))),
                                              child: Padding(padding: const EdgeInsets.all(8.0),
                                                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                                 if(shippingController.shippingList == null || shippingController.shippingList!.isEmpty || shippingController.shippingList?[index].shippingMethodList == null ||
                                                     shippingController.chosenShippingList.isEmpty || shippingController.shippingList![index].shippingIndex == -1)

                                                  Row(children: [
                                                      SizedBox(width: 15,height: 15, child: Image.asset(Images.delivery,color: Theme.of(context).textTheme.bodyLarge?.color)),
                                                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                                      Text(getTranslated('choose_shipping', context)!, style: textRegular, overflow: TextOverflow.ellipsis,maxLines: 1,),]),

                                                  Flexible(child: Text(
                                                    ((shippingController.shippingList != null && shippingController.shippingList!.isNotEmpty &&
                                                      shippingController.shippingList?[index].shippingMethodList != null) &&
                                                    (shippingController.chosenShippingList.isNotEmpty &&
                                                      shippingController.shippingList![index].shippingIndex != -1))?

                                                      shippingController.shippingList![index].shippingMethodList![shippingController.shippingList![index].shippingIndex!].title.toString() : '',

                                                    style: titilliumSemiBold.copyWith(color: Theme.of(context).hintColor),
                                                    maxLines: 1, overflow: TextOverflow.ellipsis,textAlign: TextAlign.end)),

                                                  Icon(Icons.keyboard_arrow_down, color: Theme.of(context).primaryColor),
                                                ]),
                                              ),
                                            ),
                                          ),
                                        ) : const SizedBox(),)
                                        ],
                                      ),
                                    ) : const SizedBox(),

                                    if(sellerGroupList[index].minimumOrderAmountInfo!> totalCost)
                                    Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
                                      child: Text('${getTranslated('minimum_order_amount_is', context)} '
                                          '${PriceConverter.convertPrice(context, sellerGroupList[index].minimumOrderAmountInfo)}',
                                        style: textRegular.copyWith(color: Theme.of(context).colorScheme.error),),),

                                    if(configProvider.configModel!.shippingMethod == 'sellerwise_shipping' && sellerGroupList[index].shippingType == 'order_wise' && hasPhysical)
                                      Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                                      child: ((shippingController.shippingList != null && shippingController.shippingList!.isNotEmpty &&
                                        shippingController.shippingList![index].shippingMethodList != null
                                        && shippingController.shippingList![index].shippingIndex != -1) &&
                                        shippingController.chosenShippingList.isNotEmpty) ?
                                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Row(children: [
                                            Text((shippingController.shippingList == null ||
                                                shippingController.shippingList![index].shippingMethodList == null ||
                                                shippingController.chosenShippingList.isEmpty ||
                                                shippingController.shippingList![index].shippingIndex == -1) ? '':
                                            '${getTranslated('shipping_cost', context)??''} : ', style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),),

                                          Text((shippingController.shippingList == null ||
                                              shippingController.shippingList![index].shippingMethodList == null ||
                                              shippingController.chosenShippingList.isEmpty ||
                                              shippingController.shippingList![index].shippingIndex == -1) ? ''
                                              : PriceConverter.convertPrice(context,
                                              shippingController.shippingList![index].shippingMethodList![shippingController.shippingList![index].shippingIndex!].cost),
                                              style: textBold.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
                                              maxLines: 1, overflow: TextOverflow.ellipsis,textAlign: TextAlign.end),
                                          ],
                                        ),
                                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                                        Row(children: [
                                            Text((shippingController.shippingList == null ||
                                                shippingController.shippingList![index].shippingMethodList == null ||
                                                shippingController.chosenShippingList.isEmpty ||
                                                shippingController.shippingList![index].shippingIndex == -1) ? '':
                                            '${getTranslated('shipping_time', context)??''} : ', style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
                                          Text((shippingController.shippingList == null ||
                                              shippingController.shippingList![index].shippingMethodList == null ||
                                              shippingController.chosenShippingList.isEmpty ||
                                              shippingController.shippingList![index].shippingIndex == -1) ? ''
                                              : '${shippingController.shippingList![index].shippingMethodList![shippingController.shippingList![index].shippingIndex!].duration.toString()} '
                                              '${getTranslated('days', context)}',
                                              style: textBold.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
                                              maxLines: 1, overflow: TextOverflow.ellipsis,textAlign: TextAlign.end)
                                          ],
                                        ),
                                      ]) : const SizedBox(),
                                    ),


                                    Card(child: Container(padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
                                      decoration: BoxDecoration(color: Theme.of(context).highlightColor),
                                      child: Column(children: [
                                        ListView.builder(
                                          physics: const NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          padding: const EdgeInsets.all(0),
                                          itemCount: cartProductList[index].length,
                                          itemBuilder: (context, i) {
                                          return CartWidget(
                                            highLightColor: _currentColor,
                                            cartModel: cartProductList[index][i],
                                            index: cartProductIndexList[index][i],
                                            fromCheckout: widget.fromCheckout,
                                          );
                                          },
                                        ),
                                      ],
                                      )),
                                    ),
                                      if(sellerGroupList[index].freeDeliveryOrderAmount?.status == 1 && hasPhysical && sellerGroupList[index].isGroupItemChecked!)
                                      Padding(padding: const EdgeInsets.only(bottom : Dimensions.paddingSizeSmall,left: Dimensions.paddingSizeDefault,
                                          right: Dimensions.paddingSizeDefault, top: Dimensions.paddingSizeSmall),
                                        child: Row(children: [
                                          SizedBox(height: 16, child: Image.asset(Images.freeShipping,
                                            color: Provider.of<ThemeController>(context, listen: false).darkTheme?
                                            Theme.of(context).hintColor: Theme.of(context).primaryColor,)),
                                          if(sellerGroupList[index].freeDeliveryOrderAmount!.amountNeed! > 0)
                                            Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                                              child: Text(PriceConverter.convertPrice(context, sellerGroupList[index].freeDeliveryOrderAmount!.amountNeed!),
                                                  style: textMedium.copyWith(color: Theme.of(context).primaryColor)),),
                                          sellerGroupList[index].freeDeliveryOrderAmount!.percentage! < 100?
                                          Text('${getTranslated('add_more_for_free_delivery', context)}', style: textMedium.copyWith(color: Theme.of(context).hintColor)):
                                          Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                                            child: Text('${getTranslated('you_got_free_delivery', context)}', style: textMedium.copyWith(color: Colors.green)),
                                          )
                                        ],),
                                      ),
                                    if(sellerGroupList[index].freeDeliveryOrderAmount?.status == 1 && hasPhysical && sellerGroupList[index].isGroupItemChecked!)
                                      Padding(padding: const EdgeInsets.fromLTRB( Dimensions.paddingSizeDefault,0,Dimensions.paddingSizeDefault,Dimensions.paddingSizeDefault),
                                        child: LinearPercentIndicator(
                                          padding: EdgeInsets.zero,
                                          barRadius: const Radius.circular(Dimensions.paddingSizeDefault),
                                          width: MediaQuery.of(context).size.width - 40,
                                          lineHeight: 4.0,
                                          percent: sellerGroupList[index].freeDeliveryOrderAmount!.percentage! / 100,
                                          backgroundColor: Provider.of<ThemeController>(context, listen: false).darkTheme?
                                          Theme.of(context).primaryColor.withValues(alpha:.5):Theme.of(context).primaryColor.withValues(alpha:.2),
                                          progressColor: (sellerGroupList[index].freeDeliveryOrderAmount!.percentage! < 100 &&
                                              !Provider.of<ThemeController>(context, listen: false).darkTheme)?
                                          Theme.of(context).colorScheme.onSecondary : Colors.green,
                                        ),
                                      ),
                                  ]),
                                ),
                              );
                              },
                          ),
                        ),
                      ),
                    ),
                    ( !onlyDigital && configProvider.configModel!.shippingMethod != 'sellerwise_shipping' && configProvider.configModel!.inhouseSelectedShippingType =='order_wise')?
                    InkWell(onTap: () {showModalBottomSheet(
                          context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                          builder: (context) => const ShippingMethodBottomSheetWidget(groupId: 'all_cart_group',sellerIndex: 0, sellerId: 1));},
                      child: Padding(padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, 0),
                        child: Container(decoration: BoxDecoration(
                          border: Border.all(width: 0.5, color: Colors.grey),
                          borderRadius: const BorderRadius.all(Radius.circular(10))),
                          child: Padding(padding: const EdgeInsets.all(8.0),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

                              Row(children: [
                                  SizedBox(width: 15,height: 15, child: Image.asset(Images.delivery, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                  Text(getTranslated('choose_shipping', context)!, style: textRegular, overflow: TextOverflow.ellipsis,maxLines: 1,),]),

                              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                Text((shippingController.shippingList == null ||shippingController.chosenShippingList.isEmpty ||
                                    shippingController.shippingList!.isEmpty || shippingController.shippingList![0].shippingMethodList == null ||
                                    shippingController.shippingList![0].shippingIndex == -1) ? ''
                                    : shippingController.shippingList![0].shippingMethodList![shippingController.shippingList![0].shippingIndex!].title.toString(),
                                  style: titilliumSemiBold.copyWith(color: Theme.of(context).hintColor),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,),
                                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                Icon(Icons.keyboard_arrow_down, color: Theme.of(context).primaryColor),
                              ]),
                            ]),
                          ),
                        ),
                      ),
                    ):const SizedBox(),


                  ]),
                  ) :
                  const Expanded(child: NoInternetOrDataScreenWidget(icon: Images.emptyCart, icCart: true,
                    isNoInternet: false, message: 'no_product_in_cart',
                  )),
                ]),
              );
            });
          }
        );
      }
    );
  }



  ({CartModel productCart, CartModel sellerCart})? _getRequiredMinOrderQtyCartModel(
      List<CartModel> sellerGroupList,
      List<List<CartModel>> cartProductList,
      ) {
    for (int index = 0; index < sellerGroupList.length; index++) {
      for (CartModel cart in cartProductList[index]) {
        if (cart.isChecked == true && cart.quantity! < (cart.productInfo?.minimumOrderQty ?? 1)) {
          return (
          productCart: cart,
          sellerCart: sellerGroupList[index],
          );
        }
      }
    }
    return null;
  }



  void _storeScreenRouteCall (CartModel sellerList) {
  if(sellerList.sellerIs == 'admin') {
    Navigator.push(context, MaterialPageRoute(builder: (_) => TopSellerProductScreen(
      sellerId: 0,
      fromMore: false,
      temporaryClose: Provider.of<SplashController>(context, listen: false).configModel?.inhouseTemporaryClose?.status ?? false,
      vacationStatus: Provider.of<SplashController>(context, listen: false).configModel?.inhouseVacationAdd?.status,
      vacationEndDate: Provider.of<SplashController>(context, listen: false).configModel?.inhouseVacationAdd?.vacationEndDate,
      vacationStartDate: Provider.of<SplashController>(context, listen: false).configModel?.inhouseVacationAdd?.vacationStartDate,
      vacationDurationType: Provider.of<SplashController>(context, listen: false).configModel?.inhouseVacationAdd?.vacationDurationType,
      name: Provider.of<SplashController>(context, listen: false).configModel?.inHouseShop?.name,
      banner: Provider.of<SplashController>(context, listen: false).configModel?.inHouseShop?.bannerFullUrl?.path,
      image: Provider.of<SplashController>(context, listen: false).configModel?.inHouseShop?.imageFullUrl?.path)
    ));
  } else {
    Navigator.push(Get.context!, MaterialPageRoute(builder: (_) => TopSellerProductScreen(
      sellerId: sellerList.shop?.sellerId,
      temporaryClose: sellerList.shop?.temporaryClose,
      vacationStatus: sellerList.shop?.vacationStatus,
      vacationEndDate: sellerList.shop?.vacationEndDate,
      vacationStartDate: sellerList.shop?.vacationStartDate,
      vacationDurationType: sellerList.shop?.vacationDurationType,
      name: sellerList.shop?.name,
      banner: sellerList.shop?.bannerFullUrl?.path,
      image: sellerList.shop?.imageFullUrl?.path,))
    );
  }
}

}
