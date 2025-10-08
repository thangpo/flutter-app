import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/paginated_list_view_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/domain/models/category_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/debounce_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/product_shimmer_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/product_widget.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class BrandAndCategoryProductScreen extends StatefulWidget {
  final bool isBrand;
  final int? id;
  final String? name;
  final String? image;
  final CategoryModel? categoryModel;
  final SubCategory? subCategory;
  final bool isInsideSubSubCategory;
  final bool isAllProduct;

  const BrandAndCategoryProductScreen({
    super.key,
    required this.isBrand,
    required this.id,
    required this.name,
    this.image,
    this.subCategory,
    this.isInsideSubSubCategory = false,
    this.categoryModel,
    this.isAllProduct = false
  });

  @override
  State<BrandAndCategoryProductScreen> createState() => _BrandAndCategoryProductScreenState();
}

class _BrandAndCategoryProductScreenState extends State<BrandAndCategoryProductScreen> {
  final TextEditingController searchTextEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  late List<SubSubCategory>? subSubCategoryList;
  late List<SubCategory>? subCategoryList;

  final DebounceHelper debounceHelper = DebounceHelper(milliseconds: 500);


  void _initializeCategoryList(String categoryName){
    subCategoryList = [];
    subSubCategoryList = [];

    if((widget.subCategory?.subSubCategories?.isNotEmpty ?? false) && widget.id != null){
      subSubCategoryList = widget.subCategory?.subSubCategories?.map((element) => element).toList() ?? [];
      subSubCategoryList?.insert(0, SubSubCategory(
        name: categoryName,
        id: widget.subCategory?.id,
        totalProductCount: widget.subCategory?.totalProductCount,
      ));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        int index = subSubCategoryList!.indexWhere((category) => category.id == widget.id);
        if (index != -1) {
          _horizontalScrollToIndex(index);
        }
      });

    } else if((widget.categoryModel?.subCategories?.isNotEmpty ?? false ) && widget.id != null) {
      subCategoryList = widget.categoryModel?.subCategories?.map((element) => element).toList() ?? [];
      subCategoryList?.insert(0, SubCategory(
        name: categoryName,
        id: widget.categoryModel?.id,
        totalProductCount: widget.categoryModel?.totalProductCount,
      ));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        int index = subCategoryList!.indexWhere((category) => category.id == widget.id);
        if (index != -1) {
          _horizontalScrollToIndex(index);
        }
      });
    }
  }

  void _horizontalScrollToIndex(int index) {
    if(index > 1){
      _categoryScrollController.animateTo(
        index * 100,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _getProducts(int? id) async {
    await Provider.of<ProductController>(context, listen: false).initBrandOrCategoryProductList(isBrand: widget.isBrand, id: id, offset: 1, isUpdate: false);
  }


  @override
  void initState() {
    final ProductController productController = Provider.of<ProductController>(context, listen: false);

    productController.setCategorySearchProductText('', isUpdate: false);

    if(widget.id != null){
      productController.updateSelectedCategoryId(id: widget.id!, isUpdate: false);
    }
    _getProducts(widget.id);

    _initializeCategoryList(getTranslated('all_products', Get.context!)!);
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: widget.name),
      body: Consumer<ProductController>(
        builder: (context, productController, child) {
          return Column(children: [

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall).copyWith(right: Dimensions.paddingSizeDefault),
              child: TextFormField(
                controller: searchTextEditingController,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  productController.setCategorySearchProductText(value);
                },
                onFieldSubmitted: (value) {
                  productController.initBrandOrCategoryProductList(
                    isBrand: widget.isBrand,
                    id: productController.selectedCategoryId,
                    searchProduct: searchTextEditingController.text.trim(),
                    offset: 1,
                    isUpdate: true,
                  );
                },
                style: textMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.only(left: Dimensions.paddingSizeLarge),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                        borderSide: BorderSide(color: Colors.grey[300]!)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                        borderSide: BorderSide(color: Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                        borderSide: BorderSide(color: Colors.grey[300]!)),
                    hintText: getTranslated('search_products', context),
                    hintStyle: textRegular.copyWith(color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.9)),
                    suffixIcon: SizedBox(width: searchTextEditingController.text.isNotEmpty ? 70 : 50,
                      child: Row(children: [
                        if(searchTextEditingController.text.isNotEmpty)
                          InkWell(
                            onTap: (){
                              searchTextEditingController.clear();
                              productController.setCategorySearchProductText('');

                              productController.initBrandOrCategoryProductList(
                                isBrand: widget.isBrand,
                                id: productController.selectedCategoryId,
                                offset: 1,
                                isUpdate: true,
                              );
                            },
                            child: const Icon(Icons.clear, size: 20,),
                          ),


                        InkWell(onTap: (){
                          if(searchTextEditingController.text.trim().isNotEmpty) {
                            debounceHelper.run((){
                              Provider.of<ProductController>(context, listen: false).initBrandOrCategoryProductList(
                                isBrand: widget.isBrand,
                                id: productController.selectedCategoryId,
                                searchProduct: searchTextEditingController.text.trim(),
                                offset: 1,
                                isUpdate: true,
                              );
                            });
                          }else{
                            showCustomSnackBar(getTranslated('enter_somethings', context), context);
                          }
                        },
                          child: Container(
                            margin: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                            ),
                            child: Image.asset(Images.search, color: Colors.white, height: Dimensions.iconSizeSmall, width: Dimensions.iconSizeSmall, fit: BoxFit.contain),
                          ),
                        ),
                      ]),
                    )
                ),
              ),
            ),

            if(subCategoryList?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(
                  left: Dimensions.paddingSizeLarge,
                  top: Dimensions.paddingSizeSmall,
                  right: Dimensions.paddingSizeDefault,
                  bottom: Dimensions.paddingSizeSmall,
                ),
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    controller: _categoryScrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: subCategoryList!.length,
                    itemBuilder: (context, index){
                      final bool isSubCategorySelected = subCategoryList?[index].id == productController.selectedCategoryId;

                      return _CategoryItemWidget(
                        categoryName: subCategoryList?[index].name ?? '',
                        totalProductCount: '(${subCategoryList?[index].totalProductCount.toString() ?? ''})',
                        isSelected: isSubCategorySelected,
                        onTap: () {
                          searchTextEditingController.clear();

                          if(productController.selectedCategoryId != subCategoryList?[index].id){
                            debounceHelper.run(() {
                              productController.updateSelectedCategoryId(id: subCategoryList![index].id!);
                              _getProducts(subCategoryList?[index].id);
                            });
                          }
                        },
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) => const SizedBox(width: Dimensions.paddingSizeSmall),
                  ),
                ),
              ),

            if(subSubCategoryList?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(
                  left: Dimensions.paddingSizeLarge,
                  top: Dimensions.paddingSizeSmall,
                  right: Dimensions.paddingSizeDefault,
                  bottom: Dimensions.paddingSizeSmall,
                ),
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    controller: _categoryScrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: subSubCategoryList!.length,
                    itemBuilder: (context, index){

                      final bool isSubSubCategorySelected = subSubCategoryList?[index].id == productController.selectedCategoryId;

                      return _CategoryItemWidget(
                        categoryName: subSubCategoryList?[index].name ?? '',
                        totalProductCount: '(${subSubCategoryList?[index].totalProductCount.toString() ?? ''})',
                        isSelected: isSubSubCategorySelected,
                        onTap: () {
                          searchTextEditingController.clear();

                          if(productController.selectedCategoryId != subSubCategoryList?[index].id){
                            debounceHelper.run((){
                              productController.updateSelectedCategoryId(id: subSubCategoryList![index].id!);
                              _getProducts(subSubCategoryList?[index].id);
                            });
                          }
                        },
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) => const SizedBox(width: Dimensions.paddingSizeSmall),
                  ),
                ),
              ),

            (productController.brandOrCategoryProductList?.products?.isNotEmpty ?? false) ?
            Flexible(child: PaginatedListView(
              scrollController: _scrollController,
              onPaginate: (offset) async {
                await productController.initBrandOrCategoryProductList(isBrand: widget.isBrand, id: widget.id, offset: offset ?? 1);
              },
              limit: productController.brandOrCategoryProductList?.limit,
              totalSize: productController.brandOrCategoryProductList?.totalSize,
              offset: productController.brandOrCategoryProductList?.offset,
              itemView :  Expanded(
                child: MasonryGridView.count(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall).copyWith(top: Dimensions.paddingSizeExtraSmall),
                  crossAxisCount: MediaQuery.of(context).size.width> 480 ? 3 : 2,
                  itemCount: productController.brandOrCategoryProductList?.products?.length ?? 0,
                  itemBuilder: (BuildContext context, int index) {
                    return ProductWidget(productModel: productController.brandOrCategoryProductList!.products![index]);
                  },
                ),
              ),
            )) : productController.brandOrCategoryProductList == null ?
            Flexible(child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: ProductShimmer(isHomePage: false, isEnabled: productController.brandOrCategoryProductList == null),
            )) :
            const Flexible(child: NoInternetOrDataScreenWidget(isNoInternet: false, icon: Images.noProduct, message: 'no_product_found')),

          ]);
        },
      ),
    );
  }
}

class _CategoryItemWidget extends StatelessWidget {
  final String categoryName;
  final String totalProductCount;
  final bool isSelected;
  final Function()? onTap;
  const _CategoryItemWidget({
    required this.categoryName,
    required this.totalProductCount,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeEight, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).hintColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeEight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              offset: const Offset(0, 1),
              spreadRadius: 0,
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Row(children: [
            Text(categoryName, style: isSelected ? textBold.copyWith(
                fontSize: Dimensions.fontSizeExtraSmall,
                color: Theme.of(context).cardColor) : textRegular.copyWith(
              fontSize: Dimensions.fontSizeExtraSmall,
              color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.70),
            )),
            const SizedBox(width: Dimensions.paddingSizeExtraExtraSmall),

            Text(totalProductCount, style: isSelected ? textBold.copyWith(
                fontSize: Dimensions.fontSizeExtraSmall,
                color: Theme.of(context).cardColor.withValues(alpha: 0.70)) : textRegular.copyWith(
              fontSize: Dimensions.fontSizeExtraSmall,
              color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.70),
            )),

          ]),
        ),
      ),
    );
  }
}
