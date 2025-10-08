import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/product_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/deal/controllers/flash_deal_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/responsive_helper.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/slider_product_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/shimmers/flash_deal_shimmer.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';


class FlashDealsListWidget extends StatelessWidget {
  final bool isHomeScreen;
  const FlashDealsListWidget({super.key, this.isHomeScreen = true});

  @override
  Widget build(BuildContext context) {

    return isHomeScreen ? Consumer<FlashDealController>(
        builder: (context, flashDealController, child) {
          return flashDealController.flashDeal != null ? flashDealController.flashDealList.isNotEmpty ?
          SizedBox(
            height: ResponsiveHelper.isTab(context)? MediaQuery.of(context).size.width * .58 : 330,
            child: CarouselSlider.builder(
              options: CarouselOptions(
                viewportFraction: ResponsiveHelper.isTab(context)? .5 :.65,
                autoPlay: true,
                pauseAutoPlayOnTouch: true,
                pauseAutoPlayOnManualNavigate: true,
                enlargeFactor: 0.2,
                enlargeCenterPage: true,
                pauseAutoPlayInFiniteScroll: true,
                disableCenter: true,
                onPageChanged: (index, reason) => flashDealController.setCurrentIndex(index),
              ),
              itemCount: flashDealController.flashDealList.isEmpty ? 1 : flashDealController.flashDealList.length,
              itemBuilder: (context, index, next) {
                return SliderProductWidget(product: flashDealController.flashDealList[index], isCurrentIndex: index == flashDealController.currentIndex);
              },
            ),
          ) : const SizedBox() : const FlashDealShimmer();
        }) : Consumer<FlashDealController>(
      builder: (context, flashDealController, child) {
        return flashDealController.flashDealList.isNotEmpty ?
        RepaintBoundary(
          child: MasonryGridView.count(
            itemCount: flashDealController.flashDealList.length,
            padding: const EdgeInsets.all(0),
            itemBuilder: (BuildContext context, int index) {
              return ProductWidget(productModel: flashDealController.flashDealList[index]);
            }, crossAxisCount: 2,
          ),
        ) : const Center(child: CircularProgressIndicator());
      },
    );
  }
}



