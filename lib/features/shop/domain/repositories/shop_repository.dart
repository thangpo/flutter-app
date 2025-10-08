import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/exception/api_error_handler.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/data/services/data_sync_service.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/repositories/shop_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/common/enums/data_source_enum.dart';

class ShopRepository extends DataSyncService implements ShopRepositoryInterface {
  final DioClient dioClient;
  ShopRepository({required this.dioClient, required super.dataSyncRepoInterface});

  @override
  Future<ApiResponseModel> get(String sellerId) async {
    try {
      final response = await dioClient.get("${AppConstants.sellerUri}$sellerId");
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel<T>> getMoreStore<T>({required DataSourceEnum source}) async {
    return await fetchData<T>(AppConstants.moreStore, source);
  }

  @override
  Future<ApiResponseModel<T>> getSellerList<T>({required String type, required int offset, required int limit, required DataSourceEnum source}) async {
    return await fetchData<T>('${AppConstants.sellerList}$type?limit=$limit&offset=$offset', source);
  }



  @override
  Future<ApiResponseModel> getClearanceShopProductList(String type, String offset, String sellerId) async {
    try {
      final response = await dioClient.get(
          '${AppConstants.clearanceShopProductUri}$sellerId/products?guest_id=1&limit=10&offset=$offset&offer_type=$type');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }


  @override
  Future<ApiResponseModel> getClearanceSearchProduct(String sellerId, String offset, String productId, {String search = '', String? categoryIds="[]", String? brandIds="[]", String? authorIds ='[]', String? publishingIds = '[]', String? productType, String? offerType}) async {
    try {
      final response = await dioClient.get(
          '${AppConstants.clearanceShopSearchProductUri}$sellerId/products?guest_id=1&limit=10&offset=$offset&search=$search&category=$categoryIds&brand_ids=$brandIds&product_id=$productId&product_authors=$authorIds&publishing_houses=$publishingIds&product_type=$productType&offer_type=$offerType');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future add(value) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future delete(int id) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset = 1}) {
    // TODO: implement getList
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int id) {
    // TODO: implement update
    throw UnimplementedError();
  }

}