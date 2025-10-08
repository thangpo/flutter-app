import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/services/seller_product_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/models/shop_again_from_recent_store_model.dart';
import 'package:flutter_sixvalley_ecommerce/common/enums/data_source_enum.dart';
import 'package:flutter_sixvalley_ecommerce/helper/data_sync_helper.dart';

class SellerProductController extends ChangeNotifier {
  final SellerProductServiceInterface? sellerProductServiceInterface;
  SellerProductController({required this.sellerProductServiceInterface});


  ProductModel? sellerProduct;
  ProductModel? sellerMoreProduct;

  Future <ApiResponseModel> getSellerProductList(String sellerId, int offset, String productId, {
    bool reload = true,
    String search = '',
    String? categoryIds = '[]',
    String? brandIds = '[]',
    String? authorIds = '[]',
    String? publishingIds = '[]',
    String? productType = 'all',
  }) async {

    ApiResponseModel apiResponse = await sellerProductServiceInterface!.getSellerProductList(
      sellerId, offset.toString(),
      productId, categoryIds : categoryIds,
      brandIds: brandIds, search: search,
      authorIds: authorIds, publishingIds: publishingIds,
      productType: productType
    );

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      if(offset == 1){
        sellerProduct = ProductModel.fromJson(apiResponse.response!.data);
      }else{
        sellerProduct?.products?.addAll(ProductModel.fromJson(apiResponse.response!.data).products!);
        sellerProduct?.offset = (ProductModel.fromJson(apiResponse.response!.data).offset!);
        sellerProduct?.totalSize = ProductModel.fromJson(apiResponse.response!.data).totalSize;
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }



  Future <ApiResponseModel> getSellerMoreProductList(String sellerId, int offset, String productId) async {
    sellerMoreProduct = null;

    ApiResponseModel apiResponse = await sellerProductServiceInterface!.getSellerProductList( sellerId, offset.toString(), productId );
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      if(offset == 1){
        sellerMoreProduct = ProductModel.fromJson(apiResponse.response!.data);
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }

  ProductModel? productModel;

  Future<void> getSellerWiseBestSellingProductList(String sellerId, int offset) async {
    ApiResponseModel apiResponse = await sellerProductServiceInterface!.getSellerWiseBestSellingProductList(sellerId, offset.toString());
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      if(offset == 1){
        productModel = null;
        productModel = ProductModel.fromJson(apiResponse.response!.data);
      }else {
        productModel!.products!.addAll(ProductModel.fromJson(apiResponse.response!.data).products!);
        productModel!.offset = ProductModel.fromJson(apiResponse.response!.data).offset;
        productModel!.totalSize = ProductModel.fromJson(apiResponse.response!.data).totalSize;
      }
    } else {
      ApiChecker.checkApi( apiResponse);
    }

    notifyListeners();
  }

  ProductModel? sellerWiseFeaturedProduct;

  Future<void> getSellerWiseFeaturedProductList(String sellerId, int offset) async {
    ApiResponseModel apiResponse = await sellerProductServiceInterface!.getSellerWiseFeaturedProductList(sellerId, offset.toString());
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      if(offset == 1){
        sellerWiseFeaturedProduct = null;
        sellerWiseFeaturedProduct = ProductModel.fromJson(apiResponse.response!.data);

      }else {
        sellerWiseFeaturedProduct!.products!.addAll(ProductModel.fromJson(apiResponse.response!.data).products!);
        sellerWiseFeaturedProduct!.offset = ProductModel.fromJson(apiResponse.response!.data).offset;
        sellerWiseFeaturedProduct!.totalSize = ProductModel.fromJson(apiResponse.response!.data).totalSize;
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }


  ProductModel? sellerWiseRecommendedProduct;
  Future<void> getSellerWiseRecommendedProductList(String sellerId, int offset) async {
    ApiResponseModel apiResponse = await sellerProductServiceInterface!.getSellerWiseRecomendedProductList(sellerId, offset.toString());
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      if(offset == 1){
        sellerWiseRecommendedProduct = null;
        sellerWiseRecommendedProduct = ProductModel.fromJson(apiResponse.response!.data);
      }else {
        sellerWiseRecommendedProduct!.products!.addAll(ProductModel.fromJson(apiResponse.response!.data).products!);
        sellerWiseRecommendedProduct!.offset = ProductModel.fromJson(apiResponse.response!.data).offset;
        sellerWiseRecommendedProduct!.totalSize = ProductModel.fromJson(apiResponse.response!.data).totalSize;
      }
    } else {
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
  }

  List<ShopAgainFromRecentStoreModel> shopAgainFromRecentStoreList = [];

  Future<void> getShopAgainFromRecentStore() async {
    DataSyncHelper.fetchAndSyncData(
      fetchFromLocal: () => sellerProductServiceInterface!.getShopAgainFromRecentStore(source: DataSourceEnum.local),
      fetchFromClient: () => sellerProductServiceInterface!.getShopAgainFromRecentStore(source: DataSourceEnum.client),
      onResponse: (data, source) {
        shopAgainFromRecentStoreList = [];
        data.forEach((store) => shopAgainFromRecentStoreList.add(ShopAgainFromRecentStoreModel.fromJson(store)));
        notifyListeners();
      },
    );
  }

  void clearSellerProducts() {
    sellerWiseFeaturedProduct = null;
    sellerWiseRecommendedProduct = null;
  }
}
