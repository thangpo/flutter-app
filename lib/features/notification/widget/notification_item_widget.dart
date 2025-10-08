import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/notification/domain/models/notification_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/date_converter.dart';
import 'package:flutter_sixvalley_ecommerce/features/notification/controllers/notification_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/notification/widget/notification_dialog_widget.dart';
import 'package:provider/provider.dart';

class NotificationItemWidget extends StatelessWidget {
  final NotificationItem notificationItem;
  final int index;
  const NotificationItemWidget({super.key, required this.notificationItem, required this.index});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationController>(
      builder: (context, notificationController, _) {
        return InkWell(
            onTap:(){
              notificationController.seenNotification(notificationItem.id!);
              showModalBottomSheet(
                  backgroundColor: Colors.transparent,
                  context: context, builder: (context) => NotificationDialogWidget(notificationModel: notificationItem),
              );
            },
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              if(_willShowDate(index, notificationController.notificationModel?.notification)) ...[

                const SizedBox(height: Dimensions.paddingSizeDefault),

                Padding(
                  padding: const EdgeInsets.only(
                      left: Dimensions.paddingSizeDefault,
                  ),
                  child: Text(
                    DateConverter.getRelativeDateStatus(notificationController.notificationModel?.notification?[index].createdAt ?? '', context),
                    style: textRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha:0.70),
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),

              ],

              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha:0.05),
                        spreadRadius: 0,
                        blurRadius: 7,
                        offset: const Offset(0, 1)
                    ),
                  ],
                ),
                child: Row(children: [

                  Stack(children: [
                    Container(
                      decoration: BoxDecoration(border: Border.all(
                          color: Colors.black.withValues(alpha: 0.05), width: 2),
                          shape: BoxShape.circle
                      ),
                      child: ClipRRect(borderRadius: BorderRadius.circular(100),
                        child: CustomImageWidget(width: 45, height: 45, image: '${notificationItem.imageFullUrl?.path}', fit: BoxFit.cover),
                      ),
                    ),

                    if(notificationItem.seen == null)
                      CircleAvatar(backgroundColor: Theme.of(context).colorScheme.error.withValues(alpha:.75), radius: 3),
                  ]),
                  const SizedBox(width: Dimensions.paddingSizeSmall),

                  Expanded(child: SizedBox(height: 45, child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: Text(
                          notificationItem.title ?? '',
                          style: textBold.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.60),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )),
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                        Text(DateConverter.getLocalTimeWithAMPM(notificationItem.createdAt ?? ''), style: textRegular.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: Theme.of(context).primaryColor,
                        )),
                      ]),

                      Text( notificationItem.description ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.50),
                        )
                      ),

                    ],
                  ))),
                ]),
              ),
            ]),
        );
      }
    );
  }

  bool _willShowDate(int index, List<NotificationItem>? notificationList) {

    if (notificationList?.isEmpty ?? true) return false;
    if (index == 0) return true;


    final currentSupportTicket = notificationList?[index];
    final currentSupportTicketDate = DateTime.tryParse(currentSupportTicket?.createdAt ?? '');


    final previousSupportTicket = notificationList?[index - 1];
    final previousSupportTicketDate = DateTime.tryParse(previousSupportTicket?.createdAt ?? '');

    return currentSupportTicketDate?.day != previousSupportTicketDate?.day;
  }
}