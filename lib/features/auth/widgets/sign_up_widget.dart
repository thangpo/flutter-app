import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/domain/models/register_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/widgets/condition_check_box_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/velidate_check.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_textfield_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:provider/provider.dart';

class SignUpWidget extends StatefulWidget {
  const SignUpWidget({super.key});

  @override
  SignUpWidgetState createState() => SignUpWidgetState();
}

class SignUpWidgetState extends State<SignUpWidget> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _referController = TextEditingController();

  final FocusNode _fNameFocus = FocusNode();
  final FocusNode _lNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  final FocusNode _referFocus = FocusNode();

  RegisterModel register = RegisterModel();
  final GlobalKey<FormState> signUpFormKey = GlobalKey<FormState>();



  Future<void> route(bool isRoute, String? token, String? tempToken, String? errorMessage) async {
    var splashController = Provider.of<SplashController>(context,listen: false);
    var authController = Provider.of<AuthController>(context, listen: false);
    var profileController = Provider.of<ProfileController>(context, listen: false);
    String phone = authController.countryDialCode +_phoneController.text.trim();
    if (isRoute) {
      if(splashController.configModel!.emailVerification!){
        authController.sendOtpToEmail(_emailController.text.toString(), tempToken!).then((value) async {
          if (value.response?.statusCode == 200) {
            authController.updateEmail(_emailController.text.toString());
            // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) =>
            //     VerificationScreen(tempToken,'',_emailController.text.toString())), (route) => false);

          }
        });
      }else if(splashController.configModel!.phoneVerification!){
        authController.sendOtpToPhone(phone,tempToken!).then((value) async {
          if (value.isSuccess) {
            authController.updatePhone(phone);
            // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) =>
            //     VerificationScreen(tempToken,phone,'')), (route) => false);

          }
        });
      }else{
        await profileController.getUserInfo(context);
        Navigator.pushAndRemoveUntil(Get.context!, MaterialPageRoute(builder: (_) =>
        const DashBoardScreen()), (route) => false);
        _emailController.clear();
        _passwordController.clear();
        _firstNameController.clear();
        _lastNameController.clear();
        _phoneController.clear();
        _confirmPasswordController.clear();
        _referController.clear();
      }


    }
    else {
      showCustomSnackBar(errorMessage, context);
    }
  }


  @override
  void initState() {
    super.initState();
    Provider.of<AuthController>(context, listen: false).setCountryCode(CountryCode.fromCountryCode(Provider.of<SplashController>(context, listen: false).configModel!.countryCode!).dialCode!, notify: false);

  }

  @override
  Widget build(BuildContext context) {
    final config =  Provider.of<SplashController>(context, listen: false).configModel;
    return Column(children: [
      Consumer<AuthController>(
          builder: (context, authProvider, _) {
            return Consumer<SplashController>(
                builder: (context, splashProvider,_) {
                  return Form(
                    key: signUpFormKey,
                    child: Column(children: [
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall,),
                      Container(
                          margin: const EdgeInsets.only(left: Dimensions.marginSizeDefault, right: Dimensions.marginSizeDefault),
                          child: CustomTextFieldWidget(
                              hintText: getTranslated('first_name', context),
                              labelText: getTranslated('first_name', context),
                              labelTextStyle: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color),
                              inputType: TextInputType.name,
                              required: true,
                              focusNode: _fNameFocus,
                              nextFocus: _lNameFocus,
                              prefixIcon: Images.username,
                              capitalization: TextCapitalization.words,
                              controller: _firstNameController,
                              validator: (value)  => ValidateCheck.validateEmptyText(value, "first_name_field_is_required"))),


                      Container(margin: const EdgeInsets.only(left: Dimensions.marginSizeDefault, right: Dimensions.marginSizeDefault,
                          top: Dimensions.marginSizeSmall),
                          child: CustomTextFieldWidget(
                              hintText: getTranslated('last_name', context),
                              labelText: getTranslated('last_name', context),
                              labelTextStyle: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color),
                              focusNode: _lNameFocus,
                              prefixIcon: Images.username,
                              nextFocus: _emailFocus,
                              required: true,
                              capitalization: TextCapitalization.words,
                              controller: _lastNameController,
                              validator: (value)  => ValidateCheck.validateEmptyText(value, "last_name_field_is_required"))),

                      Container(margin: const EdgeInsets.only(left: Dimensions.marginSizeDefault, right: Dimensions.marginSizeDefault,
                          top: Dimensions.marginSizeSmall),
                          child: CustomTextFieldWidget(
                              hintText: getTranslated('enter_your_email', context),
                              labelText: getTranslated('enter_your_email', context),
                              labelTextStyle: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color),
                              focusNode: _emailFocus,
                              nextFocus: _phoneFocus,
                              required: true,
                              inputType: TextInputType.emailAddress,
                              controller: _emailController,
                              prefixIcon: Images.email,
                              validator: (value) => ValidateCheck.validateEmail(value))),



                      Container(margin: const EdgeInsets.only(left: Dimensions.marginSizeDefault,
                        right: Dimensions.marginSizeDefault, top: Dimensions.marginSizeSmall),
                        child: CustomTextFieldWidget(
                          hintText: getTranslated('enter_mobile_number', context),
                          labelText: getTranslated('enter_mobile_number', context),
                          labelTextStyle: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color),
                          controller: _phoneController,
                          focusNode: _phoneFocus,
                          nextFocus: _passwordFocus,
                          required: true,
                          showCodePicker: true,
                          countryDialCode: authProvider.countryDialCode,
                          onCountryChanged: (CountryCode countryCode) {
                            _phoneFocus.requestFocus();
                            authProvider.countryDialCode = countryCode.dialCode!;
                            authProvider.setCountryCode(countryCode.dialCode!);
                          },
                          isAmount: true,
                          validator: (value)=> ValidateCheck.validatePhoneNoText(value, authProvider.countryDialCode, "phone_must_be_required"),
                          inputAction: TextInputAction.next,
                          inputType: TextInputType.phone)),




                      Container(margin: const EdgeInsets.only(left: Dimensions.marginSizeDefault,
                          right: Dimensions.marginSizeDefault, top: Dimensions.marginSizeSmall),
                          child: CustomTextFieldWidget(
                              hintText: getTranslated('minimum_password_length', context),
                              labelText: getTranslated('password', context),
                              labelTextStyle: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color),
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              isPassword: true,required: true,
                              nextFocus: _confirmPasswordFocus,
                              inputAction: TextInputAction.next,
                              validator: (value)=> ValidateCheck.validatePassword(value, "password_must_be_required"),
                              prefixIcon: Images.pass)),



                      Hero(tag: 'user',
                          child: Container(margin: const EdgeInsets.only(left: Dimensions.marginSizeDefault,
                              right: Dimensions.marginSizeDefault, top: Dimensions.marginSizeSmall),
                              child: CustomTextFieldWidget(
                                  isPassword: true,required: true,
                                  hintText: getTranslated('re_enter_password', context),
                                  labelText: getTranslated('re_enter_password', context),
                                  labelTextStyle: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color),
                                  controller: _confirmPasswordController,
                                  focusNode: _confirmPasswordFocus,
                                  inputAction: TextInputAction.done,
                                  validator: (value)=> ValidateCheck.validateConfirmPassword(value, _passwordController.text.trim()),
                                  prefixIcon: Images.pass))),


                      //if(splashProvider.configModel!.refEarningStatus != null && splashProvider.configModel!.refEarningStatus == "1")
                      // Padding(padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault, left: Dimensions.paddingSizeDefault),
                      //   child: Row(children: [Text(getTranslated('refer_code', context)??'')])),
                        if(splashProvider.configModel?.refEarningStatus != null && splashProvider.configModel?.refEarningStatus == "1")
                          Container(margin: const EdgeInsets.only(left: Dimensions.marginSizeDefault,
                              right: Dimensions.marginSizeDefault, top: Dimensions.marginSizeSmall),
                              child: CustomTextFieldWidget(
                                  hintText: getTranslated('enter_refer_code', context),
                                  labelText: getTranslated('referral_code', context),
                                  labelTextStyle: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color),
                                  controller: _referController,
                                  focusNode: _referFocus,
                                  prefixIcon: Images.referImage,
                                  prefixColor: Theme.of(context).primaryColor,
                                  inputAction: TextInputAction.done)),

                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      const ConditionCheckBox(),

                      Container(margin: const EdgeInsets.all(Dimensions.paddingSizeDefault), child: Hero(
                        tag: 'onTap',
                        child: CustomButton(
                          isLoading: authProvider.isLoading,
                          onTap: authProvider.isAcceptTerms ?  (){
                            String firstName = _firstNameController.text.trim();
                            String lastName = _lastNameController.text.trim();
                            String email = _emailController.text.trim();
                            String phoneNumber = authProvider.countryDialCode +_phoneController.text.trim();
                            String password = _passwordController.text.trim();

                            if(signUpFormKey.currentState?.validate() ?? false) {
                              register.fName = firstName;
                              register.lName = lastName;
                              register.email = email;
                              register.phone = phoneNumber;
                              register.password = password;
                              register.referCode = _referController.text.trim();
                              authProvider.registration(register, route, config!);
                            }
                          } : null, buttonText: getTranslated('sign_up', context),
                        ),
                      )),


                      authProvider.isLoading ? const SizedBox() :
                      Center(child: Padding(padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraLarge),
                        child: InkWell(onTap: () {
                          authProvider.getGuestIdUrl();
                          Navigator.pop(context);
                        },
                          child: Column(children: [
                            Text(getTranslated('already_have_account', context)!, style: titleRegular.copyWith(fontSize: Dimensions.fontSizeDefault)),

                            Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                              Text(getTranslated('sign_in', context)!, style: titilliumRegular.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                color: Theme.of(context).primaryColor,
                              )),

                              Icon(Icons.arrow_forward, size: Dimensions.iconSizeExtraSmall, color: Theme.of(context).primaryColor)
                            ]),
                          ]),
                        ),
                      )),
                    ]),
                  );
                }
            );
          }
      ),
    ]);
  }
}
