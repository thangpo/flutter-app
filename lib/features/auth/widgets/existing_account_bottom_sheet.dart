import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/domain/models/user_log_data.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/otp_registration_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/domain/models/profile_model.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

class ExistingAccountBottomSheet extends StatefulWidget {
  final ProfileModel profileModel;
  final String socialLoginMedium;
  final BuildContext con;
  const ExistingAccountBottomSheet({
    super.key,
    required this.profileModel,
    required this.socialLoginMedium,
    required this.con
  });


  @override
  State<ExistingAccountBottomSheet> createState() => _ExistingAccountBottomSheetState();
}

class _ExistingAccountBottomSheetState extends State<ExistingAccountBottomSheet> {
  @override
  Widget build(BuildContext context) {

    final Size size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        SizedBox(height: size.height * 0.015),

        CircleAvatar(
          radius: size.height * 0.05,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: CustomImageWidget(
              image: widget.profileModel.image != null ? "${widget.profileModel.imageFullUrl?.path}" : '',
              fit: BoxFit.fill,
            ),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Text("${widget.profileModel.fName} ${widget.profileModel.lName}",
          style: titilliumRegular.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraLarge),

        Text(getTranslated('is_it_you', context)!,
          style: titilliumRegular.copyWith(
            fontSize: Dimensions.fontSizeLarge,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.height * 0.02,
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(children:[

              TextSpan(
                text: getTranslated('it_looks_like_the_email', context)!,
                style: titilliumRegular.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).hintColor.withValues(alpha:0.5),
                ),
              ),

              TextSpan(
                text: ' ${widget.profileModel.email} ',
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).hintColor,
                ),
              ),

              TextSpan(
                text: getTranslated('already_used_existing_account', context)!,
                style: titilliumRegular.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).hintColor.withValues(alpha:0.5),
                ),
              ),

            ])),
        ),
        SizedBox(height: size.height * 0.02),

        Row(children: [

          Expanded(child: Container()),

          Expanded(flex: 3, child: Consumer<AuthController>(
              builder: (context, authProvider, child) {
                return CustomButton(
                  backgroundColor: Theme.of(context).hintColor,
                  isLoading: authProvider.isPhoneNumberVerificationButtonLoading,
                  buttonText: getTranslated('no', context)!,
                  onTap: (){

                    if(authProvider.isPhoneNumberVerificationButtonLoading){

                    }else{
                      Navigator.pop(widget.con);
                      authProvider.existingAccountCheck(
                          email: widget.profileModel.email!,
                          userResponse: 0,
                          medium: widget.socialLoginMedium
                      ).then((value){

                        final (responseModel, tempToken) = value;
                        if(responseModel != null && responseModel.isSuccess && responseModel.message == 'token') {

                          authProvider.saveUserEmailAndPassword(
                            UserLogData(
                              phoneNumber: widget.profileModel.phone,
                              email: widget.profileModel.email,
                              password: null,
                            ),
                          );
                          Navigator.pushAndRemoveUntil(Get.context!, MaterialPageRoute(builder: (_) => const DashBoardScreen()), (route) => false);

                        }else if(responseModel != null && responseModel.isSuccess && responseModel.message == 'tempToken'){
                          Navigator.push(Get.context!, MaterialPageRoute(builder: (_) => OtpRegistrationScreen(tempToken: tempToken!, userInput: widget.profileModel.email ?? '', userName: "${widget.profileModel.fName} ${widget.profileModel.lName}" )));
                        }

                      });
                    }

                  },
                );
              }
          ),),

          Expanded(child: Container()),

          Expanded(flex: 3,child: Consumer<AuthController>(
              builder: (context, authProvider, child) {
                return CustomButton(
                  isLoading: authProvider.isPhoneNumberVerificationButtonLoading,
                  buttonText: getTranslated('yes_its_me', context)!,
                  onTap: (){

                    if(authProvider.isPhoneNumberVerificationButtonLoading){

                    }else{
                      Navigator.pop(widget.con);
                      authProvider.existingAccountCheck(
                          email: widget.profileModel.email!,
                          userResponse: 1,
                          medium: widget.socialLoginMedium
                      ).then((value){

                        final (responseModel, tempToken) = value;
                        if(responseModel != null && responseModel.isSuccess && responseModel.message == 'token') {

                          authProvider.saveUserEmailAndPassword(
                            UserLogData(
                              phoneNumber: widget.profileModel.phone,
                              email: widget.profileModel.email,
                              password: null,
                            ),
                          );
                          Navigator.pushAndRemoveUntil(Get.context!, MaterialPageRoute(builder: (_) => const DashBoardScreen()), (route) => false);
                        }else if(responseModel != null && responseModel.isSuccess && responseModel.message == 'tempToken'){
                          Navigator.push(Get.context!, MaterialPageRoute(builder: (_) => OtpRegistrationScreen(tempToken: tempToken!, userInput: widget.profileModel.email ?? '', userName: "${widget.profileModel.fName} ${widget.profileModel.lName}" )));
                        }

                      });
                    }

                  },
                );
              }
          ),),

          Expanded(child: Container()),

        ]),

        const SizedBox(height: Dimensions.paddingSizeLarge),


      ]),
    );
  }
}