import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/screens/specification_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';


class ProductSpecificationWidget extends StatelessWidget {
  final String productSpecification;

  const ProductSpecificationWidget({super.key, required this.productSpecification});

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(getTranslated('product_specification', context)??'',style: textMedium ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

        Column(children: [
          Stack(children: [
            Container(
              height: (productSpecification.isNotEmpty && productSpecification.length > 400) ? 150 : null,
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall).copyWith(bottom: 0),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: HtmlWidget(
                  productSpecification,
                  onTapUrl: (String url) {
                    return launchUrl(Uri.parse(url),mode: LaunchMode.externalApplication);
                  },
                  textStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
              ),
            ),

            if( (productSpecification.isNotEmpty && productSpecification.length > 400)) Positioned.fill(child: Align(
              alignment: Alignment.bottomCenter, child: Container(
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
                Theme.of(context).cardColor.withValues(alpha:0),
                Theme.of(context).cardColor,
              ])),
              height: 55,
            ),
            )),

          ]),

          if(productSpecification.isNotEmpty && productSpecification.length > 400)
            Center(child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SpecificationScreen(specification: productSpecification))),
              child: Text(getTranslated('view_full_detail', context)!, style: titleRegular.copyWith(
                color: Provider.of<ThemeController>(context, listen: false).darkTheme
                    ? Colors.white
                    : Theme.of(context).primaryColor,
              )),
            )),


        ]),
      ]),
    );
  }
}
