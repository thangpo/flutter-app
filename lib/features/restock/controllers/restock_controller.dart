import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/restock/domain/services/restock_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/screens/cart_screen.dart';
import '../domain/models/restock_product_model.dart';


class RestockController with ChangeNotifier {
  final RestockServiceInterface restockServiceInterface;
  RestockController({required this.restockServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isBottomSheetOpen = false;
  bool get isBottomSheetOpen => _isBottomSheetOpen;

  final bool _isDeleteLoading = false;
  bool get isDeleteLoading => _isDeleteLoading;

  RestockProductModel? restockProductModel;

  Future<ApiResponseModel> reorder({String? orderId}) async {
    _isLoading =true;
    ApiResponseModel apiResponse = await restockServiceInterface.reorder(orderId!);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      showCustomSnackBar(apiResponse.response?.data['message'], Get.context!, isError: false);
      Navigator.push(Get.context!, MaterialPageRoute(builder: (_) => const CartScreen()));
    }
    notifyListeners();
    return apiResponse;
  }


  Future<void> getRestockProductList(int offset,{bool getAll = false}) async {
    _isLoading = true;
    ApiResponseModel apiResponse = await restockServiceInterface.getRestockProductList(offset.toString(), getAll);

    if (apiResponse.response != null  && apiResponse.response!.statusCode == 200) {
      _isLoading = false;
      if(offset == 1) {
        restockProductModel = RestockProductModel.fromJson(apiResponse.response?.data);
        if(getAll && restockProductModel!.data!.isNotEmpty) {
          subscribeTopic(restockProductModel?.data ?? []);
        }
      } else {
        restockProductModel!.data!.addAll(RestockProductModel.fromJson(apiResponse.response?.data).data!);
        restockProductModel!.offset = RestockProductModel.fromJson(apiResponse.response?.data).offset;
        restockProductModel!.totalSize = RestockProductModel.fromJson(apiResponse.response?.data).totalSize;
      }
    _isLoading = false;
    notifyListeners();
  }}


  void subscribeTopic (List<Data> data) async {
    for (Data item in data) {
      await  FirebaseMessaging.instance.subscribeToTopic(item.fcmTopic!);
    }
  }


  Future<void> deleteRestockProduct(String? id, String? type, int? index) async {
    _isLoading = true;
    ApiResponseModel apiResponse = await restockServiceInterface.deleteRestockProduct(type, id);

    if (apiResponse.response != null  && apiResponse.response!.statusCode == 200) {
      if(index != null){
        restockProductModel!.data!.removeAt(index);
        restockProductModel!.totalSize = (restockProductModel!.totalSize! - 1);
      } else if (type == 'all'){
        restockProductModel!.data = [];
        restockProductModel!.totalSize = 0;
      }
      _isLoading = false;
      notifyListeners();
    }}


  void emptyReStockData() {
    restockProductModel = null;
    notifyListeners();
  }


  void setBottomSheetOpen(bool value) {
    _isBottomSheetOpen = value;
    notifyListeners();
  }


}
