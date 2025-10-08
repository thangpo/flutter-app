import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/login_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';

class NotLoggedInBottomSheetWidget extends StatelessWidget {
  const NotLoggedInBottomSheetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.only(bottom: 40, top: 15),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.paddingSizeDefault))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40,height: 5,decoration: BoxDecoration(
            color: Theme.of(context).hintColor.withValues(alpha:.5),
            borderRadius: BorderRadius.circular(20)),),
        const SizedBox(height: 40,),
        Padding(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
          child: SizedBox(width: 60,child: Image.asset(Images.loginIcon)),),

        const SizedBox(height: Dimensions.paddingSizeExtraSmall,),
        Text(getTranslated('please_login', context)!, style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color),),

        Padding(padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeLarge),
          child: Text('${getTranslated('need_to_login', context)}', style:  titleRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),),


        const SizedBox(height: Dimensions.paddingSizeDefault,),


        Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeOverLarge),
          child: Row(mainAxisAlignment: MainAxisAlignment.center,children: [
            Expanded(child: SizedBox(width: 120,child: CustomButton(buttonText: '${getTranslated('cancel', context)}',
                backgroundColor: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha:.5),
                textColor: Theme.of(context).textTheme.bodyLarge?.color,
                onTap: ()=> Navigator.pop(context),))),
            const SizedBox(width: Dimensions.paddingSizeExtraLarge,),
            Expanded(
              child: SizedBox(width: 120,child: CustomButton(buttonText: '${getTranslated('login', context)}',
                  backgroundColor: Theme.of(context).primaryColor,
                  onTap: () {Navigator.of(context).pop();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));})),
            )
          ],),
        )

      ],),
    );
  }
}
