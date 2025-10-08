import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_loader_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/seller_product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/domain/models/author_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/controllers/shop_controller.dart';
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
import 'package:provider/provider.dart';

class ClearanceProductFilterDialog extends StatefulWidget {
  final int? sellerId;
  final bool fromShop;
  final List<AuthorModel>? authorList;
  final List<AuthorModel>? publishingHouse;
  final void Function() applyFilter;

  const ClearanceProductFilterDialog({super.key, this.sellerId,  this.fromShop = true, this.authorList, this.publishingHouse, required this.applyFilter});

  @override
  ClearanceProductFilterDialogState createState() => ClearanceProductFilterDialogState();
}

class ClearanceProductFilterDialogState extends State<ClearanceProductFilterDialog> {
  List<int> authors = [];
  List<int> publishingHouses = [];

  List<AuthorModel>? _authorList;
  List<AuthorModel>? _publishingHouse;

  @override
  void initState() {
    super.initState();

    _authorList = widget.authorList;
    _publishingHouse = widget.publishingHouse;

    if(_authorList!.isNotEmpty) {
      for (int i =0; i< _authorList!.length; i++) {
        authors.add(i);
      }
    }

    if(_publishingHouse!.isNotEmpty) {
      for (int i=0; i < _publishingHouse!.length; i++) {
        publishingHouses.add(i);
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);

    return Dismissible(
      key: const Key('key'),
      direction: DismissDirection.down,
      onDismissed: (_) => Navigator.pop(context),
      child: Consumer<SearchProductController>(builder: (context, searchProvider, child) {
        if(widget.fromShop){
          _authorList = searchProvider.sellerAuthorsList;
          _publishingHouse = searchProvider.sellerPublishingHouseList;
        }else{
          _authorList = searchProvider.authorsList;
         _publishingHouse = searchProvider.publishingHouseList;
        }
        return Consumer<CategoryController>(builder: (context, categoryProvider,_) {
          return Consumer<BrandController>(builder: (context, brandProvider,_) {
            return Consumer<SellerProductController>(builder: (context, productController, _) {
              return Consumer<ShopController>(builder: (context, shopController, _) {
                  return Container(
                    constraints: BoxConstraints(maxHeight: size.height * 0.9),
                    decoration: BoxDecoration(color: Theme.of(context).highlightColor,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
                    child: Column(
                      children: [

                        Column(mainAxisSize: MainAxisSize.min, children: [
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
                                await categoryProvider.resetChecked(widget.fromShop ? widget.sellerId! : null, widget.fromShop);
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
                                }
                                shopController.disableSearch();

                                if(context.mounted) {Navigator.of(context).pop();}
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
                            child: Column( crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
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
                                          onChanged: (value) {searchProvider.setProductTypeIndex(value == 'all_product_search' ? 0 : value == 'physical' ? 1 : 2, true);},
                                          isExpanded: true,
                                          underline: const SizedBox(),
                                        ),
                                      ),
                                    ]),
                                  ),
                                  const SizedBox(height: Dimensions.paddingSizeSmall),
                                ],

                                // Category
                                Text(getTranslated('CATEGORY', context) ?? '', style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge,  color: Theme.of(context).textTheme.bodyLarge?.color)),

                                Divider(color: Theme.of(context).hintColor.withValues(alpha:.25), thickness: .5),

                                if(categoryProvider.categoryList.isNotEmpty)
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: 40.0,
                                      maxHeight: 350.0,
                                    ),
                                    child: ListView.builder(
                                        itemCount: categoryProvider.categoryList.length,
                                        shrinkWrap: true,
                                        itemBuilder: (context, index){
                                          return Column(children: [
                                            CategoryFilterItem(title: categoryProvider.categoryList[index].name,
                                                checked: categoryProvider.categoryList[index].isSelected!,
                                                onTap: () => categoryProvider.checkedToggleCategory(index)),
                                            if(categoryProvider.categoryList[index].isSelected!)
                                              Padding(padding: const EdgeInsets.only(left: Dimensions.paddingSizeExtraLarge),
                                                child: ListView.builder(
                                                    itemCount: categoryProvider.categoryList[index].subCategories?.length??0,
                                                    shrinkWrap: true,
                                                    padding: EdgeInsets.zero,
                                                    physics: const NeverScrollableScrollPhysics(),
                                                    itemBuilder: (context, subIndex){
                                                      return CategoryFilterItem(title: categoryProvider.categoryList[index].subCategories![subIndex].name,
                                                          checked: categoryProvider.categoryList[index].subCategories![subIndex].isSelected!,
                                                          onTap: () => categoryProvider.checkedToggleSubCategory(index, subIndex));
                                                    }),
                                              )
                                          ],
                                          );
                                        }),
                                  ),

                                // Brand
                                if((searchProvider.productTypeIndex == 0 || searchProvider.productTypeIndex == 1) && brandProvider.brandList.isNotEmpty)...[
                                  Padding(padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
                                      child: Text(getTranslated('brand', context)??'', style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge,  color: Theme.of(context).textTheme.bodyLarge?.color))
                                  ),

                                  Divider(color: Theme.of(context).hintColor.withValues(alpha:.25), thickness: .5),

                                  if(brandProvider.brandList.isNotEmpty)
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minHeight: 40.0,
                                        maxHeight: 350.0,
                                      ),
                                      child: SizedBox(
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
                                ],

                                //Author
                                if((_authorList!.isNotEmpty) && (searchProvider.productTypeIndex == 0 || searchProvider.productTypeIndex == 2))...[
                                  const SizedBox(height: Dimensions.paddingSizeSmall),
                                  Text(getTranslated('author_creator_artist', context) ?? '',
                                      style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge,  color: Theme.of(context).textTheme.bodyLarge?.color)
                                  ),
                                  const SizedBox(height: Dimensions.paddingSizeSmall),

                                  Autocomplete<int> (
                                    optionsBuilder: (TextEditingValue value) {
                                      if (value.text.isEmpty) {
                                        return const Iterable<int>.empty();
                                      } else {
                                        return authors.where((author) => _authorList![author].name!.toLowerCase().contains(value.text.toLowerCase()));
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
                                    displayStringForOption: (value) =>  _authorList![value].name!,
                                    onSelected: (int value) {
                                      searchProvider.checkedToggleAuthors(value, widget.fromShop);
                                    },
                                  ),

                                  if(_authorList != null && _authorList!.isNotEmpty)
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minHeight: 40.0,
                                        maxHeight: 350.0,
                                      ),
                                      child: SizedBox(
                                        child: ListView.builder(
                                            itemCount: _authorList?.length,
                                            shrinkWrap: true,
                                            itemBuilder: (context, index){
                                              return Column(children: [
                                                CategoryFilterItem(title: _authorList![index].name,
                                                  checked: _authorList![index].isChecked!,
                                                  onTap: () {
                                                    searchProvider.checkedToggleAuthors(index, widget.fromShop);
                                                  },
                                                )
                                              ],
                                              );
                                            }),
                                      ),
                                    ),
                                ],

                                //Publishing House
                                if((_publishingHouse != null && _publishingHouse!.isNotEmpty) && (searchProvider.productTypeIndex == 0 || searchProvider.productTypeIndex == 2))...[
                                  const SizedBox(height: Dimensions.paddingSizeSmall),
                                  Text( getTranslated('publishing_house', context) ?? '',
                                      style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge,  color: Theme.of(context).textTheme.bodyLarge?.color)
                                  ),
                                  const SizedBox(height: Dimensions.paddingSizeSmall),

                                  Autocomplete<int> (
                                    optionsBuilder: (TextEditingValue value) {
                                      if (value.text.isEmpty) {
                                        return const Iterable<int>.empty();
                                      } else {
                                        return publishingHouses.where((author) => _publishingHouse![author].name!.toLowerCase().contains(value.text.toLowerCase()));
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
                                    displayStringForOption: (value) =>  _publishingHouse![value].name!,
                                    onSelected: (int value) {
                                      searchProvider.checkedTogglePublishingHouse(value, widget.fromShop);
                                    },
                                  ),

                                  if(_publishingHouse != null && _publishingHouse!.isNotEmpty)
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minHeight: 40.0,
                                        maxHeight: 350.0,
                                      ),
                                      child: SizedBox(
                                        child: ListView.builder(
                                            itemCount: _publishingHouse?.length,
                                            shrinkWrap: true,
                                            itemBuilder: (context, index){
                                              return Column(children: [
                                                CategoryFilterItem(title: _publishingHouse![index].name,
                                                    checked: _publishingHouse![index].isChecked!,
                                                    onTap: () => searchProvider.checkedTogglePublishingHouse(index, widget.fromShop)),
                                              ],);
                                            }),
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
                            onTap: widget.applyFilter,
                          ),
                        ),
                      ],
                    ),
                  );
                }
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
          Expanded(child: Text(title??'', style: textRegular.copyWith( color: Theme.of(context).textTheme.bodyLarge?.color))),

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
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Padding(padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
              child: Icon(checked? Icons.check_box_rounded: Icons.check_box_outline_blank_rounded,
                  color: (checked && !Provider.of<ThemeController>(context, listen: false).darkTheme)?
                  Theme.of(context).primaryColor:(checked && Provider.of<ThemeController>(context, listen: false).darkTheme)?
                  Colors.white : Theme.of(context).hintColor.withValues(alpha:.5)),
            ),
            Expanded(child: Text(title??'', style: textRegular.copyWith( color: Theme.of(context).textTheme.bodyLarge?.color))),

          ],),),
      ),
    );
  }
}

