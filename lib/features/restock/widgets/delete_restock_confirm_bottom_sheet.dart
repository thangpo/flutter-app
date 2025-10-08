import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_asset_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_loader_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/restock/controllers/restock_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:provider/provider.dart';

class DeleteRestockCustomBottomSheetWidget extends StatelessWidget {
  const DeleteRestockCustomBottomSheetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.only(bottom: 40, top: 15),
      decoration: BoxDecoration(color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.paddingSizeDefault))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40,height: 4,decoration: BoxDecoration(
            color: Theme.of(context).hintColor.withValues(alpha:.5), borderRadius: BorderRadius.circular(20)),),
        const SizedBox(height: 30,),

        const Padding(padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
          child: CustomAssetImageWidget(Images.delete, height: 60, width: 60)),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

        Text(getTranslated('are_you_sure', context)!, style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color),),

        Padding(padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeLarge),
          child: Text('${getTranslated('want_to_remove_all_restock', context)}', style: textRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),)),

        const SizedBox(height: Dimensions.paddingSizeDefault),
        Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeOverLarge),
            child: Row(mainAxisAlignment: MainAxisAlignment.center,children: [
              Expanded(child: SizedBox(width: 120,child: CustomButton(buttonText: '${getTranslated('cancel', context)}',
                backgroundColor: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha:.5),
                textColor: Theme.of(context).textTheme.bodyLarge?.color,
                onTap: ()=> Navigator.pop(context)))),

              const SizedBox(width: Dimensions.paddingSizeDefault,),
              Expanded(child: SizedBox(width: 120,child: CustomButton(buttonText: '${getTranslated('delete', context)}',
                onTap: () {
                  showDialog(context: context, builder: (ctx)  => const CustomLoaderWidget());
                  Provider.of<RestockController>(context, listen: false).deleteRestockProduct(null, 'all', null);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                })))]))

      ]),
    );
  }
}
