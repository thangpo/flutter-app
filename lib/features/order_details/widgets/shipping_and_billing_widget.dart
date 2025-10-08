import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/controllers/order_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/widgets/icon_with_text_row_widget.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';

class ShippingAndBillingWidget extends StatelessWidget {
  final OrderDetailsController orderProvider;
  const ShippingAndBillingWidget({super.key, required this.orderProvider});

  @override
  Widget build(BuildContext context) {
    return  orderProvider.orders!.orderType == 'POS' ? Container(
      alignment: Alignment.center, padding: const EdgeInsets.all(Dimensions.homePagePadding),
      color: Theme.of(context).highlightColor,
      child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(getTranslated('pos_order', context)!),

          InkWell(
            onTap: (){
              orderProvider.getOrderInvoice(orderProvider.orders!.id.toString(), context);
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha:0.15)),
              ),
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child:  orderProvider.isInvoiceLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator()) :
              Image.asset(Images.downloadIcon, height: 15, width: 15),
            ),
          ),
        ],
      )) :
    Container(decoration: const BoxDecoration(
      image: DecorationImage(image: AssetImage(Images.mapBg), fit: BoxFit.cover)),
        child: Card(margin: const EdgeInsets.all(Dimensions.marginSizeDefault),
          child: Padding(padding: const EdgeInsets.all(Dimensions.homePagePadding),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [


              orderProvider.orders!.shippingAddressData != null ?
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(getTranslated('shipping_address', context)!, style: textMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge?.color),),
                  const SizedBox(height: Dimensions.marginSizeSmall),

                  Row(
                    children: [
                      Expanded(
                        child: IconWithTextRowWidget(
                          icon: Icons.person,
                          text: '${orderProvider.orders!.shippingAddressData != null ?
                          orderProvider.orders!.shippingAddressData!.contactPersonName : ''}',),
                      ),

                      Expanded(
                        child: IconWithTextRowWidget(
                          icon: Icons.call,
                          text: '${orderProvider.orders!.shippingAddressData != null ?
                          orderProvider.orders!.shippingAddressData!.phone : ''}',),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.marginSizeSmall),

                  Row(mainAxisAlignment:MainAxisAlignment.start, crossAxisAlignment:CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, color: Provider.of<ThemeController>(context, listen: false).darkTheme?
                      Colors.white : Theme.of(context).hintColor.withValues(alpha: 0.5)),
                      const SizedBox(width: Dimensions.marginSizeSmall),

                      Expanded(child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text('${orderProvider.orders!.shippingAddressData != null ?
                        orderProvider.orders!.shippingAddressData!.address : ''}',
                          maxLines: 3, overflow: TextOverflow.ellipsis,
                          style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color))))]
                  ),

                  ],
                ):const SizedBox(),


                if(orderProvider.orders!.billingAddressData != null)
                Divider(thickness: .25, color: Theme.of(context).primaryColor.withValues(alpha:0.50)),

                orderProvider.orders!.billingAddressData != null ?
                Padding(
                  padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(getTranslated('billing_address', context)!,
                      style: textMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color)),
                      const SizedBox(height: Dimensions.marginSizeSmall),

                        if(orderProvider.orders!.shippingAddressData?.id == orderProvider.orders?.billingAddressData?.id)...[
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.30),
                              borderRadius: BorderRadius.circular(Dimensions.radiusSmall)
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const SizedBox(width: Dimensions.paddingSizeSmall),
                                Text(
                                  getTranslated('same_as_shipping_address', context)!,
                                  style: textMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color)
                                )
                              ],
                            ),
                          )
                        ],


                        if(orderProvider.orders!.shippingAddressData?.id != orderProvider.orders?.billingAddressData?.id)...[
                          Row(
                            children: [
                              Expanded(
                                child: IconWithTextRowWidget(
                                    icon: Icons.person,
                                    text: '${orderProvider.orders!.billingAddressData != null ?
                                    orderProvider.orders!.billingAddressData!.contactPersonName : ''}'),
                              ),


                              Expanded(
                                child: IconWithTextRowWidget(icon: Icons.call,
                                    text: '${orderProvider.orders!.billingAddressData != null ?
                                    orderProvider.orders!.billingAddressData!.phone : ''}'),
                              )
                            ],
                          ),
                          const SizedBox(height: Dimensions.marginSizeSmall),

                          Row(mainAxisAlignment:MainAxisAlignment.start,
                            crossAxisAlignment:CrossAxisAlignment.start, children: [
                              Icon(Icons.location_on, color: Provider.of<ThemeController>(context, listen: false).darkTheme?
                              Colors.white : Theme.of(context).hintColor.withValues(alpha: 0.5)),
                              const SizedBox(width: Dimensions.marginSizeSmall),

                              Expanded(child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 1),
                                child: Text(' ${orderProvider.orders!.billingAddressData != null ?
                                orderProvider.orders!.billingAddressData!.address : ''}',
                                    maxLines: 3, overflow: TextOverflow.ellipsis,
                                    style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color)),
                              )),
                            ],
                          ),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                        ]


                    ]
                  ),
                ):const SizedBox(),
              ],
            ),

          ),

        )
    );
  }
}
