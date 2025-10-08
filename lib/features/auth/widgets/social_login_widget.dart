import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/domain/models/signup_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/domain/models/social_login_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/enums/from_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/enums/social_login_options.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/otp_registration_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/widgets/existing_account_bottom_sheet.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/domain/models/profile_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/responsive_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/facebook_login_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/google_login_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialLoginWidget extends StatefulWidget {
  const SocialLoginWidget({super.key});

  @override
  SocialLoginWidgetState createState() => SocialLoginWidgetState();
}

class SocialLoginWidgetState extends State<SocialLoginWidget> {
  SocialLoginModel socialLogin = SocialLoginModel();

  @override
  Widget build(BuildContext context) {
    final ConfigModel? configModel = Provider.of<SplashController>(context, listen: false).configModel;
    final socialLoginConfig = configModel?.customerLogin?.socialMediaLoginOptions;
    List<String> socialLoginList = [];

    if(socialLoginConfig?.facebook == 1) {
      socialLoginList.add("facebook");
    }

    if (socialLoginConfig?.google == 1) {
      socialLoginList.add("google");
    }

    if (socialLoginConfig?.apple == 1) {
      socialLoginList.add("apple");
    }

    return Consumer<AuthController>(builder: (context, authProvider, _) {
      if (socialLoginList.length == 1) {
        return Row(children: [
          if (socialLoginConfig?.google == 1)
            Expanded(
                child: InkWell(
                  onTap: () => googleLogin(context),
                  child: SocialLoginButtonWidget(
                    text: getTranslated('continue_with_google', context)!,
                    image: Images.google,
                  ),
                )),
           if (socialLoginConfig?.facebook == 1)
            Expanded(
              child: InkWell(
                onTap: () => facebookLogin(context),
                child: SocialLoginButtonWidget(
                  text: getTranslated('continue_with_facebook', context)!,
                  image: Images.facebook,
                ),
              ),),

            if(socialLoginConfig?.apple == 1 && defaultTargetPlatform == TargetPlatform.iOS)
              Expanded(
                child: InkWell(
                  onTap: () => appleLogin(context),
                  child: SocialLoginButtonWidget(
                    text: getTranslated('continue_with_apple', context)!,
                    image: Images.appleLogo,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
          ]);
        } else if(socialLoginList.length == 2){
          return Row(mainAxisAlignment: MainAxisAlignment.center, children: [

            if(socialLoginConfig?.google == 1)...[
              Expanded(child: InkWell(
                onTap: () => googleLogin(context),
                child: SocialLoginButtonWidget(
                  text: getTranslated('google', context)!,
                  image: Images.google,
                ),

              )),
              const SizedBox(width: Dimensions.paddingSizeDefault),
            ],


            if(socialLoginConfig?.facebook == 1)...[

              Expanded(child: InkWell(
                onTap: () => facebookLogin(context),
                child: SocialLoginButtonWidget(
                  text: getTranslated('facebook', context)!,
                  image: Images.facebook,
                ),
              )),
              socialLoginConfig?.apple == 1 ? const SizedBox(width: Dimensions.paddingSizeDefault)
                  : const SizedBox.shrink(),
            ],

            if(socialLoginConfig?.apple == 1 && defaultTargetPlatform == TargetPlatform.iOS)...[
              Expanded(
                child: InkWell(
                  onTap: () => appleLogin(context),
                  child: SocialLoginButtonWidget(
                    text: getTranslated('continue_with_apple', context)!,
                    image: Images.appleLogo,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ],

          ]);
        }   else if(socialLoginList.length == 3){
        return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (socialLoginConfig?.google == 1) ...[
            InkWell(
              onTap: () => googleLogin(context),
              child: const SocialLoginButtonWidget(
                image: Images.google,
                padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeLarge),
          ],
          if (socialLoginConfig?.facebook == 1) ...[
            InkWell(
              onTap: () => facebookLogin(context),
              child: const SocialLoginButtonWidget(
                image: Images.facebook,
                padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeLarge),
          ],
          if (socialLoginConfig?.apple == 1 &&
              defaultTargetPlatform == TargetPlatform.iOS) ...[
            InkWell(
              onTap: () => appleLogin(context),
              child: SocialLoginButtonWidget(
                image: Images.appleLogo,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              ),
            ),
          ],
        ]);
      } else {
        return Container(
          height: 50,
          width: 50,
          color: Colors.red,
        );
      }
    });

    ///Prev Code
    // return Column(children: [
    //     (Provider.of<SplashController>(context,listen: false).configModel!.socialLogin![0].status! ||
    //    Provider.of<SplashController>(context,listen: false).configModel!.socialLogin![1].status! ||
    //         Provider.of<SplashController>(context,listen: false).configModel!.socialLogin![2].status!)?
    //
    //     Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    //         Expanded(child: Image.asset(Images.left, color: Theme.of(context).primaryColor)),
    //         const SizedBox(width: Dimensions.paddingSizeSmall,),
    //         Center(child: Text(getTranslated('or_login_with', context)??'', style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault),)),
    //         const SizedBox(width: Dimensions.paddingSizeSmall,),
    //         Expanded(child: Image.asset( Images.right))]) :const SizedBox(),
    //
    //
    //     Padding(padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
    //       child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    //          Provider.of<SplashController>(context,listen: false).configModel!.socialLogin![0].status!?
    //
    //           InkWell(onTap: () async{
    //               await Provider.of<GoogleSignInController>(context, listen: false).login();
    //               String? id,token,email, medium;
    //               if(context.mounted){}
    //               if(Provider.of<GoogleSignInController>(Get.context!,listen: false).googleAccount != null){
    //                 id = Provider.of<GoogleSignInController>(Get.context!,listen: false).googleAccount!.id;
    //                 email = Provider.of<GoogleSignInController>(Get.context!,listen: false).googleAccount!.email;
    //                 token = Provider.of<GoogleSignInController>(Get.context!,listen: false).auth.accessToken;
    //                 medium = 'google';
    //                 log('eemail =>$email token =>$token');
    //
    //                 socialLogin.email = email;
    //                 socialLogin.medium = medium;
    //                 socialLogin.token = token;
    //                 socialLogin.uniqueId = id;
    //                 await Provider.of<AuthController>(Get.context!, listen: false).socialLogin(socialLogin, route);
    //               }
    //
    //             },
    //             child: Padding(padding: const EdgeInsets.all(6),
    //               child: Container(decoration: BoxDecoration(
    //                 borderRadius: BorderRadius.circular(100),
    //                 color: Theme.of(context).cardColor,
    //                 boxShadow: [BoxShadow(color: Theme.of(context).hintColor.withValues(alpha:.25), blurRadius: 1, spreadRadius: 1, offset: const Offset(0,0))]),
    //                 child: Padding(padding: const EdgeInsets.all(8.0),
    //                   child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
    //                       Container(decoration: const BoxDecoration(color: Colors.white ,
    //                           borderRadius: BorderRadius.all(Radius.circular(5))),
    //                         height: 47,width: 47,
    //                         child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
    //                           child: Image.asset(Images.google))), // <-- Use 'Image.asset(...)' here
    //                     ]))))) :const SizedBox(),
    //
    //
    //           Provider.of<SplashController>(context,listen: false).configModel!.socialLogin![1].status!?
    //           InkWell(onTap: () async{
    //               await Provider.of<FacebookLoginController>(context, listen: false).login();
    //               String? id,token,email, medium;
    //               if(Provider.of<FacebookLoginController>(Get.context!,listen: false).userData != null){
    //                 id = Provider.of<FacebookLoginController>(Get.context!,listen: false).result.accessToken!.userId;
    //                 email = Provider.of<FacebookLoginController>(Get.context!,listen: false).userData!['email'];
    //                 token = Provider.of<FacebookLoginController>(Get.context!,listen: false).result.accessToken!.token;
    //                 medium = 'facebook';
    //                 socialLogin.email = email;
    //                 socialLogin.medium = medium;
    //                 socialLogin.token = token;
    //                 socialLogin.uniqueId = id;
    //                 await Provider.of<AuthController>(Get.context!, listen: false).socialLogin(socialLogin, route);
    //               }
    //             },
    //             child: Padding(padding: const EdgeInsets.all(6),
    //               child: Container(decoration: BoxDecoration(
    //                   borderRadius: BorderRadius.circular(100),
    //                   color: Theme.of(context).cardColor,
    //                   boxShadow: [BoxShadow(color: Theme.of(context).hintColor.withValues(alpha:.25), blurRadius: 1, spreadRadius: 1, offset: const Offset(0,0))]),
    //                 child: Padding(padding: const EdgeInsets.all(8.0),
    //                   child: Wrap(crossAxisAlignment: WrapCrossAlignment.center,
    //                     children: [SizedBox(height: 47,width: 47,
    //                         child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
    //                           child: Image.asset(Images.facebook),)),
    //                     ]))))):const SizedBox(),
    //
    //
    //           if(Provider.of<SplashController>(context,listen: false).configModel!.socialLogin!.length >2 && Provider.of<SplashController>(context,listen: false).configModel!.socialLogin![2].status! && Platform.isIOS)
    //           Padding(padding: const EdgeInsets.all(6.0),
    //             child: Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
    //               child: SizedBox(width: 70,height: 70,
    //                 child: ClipRRect(borderRadius: BorderRadius.circular(100),
    //                   child: SignInWithAppleButton(
    //                     style: Provider.of<ThemeController>(context, listen: false).darkTheme? SignInWithAppleButtonStyle.black : SignInWithAppleButtonStyle.white,
    //                     text: '',
    //                     height: 47,
    //                     onPressed: () async {
    //                       String? id,token,email, medium;
    //                       final credential = await SignInWithApple.getAppleIDCredential(
    //                         scopes: [AppleIDAuthorizationScopes.email,
    //                           AppleIDAuthorizationScopes.fullName]);
    //                       id = credential.authorizationCode;
    //                       email = credential.email??'';
    //                       token = credential.authorizationCode;
    //                       medium = 'apple';
    //                       socialLogin.email = email;
    //                       socialLogin.medium = medium;
    //                       socialLogin.token = token;
    //                       socialLogin.uniqueId = id;
    //                       await Provider.of<AuthController>(Get.context!, listen: false).socialLogin(socialLogin, route);
    //
    //                       log('id token =>${credential.identityToken}\n===> Identifier${credential.userIdentifier}\n==>Given Name ${credential.familyName}');
    //                     },
    //                   ),
    //                 ),
    //               ),
    //             ),
    //           )
    //         ],
    //       ),
    //     ),
    //   ]);
  }
}

Future<void> route(
    bool isRoute,
    String? token,
    String? temporaryToken,
    ProfileModel? profileModel,
    String? errorMessage,
    String? loginMedium,
    String? phone,
    String? email,
    String? name,
    ) async {
  final AuthController authProvider = Provider.of<AuthController>(Get.context!, listen: false);

  if (isRoute) {
    if (phone != null) {
      // authProvider.sendVerificationCode(config, signUpModel)
      await authProvider.sendVerificationCode(Provider.of<SplashController>(Get.context!, listen: false).configModel!,
          SignUpModel(email: null, phone: phone),
          type: 'phone',
          fromPage: FromPage.login);
    } else if (token != null) {
      Navigator.pushAndRemoveUntil(
          Get.context!,
          MaterialPageRoute(builder: (_) => const DashBoardScreen()), (route) => false);
    } else if (temporaryToken != null && temporaryToken.isNotEmpty) {
      Navigator.pushAndRemoveUntil(
        Get.context!,
        MaterialPageRoute(builder: (_) => OtpRegistrationScreen(tempToken: temporaryToken, userInput: email ?? '', userName: name ?? '')), (route) => false);
    } else if (profileModel != null) {
      showModalBottomSheet(
        context: Get.context!,
        isScrollControlled: true,
        backgroundColor:
        Theme.of(Get.context!).primaryColor.withValues(alpha: 0),
        builder: (con) => ExistingAccountBottomSheet(
          profileModel: profileModel,
          socialLoginMedium: loginMedium!,
          con: con,
        ));
    } else {
      showCustomSnackBar(errorMessage, Get.context!);
    }
  } else {
    showCustomSnackBar(errorMessage, Get.context!);
  }
}

Future<void> googleLogin(BuildContext context) async {
  SocialLoginModel socialLogin = SocialLoginModel();

  try {
    await Provider.of<GoogleSignInController>(context, listen: false).login();
    String? id, token, email, medium, name;
    if (context.mounted) {}
    if (Provider.of<GoogleSignInController>(Get.context!, listen: false).googleAccount != null) {
      id = Provider.of<GoogleSignInController>(Get.context!, listen: false).googleAccount!.id;
      email = Provider.of<GoogleSignInController>(Get.context!, listen: false).googleAccount!.email;
      token = Provider.of<GoogleSignInController>(Get.context!, listen: false).auth?.accessToken;
      name =  Provider.of<GoogleSignInController>(Get.context!, listen: false).googleAccount!.displayName;
      medium = 'google';
      log('eemail =>$email token =>$token');

      socialLogin.email = email;
      socialLogin.medium = medium;
      socialLogin.token = token;
      socialLogin.uniqueId = id;
      socialLogin.name = name;

      await Provider.of<AuthController>(Get.context!, listen: false).socialLogin(socialLogin, route);
    }
  } catch (er) {
    debugPrint('access token error is : $er');
  }
}

Future<void> facebookLogin(BuildContext context) async {
  SocialLoginModel socialLogin = SocialLoginModel();

  try {
    await Provider.of<FacebookLoginController>(context, listen: false).login();
    String? id, token, email, medium, name;
    if (Provider.of<FacebookLoginController>(Get.context!, listen: false).userData != null) {
      id = Provider.of<FacebookLoginController>(Get.context!, listen: false).userData?['id'];
      email = Provider.of<FacebookLoginController>(Get.context!, listen: false).userData?['email'];
      token = Provider.of<FacebookLoginController>(Get.context!, listen: false).result.accessToken?.tokenString;
      name = Provider.of<FacebookLoginController>(Get.context!, listen: false).userData?['name'] ?? '';
      medium = 'facebook';
      socialLogin.email = email;
      socialLogin.medium = medium;
      socialLogin.token = token;
      socialLogin.uniqueId = id;
      await Provider.of<AuthController>(Get.context!, listen: false).socialLogin(socialLogin, route);
    }
  } catch (er) {
    debugPrint('access token error is : $er');
  }
}

Future<void> appleLogin(BuildContext context) async {
  SocialLoginModel socialLogin = SocialLoginModel();
  try {
    String? id, token, email, medium;
    final credential = await SignInWithApple.getAppleIDCredential(scopes: [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName
    ]);



    id = credential.authorizationCode;
    email = await Provider.of<AuthController>(Get.context!, listen: false).onConfigurationAppleEmail(credential);

    token = credential.authorizationCode;
    medium = 'apple';
    socialLogin.email = email;
    socialLogin.medium = medium;
    socialLogin.token = token;
    socialLogin.uniqueId = id;
    socialLogin.name = credential.givenName ?? '';
    await Provider.of<AuthController>(Get.context!, listen: false).socialLogin(socialLogin, route);

    log('id token =>${credential.identityToken}\n===> Identifier${credential.userIdentifier}\n==>Given Name ${credential.familyName}');
  } catch (er) {
    debugPrint('access token error is : $er');
  }
}

class SocialLoginButtonWidget extends StatelessWidget {
  final String? text;
  final String image;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final SocialLoginOption? option;
  const SocialLoginButtonWidget({super.key, this.text, required this.image, this.color, this.padding, this.option});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).hintColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            image,
            color: color,
            height: ResponsiveHelper.isTab(context) ? 20 : 15,
            width: ResponsiveHelper.isTab(context) ? 20 : 15,
          ),
          if (text != null) ...[
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            Text(text!,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            )
          ],
        ],
      ),
    );
  }
}
