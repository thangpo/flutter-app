import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/paginated_list_view_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/product_shimmer_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/product_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/brand/controllers/brand_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/brand/domain/models/brand_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/controllers/category_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/domain/models/category_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/clearance_sale/widgets/clearance_custom_appbar.dart';
import 'package:flutter_sixvalley_ecommerce/features/clearance_sale/widgets/clearance_search_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/controllers/search_product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/controllers/shop_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/responsive_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class ClearanceSaleShopProductScreen extends StatefulWidget {
  final String sellerId;
  const ClearanceSaleShopProductScreen({super.key, required this.sellerId});

  @override
  State<ClearanceSaleShopProductScreen> createState() => _ClearanceSaleShopProductScreenState();
}

class _ClearanceSaleShopProductScreenState extends State<ClearanceSaleShopProductScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late String? shopName;

  @override
  void initState() {
    super.initState();

    Provider.of<ShopController>(Get.context!, listen: false).disableSearch(isUpdate: false);
    shopName = Provider.of<ShopController>(context, listen: false).shopName;

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
        child: Column(
          children: [
            ClearanceCustomAppBar(
              title: Column(children: [
                Text('$shopName',
                    style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color),
                    maxLines: 1,textAlign: TextAlign.start, overflow: TextOverflow.ellipsis
                ),

                Text(getTranslated('clearance_sale', context)!,
                    style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color),
                    maxLines: 1,textAlign: TextAlign.start, overflow: TextOverflow.ellipsis
                ),

              ],),
            ),
            const SizedBox(height: 10,),

            SizedBox(
                height: 65,
                child: Consumer<ShopController>(
                    builder: (context, productController, child) {
                      return ClearanceSearchBarWidget(
                        showFilter: true,
                        controller: _searchController,
                        sellerId: int.parse(widget.sellerId),
                        handleSearchText: (String? text) {productController.setSearchText(text);},
                        onSearchClick: () => onClick(context, productController, _searchController, widget.sellerId),
                        searchIcon: Icon(!productController.isSearchActive ? Icons.search : Icons.close, color: Theme.of(context).cardColor, size: 15),
                        applyFilter: () => applyShopFilter(context: context, sellerId: widget.sellerId),
                      );
                })
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Consumer<ShopController>(builder: (context, shopController, _){

                  ProductModel? productModel = (shopController.isSearchActive || shopController.isFilterActive)
                      ? shopController.clearanceSearchProductModel : shopController.clearanceProductModel;

                  return (productModel != null && !shopController.isSearchLoading)
                      ? (productModel.products != null && productModel.products!.isNotEmpty)
                      ? PaginatedListView(scrollController: _scrollController,
                        onPaginate: (int? offset) async => (shopController.isSearchActive || shopController.isFilterActive)
                            ? applyShopFilter(context: context, sellerId: widget.sellerId, fromPagination: true, offset: offset)
                            : await shopController.getClearanceShopProductList('clearance_sale', offset.toString(), widget.sellerId),
                          totalSize: productModel.totalSize,
                          offset: productModel.offset,
                          itemView: RepaintBoundary(
                            child: MasonryGridView.count(
                              itemCount: productModel.products?.length,
                              crossAxisCount: ResponsiveHelper.isTab(context)? 3: 2,
                              padding: const EdgeInsets.all(0),
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemBuilder: (BuildContext context, int index) => ProductWidget(productModel: productModel.products![index]),
                            ),
                          )
                      ) : const NoInternetOrDataScreenWidget(isNoInternet: false) : ProductShimmer(isEnabled: productModel == null, isHomePage: false);
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void applyShopFilter({required BuildContext context, required String sellerId, bool fromPagination = false, int? offset}) async {
  final brandProvider = Provider.of<BrandController>(context, listen: false);
  final categoryProvider = Provider.of<CategoryController>(context, listen: false);
  final searchProvider = Provider.of<SearchProductController>(context, listen: false);
  final shopController = Provider.of<ShopController>(context, listen: false);

  if(shopController.isSearchLoading) return;


  (brandProvider.selectedBrandIds.isEmpty && categoryProvider.selectedCategoryIds.isEmpty)
      && searchProvider.selectedSellerAuthorIds.isEmpty && searchProvider.sellerPublishingHouseIds.isEmpty
      && (searchProvider.productTypeIndex != 0 && searchProvider.productTypeIndex != 1 && searchProvider.productTypeIndex != 2)
      ? null :
  searchProvider.setFilterApply(isFiltered: true);
  List<int> selectedBrandIdsList =[];
  List<int> selectedCategoryIdsList =[];

  for(CategoryModel category in categoryProvider.categoryList){
    if(category.isSelected!){
      selectedCategoryIdsList.add(category.id!);
    }
  }
  for(CategoryModel category in categoryProvider.categoryList){
    if(category.isSelected!){
      if(category.subCategories != null){
        for(int i=0; i< category.subCategories!.length; i++){
          selectedCategoryIdsList.add(category.subCategories![i].id!);
        }
      }

    }
  }
  for(BrandModel brand in brandProvider.brandList){
    if(brand.checked!){
      selectedBrandIdsList.add(brand.id!);
    }
  }


  // if(searchProvider.productTypeIndex == 1 && selectedCategoryIdsList.isEmpty && selectedBrandIdsList.isEmpty) {
  //   showCustomSnackBar('${getTranslated('select_brand_or_category_first', context)}', context, isToaster: true);
  // } else if (searchProvider.productTypeIndex == 2 && (searchProvider.selectedSellerAuthorIds.isEmpty && searchProvider.sellerPublishingHouseIds.isEmpty)){
  //   showCustomSnackBar('${getTranslated('select_author_or_publishing_first', context)}', context, isToaster: true);
  // }
  // else if(searchProvider.productTypeIndex == 0 && ((selectedCategoryIdsList.isEmpty && selectedBrandIdsList.isEmpty)
  //         && ((searchProvider.selectedAuthorIds.isEmpty && searchProvider.publishingHouseIds.isEmpty)
  //         && (searchProvider.selectedSellerAuthorIds.isEmpty && searchProvider.sellerPublishingHouseIds.isEmpty)))){
  //   showCustomSnackBar('${getTranslated('select_brand_or_category_first', context)}', context, isToaster: true);
  // }
  // else{
  //
  //   shopController.isSearchLoading = true;
  //
  //   String selectedCategoryId = selectedCategoryIdsList.isNotEmpty? jsonEncode(selectedCategoryIdsList) : '[]';
  //   String selectedBrandId = selectedBrandIdsList.isNotEmpty? jsonEncode(selectedBrandIdsList) : '[]';
  //   String selectedAuthorId = searchProvider.selectedSellerAuthorIds.isNotEmpty? jsonEncode(searchProvider.selectedSellerAuthorIds) : searchProvider.selectedAuthorIds.isNotEmpty? jsonEncode(searchProvider.selectedAuthorIds) : '[]';
  //   String selectedPublishingId = searchProvider.sellerPublishingHouseIds.isNotEmpty? jsonEncode(searchProvider.sellerPublishingHouseIds) : searchProvider.publishingHouseIds.isNotEmpty? jsonEncode(searchProvider.publishingHouseIds) : '[]';
  //
  //   if(formPagination) {
  //     await shopController.getClearanceSearchProduct(sellerId, offset ?? 1, "", categoryIds: selectedCategoryId,
  //       brandIds: selectedBrandId, authorIds: selectedAuthorId, publishingIds: selectedPublishingId,
  //       productType:  searchProvider.productTypeIndex == 0 ? 'all' : searchProvider.productTypeIndex == 1 ? 'physical' : 'digital', offerType: 'clearance_sale'
  //     );
  //   } else {
  //     shopController.getClearanceSearchProduct(sellerId, 1, "", categoryIds: selectedCategoryId,
  //       brandIds: selectedBrandId, authorIds: selectedAuthorId, publishingIds: selectedPublishingId,
  //       productType:  searchProvider.productTypeIndex == 0 ? 'all' : searchProvider.productTypeIndex == 1 ? 'physical' : 'digital', offerType: 'clearance_sale'
  //     ).then((value) {
  //       if(value.response?.statusCode == 200){
  //         shopController.isSearchLoading = false;
  //         shopController.isFilterActive = true;
  //         if(context.mounted) Navigator.pop(context);
  //       }
  //     });
  //   }
  // }


  String selectedCategoryId = selectedCategoryIdsList.isNotEmpty? jsonEncode(selectedCategoryIdsList) : '[]';
  String selectedBrandId = selectedBrandIdsList.isNotEmpty? jsonEncode(selectedBrandIdsList) : '[]';
  String selectedAuthorId = searchProvider.selectedSellerAuthorIds.isNotEmpty? jsonEncode(searchProvider.selectedSellerAuthorIds) : searchProvider.selectedAuthorIds.isNotEmpty? jsonEncode(searchProvider.selectedAuthorIds) : '[]';
  String selectedPublishingId = searchProvider.sellerPublishingHouseIds.isNotEmpty? jsonEncode(searchProvider.sellerPublishingHouseIds) : searchProvider.publishingHouseIds.isNotEmpty? jsonEncode(searchProvider.publishingHouseIds) : '[]';

  if(fromPagination) {
    await shopController.getClearanceSearchProduct(sellerId, offset ?? 1, "", categoryIds: selectedCategoryId,
        brandIds: selectedBrandId, authorIds: selectedAuthorId, publishingIds: selectedPublishingId,
        productType:  searchProvider.productTypeIndex == 0 ? 'all' : searchProvider.productTypeIndex == 1 ? 'physical' : 'digital', offerType: 'clearance_sale', fromPaginantion: fromPagination
    );
  } else {

    if(context.mounted) Navigator.pop(context);

    shopController.getClearanceSearchProduct(sellerId, 1, "", categoryIds: selectedCategoryId,
        brandIds: selectedBrandId, authorIds: selectedAuthorId, publishingIds: selectedPublishingId,
        productType:  searchProvider.productTypeIndex == 0 ? 'all' : searchProvider.productTypeIndex == 1 ? 'physical' : 'digital', offerType: 'clearance_sale'
    ).then((value) {
      if(value.response?.statusCode == 200){
        shopController.isFilterActive = true;
      }
    });
  }
}



void onClick( BuildContext context, ShopController shopController, TextEditingController searchController, String sellerId){
  if(searchController.text.isEmpty && !shopController.isSearchActive) {
    showCustomSnackBar(getTranslated('type_something_to_search_for_products', context), context);
  } else if(!shopController.isSearchActive && !shopController.isSearchLoading){
    shopController.setSearchText(searchController.text.trim());
    shopController.getClearanceSearchProduct(sellerId, 1, '', search: shopController.searchText!);
    shopController.toggleSearchActive();
  } else if(!shopController.isSearchLoading){
    searchController.text = '';
    shopController.setSearchText('');
    shopController.disableSearch();
  }
}


