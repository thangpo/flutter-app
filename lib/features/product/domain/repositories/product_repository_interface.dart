import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/enums/data_source_enum.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/enums/product_type.dart';
import 'package:flutter_sixvalley_ecommerce/interface/repo_interface.dart';

abstract class ProductRepositoryInterface extends RepositoryInterface {

  Future<dynamic> getFilteredProductList(BuildContext context, String offset, ProductType productType);

  Future<ApiResponseModel<T>> getProductModelByType<T>({required int offset, required ProductType productType, required DataSourceEnum source});

  Future<dynamic> getBrandOrCategoryProductList({required bool isBrand, required int id, String searchProduct = '', required int offset});

  Future<dynamic> getRelatedProductList(String id);

  Future<dynamic> getLatestProductList(String offset);

  Future<ApiResponseModel<T>> getRecommendedProduct<T>({required DataSourceEnum source});

  Future<ApiResponseModel<T>> getMostDemandedProduct<T>({required DataSourceEnum source});

  Future<ApiResponseModel<T>> getFindWhatYouNeed<T>({required DataSourceEnum source});

  Future<dynamic> getJustForYouProductList({required int offset, int? limit});

  Future<ApiResponseModel<T>> getMostSearchingProductList<T>({required int offset, required DataSourceEnum source});

  Future<ApiResponseModel<T>> getHomeCategoryProductList<T>({required DataSourceEnum source});

  Future<ApiResponseModel<T>> getClearanceAllProductList<T>({required int offset, required DataSourceEnum source});

  Future<dynamic> getClearanceSearchProducts(String query, String? categoryIds, String? brandIds, String? authorIds, String? publishingIds, String? sort, String? priceMin, String? priceMax, int offset, String? productType, String? offerType);

}