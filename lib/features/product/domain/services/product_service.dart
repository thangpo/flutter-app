import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/repositories/product_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/services/product_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/enums/product_type.dart';

import '../../../../common/enums/data_source_enum.dart';

class ProductService implements ProductServiceInterface{
  ProductRepositoryInterface productRepositoryInterface;

  ProductService({required this.productRepositoryInterface});

  @override
  Future getBrandOrCategoryProductList({required bool isBrand, required int id, String searchProduct = '', required int offset}) async{
    return await productRepositoryInterface.getBrandOrCategoryProductList(isBrand: isBrand, id: id, searchProduct: searchProduct, offset: offset);
  }

  @override
  Future getFilteredProductList(BuildContext context, String offset, ProductType productType) async{
    return await productRepositoryInterface.getFilteredProductList(context, offset, productType);
  }

  @override
  Future<ApiResponseModel<T>> getFindWhatYouNeed<T>({required DataSourceEnum source}) async{
    return await productRepositoryInterface.getFindWhatYouNeed(source: source);
  }

  @override
  Future<ApiResponseModel<T>> getHomeCategoryProductList<T>({required DataSourceEnum source}) async{
    return await productRepositoryInterface.getHomeCategoryProductList(source: source);
  }

  @override
  Future getJustForYouProductList({required int offset, int? limit}) async{
    return await productRepositoryInterface.getJustForYouProductList(offset: offset, limit: limit);
  }

  @override
  Future getLatestProductList(String offset) async{
    return await productRepositoryInterface.getLatestProductList(offset);
  }

  @override
  Future<ApiResponseModel<T>> getMostDemandedProduct<T>({required DataSourceEnum source}) async{
    return await productRepositoryInterface.getMostDemandedProduct(source: source);
  }

  @override
  Future<ApiResponseModel<T>> getMostSearchingProductList<T>({required int offset, required DataSourceEnum source}) async{
    return await productRepositoryInterface.getMostSearchingProductList(offset: offset, source: source);
  }

  @override
  Future<ApiResponseModel<T>> getRecommendedProduct<T>({required DataSourceEnum source}) async{
    return await productRepositoryInterface.getRecommendedProduct(source: source);
  }

  @override
  Future getRelatedProductList(String id) async{
    return await productRepositoryInterface.getRelatedProductList(id);
  }

  @override
  Future<ApiResponseModel<T>> getClearanceAllProductList<T>({required int offset, required DataSourceEnum source}) async{
    return await productRepositoryInterface.getClearanceAllProductList(offset: offset, source: source);
  }


  @override
  Future getClearanceSearchProducts(String query, String? categoryIds, String? brandIds, String? authorIds, String? publishingIds, String? sort, String? priceMin, String? priceMax, int offset, String? productType, String? offerType) async{
    return await productRepositoryInterface.getClearanceSearchProducts(query, categoryIds, brandIds, authorIds, publishingIds, sort, priceMin, priceMax, offset, productType, offerType);
  }

  @override
  Future<ApiResponseModel<T>> getProductModelByType<T>({required int offset, required ProductType productType, required DataSourceEnum source}) async {
    return await productRepositoryInterface.getProductModelByType(offset: offset, productType: productType, source: source);
  }




}