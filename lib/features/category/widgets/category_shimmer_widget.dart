import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';


class CategoryShimmerWidget extends StatelessWidget {
  const CategoryShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 100,
      child: ListView.builder(
        itemCount: 4,
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemBuilder: (BuildContext context, int index) {

          return Padding(padding: const EdgeInsets.only(left: Dimensions.homePagePadding),
            child: SizedBox(height: 50,
              child: Container(width: 100,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                    color: Provider.of<ThemeController>(context).darkTheme ?
                    Theme.of(context).primaryColor.withValues(alpha:.05) :
                    Theme.of(context).cardColor,
                    boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.2), spreadRadius: 1, blurRadius: 5)]),
                child: Shimmer.fromColors(
                  baseColor: Theme.of(context).cardColor,
                  highlightColor: Colors.grey[300]!,
                  enabled: true,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

                    Container(height: 70, padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Provider.of<ThemeController>(context).darkTheme ?
                        Theme.of(context).primaryColor.withValues(alpha:.05) :
                        Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(10))),

                    Padding(padding: const EdgeInsets.all(10),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start, children: [

                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                            Container(height: 5, color: Theme.of(context).cardColor)]),
                    ),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
