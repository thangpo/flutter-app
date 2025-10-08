import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/domain/models/media_file_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/domain/models/message_body.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/domain/models/chat_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/domain/models/message_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/domain/services/chat_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/helper/date_converter.dart';
import 'package:flutter_sixvalley_ecommerce/helper/image_size_checker.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

enum SenderType {
  customer,
  seller,
  admin,
  deliveryMan,
  unknown
}

class ChatController extends ChangeNotifier {
  final ChatServiceInterface? chatServiceInterface;
  ChatController({required this.chatServiceInterface});

  File? _imageFile;
  File? get imageFile => _imageFile;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  int _userTypeIndex = 0;
  int get userTypeIndex => _userTypeIndex;

  ChatModel? chatModel;
  ChatModel? deliverymanChatModel;

  ChatModel? searchChatModel;
  ChatModel? searchDeliverymanChatModel;

  bool sellerChatCall= false;
  bool deliveryChatCall= false;

  bool _isActiveSuffixIcon = false;
  bool get isActiveSuffixIcon => _isActiveSuffixIcon;

  bool _isSearchComplete = false;
  bool get isSearchComplete => _isSearchComplete;

  bool _pickedFIleCrossMaxLimit = false;
  bool get pickedFIleCrossMaxLimit => _pickedFIleCrossMaxLimit;

  bool _pickedFIleCrossMaxLength = false;
  bool get pickedFIleCrossMaxLength => _pickedFIleCrossMaxLength;

  bool _singleFIleCrossMaxLimit = false;
  bool get singleFIleCrossMaxLimit => _singleFIleCrossMaxLimit;

  List<PlatformFile>? pickedFiles;

  String _onImageOrFileTimeShowID = '';
  String get onImageOrFileTimeShowID => _onImageOrFileTimeShowID;

  bool _isClickedOnImageOrFile = false;
  bool get isClickedOnImageOrFile => _isClickedOnImageOrFile;

  bool _isClickedOnMessage = false;
  bool get isClickedOnMessage => _isClickedOnMessage;

  String _onMessageTimeShowID = '';
  String get onMessageTimeShowID => _onMessageTimeShowID;

  bool _isSending = false;
  bool get isSending => _isSending;




  Future<void> getChatList( int offset, {bool reload = true, int? userType}) async {
    if(reload){
      notifyListeners();
    }

    if(offset == 1){
      if(offset == 1 && userType == 0){
        deliverymanChatModel = null;
      }else if (offset == 1 && userType == 1) {
        chatModel = null;
      }
      if(userType == null){
        notifyListeners();
      }
    }

    ApiResponseModel apiResponse = await chatServiceInterface!.getChatList(userType!= null ? userType  == 0 ? 'delivery-man' : 'seller' : _userTypeIndex == 0 ? 'delivery-man' : 'seller', offset);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      if(offset == 1){
        if(userType == 0) {
          deliverymanChatModel = null;
          deliverymanChatModel = ChatModel.fromJson(apiResponse.response!.data);
        }else {
          chatModel = null;
          chatModel = ChatModel.fromJson(apiResponse.response!.data);
        }
      }else{
        if(userType == 0) {
          deliverymanChatModel?.chat?.addAll(ChatModel.fromJson(apiResponse.response!.data).chat!);
          deliverymanChatModel?.offset  = (ChatModel.fromJson(apiResponse.response!.data).offset!);
          deliverymanChatModel?.totalSize  = (ChatModel.fromJson(apiResponse.response!.data).totalSize!);
        } else {
          chatModel?.chat?.addAll(ChatModel.fromJson(apiResponse.response!.data).chat!);
          chatModel?.offset  = (ChatModel.fromJson(apiResponse.response!.data).offset!);
          chatModel?.totalSize  = (ChatModel.fromJson(apiResponse.response!.data).totalSize!);
        }
      }
    } else {
      ApiChecker.checkApi( apiResponse);
    }
    // if(userType == null){
      notifyListeners();
    // }
  }

  Future<void> searchChat(BuildContext context, String search, int userIndex) async {
    _isLoading = true;
    searchChatModel = null;
    searchDeliverymanChatModel = null;

    notifyListeners();
    ApiResponseModel apiResponse = await chatServiceInterface!.searchChat(userIndex == 0? 'seller' : 'delivery-man', search);
    if (apiResponse.response != null && apiResponse.response?.statusCode == 200 && apiResponse.response is !List) {
      if(userIndex == 0) {
        searchChatModel = null;
        searchChatModel = ChatModel(totalSize: 1, limit: '10', offset: '1', chat: []);

        apiResponse.response!.data.forEach((chat) => searchChatModel!.chat!.add(Chat.fromJson(chat)));
        searchChatModel?.chat = searchChatModel!.chat;
      } else {
        searchDeliverymanChatModel = null;
        searchDeliverymanChatModel = ChatModel(totalSize: 1, limit: '10', offset: '1', chat: []);

        apiResponse.response!.data.forEach((chat) => searchDeliverymanChatModel!.chat!.add(Chat.fromJson(chat)));
        searchDeliverymanChatModel?.chat = searchDeliverymanChatModel!.chat;
      }
    } else {
      _isLoading = false;
      ApiChecker.checkApi( apiResponse);
    }

    _isLoading = false;
    _isSearchComplete = true;

    notifyListeners();
  }


  MessageModel? messageModel;

  Future<void> getMessageList(BuildContext context, int? id, int offset, {bool reload = true, int? userType}) async {
    if(reload){
      messageModel = null;
    }
    _isLoading = true;
    ApiResponseModel apiResponse = await chatServiceInterface!.getMessageList(userType != null ? userType == 0 ? 'delivery-man' : 'seller' : _userTypeIndex == 0? 'delivery-man' : 'seller', id, offset);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {

      final model = MessageModel.fromJson(apiResponse.response?.data);

      if(offset == 1){
        messageModel = model;

      } else{

        messageModel?.totalSize =  model.totalSize;
        messageModel?.offset =  model.offset;
        messageModel?.limit =  model.limit;
        messageModel?.message?.addAll(model.message ?? []) ;

      }
    } else {
      _isLoading = false;
      ApiChecker.checkApi( apiResponse);
    }
    _isLoading = false;
    notifyListeners();
  }



  Future<http.StreamedResponse> sendMessage(MessageBody messageBody,{int? userType}) async {
    _isSending = true;
    notifyListeners();

    http.StreamedResponse response = await chatServiceInterface!.sendMessage(messageBody, userType != null ? userType == 0 ? 'delivery-man' : 'seller' : _userTypeIndex == 0? 'delivery-man' : 'seller', getXFileFromMediaFileModel(pickedMediaStored ?? []) ?? [], pickedFiles ?? []);

    if (response.statusCode == 200) {
      getMessageList(Get.context!, messageBody.id, 1, reload: false, userType: userType);
      getChatList(1, userType: userType);
      _pickedImageFiles = [];
      pickedMediaStored = [];
    }

    _pickedImageFiles = [];
    pickedMediaStored = [];
    pickedFiles = [];

    _isSending = false;

    notifyListeners();
    return response;
  }


  Future<ApiResponseModel> seenMessage(BuildContext context, int? sellerId, int? deliveryId) async {
    ApiResponseModel apiResponse = await chatServiceInterface!.seenMessage(_userTypeIndex == 0? sellerId!: deliveryId!, _userTypeIndex == 0? 'delivery-man' : 'seller');
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      // await getChatList(1);
    } else {
      ApiChecker.checkApi(apiResponse);
    }

    notifyListeners();
    return apiResponse;
  }


  void setUserTypeIndex(BuildContext context, int index, {bool searchActive = false, bool isUpdate = true}) {
    _userTypeIndex = index;
    if(!searchActive){
      // getChatList(1);
    }

    if(isUpdate){
      notifyListeners();
    }
  }

  List <PlatformFile> _pickedImageFiles =[];
  List <PlatformFile>? get pickedImageFile => _pickedImageFiles;
  List <MediaFileModel>?  pickedMediaStored = [];

  void pickMultipleMedia(bool isRemove,{int? index, bool openCamera = false}) async {
    _pickedFIleCrossMaxLimit = false;
    _pickedFIleCrossMaxLength = false;

    if(isRemove) {
      if(index != null){
        pickedMediaStored?.removeAt(index);
      }
    } else if(openCamera){
      final XFile? pickedImage = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 400);

      if(pickedImage != null) {
        pickedMediaStored?.add(MediaFileModel(file: pickedImage, thumbnailPath: pickedImage.path, isVideo: false));

      }
    } else {

      FilePickerResult? filePickerResult =  await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowCompression: true,
        allowedExtensions: [
          ...AppConstants.imageExtensions,
          ...AppConstants.videoExtensions,
        ],
        compressionQuality: 40,
      );

      _pickedImageFiles = filePickerResult?.files ?? [];

      for (PlatformFile file in _pickedImageFiles) {
        if (isVideoExtension(file.path ?? '')) {
          final thumbnailPath = await generateThumbnail(file.path ?? '');
          if (thumbnailPath != null) {

            pickedMediaStored?.add(MediaFileModel(file: file.xFile, thumbnailPath: thumbnailPath, isVideo: true));
          }
        } else {
          pickedMediaStored?.add(MediaFileModel(
            file: file.xFile,
            thumbnailPath: file.path,
            isVideo: false,
            isSvg: file.extension == 'svg',
          ));
        }
      }
    }

    _pickedFIleCrossMaxLength = _isMediaCrossMaxLen();
    _pickedFIleCrossMaxLimit =  await _isCrossMediaMaxLimit();

    notifyListeners();
  }

  Future<bool> _isCrossMediaMaxLimit() async =>
      _pickedImageFiles.length == AppConstants.maxLimitOfTotalFileSent
          && await ImageSize.getMultipleImageSizeFromXFile(getXFileFromMediaFileModel(pickedMediaStored ?? []) ?? []) > AppConstants.maxLimitOfFileSentINConversation;

  bool _isMediaCrossMaxLen() => pickedMediaStored!.length > AppConstants.maxLimitOfTotalFileSent;



  List<XFile>? getXFileFromMediaFileModel(List<MediaFileModel> mediaFileModel) {
    return mediaFileModel
        .map((model) => model.file)
        .whereType<XFile>() // Filters out any null values
        .toList();
  }

  bool isVideoExtension(String path) {
    final fileExtension = path.split('.').last.toLowerCase();

    const videoExtensions = [
      'mp4', 'mkv', 'avi', 'mov', 'flv', 'wmv', 'webm', 'mpeg', 'mpg', '3gp', 'ogv'
    ];
    return videoExtensions.contains(fileExtension);
  }
  Future<String?> generateThumbnail(String filePath) async {
    final directory = await getTemporaryDirectory();

    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: filePath, // Replace with your video URL
      thumbnailPath: directory.path,
      imageFormat: ImageFormat.PNG,
      maxHeight: 100,
      maxWidth: 200,
      quality: 1,
    );

    return thumbnailPath.path;
  }



  void showSuffixIcon(BuildContext context,String text){
    if(text.isNotEmpty){
      _isActiveSuffixIcon = true;
    }else if(text.isEmpty){
      _isActiveSuffixIcon = false;
      _isSearchComplete = false;
    }
    notifyListeners();
  }


  bool isSameUserWithPreviousMessage(Message? previousConversation, Message currentConversation){
    if(getSenderType(previousConversation) == getSenderType(currentConversation) && previousConversation?.message != null && currentConversation.message !=null){
      return true;
    }
    return false;
  }
  bool isSameUserWithNextMessage( Message currentConversation, Message? nextConversation){
    if(getSenderType(currentConversation) == getSenderType(nextConversation) && nextConversation?.message != null && currentConversation.message !=null){
      return true;
    }
    return false;
  }


  SenderType getSenderType(Message? senderData) {
    if (senderData?.sentByCustomer ?? false) {
      return SenderType.customer;
    } else if (senderData?.sentBySeller ?? false) {
      return SenderType.seller;
    } else if (senderData?.sentByAdmin ?? false) {
      return SenderType.admin;
    } else if (senderData?.sentByDeliveryman ?? false) {
      return SenderType.deliveryMan;
    } else {
      return SenderType.unknown;
    }
  }



  String getChatTime (String todayChatTimeInUtc , String? nextChatTimeInUtc) {
    String chatTime = '';
    DateTime todayConversationDateTime = DateConverter.isoUtcStringToLocalTimeOnly(todayChatTimeInUtc);
    DateTime nextConversationDateTime;
    DateTime currentDate = DateTime.now();

    if(nextChatTimeInUtc == null){
      String chatTime = DateConverter.isoStringToLocalDateAndTime(todayChatTimeInUtc);
      return chatTime;
    }else{
      nextConversationDateTime = DateConverter.isoUtcStringToLocalTimeOnly(nextChatTimeInUtc);


      if(todayConversationDateTime.difference(nextConversationDateTime) < const Duration(minutes: 30) &&
          todayConversationDateTime.weekday == nextConversationDateTime.weekday){
        chatTime = '';
      }else if(currentDate.weekday != todayConversationDateTime.weekday
          && DateConverter.countDays(todayConversationDateTime) < 6){

        if( (currentDate.weekday -1 == 0 ? 7 : currentDate.weekday -1) == todayConversationDateTime.weekday){
          chatTime = DateConverter.convert24HourTimeTo12HourTimeWithDay(todayConversationDateTime, false);
        }else{
          chatTime = DateConverter.convertStringTimeToDate(todayConversationDateTime);
        }

      }else if(currentDate.weekday == todayConversationDateTime.weekday
          && DateConverter.countDays(todayConversationDateTime) < 6){
        chatTime = DateConverter.convert24HourTimeTo12HourTimeWithDay(todayConversationDateTime, true);
      }else{
        chatTime = DateConverter.isoStringToLocalDateAndTimeConversation(todayChatTimeInUtc);
      }
    }
    return chatTime;
  }

  Future<void> pickOtherFile(bool isRemove, {int? index}) async {
    _pickedFIleCrossMaxLimit = false;
    _pickedFIleCrossMaxLength = false;
    _singleFIleCrossMaxLimit = false;

    List<String> allowedFileExtensions = [
      'doc', 'docx', 'txt', 'csv', 'xls', 'xlsx', 'rar', 'tar', 'targz', 'zip', 'pdf',
    ];

    if(isRemove){
      if(pickedFiles!=null){
        pickedFiles!.removeAt(index!);
      }
    }else{
      List<PlatformFile>? platformFile = (await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedFileExtensions,
        allowMultiple: true,
        withReadStream: true,
      ))?.files ;

      pickedFiles = [];

      pickedFiles = platformFile;

    }

    _pickedFIleCrossMaxLimit = _isCrossedMaxFileLimit(pickedFiles);
    _pickedFIleCrossMaxLength = _isCrossedMaxFileLen(pickedFiles);
    notifyListeners();
  }

  bool _isCrossedMaxFileLimit(List<PlatformFile>? platformFile) =>
      pickedFiles?.length == AppConstants.maxLimitOfTotalFileSent
          && platformFile != null
          && ImageSize.getMultipleFileSizeFromPlatformFiles(platformFile) > AppConstants.maxLimitOfFileSentINConversation;

  bool _isCrossedMaxFileLen(List<PlatformFile>? platformFile) => platformFile!.length > AppConstants.maxLimitOfTotalFileSent ;

  void downloadFile(String url, String dir, String openFileUrl, String fileName) async {

    var snackBar = const SnackBar(content: Text('Downloading....'),backgroundColor: Colors.black54, duration: Duration(seconds: 1),);
    ScaffoldMessenger.of(Get.context!).showSnackBar(snackBar);

    final task  = await FlutterDownloader.enqueue(
      url: url,
      savedDir: dir,
      fileName: fileName,
      showNotification: true,
      saveInPublicStorage: true,
      openFileFromNotification: true,
    );

    if (kDebugMode) {
      print('-----task-----${task != null} || $openFileUrl');
    }

    if(task !=null){
      await OpenFile.open(openFileUrl);
    }
  }


  Future<void> multiDownload(List<String> urls, String zipFileName) async {
    var snackBar = const SnackBar(
      content: Text('Preparing download...'),
      backgroundColor: Colors.black54,
      duration: Duration(seconds: 1),
    );
    ScaffoldMessenger.of(Get.context!).showSnackBar(snackBar);

    try {
      // Temporary directory for storing files and zip
      final tempDir = await getTemporaryDirectory();
      final zipFilePath = '${tempDir.path}/$zipFileName';

      // Download each file to temp directory
      List<File> downloadedFiles = [];
      for (var i = 0; i < urls.length; i++) {
        final fileName = 'file_$i'; // Name files uniquely
        final filePath = '${tempDir.path}/$fileName';
        await FlutterDownloader.enqueue(
          url: urls[i],
          savedDir: tempDir.path,
          fileName: fileName,
          showNotification: false,
          saveInPublicStorage: false,
        );
        downloadedFiles.add(File(filePath));
      }

      // Create ZIP file
      final encoder = ZipFileEncoder();
      encoder.create(zipFilePath);
      for (var file in downloadedFiles) {
        encoder.addFile(file);
      }
      encoder.close();

      // Notify user about downloading ZIP
      snackBar = const SnackBar(
        content: Text('Downloading ZIP file...'),
        backgroundColor: Colors.black54,
        duration: Duration(seconds: 2),
      );
      ScaffoldMessenger.of(Get.context!).showSnackBar(snackBar);

      // Save ZIP file to specified location
      final dir = await getExternalStorageDirectory(); // Adjust as needed
      final zipSavedPath = '${dir!.path}/$zipFileName';
      final savedZipFile = await File(zipFilePath).copy(zipSavedPath);

      // Open the ZIP file
      await OpenFile.open(savedZipFile.path);
    } catch (e) {
      debugPrint('Error: $e');
      snackBar = const SnackBar(
        content: Text('Failed to download files'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      );
      ScaffoldMessenger.of(Get.context!).showSnackBar(snackBar);
    }
  }


  String getChatTimeWithPrevious (Message currentChat, Message? previousChat) {
    DateTime todayConversationDateTime = DateConverter
        .isoUtcStringToLocalTimeOnly(currentChat.createdAt ?? "");

    DateTime previousConversationDateTime;

    if (previousChat?.createdAt == null) {
      return 'Not-Same';
    } else {
      previousConversationDateTime =
          DateConverter.isoUtcStringToLocalTimeOnly(previousChat!.createdAt!);
      if (kDebugMode) {
        print("The Difference is ${previousConversationDateTime.difference(todayConversationDateTime) < const Duration(minutes: 30)}");
      }
      if (previousConversationDateTime.difference(todayConversationDateTime) <
          const Duration(minutes: 30) &&
          todayConversationDateTime.weekday ==
              previousConversationDateTime.weekday && isSameUserWithPreviousMessage(currentChat, previousChat)) {
        return '';
      } else {
        return 'Not-Same';
      }
    }

  }


  void toggleOnClickMessage ({required String onMessageTimeShowID}) {
    _onImageOrFileTimeShowID = '';
    _isClickedOnImageOrFile = false;
    if(_isClickedOnMessage && _onMessageTimeShowID != onMessageTimeShowID){
      _onMessageTimeShowID = onMessageTimeShowID;
    }else if(_isClickedOnMessage && _onMessageTimeShowID == onMessageTimeShowID){
      _isClickedOnMessage = false;
      _onMessageTimeShowID = '';
    }else{
      _isClickedOnMessage = true;
      _onMessageTimeShowID = onMessageTimeShowID;
    }
    notifyListeners();
  }


  String? getOnPressChatTime(Message currentConversation){
    if(currentConversation.id.toString() == _onMessageTimeShowID || currentConversation.id.toString() == _onImageOrFileTimeShowID){
      DateTime currentDate = DateTime.now();
      DateTime todayConversationDateTime = DateConverter.isoUtcStringToLocalTimeOnly(
          currentConversation.createdAt ?? ""
      );

      if(currentDate.weekday != todayConversationDateTime.weekday && DateConverter.countDays(todayConversationDateTime) <= 7){
        return DateConverter.convertStringTimeToDateChatting(todayConversationDateTime);

      }else if(currentDate.weekday == todayConversationDateTime.weekday && DateConverter.countDays(todayConversationDateTime) <= 7){
        return  DateConverter.convert24HourTimeTo12HourTime(todayConversationDateTime);

      }else{
        return DateConverter.isoStringToLocalDateAndTime(currentConversation.createdAt!);
      }
    }else{
      return null;
    }
  }


  void resetIsSearchComplete({bool isUpdate = true}){
    _isSearchComplete = false;

    if(isUpdate) {
      notifyListeners();
    }
  }

}

