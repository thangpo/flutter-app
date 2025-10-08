import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/product_shimmer_item_widget.dart';
import 'package:flutter_sixvalley_ecommerce/helper/responsive_helper.dart';

class SliderProductShimmerWidget extends StatelessWidget {
  const SliderProductShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {

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
        itemCount: 3,
        itemBuilder: (context, index, next) {
          return const ProductShimmerItemWidget();
        },
    ));
  }
}
