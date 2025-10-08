import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_asset_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/controllers/address_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/widgets/address_shimmer.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/widgets/remove_address_bottom_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/screens/add_new_address_screen.dart';
import 'package:provider/provider.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});
  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  final ScrollController _scrollController = ScrollController();
  bool isScrolledToEnd = false;



  void _onScroll() {
    if (_scrollController.position.atEdge) {
      isScrolledToEnd = _scrollController.position.pixels == _scrollController.position.maxScrollExtent;
      setState(() {

      });
    }
  }

  @override
  void initState() {
    super.initState();
    Provider.of<AddressController>(context, listen: false).getAddressList(all: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: getTranslated('addresses', context)),
      floatingActionButton: isScrolledToEnd ? null : FloatingActionButton(
          shape:  RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddNewAddressScreen(isBilling: false))),
          backgroundColor: Theme.of(context).primaryColor,
          child: Icon(Icons.add, color: Theme.of(context).highlightColor),
      ),


      body: Consumer<AddressController>(
        builder: (context, locationProvider, child) {
          return  locationProvider.addressList != null? locationProvider.addressList!.isNotEmpty ?
          RefreshIndicator(onRefresh: () async => await locationProvider.getAddressList(),
            backgroundColor: Theme.of(context).secondaryHeaderColor,
            child: ListView.builder(padding: const EdgeInsets.all(0),
              controller: _scrollController,
              itemCount: locationProvider.addressList?.length,
              itemBuilder: (context, index){
                return AddressItemWidget(locationProvider: locationProvider, index: index);
              },
            ),
          ) :
          const NoInternetOrDataScreenWidget(isNoInternet: false,
            message: 'no_address_found',
            icon: Images.noAddress,
          ) : const AddressShimmerWidget();
        },
      ),
    );
  }
}

class AddressItemWidget extends StatelessWidget {
  const AddressItemWidget({
    super.key, required this.locationProvider, required this.index,
  });

  final AddressController locationProvider;
  final int index;


  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, 0),
        child: Container(padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            Row(children: [

              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style.copyWith(color: Theme.of(context).textTheme.titleMedium?.color),
                  children: <InlineSpan>[
                    TextSpan(text: '${locationProvider.addressList![index].addressType?.toUpperCase()} ', style: textBold.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: Dimensions.fontSizeSmall,
                    )),

                    TextSpan(
                        text: '(${(locationProvider.addressList?[index].isBilling ?? false) ?
                        getTranslated('billing_address', context) : getTranslated('shipping_address', context)})',
                        style: textRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall)
                    ),
                  ],
                ),
                textAlign: TextAlign.left,
              ),
              const Spacer(),

              PopupMenuButton<String>(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                ),
                padding: EdgeInsets.zero,
                menuPadding: EdgeInsets.zero,
                child: Icon(Icons.more_vert, color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.70)),
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Padding(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      child: Row(children: [
                        const CustomAssetImageWidget(Images.edit, height: Dimensions.homePagePadding, width: Dimensions.homePagePadding),
                        const SizedBox(width: Dimensions.paddingSizeEight),

                        Text(getTranslated('edit', context)!, style: textRegular,),
                      ]),
                    ),
                  ),

                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Padding(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      child: Row(children: [
                        const CustomAssetImageWidget(Images.delete, height: Dimensions.homePagePadding, width: Dimensions.homePagePadding),
                        const SizedBox(width: Dimensions.paddingSizeEight),

                        Text(getTranslated('delete', context)!, style: textRegular),
                      ]),
                    ),
                  ),
                ],
                onSelected: (value) {
                  if(value == 'edit') {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_)=> AddNewAddressScreen(
                      isBilling:  locationProvider.addressList?[index].isBilling,
                      address: locationProvider.addressList?[index],
                      isEnableUpdate: true,
                    )));
                  } else if(value == 'delete') {
                    showModalBottomSheet(backgroundColor: Colors.transparent, context: context, builder: (_)=>
                        RemoveFromAddressBottomSheet(addressId: locationProvider.addressList![index].id!, index: index));
                  }
                },
              ),
            ]),
            const SizedBox(height: Dimensions.paddingSizeSmall),


            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.location_on, color: Theme.of(context).hintColor, size: Dimensions.paddingSizeDefault),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                Flexible(child: Text(locationProvider.addressList?[index].address ?? '', style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ))),
              ]),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Row(crossAxisAlignment: CrossAxisAlignment.start,children: [
            
              Flexible(child: Text.rich(TextSpan(children: [
                TextSpan(text: '${getTranslated('city', context)} : ', style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor,
                )),
            
                TextSpan(text: locationProvider.addressList?[index].city ?? "", style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge?.color,
                )),
              ]))),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault).copyWith(top: 3),
                height: Dimensions.fontSizeSmall,
                width: 1,
                color: Theme.of(context).hintColor,
              ),
            
              Flexible(child: Text.rich(TextSpan(children: [
                TextSpan(text: '${getTranslated('zip', context)} : ', style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor,
                )),
            
                TextSpan(text: locationProvider.addressList?[index].zip ?? "", style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge?.color,
                )),
              ]))),
            ]),
          ]),
        ),
      ),

      if((locationProvider.addressList?.length ?? 0) <= 5 && index == (locationProvider.addressList?.length ?? 0) - 1)
        const SizedBox(height: 200),
    ]);
  }
}
