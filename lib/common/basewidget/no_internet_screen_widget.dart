import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_asset_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/helper/color_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:provider/provider.dart';

class NoInternetOrDataScreenWidget extends StatelessWidget {
  final bool isNoInternet;
  final Widget? child;
  final String? message;
  final String? icon;
  final bool icCart;
  final EdgeInsets? padding;
  final double? iconSize;
  const NoInternetOrDataScreenWidget({super.key, required this.isNoInternet, this.child, this.message, this.icon,  this.icCart = false, this.padding, this.iconSize = 75});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.all(MediaQuery.of(context).size.height * 0.025),
      child: Center(
        child: Column(mainAxisAlignment: padding == null ? MainAxisAlignment.center  : MainAxisAlignment.start, children: [
          CustomAssetImageWidget(isNoInternet ? Images.noInternet :icon != null? icon! : Images.noData, height: iconSize, width: iconSize, fit: BoxFit.cover),

          if(isNoInternet)
            Text(getTranslated('OPPS', context)!, style: titilliumBold.copyWith(fontSize: 30, color: Colors.white)),

          const SizedBox(height: Dimensions.paddingSizeDefault),

          Text(isNoInternet ?
          getTranslated('no_internet_connection', context)!
              : message != null? getTranslated(message, context)??''
              : getTranslated('no_data_found', context)??'', textAlign: TextAlign.center, style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 20),

          isNoInternet ? Container(
            height: 45,
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(5),
              color: Provider.of<ThemeController>(context).darkTheme ?
              ColorHelper.darken(Theme.of(context).colorScheme.secondary, 0.2) :
              Theme.of(context).colorScheme.secondary
            ),
            child: TextButton(
              onPressed: () async {
                List<ConnectivityResult> results = await Connectivity().checkConnectivity();
                bool isConnected = results.any((result) => result != ConnectivityResult.none);

                if (isConnected) {
                  Navigator.pushReplacement(Get.context!, MaterialPageRoute(builder: (_) => child!));
                }
              },

              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: Text(getTranslated('RETRY', context)!, style: titilliumSemiBold.copyWith(color: Theme.of(context).highlightColor, fontSize: Dimensions.fontSizeLarge)),
              ),
            ),
          ) : const SizedBox.shrink(),

          if(icCart)
            SizedBox(width: 160,
              child: CustomButton(backgroundColor: Colors.transparent,
                  onTap: ()=> Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_)=> const DashBoardScreen()), (route) => false),
                  isBorder: true, textColor: Theme.of(context).primaryColor,
                  buttonText: '${getTranslated('continue_shopping', context)}'),
            )

        ]),
      ),
    );
  }
}

