import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_asset_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/login_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:provider/provider.dart';

class DeleteAccountBottomSheet extends StatelessWidget {
  final String customerId;
  const DeleteAccountBottomSheet({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.paddingSizeDefault))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        Container(width: 40,height: 5,decoration: BoxDecoration(
          color: Theme.of(context).hintColor.withValues(alpha:.5),
          borderRadius: BorderRadius.circular(20),
        )),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
          child: CustomAssetImageWidget(Images.delete, height: 60, width: 60),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

        Text(getTranslated('delete_account', context)!, style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color),),
        const SizedBox(height: Dimensions.paddingSizeSmall),


        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Text('${getTranslated('want_to_delete_account', context)}', textAlign: TextAlign.center, style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),),
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),

        Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeOverLarge),
          child: Row(mainAxisAlignment: MainAxisAlignment.center,children: [
            SizedBox(width: 120,child: CustomButton(buttonText: '${getTranslated('cancel', context)}',
              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha:.5),
              textColor: Theme.of(context).textTheme.bodyLarge?.color,
              onTap: ()=> Navigator.pop(context),)),
            const SizedBox(width: Dimensions.paddingSizeDefault,),

            SizedBox(width: 120,child: Consumer<ProfileController>(
              builder: (context, profileController, _) {
                return CustomButton(
                  isLoading: profileController.isDeleting,
                    buttonText: '${getTranslated('delete', context)}',
                    backgroundColor: Theme.of(context).colorScheme.error,
                    onTap: (){
                      profileController.deleteCustomerAccount(context, int.parse(customerId)).then((condition) {
                        if(context.mounted) {
                          Navigator.pop(context);
                          if(condition.response?.statusCode == 200){
                            Navigator.pop(context);
                            Provider.of<AuthController>(context,listen: false).clearSharedData();
                            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen(fromLogout: true)), (route) => false);
                          }
                        }
                      });
                    },
                );
              }
            ))
          ],),
        ),


      ],),
    );
  }
}
