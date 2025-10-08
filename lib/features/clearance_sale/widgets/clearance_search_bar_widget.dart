import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/clearance_sale/widgets/clearance_custom_textfield_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/clearance_sale/widgets/clearance_sale_filter_dialog_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/controllers/search_product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/domain/models/author_model.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';


class ClearanceSearchBarWidget extends StatefulWidget {
  final bool showFilter;
  final bool showBack;
  final int? sellerId;
  final bool fromShop;
  final TextEditingController controller;
  final void Function() applyFilter;
  final Function(String? text) handleSearchText;
  final void Function() onSearchClick;
  final Icon searchIcon;
  const ClearanceSearchBarWidget({super.key, this.showFilter = true, this.showBack = false, this.sellerId, this.fromShop = true, required this.controller, required this.applyFilter, required this.handleSearchText, required this.onSearchClick, required this.searchIcon});

  @override
  State<ClearanceSearchBarWidget> createState() => _ClearanceSearchBarWidgetState();
}

class _ClearanceSearchBarWidgetState extends State<ClearanceSearchBarWidget> {

  late List<AuthorModel>? authorList;
  late List<AuthorModel>? publishingHouse;

  @override
  void initState() {
    super.initState();

    if(widget.fromShop){
      authorList = Provider.of<SearchProductController>(context, listen: false).sellerAuthorsList;
      publishingHouse = Provider.of<SearchProductController>(context, listen: false).sellerPublishingHouseList;
    }else{
      authorList = Provider.of<SearchProductController>(context, listen: false).authorsList;
      publishingHouse = Provider.of<SearchProductController>(context, listen: false).publishingHouseList;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeSmall),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start,  mainAxisAlignment: MainAxisAlignment.center, children: [
          if(widget.showBack) Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Center(child: InkWell(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_new_sharp),
            )),
            const SizedBox(width: Dimensions.paddingSizeDefault),
          ]),

          Expanded(flex: 6, child: Container(
            // padding: const  EdgeInsets.all(Dimensions.paddingSizeVeryTiny),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
              border: Border.all(color: Theme.of(context).hintColor.withValues(alpha:0.2),),
            ),
            child: Stack(children: [
              ClearanceCustomTextFieldWidget(
                border: false,
                focusBorder: false,
                hintText: getTranslated('search_products', context)!,
                controller: widget.controller,
                onChanged: widget.handleSearchText,
              ),

              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: widget.onSearchClick,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.showFilter ? Dimensions.paddingSizeSmall : Dimensions.paddingSizeDefault,
                        vertical: Dimensions.paddingSizeSmall,
                      ),
                      margin: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                      ),
                      child: widget.searchIcon,
                    ),
                  ),
                ),
              ),
            ]),
          )),

          if(widget.showFilter) ...[
            const SizedBox(width: Dimensions.paddingSizeSmall),

            Expanded(flex: 1, child: InkWell(
              onTap: () {
                showModalBottomSheet(
                    context: context, isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (c) => widget.fromShop
                        ? ClearanceProductFilterDialog(sellerId: widget.sellerId, authorList: authorList, publishingHouse: publishingHouse, applyFilter: widget.applyFilter, fromShop: widget.fromShop,)
                        : ClearanceProductFilterDialog(authorList: authorList, publishingHouse: publishingHouse, applyFilter: widget.applyFilter, fromShop: widget.fromShop,)
                );
              },
              child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Provider.of<ThemeController>(context, listen: false).darkTheme
                            ? Theme.of(context).hintColor.withValues(alpha:.25)
                            : Theme.of(context).primaryColor.withValues(alpha:.15),
                    ),
                    borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                  ),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: Center(
                    child: Image.asset(Images.dropdown, color: Provider.of<ThemeController>(context, listen: false).darkTheme ? Theme.of(context).hintColor : null,),
                  )
              ),
            ))
          ],
        ]),
      ),
    );
  }
}


