import 'package:flutter_sixvalley_ecommerce/features/product/domain/repositories/seller_product_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/services/seller_product_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/common/enums/data_source_enum.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';

class SellerProductService implements SellerProductServiceInterface {
  final SellerProductRepositoryInterface sellerProductRepositoryInterface;

  SellerProductService({required this.sellerProductRepositoryInterface});

  @override
  Future getSellerProductList(String sellerId, String offset, String productId,
      {String search = '',
      String? categoryIds,
      String? brandIds,
      String? authorIds,
      String? publishingIds,
      String? productType}) async {
    return await sellerProductRepositoryInterface.getSellerProductList(
        sellerId, offset, productId,
        search: search,
        categoryIds: categoryIds,
        brandIds: brandIds,
        authorIds: authorIds,
        publishingIds: publishingIds,
        productType: productType);
  }

  @override
  Future getSellerWiseBestSellingProductList(
      String sellerId, String offset) async {
    return await sellerProductRepositoryInterface
        .getSellerWiseBestSellingProductList(sellerId, offset);
  }

  @override
  Future getSellerWiseFeaturedProductList(
      String sellerId, String offset) async {
    return await sellerProductRepositoryInterface
        .getSellerWiseFeaturedProductList(sellerId, offset);
  }

  @override
  Future getSellerWiseRecomendedProductList(
      String sellerId, String offset) async {
    return await sellerProductRepositoryInterface
        .getSellerWiseRecommendedProductList(sellerId, offset);
  }

  @override
  Future<ApiResponseModel<T>> getShopAgainFromRecentStore<T>(
      {required DataSourceEnum source}) async {
    return await sellerProductRepositoryInterface.getShopAgainFromRecentStore(
        source: source);
  }
}
