import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_asset_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/controllers/chat_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';

class CustomImagePickBottomSheet extends StatelessWidget {
  final ChatController chatController;
   const CustomImagePickBottomSheet(this.chatController, {super.key});

  @override
  Widget build(BuildContext context) {
    double widthSize = MediaQuery.sizeOf(context).width;
    ThemeController themeProvider = Provider.of<ThemeController>(context, listen: false);
    return Container(
      width: widthSize,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(Dimensions.paddingSizeExtraLarge), topRight: Radius.circular(Dimensions.paddingSizeExtraLarge)),
        color: themeProvider.darkTheme ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).cardColor,
      ),
      child: Center(
        child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.spaceAround, children: [

          InkWell(
            onTap: () {
              chatController.pickMultipleMedia(false);
              Navigator.pop(context);
            },
            child: Column(mainAxisSize: MainAxisSize.min, children: [

                const CustomAssetImageWidget(Images.fromGallery, width: 70, height: 70,),
              const SizedBox(height: Dimensions.paddingSizeSmall,),

                Text(getTranslated('from_gallery', context)!, style: titilliumRegular,),

              ]),
          ),
          const SizedBox(width: Dimensions.paddingSizeOverLarge,),

          InkWell(
            onTap: () {
              chatController.pickMultipleMedia(false, openCamera: true);
              Navigator.pop(context);
            },
            child: Column(mainAxisSize: MainAxisSize.min, children: [

                const CustomAssetImageWidget(Images.openCamera, width: 70, height: 70,),
                const SizedBox(height: Dimensions.paddingSizeSmall,),

                Text(getTranslated('open_camera', context)!, style: titilliumRegular,),

              ]),
          ),
        ]),
      ),
    );
  }
}

