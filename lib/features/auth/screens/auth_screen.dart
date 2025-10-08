import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/widgets/sign_up_widget.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatefulWidget{
  final bool fromLogout;
  const AuthScreen({super.key, this.fromLogout = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {


  @override
  void initState() {
    super.initState();
  }
  bool scrolled = false;
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {

        if(didPop) return;

        Navigator.pop(context);
      },
      child: Scaffold(
        body: Consumer<AuthController>(
          builder: (context, authProvider,_) {
            return Column(children: [
                Stack(children: [
                  Container(height: 150, decoration: BoxDecoration(color: Theme.of(context).primaryColor)),
                  Image.asset(Images.loginBg,fit: BoxFit.cover,height: 150, opacity : const AlwaysStoppedAnimation(.15)),

                  Padding(padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * .03),
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [

                          Image.asset(Images.splashLogo, width: 130, height: 80)]),

                        Text(getTranslated('sign_up', context)!, style: titilliumRegular.copyWith(
                          color: Theme.of(context).highlightColor,
                          fontSize: Dimensions.fontSizeLarge,
                        )),
                      ],
                    ),
                  ),
                ]),

                AnimatedContainer(transform: Matrix4.translationValues(0, -12, 0),
                  curve: Curves.fastOutSlowIn,
                  decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge))),
                  duration: const Duration(seconds: 2),
                  child: Padding(padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Padding(padding: const EdgeInsets.symmetric(horizontal:  Dimensions.marginSizeLarge),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          InkWell(onTap: (){},
                            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                              Container(height: 0, width: 25, margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                                color: Theme.of(context).primaryColor))
                            ]),
                          ),
                        ]),
                      ),
                    ],),
                  ),
                ),

              const Expanded(child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, ),
                //child: authProvider.selectedIndex == 0 ? const SignInWidget() : const SignUpWidget(),
                child: SignUpWidget(),
              )),
            ]);
          }
        ),
      ),
    );
  }
}

