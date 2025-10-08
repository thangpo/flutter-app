import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/login_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:provider/provider.dart';

class LogoutCustomBottomSheetWidget extends StatelessWidget {
  const LogoutCustomBottomSheetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.only(bottom: 40, top: 15),
      decoration: BoxDecoration(color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.paddingSizeDefault))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40,height: 4,decoration: BoxDecoration(
            color: Theme.of(context).hintColor.withValues(alpha:.5), borderRadius: BorderRadius.circular(20)),),
        const SizedBox(height: 30,),

       Padding(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
          child: SizedBox(width: 60,child: Image.asset(Images.exitIcon)),),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall,),

        Text(getTranslated('sign_out', context)!, style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color)),

        Padding(padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeLarge),
          child: Text('${getTranslated('want_to_sign_out', context)}', style: titleRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color))),

        const SizedBox(height: Dimensions.paddingSizeDefault),
        Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeOverLarge),
          child: Row(mainAxisAlignment: MainAxisAlignment.center,children: [
            Expanded(child: SizedBox(width: 120,child: CustomButton(buttonText: '${getTranslated('cancel', context)}',
                backgroundColor: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha:.5),
                textColor: Theme.of(context).textTheme.bodyLarge?.color,
                onTap: ()=> Navigator.pop(context),))),

            const SizedBox(width: Dimensions.paddingSizeDefault,),
            Expanded(child: SizedBox(width: 120,child: CustomButton(buttonText: '${getTranslated('sign_out', context)}',
                onTap: (){
              Provider.of<AuthController>(context, listen: false).logOut().then((condition) {
                if(context.mounted) {
                  Navigator.pop(context);
                  Provider.of<CartController>(context,listen: false).resetCartList();
                  Provider.of<AuthController>(context,listen: false).clearSharedData();
                  Provider.of<ProfileController>(context,listen: false).clearProfileData();
                  Provider.of<AuthController>(context, listen: false).getGuestIdUrl();
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LoginScreen(fromLogout: true)));
                }
              });
            })))]))

      ],),
    );
  }
}
