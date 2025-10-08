import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/exception/api_error_handler.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/data/services/data_sync_service.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/repositories/seller_product_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/common/enums/data_source_enum.dart';

class SellerProductRepository extends DataSyncService implements SellerProductRepositoryInterface {
  final DioClient dioClient;
  SellerProductRepository({required this.dioClient, required super.dataSyncRepoInterface});

  @override
  Future<ApiResponseModel> getSellerProductList(
      String sellerId, String offset, String productId,
      {String search = '',
        String? categoryIds = "[]",
        String? brandIds = "[]",
        String? authorIds = '[]',
        String? publishingIds = '[]',
        String? productType,
      }) async {
    try {
      final response = await dioClient.get(
          '${AppConstants.sellerProductUri}$sellerId/products?guest_id=1&limit=10&offset=$offset&search=$search&category=$categoryIds&brand_ids=$brandIds&product_id=$productId&product_authors=$authorIds&publishing_houses=$publishingIds&product_type=$productType');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> getSellerWiseBestSellingProductList(String sellerId, String offset) async {
    try {
      final response = await dioClient.get(
          '${AppConstants.sellerWiseBestSellingProduct}$sellerId/seller-best-selling-products?guest_id=1&limit=10&offset=$offset');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel> getSellerWiseFeaturedProductList(String sellerId, String offset) async {
    try {
      final response = await dioClient.get('${AppConstants.sellerWiseBestSellingProduct}$sellerId/seller-featured-product?guest_id=1&limit=10&offset=$offset');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }


  @override
  Future<ApiResponseModel> getSellerWiseRecommendedProductList(String sellerId, String offset) async {
    try {
      final response = await dioClient.get(
          '${AppConstants.sellerWiseBestSellingProduct}$sellerId/seller-recommended-products?guest_id=1&limit=10&offset=$offset');
      return ApiResponseModel.withSuccess(response);
    } catch (e) {
      return ApiResponseModel.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponseModel<T>> getShopAgainFromRecentStore<T>({required DataSourceEnum source}) async {
    return await fetchData<T>(AppConstants.shopAgainFromRecentStore, source);
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
  Future get(String id) {
    // TODO: implement get
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
