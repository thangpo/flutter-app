import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_loader_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/brand/domain/models/brand_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/domain/models/category_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/seller_product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/domain/models/author_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/brand/controllers/brand_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/controllers/category_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/controllers/search_product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:provider/provider.dart';

class ProductFilterDialog extends StatefulWidget {
  final int? sellerId;
  final bool fromShop;
  const ProductFilterDialog({super.key, this.sellerId,  this.fromShop = true});

  @override
  ProductFilterDialogState createState() => ProductFilterDialogState();
}

class ProductFilterDialogState extends State<ProductFilterDialog> {
  List<int> authors = [];
  List<int> publishingHouses = [];


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);

    return Dismissible(
      key: const Key('key'),
      direction: DismissDirection.down,
      onDismissed: (_) => Navigator.pop(context),
      child: Consumer<SearchProductController>(builder: (context, searchProvider, child) {
        late List<AuthorModel>? authorList = widget.fromShop ? Provider.of<SearchProductController>(context, listen: false).sellerAuthorsList :
        Provider.of<SearchProductController>(context, listen: false).authorsList;

        late List<AuthorModel>? publishingHouse = widget.fromShop ? Provider.of<SearchProductController>(context, listen: false).sellerPublishingHouseList :
        Provider.of<SearchProductController>(context, listen: false).publishingHouseList;

        if(authorList!.isNotEmpty) {
          for (int i =0; i< authorList.length; i++) {
            authors.add(i);
          }
        }

        if(publishingHouse!.isNotEmpty) {
          for (int i=0; i < publishingHouse.length; i++) {
            publishingHouses.add(i);
          }
        }

        return Consumer<CategoryController>(builder: (context, categoryProvider,_) {
          return Consumer<BrandController>(builder: (context, brandProvider,_) {
            return Consumer<SellerProductController>(builder: (context, productController,_) {
              return Container(
                constraints: BoxConstraints(maxHeight: size.height * 0.9),
                decoration: BoxDecoration(color: Theme.of(context).highlightColor,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Column( mainAxisSize: MainAxisSize.min, children: [
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      Center(child: Container(width: 35,height: 4,decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
                          color: Theme.of(context).hintColor.withValues(alpha:.5)))),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

                        // Opacity(
                        //   opacity: 0,
                        //   child: Row(children: [
                        //     SizedBox(width: 20, child: Image.asset(Images.reset)),
                        //     Text('${getTranslated('reset', context)}', style: textRegular.copyWith(color: Theme.of(context).primaryColor)),
                        //     const SizedBox(width: Dimensions.paddingSizeDefault)
                        //   ]),
                        // ),

                        const SizedBox(width: 64,),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(getTranslated('filter', context) ?? '', style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color)),
                          ],
                        ),


                       (categoryProvider.selectedCategoryIds.isNotEmpty || brandProvider.selectedBrandIds.isNotEmpty
                         ||(widget.fromShop ? searchProvider.sellerPublishingHouseIds.isNotEmpty : searchProvider.publishingHouseIds.isNotEmpty) ||
                         (widget.fromShop ? searchProvider.selectedSellerAuthorIds.isNotEmpty : searchProvider.selectedAuthorIds.isNotEmpty)
                        ) ? InkWell(
                          onTap: () async {
                            showDialog(context: context, builder: (ctx)  => const CustomLoaderWidget());
                            await categoryProvider.resetChecked(widget.fromShop?widget.sellerId!: null, widget.fromShop);
                            searchProvider.setFilterApply(isFiltered: false);
                            categoryProvider.selectedCategoryIds.clear();
                            brandProvider.selectedBrandIds.clear();
                            searchProvider.selectedSellerAuthorIds.clear();
                            searchProvider.sellerPublishingHouseIds.clear();
                            searchProvider.publishingHouseIds.clear();
                            searchProvider.selectedAuthorIds.clear();
                            searchProvider.resetChecked(widget.sellerId, widget.fromShop);
                            if(context.mounted) {
                              Provider.of<SearchProductController>(context, listen: false).setProductTypeIndex(0, false);
                              Navigator.of(context).pop();
                            }
                          },
                          child: Row(children: [
                            SizedBox(width: 20, child: Image.asset(Images.reset)),
                            Text('${getTranslated('reset', context)}', style: textRegular.copyWith(color: Theme.of(context).primaryColor)),
                            const SizedBox(width: Dimensions.paddingSizeDefault,)
                          ]),
                        ) : SizedBox(width: size.width * 0.19),

                      ]),

                    ]),

                    Flexible(child: Padding(
                      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                          child: Column( crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              if(Provider.of<SplashController>(context, listen: false).configModel?.digitalProductSetting == '1')...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    const SizedBox(height: Dimensions.paddingSizeSmall),
                                    Text(getTranslated('product_type', context)!,
                                        style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        border: Border.all(width: .7,color: Theme.of(context).hintColor.withValues(alpha:.3)),
                                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                                      ),
                                      child: DropdownButton<String>(
                                        value: searchProvider.productTypeIndex == 0 ? 'all_product_search' : searchProvider.productTypeIndex == 1 ? 'physical' : 'digital',
                                        items: <String>['all_product_search', 'physical', 'digital'].map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(getTranslated(value, context)!),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          searchProvider.setProductTypeIndex(value == 'all_product_search' ? 0 : value == 'physical' ? 1 : 2, true);
                                        },
                                        isExpanded: true,
                                        underline: const SizedBox(),
                                      ),
                                    ),
                                  ]),
                                ),
                                const SizedBox(height: Dimensions.paddingSizeSmall),
                              ],

                              // Category
                                 Text(getTranslated('CATEGORY', context) ?? '',
                                  style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color)
                                 ),

                                 Divider(color: Theme.of(context).hintColor.withValues(alpha:.25), thickness: .5),

                              if(categoryProvider.filteredCategoryList.isNotEmpty)
                                ConstrainedBox(
                                   constraints: const BoxConstraints(
                                    minHeight: 40.0,
                                    maxHeight: 350.0,
                                  ),
                                  child: RepaintBoundary(
                                    child: ListView.builder(
                                      itemCount: categoryProvider.filteredCategoryList.length,
                                      shrinkWrap: true,
                                      itemBuilder: (context, index){
                                        return Column(children: [
                                          CategoryFilterItem(title: categoryProvider.filteredCategoryList[index].name,
                                              checked: categoryProvider.filteredCategoryList[index].isSelected!,
                                              onTap: () => categoryProvider.checkedToggleCategory(index)),
                                          if(categoryProvider.filteredCategoryList[index].isSelected!)
                                            Padding(padding: const EdgeInsets.only(left: Dimensions.paddingSizeExtraLarge),
                                              child: RepaintBoundary(
                                                child: ListView.builder(
                                                    itemCount: categoryProvider.filteredCategoryList[index].subCategories?.length??0,
                                                    shrinkWrap: true,
                                                    padding: EdgeInsets.zero,
                                                    physics: const NeverScrollableScrollPhysics(),
                                                    itemBuilder: (context, subIndex){
                                                      return CategoryFilterItem(title: categoryProvider.filteredCategoryList[index].subCategories![subIndex].name,
                                                          checked: categoryProvider.filteredCategoryList[index].subCategories![subIndex].isSelected!,
                                                          onTap: () => categoryProvider.checkedToggleSubCategory(index, subIndex));
                                                    }),
                                              ),
                                            )
                                        ],
                                        );
                                      }),
                                  ),
                                ),

                              // Brand
                              if((searchProvider.productTypeIndex == 0 || searchProvider.productTypeIndex == 1) && brandProvider.brandList.isNotEmpty)...[
                                Padding(padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
                                  child: Text(getTranslated('brand', context)??'',
                                    style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color))),

                                Divider(color: Theme.of(context).hintColor.withValues(alpha:.25), thickness: .5),

                                if(brandProvider.brandList.isNotEmpty)
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: 40.0,
                                      maxHeight: 350.0,
                                    ),
                                    child: SizedBox(
                                      child: RepaintBoundary(
                                        child: ListView.builder(
                                          itemCount: brandProvider.brandList.length,
                                          shrinkWrap: true,
                                          itemBuilder: (context, index){
                                            return CategoryFilterItem(title: brandProvider.brandList[index].name,
                                                checked: brandProvider.brandList[index].checked!,
                                                onTap: () => brandProvider.checkedToggleBrand(index));
                                          }),
                                      ),
                                    ),
                                  ),
                              ],

                              //Author
                              if((authorList.isNotEmpty) && searchProvider.productTypeIndex == 0 || searchProvider.productTypeIndex == 2 )...[
                                const SizedBox(height: Dimensions.paddingSizeSmall),
                                Text(getTranslated('author_creator_artist', context) ?? '',
                                  style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color)
                                ),
                                const SizedBox(height: Dimensions.paddingSizeSmall),

                                Autocomplete<int> (
                                  optionsBuilder: (TextEditingValue value) {
                                    if (value.text.isEmpty) {
                                      return const Iterable<int>.empty();
                                    } else {
                                      return authors.where((author) => authorList[author].name!.toLowerCase().contains(value.text.toLowerCase()));
                                    }
                                  },
                                  fieldViewBuilder: (context, controller, node, onComplete) {
                                    return Container(
                                      height: 50,
                                      decoration: BoxDecoration(color: Theme.of(context).highlightColor,
                                        border: Border.all(width: 1, color: Theme.of(context).hintColor.withValues(alpha:.50)),
                                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                                      ),
                                      child: TextField(
                                        controller: controller,
                                        focusNode: node,
                                        onEditingComplete: onComplete,
                                        onSubmitted: (value) {
                                          // resProvider.addPublishingHouse(value);
                                        },
                                        decoration: InputDecoration(
                                          hintText: getTranslated('search_by_author', context),
                                          hintStyle: textMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor),
                                          border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                                              borderSide: BorderSide.none
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  displayStringForOption: (value) =>  authorList[value].name!,
                                  onSelected: (int value) {
                                    searchProvider.checkedToggleAuthors(value, widget.fromShop);
                                  },
                                ),

                                if(authorList.isNotEmpty)
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: 40.0,
                                      maxHeight: 350.0,
                                    ),
                                    child: SizedBox(
                                      child: RepaintBoundary(
                                        child: ListView.builder(
                                          itemCount: authorList.length,
                                          shrinkWrap: true,
                                          itemBuilder: (context, index){
                                            return Column(children: [
                                              CategoryFilterItem(title: authorList[index].name,
                                                checked: authorList[index].isChecked!,
                                                onTap: () => searchProvider.checkedToggleAuthors(index, widget.fromShop)),
                                            ],
                                            );
                                          }),
                                      ),
                                    ),
                                  ),
                              ],

                              //Publishing House
                              if((publishingHouse.isNotEmpty) && searchProvider.productTypeIndex == 0 || searchProvider.productTypeIndex == 2)...[
                                const SizedBox(height: Dimensions.paddingSizeSmall),
                                Text( getTranslated('publishing_house', context) ?? '',
                                  style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color)
                                ),
                                const SizedBox(height: Dimensions.paddingSizeSmall),

                                Autocomplete<int> (
                                  optionsBuilder: (TextEditingValue value) {
                                    if (value.text.isEmpty) {
                                      return const Iterable<int>.empty();
                                    } else {
                                      return publishingHouses.where((author) => publishingHouse[author].name!.toLowerCase().contains(value.text.toLowerCase()));
                                    }
                                  },
                                  fieldViewBuilder: (context, controller, node, onComplete) {
                                    return Container(
                                      height: 50,
                                      decoration: BoxDecoration(color: Theme.of(context).highlightColor,
                                        border: Border.all(width: 1, color: Theme.of(context).hintColor.withValues(alpha:.50)),
                                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                                      ),
                                      child: TextField(
                                        controller: controller,
                                        focusNode: node,
                                        onEditingComplete: onComplete,
                                        onSubmitted: (value) {
                                          // resProvider.addPublishingHouse(value);
                                        },
                                        decoration: InputDecoration(
                                          hintText: getTranslated('search_by_publishing_house', context),
                                          hintStyle: textMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor),
                                          border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                                              borderSide: BorderSide.none
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  displayStringForOption: (value) =>  publishingHouse[value].name!,
                                  onSelected: (int value) {
                                    searchProvider.checkedTogglePublishingHouse(value, widget.fromShop);
                                  },
                                ),

                                if(publishingHouse.isNotEmpty)
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: 40.0,
                                      maxHeight: 350.0,
                                    ),
                                    child: SizedBox(
                                      child: RepaintBoundary(
                                        child: ListView.builder(
                                          itemCount: publishingHouse.length,
                                          shrinkWrap: true,
                                          itemBuilder: (context, index){
                                            return Column(children: [
                                              CategoryFilterItem(title: publishingHouse[index].name,
                                                checked: publishingHouse[index].isChecked!,
                                                onTap: () => searchProvider.checkedTogglePublishingHouse(index, widget.fromShop)),
                                            ],
                                            );
                                          }),
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                    )),

                    Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      child: CustomButton(
                        buttonText: getTranslated('apply', context),
                        onTap:

                        brandProvider.selectedBrandIds.isEmpty && categoryProvider.selectedCategoryIds.isEmpty && (widget.fromShop ? searchProvider.selectedSellerAuthorIds.isEmpty && searchProvider.sellerPublishingHouseIds.isEmpty : searchProvider.selectedAuthorIds.isEmpty && searchProvider.publishingHouseIds.isEmpty) && (searchProvider.productTypeIndex != 0 && searchProvider.productTypeIndex != 1 && searchProvider.productTypeIndex != 2) ? null : () {
                          searchProvider.setFilterApply(isFiltered: true);
                          List<int> selectedBrandIdsList =[];
                          List<int> selectedCategoryIdsList =[];

                          for(CategoryModel category in categoryProvider.filteredCategoryList){
                            if(category.isSelected!){
                              selectedCategoryIdsList.add(category.id!);
                            }
                          }
                          for(CategoryModel category in categoryProvider.filteredCategoryList){
                            if(category.isSelected!){
                              if(category.subCategories != null){
                                for(int i=0; i< category.subCategories!.length; i++){
                                  if(category.subCategories?[i].isSelected ?? false){
                                    selectedCategoryIdsList.add(category.subCategories![i].id!);

                                  }
                                }
                              }

                            }
                          }
                          for(BrandModel brand in brandProvider.brandList){
                            if(brand.checked!){
                              selectedBrandIdsList.add(brand.id!);
                            }
                          }

                          if(searchProvider.productTypeIndex == 1  && selectedCategoryIdsList.isEmpty && selectedBrandIdsList.isEmpty && searchProvider.productTypeIndex == 0) {
                            showCustomSnackBar('${getTranslated('select_brand_or_category_first', context)}', context, isToaster: true);
                          } else if (searchProvider.productTypeIndex == 2 &&((searchProvider.selectedAuthorIds.isEmpty && searchProvider.publishingHouseIds.isEmpty) || (searchProvider.selectedSellerAuthorIds.isEmpty && searchProvider.sellerPublishingHouseIds.isEmpty)) && searchProvider.productTypeIndex == 0){
                            showCustomSnackBar('${getTranslated('select_author_or_publishing_first', context)}', context, isToaster: true);
                          } else{
                            String selectedCategoryId = selectedCategoryIdsList.isNotEmpty? jsonEncode(selectedCategoryIdsList) : '[]';
                            String selectedBrandId = selectedBrandIdsList.isNotEmpty? jsonEncode(selectedBrandIdsList) : '[]';
                            String selectedAuthorId = widget.fromShop ?
                            searchProvider.selectedSellerAuthorIds.isNotEmpty? jsonEncode(searchProvider.selectedSellerAuthorIds) : '[]' :
                            searchProvider.selectedAuthorIds.isNotEmpty? jsonEncode(searchProvider.selectedAuthorIds) : '[]';
                            String selectedPublishingId =  widget.fromShop ?
                            searchProvider.sellerPublishingHouseIds.isNotEmpty? jsonEncode(searchProvider.sellerPublishingHouseIds) : '[]' :
                            searchProvider.publishingHouseIds.isNotEmpty? jsonEncode(searchProvider.publishingHouseIds) : '[]';

                            if(widget.fromShop) {
                              productController.getSellerProductList(widget.sellerId.toString(), 1, "", categoryIds: selectedCategoryId,
                                brandIds: selectedBrandId, authorIds: selectedAuthorId, publishingIds: selectedPublishingId,
                                productType:  searchProvider.productTypeIndex == 0 ? 'all' : searchProvider.productTypeIndex == 1 ? 'physical' : 'digital'
                              ).then((value) {
                                if(value.response?.statusCode == 200){
                                  if(context.mounted) {
                                    Navigator.pop(context);
                                  }
                                }
                              });
                            } else {
                              searchProvider.searchProduct(query : searchProvider.searchController.text.toString(),
                                offset: 1, brandIds: selectedBrandId, categoryIds: selectedCategoryId, authorIds: selectedAuthorId, publishingIds: selectedPublishingId,
                                sort: searchProvider.sortText, priceMin: searchProvider.minPriceForFilter.toString(), priceMax: searchProvider.maxPriceForFilter.toString());
                              Navigator.pop(context);
                            }
                          }
                        },

                      ),
                    ),
                  ],
                ),
              );
            });
          });
        });
      }),
    );
  }
}

class FilterItemWidget extends StatelessWidget {
  final String? title;
  final int index;
  const FilterItemWidget({super.key, required this.title, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
      child: Container(decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)),
        child: Row(children: [
          Padding(padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
            child: InkWell(
                onTap: ()=> Provider.of<SearchProductController>(context, listen: false).setFilterIndex(index),
                child: Icon(Provider.of<SearchProductController>(context).filterIndex == index? Icons.check_box_rounded: Icons.check_box_outline_blank_rounded,
                    color: (Provider.of<SearchProductController>(context).filterIndex == index )? Theme.of(context).primaryColor: Theme.of(context).hintColor.withValues(alpha:.5))),
          ),
          Expanded(child: Text(title??'', style: textRegular.copyWith())),

        ],),),
    );
  }
}

class CategoryFilterItem extends StatelessWidget {
  final String? title;
  final bool checked;
  final Function()? onTap;
  const CategoryFilterItem({super.key, required this.title, required this.checked, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
      child: InkWell(
        onTap: onTap,
        child: Container(decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Padding(padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
              child: Icon(checked? Icons.check_box_rounded: Icons.check_box_outline_blank_rounded,
                  color: (checked && !Provider.of<ThemeController>(context, listen: false).darkTheme)?
                  Theme.of(context).primaryColor:(checked && Provider.of<ThemeController>(context, listen: false).darkTheme)?
                  Colors.white : Theme.of(context).hintColor.withValues(alpha:.5)),
            ),
            Expanded(child: Text(title??'', style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color))),

          ],),),
      ),
    );
  }
}

