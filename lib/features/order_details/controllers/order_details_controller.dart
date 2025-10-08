import 'dart:io';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/domain/models/order_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/domain/models/order_details_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/domain/services/order_details_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/review/controllers/review_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:open_file_manager/open_file_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;




class OrderDetailsController with ChangeNotifier {
  final OrderDetailsServiceInterface orderDetailsServiceInterface;
  OrderDetailsController({required this.orderDetailsServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isDownloaodLoading = false;
  bool get isDownloaodLoading => _isDownloaodLoading;
  int _downloaodIndex = -1;
  int get downloaodIndex => _downloaodIndex;

  XFile? _imageFile;
  XFile? get imageFile => _imageFile;
  List <XFile?>_refundImage = [];
  List<XFile?> get refundImage => _refundImage;
  List<File> reviewImages = [];
  bool _isInvoiceLoading = false;
  bool get isInvoiceLoading => _isInvoiceLoading;



  bool _onlyDigital = true;
  bool get onlyDigital => _onlyDigital;

  void digitalOnly(bool value, {bool isUpdate = false}){
    _onlyDigital = value;
    if(isUpdate){
      notifyListeners();
    }
  }



  List<OrderDetailsModel>? _orderDetails;
  List<OrderDetailsModel>? get orderDetails => _orderDetails;

  Future <ApiResponseModel> getOrderDetails(String orderID) async {
    _orderDetails = null;
    ApiResponseModel apiResponse = await orderDetailsServiceInterface.getOrderDetails(orderID);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _orderDetails = null;
      _orderDetails = [];
      apiResponse.response!.data.forEach((order) {
        OrderDetailsModel orderDetailsModel = OrderDetailsModel.fromJson(order);
        _orderDetails!.add(orderDetailsModel);
      });
    }
    notifyListeners();
    return apiResponse;
  }

  void emptyOrderDetails() {
    _orderDetails = null;
    orders = null;
    notifyListeners();
  }



  Future <ApiResponseModel> getOrderInvoice(String orderID, context) async {
    _isInvoiceLoading = true;
    notifyListeners();
    ApiResponseModel apiResponse = await orderDetailsServiceInterface.getOrderInvoice(orderID);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      await requestPermissions();
      final downloadsDirectory = Directory('/storage/emulated/0/Download');
      List<int> intList = List<int>.from(apiResponse.response!.data);

      String fileName = '$orderID.pdf';
      var filePath = path.join(downloadsDirectory.path, '$orderID.pdf');

      int fileCounter = 1;

      while (await File(filePath).exists()) {
        fileName = '$orderID($fileCounter).pdf';
        filePath = path.join(downloadsDirectory.path, fileName);
        fileCounter++;
      }

      final file = File(filePath);
      await file.writeAsBytes(intList);
      await OpenFile.open(filePath);
      showCustomSnackBar(getTranslated('invoice_downloaded_successfully', context), context, isError: false);
    } else {
      showCustomSnackBar(getTranslated('invoice_download_failed', context), context);
    }
    _isInvoiceLoading = false;
    notifyListeners();
    return apiResponse;
  }




  Orders? orders;
  Future <void> getOrderFromOrderId(String orderID) async {
    ApiResponseModel apiResponse = await orderDetailsServiceInterface.getOrderFromOrderId(orderID);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      orders = Orders.fromJson(apiResponse.response!.data);
    }
    notifyListeners();
  }



  void pickImage(bool isRemove, {bool fromReview = false}) async {
    if(isRemove) {
      _imageFile = null;
      _refundImage = [];
      reviewImages = [];
    }else {
      _imageFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 20);
      if (_imageFile != null) {
        if(fromReview){
          reviewImages.add(File(_imageFile!.path));
        }else{
          _refundImage.add(_imageFile);
        }
      }
    }
    notifyListeners();
  }


  void removeImage(int index, {bool fromReview = false}){
    if(fromReview){
      reviewImages.removeAt(index);
    }else{
      _refundImage.removeAt(index);
    }

    notifyListeners();
  }



  void downloadFile(String url, String dir) async {
    await FlutterDownloader.enqueue(
      url: url,
      savedDir: dir,
      showNotification: true,
      saveInPublicStorage: true,
      openFileFromNotification: true,
    );
  }



  bool searching = false;
  Future<ApiResponseModel> trackOrder({String? orderId, String? phoneNumber, bool isUpdate = true}) async {
    searching = true;
    if(isUpdate) {
      notifyListeners();
    }

    ApiResponseModel apiResponse = await orderDetailsServiceInterface.trackOrder(orderId!, phoneNumber!);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      searching = false;
      _orderDetails = [];
      apiResponse.response!.data.forEach((order) => _orderDetails!.add(OrderDetailsModel.fromJson(order)));
    } else {
      searching = false;
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }

  Future<ApiResponseModel> downloadDigitalProduct({int? orderDetailsId}) async {
    ApiResponseModel apiResponse = await orderDetailsServiceInterface.downloadDigitalProduct(orderDetailsId!);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      Provider.of<AuthController>(Get.context!, listen: false).resendTime = (apiResponse.response!.data["time_count_in_second"]);
    } else {
      _isLoading = false;
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }


  Future<ApiResponseModel> resentDigitalProductOtp({int? orderId}) async {
    ApiResponseModel apiResponse = await orderDetailsServiceInterface.resentDigitalProductOtp(orderId!);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {

    } else {
      _isLoading = false;
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }

  Future<ApiResponseModel> verifyDigitalProductOtp({required int orderId, required String otp}) async {
    ApiResponseModel apiResponse = await orderDetailsServiceInterface.verifyDigitalProductOtp(orderId, otp);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      Navigator.of(Get.context!).pop();
      _launchUrl(Uri.parse('${AppConstants.baseUrl}${AppConstants.otpVerificationForDigitalProduct}?order_details_id=$orderId&otp=$otp&guest_id=1&action=download'));

    } else {
      _isLoading = false;
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }


  void productDownload({required String url, required String fileName, required int index, bool isIos = false}) async {
    _isDownloaodLoading = true;
    _downloaodIndex = index;
    notifyListeners();

    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    var selectedFolderType = FolderType.download;
    final subFolderPathCtrl = TextEditingController();


    List<String> fileTypes = [ '.txt', '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.mp3', '.wav', '.ogg', '.m4a', '.aac',
      '.mp4', '.avi', '.mkv', '.webm', '.3gp', '.pdf', '.doc'];


    if(isIos){
     HttpClientResponse apiResponse = await orderDetailsServiceInterface.productDownload(url);
     if (apiResponse.statusCode == 200) {

       List<int> downloadData = [];
       Directory downloadDirectory;

       if (Platform.isIOS) {
         downloadDirectory = await getApplicationDocumentsDirectory();
       } else {
         downloadDirectory = Directory('/storage/emulated/0/Download');
         if (!await downloadDirectory.exists()) downloadDirectory = (await getExternalStorageDirectory())!;
       }

       String filePathName = "${downloadDirectory.path}/$fileName";
       File savedFile = File(filePathName);
       bool fileExists = await savedFile.exists();

       if (fileExists) {
         ScaffoldMessenger.of(Get.context!).showSnackBar(const SnackBar(content: Text("File already downloaded")));
       } else {
         apiResponse.listen((d) => downloadData.addAll(d), onDone: () {
           savedFile.writeAsBytes(downloadData);
         });
         showCustomSnackBar(getTranslated('product_downloaded_successfully', Get.context!), Get.context!, isError: false);
       }
       _isDownloaodLoading = false;
       await OpenFile.open(filePathName);
       Navigator.of(Get.context!).pop();

     } else {
       _isDownloaodLoading = false;
       showCustomSnackBar(getTranslated('product_download_failed', Get.context!), Get.context!);
       Navigator.of(Get.context!).pop();
     }
   } else {
     String? task;
     Directory downloadDirectory = Directory('/storage/emulated/0/Download');
     String filePathName = "${downloadDirectory.path}/$fileName";
     File savedFile = File(filePathName);
     bool fileExists = await savedFile.exists();


     if(fileExists) {
       showCustomSnackBar(getTranslated('file_already_downloaded', Get.context!), Get.context!);
     } else{
       task  = await FlutterDownloader.enqueue(
         url: url,
         savedDir: downloadDirectory.path,
         fileName: fileName,
         showNotification: true,
         saveInPublicStorage: true,
         openFileFromNotification: true,
       );

       if(task != null) {
         showCustomSnackBar(getTranslated('product_downloaded_successfully', Get.context!), Get.context!, isError: false);

         if(!fileTypes.contains(getFileExtension(fileName))){
           await openFileManager(
             androidConfig: AndroidConfig(
               folderType: selectedFolderType,
             ),
             iosConfig: IosConfig(
               subFolderPath: subFolderPathCtrl.text.trim(),
             ),
           );
         }
       } else{
         showCustomSnackBar(getTranslated('product_download_failed', Get.context!), Get.context!);
       }
     }
     _isDownloaodLoading = false;
   }


    notifyListeners();
  }

  String getFileExtension(String fileName) {
    if (fileName.contains('.')) {
      return '.${fileName.split('.').last}';
    }
    return '';
  }

  Future<void> setOrderReviewExpanded(int index, bool status) async {

    if(status){
      final reviewController = Provider.of<ReviewController>(Get.context!, listen: false);
      reviewController.orderWiseReview = null;
    }

    if(_orderDetails != null){
      for(int i = 0; i< _orderDetails!.length;  i++){
        if(i == index){
          _orderDetails![i].isExpanded = status;
        } else{
          _orderDetails![i].isExpanded = false;
        }
      }
    }
    notifyListeners();
  }

  Future<void> requestPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }
}


Future<void> _launchUrl(Uri url) async {
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw 'Could not launch $url';
  }
}