import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/more/widgets/faq_expansion_tile_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';
class FaqScreen extends StatefulWidget {
  final String? title;
  const FaqScreen({super.key, required this.title});

  @override
  FaqScreenState createState() => FaqScreenState();
}

class FaqScreenState extends State<FaqScreen> {
 
  @override
  Widget build(BuildContext context) {
    var splashController = Provider.of<SplashController>(context, listen: false);
    return Scaffold(
      body: Column(children: [

        CustomAppBar(title: widget.title),
        const SizedBox(height: Dimensions.paddingSizeDefault,),

        splashController.configModel!.faq != null && splashController.configModel!.faq!.isNotEmpty? Expanded(
          child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: Provider.of<SplashController>(context, listen: false).configModel!.faq!.length,
              itemBuilder: (ctx, index){
                return  Consumer<SplashController>(
                  builder: (ctx, faq, child){
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.homePagePadding),
                      child: Card(
                        elevation: Dimensions.paddingSizeExtraSmall,
                        shadowColor: Theme.of(context).highlightColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                        color: Theme.of(context).cardColor,
                        child: FaqExpansionTileWidget(index: index, faq: faq),

                      )
                    );
                  },
                );
              }),
        ): const NoInternetOrDataScreenWidget(isNoInternet: false)

      ],),
    );
  }
}
