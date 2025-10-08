import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/paginated_list_view_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/product_shimmer_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/product_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/brand/controllers/brand_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/brand/domain/models/brand_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/controllers/category_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/domain/models/category_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/clearance_sale/widgets/clearance_search_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/controllers/search_product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/responsive_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class ClearanceSaleAllProductScreen extends StatefulWidget {
  const ClearanceSaleAllProductScreen({super.key});

  @override
  State<ClearanceSaleAllProductScreen> createState() => _ClearanceSaleAllProductScreenState();
}

class _ClearanceSaleAllProductScreenState extends State<ClearanceSaleAllProductScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Provider.of<ProductController>(Get.context!, listen: false).disableSearch(isUpdate: false);
    Provider.of<ProductController>(Get.context!, listen: false).getClearanceSearchProduct(offset: 1, query: '', isNotify: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
        child: Column(
          children: [
            CustomAppBar(title: getTranslated('clearance_sale', context)),
            const SizedBox(height: 10,),

            SizedBox(height: 65,
                child: Consumer<ProductController>(
                  builder: (context, productController, child) {
                    return ClearanceSearchBarWidget(
                      showFilter: true,
                      controller: _searchController,
                      fromShop: false,
                      handleSearchText: (String? text) {
                        productController.setSearchText(text);
                        },
                      onSearchClick: () => onClick(context, productController, _searchController),
                      searchIcon: Icon(!productController.isSearchActive ? Icons.search : Icons.close, color: Theme.of(context).cardColor, size: 15),
                      applyFilter: () => applyFilter(context: context)
                    );
                  }
                )
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Consumer<ProductController>(builder: (context, productController, _){

                    ProductModel? productModel =  productController.clearanceSearchProductModel;

                    return (productModel != null && !productController.isSearchLoading)
                        ? (productModel.products != null && productModel.products!.isNotEmpty)
                        ? PaginatedListView(scrollController: _scrollController,
                        onPaginate: (int? offset) async => applyFilter(context: context, fromPagination: true, offset: offset),
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

void applyFilter({required BuildContext context, bool fromPagination = false, int? offset}) {

  final brandProvider = Provider.of<BrandController>(context, listen: false);
  final categoryProvider = Provider.of<CategoryController>(context, listen: false);
  final searchProvider = Provider.of<SearchProductController>(context, listen: false);
  final productController = Provider.of<ProductController>(context, listen: false);

  if(productController.isSearchLoading) return;


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



  String selectedCategoryId = selectedCategoryIdsList.isNotEmpty ? jsonEncode(selectedCategoryIdsList) : '[]';
  String selectedBrandId = selectedBrandIdsList.isNotEmpty ? jsonEncode(selectedBrandIdsList) : '[]';
  String selectedAuthorId = searchProvider.selectedSellerAuthorIds.isNotEmpty ? jsonEncode(searchProvider.selectedSellerAuthorIds) : searchProvider.selectedAuthorIds.isNotEmpty? jsonEncode(searchProvider.selectedAuthorIds) : '[]';
  String selectedPublishingId = searchProvider.sellerPublishingHouseIds.isNotEmpty ? jsonEncode(searchProvider.sellerPublishingHouseIds) : searchProvider.publishingHouseIds.isNotEmpty? jsonEncode(searchProvider.publishingHouseIds) : '[]';

  if(fromPagination) {
    productController.getClearanceSearchProduct(query: productController.isSearchActive ? productController.searchText ?? '' : '', categoryIds: selectedCategoryId,
        brandIds: selectedBrandId, authorIds: selectedAuthorId, publishingIds: selectedPublishingId, offset: offset ?? 1,
        productType:  searchProvider.productTypeIndex == 0 ? 'all' : searchProvider.productTypeIndex == 1 ? 'physical' : 'digital', offerType: 'clearance_sale', fromPaginantion: fromPagination
    );
  } else {

    if(context.mounted) Navigator.pop(context);

    productController.getClearanceSearchProduct(query: productController.isSearchActive ? productController.searchText ?? '' : '',categoryIds: selectedCategoryId,
        brandIds: selectedBrandId, authorIds: selectedAuthorId, publishingIds: selectedPublishingId, offset: 1,
        productType:  searchProvider.productTypeIndex == 0 ? 'all' : searchProvider.productTypeIndex == 1 ? 'physical' : 'digital', offerType: 'clearance_sale'
    ).then((value) {
      if(value.response?.statusCode == 200){
        productController.isFilterActive = true;
      }
    });
  }
}




void onClick( BuildContext context, ProductController productController, TextEditingController searchController){
  if(searchController.text.isEmpty && !productController.isSearchActive) {
    showCustomSnackBar(getTranslated('type_something_to_search_for_products', context), context);
  }
  else if(!productController.isSearchActive && !productController.isSearchLoading){
    productController.setSearchText(searchController.text.trim());
    productController.getClearanceSearchProduct(offset: 1, query: productController.searchText!);
    productController.toggleSearchActive();
  }
  else if(!productController.isSearchLoading){
    searchController.text = '';
    productController.setSearchText('');
    productController.toggleSearchActive();
    productController.getClearanceSearchProduct(offset: 1, query: '');
  }
}



