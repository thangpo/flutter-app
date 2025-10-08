import 'package:flutter_sixvalley_ecommerce/common/enums/data_source_enum.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';

abstract class ShopServiceInterface {
  Future<ApiResponseModel<T>> getMoreStore<T>({required DataSourceEnum source});
  Future<ApiResponseModel<T>> getSellerList<T>({required String type, required int offset, required int limit, required DataSourceEnum source});
  Future<dynamic> getClearanceShopProductList(String type, String offset, String sellerId);
  Future<dynamic> get(String id);
  Future<dynamic> getClearanceSearchProduct(String sellerId, String offset, String productId, {String search = '', String? categoryIds, String? brandIds,  String? authorIds, String? publishingIds, String? productType, String? offerType});
}
