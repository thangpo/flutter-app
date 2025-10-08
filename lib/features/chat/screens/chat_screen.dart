import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_asset_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/domain/models/message_body.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/domain/models/message_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/screens/media_viewer_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/widgets/custom_image_pick_bottom_sheet.dart';
import 'package:flutter_sixvalley_ecommerce/helper/date_converter.dart';
import 'package:flutter_sixvalley_ecommerce/helper/image_size_checker.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/controllers/chat_controller.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_textfield_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/paginated_list_view_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/widgets/chat_shimmer_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/widgets/message_bubble_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' as foundation;

class ChatScreen extends StatefulWidget {
  final int? id;
  final String? name;
  final bool isDelivery;
  final String? image;
  final String? phone;
  final bool isShopOnVacation;
  final bool isShopTemporaryClosed;
  final int? userType;
  const ChatScreen({
    super.key,
    this.id,
    required this.name,
    this.isDelivery = false,
    this.image,
    this.phone,
    this.userType,
    this.isShopOnVacation = false,
    this.isShopTemporaryClosed = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  ScrollController scrollController = ScrollController();
  bool emojiPicker = false;

  bool isClosed = false;
  void clickedOnClose(){
    setState(() {
      isClosed = true;
    });
  }


  @override
  void initState() {
    loadDaa();
    super.initState();
  }

  Future<void> loadDaa() async{
   await Provider.of<ChatController>(context, listen: false).getMessageList( context, widget.id, 1, userType: widget.userType);
  }


  bool _isMediaExist (ChatController chatController){
    return (chatController.pickedMediaStored?.isNotEmpty ?? false) || (chatController.pickedFiles?.isNotEmpty ?? false);
  }

  bool _isMsgValid(ChatController chatController){
    bool isImageMsgValid = (chatController.pickedMediaStored?.isNotEmpty ?? false) && !chatController.pickedFIleCrossMaxLength;
    bool isFileMsgValid = (chatController.pickedFiles?.isNotEmpty ?? false) && !chatController.pickedFIleCrossMaxLength;
    bool isTextMsgValid = _controller.text.isNotEmpty && !chatController.pickedFIleCrossMaxLength;
    return (isImageMsgValid || isFileMsgValid  || isTextMsgValid) && !chatController.pickedFIleCrossMaxLimit && !chatController.isLoading;
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(backgroundColor: Theme.of(context).cardColor,
        titleSpacing: 0,
        elevation: 1,
        leading: InkWell(onTap: ()=> Navigator.pop(context),
            child: Icon(CupertinoIcons.back, color: Theme.of(context).textTheme.bodyLarge?.color)),
        title: Row(children: [

          ClipRRect(borderRadius: BorderRadius.circular(100),
            child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(100),
                    border: Border.all(width: .5, color: Theme.of(context).primaryColor.withValues(alpha:.125))),
                height: 40, width: 40,child: CustomImageWidget(image: widget.image??''))),


          Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
            child: Text(widget.name??'', style: textRegular.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color)))]),
        actions: widget.isDelivery? [InkWell(
          onTap: ()=> _launchUrl("tel:${widget.phone}"),
          child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Container(decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha:.125),
                borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)),
                height: 35, width: 35,child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                  child: Image.asset(Images.callIcon, color: Theme.of(context).primaryColor)))),
        )]:[]),

      body: Stack(
        children: [
          Consumer<ChatController>(builder: (context, chatController, child) => Column(children: [
            chatController.messageModel != null? (chatController.messageModel!.message != null && chatController.messageModel!.message!.isNotEmpty)?
            Expanded(child:  SingleChildScrollView(
              controller: scrollController,
              reverse: true,
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                child: PaginatedListView(
                  reverse: true,
                  scrollController: scrollController,
                  onPaginate: (int? offset) => chatController.getMessageList(context,widget.id, offset ?? 1, reload: false),
                  totalSize: chatController.messageModel?.totalSize,
                  offset: chatController.messageModel?.offset,
                  limit: chatController.messageModel?.limit,
                  // enabledPagination: chatController.messageModel == null,
                  itemView: ListView.builder(
                    itemCount: chatController.messageModel?.message?.length,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    reverse: true,
                    itemBuilder: (context, index) {
                      return  Column(
                        crossAxisAlignment: chatController.messageModel?.message?[index].sentByCustomer ?? false
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          if(_willShowDate(index, chatController.messageModel) != null)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeExtraSmall,
                                  vertical: Dimensions.paddingSizeSmall,
                                ),
                                // DateConverter.customTime(DateTime.parse(chat!.createdAt!))
                                child: Text(
                                  DateConverter.dateStringMonthYear(DateTime.tryParse(chatController.messageModel!.message![index].createdAt!)),
                                  style: textMedium.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha:0.5),
                                  ),
                                  textDirection: TextDirection.ltr,
                                ),
                              ),
                            ),


                          MessageBubbleWidget(
                            message: chatController.messageModel!.message![index],
                            previous: (index != 0) ? chatController.messageModel!.message![index -1 ] : null,
                            next: index == (chatController.messageModel!.message!.length -1) ?  null : chatController.messageModel!.message![index + 1],
                          ),

                        ],);
                    },
                  ),
                ),
              ),
            )) : const Expanded(child: NoInternetOrDataScreenWidget(isNoInternet: false)):
            const Expanded(child: ChatShimmerWidget()),



            chatController.isSending ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
                  child: AnimatedContainer(
                    curve: Curves.fastOutSlowIn,
                    duration: const Duration(milliseconds: 500),
                    height: chatController.isSending ? 25.0 : 0.0,
                    child: Text(getTranslated('sending', context)!, style: textRegular.copyWith(color: Theme.of(context).primaryColor.withValues(alpha:.75)),),
                  ),
                ),
              ],
            ) : const SizedBox(),



            Container(
              color:  (chatController.isLoading == false && _isMediaExist(chatController)) ?
              Theme.of(context).primaryColor.withValues(alpha:0.1) : null,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                _isMediaExist(chatController) ? const SizedBox(height: Dimensions.paddingSizeSmall) : const SizedBox(),

                (chatController.pickedMediaStored?.isNotEmpty ?? false) ?
                Container(
                    height: (chatController.pickedFIleCrossMaxLimit || chatController.pickedFIleCrossMaxLength || chatController.singleFIleCrossMaxLimit) ? 110 : 90,
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.zero,
                            itemBuilder: (context,index){

                              if (kDebugMode) {
                                print('--------path: ${chatController.pickedMediaStored?[index].thumbnailPath}');
                              }

                              return  Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Stack(children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 5),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        height: 80,
                                        width: chatController.pickedMediaStored?[index].isVideo ?? false ? 120 : 80,
                                        child: chatController.pickedMediaStored?[index].isSvg ?? false
                                            ? SvgPicture.file(File(chatController.pickedMediaStored![index].thumbnailPath ?? ''), fit: BoxFit.cover)
                                            : Image.file(File(chatController.pickedMediaStored![index].thumbnailPath ?? ''), fit: BoxFit.cover),
                                      ),
                                    ),
                                  ),


                                  if(chatController.pickedMediaStored?[index].isVideo ?? false)
                                    Positioned.fill(
                                      child: Align(alignment: Alignment.center, child: InkWell(
                                        onTap: () => Navigator.push(context, MaterialPageRoute(
                                          builder: (_) => MediaViewerScreen(
                                            clickedIndex: index,
                                            localMedia: chatController.getXFileFromMediaFileModel(chatController.pickedMediaStored ?? []),
                                          ),
                                        )),
                                        child: Container(
                                          padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.play_arrow, color: Theme.of(context).primaryColor, size: 30),
                                        ),
                                      )),
                                    ),


                                  Positioned(right: 0, child: InkWell(
                                    onTap: () => chatController.pickMultipleMedia(true,index: index),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).hintColor,
                                        shape: BoxShape.circle,
                                      ),
                                      transform: Matrix4.translationValues(0, -6, 0),
                                      child: CustomAssetImageWidget(
                                        Images.cancel, height: 20, width: 20,
                                        color: Theme.of(context).cardColor,
                                      ),
                                    ),
                                  )),

                                ]),
                              );

                            },
                            itemCount: chatController.pickedMediaStored!.length,
                          ),
                        ),

                        if(chatController.pickedFIleCrossMaxLimit || chatController.pickedFIleCrossMaxLength || chatController.singleFIleCrossMaxLimit)
                          Text( "${chatController.pickedFIleCrossMaxLength ? "• ${getTranslated('can_not_select_more_than', context)!} ${AppConstants.maxLimitOfTotalFileSent.floor()} 'files' " :""} "
                              "${chatController.pickedFIleCrossMaxLimit ? "• ${getTranslated('total_images_size_can_not_be_more_than', context)!} ${AppConstants.maxLimitOfFileSentINConversation.floor()} MB" : ""} "
                              "${chatController.singleFIleCrossMaxLimit ? "• ${getTranslated('single_file_size_can_not_be_more_than', context)!} ${AppConstants.maxSizeOfASingleFile.floor()} MB" : ""} ",
                            style: textRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).colorScheme.error.withValues(alpha:0.7),
                            ),
                          )
                      ],

                    )
                ) : const SizedBox(),

                ((chatController.pickedFiles?.isNotEmpty ?? false) && chatController.isLoading == false) ?
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 70,
                        child: ListView.separated(
                          shrinkWrap: true, scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(bottom: 5),
                          separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeDefault),
                          itemCount: chatController.pickedFiles?.length ?? 0,
                          itemBuilder: (context, index){
                            String fileSize =  ImageSize.getFileSizeFromPlatformFileToString(chatController.pickedFiles![index]);
                            return Container(width: 180,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                              ),
                              padding: const EdgeInsets.only(left: 10, right: 5),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.center,children: [

                                Image.asset(Images.fileIcon,height: 30, width: 30,),
                                const SizedBox(width: Dimensions.paddingSizeExtraSmall,),

                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,mainAxisAlignment: MainAxisAlignment.center, children: [

                                  Text(chatController.pickedFiles![index].name,
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: textBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                                  ),

                                  Text(fileSize, style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault,
                                    color: Theme.of(context).hintColor,
                                  )),
                                ])),


                                InkWell(
                                  onTap: () {
                                    chatController.pickOtherFile(true, index: index);
                                  },
                                  child: Padding(padding: const EdgeInsets.only(top: 5),
                                    child: Align(alignment: Alignment.topRight,
                                      child: Icon(Icons.close,
                                        size: Dimensions.paddingSizeLarge,
                                        color: Theme.of(context).hintColor,
                                      ),
                                    ),
                                  ),
                                )
                              ]),
                            );
                          },
                        ),
                      ),


                      if(chatController.pickedFIleCrossMaxLimit || chatController.pickedFIleCrossMaxLength || chatController.singleFIleCrossMaxLimit)
                        Text( "${chatController.pickedFIleCrossMaxLength ? "• ${getTranslated('can_not_select_more_than', context)!} ${AppConstants.maxLimitOfTotalFileSent.floor()} 'files' " :""} "
                            "${chatController.pickedFIleCrossMaxLimit ? "• ${getTranslated('total_images_size_can_not_be_more_than', context)!} ${AppConstants.maxLimitOfFileSentINConversation.floor()} MB" : ""} "
                            "${chatController.singleFIleCrossMaxLimit ? "• ${getTranslated('single_file_size_can_not_be_more_than', context)!} ${AppConstants.maxSizeOfASingleFile.floor()} MB" : ""} ",
                          style: textRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).colorScheme.error.withValues(alpha:0.7),
                          ),
                        ),
                    ],
                  ),
                ) : const SizedBox(),


                Padding(
                  padding: const EdgeInsets.fromLTRB( Dimensions.paddingSizeDefault,  0, Dimensions.paddingSizeSmall,  Dimensions.paddingSizeDefault),
                  child: Opacity(
                    opacity: ((chatController.isSending || chatController.isLoading) || widget.isShopTemporaryClosed) ? 0.5 : 1,
                    child: AbsorbPointer(
                      absorbing: ((chatController.isSending || chatController.isLoading) || widget.isShopTemporaryClosed),
                      child: SizedBox(height: 60, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Expanded(child: CustomTextFieldWidget(
                          inputAction: TextInputAction.send,
                          //showLabelText: false,
                          prefixIcon: Images.emoji,
                          prefixColor: Theme.of(context).colorScheme.onSecondary.withValues(alpha:0.50),
                          suffixIcon: Images.attachment,
                          suffixIcon2: Images.file,
                          suffixColor: Theme.of(context).primaryColor,
                          isPassword: false,
                          onTap: (){
                            setState(() {
                              emojiPicker = false;
                            });
                          },
                          prefixOnTap: (){
                            setState(() {
                              emojiPicker = !emojiPicker;
                              FocusManager.instance.primaryFocus?.unfocus();
                            });
                          },
                          suffixOnTap: () => showModalBottomSheet(context: context, builder: (context) => CustomImagePickBottomSheet(chatController)),
                          suffix2OnTap: (){
                            chatController.pickOtherFile(false);
                          },
                          controller: _controller,
                          labelText: getTranslated('send_a_message', context),
                          hintText: getTranslated('send_a_message', context),
                        )),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                      
                      
                        InkWell(
                          onTap: (chatController.isSending && chatController.isLoading) ? null : (){
                            if(!_isMsgValid(chatController)){
                              chatController.pickedFIleCrossMaxLength ? showCustomSnackBar(getTranslated('can_not_select_more_than_5_files', context), context) : showCustomSnackBar(getTranslated('write_somethings', context), context);
                            } else{
                              MessageBody messageBody = MessageBody(id : widget.id,  message: _controller.text);
                              chatController.sendMessage(messageBody, userType: widget.userType).then((value){
                                _controller.clear();
                              });
                            }
                          },
                          child: Opacity(opacity: (chatController.isSending || chatController.isLoading) ? 0.2 : 1, child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Container(
                              width: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                                border: Border.all(width: 1, color: Theme.of(context).hintColor.withValues(alpha: 0.7)),
                              ),
                              child: Center(child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  Dimensions.paddingSizeExtraExtraSmall,
                                  Dimensions.paddingSizeExtraExtraSmall,
                                  Dimensions.paddingSizeExtraExtraSmall,
                                  8,
                                ),
                                child: Image.asset(Images.send, color: Provider.of<ThemeController>(context).darkTheme ? Colors.white: null),
                              )),
                            ),
                          )),
                        ),
                      
                      ])),
                    ),
                  ),
                ),
              ]),
            ),



            if(emojiPicker)
              SizedBox(height: 250,
                child: EmojiPicker(
                  onBackspacePressed: () {},
                  textEditingController: _controller,
                  config: Config(
                    height: 256,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: EmojiViewConfig(
                      // Issue: https://github.com/flutter/flutter/issues/28894
                      emojiSizeMax: 28 *
                          (foundation.defaultTargetPlatform ==
                              TargetPlatform.iOS
                              ? 1.2
                              : 1.0),
                    ),
                    // swapCategoryAndBottomBar: false,
                    skinToneConfig: const SkinToneConfig(),
                    categoryViewConfig: const CategoryViewConfig(),
                    bottomActionBarConfig: const BottomActionBarConfig(),
                    searchViewConfig: const SearchViewConfig(),
                  ),
                ),
              ),
          ])),

          if(widget.isShopOnVacation && !isClosed && !widget.isShopTemporaryClosed)
            Container(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
              decoration: const BoxDecoration(color: Color(0xFFFEF7D1)),
              child: Row(children: [
                Expanded(child: Text("${getTranslated("shop_close_message", context)}",
                  style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color))),
                const SizedBox(width: Dimensions.paddingSizeSmall,),
                InkWell(onTap: ()=> clickedOnClose(),
                  child: Icon(Icons.cancel, size: 35, color: Theme.of(context).hintColor, ))
              ],
            ),),

          if(!isClosed && widget.isShopTemporaryClosed)
            Container(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
              decoration: const BoxDecoration(color: Color(0xFFFEF7D1)),
              child: Row(children: [
                Expanded(child: Text("${getTranslated("shop_available_message", context)}",
                    style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color))),
                const SizedBox(width: Dimensions.paddingSizeSmall,),
                InkWell(onTap: ()=> clickedOnClose(),
                    child: Icon(Icons.cancel, size: 35, color: Theme.of(context).hintColor, ))
              ],
              ),),

        ],
      ),
    );
  }

  String? _willShowDate(int index, MessageModel? messageModel) {

    if(messageModel?.message == null) return null;

    final Message currentMessage = messageModel!.message![index];
    final nextMessage = index < ((messageModel.message?.length ?? 0) - 1) ? messageModel.message![index + 1] : null;

    DateTime? currentMessageDate = currentMessage.createdAt == null ? null : DateTime.tryParse(currentMessage.createdAt!);
    DateTime? nextMessageDate = nextMessage?.createdAt == null ? null : DateTime.tryParse(nextMessage!.createdAt!);
    bool isFirst = index == ((messageModel.message?.length ?? 0) - 1);

    if (isFirst || (nextMessageDate?.day != currentMessageDate?.day)) {
      return DateConverter.dateStringMonthYear(currentMessageDate);
    }
    return null;
  }

}



Future<void> _launchUrl(String url) async {
  if (!await launchUrl(Uri.parse(url))) {
    throw 'Could not launch $url';
  }
}

