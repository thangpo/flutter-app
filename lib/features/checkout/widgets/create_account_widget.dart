import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_textfield_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/controllers/checkout_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/velidate_check.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

class CreateAccountWidget extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  const CreateAccountWidget({super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckoutController>(
      builder: (context, checkoutController, _) {
        return Card(child: Container(padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
              color: Theme.of(context).cardColor),
            child: Column( crossAxisAlignment:CrossAxisAlignment.start, children: [
              Row(children: [
                 SizedBox(
                  height: 24, width: 30,
                  child: Checkbox(
                    visualDensity: VisualDensity.compact,
                    side: WidgetStateBorderSide.resolveWith(
                            (states) => BorderSide(width: 2, color: Theme.of(context).primaryColor.withValues(alpha:0.10))),
                    checkColor: Colors.white,
                    value: checkoutController.isCheckCreateAccount,
                    onChanged: (bool? value) {
                      checkoutController.setIsCheckCreateAccount(value!, update: true);
                    },
                  ),
                ),

                Text(getTranslated('create_account_with', context)!,
                    style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color))

              ]),

              checkoutController.isCheckCreateAccount ?
              Form(key: formKey, child: Column(
                children: [
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  CustomTextFieldWidget(
                    hintText: getTranslated('minimum_password_length', context),
                    labelText: getTranslated('password', context),
                    controller: checkoutController.passwordController,
                    isPassword: true,
                    required: true,
                    //nextFocus: _confirmPasswordFocus,
                    inputAction: TextInputAction.next,
                    validator: (value)=> ValidateCheck.validatePassword(value, "password_must_be_required"),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  CustomTextFieldWidget(
                    isPassword: true,
                    required: true,
                    hintText: getTranslated('re_enter_password', context),
                    labelText: getTranslated('re_enter_password', context),
                    controller:  checkoutController.confirmPasswordController,
                    // focusNode: _confirmPasswordFocus,
                    inputAction: TextInputAction.done,
                    validator: (value)=> ValidateCheck.validateConfirmPassword(value, checkoutController.passwordController.text.trim()),
                  ),
                ],
              )) : const SizedBox(),
            ])
        ));
      }
    );

  }
}
