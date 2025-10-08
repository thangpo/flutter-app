import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/image_diaglog_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/support/domain/models/support_reply_model.dart';
import 'package:flutter_sixvalley_ecommerce/localization/controllers/localization_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

class SupportTicketReplyWidget extends StatelessWidget {
  final bool isMe;
  final String dateTime;
  final String? message;
  final SupportReplyModel replyModel;
  const SupportTicketReplyWidget({super.key, required this.isMe, required this.dateTime, this.message, required this.replyModel});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end:CrossAxisAlignment.start, children: [
      Container(margin: isMe ?  const EdgeInsets.fromLTRB(50, 5, 10, 5) : const EdgeInsets.fromLTRB(10, 5, 50, 5),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(10),
              bottomLeft: isMe ? const Radius.circular(10) : const Radius.circular(0),
              bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(10),
              topRight: const Radius.circular(10)),
              color: isMe ? Theme.of(context).primaryColor.withValues(alpha:.1) : Theme.of(context).highlightColor),
          child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, children: [
                Text(dateTime, style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor,)),


                message != null ?
                Text(message??'', style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color)) :
                const SizedBox.shrink()])),


      if(replyModel.attachmentFullUrl != null && replyModel.attachmentFullUrl!.isNotEmpty)
        const SizedBox(height: Dimensions.paddingSizeSmall),
      (replyModel.attachmentFullUrl != null && replyModel.attachmentFullUrl!.isNotEmpty)?
      Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
        child: Directionality(textDirection:Provider.of<LocalizationController>(context, listen: false).isLtr ? isMe ?
        TextDirection.rtl : TextDirection.ltr : isMe ? TextDirection.ltr : TextDirection.rtl,
          child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              childAspectRatio: 1, crossAxisCount: 3,
              mainAxisSpacing: Dimensions.paddingSizeSmall, crossAxisSpacing: Dimensions.paddingSizeSmall),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: replyModel.attachmentFullUrl?.length,
            itemBuilder: (BuildContext context, attachmentIndex) {


            return  InkWell(onTap: () => showDialog(context: context, builder: (ctx)  =>  ImageDialog(
                imageUrl: '${replyModel.attachmentFullUrl?[attachmentIndex].path}')),
              child: ClipRRect(borderRadius: BorderRadius.circular(5),
                  child:CustomImageWidget(height: 100, width: 100, fit: BoxFit.cover,
                      image: '${replyModel.attachmentFullUrl?[attachmentIndex].path}')),);

            },),
        ),
      ):
      const SizedBox.shrink(),
    ],
    );
  }
}
