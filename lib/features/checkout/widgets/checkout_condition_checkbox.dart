import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/controllers/checkout_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/more/screens/html_screen_view.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/business_pages_model.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

class CheckoutConditionCheckBox extends StatelessWidget {
  const CheckoutConditionCheckBox({super.key});

  @override
  Widget build(BuildContext context) {
    final SplashController splashController = Provider.of<SplashController>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Consumer<CheckoutController>(
          builder: (ctx, checkoutController, _){
            return Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              InkWell(
                onTap: ()=> checkoutController.toggleTermsCheck(),
                child: Row(children: [
                  SizedBox(width : 20, height : 20,
                      child: Container(alignment: Alignment.center,
                          decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha:.75), width: 1.5),
                              borderRadius: BorderRadius.circular(6)),
                          child: Icon(CupertinoIcons.checkmark_alt,size: 15,
                              color: checkoutController.isAcceptTerms? Theme.of(context).primaryColor.withValues(alpha:.75): Colors.transparent))),
                ]),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),


              Flexible(
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style.copyWith(color: Theme.of(context).textTheme.headlineLarge?.color),
                    children: <InlineSpan>[
                      TextSpan(
                        text: getTranslated('i_have_read_and_agree_to_the_website', context) ?? '',
                        style: textMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge?.color)
                      ),
                
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: IntrinsicWidth(
                          child: InkWell(
                            onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_) => HtmlViewScreen(
                              page: getPageBySlug('terms-and-conditions', splashController.defaultBusinessPages),
                            ))),
                            child: Text(getTranslated('terms_condition', context)!, style: textMedium.copyWith(
                              fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor.withValues(alpha:0.8),
                              decoration: TextDecoration.underline, decorationColor: Theme.of(context).primaryColor,
                            )),
                          ),
                        ),
                      ),
                      const TextSpan(text: ', '),
                
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: IntrinsicWidth(
                          child: InkWell(
                            onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_) => HtmlViewScreen(
                              page: getPageBySlug('privacy-policy', splashController.defaultBusinessPages),
                            ))),
                            child: Text(getTranslated('privacy_policy', context)!, style: textMedium.copyWith(
                              fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor.withValues(alpha:0.8),
                              decoration: TextDecoration.underline, decorationColor: Theme.of(context).primaryColor,
                            )),
                          ),
                        ),
                      ),
                      const TextSpan(text: ', '),
                
                      if(getPageBySlug('refund-policy', splashController.defaultBusinessPages) != null)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: IntrinsicWidth(
                          child: InkWell(
                            onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_) => HtmlViewScreen(
                              page: getPageBySlug('refund-policy', splashController.defaultBusinessPages),
                            ))),
                            child: Text(getTranslated('refund_policy', context)!, style: textMedium.copyWith(
                              fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor.withValues(alpha:0.8),
                              decoration: TextDecoration.underline, decorationColor: Theme.of(context).primaryColor,
                            )),
                          ),
                        ),
                      ),
                
                    ],
                  ),
                  textAlign: TextAlign.left,
                ),
              ),






            ]);
          }
      ),
    );
  }

  BusinessPageModel? getPageBySlug(String slug, List<BusinessPageModel>? pagesList) {
    BusinessPageModel? pageModel;
    if(pagesList != null && pagesList.isNotEmpty){
      for (var page in pagesList) {
        if(page.slug == slug) {
          pageModel = page;
        }
      }
    }

    return pageModel;
  }

}
