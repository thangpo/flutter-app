import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';



class AddressShimmerWidget extends StatelessWidget {
  const AddressShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 15,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      itemBuilder: (context, index) {
        return Padding(padding: const EdgeInsets.only(bottom: 10.0),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(5),
                color: Provider.of<ThemeController>(context).darkTheme ?
                Theme.of(context).primaryColor.withValues(alpha:.05) :
                Theme.of(context).cardColor,
                boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha:0.3), spreadRadius: 1, blurRadius: 5)]),
            child: Shimmer.fromColors(baseColor: Theme.of(context).cardColor,
              highlightColor: Colors.grey[300]!,
              enabled: true,
              child: Padding(padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                child: Row(children: [
                  const CircleAvatar(radius: 30, child: Icon(Icons.person)),
                  Expanded(child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                      child: Column(children: [
                        Container(height: 15, color: Provider.of<ThemeController>(context).darkTheme ?
                        Theme.of(context).primaryColor.withValues(alpha:.05) :
                        Theme.of(context).cardColor,),
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                        Container(height: 15, color: Provider.of<ThemeController>(context).darkTheme ?
                        Theme.of(context).primaryColor.withValues(alpha:.05) :
                        Theme.of(context).cardColor,)]))),
                  Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(height: 10, width: 30, color: Theme.of(context).colorScheme.secondaryContainer),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Container(height: 15, width: 15,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).primaryColor)),
                  ])
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}