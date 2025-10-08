import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/title_row_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/banner/controllers/banner_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/banner/widgets/fashion_banner_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/banner/widgets/single_banner_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/brand/controllers/brand_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/controllers/category_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/widgets/category_list_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/clearance_sale/widgets/clearance_sale_list_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/deal/controllers/featured_deal_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/deal/controllers/flash_deal_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/deal/screens/featured_deal_screen_view.dart';
import 'package:flutter_sixvalley_ecommerce/features/deal/screens/flash_deal_screen_view.dart';
import 'package:flutter_sixvalley_ecommerce/features/deal/widgets/featured_deal_list_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/deal/widgets/flash_deals_list_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/shimmers/flash_deal_shimmer.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/announcement_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/aster_theme/find_what_you_need_shimmer.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/aster_theme/more_store_list_view_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/fashion_theme/most_demanded_product_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/fashion_theme/shop_again_from_your_recent_store_list_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/featured_product_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/just_for_you/just_for_you_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/product_list_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/search_home_page_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/shop_again_from_recent_store_list_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/notification/controllers/notification_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/seller_product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/enums/product_type.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/widgets/latest_product_list_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/widgets/most_searching_product_list_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/widgets/recommended_product_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/screens/product_details_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/screens/search_product_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/controllers/shop_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/screens/all_shop_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/widgets/more_store_list_view.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/top_seller_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/responsive_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';


class FashionThemeHomePage extends StatefulWidget {
  const FashionThemeHomePage({super.key});

  @override
  State<FashionThemeHomePage> createState() => _FashionThemeHomePageState();

  static Future<void> loadData(bool reload) async {
    final flashDealController = Provider.of<FlashDealController>(Get.context!, listen: false);
    final shopController = Provider.of<ShopController>(Get.context!, listen: false);
    final categoryController = Provider.of<CategoryController>(Get.context!, listen: false);
    final bannerController = Provider.of<BannerController>(Get.context!, listen: false);
    final productController = Provider.of<ProductController>(Get.context!, listen: false);
    final brandController = Provider.of<BrandController>(Get.context!, listen: false);
    final featuredDealController = Provider.of<FeaturedDealController>(Get.context!, listen: false);
    final notificationController = Provider.of<NotificationController>(Get.context!, listen: false);
    final cartController = Provider.of<CartController>(Get.context!, listen: false);
    final profileController = Provider.of<ProfileController>(Get.context!, listen: false);
    final sellerProductController = Provider.of<SellerProductController>(Get.context!, listen: false);
    final splashController = Provider.of<SplashController>(Get.context!, listen: false);

    splashController.initConfig(Get.context!, null, null);

    shopController.getAllSellerList(offset: 1, isUpdate: reload);
    shopController.getTopSellerList(offset: 1, isUpdate: reload);
    if(flashDealController.flashDealList.isEmpty || reload) {
      // await flashDealController.getFlashDealList(reload, false);
    }

    bannerController.getBannerList();

    cartController.getCartData(Get.context!);

    categoryController.getCategoryList(reload);

    productController.getHomeCategoryProductList(reload);


    brandController.getBrandList(offset: 1, isUpdate: reload);

    productController.getLatestProductList(1, isUpdate: reload);
    productController.getSelectedProductModel(1, isUpdate: false);

    productController.getFeaturedProductModel(1, isUpdate: reload);

    featuredDealController.getFeaturedDealList();

    // productController.getLProductList('1', reload: reload);

    productController.getRecommendedProduct();

    productController.getMostDemandedProduct();

    productController.getMostSearchingProduct(1, isUpdate: reload);

    productController.getClearanceAllProductList(1, isUpdate: reload);

    shopController.getMoreStore();

    if(notificationController.notificationModel == null ||
        (notificationController.notificationModel != null &&
          notificationController.notificationModel!.notification!.isEmpty)
        || reload) {
      notificationController.getNotificationList(1);
    }

    if(Provider.of<AuthController>(Get.context!, listen: false).isLoggedIn()){
      if(profileController.userInfoModel == null) {
        await profileController.getUserInfo(Get.context!);
      }

      sellerProductController.getShopAgainFromRecentStore();

    }
  }

}

class _FashionThemeHomePageState extends State<FashionThemeHomePage> {
  final ScrollController _scrollController = ScrollController();

  final List<ProductType> productTypeList = [
    ProductType.newArrival,
    ProductType.topProduct,
    ProductType.bestSelling,
    ProductType.discountedProduct,
  ];



  bool singleVendor = false;
  @override
  void initState() {
    super.initState();
    singleVendor = Provider.of<SplashController>(context, listen: false).configModel!.businessMode == "single";
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(resizeToAvoidBottomInset: false,
      body: SafeArea(child: RefreshIndicator(
        onRefresh: () async {
          await FashionThemeHomePage.loadData( true);

        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
                floating: true,
                elevation: 0,
                centerTitle: false,
                automaticallyImplyLeading: false,
                backgroundColor: Theme.of(context).highlightColor,
                title: Image.asset(Images.logoWithNameImage, height: 35)),

            SliverToBoxAdapter(child: Provider.of<SplashController>(context, listen: false).configModel!.announcement!.status == '1'?
            Consumer<SplashController>(
              builder: (context, announcement, _){
                return (announcement.configModel!.announcement!.announcement != null && announcement.onOff)?
                AnnouncementWidget(announcement: announcement.configModel!.announcement):const SizedBox();
              },):const SizedBox(),),


            SliverPersistentHeader(pinned: true, delegate: SliverDelegate(
              child: InkWell(
                onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                child: const Hero(tag: 'search', child: Material(child: SearchHomePageWidget())),
              ),
            )),

            SliverToBoxAdapter(
              child: Column(children: [
                const FashionBannersWidget(),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                const CategoryListWidget(isHomePage: true),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Consumer<FlashDealController>(
                    builder: (context, megaDeal, child) {
                      return  megaDeal.flashDeal != null ? megaDeal.flashDealList.isNotEmpty ?
                      Column(children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.homePagePadding),
                          child: TitleRowWidget(title: getTranslated('flash_deal', context),
                              eventDuration: megaDeal.flashDeal != null ? megaDeal.duration : null,
                              onTap: () {Navigator.push(context, MaterialPageRoute(builder: (_) => const FlashDealScreenView()));
                              },isFlash: true),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        Text(getTranslated('flash_sale_fore_any_item', context)??'', style: textRegular.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontSize: Dimensions.fontSizeDefault,
                        )),
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        const FlashDealsListWidget(),

                      ]) : const SizedBox.shrink(): const FlashDealShimmer();

                    }),


                Consumer<FeaturedDealController>(
                  builder: (context, featuredDealProvider, child) {
                    return featuredDealProvider.featuredDealProductList != null
                        ? featuredDealProvider.featuredDealProductList!.isNotEmpty
                        ? Stack(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: 150,
                          color: Provider.of<ThemeController>(context, listen: false).darkTheme
                              ? Theme.of(context).primaryColor.withValues(alpha:0.20)
                              : Theme.of(context).primaryColor.withValues(alpha:0.125),
                        ),

                        Column(children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                            child: TitleRowWidget(
                              title: '${getTranslated('featured_deals', context)}',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const FeaturedDealScreenView(),
                                ),
                              ),
                            ),
                          ),

                          const FeaturedDealsListWidget(),

                        ]),
                      ],
                    ) : const SizedBox.shrink() : const FindWhatYouNeedShimmer();
                  },
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                const ClearanceListWidget(),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                Consumer<BannerController>(
                  builder: (context, bannerProvider, child) {
                    return bannerProvider.promoBannerMiddleTop != null ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                      child: SingleBannersWidget(
                        bannerModel: bannerProvider.promoBannerMiddleTop,
                        height: MediaQuery.of(context).size.width / 3,
                      ),
                    ) : const SizedBox();
                  },
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),



                const FeaturedProductWidget(),
                const SizedBox(height: Dimensions.paddingSizeDefault),



                singleVendor ? const SizedBox() : Consumer<ShopController>(
                    builder: (context, topStoreProvider,_) {
                      return (topStoreProvider.topSellerModel != null && (topStoreProvider.topSellerModel!.sellers!=null && topStoreProvider.topSellerModel!.sellers!.isNotEmpty))?
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        TitleRowWidget(title: getTranslated('top_fashion_house', context),
                            onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_) =>
                            const AllTopSellerScreen(title: 'top_fashion_house',)))),
                        singleVendor ? const SizedBox(height: 0):const SizedBox(height: Dimensions.paddingSizeSmall),
                        singleVendor?const SizedBox():
                        SizedBox(height: ResponsiveHelper.isTab(context)? 170 : 165, child:  const TopSellerWidget())]):
                      const SizedBox();}),


                Consumer<BannerController>(builder: (context, bannerProvider, child){
                  return bannerProvider.promoBannerLeft != null ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeDefault),
                    child: SingleBannersWidget(bannerModel : bannerProvider.promoBannerLeft, height: MediaQuery.of(context).size.width * .90),
                  ) : const SizedBox();
                }),




                const Padding(padding: EdgeInsets.only(bottom: Dimensions.homePagePadding),
                    child: RecommendedProductWidget(fromAsterTheme: true)),



                const LatestProductListWidget(),
                const SizedBox(height: Dimensions.paddingSizeDefault),


                Consumer<BannerController>(builder: (context, bannerProvider, child){
                  return bannerProvider.promoBannerMiddleBottom != null?
                  Padding(padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraLarge,
                      left:Dimensions.homePagePadding, right: Dimensions.paddingSizeSmall ),
                      child: SingleBannersWidget(bannerModel : bannerProvider.promoBannerMiddleBottom,
                          height: MediaQuery.of(context).size.width/3)):const SizedBox();}),



                Consumer<ProductController>(
                    builder: (context, productController, _) {
                      return (productController.mostSearchingProduct != null && productController.mostSearchingProduct!.products != null &&
                          productController.mostSearchingProduct!.products!.isNotEmpty)?
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        TitleRowWidget(title: getTranslated('your_most_searching', context),
                            onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_) =>
                            const MostSearchingProductListWidget()))),
                        const SizedBox(height: Dimensions.paddingSizeSmall),


                        JustForYouView(productList: productController.mostSearchingProduct?.products),
                        const SizedBox(height: Dimensions.paddingSizeDefault),

                      ]):const SizedBox();
                    }),



                Consumer<ProductController>(
                    builder: (context, demandProvider, _) {
                      return demandProvider.mostDemandedProductModel != null?
                      InkWell(onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=>
                          ProductDetails(productId: demandProvider.mostDemandedProductModel?.productId,
                              slug: demandProvider.mostDemandedProductModel?.slug))),
                          child: Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                              child: Column(children: [
                                Text(getTranslated('most_demanded_product', context)!,
                                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color),),
                                const SizedBox(height: Dimensions.paddingSizeSmall),

                                const MostDemandedProductView(),

                                const SizedBox(height: Dimensions.paddingSizeDefault),

                              ]))): const SizedBox();
                    }),



                if(Provider.of<AuthController>(Get.context!, listen: false).isLoggedIn())
                  Consumer<SellerProductController>(
                      builder: (context, shopAgainProvider,_) {
                        return shopAgainProvider.shopAgainFromRecentStoreList.isNotEmpty?
                        Column(children: [
                          TitleRowWidget(
                            title: getTranslated('shop_again_from_recent_store', context),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_)=> const ShopAgainFromRecentStoreListWidget())),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          const SizedBox(height: 160, child: ShopAgainFromYourRecentStore()),

                          const SizedBox(height: Dimensions.paddingSizeDefault)]):const SizedBox();}),


                Consumer<BannerController>(builder: (context, bannerProvider, child){
                  return bannerProvider.promoBannerRight != null?
                  Padding(padding: const EdgeInsets.only(bottom: Dimensions.homePagePadding,
                      left:Dimensions.bannerPadding, right: Dimensions.bannerPadding ),
                      child: SingleBannersWidget(bannerModel : bannerProvider.promoBannerRight,
                          height: MediaQuery.of(context).size.width * 1.5)):const SizedBox();}),


                Consumer<BannerController>(builder: (context, bannerProvider, child){
                  return bannerProvider.promoBannerBottom != null?
                  Padding(padding: const EdgeInsets.only(bottom: Dimensions.homePagePadding ),
                      child: SingleBannersWidget(noRadius: true, bannerModel : bannerProvider.promoBannerBottom,
                          height: MediaQuery.of(context).size.width / 10)):const SizedBox();}),




                Consumer<ShopController>(
                    builder: (context, moreSellerProvider, _) {
                      return moreSellerProvider.moreStoreList.isNotEmpty?
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Padding(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                          child: TitleRowWidget(title: getTranslated('other_store', context),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
                              const MoreStoreViewListView()))),),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        SizedBox(height: ResponsiveHelper.isTab(context)? 170 : 100, child: const MoreStoreView(isHome: true,)),
                      ],):const SizedBox();}),





              ]),
            ),

            SliverPersistentHeader(pinned: true, delegate: SliverDelegate(
              child:  Align(
                alignment: Alignment.topLeft,
                child: _AllProductTypeTabWidget(productTypeList: productTypeList),
              ),
            )),

            HomeProductListWidget(scrollController: _scrollController),
          ],
        ),
      )),
    );
  }
}

class _AllProductTypeTabWidget extends StatelessWidget {
  const _AllProductTypeTabWidget({
    required this.productTypeList,
  });

  final List<ProductType> productTypeList;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha:.125)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: Dimensions.homePagePadding, bottom: Dimensions.paddingSizeSmall),
          child: TitleRowWidget(title : getTranslated('all_products', context)!),
        ),

        Selector<ProductController, ProductType>(
          selector: (_, productController)=> productController.productType,
          builder: (context, productType, _) {
            final ProductController productController = Provider.of<ProductController>(context, listen: false);

            return Padding(
              padding: const EdgeInsets.only(bottom : Dimensions.paddingSizeSmall),
              child: SizedBox(height: 35, child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: productTypeList.length,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  separatorBuilder: (_, index) => const SizedBox(width: Dimensions.paddingSizeDefault),
                  itemBuilder: (context, index){
                    return InkWell(
                        onTap: ()=> productController.onChangeSelectedProductType(productTypeList[index]),
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: Dimensions.paddingSizeExtraSmall,
                              horizontal: Dimensions.paddingSizeDefault,
                            ),

                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                              color: Theme.of(context).cardColor,
                              border: Border.all(
                                width: 1, color: productTypeList[index] == productType
                                  ? Theme.of(context).primaryColor.withValues(alpha:.5)
                                  : Theme.of(context).cardColor,
                              ),
                            ),
                            child: Center(child: Text(_getFilterTypeTitle(productTypeList[index], context), style: textMedium.copyWith(
                              color: productTypeList[index] == productType
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).hintColor,
                            ))))
                    );
                  }),
              ),
            );
          },
        ),

      ]),
    );
  }

  String _getFilterTypeTitle(ProductType type, BuildContext context) {
    switch (type) {
      case ProductType.newArrival:
        return getTranslated('new_arrival',context)!;
      case ProductType.topProduct:
        return getTranslated('top_product',context)!;
      case ProductType.bestSelling:
        return getTranslated('best_selling',context)!;
      case ProductType.discountedProduct:
        return getTranslated('discounted_product',context)!;

      default: return getTranslated('new_arrival',context)!;

    }
  }

}

class SliverDelegate extends SliverPersistentHeaderDelegate {
  Widget child;
  double height;
  SliverDelegate({required this.child, this.height = 70});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverDelegate oldDelegate) {
    return oldDelegate.maxExtent != height || oldDelegate.minExtent != height || child != oldDelegate.child;
  }
}
