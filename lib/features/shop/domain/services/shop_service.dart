import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/repositories/shop_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/services/shop_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/common/enums/data_source_enum.dart';

class ShopService implements ShopServiceInterface {
  final ShopRepositoryInterface shopRepositoryInterface;

  ShopService({required this.shopRepositoryInterface});

  @override
  Future<ApiResponseModel<T>> getMoreStore<T>({required DataSourceEnum source}) async {
    return await shopRepositoryInterface.getMoreStore(source: source);
  }

  @override
  Future<ApiResponseModel<T>> getSellerList<T>({required String type, required int offset, required int limit, required DataSourceEnum source}) async {
    return await shopRepositoryInterface.getSellerList(source: source, type: type, offset: offset, limit: limit);
  }

  @override
  Future getClearanceShopProductList(String type, String offset, String sellerId) async{
    return await shopRepositoryInterface.getClearanceShopProductList(type, offset, sellerId);
  }

  @override
  Future get(String id) async {
    return await shopRepositoryInterface.get(id);
  }

  @override
  Future getClearanceSearchProduct(String sellerId, String offset, String productId, {String search = '', String? categoryIds, String? brandIds, String? authorIds, String? publishingIds, String? productType, String? offerType}) async {
    return await shopRepositoryInterface.getClearanceSearchProduct(sellerId, offset, productId, search: search, categoryIds: categoryIds, brandIds: brandIds, authorIds: authorIds, publishingIds: publishingIds, productType: productType, offerType: 'clearance_sale');
  }

}