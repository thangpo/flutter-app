import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/seller_product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/controllers/product_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/widgets/bottom_cart_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/widgets/product_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/widgets/product_specification_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/widgets/product_title_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/widgets/promise_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/widgets/related_product_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/widgets/review_and_specification_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/widgets/shop_info_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/widgets/youtube_video_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/review/controllers/review_controller.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/shimmers/product_details_shimmer.dart';
import 'package:flutter_sixvalley_ecommerce/features/review/widgets/review_section.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/screens/shop_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/widgets/shop_more_product_view_list.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/product_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/title_row_widget.dart';
import 'package:provider/provider.dart';

class ProductDetails extends StatefulWidget {
  final int? productId;
  final String? slug;
  final bool isFromWishList;
  final bool isNotification;
  const ProductDetails({super.key, required this.productId, required this.slug, this.isFromWishList = false, this.isNotification = false});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {

  List<TextSpan> _publishingHouse = [];
  List<TextSpan> _authors = [];

  Size widgetSize = const Size(100, 400);

  Future<void> _loadData( BuildContext context) async{
    Provider.of<ProductDetailsController>(context, listen: false).getProductDetails(context, widget.productId.toString(), widget.slug.toString());
    Provider.of<ReviewController>(context, listen: false).removePrevReview();
    Provider.of<ProductDetailsController>(context, listen: false).removePrevLink();
    Provider.of<ReviewController>(context, listen: false).getReviewList(widget.productId, widget.slug, context);
    Provider.of<ProductController>(context, listen: false).removePrevRelatedProduct();
    Provider.of<ProductController>(context, listen: false).initRelatedProductList(widget.productId.toString(), context);
    Provider.of<ProductDetailsController>(context, listen: false).getCount(widget.productId.toString(), context);
    Provider.of<ProductDetailsController>(context, listen: false).getSharableLink(widget.slug.toString(), context);
  }

  @override
  void initState() {
    Provider.of<ProductDetailsController>(context, listen: false).selectReviewSection(false, isUpdate: false);
    _loadData(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ScrollController scrollController = ScrollController();
    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) async{
        if(widget.isNotification) {
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => const DashBoardScreen()), (route) => false);
        } else {
          return;
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: getTranslated('product_details', context),
          onBackPressed: () {
            if(Navigator.of(context).canPop()){
              Navigator.of(context).pop();
            }else {
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => const DashBoardScreen()), (route) => false);
            }
          },
        ),

        body: RefreshIndicator(
          onRefresh: () async => _loadData(context),
          child: Consumer<ProductDetailsController>(
            builder: (context, details, child) {
              if(details.productDetailsModel?.publishingHouse != null && details.productDetailsModel!.publishingHouse!.isNotEmpty) {
                _publishingHouse = [];
                for(String? houseName in details.productDetailsModel!.publishingHouse!) {
                  _publishingHouse.add(TextSpan(text: '${houseName!} ' , style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault)));
                }
              }

              if(details.productDetailsModel?.authors != null && details.productDetailsModel!.authors!.isNotEmpty) {
                _authors = [];
                for(String? authorName in details.productDetailsModel!.authors!) {
                  _authors.add(TextSpan(text: '${authorName!} ', style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault)));
                }
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: !details.isDetails ?
                Column(children: [

                  ProductImageWidget(productModel: details.productDetailsModel),

                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    ProductTitleWidget(
                      productModel: details.productDetailsModel,
                      averageRatting: details.productDetailsModel?.averageReview ?? "0",
                    ),

                    (details.productDetailsModel?.productType == 'digital' && (_publishingHouse.isNotEmpty || _authors.isNotEmpty)) ?
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal : Dimensions.homePagePadding),
                      child: RichText(text: TextSpan(
                          text: '',
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w400,
                            fontSize: Dimensions.fontSizeDefault,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          children: [
                            if (details.productDetailsModel?.publishingHouse != null && details.productDetailsModel!.publishingHouse!.isNotEmpty)
                              TextSpan( text: "${getTranslated('publishing_housec', context)}", style: titilliumRegular.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: Theme.of(context).hintColor,
                              )),

                            ..._publishingHouse,

                            if (details.productDetailsModel?.publishingHouse != null && details.productDetailsModel!.publishingHouse!.isNotEmpty)
                              WidgetSpan(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                                  height: 15.0, width: 1.0,
                                  color: Theme.of(context).primaryColor.withValues(alpha:0.50),
                                ),
                              ),

                            if (details.productDetailsModel?.authors != null && details.productDetailsModel!.authors!.isNotEmpty)
                              TextSpan( text: "${getTranslated('author', context)}",
                                  style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor)
                              ),
                            ..._authors,
                          ],
                      )),
                    ) : const SizedBox(),

                    const ReviewAndSpecificationSectionWidget(),

                    details.isReviewSelected?
                    Column(children: [
                      ReviewSection(details: details),

                      _ProductDetailsProductListWidget(scrollController: scrollController),


                    ]):

                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      (details.productDetailsModel?.details != null && details.productDetailsModel!.details!.isNotEmpty) ?
                      Container(
                        margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        child: ProductSpecificationWidget(
                          productSpecification: ProductHelper.removeIframe(details.productDetailsModel!.details ?? ''),
                        ),
                      ) : const SizedBox(),

                      (details.productDetailsModel?.videoUrl != null && details.isValidYouTubeUrl(details.productDetailsModel!.videoUrl!))?
                      YoutubeVideoWidget(url: details.productDetailsModel!.videoUrl):const SizedBox(),


                      (details.productDetailsModel != null) ?
                      ShopInfoWidget(sellerId: details.productDetailsModel!.addedBy == 'seller'? details.productDetailsModel!.userId.toString() : "0") : const SizedBox.shrink(),

                      const SizedBox(height: Dimensions.paddingSizeLarge,),

                      Container(padding: const EdgeInsets.only(top: Dimensions.paddingSizeLarge, bottom: Dimensions.paddingSizeDefault),
                          decoration: BoxDecoration(color: Theme.of(context).cardColor),
                          child: const PromiseWidget()),

                      _ProductDetailsProductListWidget(scrollController: scrollController),


                    ]),
                  ]),
                ]) :
                const ProductDetailsShimmer(),
              );
            },
          ),
        ),

        bottomNavigationBar: Consumer<ProductDetailsController>(
          builder: (context, details, child) {
            return !details.isDetails?
            BottomCartWidget(product: details.productDetailsModel):const SizedBox();
          }
        ),
      ),
    );
  }
}

class _ProductDetailsProductListWidget extends StatelessWidget {
  const _ProductDetailsProductListWidget({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductDetailsController>(
        builder: (context, productDetailsController, _) {
          return Column(children: [
            Consumer<SellerProductController>(
                builder: (context, sellerProductController, _) {
                  return (sellerProductController.sellerMoreProduct != null && sellerProductController.sellerMoreProduct!.products != null &&
                      sellerProductController.sellerMoreProduct!.products!.isNotEmpty)?
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical : Dimensions.paddingSizeDefault),
                    child: TitleRowWidget(title: getTranslated('more_from_the_shop', context),
                      onTap: (){
                        if(productDetailsController.productDetailsModel?.addedBy == 'seller') {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => TopSellerProductScreen(
                            fromMore: true,
                            sellerId: productDetailsController.productDetailsModel?.seller?.id,
                            temporaryClose: productDetailsController.productDetailsModel?.seller?.shop?.temporaryClose,
                            vacationStatus: productDetailsController.productDetailsModel?.seller?.shop?.vacationStatus??false,
                            vacationEndDate: productDetailsController.productDetailsModel?.seller?.shop?.vacationEndDate,
                            vacationStartDate: productDetailsController.productDetailsModel?.seller?.shop?.vacationStartDate,
                            vacationDurationType: productDetailsController.productDetailsModel?.seller?.shop?.vacationDurationType,
                            name: productDetailsController.productDetailsModel?.seller?.shop?.name,
                            banner: productDetailsController.productDetailsModel?.seller?.shop?.bannerFullUrl?.path,
                            image: productDetailsController.productDetailsModel?.seller?.shop?.imageFullUrl?.path,
                          )));
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => TopSellerProductScreen(
                            sellerId: 0,
                            fromMore: true,
                            temporaryClose: Provider.of<SplashController>(context, listen: false).configModel?.inhouseTemporaryClose?.status ?? false,
                            vacationStatus: Provider.of<SplashController>(context, listen: false).configModel?.inhouseVacationAdd?.status,
                            vacationEndDate: Provider.of<SplashController>(context, listen: false).configModel?.inhouseVacationAdd?.vacationEndDate,
                            vacationStartDate: Provider.of<SplashController>(context, listen: false).configModel?.inhouseVacationAdd?.vacationStartDate,
                            vacationDurationType: Provider.of<SplashController>(context, listen: false).configModel?.inhouseVacationAdd?.vacationDurationType,
                            name: Provider.of<SplashController>(context, listen: false).configModel?.inHouseShop?.name,
                            banner: Provider.of<SplashController>(context, listen: false).configModel?.inHouseShop?.bannerFullUrl?.path,
                            image: Provider.of<SplashController>(context, listen: false).configModel?.inHouseShop?.imageFullUrl?.path))
                          );
                        }
                      },
                    ),
                  ) : const SizedBox();
                }
            ),

            Padding(padding: const EdgeInsets.symmetric(horizontal : Dimensions.paddingSizeSmall),
              child: ShopMoreProductViewList(
                  scrollController: scrollController, sellerId: productDetailsController.productDetailsModel!.userId!)),

            Consumer<ProductController>(
              builder: (context, productController,_) {
                return (productController.relatedProductList != null && productController.relatedProductList!.isNotEmpty)?Padding(padding: const EdgeInsets.symmetric(
                    vertical: Dimensions.paddingSizeExtraSmall),
                    child: TitleRowWidget(title: getTranslated('related_products', context), isDetailsPage: true)): const SizedBox();
              }
            ),
            const SizedBox(height: 5),
            const Padding(padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
              child: RelatedProductWidget(),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
          ]);
        }
    );
  }
}
