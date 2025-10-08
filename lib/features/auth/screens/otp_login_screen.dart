import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_asset_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_textfield_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/enums/from_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/widgets/social_login_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/localization/controllers/localization_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';

class OtpLoginScreen extends StatefulWidget {
  final bool fromLogout;
  const OtpLoginScreen({super.key, this.fromLogout = false});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {

  String? countryCode;
  TextEditingController? _phoneNumberController;

  @override
  void initState() {
    super.initState();
    _phoneNumberController = TextEditingController();

    final ConfigModel configModel = Provider.of<SplashController>(context, listen: false).configModel!;
    countryCode ??= CountryCode.fromCountryCode(configModel.countryCode!).dialCode;
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authProvider = Provider.of<AuthController>(context, listen: false);
    final double width = MediaQuery.of(context).size.width;
    final Size size = MediaQuery.of(context).size;
    final ConfigModel configModel = Provider.of<SplashController>(context, listen: false).configModel!;
    final SocialMediaLoginOptions? socialStatus = configModel.customerLogin?.socialMediaLoginOptions;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {

        if(didPop) return;

        Navigator.pop(context);
      },

      child: Scaffold(
        body: SafeArea(
          child: Stack(children: [

            Positioned(
                top: Dimensions.paddingSizeThirtyFive,
                left:  Provider.of<LocalizationController>(context, listen: false).isLtr ? Dimensions.paddingSizeLarge : null,
                right: Provider.of<LocalizationController>(context, listen: false).isLtr ? null : Dimensions.paddingSizeLarge,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios, size: 20, color: Theme.of(context).primaryColor),
                  onPressed: () {
                    if(widget.fromLogout) {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashBoardScreen()), (route) => false);
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                )
            ),

            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Container(
                        width: width > 700 ? 450 : width,
                        margin: const EdgeInsets.only(top: Dimensions.paddingSizeLarge),
                        // padding: width > 700 ? const EdgeInsets.all(Dimensions.paddingSizeDefault) : null,
                        decoration: width > 700 ? BoxDecoration(
                          color: Theme.of(context).canvasColor, borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).textTheme.bodyMedium!.color!.withValues(alpha:0.07),
                              blurRadius: 30,
                              offset: const Offset(0,10),
                              spreadRadius: 0,
                            ),
                          ],
                        ) : null,

                        child: Center(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Directionality(
                              textDirection: TextDirection.ltr,
                              child: CustomAssetImageWidget(
                                Images.logoWithNameImage, width: 150, height: 140, fit: BoxFit.scaleDown,
                              ),
                            ),

                            SizedBox(height: size.height * 0.1),

                            Row(children: [

                              Expanded(child: Container()),

                              Expanded(flex: 10, child: Column(children: [

                                CustomTextFieldWidget(
                                  showCodePicker: true,
                                  countryDialCode: countryCode,
                                  onCountryChanged: (CountryCode value) {
                                    countryCode = value.dialCode;
                                  },
                                  // hintText: getTranslated('number_hint', context),
                                  isShowBorder: true,
                                  controller: _phoneNumberController,
                                  inputType: TextInputType.phone,
                                  labelText: getTranslated('mobile_number', context),
                                ),
                                SizedBox(height: size.height * 0.03),

                                Consumer<AuthController>(
                                    builder: (context, authProvider, child) {
                                      return InkWell(
                                        onTap: ()=> authProvider.toggleRememberMe(),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 18,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  border: Border.all(color: Theme.of(context).primaryColor),
                                                  borderRadius: BorderRadius.circular(3)
                                              ),
                                              child: authProvider.isActiveRememberMe
                                                  ? Icon(Icons.done, color: Theme.of(context).primaryColor, size: 14)
                                                  : const SizedBox.shrink(),
                                            ),
                                            const SizedBox(width: Dimensions.paddingSizeSmall),

                                            Text(
                                              getTranslated('remember', context)!,
                                              style: titilliumRegular.copyWith(
                                                  fontSize: Dimensions.fontSizeSmall,
                                                  color: Theme.of(context).hintColor,
                                                  fontWeight: FontWeight.w600
                                              ),
                                            ),
                                            const SizedBox(height: Dimensions.paddingSizeSmall),




                                          ],
                                        ),
                                      );
                                    }
                                ),
                                SizedBox(height: size.height * 0.03),

                                Consumer<AuthController>(builder: (context, authProvider, child) {
                                  return !authProvider.isPhoneNumberVerificationButtonLoading ? CustomButton(
                                      buttonText : getTranslated('get_otp', context),
                                      onTap: () async {

                                        if (_phoneNumberController!.text.isEmpty) {
                                          showCustomSnackBar(getTranslated('enter_phone_number', context), context);
                                        }else {

                                          String phoneWithCountryCode = countryCode! + _phoneNumberController!.text.trim();


                                          if(configModel.customerVerification?.firebase == 1) {
                                            await authProvider.firebaseVerifyPhoneNumber(phoneWithCountryCode, FromPage.otpLogin );
                                          } else {
                                            await authProvider.checkPhoneForOtp(phoneWithCountryCode, FromPage.otpLogin);
                                          }

                                        }
                                      }) : Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                                      ));
                                }
                                ),
                                const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                              ]),
                              ),

                              Expanded(child: Container()),
                            ]),


                            if(_isShowSocialLoginButton(configModel, socialStatus))...[
                              Center(child: Text(
                                getTranslated('or', context)!,
                                style: titilliumRegular.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                              ),
                              const SizedBox(height: Dimensions.paddingSizeDefault),

                              const Padding(padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge) ,child: SocialLoginWidget()),
                              const SizedBox(height: Dimensions.paddingSizeLarge),
                            ],


                            Center(
                              child: InkWell(
                                onTap: () {
                                  if (!authProvider.isLoading) {
                                    authProvider.removeGoogleLogIn();
                                    authProvider.getGuestIdUrl();
                                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashBoardScreen()), (route) => false);
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
                                      fontWeight: FontWeight.w600,
                                      fontSize: Dimensions.fontSizeDefault,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ])),
                              ),
                            ),

                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}


bool _isShowSocialLoginButton (ConfigModel configModel, SocialMediaLoginOptions? socialStatus){
  return (configModel.customerLogin?.loginOption?.socialMediaLogin == 1)
      && (configModel.customerLogin?.loginOption?.manualLogin != 1)
      && ( (socialStatus?.apple == 1 && defaultTargetPlatform == TargetPlatform.iOS)
          || socialStatus?.google == 1
          || socialStatus?.facebook == 1
      );
}