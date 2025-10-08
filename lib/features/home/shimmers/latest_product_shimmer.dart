import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class LatestProductShimmer extends StatelessWidget {
  const LatestProductShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(15),
      child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
          color: Provider.of<ThemeController>(context).darkTheme ?
          Theme.of(context).primaryColor.withValues(alpha:.05) :
          Theme.of(context).cardColor,
          boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.3), spreadRadius: 1, blurRadius: 5)]),
        child: Shimmer.fromColors(baseColor: Theme.of(context).cardColor,
          highlightColor: Colors.grey[300]!,
          enabled: true,
          child: Padding(padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
            child: Column(children: [
               Container(height: 220, width: MediaQuery.of(context).size.width,
                 decoration: BoxDecoration(color: Provider.of<ThemeController>(context).darkTheme ?
                 Theme.of(context).primaryColor.withValues(alpha:.05) :
                 Theme.of(context).cardColor, borderRadius: BorderRadius.circular(10))),


              Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
                child: Column(children: [
                  Container(height: 15, color: Provider.of<ThemeController>(context).darkTheme ?
                  Theme.of(context).primaryColor.withValues(alpha:.05) :
                  Theme.of(context).cardColor,),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Container(height: 15, color: Provider.of<ThemeController>(context).darkTheme ?
                  Theme.of(context).primaryColor.withValues(alpha:.05) :
                  Theme.of(context).cardColor,),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}