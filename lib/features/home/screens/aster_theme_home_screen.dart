import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/title_row_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/banner/controllers/banner_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/banner/widgets/banners_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/banner/widgets/footer_banner_slider_widget.dart';
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
import 'package:flutter_sixvalley_ecommerce/features/home/shimmers/order_again_shimmer.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/shimmers/top_store_shimmer.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/announcement_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/aster_theme/find_what_you_need_shimmer.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/aster_theme/find_what_you_need_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/aster_theme/more_store_list_view_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/aster_theme/order_again_list_view_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/featured_product_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/just_for_you/just_for_you_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/product_list_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/product_type_popup_menu_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/search_home_page_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/notification/controllers/notification_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/controllers/order_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/seller_product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/enums/product_type.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/screens/view_all_product_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/widgets/home_category_product_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/widgets/latest_product_list_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/widgets/recommended_product_widget.dart';
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


class AsterThemeHomeScreen extends StatefulWidget {
  const AsterThemeHomeScreen({super.key});

  @override
  State<AsterThemeHomeScreen> createState() => _AsterThemeHomeScreenState();

  static Future<void> loadData(bool reload) async {
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
    final orderController = Provider.of<OrderController>(Get.context!, listen: false);
    final splashController = Provider.of<SplashController>(Get.context!, listen: false);

    splashController.initConfig(Get.context!, null, null);

    shopController.getAllSellerList(offset: 1, isUpdate: reload);

    cartController.getCartData(Get.context!);

    bannerController.getBannerList();

    categoryController.getCategoryList(reload);

    productController.getHomeCategoryProductList(reload);

    shopController.getTopSellerList(offset: 1, isUpdate: reload);

    brandController.getBrandList(offset: 1, isUpdate: reload);

    productController.getLatestProductList(1, isUpdate: false);
    productController.getSelectedProductModel(1, isUpdate: false);


    productController.getFeaturedProductModel(1, isUpdate: reload);

    featuredDealController.getFeaturedDealList();

    // productController.getLProductList('1', reload: reload);

    productController.getRecommendedProduct();

    productController.findWhatYouNeed();

    productController.getJustForYouProduct(1, isUpdate: reload);

    shopController.getMoreStore();

    productController.getClearanceAllProductList(1, isUpdate: reload);

    if(notificationController.notificationModel == null ||
        (notificationController.notificationModel != null
            && notificationController.notificationModel!.notification!.isEmpty)
        || reload) {
      notificationController.getNotificationList(1);
    }

    if(Provider.of<AuthController>(Get.context!, listen: false).isLoggedIn()){
      if(profileController.userInfoModel == null) {
        profileController.getUserInfo(Get.context!);
      }


      sellerProductController.getShopAgainFromRecentStore();


      if(orderController.orderModel == null || (orderController.orderModel != null && orderController.orderModel!.orders!.isEmpty) || reload) {
        orderController.getOrderList(1,'delivered', type: 'reorder' );
      }
    }
  }
}

class _AsterThemeHomeScreenState extends State<AsterThemeHomeScreen> {
  final ScrollController _scrollController = ScrollController();



  void passData(int index, String title) {
    index = index;
    title = title;
  }

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
            await AsterThemeHomeScreen.loadData(true);
          },
        child: CustomScrollView(controller: _scrollController, slivers: [
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

          // Search Button
          SliverPersistentHeader(pinned: true, delegate: SliverDelegate(
            child: InkWell(
              onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
              child: const Hero(tag: 'search', child: Material(child: SearchHomePageWidget())),
            ),
          )),

          SliverToBoxAdapter(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const BannersWidget(),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              const CategoryListWidget(isHomePage: true),
              const SizedBox(height: Dimensions.paddingSizeDefault),


              Consumer<FlashDealController>(
                  builder: (context, megaDeal, child) {
                    return  megaDeal.flashDeal != null ? megaDeal.flashDealList.isNotEmpty ?
                    Column(children: [
                      Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                        child: TitleRowWidget(title: getTranslated('flash_deal', context),
                            eventDuration: megaDeal.flashDeal != null ? megaDeal.duration : null,
                            onTap: () {Navigator.push(context, MaterialPageRoute(builder: (_) => const FlashDealScreenView()));
                            },isFlash: true),),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      Padding( padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                        child: Text(getTranslated('hurry_up_the_offer_is_limited_grab_while_it_lasts', context)??'',
                            textAlign: TextAlign.center,
                            style: textRegular.copyWith(color: Provider.of<ThemeController>(context, listen: false).darkTheme?
                            Theme.of(context).hintColor : Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeDefault)),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      const Padding(
                        padding: EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                        child: FlashDealsListWidget(),
                      ),
                    ]) : const SizedBox.shrink(): const FlashDealShimmer();
                  }),


              // Find what you need
              Consumer<ProductController>(
                  builder: (context, productController, _) {
                    return productController.findWhatYouNeedModel != null ?
                    (productController.findWhatYouNeedModel!.findWhatYouNeed != null &&
                        productController.findWhatYouNeedModel!.findWhatYouNeed!.isNotEmpty)?
                    Column(children: [
                      TitleRowWidget(title: getTranslated('find_what_you_need', context)),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      SizedBox(height: ResponsiveHelper.isTab(context)?  165 :150, child: const FindWhatYouNeedView()),
                      const SizedBox(height: Dimensions.paddingSizeDefault),


                    ]):const SizedBox() : const FindWhatYouNeedShimmer();}),



              //Order Again
              (Provider.of<AuthController>(context, listen: false).isLoggedIn()) ?
              Consumer<OrderController>(
                  builder: (context, orderProvider,_) {
                    return orderProvider.deliveredOrderModel != null ?
                    (orderProvider.deliveredOrderModel!.orders != null && orderProvider.deliveredOrderModel!.orders!.isNotEmpty) ?
                    const Padding(padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                      child: OrderAgainView(),
                    ):

                    Consumer<BannerController>(builder: (context, bannerProvider, child){
                      return bannerProvider.sideBarBanner != null?
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                        child: SingleBannersWidget(bannerModel : bannerProvider.sideBarBanner,
                            height: MediaQuery.of(context).size.width * 1.2),
                      ):const SizedBox();}):
                    const OrderAgainShimmerShimmer();
                  }
              ): Consumer<BannerController>(builder: (context, bannerProvider, child){
                return bannerProvider.sideBarBanner != null?
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  child: SingleBannersWidget(bannerModel : bannerProvider.sideBarBanner,
                      height: MediaQuery.of(context).size.width * 1.2),
                ):const SizedBox();}),
              const SizedBox(height: Dimensions.paddingSizeDefault,),




              //top seller
              singleVendor? const SizedBox():
              Consumer<ShopController>(
                  builder: (context, shopController,_) {
                    return shopController.topSellerModel != null? (shopController.topSellerModel!.sellers!=null && shopController.topSellerModel!.sellers!.isNotEmpty) ?
                    Column(children: [
                      TitleRowWidget(title: getTranslated('top_stores', context),
                          onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_) =>
                          const AllTopSellerScreen( title: 'top_stores',)))),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      SizedBox(height: ResponsiveHelper.isTab(context)? 180 : 165, child: const TopSellerWidget()),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                    ]): const SizedBox(): const TopStoreShimmer();}),




              Consumer<FeaturedDealController>(
                builder: (context, featuredDealProvider, child) {
                  return featuredDealProvider.featuredDealProductList != null?
                  featuredDealProvider.featuredDealProductList!.isNotEmpty ?
                  Stack(children: [
                    Container(width: MediaQuery.of(context).size.width,height: 150,
                        color: Provider.of<ThemeController>(context, listen: false).darkTheme?
                        Theme.of(context).primaryColor.withValues(alpha:.20):Theme.of(context).primaryColor.withValues(alpha:.125)),

                    Padding(padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                        child: Column(children: [
                          Padding(padding: const EdgeInsets.fromLTRB(0, Dimensions.paddingSizeDefault,0 ,
                              Dimensions.paddingSizeDefault),
                              child: TitleRowWidget(title: '${getTranslated('featured_deals', context)}',
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
                                  const FeaturedDealScreenView())))),
                          const FeaturedDealsListWidget()]))]) :
                  const SizedBox.shrink() : const FindWhatYouNeedShimmer();},),

              const ClearanceListWidget(),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              const FooterBannerSliderWidget(),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              const FeaturedProductWidget(),
              const SizedBox(height: Dimensions.paddingSizeDefault),





              Consumer<BannerController>(builder: (context, bannerProvider, child){
                return bannerProvider.topSideBarBannerBottom != null?
                Padding(padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault,
                    left:Dimensions.bannerPadding, right: Dimensions.bannerPadding ),
                    child: SingleBannersWidget(bannerModel : bannerProvider.topSideBarBannerBottom,
                        height: MediaQuery.of(context).size.width * 1.2)):const SizedBox();}),



              const Padding(padding: EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                  child: RecommendedProductWidget(fromAsterTheme: true)),



              const LatestProductListWidget(),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              //blackFriday
              Consumer<BannerController>(builder: (context, bannerProvider, child){
                return bannerProvider.footerBannerList != null && bannerProvider.footerBannerList!.isNotEmpty?
                Padding(padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault,
                    left:Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault ),
                    child: SingleBannersWidget(bannerModel : bannerProvider.footerBannerList![0],
                        height: MediaQuery.of(context).size.width * 0.5)):const SizedBox();}),





              Selector<ProductController, ProductModel?>(
                selector: (ctx, productController)=> productController.justForYouProductModel,
                builder: (context, justForYouProductModel,_) {
                  return (justForYouProductModel?.products?.isNotEmpty ?? false) ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TitleRowWidget(title: getTranslated('just_for_you', context), onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewAllProductScreen(productType: ProductType.justForYou)));
                      },),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      JustForYouView(productList: justForYouProductModel?.products),
                    ],
                  ) : const SizedBox();
                },
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),



              Consumer<ShopController>(
                  builder: (context, moreStoreProvider, _) {
                    return moreStoreProvider.moreStoreList.isNotEmpty ?
                    Column(children: [
                      TitleRowWidget(
                        title: getTranslated('more_store', context),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MoreStoreViewListView(title: getTranslated('more_store', context)))),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      const MoreStoreView(isHome: true),
                      const SizedBox(height: Dimensions.paddingSizeDefault),


                    ]):const SizedBox();
                  }),




              const HomeCategoryProductWidget(isHomePage: true),
              const SizedBox(height: Dimensions.paddingSizeDefault),


              Consumer<BannerController>(builder: (context, footerBannerProvider, child){
                return footerBannerProvider.mainSectionBanner != null?
                SingleBannersWidget(bannerModel: footerBannerProvider.mainSectionBanner,
                  height: MediaQuery.of(context).size.width/4,):const SizedBox();}),







            ]),
          ),

          SliverPersistentHeader(pinned: true, delegate: SliverDelegate(
            child:  Align(
              alignment: Alignment.topLeft,
              child: Container(color: Theme.of(context).scaffoldBackgroundColor, child: const ProductPopupFilterWidget()),
            ),
          )),


          HomeProductListWidget(scrollController: _scrollController),
        ]),
        ),
      ),
    );
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


