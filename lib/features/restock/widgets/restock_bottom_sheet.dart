import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/controllers/product_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/screens/product_details_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/push_notification/models/notification_body.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:provider/provider.dart';



class RestockSheetWidget extends StatefulWidget {
  final NotificationBody? notificationBody;
  const RestockSheetWidget({super.key, this.notificationBody});

  @override
  RestockSheetWidgetState createState() => RestockSheetWidgetState();
}

class RestockSheetWidgetState extends State<RestockSheetWidget> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.only(top : Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(color: Theme.of(context).highlightColor,
            borderRadius: const BorderRadius.only(topRight: Radius.circular(20), topLeft: Radius.circular(20))),
        child: Consumer<ProductDetailsController>(
          builder: (ctx, details, child) {
            return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [


              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                    child: Container(
                      height: 3, width: 40,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(20)),
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                ],
              ),


              Align(
                alignment: Alignment.centerRight, child: InkWell(onTap: () => Navigator.pop(context),
                  child: const Padding(padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                    child: Icon(Icons.close, size: 30)
                  )
                )
              ),

              CustomImageWidget(image: widget.notificationBody?.image ?? '', height: 100, width: 100),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              Text(widget.notificationBody?.title ?? '', maxLines: 2,
                overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge)
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              Text(widget.notificationBody?.status == 'product_restocked' ?
                 getTranslated('this_product_has_been_restock', context)!
                 : getTranslated('this_product_has_been_updated', context)!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              SizedBox(
                height: 40, width: 230,
                child: CustomButton(
                  textColor: Colors.white,
                  buttonText: getTranslated('view_product', context),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context, PageRouteBuilder(transitionDuration: const Duration(milliseconds: 1000),
                      pageBuilder: (context, anim1, anim2) => ProductDetails(
                        productId: int.tryParse(widget.notificationBody?.productId ?? ''),
                        slug: widget.notificationBody?.slug)
                      )
                    );
                  },
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

            ]);
          },
        ),
      ),
    ],
   );
  }




}



