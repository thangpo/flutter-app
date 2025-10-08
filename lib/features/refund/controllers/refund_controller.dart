import 'dart:io';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/controllers/order_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/refund/domain/models/refund_info_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/refund/domain/models/refund_result_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/refund/domain/services/refund_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';


class RefundController with ChangeNotifier {
  final RefundServiceInterface refundServiceInterface;
  RefundController({required this.refundServiceInterface});

  bool _isLoading = false;
  bool _isRefund = false;
  bool get isRefund => _isRefund;
  bool get isLoading => _isLoading;
  XFile? _imageFile;
  XFile? get imageFile => _imageFile;
  List <XFile?> refundImage = [];
  RefundInfoModel? _refundInfoModel;
  RefundInfoModel? get refundInfoModel => _refundInfoModel;
  RefundResultModel? _refundResultModel;
  RefundResultModel? get refundResultModel => _refundResultModel;


  int? _selectedOrderDetailsId;
  int? get getSelectedOrderDetailsId => _selectedOrderDetailsId;


  void pickRefundImage(bool isRemove) async {
    if (isRemove) {
      _imageFile = null;
      refundImage = [];
    } else {
      _imageFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 20);
      if (_imageFile != null && File(_imageFile!.path).existsSync()) {
        refundImage.add(_imageFile);
      }
    }
    notifyListeners();
  }

  void removeRefundImage(int index) {
    if (index >= 0 && index < refundImage.length) {
      refundImage.removeAt(index);
    }
    notifyListeners();
  }


  Future<http.StreamedResponse> refundRequest(String orderId, int orderDetailsId, double? amount, String refundReason) async {
    setSelectedOrderDetailsId(orderDetailsId);
    _isLoading = true;
    notifyListeners();
    http.StreamedResponse response = await refundServiceInterface.refundRequest(orderDetailsId, amount, refundReason,refundImage);
    if (response.statusCode == 200) {
      Navigator.pop(Get.context!);
      showCustomSnackBar(getTranslated('successfully_requested_for_refund', Get.context!), Get.context!, isError: false);
      getRefundReqInfo(orderDetailsId);
      Provider.of<OrderDetailsController>(Get.context!, listen: false).getOrderDetails(orderId.toString());
    }
    _imageFile = null;
    refundImage = [];
    _isLoading = false;
    notifyListeners();
    return response;
  }



  Future<ApiResponseModel> getRefundReqInfo(int? orderDetailId) async {
    setSelectedOrderDetailsId(orderDetailId);
    _isRefund = true;
    notifyListeners();

    ApiResponseModel apiResponse = await refundServiceInterface.getRefundInfo(orderDetailId);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _refundInfoModel = RefundInfoModel.fromJson(apiResponse.response!.data);
      _isRefund = false;
    } else if(apiResponse.response?.statusCode == 202) {
      _isRefund = false;
      showCustomSnackBar('${apiResponse.response!.data['message']}', Get.context!);
    }
    notifyListeners();
    return apiResponse;
  }



  Future<ApiResponseModel> getRefundResult(BuildContext context, int? orderDetailId) async {
    _isLoading =true;
    ApiResponseModel apiResponse = await refundServiceInterface.getRefundResult(orderDetailId);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _isLoading = false;
      _refundResultModel = RefundResultModel.fromJson(apiResponse.response!.data);
    }
    notifyListeners();
    return apiResponse;
  }


  void setSelectedOrderDetailsId(int? orderDetailsId) {
    _selectedOrderDetailsId = orderDetailsId;
  }


  void removeRefundDetails() {
    _refundResultModel = null;
    notifyListeners();
  }

}
