import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/title_row_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/controllers/address_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/banner/controllers/banner_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/banner/widgets/banners_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/banner/widgets/footer_banner_slider_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/banner/widgets/single_banner_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/brand/controllers/brand_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/brand/screens/brands_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/brand/widgets/brand_list_widget.dart';
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
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/featured_product_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/product_list_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/product_type_popup_menu_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/search_home_page_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/notification/controllers/notification_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/widgets/home_category_product_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/widgets/latest_product_list_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/widgets/recommended_product_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/screens/search_product_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/controllers/shop_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/screens/all_shop_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/top_seller_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/responsive_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/helper/app_globals.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/affiliate_product_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/financial_center_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/all_seller_widget.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/screens/flight_booking_screen.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/screens/tour_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/menu_widget.dart';
import '../widgets/location_list_widget.dart';


class FeatureItem {
  final String title;
  final String? description;
  final String? image;
  final IconData? icon;
  final Color? color;
  final VoidCallback onTap;

  FeatureItem({
    required this.title,
    this.description,
    this.image,
    this.icon,
    this.color,
    required this.onTap,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();

  static Future<void> loadData(bool reload) async {
    final flashDealController =
    Provider.of<FlashDealController>(Get.context!, listen: false);
    final shopController =
    Provider.of<ShopController>(Get.context!, listen: false);
    final categoryController =
    Provider.of<CategoryController>(Get.context!, listen: false);
    final bannerController =
    Provider.of<BannerController>(Get.context!, listen: false);
    final addressController =
    Provider.of<AddressController>(Get.context!, listen: false);
    final productController =
    Provider.of<ProductController>(Get.context!, listen: false);
    final brandController =
    Provider.of<BrandController>(Get.context!, listen: false);
    final featuredDealController =
    Provider.of<FeaturedDealController>(Get.context!, listen: false);
    final notificationController =
    Provider.of<NotificationController>(Get.context!, listen: false);
    final cartController =
    Provider.of<CartController>(Get.context!, listen: false);
    final profileController =
    Provider.of<ProfileController>(Get.context!, listen: false);
    final splashController =
    Provider.of<SplashController>(Get.context!, listen: false);

    if (flashDealController.flashDealList.isEmpty || reload) {
      // await flashDealController.getFlashDealList(reload, false);
    }

    splashController.initConfig(Get.context!, null, null);

    categoryController.getCategoryList(reload);

    bannerController.getBannerList();

    shopController.getAllSellerList(offset: 1, isUpdate: reload);
    shopController.getTopSellerList(offset: 1, isUpdate: reload);

    if (addressController.addressList == null ||
        (addressController.addressList != null &&
            addressController.addressList!.isEmpty) ||
        reload) {
      addressController.getAddressList();
    }

    cartController.getCartData(Get.context!);

    productController.getHomeCategoryProductList(reload);

    brandController.getBrandList(offset: 1, isUpdate: reload);

    featuredDealController.getFeaturedDealList();

    productController.getLatestProductList(1, isUpdate: reload);
    productController.getSelectedProductModel(1, isUpdate: reload);

    productController.getFeaturedProductModel(1, isUpdate: reload);

    productController.getRecommendedProduct();

    productController.getClearanceAllProductList(1, isUpdate: reload);

    if (notificationController.notificationModel == null ||
        (notificationController.notificationModel != null &&
            notificationController.notificationModel!.notification!.isEmpty) ||
        reload) {
      notificationController.getNotificationList(1);
    }

    if (Provider.of<AuthController>(Get.context!, listen: false).isLoggedIn() &&
        profileController.userInfoModel == null) {
      await profileController.getUserInfo(Get.context!);
    }
  }
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

  void passData(int index, String title) {
    index = index;
    title = title;
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Không mở được $url');
    }
  }

  bool singleVendor = false;

  @override
  void initState() {
    super.initState();

    singleVendor = Provider.of<SplashController>(context, listen: false)
        .configModel!
        .businessMode ==
        "single";
  }

  @override
  Widget build(BuildContext context) {
    final ConfigModel? configModel =
        Provider.of<SplashController>(context, listen: false).configModel;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await HomePage.loadData(true);
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
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(Images.logoWithNameImage, height: 35),
                    const MenuWidget(), // Thêm MenuWidget cạnh logo
                  ],
                ),
              ),
              SliverToBoxAdapter(
                  child: Provider.of<SplashController>(context, listen: false)
                      .configModel!
                      .announcement!
                      .status ==
                      '1'
                      ? Consumer<SplashController>(
                      builder: (context, announcement, _) {
                        return (announcement.configModel!.announcement!
                            .announcement !=
                            null &&
                            announcement.onOff)
                            ? AnnouncementWidget(
                            announcement:
                            announcement.configModel!.announcement)
                            : const SizedBox();
                      })
                      : const SizedBox()),
              SliverPersistentHeader(
                  pinned: true,
                  delegate: SliverDelegate(
                    child: InkWell(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SearchScreen())),
                      child: const Hero(
                          tag: 'search',
                          child: Material(child: SearchHomePageWidget())),
                    ),
                  )),
              SliverToBoxAdapter(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BannersWidget(),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      NewFeaturesSection(
                        features: [
                          FeatureItem(
                            title: getTranslated('flight_booking', context) ??
                                'Đặt vé máy bay',
                            image: 'assets/images/plane.png',
                            icon: Icons.flight,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                    const FlightBookingScreen()),
                              );
                            },
                          ),
                          FeatureItem(
                            title: getTranslated('tour_booking', context) ??
                                'Du lịch',
                            image: 'assets/images/travel.png',
                            icon: Icons.travel_explore,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                    const TourListScreen()),
                              );
                            },
                          ),
                        ],
                      ),

                      const CategoryListWidget(isHomePage: true),
                      const SizedBox(height: Dimensions.paddingSizeDefault),


                      const AffiliateProductWidget(),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      Consumer<FlashDealController>(
                          builder: (context, megaDeal, child) {
                            return megaDeal.flashDeal == null
                                ? const FlashDealShimmer()
                                : megaDeal.flashDealList.isNotEmpty
                                ? Column(children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal:
                                    Dimensions.paddingSizeDefault),
                                child: TitleRowWidget(
                                  title:
                                  getTranslated('flash_deal', context)
                                      ?.toUpperCase(),
                                  eventDuration:
                                  megaDeal.flashDeal != null
                                      ? megaDeal.duration
                                      : null,
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                            const FlashDealScreenView()));
                                  },
                                  isFlash: true,
                                ),
                              ),
                              const SizedBox(
                                  height: Dimensions.paddingSizeSmall),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal:
                                    Dimensions.paddingSizeDefault),
                                child: Text(
                                  getTranslated(
                                      'hurry_up_the_offer_is_limited_grab_while_it_lasts',
                                      context) ??
                                      '',
                                  style: textRegular.copyWith(
                                      color: Provider.of<ThemeController>(
                                          context,
                                          listen: false)
                                          .darkTheme
                                          ? Theme.of(context).hintColor
                                          : Theme.of(context)
                                          .primaryColor,
                                      fontSize:
                                      Dimensions.fontSizeDefault),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(
                                  height: Dimensions.paddingSizeSmall),
                              const FlashDealsListWidget()
                            ])
                                : const SizedBox.shrink();
                          }),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                      Consumer<FeaturedDealController>(
                          builder: (context, featuredDealProvider, child) {
                            return featuredDealProvider.featuredDealProductList !=
                                null
                                ? featuredDealProvider
                                .featuredDealProductList!.isNotEmpty
                                ? Column(
                              children: [
                                Stack(children: [
                                  Container(
                                    width:
                                    MediaQuery.of(context).size.width,
                                    height: 150,
                                    color: Provider.of<ThemeController>(
                                        context,
                                        listen: false)
                                        .darkTheme
                                        ? Theme.of(context).highlightColor
                                        : Theme.of(context)
                                        .colorScheme
                                        .onTertiary,
                                  ),
                                  Column(children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: Dimensions
                                              .paddingSizeDefault),
                                      child: TitleRowWidget(
                                        title:
                                        '${getTranslated('featured_deals', context)}',
                                        onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                const FeaturedDealScreenView())),
                                      ),
                                    ),
                                    const FeaturedDealsListWidget(),
                                  ]),
                                ]),
                                const SizedBox(
                                    height:
                                    Dimensions.paddingSizeDefault),
                              ],
                            )
                                : const SizedBox.shrink()
                                : const FindWhatYouNeedShimmer();
                          }),

                      const ClearanceListWidget(),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      Consumer<BannerController>(
                          builder: (context, footerBannerProvider, child) {
                            return footerBannerProvider.footerBannerList != null &&
                                footerBannerProvider
                                    .footerBannerList!.isNotEmpty
                                ? Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeDefault),
                                child: SingleBannersWidget(
                                    bannerModel: footerBannerProvider
                                        .footerBannerList?[0]))
                                : const SizedBox();
                          }),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      const FeaturedProductWidget(),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      singleVendor
                          ? const SizedBox()
                          : Consumer<ShopController>(
                          builder: (context, topSellerProvider, child) {
                            return (topSellerProvider.topSellerModel !=
                                null &&
                                (topSellerProvider
                                    .topSellerModel!.sellers !=
                                    null &&
                                    topSellerProvider.topSellerModel!
                                        .sellers!.isNotEmpty))
                                ? TitleRowWidget(
                                title:
                                getTranslated('top_seller', context),
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const AllTopSellerScreen(
                                          title: 'top_stores',
                                        ))))
                                : const SizedBox();
                          }),
                      singleVendor
                          ? const SizedBox(height: 0)
                          : const SizedBox(height: Dimensions.paddingSizeSmall),

                      singleVendor
                          ? const SizedBox()
                          : Consumer<ShopController>(
                          builder: (context, topSellerProvider, child) {
                            return (topSellerProvider.topSellerModel !=
                                null &&
                                (topSellerProvider
                                    .topSellerModel!.sellers !=
                                    null &&
                                    topSellerProvider.topSellerModel!
                                        .sellers!.isNotEmpty))
                                ? Padding(
                                padding: const EdgeInsets.only(
                                    bottom:
                                    Dimensions.paddingSizeDefault),
                                child: SizedBox(
                                    height:
                                    ResponsiveHelper.isTab(context)
                                        ? 170
                                        : 165,
                                    child: const TopSellerWidget()))
                                : const SizedBox();
                          }),
                      LocationListWidget(),
                      const Padding(
                          padding: EdgeInsets.only(
                              bottom: Dimensions.paddingSizeDefault),
                          child: RecommendedProductWidget()),

                      const Padding(
                          padding: EdgeInsets.only(
                              bottom: Dimensions.paddingSizeDefault),
                          child: LatestProductListWidget()),

                      if (configModel?.brandSetting == "1")
                        TitleRowWidget(
                          title: getTranslated('brand', context),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const BrandsView())),
                        ),
                      SizedBox(
                          height: configModel?.brandSetting == "1"
                              ? Dimensions.paddingSizeSmall
                              : 0),

                      if (configModel!.brandSetting == "1") ...[
                        const BrandListWidget(isHomePage: true),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                      ],
                      const HomeCategoryProductWidget(isHomePage: true),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      const FooterBannerSliderWidget(),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                    ]),
              ),
              SliverPersistentHeader(
                  pinned: true,
                  delegate: SliverDelegate(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: const ProductPopupFilterWidget()),
                    ),
                  )),
              HomeProductListWidget(scrollController: _scrollController),
            ],
          ),
        ),
      ),
    );
  }
}

class NewFeaturesSection extends StatelessWidget {
  final List<FeatureItem> features;

  const NewFeaturesSection({
    super.key,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeController>(context).darkTheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
            Theme.of(context).cardColor,
            Theme.of(context).cardColor.withOpacity(0.8),
          ]
              : [
            Colors.white,
            Colors.blue.shade50.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.blue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Transform.rotate(
                        angle: (1 - value) * 0.5,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkMode
                            ? [
                          Theme.of(context).primaryColorDark,
                          Theme.of(context).primaryColorDark.withOpacity(0.8),
                        ]
                            : [
                          Colors.blue.shade600,
                          Colors.blue.shade400,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode
                              ? Colors.black.withOpacity(0.3)
                              : Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(20 * (1 - value), 0),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getTranslated('experience_services', context) ??
                              'Trải nghiệm dịch vụ tiện ích',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Theme.of(context).colorScheme.onPrimary
                                : Colors.blue.shade900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFeaturesGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    if (features.length <= 2) {
      return Row(
        children: features.asMap().entries.map((entry) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildFeatureCard(entry.value, entry.key),
            ),
          );
        }).toList(),
      );
    } else if (features.length <= 4) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: features.length,
        itemBuilder: (context, index) {
          return _buildFeatureCard(features[index], index);
        },
      );
    } else {
      return SizedBox(
        height: 140,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: features.length,
          itemBuilder: (context, index) {
            return Container(
              width: 130,
              margin: EdgeInsets.only(
                right: index == features.length - 1 ? 0 : 12,
              ),
              child: _buildFeatureCard(features[index], index),
            );
          },
        ),
      );
    }
  }

  Widget _buildFeatureCard(FeatureItem feature, int index) {
    final Color featureColor = feature.color ?? Colors.blue;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value.clamp(0.0, 1.0),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: _AnimatedFeatureCard(
        feature: feature,
        featureColor: featureColor,
      ),
    );
  }
}

class _AnimatedFeatureCard extends StatefulWidget {
  final FeatureItem feature;
  final Color featureColor;

  const _AnimatedFeatureCard({
    required this.feature,
    required this.featureColor,
  });

  @override
  State<_AnimatedFeatureCard> createState() => _AnimatedFeatureCardState();
}

class _AnimatedFeatureCardState extends State<_AnimatedFeatureCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeController>(context).darkTheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: InkWell(
          onTap: widget.feature.onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Theme.of(context).cardColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered
                    ? widget.featureColor.withOpacity(0.4)
                    : widget.featureColor.withOpacity(0.2),
                width: _isHovered ? 2.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.2)
                      : widget.featureColor.withOpacity(_isHovered ? 0.2 : 0.1),
                  blurRadius: _isHovered ? 12 : 8,
                  offset: Offset(0, _isHovered ? 6 : 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isHovered ? _pulseAnimation.value : 1.0,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDarkMode
                            ? [
                          Theme.of(context).primaryColorDark.withOpacity(_isHovered ? 0.3 : 0.2),
                          Theme.of(context).primaryColorDark.withOpacity(_isHovered ? 0.2 : 0.15),
                        ]
                            : [
                          widget.featureColor
                              .withOpacity(_isHovered ? 0.2 : 0.15),
                          widget.featureColor
                              .withOpacity(_isHovered ? 0.12 : 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDarkMode
                            ? Theme.of(context).primaryColorDark.withOpacity(_isHovered ? 0.5 : 0.4)
                            : widget.featureColor
                            .withOpacity(_isHovered ? 0.4 : 0.3),
                        width: 2,
                      ),
                    ),
                    child: widget.feature.image != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        widget.feature.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            widget.feature.icon ?? Icons.star,
                            color: isDarkMode
                                ? Theme.of(context).colorScheme.onPrimary
                                : widget.featureColor,
                            size: 30,
                          );
                        },
                      ),
                    )
                        : Icon(
                      widget.feature.icon ?? Icons.star,
                      color: isDarkMode
                          ? Theme.of(context).colorScheme.onPrimary
                          : widget.featureColor,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _isHovered ? FontWeight.w700 : FontWeight.w600,
                    color: isDarkMode
                        ? Theme.of(context).colorScheme.onPrimary
                        : Colors.grey.shade800,
                    height: 1.2,
                  ),
                  child: Text(
                    widget.feature.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.feature.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.feature.description!,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDarkMode
                          ? Theme.of(context).hintColor
                          : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
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
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverDelegate oldDelegate) {
    return oldDelegate.maxExtent != height ||
        oldDelegate.minExtent != height ||
        child != oldDelegate.child;
  }
}
