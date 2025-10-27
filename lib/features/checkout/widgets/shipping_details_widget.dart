import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/controllers/address_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/controllers/checkout_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/create_account_widget.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/screens/saved_address_list_screen.dart';
import 'package:provider/provider.dart';


class ShippingDetailsWidget extends StatefulWidget {
  final bool hasPhysical;
  final GlobalKey<FormState> passwordFormKey;
  final VoidCallback? onAddressChanged;

  const ShippingDetailsWidget({super.key, required this.hasPhysical, required this.passwordFormKey, this.onAddressChanged,});

  @override
  State<ShippingDetailsWidget> createState() => _ShippingDetailsWidgetState();
}

class _ShippingDetailsWidgetState extends State<ShippingDetailsWidget> {

  @override
  Widget build(BuildContext context) {
    bool isGuestMode = !Provider.of<AuthController>(context, listen: false).isLoggedIn();
    return Consumer<CheckoutController>(
        builder: (context, shippingProvider,_) {
          // THAY ĐỔI: Luôn set sameAsBilling = true
          if(!shippingProvider.sameAsBilling){
            WidgetsBinding.instance.addPostFrameCallback((_) {
              shippingProvider.setSameAsBilling();
            });
          }

          return Consumer<AddressController>(
              builder: (context, locationProvider, _) {
                return Container(padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeSmall,
                    Dimensions.paddingSizeSmall, Dimensions.paddingSizeSmall,0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    widget.hasPhysical?
                    Card(child: Container(padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
                          color: Theme.of(context).cardColor,),
                        child: Column(crossAxisAlignment:CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment:MainAxisAlignment.start, crossAxisAlignment:CrossAxisAlignment.start, children: [
                            Expanded(child: Row(children: [
                              SizedBox(width: 18, child: Image.asset(Images.deliveryTo)),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                                  child: Text('${getTranslated('delivery_to', context)}',
                                      style: textMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color)))])),


                            InkWell(onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (BuildContext context) => const SavedAddressListScreen())),
                              child: SizedBox(width: 20, child: Image.asset(Images.edit,
                                scale: 3, color: Theme.of(context).primaryColor,)),),]),
                          const SizedBox(height: Dimensions.paddingSizeDefault,),

                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text((shippingProvider.addressIndex == null || locationProvider.addressList!.isEmpty) ?
                            '${getTranslated('address_type', context)}' :
                            locationProvider.addressList![shippingProvider.addressIndex!].addressType!.capitalize(),
                                style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color), maxLines: 3, overflow: TextOverflow.fade),
                            const Divider(thickness: .200),


                            (shippingProvider.addressIndex == null || locationProvider.addressList!.isEmpty)?
                            Text(getTranslated('add_your_address', context)??'',
                                style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge?.color),
                                maxLines: 3, overflow: TextOverflow.fade):
                            Column(children: [
                              AddressInfoItem(icon: Images.user,
                                  title: locationProvider.addressList![shippingProvider.addressIndex!].contactPersonName??''),
                              AddressInfoItem(icon: Images.callIcon,
                                  title: locationProvider.addressList![shippingProvider.addressIndex!].phone??''),
                              AddressInfoItem(icon: Images.address,
                                  title: locationProvider.addressList![shippingProvider.addressIndex!].address??''),])]),
                        ]))): const SizedBox(),
                    SizedBox(height: widget.hasPhysical? Dimensions.paddingSizeSmall:0),

                    isGuestMode ? (widget.hasPhysical)?
                    CreateAccountWidget(formKey: widget.passwordFormKey) : const SizedBox() : const SizedBox(),

                    isGuestMode ? const SizedBox(height: Dimensions.paddingSizeSmall) : const SizedBox(),

                    // THAY ĐỔI: Đã xóa hoàn toàn checkbox "Same as Delivery"
                    // THAY ĐỔI: Đã xóa hoàn toàn phần Billing Address UI

                    isGuestMode ? (!widget.hasPhysical)?
                    CreateAccountWidget(formKey: widget.passwordFormKey) : const SizedBox() : const SizedBox(),

                  ]),
                );
              }
          );
        }
    );
  }
}

class AddressInfoItem extends StatelessWidget {
  final String? icon;
  final String? title;
  const AddressInfoItem({super.key, this.icon, this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
      child: Row(children: [
        SizedBox(width: 18, child: Image.asset(icon!)),
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
            child: Text(title??'', style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color), maxLines: 2, overflow: TextOverflow.fade )))]),
    );
  }
}
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}