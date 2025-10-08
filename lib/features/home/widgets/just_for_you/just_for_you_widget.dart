
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/product_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/responsive_helper.dart';
import 'package:provider/provider.dart';

class JustForYouView extends StatefulWidget {
  final List<Product>? productList;
   const JustForYouView({super.key, required this.productList});

  @override
  State<JustForYouView> createState() => _JustForYouViewState();
}

class _JustForYouViewState extends State<JustForYouView> {

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductController>(
      builder: (context, productController,_) {
        return SizedBox(
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
            itemCount: widget.productList?.length,
            itemBuilder: (context, index, next) {
              return ProductWidget(productModel: widget.productList![index], productNameLine: 1);
            },
          ),
        );
      }
    );
  }
}
