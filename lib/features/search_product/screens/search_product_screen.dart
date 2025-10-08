
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/brand/controllers/brand_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/controllers/category_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/widgets/partial_matched_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/widgets/search_product_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/controllers/search_product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/product_shimmer_widget.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  ScrollController scrollController = ScrollController();
  @override
  void initState() {
    Provider.of<SearchProductController>(context, listen: false).cleanSearchProduct();
    Provider.of<SearchProductController>(context, listen: false).initHistoryList();
    Provider.of<SearchProductController>(context, listen: false).setInitialFilerData();

    Provider.of<CategoryController>(context, listen: false).resetChecked(null, false);
    Provider.of<SearchProductController>(context, listen: false).setFilterApply(isFiltered: false);
    Provider.of<CategoryController>(context, listen: false).selectedCategoryIds.clear();
    Provider.of<BrandController>(context, listen: false).selectedBrandIds.clear();
    Provider.of<SearchProductController>(context, listen: false).selectedSellerAuthorIds.clear();
    Provider.of<SearchProductController>(context, listen: false).sellerPublishingHouseIds.clear();
    Provider.of<SearchProductController>(context, listen: false).publishingHouseIds.clear();
    Provider.of<SearchProductController>(context, listen: false).selectedAuthorIds.clear();
    // Provider.of<SearchProductController>(context, listen: false).resetChecked(null, false);
    super.initState();
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: CustomAppBar(title: getTranslated('search_product', context)),
      body: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(color: Theme.of(context).canvasColor,
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.1), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 1),)]),
              child: const SearchSuggestion()),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            Consumer<SearchProductController>(
              builder: (context, searchProvider, child) {
                return (searchProvider.isLoading && searchProvider.searchedProduct == null) ?
                ProductShimmer(isHomePage: false, isEnabled : searchProvider.searchedProduct == null) :
                (searchProvider.searchedProduct != null && searchProvider.isClear) ?
                ((searchProvider.searchedProduct != null && searchProvider.searchedProduct?.products != null && searchProvider.searchedProduct!.products!.isNotEmpty) || (searchProvider.isSortingApplied || searchProvider.isFilterApplied)) ?
                const SearchProductWidget() : const NoInternetOrDataScreenWidget(isNoInternet: false) :
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Consumer<SearchProductController>(
                        builder: (context, searchProvider, child) {
                          return Padding( padding: const EdgeInsets.symmetric(horizontal:  Dimensions.paddingSizeLarge),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              if(searchProvider.historyList.isNotEmpty)
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Expanded(child: Text(getTranslated('search_history', context)!, style: textMedium.copyWith(fontSize : Dimensions.fontSizeLarge))),


                                  InkWell(borderRadius: BorderRadius.circular(10),
                                      onTap: () => Provider.of<SearchProductController>(context, listen: false).clearSearchAddress(),
                                      child: Container(padding: const EdgeInsets.symmetric(horizontal:Dimensions.paddingSizeDefault,
                                          vertical:Dimensions.paddingSizeLarge ),
                                          child: Text(getTranslated('clear_all', context)!,
                                              style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault,
                                                  color: Provider.of<ThemeController>(context).darkTheme? Colors.white : Theme.of(context).colorScheme.error))))]),



                              Wrap(direction: Axis.horizontal, alignment : WrapAlignment.start,
                                children: [for (int index =0; index < searchProvider.historyList.length; index++)
                                  Padding(padding:  const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                                    child: Container(decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.all(Radius.circular(50)),
                                        color: Provider.of<ThemeController>(context, listen: false).darkTheme? Colors.grey.withValues(alpha:0.2): Theme.of(context).colorScheme.onPrimary.withValues(alpha:.1)),
                                      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall-3, horizontal: Dimensions.paddingSizeSmall),
                                      margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                                      child: InkWell(onTap: () => searchProvider.searchProduct( query : searchProvider.historyList[index], offset: 1),
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width*0.85),
                                          child: Row(mainAxisSize:MainAxisSize.min,children: [
                                            Flexible(child: Text(searchProvider.historyList[index],
                                                style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color),
                                                overflow: TextOverflow.ellipsis)),
                                            const SizedBox(width: Dimensions.paddingSizeExtraSmall,),
                                            InkWell(onTap: () {
                                              //searchProvider.historyList.removeAt(index);
                                              searchProvider.removeSearchAddress(index);
                                              setState(() {});
                                            },
                                                child: SizedBox(width: 20, child: Image.asset(Images.cancel, color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha:.5),)))])))))]),
                             ],
                            ),
                          );
                        }
                    ),

                  Padding(padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault,left: Dimensions.paddingSizeDefault,right: Dimensions.paddingSizeDefault),
                    child: Text(getTranslated('popular_tag', context)!, style: textMedium.copyWith(fontSize : Dimensions.fontSizeLarge)),),


                  Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    child: Consumer<SplashController>(
                      builder: (context, popularTagProvider,_) {
                        return Wrap(direction: Axis.horizontal, alignment : WrapAlignment.start,
                          children: [for (int index = 0; index < popularTagProvider.configModel!.popularTags!.length; index++)
                            Padding(padding:  const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                              child: Container(decoration: BoxDecoration(
                                  border: Border.all(width: .5, color: Theme.of(context).primaryColor.withValues(alpha:.125)),
                                  borderRadius: const BorderRadius.all(Radius.circular(50))),
                                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall-3, horizontal: Dimensions.paddingSizeSmall),
                                margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                                child: InkWell(onTap: () => Provider.of<SearchProductController>(context, listen: false).searchProduct(query : popularTagProvider.configModel!.popularTags![index].tag??'', offset: 1),
                                  child: ConstrainedBox(constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width*0.85),
                                    child: Row(mainAxisSize:MainAxisSize.min,children: [
                                      Flexible(child: Text(popularTagProvider.configModel!.popularTags![index].tag??'',
                                          style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color),
                                          overflow: TextOverflow.ellipsis))])))))]);})),
                  ],
                );
              },
            ),
          ],
          ),)
        ],
      ),
    );
  }
}
