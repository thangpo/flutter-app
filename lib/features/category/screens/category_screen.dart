
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/domain/models/category_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/screens/brand_and_category_product_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/controllers/category_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:provider/provider.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    Provider.of<ProductController>(context, listen: false).initBrandOrCategoryProductList(
      isBrand: false,
      id: Provider.of<CategoryController>(context, listen: false).categoryList[0].id,
      offset: 1,
      isUpdate: false,
    );

    Provider.of<CategoryController>(context, listen: false).onChangeSelectedIndex(0, isUpdate: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: getTranslated('CATEGORY', context)),
      body: Consumer<CategoryController>(
        builder: (context, categoryProvider, child) {
          return categoryProvider.categoryList.isNotEmpty ?
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

            Expanded(flex: 3, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeEight),
              height: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).highlightColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    offset: const Offset(1, -1),
                    spreadRadius: 0,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: categoryProvider.categoryList.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  CategoryModel category = categoryProvider.categoryList[index];
                  return InkWell(
                    onTap: () {
                      categoryProvider.onChangeSelectedIndex(index);
                      Provider.of<ProductController>(context, listen: false).initBrandOrCategoryProductList(
                        isBrand: false,
                        id: categoryProvider.categoryList[index].id,
                        offset: 1,
                      );
                    },
                    child: CategoryItem(
                      title: category.name,
                      icon: category.imageFullUrl?.path,
                      isSelected: categoryProvider.categorySelectedIndex == index,
                    ),
                  );
                },
              ),
            )),

            Expanded(flex: 7, child: Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraExtraSmall),
                decoration: BoxDecoration(
                  color: Theme.of(context).highlightColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      offset: const Offset(0, 1),
                      spreadRadius: 0,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: ListView.separated(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: categoryProvider.categoryList[categoryProvider.categorySelectedIndex!].subCategories!.length + 1,
                  itemBuilder: (context, index) {
                    late SubCategory subCategory;
                    if(index != 0) {
                      subCategory = categoryProvider.categoryList[categoryProvider.categorySelectedIndex!].subCategories![index-1];
                    }
                    if(index == 0) {
                      return Ink(
                        color: Theme.of(context).highlightColor,
                        child: ListTile(
                          visualDensity: const VisualDensity(vertical: -4),
                          title: Padding(
                            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                            child: Text(
                                (((categoryProvider.categoryList[categoryProvider.categorySelectedIndex!].subCategories?.length ?? 0) > 1)) ?
                                getTranslated('all_products', context)! : getTranslated('view_all_products', context)!,
                                style: textBold.copyWith(fontSize: Dimensions.fontSizeSmall),
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          onTap: () {

                            Navigator.push(context, MaterialPageRoute(builder: (_) => BrandAndCategoryProductScreen(
                              isBrand: false,
                              id: categoryProvider.categoryList[categoryProvider.categorySelectedIndex!].id,
                              name: categoryProvider.categoryList[categoryProvider.categorySelectedIndex!].name,
                              categoryModel: categoryProvider.categoryList[categoryProvider.categorySelectedIndex!],
                              isAllProduct: true,
                            )));
                          },
                        ),
                      );
                    } else if (subCategory.subSubCategories?.isNotEmpty ?? false) {
                      return Ink(
                          color: Theme.of(context).highlightColor,
                          child: ExpansionTile(
                              visualDensity: const VisualDensity(vertical: -4),
                              tilePadding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                              iconColor: Theme.of(context).textTheme.bodyLarge?.color,
                              shape: const Border(),
                              key: Key('${Provider.of<CategoryController>(context).categorySelectedIndex}$index'),
                              title: Text(subCategory.name ?? '', style: textBold.copyWith(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontSize: Dimensions.fontSizeSmall,
                              ), maxLines: 2, overflow: TextOverflow.ellipsis),
                              children: _getSubSubCategories(context, subCategory)
                          ),
                      );
                    } else {
                      return Ink(
                        color: Theme.of(context).highlightColor,
                        child: ListTile(
                          title: Text(subCategory.name ?? '', style: textBold.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                          ), maxLines: 2, overflow: TextOverflow.ellipsis),
                          contentPadding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault),
                          trailing: Icon(Icons.navigate_next, color: Theme.of(context).textTheme.bodyLarge!.color),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => BrandAndCategoryProductScreen(
                              isBrand: false,
                              id: subCategory.id,
                              name: categoryProvider.categoryList[categoryProvider.categorySelectedIndex!].name,
                              categoryModel: categoryProvider.categoryList[categoryProvider.categorySelectedIndex!]
                            )));
                          },
                        ),
                      );
                    }
                  },
                  separatorBuilder: (context, index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    child: Divider(
                      color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.10),
                      thickness: 1,
                    ),
                  ),
                ),
              ),
            )),

          ]) : Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor)));
        },
      ),
    );
  }

  List<Widget> _getSubSubCategories(BuildContext context, SubCategory subCategory) {

    List<Widget> subSubCategories = [];
    subSubCategories.add(ListTile(
      visualDensity: const VisualDensity(vertical: -4),
      title: Row(children: [
        const SizedBox(width: Dimensions.paddingSizeSmall),
    
        Flexible(child: Text(getTranslated('all_products', context)!, style: textRegular.copyWith(
          fontSize: Dimensions.fontSizeSmall,
          color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.80)
        ), maxLines: 2, overflow: TextOverflow.ellipsis)),
    
      ]),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => BrandAndCategoryProductScreen(
          isBrand: false,
          id: subCategory.id,
          name: subCategory.name,
          subCategory: subCategory,
          isAllProduct: true,
        )));
      },
    ));
    for(int index=0; index < subCategory.subSubCategories!.length; index++) {
      subSubCategories.add(ListTile(
        visualDensity: const VisualDensity(vertical: -4),
        title: Row(children: [

          const SizedBox(width: Dimensions.paddingSizeSmall),

          Flexible(
            child: Text(subCategory.subSubCategories![index].name!, style: textRegular.copyWith(
              color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.80),
              fontSize: Dimensions.fontSizeSmall,
            ), maxLines: 2, overflow: TextOverflow.ellipsis),
          ),

        ]),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => BrandAndCategoryProductScreen(
            isBrand: false,
            id: subCategory.subSubCategories![index].id,
            name: subCategory.name,
            subCategory: subCategory,
          )));
        },
      ));
    }
    return subSubCategories;
  }
}

class CategoryItem extends StatelessWidget {
  final String? title;
  final String? icon;
  final bool isSelected;
  const CategoryItem({super.key, required this.title, required this.icon, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, boxConstraints) {
        return Container(
          height: boxConstraints.maxWidth,
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
          margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall, horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
            color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Theme.of(context).hintColor.withValues(alpha: 0.07),
          ),
          child: Center(child: Column(children: [

            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: CustomImageWidget(fit: BoxFit.cover, image: '$icon', height: 40, width: 40),
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
              child: Text(title!, maxLines: 2, style: textBold.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                height: 1.0,
                color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
              ), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            ),
          ])),
        );
      }
    );
  }
}

