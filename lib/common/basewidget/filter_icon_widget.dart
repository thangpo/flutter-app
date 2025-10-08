import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_asset_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';

class FilterIconWidget extends StatelessWidget {
  final int filterCount;
  final double? height;
  final double? width;
  final GestureTapCallback? onTap;

  const FilterIconWidget({super.key, this.filterCount = 3, required this.onTap, this.height = 30, this.width = 30});

  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, child: Stack(children: [
      CustomAssetImageWidget(Images.productFilterIcon, width: width, height: height),

      if(filterCount > 0) Positioned(right: 0, top: 0, child: Container(
        width: 17, height: 17,
        transform: Matrix4.translationValues(6, -6, 0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          border: Border.all(color: Theme.of(context).highlightColor, width: 2,),
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeOverLarge),
        ),
        child: Center(child: Text('$filterCount', style: textRegular.copyWith(
          fontSize: Dimensions.paddingSizeSmall,
          color: Theme.of(context).highlightColor,
        ))),
      )),
    ]));
  }
}
