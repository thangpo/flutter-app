import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/paginated_list_view_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/widgets/address_shimmer.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/restock/controllers/restock_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/restock/domain/models/restock_product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/restock/widgets/delete_restock_confirm_bottom_sheet.dart';
import 'package:flutter_sixvalley_ecommerce/features/restock/widgets/restock_list_item_widget.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:provider/provider.dart';

class RestockListScreen extends StatefulWidget {
  const RestockListScreen({super.key});
  @override
  State<RestockListScreen> createState() => _RestockListScreenState();
}

class _RestockListScreenState extends State<RestockListScreen> {
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {

      Provider.of<RestockController>(context, listen: false).getRestockProductList(1);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) async{
        if(Navigator.of(context).canPop()){
          if( Provider.of<RestockController>(context, listen: false).restockProductModel != null && Provider.of<RestockController>(context, listen: false).restockProductModel?.data == [] ){
            Provider.of<RestockController>(context, listen: false).emptyReStockData();
          }
          return;
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: getTranslated('restock_request', context),
          onBackPressed: () {
            if( Provider.of<RestockController>(context, listen: false).restockProductModel != null && Provider.of<RestockController>(context, listen: false).restockProductModel?.data == [] ){
              Provider.of<RestockController>(context, listen: false).emptyReStockData();
            }
            Navigator.pop(context);
          },
        ),

        body: Consumer<RestockController>(
          builder: (context, restockController, child) {
            return  restockController.restockProductModel != null ? restockController.restockProductModel!.data!.isNotEmpty ?
            RefreshIndicator(
              onRefresh: () async => await restockController.getRestockProductList(1),
              backgroundColor: Theme.of(context).secondaryHeaderColor,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault,
                      Dimensions.paddingSizeDefault, Dimensions.paddingSizeExtraSmall),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

                        RichText(text: TextSpan(children: [
                          TextSpan(text: '${getTranslated('products', context)} ',
                            style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                          TextSpan(text: '(${restockController.restockProductModel?.totalSize ?? 0})',
                            style: textBold.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Theme.of(context).hintColor
                            ),
                          ),
                        ])),

                        InkWell(
                          onTap: () async {
                            showModalBottomSheet(backgroundColor: Colors.transparent,
                              context: context, builder: (_)=>  const DeleteRestockCustomBottomSheetWidget()
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error.withValues(alpha:0.15),
                              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                            ),
                            child: Text(
                              getTranslated('clear_all', context)!,
                              style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).colorScheme.error),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),


                  Expanded(
                    child: SingleChildScrollView(
                      child: PaginatedListView(
                        scrollController: scrollController,
                        onPaginate: (int? offset) async => await restockController.getRestockProductList(offset!),
                        totalSize: restockController.restockProductModel?.totalSize,
                        offset: int.tryParse(restockController.restockProductModel!.offset!),
                        itemView: ListView.builder(padding: const EdgeInsets.all(0),
                          itemCount: restockController.restockProductModel?.data?.length ?? 0,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            Product? product = restockController.restockProductModel?.data![index].product;
                            double ratting = (product?.rating?.isNotEmpty ?? false) ?  double.parse('${product?.rating?[0].average}') : 0;
                            Data? data = restockController.restockProductModel?.data![index];
                            return RestockListItemWidget(
                              product: product,
                              ratting: ratting,
                              data: data,
                              index: index
                            );
                          },
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ) :
            const NoInternetOrDataScreenWidget(isNoInternet: false, message: 'product_not_found', icon: Images.noProduct)
            : const AddressShimmerWidget();
          },
        ),
      ),
    );
  }
}
