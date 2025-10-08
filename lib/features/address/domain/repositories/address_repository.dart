import 'package:dio/dio.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/exception/api_error_handler.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/domain/models/address_model.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/domain/models/label_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/domain/repositories/address_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';


class AddressRepository implements AddressRepoInterface<ApiResponseModel>{
  final DioClient? dioClient;
  AddressRepository({this.dioClient});


  @override
  Future<ApiResponseModel> getDeliveryRestrictedCountryList() async {
    try {
      final response = await dioClient!.get(AppConstants.deliveryRestrictedCountryList);
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> getDeliveryRestrictedZipList() async {
    try {
      final response = await dioClient!.get(AppConstants.deliveryRestrictedZipList);
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> getDeliveryRestrictedZipBySearch(String zipcode) async {
    try {
      final response = await dioClient!.get('${AppConstants.deliveryRestrictedZipList}?search=$zipcode');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> getDeliveryRestrictedCountryBySearch(String country) async {
    try {
      final response = await dioClient!.get('${AppConstants.deliveryRestrictedCountryList}?search=$country');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }


  @override
  Future<ApiResponseModel> getList({int? offset}) async {
    try {
      final response = await dioClient!.get('${AppConstants.addressListUri}?guest_id=${Provider.of<AuthController>(Get.context!, listen: false).getGuestToken()}');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> delete(int? id) async {
    try {
      final response = await dioClient!.post(
        '${AppConstants.removeAddressUri}?address_id=$id&guest_id=${Provider.of<AuthController>(Get.context!, listen: false).getGuestToken()}',
        data: {"_method" : 'delete'}
      );
      ApiResponseModel res = ApiResponseModel.withSuccess(response);
      return res;
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }


  @override
  Future<ApiResponseModel> add(AddressModel addressModel) async {
    try {
      Response response = await dioClient!.post(AppConstants.addAddressUri, data: addressModel.toJson());
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> update(Map<String, dynamic> addressModel, int addressId) async {
    try {
      Response response = await dioClient!.post(AppConstants.updateAddressUri, data: addressModel);
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }


  @override
  List<LabelAsModel> getAddressType() {
    List<LabelAsModel> labelAsList= [
      LabelAsModel('home', Images.homeImage),
      LabelAsModel('office', Images.officeImage),
      LabelAsModel('others', Images.address),
    ];
    return labelAsList;
  }




  @override
  Future get(String id) {
    // TODO: implement get
    throw UnimplementedError();
  }

}


