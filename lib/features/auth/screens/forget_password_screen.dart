import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/response_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/number_checker_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_textfield_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/otp_verification_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/enums/from_page.dart';


class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});
  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  TextEditingController? _userInputController;
  String? _countryCode;

  final GlobalKey<ScaffoldMessengerState> _key = GlobalKey();

  final GlobalKey<FormState> forgetFormKey = GlobalKey<FormState>();

  final ConfigModel config = Provider.of<SplashController>(Get.context!, listen: false).configModel!;

  @override
  void initState() {
    _userInputController = TextEditingController();
    final AuthController authProvider = Provider.of<AuthController>(context, listen: false);

    authProvider.clearVerificationMessage();
    authProvider.setIsLoading = false;
    authProvider.setIsPhoneVerificationButttonLoading = false;
    authProvider.toggleIsNumberLogin(value: false, isUpdate: false);
    _countryCode = CountryCode.fromCountryCode(Provider.of<SplashController>(context, listen: false).configModel!.countryCode!).dialCode;
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    final ConfigModel configModel =  Provider.of<SplashController>(context, listen: false).configModel!;
    return Scaffold(
      key: _key,

      appBar: CustomAppBar(title: getTranslated('forget_password', context)),
      body: Consumer<AuthController>(
        builder: (context, authProvider,_) {
          return Consumer<SplashController>(
            builder: (context, splashProvider, _) {
              return Form(
                key: forgetFormKey,
                child: ListView(padding: const EdgeInsets.all(Dimensions.paddingSizeDefault), children: [

                  Center(child: Padding(padding: const EdgeInsets.all(50), child: Image.asset(Images.logoWithNameImage, height: 150, width: 150))),

                  Text(getTranslated('forget_password', context)!, textAlign: TextAlign.center, style: textBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: Theme.of(context).textTheme.bodyLarge?.color
                  )),

                  Text(getTranslated('enter_phone_number_for_password_reset', context)!, textAlign: TextAlign.center, style: textRegular.copyWith(
                    color: Theme.of(context).hintColor,
                    fontSize: Dimensions.fontSizeDefault,
                  )),
                 const SizedBox(height: Dimensions.marginSizeAuthSmall),


                  Selector<AuthController, bool>(
                    selector: (context, authProvider) => authProvider.isNumberLogin,
                    builder: (_, isNumberLogin, ___) {
                      return CustomTextFieldWidget(
                        countryDialCode: isNumberLogin ? _countryCode : null,
                        showCodePicker: isNumberLogin,
                        onCountryChanged: (CountryCode value) {
                          _countryCode = value.dialCode;
                        },

                        onChanged: (String text){

                          final numberRegExp = RegExp(r'^[+-]?[0-9]+$');

                          if(text.isEmpty && authProvider.isNumberLogin){
                            authProvider.toggleIsNumberLogin();
                          }
                          if(text.startsWith(numberRegExp) && !authProvider.isNumberLogin){
                            authProvider.toggleIsNumberLogin();
                          }


                          final emailRegExp = RegExp(r'@');

                          if(text.contains(emailRegExp) && authProvider.isNumberLogin) {
                            authProvider.toggleIsNumberLogin();
                          }
                        },
                        hintText: '',
                        isShowBorder: true,
                        controller: _userInputController,
                        inputType: TextInputType.number,
                        labelText: getTranslated('phone', context),
                      );
                    },
                  ),
                  const SizedBox(height: Dimensions.bannerPadding),

                  CustomButton(
                    isLoading: (authProvider.isLoading || authProvider.isForgotPasswordLoading),
                    buttonText: getTranslated('send', context),
                    onTap: () async {
                      if(forgetFormKey.currentState?.validate() ?? false) {
                        if(!(config.emailVerification ?? false) && !(config.phoneVerification ?? false) && config.customerVerification?.phone == 0 && config.customerVerification?.firebase == 0 && config.customerVerification?.email == 0) {
                          showCustomSnackBar(getTranslated('forgot_password_configuration_is_not', context), context);
                        } else if (_userInputController!.text.isEmpty) {
                          showCustomSnackBar(getTranslated('enter_email_or_phone', context), context);
                        } else if(!NumberCheckerHelper.isNumber(_userInputController!.text.trim())) {
                          showCustomSnackBar(getTranslated('enter_phone_number', context), context);
                        }
                          else{
                          String userInput = _userInputController!.text.trim();
                          bool isNumber = NumberCheckerHelper.isNumber(userInput);

                          if(isNumber) {
                            userInput = _countryCode! + userInput;
                          }

                          ResponseModel? response =  await authProvider.forgetPassword(config: configModel, phoneOrEmail: userInput, type: isNumber ? 'phone' : 'email');
                          if(response != null && response.isSuccess) {
                            if(isNumber && !authProvider.sendToEmail) {
                              if(context.mounted) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => VerificationScreen(userInput, FromPage.forgetPassword)));
                              }
                            } else {
                              if(context.mounted) {
                                showCustomSnackBar(response.message, context, isError: false);
                              }
                            }
                          } else if(response != null && !response.isSuccess) {
                            if(context.mounted){
                              showCustomSnackBar(response.message, context);
                            }
                          }
                        }
                      }
                    },
                  ),
                ]),
              );
            }
          );
        }
      ),
    );
  }
}

