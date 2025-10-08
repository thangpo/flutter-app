import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_asset_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/support/controllers/support_ticket_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/support/domain/models/support_ticket_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/support/screens/support_conversation_screen.dart';
import 'package:flutter_sixvalley_ecommerce/helper/date_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/shipping_details_widget.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

class SupportTicketWidget extends StatelessWidget {
  final SupportTicketModel supportTicketModel;
  final int index;
  const SupportTicketWidget({super.key, required this.supportTicketModel, required this.index});

  @override
  Widget build(BuildContext context) {
    return Consumer<SupportTicketController>(
      builder: (context, supportTicketController, _) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          if(_willShowDate(index, supportTicketController.supportTicketList)) ...[

              const SizedBox(height: Dimensions.paddingSizeDefault),

              Padding(
                padding: const EdgeInsets.only(
                  left: Dimensions.paddingSizeDefault,
                ),
                child: Text(
                  DateConverter.getRelativeDateStatus(supportTicketController.supportTicketList?[index].createdAt ?? '', context),
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

          Slidable(
            key: const ValueKey(0),
            endActionPane: ActionPane(extentRatio:supportTicketModel.status == 'close'? 0.01 : .25,
              motion: const ScrollMotion(),
              children: [
                if(supportTicketModel.status != 'close')
                  SlidableAction(
                    onPressed: (value){
                      Provider.of<SupportTicketController>(context, listen: false).closeSupportTicket(supportTicketModel.id);
                    },
                    backgroundColor: Theme.of(context).colorScheme.error.withValues(alpha:.05),
                    foregroundColor: Theme.of(context).colorScheme.error.withValues(alpha:.75),
                    icon: CupertinoIcons.clear,
                    label: getTranslated('close', context),
                  ),
              ],
            ),
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SupportConversationScreen(
                  supportTicketModel: supportTicketModel))),
              child: Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [

                    Row(children: [

                      SizedBox(width: 15, child: CustomAssetImageWidget(supportTicketModel.type?.toLowerCase() == 'website problem'? Images.websiteProblem :
                      supportTicketModel.type == 'Complaint'? Images.complaint : supportTicketModel.type == 'Partner request'?
                      Images.partnerRequest : Images.infoQuery)),
                      const SizedBox(width: Dimensions.paddingSizeSmall),

                      Expanded(child: Text(getTranslated(_toSnakeCase(supportTicketModel.type ?? ''), context) ?? supportTicketModel.type!, style: textBold.copyWith(
                          color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha:.70)))),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeSmall,
                          vertical: Dimensions.paddingSizeExtraExtraSmall,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                          color: supportTicketModel.status == 'open'
                              ? Theme.of(context).colorScheme.onTertiaryContainer.withValues(alpha:.125)
                              : supportTicketModel.status == 'pending'
                              ? Theme.of(context).colorScheme.outline.withValues(alpha:.125)
                              : Theme.of(context).colorScheme.error.withValues(alpha:.125),
                        ),
                        child: Text(
                          supportTicketModel.status == 'pending'
                              ? getTranslated('pending', context)!
                              : supportTicketModel.status == 'open'
                              ? getTranslated('open', context)!
                              : getTranslated('closed', context)!,
                          style: textMedium.copyWith(
                            color: supportTicketModel.status == 'open'
                                ? Theme.of(context).colorScheme.onTertiaryContainer
                                : supportTicketModel.status == 'pending'
                                ? Theme.of(context).colorScheme.outline
                                : Theme.of(context).colorScheme.error,
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                      ),

                    ]),

                    Padding(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeEight),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

                        _ContentLabel(labelText: '${getTranslated('sub', context)}'),
                        const SizedBox(width: Dimensions.paddingSizeEight),

                        Expanded(child: Text(supportTicketModel.subject!, style: textRegular, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: Dimensions.imageSizeExtraSeventy)

                      ]),
                    ),

                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

                      _ContentLabel(labelText: '${getTranslated('priority', context)}'),
                      const SizedBox(width: Dimensions.paddingSizeEight),

                      Expanded(child: Text(
                          getTranslated(_toSnakeCase(supportTicketModel.priority ?? ''), context) ?? supportTicketModel.priority!.capitalize(),

                        style: textBold.copyWith(
                        color: supportTicketModel.priority == 'High'
                            ? Colors.amber : supportTicketModel.priority == 'Urgent'
                            ? Theme.of(context).colorScheme.error
                            : (supportTicketModel.priority == 'Low' || supportTicketModel.priority == 'low')
                            ? Theme.of(context).primaryColor : Colors.greenAccent,
                      ))),

                      Text(
                        DateConverter.getLocalTimeWithAMPM(supportTicketModel.createdAt ?? ''),
                        style: textRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.70)
                        ),
                      ),

                    ]),
                  ],
                ),
              ),
            ),
          ),
        ]);
      }
    );
  }

  String _toSnakeCase(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }


  bool _willShowDate(int index, List<SupportTicketModel>? supportTicketList) {

    if (supportTicketList?.isEmpty ?? true) return false;
    if (index == 0) return true;


    final currentSupportTicket = supportTicketList?[index];
    final currentSupportTicketDate = DateTime.tryParse(currentSupportTicket?.createdAt ?? '');


    final previousSupportTicket = supportTicketList?[index - 1];
    final previousSupportTicketDate = DateTime.tryParse(previousSupportTicket?.createdAt ?? '');

    return currentSupportTicketDate?.day != previousSupportTicketDate?.day;
  }

}

class _ContentLabel extends StatelessWidget {
  final String labelText;
  final TextStyle? labelTextStyle;
  const _ContentLabel({
    required this.labelText,
    this.labelTextStyle
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [

      Text(labelText, style: labelTextStyle ?? textRegular.copyWith(
            fontWeight: FontWeight.w400,
            color: Theme.of(context).textTheme.bodyLarge?.color,
      ), overflow: TextOverflow.ellipsis),

      const Text(' : '),

    ]);
  }


  String toSnakeCase(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }

}
