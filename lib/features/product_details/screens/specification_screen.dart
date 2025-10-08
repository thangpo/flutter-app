import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';
class SpecificationScreen extends StatelessWidget {
  final String specification;
  const SpecificationScreen({super.key, required this.specification});

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: Column(children: [
          CustomAppBar(title: getTranslated('specification', context)),
          Expanded(child: SingleChildScrollView(
            child: HtmlWidget(
              specification,
              textStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              onTapUrl: (String url) {
            return launchUrl(Uri.parse(url),mode: LaunchMode.externalApplication);
          }),)),
          const SizedBox(height: Dimensions.paddingSizeSmall),

        ]),
      ),
    );
  }
}
