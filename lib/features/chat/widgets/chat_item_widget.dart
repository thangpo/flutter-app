
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/domain/models/chat_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/date_converter.dart';
import 'package:flutter_sixvalley_ecommerce/helper/shop_helper.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/controllers/chat_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/screens/chat_screen.dart';
import 'package:provider/provider.dart';

class ChatItemWidget extends StatefulWidget {
  final Chat? chat;
  final ChatController chatProvider;
  final Function callBack;
  const ChatItemWidget({super.key, this.chat, required this.chatProvider, required this.callBack});

  @override
  State<ChatItemWidget> createState() => _ChatItemWidgetState();
}

class _ChatItemWidgetState extends State<ChatItemWidget> {

  String? baseUrl = '', image = '', call = '', name = '';
  int? id;
  bool vacationIsOn = false;


  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    final SplashController splashController = Provider.of<SplashController>(context, listen: false);


    image = widget.chatProvider.userTypeIndex != 0 ?
    widget.chat!.sellerInfo != null ? widget.chat?.sellerInfo?.shops![0].imageFullUrl?.path : '' : widget.chat?.deliveryMan?.imageFullUrl?.path ?? '';

    call = widget.chatProvider.userTypeIndex != 0 ?
    '' : '${widget.chat!.deliveryMan?.code}${widget.chat!.deliveryMan?.phone}';

    id = widget.chatProvider.userTypeIndex != 0 ?
    widget.chat?.sellerId??widget.chat?.adminId : widget.chat!.deliveryManId;
    if(widget.chatProvider.userTypeIndex != 0){
      if(widget.chat!.sellerInfo != null && widget.chat?.adminId == null){
        name = widget.chat!.sellerInfo!.shops![0].name ?? '';
      }else if(widget.chat?.adminId == 0){
        name = splashController.configModel?.inHouseShop?.name;
      }else{
        name = 'Shop not found';
      }
    }else{
      name = "${widget.chat!.deliveryMan?.fName??''} ${widget.chat!.deliveryMan?.lName??''}";
    }

    if(widget.chatProvider.userTypeIndex != 0){
      if (widget.chat?.sellerInfo?.shops![0].vacationEndDate != null) {
        vacationIsOn = ShopHelper.isVacationActive(
          context,
          startDate: DateTime.parse(widget.chat!.sellerInfo!.shops![0].vacationStartDate!),
          endDate: DateTime.parse(widget.chat!.sellerInfo!.shops![0].vacationEndDate!),
          vacationDurationType: widget.chat!.sellerInfo!.shops![0].vacationDurationType,
          vacationStatus: widget.chat!.sellerInfo!.shops![0].vacationStatus,
          isInHouseSeller: false,
        );
      }

      if(widget.chat?.adminId == 0 && (splashController.configModel?.inhouseVacationAdd?.status ?? false)){
        final inHouseVacationAdd = Provider.of<SplashController>(Get.context!, listen: false).configModel?.inhouseVacationAdd;
        vacationIsOn = ShopHelper.isVacationActive(
          context,
          startDate: inHouseVacationAdd?.vacationStartDate,
          endDate: inHouseVacationAdd?.vacationEndDate,
          vacationDurationType: inHouseVacationAdd?.vacationDurationType,
          vacationStatus: inHouseVacationAdd?.status,
          isInHouseSeller: true,
        );
      }
    }



    return Consumer<ChatController>(
      builder: (context, chatController,_) {
        return InkWell(
          onTap: (){
            chatController.seenMessage( context, id,id,);
            if((name!.trim().isEmpty || name == 'Shop not found' || name!.trim()=='') && widget.chat?.adminId == null){
              showCustomSnackBar(getTranslated('user_account_was_deleted', context), context);
            }else{
              widget.callBack();
              Navigator.push(Get.context!, MaterialPageRoute(builder: (_) =>
                  ChatScreen(
                    id: id,
                    name: name,
                    image: (widget.chat?.adminId == 0 )
                        ? "${splashController.configModel?.inHouseShop?.imageFullUrl?.path}"
                        : '$image',
                    isDelivery: widget.chatProvider.userTypeIndex == 0,
                    phone: call,
                    isShopOnVacation: widget.chatProvider.userTypeIndex == 0 ? false : vacationIsOn,
                    isShopTemporaryClosed: widget.chatProvider.userTypeIndex == 0
                        ? false
                        : widget.chat?.adminId == 0
                        ? splashController.configModel?.inhouseTemporaryClose?.status ?? false
                        : widget.chat?.sellerInfo?.shops?[0].temporaryClose ?? false,
                  )));
            }
          },
          child: Container(decoration: BoxDecoration(
            color: (widget.chat!.unseenMessageCount != null && widget.chat!.unseenMessageCount! > 0) ?
            Theme.of(context).primaryColor.withValues(alpha:.05) : Theme.of(context).cardColor),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical : Dimensions.paddingSizeDefault, horizontal: Dimensions.paddingSizeDefault),
              child: Row(children: [

                Stack(children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha:.25),width: .5),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: CustomImageWidget(
                            image:(widget.chat?.adminId == 0) ? "${splashController.configModel?.inHouseShop?.imageFullUrl?.path}" :'$image',
                            height: 50,width: 50, fit: BoxFit.cover,
                        ),
                    ),
                  ),

                  if(isShopTemporaryClose(splashController))
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.black54.withValues(alpha:.65),
                        borderRadius: BorderRadius.circular(100),
                      ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                            child: Center(child: Text(getTranslated("temporary_closed", context) ?? '',
                              style: textMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
                              textAlign: TextAlign.center,
                            )),
                        ),
                    ),

                    if(!isShopTemporaryClose(splashController) && vacationIsOn)
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.black54.withValues(alpha:.65),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Center(child: Text(getTranslated("close", context) ?? '',
                            style: textMedium.copyWith(color: Colors.white),
                          )),
                        ),
                      ),
                ]),
                const SizedBox(width: Dimensions.paddingSizeDefault),

                Expanded(child: Column(children: [

                  Row(children: [
                    (widget.chat?.adminId == 0) ?
                    Expanded(child: Text("${splashController.configModel?.inHouseShop?.name}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color),
                    )) :
                    Expanded(child: Text(name??'', maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color),
                    )),
                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    Text(DateConverter.compareDates(widget.chat?.createdAt ?? ''), style: titilliumRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).hintColor,
                    )),

                  ]),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  Row(children: [
                    Expanded(child: Text(widget.chat!.message?? getTranslated('sent_attachment', context)!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color),
                    )),

                    if(widget.chat!.unseenMessageCount != null && widget.chat!.unseenMessageCount! > 0)
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                    if(widget.chat!.unseenMessageCount != null && widget.chat!.unseenMessageCount! > 0)
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text('${widget.chat!.unseenMessageCount}', style: textRegular.copyWith(
                          color: Colors.white, fontSize: Dimensions.fontSizeSmall,
                        )),
                      ),
                  ]),

                ])),
              ]),
            ),
          ),
        );
      }
    );
  }

  bool isShopTemporaryClose(SplashController splashController) => widget.chat?.sellerInfo?.shops?[0].temporaryClose ?? false || ((widget.chat?.adminId == 0) && (splashController.configModel?.inhouseTemporaryClose?.status ?? false));
}
