import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/business_pages_model.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

class HtmlViewScreen extends StatelessWidget {
  final BusinessPageModel? page;
  const HtmlViewScreen({super.key, required this.page});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Theme.of(context).cardColor,
      body: Column(children: [
          CustomAppBar(title: page?.title ?? ''),
          Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              physics: const BouncingScrollPhysics(),
            child:  Column(
              children: [

                const SizedBox(height: Dimensions.paddingSizeSmall),
                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    child: SizedBox(
                      height: 70,
                      width: double.infinity,
                      child: CustomImageWidget(
                        fit: BoxFit.cover,
                        image: page?.bannerFullUrl?.path ?? "",
                      ),
                    ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                HtmlWidget(page?.description ?? '',
                  onTapUrl: (String url) {
                    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  },
                  textStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
