import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_asset_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/domain/models/signup_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/domain/models/user_log_data.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/enums/from_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/otp_registration_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/reset_password_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/controllers/order_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/screens/profile_screen1.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/color_helper.dart';
import 'package:flutter_sixvalley_ecommerce/helper/email_checker_helper.dart';
import 'package:flutter_sixvalley_ecommerce/helper/number_checker_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';


class VerificationScreen extends StatefulWidget {
  final String? userInput;
  final FromPage fromPage;
  final bool fromDigitalProduct;
  final int? orderId;
  final String? session;

  const VerificationScreen(this.userInput, this.fromPage,
   {super.key, this.session, this.fromDigitalProduct = false, this.orderId});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  Timer? _timer;
  int? _seconds = 0;

  bool? isPhone;

  @override
  void initState() {
    super.initState();
    isPhone = EmailCheckerHelper.isNotValid(widget.userInput.toString());
    _startTimer();
  }

  void _startTimer() {
    _seconds = (isPhone! && Provider.of<SplashController>(context, listen: false).configModel?.customerVerification?.firebase == 1) ? 30 : Provider.of<SplashController>(context, listen: false).configModel?.otpResendTime ?? 1;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds = _seconds! - 1;
      if(_seconds == 0) {
        timer.cancel();
        _timer?.cancel();
      }
      setState(() {});
    });
  }



  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }
  @override
  Widget build(BuildContext context) {
    int minutes = (_seconds! / 60).truncate();
    String minutesStr = (minutes % 60).toString().padLeft(2, '0');

    final isPhone = EmailCheckerHelper.isNotValid(widget.userInput.toString());
    final Size size = MediaQuery.of(context).size;
    final ConfigModel config = Provider.of<SplashController>(context, listen: false).configModel!;
    final bool isFirebaseOTP = config.customerVerification!.status ==1 && config.customerVerification?.firebase == 1;

    return Scaffold(
      appBar: CustomAppBar(title: getTranslated('otp_verification', context), isBackButtonExist: true,),

      body: Consumer<SplashController>(
          builder: (context, splashProvider, _) {
            return Stack(
              children: [

                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Consumer<AuthController>(
                    builder: (context, authProvider, child) => Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      widget.fromDigitalProduct? CustomAppBar(title: '${getTranslated('verify_otp', context)}'): const SizedBox(),

                      SizedBox(height: size.height * 0.14),

                      CustomAssetImageWidget(
                        isPhone ? Images.phoneOtpSvg : Images.mailOtpSvg,
                        height: 100, width: 100,
                      ),

                      const SizedBox(height: Dimensions.paddingSizeExtraOverLarge),


                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(children: [

                            TextSpan(
                              text: getTranslated('we\'ve_sent_verification_code', context),
                              style: titilliumRegular.copyWith(
                                color: Theme.of(context).hintColor,
                                fontSize: Dimensions.fontSizeDefault,
                              ),
                            ),

                            TextSpan(
                              text: " ${widget.userInput} ",
                              style: titilliumRegular.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                fontSize: Dimensions.fontSizeDefault,
                              ),
                            ),

                          ]),
                        ),
                      ),


                      Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: 35),
                        child: PinCodeTextField(
                          length: 6,
                          appContext: context,
                          obscureText: false,
                          showCursor: true,
                          keyboardType: TextInputType.number,
                          animationType: AnimationType.fade,
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            fieldHeight: 45,
                            fieldWidth: 45,
                            borderWidth: 1,
                            borderRadius: BorderRadius.circular(10),
                            selectedColor: ColorHelper.darken(Theme.of(context).colorScheme.secondary, 0.2),
                            selectedFillColor: Colors.white,
                            inactiveFillColor: Theme.of(context).cardColor,
                            inactiveColor: ColorHelper.darken(Theme.of(context).colorScheme.secondary, 0.2),
                            activeColor: ColorHelper.darken(Theme.of(context).colorScheme.secondary, 0.1),
                            activeFillColor: Theme.of(context).cardColor,
                          ),
                          textStyle: titilliumBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).textTheme.bodyLarge?.color),
                          animationDuration: const Duration(milliseconds: 300),
                          backgroundColor: Colors.transparent,
                          enableActiveFill: true,
                          onChanged: authProvider.updateVerificationCode,
                          beforeTextPaste: (text) {
                            return true;
                          },
                        ),
                      ),


                      if(widget.fromDigitalProduct)
                        Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                            child:  CustomButton(buttonText: getTranslated('verify', context),
                                onTap: (){
                                  Provider.of<OrderDetailsController>(context, listen: false).verifyDigitalProductOtp(orderId: widget.orderId!,
                                      otp: authProvider.verificationCode).then((value) {
                                    if(value.response?.statusCode == 200) {
                                      if(context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    }else {
                                      if(context.mounted) {
                                        showCustomSnackBar(getTranslated('input_valid_otp', context), context, isError: true);
                                      }
                                    }});})),

                      if(!widget.fromDigitalProduct)
                        Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                          child: (authProvider.isEnableVerificationCode && !authProvider.resendButtonLoading) ?
                          !authProvider.isPhoneNumberVerificationButtonLoading ?
                          CustomButton(
                            buttonText: getTranslated('verify', context),
                            backgroundColor: !authProvider.isEnableVerificationCode ? Theme.of(context).disabledColor : null,
                            onTap: () {
                              if (widget.fromPage == FromPage.login) {
                                if(config.customerVerification!.status == 1){
                                  if(isPhone && isFirebaseOTP){
                                    authProvider.firebaseOtpLogin(
                                      phoneNumber: widget.userInput ?? '',
                                      session: '${widget.session}',
                                      otp: authProvider.verificationCode,
                                    );
                                  } else if(isPhone && config.customerVerification?.phone == 1) {
                                    authProvider.verifyPhone(widget.userInput ?? '', '').then((value) {
                                      if (value.isSuccess && context.mounted) {
                                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashBoardScreen()), (route) => false);
                                      }
                                    });
                                  } else if(!isPhone && config.customerVerification?.email == 1) {
                                    authProvider.verifyEmail(widget.userInput ?? '').then((value) {
                                      if (value.isSuccess && context.mounted) {
                                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashBoardScreen()), (route) => false);
                                      }
                                    });
                                  }
                                }
                              } else if(widget.fromPage == FromPage.otpLogin) {
                                if (config.customerVerification?.firebase == 1) {
                                  authProvider.firebaseOtpLogin(
                                    phoneNumber: widget.userInput ?? '',
                                    session: authProvider.verificationID ?? '',
                                    // session: '${widget.session}',
                                    otp: authProvider.verificationCode,
                                  );
                                } else {
                                  authProvider.verifyPhoneForOtp(widget.userInput ?? '').then((value){
                                    final (responseModel, tempToken) = value;
                                    if((responseModel != null && responseModel.isSuccess) && tempToken == null) {
                                      if (authProvider.isActiveRememberMe) {
                                        String userCountryCode = NumberCheckerHelper.getCountryCode(widget.userInput)!;

                                        authProvider.saveUserEmailAndPassword(UserLogData(
                                          countryCode:  userCountryCode,
                                          phoneNumber: widget.userInput?.substring(userCountryCode.length),
                                          email: null,
                                          password: null,
                                        ));
                                      } else {
                                        authProvider.clearUserEmailAndPassword();
                                      }
                                      if(context.mounted) {
                                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashBoardScreen()), (route) => false);
                                      }
                                    }else if((responseModel != null && responseModel.isSuccess) && tempToken != null) {
                                      if(context.mounted) {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => OtpRegistrationScreen(tempToken: tempToken, userInput: widget.userInput?? '')));
                                      }
                                    }
                                  });
                                }
                              } else if(widget.fromPage == FromPage.profile) {
                                String type = isPhone ? 'phone': 'email';
                                authProvider.verifyProfileInfo(widget.userInput!,type).then((value){
                                  if(value.isSuccess && context.mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const ProfileScreen1(formVerification: true)), (route) => false);
                                  }
                                });
                              } else {
                                if (isFirebaseOTP && isPhone) {authProvider.firebaseOtpLogin(
                                  phoneNumber: widget.userInput ?? '',
                                  session: '${widget.session}',
                                  otp: authProvider.verificationCode,
                                  isForgetPassword: true,
                                );
                                } else {
                                  authProvider.verifyToken(widget.userInput ?? '').then((value) {
                                    if (value.isSuccess && context.mounted) {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => ResetPasswordScreen(mobileNumber:  widget.userInput ?? '',otp:  authProvider.verificationCode)));
                                    } else {
                                      if(context.mounted) {
                                        showCustomSnackBar(value.message!, context);
                                      }
                                    }
                                  });
                                }
                              }
                            },
                          ):  Center(child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor))) : const  SizedBox.shrink(),
                        ),

                      const SizedBox(height: Dimensions.paddingSizeDefault),


                      if(_seconds! <= 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(getTranslated('i_didnt_receive_the_code', context)!),

                          authProvider.resendButtonLoading ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(strokeWidth: 02,)) : InkWell(
                            onTap: () async {
                              if (widget.fromPage != FromPage.forgetPassword) {
                                await authProvider.sendVerificationCode(
                                  config,
                                  SignUpModel(
                                    phone: widget.userInput,
                                    email: widget.userInput,
                                  ),
                                  type: isPhone ? 'phone' : 'email',
                                  fromPage: FromPage.verification,
                                  isResend: true
                                );
                                _startTimer();
                              } else {
                                _startTimer();
                                await authProvider.forgetPassword(
                                  config: config,
                                  phoneOrEmail: widget.userInput ?? '',
                                  type: isPhone ? 'phone' : 'email',
                                  isResend: true
                                ).then((value) {
                                  if (value!.isSuccess && context.mounted) {
                                    showCustomSnackBar(getTranslated('resend_code_successful', context), context, isError: false);
                                  } else {
                                    if(context.mounted){
                                      showCustomSnackBar(value.message!,  context);
                                    }
                                  }
                                });
                              }
                            },
                            child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                              child: Text(getTranslated('resend_code', context)??"",
                              style: robotoBold.copyWith(color: Theme.of(context).primaryColor))
                            )
                          )
                        ],
                        ),
                      ),

                      if(_seconds! > 0)
                        Text('${getTranslated('resend_code', context)} ${getTranslated('after', context)} ${_seconds! > 0 ? '$minutesStr:${_seconds! % 60}' : ''} ${'Sec'}'),





                    ],
                    ),
                  ),
                )

              ],
            );
          }
      ),
    );
  }
}
