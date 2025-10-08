import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/product_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/slider_product_shimmer_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/screens/view_all_product_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/enums/product_type.dart';
import 'package:flutter_sixvalley_ecommerce/helper/responsive_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/title_row_widget.dart';
import 'package:provider/provider.dart';



class LatestProductListWidget extends StatelessWidget {
  const LatestProductListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ProductController, ProductModel?>(
      selector: (ctx, productController)=> productController.latestProductModel,
      builder: (context, latestProductModel, child) {
        return (latestProductModel?.products?.isNotEmpty ?? false)  ? Column( children: [
          TitleRowWidget(
            title: getTranslated('latest_products', context),
            onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewAllProductScreen(productType: ProductType.latestProduct))),
          ),

          const SizedBox(height: Dimensions.paddingSizeSmall),


          SizedBox(
            height: ResponsiveHelper.isTab(context)? MediaQuery.of(context).size.width * .58 : 320,
            child: CarouselSlider.builder(
              options: CarouselOptions(
                viewportFraction: ResponsiveHelper.isTab(context)? .5 :.65,
                autoPlay: false,
                pauseAutoPlayOnTouch: true,
                pauseAutoPlayOnManualNavigate: true,
                enlargeFactor: 0.2,
                enlargeCenterPage: true,
                pauseAutoPlayInFiniteScroll: true,
                disableCenter: true,
              ),
              itemCount: latestProductModel?.products?.length,
              itemBuilder: (context, index, next) {
                return ProductWidget(productModel: latestProductModel!.products![index], productNameLine: 1);
              },
            ),
          ),




        ]) : latestProductModel == null ? const SliderProductShimmerWidget() : const SizedBox();
      },
    );
  }
}

