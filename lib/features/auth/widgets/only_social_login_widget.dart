import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_asset_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/google_login_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/otp_registration_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/widgets/existing_account_bottom_sheet.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/widgets/social_login_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/domain/models/profile_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/responsive_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';


class OnlySocialLoginWidget extends StatefulWidget {
  final bool fromLogout;
  const OnlySocialLoginWidget({super.key, this.fromLogout = false});

  @override
  State<OnlySocialLoginWidget> createState() => _OnlySocialLoginWidgetState();
}

class _OnlySocialLoginWidgetState extends State<OnlySocialLoginWidget> {

  Future<void> route(bool isRoute, String? token, String? temporaryToken, ProfileModel? profileModel, String? errorMessage, String? loginMedium) async {
    if (isRoute) {
      if(token != null){
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashBoardScreen()), (route) => false);
      } else if(temporaryToken != null && temporaryToken.isNotEmpty) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => OtpRegistrationScreen(
          tempToken: temporaryToken,
          userInput: Provider.of<GoogleSignInController>(Get.context!,listen: false).googleAccount?.email ?? '',
          userName: Provider.of<GoogleSignInController>(Get.context!,listen: false).googleAccount?.displayName ?? '')), (route) => false);
      } else if (profileModel != null) {
        showModalBottomSheet(context: context, isScrollControlled: true,
            backgroundColor: Theme.of(context).primaryColor.withValues(alpha:0),
            builder: (con) => ExistingAccountBottomSheet(profileModel: profileModel, socialLoginMedium: loginMedium!, con: con,)
        );
      }else {
        showCustomSnackBar(errorMessage, context);
      }
    } else {
      showCustomSnackBar(errorMessage, context);
    }
  }


  @override
  Widget build(BuildContext context) {

    final double width = MediaQuery.of(context).size.width;
    final Size size = MediaQuery.of(context).size;

    final socialLogin = SocialMediaLoginOptions(
      facebook: 1,
      google: 1,
      apple: 1
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {

        if(didPop) return;

        Navigator.pop(context);
      },
      child: Scaffold(
        body: Column(children: [
          SizedBox(
            height: size.height * 0.08,
          ),

          Center(
            child: Container(width: width > 700 ? 450 : width,
              margin: const EdgeInsets.only(top: Dimensions.paddingSizeLarge),
              padding: width > 700 ? const EdgeInsets.all(Dimensions.paddingSizeDefault) : null,
              decoration: width > 700 ? BoxDecoration(
                color: Theme.of(context).canvasColor, borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(
                    color: Theme.of(context).textTheme.bodyMedium!.color!.withValues(alpha:0.07),
                    blurRadius: 30,
                    spreadRadius: 0,
                    offset: const Offset(0,10)
                ),],
              ) : null,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [


                SizedBox(height: size.height * 0.05),

                const Directionality(
                  textDirection: TextDirection.ltr,
                  child: CustomAssetImageWidget(
                    Images.logoWithNameImage,
                    height: 100,
                    width: 150,
                    // fit: BoxFit.scaleDown,
                  ),
                ),

                SizedBox(
                  height: size.height * 0.07,
                ),


                Text(
                  "${getTranslated('on_boarding_title_one', context)!} ${AppConstants.appName}",
                  style: titilliumRegular.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                if(socialLogin.google == 1)...[
                  Row(children: [

                    Expanded(child: Container()),

                    Expanded(flex: 4,
                      child: Consumer<AuthController>(
                          builder: (context, authProvider, child) {
                            return InkWell(
                              onTap: () => googleLogin(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).hintColor.withValues(alpha:0.08),
                                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                  border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha:0.1)),
                                ),
                                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [

                                  Image.asset(Images.google,
                                    height: ResponsiveHelper.isTab(context) ? 20 : 15,
                                    width: ResponsiveHelper.isTab(context) ? 20 : 15,
                                  ),
                                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                  Text(getTranslated("continue_with_google", context)!, style: robotoBold.copyWith(
                                    fontSize: Dimensions.fontSizeDefault,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),),

                                ],),
                              ),
                            );
                          }
                      ),
                    ),

                    Expanded(child: Container()),

                  ]),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                ],

                if(socialLogin.facebook == 1)...[
                  Row(children: [

                    Expanded(child: Container()),

                    Expanded(flex: 4,
                      child: Consumer<AuthController>(
                          builder: (context, authProvider, child) {
                            return InkWell(
                              onTap: () => facebookLogin(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).hintColor.withValues(alpha:0.08),
                                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                  border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha:0.1)),
                                ),
                                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [

                                  Image.asset(Images.facebook,
                                    height: ResponsiveHelper.isTab(context) ? 20 : 15,
                                    width: ResponsiveHelper.isTab(context) ? 20 : 15,
                                  ),
                                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                  Text(getTranslated("continue_with_facebook", context)!, style: robotoBold.copyWith(
                                    fontSize: Dimensions.fontSizeDefault,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  )),
                                ],),
                              ),
                            );
                          }
                      ),
                    ),

                    Expanded(child: Container()),

                  ]),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                ],

                if(socialLogin.apple == 1 && defaultTargetPlatform == TargetPlatform.iOS)...[
                  Row(children: [

                    Expanded(child: Container()),

                    Expanded(flex: 4,
                      child: Consumer<AuthController>(
                          builder: (context, authProvider, child) {
                            return InkWell(
                              onTap: () => appleLogin(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).hintColor.withValues(alpha:0.08),
                                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                  border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha:0.1)),
                                ),
                                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [

                                  Image.asset(
                                    Images.appleLogo, color: Theme.of(context).textTheme.bodyMedium?.color,
                                    height: ResponsiveHelper.isTab(context) ? 20 : 15,
                                    width: ResponsiveHelper.isTab(context) ? 20 : 15,
                                  ),
                                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),


                                  Text(getTranslated("continue_with_apple", context)!, style: robotoBold.copyWith(
                                    fontSize: Dimensions.fontSizeDefault,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  )),

                                ],),
                              ),
                            );
                          }
                      ),
                    ),

                    Expanded(child: Container()),

                  ]),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                ],


                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: Theme.of(context).hintColor)),
                      const SizedBox(width: Dimensions.paddingSizeSmall),

                      Text(getTranslated('OR', context)!,
                        style: Theme.of(context).textTheme.displayMedium!.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            color: Theme.of(context).hintColor,
                            fontWeight: FontWeight.w400
                        ),
                      ),

                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Expanded(child: Divider(color: Theme.of(context).hintColor)),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Center(
                  child: InkWell(
                    onTap: ()=> {
                      if (!Provider.of<AuthController>(context, listen: false).isLoading) {
                        Provider.of<AuthController>(context, listen: false).getGuestIdUrl(),
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashBoardScreen()), (route) => false),
                      }
                    },
                    child: RichText(text: TextSpan(children: [

                      TextSpan(text: '${getTranslated('continue_as', context)} ',
                        style: titilliumRegular.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).hintColor,
                        ),
                      ),

                      TextSpan(text: getTranslated('guest', context),
                        style: titilliumRegular.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    ],),),
                  ),
                ),

                SizedBox(height: size.height * 0.03),



              ]),
            ),
          ),

          if(ResponsiveHelper.isDesktop(context)) const SizedBox(height: 50),

        ]),
      ),
    );
  }
}