import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';


class DemoResetDialogWidget extends StatefulWidget {
  const DemoResetDialogWidget({super.key});

  @override
  State<DemoResetDialogWidget> createState() => _DemoResetDialogWidgetState();
}

class _DemoResetDialogWidgetState extends State<DemoResetDialogWidget> {

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
      insetPadding: const EdgeInsets.all(30),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          color: Theme.of(context).cardColor,
        ),
        width: 500,
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, color: Theme.of(context).primaryColor, size: 55),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          Text(getTranslated('session_time_out', context)!, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          Text(
            getTranslated('though_it_is_demo_text', context)!,
            textAlign: TextAlign.center,
            style: textMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraOverLarge),

          // CustomButtonWidget(isLoading: _isLoading, buttonText: getTranslated('okay', context)!, onPressed: () {
          //   setState(() {
          //     _isLoading = true;
          //   });
          //   Get.find<SplashController>().getConfigData().then((isSuccess) {
          //     if(isSuccess) {
          //       setState(() {
          //         _isLoading = false;
          //       });
          //       Get.offAllNamed(RouteHelper.getInitialRoute(fromSplash: true));
          //     }
          //   });
          // }),


        ]),
      ),
    );
  }
}
