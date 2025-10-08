
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/domain/models/address_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/domain/models/label_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/domain/repositories/address_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/domain/services/address_service_interface.dart';

 class AddressService implements AddressServiceInterface{
  final AddressRepoInterface addressRepoInterface;
  AddressService({required this.addressRepoInterface});


  List<AddressModel> _addressList = [];


  @override
  Future<List<AddressModel>> getList({bool fromRemove = false, bool isShipping = false, bool isBilling = false, bool all = false}) async {
    ApiResponseModel apiResponse = await addressRepoInterface.getList();
    _addressList = [];
    apiResponse.response?.data.forEach((address) {
      AddressModel addressModel = AddressModel.fromJson(address);
      _addressList.add(addressModel);
    });

    return _addressList;
  }




  @override
  Future<ApiResponseModel> add(AddressModel addressModel) async {
    ApiResponseModel apiResponse = await addressRepoInterface.add(addressModel);
    return apiResponse;
  }

  @override
  Future<ApiResponseModel> update(Map<String, dynamic> addressModel, int id) async {
    ApiResponseModel apiResponse = await addressRepoInterface.update(addressModel, id);
    return apiResponse;
  }

  @override
  Future<ApiResponseModel> delete(int id) async {
    ApiResponseModel response = await addressRepoInterface.delete(id);
    return response;
  }

  @override
  List<LabelAsModel> getAddressType() {
    return  addressRepoInterface.getAddressType();
  }

  @override
  Future getDeliveryRestrictedCountryBySearch(String country) async{
    ApiResponseModel response = await addressRepoInterface.getDeliveryRestrictedCountryBySearch(country);
    return response;
  }

  @override
  Future getDeliveryRestrictedCountryList() async{
    ApiResponseModel apiResponse = await addressRepoInterface.getDeliveryRestrictedCountryList();
    return apiResponse;
  }

  @override
  Future getDeliveryRestrictedZipBySearch(String zipcode) async {
    ApiResponseModel response = await addressRepoInterface.getDeliveryRestrictedZipBySearch(zipcode);
    return response;
  }

  @override
  Future getDeliveryRestrictedZipList() async {
    ApiResponseModel apiResponse = await addressRepoInterface.getDeliveryRestrictedZipList();
    return apiResponse;
  }
}