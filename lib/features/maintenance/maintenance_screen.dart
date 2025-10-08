import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> with WidgetsBindingObserver {

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final SplashController splashController = Provider.of<SplashController>(context, listen: false);
      splashController.initConfig(context, null, null).then((bool isSuccess) {
        if(isSuccess){
          final config = splashController.configModel!;
          if(config.maintenanceModeData?.maintenanceStatus == 0) {
            Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => const DashBoardScreen()));
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final ConfigModel? configModel = Provider.of<SplashController>(context).configModel;
    Provider.of<SplashController>(context, listen: false).setMaintenanceContext(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        Provider.of<SplashController>(context,listen: false).removeMaintenanceContext();
        return;
      },
      child: Scaffold(
        body: Padding(padding: EdgeInsets.all(MediaQuery.of(context).size.height*0.025),
          child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset(Images.maintenance, width: 200, height: 200),

              if(configModel?.maintenanceModeData?.maintenanceMessages?.maintenanceMessage != null && configModel!.maintenanceModeData!.maintenanceMessages!.maintenanceMessage!.isNotEmpty)...[
                Text(configModel.maintenanceModeData?.maintenanceMessages?.maintenanceMessage ?? '', style: titilliumBold.copyWith(
                  fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge!.color),
                  textAlign: TextAlign.center,
                ),
              ],


            if(configModel?.maintenanceModeData?.maintenanceMessages?.maintenanceMessage == null || (configModel?.maintenanceModeData?.maintenanceMessages?.maintenanceMessage == null && configModel!.maintenanceModeData!.maintenanceMessages!.maintenanceMessage!.isEmpty))...[
              Text(getTranslated('maintenance_title', context)!, style: titilliumBold.copyWith(
                  fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge!.color),
                textAlign: TextAlign.center,
              ),
            ],
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              if(configModel?.maintenanceModeData?.maintenanceMessages?.messageBody != null && configModel!.maintenanceModeData!.maintenanceMessages!.messageBody!.isNotEmpty)...[
                Text(configModel.maintenanceModeData?.maintenanceMessages?.messageBody ?? '' ,
                  textAlign: TextAlign.justify, style: titilliumRegular),
                SizedBox(height: size.height * 0.07),
              ],



            if(configModel?.maintenanceModeData?.maintenanceMessages?.messageBody == null || (configModel?.maintenanceModeData?.maintenanceMessages?.messageBody == null && configModel!.maintenanceModeData!.maintenanceMessages!.messageBody!.isEmpty) )...[
              Text(getTranslated('maintenance_body', context)!, textAlign: TextAlign.justify, style: titilliumRegular),
              SizedBox(height: size.height * 0.07),
            ],



              if(configModel?.maintenanceModeData?.maintenanceMessages?.businessEmail == 1 ||
              configModel?.maintenanceModeData?.maintenanceMessages?.businessNumber == 1) ...[
              if( (configModel?.maintenanceModeData?.maintenanceMessages?.maintenanceMessage != null && configModel!.maintenanceModeData!.maintenanceMessages!.maintenanceMessage!.isNotEmpty) ||
              (configModel?.maintenanceModeData?.maintenanceMessages?.messageBody != null && configModel!.maintenanceModeData!.maintenanceMessages!.messageBody!.isNotEmpty)) ...[

                Row(
                  children: List.generate(size.width ~/10, (index) => Expanded(
                  child: Container(
                  color: index%2==0?Colors.transparent :Theme.of(context).hintColor.withValues(alpha:0.2), height: 2),
                  )),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                ],


                Text(getTranslated('any_query_feel_free_to_call', context)!,
                  style: titleRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),
              ],


              if (configModel?.maintenanceModeData?.maintenanceMessages?.businessNumber == 1 )...[
                InkWell(
                  onTap: (){
                    launchUrl(Uri.parse(
                      'tel:${Provider.of<SplashController>(context, listen: false).configModel!.companyPhone}',
                    ), mode: LaunchMode.externalApplication);
                  },
                  child: Text(configModel?.companyPhone ?? "",
                    style: titleRegular.copyWith(
                      color: Theme.of(context).indicatorColor,
                      fontSize: Dimensions.fontSizeDefault,
                      decoration: TextDecoration.underline,
                      decorationColor:  Theme.of(context).indicatorColor,
                    ),
                  ),
                ),
              ],

              if(configModel!.maintenanceModeData?.maintenanceMessages?.businessEmail == 1)...[
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  InkWell(
                    onTap: (){
                      launchUrl(Uri.parse(
                        'mailto:${Provider.of<SplashController>(context, listen: false).configModel!.companyEmail}',
                      ), mode: LaunchMode.externalApplication);
                    },

                    child: Text(configModel.companyEmail ?? "",
                      style: titleRegular.copyWith(
                        color: Theme.of(context).indicatorColor,
                        fontSize: Dimensions.fontSizeDefault,
                        decoration: TextDecoration.underline,
                        decorationColor:  Theme.of(context).indicatorColor,
                      ),
                    ),
                  ),
                ],



          ]),
          ),
        ),
      ),
    );
  }
}
