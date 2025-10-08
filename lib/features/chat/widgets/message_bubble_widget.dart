import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/domain/models/message_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/controllers/chat_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/screens/media_viewer_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/controllers/localization_controller.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class MessageBubbleWidget extends StatelessWidget {
  final Message message;
  final Message? previous;
  final Message? next;
  const MessageBubbleWidget({super.key, required this.message, this.previous, this.next});

  @override
  Widget build(BuildContext context) {


    return Consumer<ChatController>(
      builder: (context, chatProvider, child) {
        final bool isMe = message.sentByCustomer!;
        final bool isLTR = Provider.of<LocalizationController>(context, listen: false).isLtr;

        final List<Attachment> images = message.attachment?.where((a) => a.type == 'media').toList() ?? [];
        final List<Attachment> files = message.attachment?.where((a) => a.type == 'file').toList() ?? [];


        String? image = _getAvatarImage(userTypeIndex: chatProvider.userTypeIndex);

        final String chatTime = chatProvider.getChatTime(message.createdAt!, message.createdAt);
        final bool isSameUserWithPreviousMessage = chatProvider.isSameUserWithPreviousMessage(previous, message);
        final bool isSameUserWithNextMessage = chatProvider.isSameUserWithNextMessage(message, next);
        final String previousMessageHasChatTime = next != null ? chatProvider.getChatTime(next!.createdAt!, message.createdAt) : "";

        return Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (_isUserAvatarActive(isMe, isSameUserWithPreviousMessage, chatProvider))
                  _UserAvatar(image: image),

                if (message.message?.isNotEmpty ?? false)
                  _MessageText(
                    message: message,
                    isMe: isMe,
                    isLTR: isLTR,
                    isSameUserWithNextMessage: isSameUserWithNextMessage,
                    isSameUserWithPreviousMessage: isSameUserWithPreviousMessage,
                    chatTime: chatTime,
                    previousMessageHasChatTime: previousMessageHasChatTime,
                    chatProvider: chatProvider,
                    isProfileAvatarActive: _isUserAvatarActive(isMe, isSameUserWithPreviousMessage, chatProvider),
                  ),
              ],
            ),

            _MessageTime(chatProvider: chatProvider, message: message),

            if (images.isNotEmpty) _MediaGridWidget(images: images, isMe: isMe),

            if (files.isNotEmpty) _FileGridWidget(files: files, isMe: isMe, isLTR: isLTR),
          ],
        );
      },
    );
  }

  String? _getAvatarImage({required int userTypeIndex}) {
    print(message.sentByAdmin);
    return userTypeIndex != 0 ?
        message.sentByAdmin == true ?
        (Provider.of<SplashController>(Get.context!, listen: false).configModel?.inHouseShop?.imageFullUrl?.path ?? "") :
        message.sellerInfo != null
        ? message.sellerInfo?.shops![0].imageFullUrl?.path
        : '' : message.deliveryMan?.imageFullUrl?.path;
  }

  bool _isUserAvatarActive(bool isMe, bool isSameUserWithPreviousMessage, ChatController chatProvider) =>
      !isMe && (!isSameUserWithPreviousMessage || chatProvider.getChatTimeWithPrevious(message, previous).isNotEmpty);
}

class _UserAvatar extends StatelessWidget {
  final String? image;

  const _UserAvatar({required this.image});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          border: Border.all(color: Theme.of(context).primaryColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          child: CustomImageWidget(
            fit: BoxFit.cover,
            width: Dimensions.paddingSizeExtraLarge + 5,
            height: Dimensions.paddingSizeExtraLarge + 5,
            image: image ?? '',
          ),
        ),
      ),
    );
  }
}

class _MessageText extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isLTR;
  final bool isSameUserWithNextMessage;
  final bool isSameUserWithPreviousMessage;
  final String chatTime;
  final String previousMessageHasChatTime;
  final ChatController chatProvider;
  final bool isProfileAvatarActive;

  const _MessageText({
    required this.message,
    required this.isMe,
    required this.isLTR,
    required this.isSameUserWithNextMessage,
    required this.isSameUserWithPreviousMessage,
    required this.chatTime,
    required this.previousMessageHasChatTime,
    required this.chatProvider,
    required this.isProfileAvatarActive,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkTheme = Provider.of<ThemeController>(context).darkTheme;

    return Flexible(child: InkWell(
      onTap: () => chatProvider.toggleOnClickMessage(onMessageTimeShowID: message.id.toString()),
      child: Container(
        margin: isMe && isLTR
            ? const EdgeInsets.fromLTRB(70, 5, 0, 5)
            : EdgeInsets.fromLTRB(isMe ? 0 : isProfileAvatarActive ? 10 : 40, 5, isLTR ? 70 : isProfileAvatarActive ? 10 : 40, 5),
        // margin: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeDefault),
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall,
          vertical: Dimensions.paddingSizeExtraSmall,
        ),
        decoration: BoxDecoration(
          borderRadius: _getBorderRadius(),
          color: isMe ? isDarkTheme
              ? Theme.of(context).cardColor
              : Theme.of(context).primaryColor
              : Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.35),
        ),
        child: Text(
          message.message!,
          textAlign: TextAlign.justify,
          style: textRegular.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: isMe ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    ));
  }

  BorderRadius _getBorderRadius() {
    const double defaultRadius = 25;

    if (isMe && (isSameUserWithNextMessage || isSameUserWithPreviousMessage)) {
      return BorderRadius.only(
        topRight: Radius.circular(isSameUserWithNextMessage && isLTR && chatTime.isEmpty ? Dimensions.radiusSmall : defaultRadius),
        bottomRight: Radius.circular(isSameUserWithPreviousMessage && isLTR && previousMessageHasChatTime.isEmpty ? Dimensions.radiusSmall : defaultRadius),
        topLeft: Radius.circular(isSameUserWithNextMessage && !isLTR && chatTime.isEmpty ? Dimensions.radiusSmall : defaultRadius),
        bottomLeft: Radius.circular(isSameUserWithPreviousMessage && !isLTR && previousMessageHasChatTime.isEmpty ? Dimensions.radiusSmall : defaultRadius),
      );

    } else if (!isMe && (isSameUserWithNextMessage || isSameUserWithPreviousMessage)) {
      return BorderRadius.only(
        topLeft: Radius.circular(isSameUserWithNextMessage && isLTR && chatTime.isEmpty ? Dimensions.radiusSmall : defaultRadius),
        bottomLeft: Radius.circular(isSameUserWithPreviousMessage && isLTR && previousMessageHasChatTime.isEmpty ? Dimensions.radiusSmall : defaultRadius),
        topRight: Radius.circular(isSameUserWithNextMessage && !isLTR && chatTime.isEmpty ? Dimensions.radiusSmall : defaultRadius),
        bottomRight: Radius.circular(isSameUserWithPreviousMessage && !isLTR && previousMessageHasChatTime.isEmpty ? Dimensions.radiusSmall : defaultRadius),
      );

    } else {
      return BorderRadius.circular(defaultRadius);
    }
  }
}

class _MessageTime extends StatelessWidget {
  final ChatController chatProvider;
  final Message message;

  const _MessageTime({required this.chatProvider, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: AnimatedContainer(
        curve: Curves.fastOutSlowIn,
        duration: const Duration(milliseconds: 500),
        height: chatProvider.onMessageTimeShowID == message.id.toString() ? 25.0 : 0.0,
        child: Padding(
          padding: EdgeInsets.only(
            top: chatProvider.onMessageTimeShowID == message.id.toString() ? Dimensions.paddingSizeExtraSmall : 0.0,
          ),
          child: Text(
            chatProvider.getOnPressChatTime(message) ?? "",
            style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
          ),
        ),
      ),
    );
  }
}

class _FileGridWidget extends StatelessWidget {
  final List<Attachment> files;
  final bool isMe;
  final bool isLTR;

  const _FileGridWidget({required this.files, required this.isMe, required this.isLTR});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Directionality(
          textDirection: isMe && isLTR ? TextDirection.rtl : !isLTR && !isMe ? TextDirection.rtl : TextDirection.ltr,
          child: Padding(
            padding: EdgeInsets.only(left: (!isMe && isLTR) ? 30 : 0, right: (!isMe && !isLTR) ? 30 : 0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: files.length,
              padding: files.isNotEmpty ? const EdgeInsets.only(top: Dimensions.paddingSizeSmall) : EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                mainAxisExtent: 60,
                crossAxisCount: 2,
                mainAxisSpacing: Dimensions.paddingSizeExtraSmall,
                crossAxisSpacing: Dimensions.paddingSizeExtraSmall,
              ),
              itemBuilder: (context, index) => _FileItem(file: files[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _FileItem extends StatelessWidget {
  final Attachment file;

  const _FileItem({required this.file});

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Provider.of<ChatController>(context, listen: false);

    return InkWell(
      onTap: () async {
        final status = await Permission.notification.request();
        if (kDebugMode) {
          print("Status is $status");
        }
        if (status.isGranted) {
          Directory? directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = Platform.isAndroid
                ? await getExternalStorageDirectory() // FOR ANDROID
                : await getApplicationSupportDirectory();
          }
          chatController.downloadFile(file.path!, directory!.path, "${directory.path}/${file.key}", "${file.key}");

        } else if (status.isDenied || status.isPermanentlyDenied) {
          await openAppSettings();
        }
      },
      child: Container(
        width: 180, height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).hintColor.withValues(alpha:0.2),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Directionality(textDirection: TextDirection.ltr, child: Row(
            children: [
              const Image(image: AssetImage(Images.fileIcon), height: 30, width: 30),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),

              Expanded(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.key.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                  ),
                  Text(
                    "${file.size}",
                    style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor),
                  ),
                ],
              )),
              const _DownloadButtonWidget(),
            ],
          )),
        ),
      ),
    );
  }
}

class _MediaGridWidget extends StatefulWidget {
  final List<Attachment> images;
  final bool isMe;

  const _MediaGridWidget({required this.images, required this.isMe});

  @override
  State<_MediaGridWidget> createState() => _MediaGridWidgetState();
}

class _MediaGridWidgetState extends State<_MediaGridWidget> {
  List<String>? _videoThumbnails;
  final Map<String, String?> _thumbnailCache = {};

  @override
  void initState() {
    super.initState();
    _generateThumbnails();
  }

  @override
  void didUpdateWidget(covariant _MediaGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images != widget.images) {
      _generateThumbnails();
    }
  }

  Future<void> _generateThumbnails() async {
    final ChatController chatController = Provider.of<ChatController>(context, listen: false);
    final List<String> thumbnails = [];

    for (Attachment image in widget.images) {
      if (chatController.isVideoExtension(image.path ?? '')) {
        if (_thumbnailCache.containsKey(image.path)) {
          thumbnails.add(_thumbnailCache[image.path] ?? '');
        } else {
          final thumbnail = await chatController.generateThumbnail(image.path ?? '');
          _thumbnailCache[image.path ?? ''] = thumbnail;
          thumbnails.add(thumbnail ?? '');
        }
      } else {
        thumbnails.add('');
      }
    }

    setState(() {
      _videoThumbnails = thumbnails;
    });
  }

  bool _isShowMoreMedia(List<Attachment> images, int index, bool isMe) {
    return images.length > 4 && index == (isMe ? 2 : 3);
  }

  @override
  Widget build(BuildContext context) {
    final bool isLtr = Provider.of<LocalizationController>(context, listen: false).isLtr;
    final ChatController chatController = Provider.of<ChatController>(context, listen: false);

    if (widget.images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: Dimensions.paddingSizeExtraSmall,
        top: 0,
        left: (!widget.isMe && isLtr) ? 40 : 0,
        right: (!widget.isMe && !isLtr) ? 40 : 0,
      ),
      child: Directionality(
        textDirection: isLtr ? (widget.isMe ? TextDirection.rtl : TextDirection.ltr) : (widget.isMe ? TextDirection.ltr : TextDirection.rtl),
        child: SizedBox(
          width: MediaQuery.of(context).size.width / 2,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              childAspectRatio: 1,
              crossAxisCount: 2,
              mainAxisSpacing: Dimensions.paddingSizeSmall,
              crossAxisSpacing: Dimensions.paddingSizeSmall,
            ),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: min(widget.images.length, 4),
            itemBuilder: (BuildContext context, index) {
              return Stack(
                children: [
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MediaViewerScreen(clickedIndex: index, serverMedia: widget.images),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      child: Stack(
                        children: [
                          if (chatController.isVideoExtension(widget.images[index].path ?? '') && (_videoThumbnails?.isNotEmpty ?? false))
                            Image.file(
                              File(_videoThumbnails?[index] ?? ''),
                              fit: BoxFit.cover,
                              height: 200,
                              width: 200,
                              errorBuilder: (_, __, ___) => const CustomImageWidget(
                                height: 200,
                                width: 200,
                                fit: BoxFit.cover,
                                image: '',
                              ),
                            )
                          else
                            CustomImageWidget(
                              height: 200,
                              width: 200,
                              fit: BoxFit.cover,
                              image: '${widget.images[index].path}',
                            ),
                          if (chatController.isVideoExtension(widget.images[index].path ?? ''))
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.center,
                                child: Container(
                                  padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.play_arrow,
                                    color: Theme.of(context).primaryColor,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_isShowMoreMedia(widget.images, index, widget.isMe))
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MediaViewerScreen(clickedIndex: index, serverMedia: widget.images),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Container(
                              width: MediaQuery.of(context).size.width / 4.2,
                              height: MediaQuery.of(context).size.width / 4.2,
                              decoration: BoxDecoration(
                                color: Colors.black54.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                    "+${widget.images.length - 3}",
                                    style: textRegular.copyWith(color: Colors.white)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DownloadButtonWidget extends StatelessWidget {
  const _DownloadButtonWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
        child: Icon(Icons.file_download_outlined, color: Theme.of(context).primaryColor),
      ),
    );
  }
}
