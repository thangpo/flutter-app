import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/compare/controllers/compare_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/controllers/product_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/domain/models/product_details_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/enums/preview_type.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/screens/product_image_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/widgets/audio_preview.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/widgets/download_preview_file.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/widgets/image_preview.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/widgets/pdf_preview_flutter.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/widgets/video_preview.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/controllers/localization_controller.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/not_logged_in_bottom_sheet_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/widgets/favourite_button_widget.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';


class ProductImageWidget extends StatelessWidget {
  final ProductDetailsModel? productModel;
  ProductImageWidget({super.key, required this.productModel});

  final PageController _controller = PageController();
  @override
  Widget build(BuildContext context) {
    final splashController = Provider.of<SplashController>(context,listen: false);
    final bool isDarkTheme = Provider.of<ThemeController>(context).darkTheme;

    return productModel != null?
    Consumer<ProductDetailsController>(
      builder: (context, productController,_) {
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

          InkWell(
            onTap: ()=>  productModel!.productImagesNull! ? null :
            Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) =>
                ProductImageScreen(title: getTranslated('product_image', context),imageList: productModel!.imagesFullUrl))),
            child: (productModel != null && productModel!.imagesFullUrl !=null) ?
            Padding(
              padding: const EdgeInsets.only(
                left: Dimensions.homePagePadding,
                top: Dimensions.homePagePadding,
                right: Dimensions.homePagePadding,
                bottom: Dimensions.paddingSizeEight,
              ),
              child: ClipRRect(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                child: Container(decoration:  BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: Provider.of<ThemeController>(context, listen: false).darkTheme?
                    Theme.of(context).hintColor.withValues(alpha:.25) : Theme.of(context).primaryColor.withValues(alpha:.25)),
                    borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)),
                  child: Stack(children: [
                    SizedBox(
                        height: MediaQuery.of(context).size.width * 0.8,
                        child: productModel!.imagesFullUrl != null?

                        PageView.builder(
                          controller: _controller,
                          itemCount: productModel!.imagesFullUrl!.length,
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius:BorderRadius.circular(Dimensions.paddingSizeSmall),
                              child: CustomImageWidget(
                                  height: 100,
                                  width: MediaQuery.of(context).size.width,
                                  image: '${productModel!.imagesFullUrl![index].path}'),
                            );
                          },
                          onPageChanged: (index) => productController.setImageSliderSelectedIndex(index),
                        ) : const SizedBox()),


                    Positioned(left: 0, right: 0, bottom: 10,
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const SizedBox(),
                          const Spacer(),
                          Row(mainAxisAlignment: MainAxisAlignment.center,
                              children: _indicators(context)),
                          const Spacer(),

                          Provider.of<ProductDetailsController>(context).imageSliderIndex != null?
                          Padding(padding: const EdgeInsets.only(right: Dimensions.paddingSizeDefault,
                              bottom: Dimensions.paddingSizeDefault),
                            child: Text('${productController.imageSliderIndex!+1}/${productModel?.imagesFullUrl?.length}'),
                          ) : const SizedBox()])),

                    Positioned(top: 16, right: 16,
                        child: Column(children: [
                          FavouriteButtonWidget(
                            backgroundColor: isDarkTheme ? Theme.of(context).cardColor : Theme.of(context).primaryColor,
                            productId: productModel?.id,
                          ),

                          if(splashController.configModel!.activeTheme != "default")
                            const SizedBox(height: Dimensions.paddingSizeSmall,),
                          if(splashController.configModel!.activeTheme != "default")
                            InkWell(onTap: () {
                              if(Provider.of<AuthController>(context, listen: false).isLoggedIn()){
                                Provider.of<CompareController>(context, listen: false).addCompareList(productModel!.id!);
                              }else{
                                showModalBottomSheet(backgroundColor: const Color(0x00FFFFFF),
                                    context: context, builder: (_)=> const NotLoggedInBottomSheetWidget());
                              }
                            },
                                child: Consumer<CompareController>(
                                    builder: (context, compare,_) {
                                      return Card(elevation: 2,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                          child: Container(width: 40, height: 40,
                                              decoration: BoxDecoration(color: compare.compIds.contains(productModel!.id) ?
                                              Theme.of(context).primaryColor: Theme.of(context).cardColor ,
                                                  shape: BoxShape.circle),
                                              child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                                child: Image.asset(Images.compare, color: compare.compIds.contains(productModel!.id) ?
                                                Theme.of(context).cardColor : Theme.of(context).primaryColor),)));
                                    })),
                          const SizedBox(height: Dimensions.paddingSizeSmall,),


                          InkWell(onTap: () {
                            if(productController.sharableLink != null) {
                              Share.share(productController.sharableLink!);
                            }
                          },
                              child: Card(elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                  child: Container(width: 40, height: 40,
                                      decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle),
                                      child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                          child: Image.asset(Images.share, color: Theme.of(context).primaryColor)))))
                        ])),

                    (productModel?.productType == 'digital' && productModel?.previewFileFullUrl != null && productModel?.previewFileFullUrl?.path != '') ?
                    Positioned (right: 10, bottom: 10,
                      child: InkWell(
                        onTap: () => _showPreview(productModel?.previewFileFullUrl?.path ?? '', productModel?.name ?? '', productModel?.previewFileFullUrl?.key ?? '', context),
                        child: Container(
                          padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                          height: 35, width: 81,
                          decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0D1B7FED), offset: Offset(0, 6),
                                  blurRadius: 12, spreadRadius: -3,
                                ),
                                BoxShadow(
                                  color: Color(0x0D1B7FED), offset: Offset(0, -6),
                                  blurRadius: 12, spreadRadius: -3,
                                ),
                              ]
                          ),
                          child: Row(
                              children: [
                                Image.asset(Images.previewEyeIcon, width: 15),
                                const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                Text('${getTranslated('preview', context)}',
                                    style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeDefault)
                                ),
                              ]
                          ),
                        ),
                      ),
                    ) : const SizedBox(),




                    ((productModel?.discount ?? 0) > 0 || (productModel?.clearanceSale != null)) ?
                    // DiscountTagWidget(productModel: productModel) : const SizedBox.shrink(),

                    Positioned(top: 10, left: 0, child: Container(
                      transform: Matrix4.translationValues(-1, 0, 0),
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(Dimensions.paddingSizeExtraSmall),
                          bottomRight: Radius.circular(Dimensions.paddingSizeExtraSmall),
                        ),
                      ),
                      child: Center(child: Directionality(textDirection: TextDirection.ltr, child: Text(
                        PriceConverter.percentageCalculation(context, productModel!.unitPrice,
                          (productModel?.clearanceSale?.discountAmount ?? 0)  > 0
                              ?  productModel?.clearanceSale?.discountAmount
                              : productModel?.discount,

                          (productModel?.clearanceSale?.discountAmount ?? 0)  > 0
                              ? productModel?.clearanceSale?.discountType
                              : productModel?.discountType,
                        ),
                        style: textBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall), textAlign: TextAlign.center,
                      ))),
                    )) : const SizedBox.shrink(),



                  ]),
                ),
              ),
            ) :
            const SizedBox(),
          ),

          Padding(
            padding: EdgeInsets.only(
              left: Provider.of<LocalizationController>(context, listen: false).isLtr ?
              Dimensions.homePagePadding : 0,
              right: Provider.of<LocalizationController>(context, listen: false).isLtr ?
              0 : Dimensions.homePagePadding, bottom: Dimensions.paddingSizeLarge,
            ),
            child: SizedBox(height: 60, child: RepaintBoundary(child: ListView.builder(
              scrollDirection: Axis.horizontal,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: false,
              itemCount: productModel!.imagesFullUrl!.length,
              itemBuilder: (context, index) {
                return InkWell(
                    onTap: (){
                      productController.setImageSliderSelectedIndex(index);
                      _controller.animateToPage(index, duration: const Duration(microseconds: 50), curve:Curves.ease);
                    },
                    child: Padding(padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                        child: Center(child: Container(
                            decoration: BoxDecoration(border: Border.all(width: index == productController.imageSliderIndex? 2:0,
                                color: (index == productController.imageSliderIndex &&
                                    Provider.of<ThemeController>(context, listen: false).darkTheme)? Theme.of(context).primaryColor:
                                (index == productController.imageSliderIndex &&
                                    !Provider.of<ThemeController>(context, listen: false).darkTheme)?
                                Theme.of(context).primaryColor: const Color(0x00FFFFFF)),
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)),
                            child: ClipRRect(borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                              child: CustomImageWidget(height: 50, width: 50,
                                  image: '${productModel!.imagesFullUrl![index].path}'),
                            )))),
                );
              },
            ))),
          ),

        ]);
      }
    ) : const SizedBox();
  }

  List<Widget> _indicators(BuildContext context) {
    List<Widget> indicators = [];
    for (int index = 0; index < productModel!.imagesFullUrl!.length; index++) {
      indicators.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraExtraSmall),
        child: Container(width: index == Provider.of<ProductDetailsController>(context).imageSliderIndex? 20 : 6, height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: index == Provider.of<ProductDetailsController>(context).imageSliderIndex ?
            Theme.of(context).primaryColor : Theme.of(context).hintColor,
          ),

        ),
      ));
    }
    return indicators;
  }

  void _showPreview(String url, String productName, String fileName, BuildContext context) {
    PreviewType type = Provider.of<ProductDetailsController>(context, listen: false).getFileType(url);

    showDialog(context: context, builder: (BuildContext context){
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
        insetPadding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        child: (type == PreviewType.pdf) ?
        PdfPreview(url: url, fileName: productName) : (type == PreviewType.image) ?
        ImagePreview(url: url, fileName: productName) : (type == PreviewType.video) ?
        VideoPreview(url: url, fileName: productName) : (type == PreviewType.audio)  ?
        AudioPreview(url: url, fileName: productName) : (type == PreviewType.others) ?
        DownloadPreview(url: url, fileName: fileName) :
        const SizedBox(),
      );
    });

  }

}
