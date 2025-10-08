import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/enums/data_source_enum.dart';
import 'package:flutter_sixvalley_ecommerce/data/local/cache_response.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/models/more_store_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/models/seller_info_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/models/seller_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/services/shop_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/helper/data_sync_helper.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class ShopController extends ChangeNotifier {
  final ShopServiceInterface? shopServiceInterface;
  ShopController({required this.shopServiceInterface});

  String? _searchText;
  String? get searchText => _searchText;

  String? shopName;
  void setShopName(String? name, {bool notify = true}){
    shopName = name;
    if(notify){
      notifyListeners();
    }
  }


  int shopMenuIndex = 0;
  void setMenuItemIndex(int index, {bool notify = true}){
    shopMenuIndex = index;
    if(notify){
      notifyListeners();
    }
  }


  SellerInfoModel? sellerInfoModel ;
  Future<void> getSellerInfo(String sellerId) async {
    ApiResponseModel apiResponse = await shopServiceInterface!.get(sellerId);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      sellerInfoModel = SellerInfoModel.fromJson(apiResponse.response!.data);
    } else {
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
  }



  bool isLoading = false;
  List<MostPopularStoreModel> moreStoreList =[];

  Future<void> getMoreStore() async {
    moreStoreList = [];
    isLoading = true;

    DataSyncHelper.fetchAndSyncData(
      fetchFromLocal: () => shopServiceInterface!.getMoreStore(source: DataSourceEnum.local),
      fetchFromClient: () => shopServiceInterface!.getMoreStore(source: DataSourceEnum.client),
      onResponse: (data, source) {
        moreStoreList.clear();
        data.forEach((store) => moreStoreList.add(MostPopularStoreModel.fromJson(store)));
        isLoading = false;
        notifyListeners();
      },
    );
  }


  String sellerType = "top";
  String sellerTypeTitle = "top_seller";
  void setSellerType(String type, {bool notify = true}){
    sellerType = type;
    filteredSellerModel = null;
    if(sellerType == "top"){
      sellerTypeTitle = "top_seller";
    }
    else if(sellerType == "new"){
      sellerTypeTitle = "new_seller";
    }else{
      sellerTypeTitle = "all_seller";
    }

    getFilteredSellerList(type: type, offset: 1, isUpdate: notify);

    if(notify){
      notifyListeners();
    }
  }

  SellerModel? topSellerModel;
  Future<void> getTopSellerList({required int offset, bool isUpdate = true}) async {

    if(offset == 1) {
      topSellerModel = null;

      if(isUpdate) {
        notifyListeners();
      }
    }

    if(offset == 1) {
      DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: ()=> shopServiceInterface!.getSellerList(type: 'top', offset: offset, limit: 10, source: DataSourceEnum.local),
        fetchFromClient: ()=> shopServiceInterface!.getSellerList(type: 'top', offset: offset, limit: 10,  source: DataSourceEnum.client),
        onResponse: (data, source) {
          topSellerModel = SellerModel.fromJson(data);
          notifyListeners();

        },
      );
    }else {
      final ApiResponseModel apiResponse = await shopServiceInterface!.getSellerList(type: 'top', limit: 10, offset: offset, source: DataSourceEnum.client);

      if(apiResponse.response?.statusCode == 200) {
        final SellerModel parseSellerModel = SellerModel.fromJson(apiResponse.response.data);

        topSellerModel?.offset  = parseSellerModel.offset;
        topSellerModel?.limit  = parseSellerModel.limit;
        topSellerModel?.sellers?.addAll(parseSellerModel.sellers ?? []);

      }else {
        ApiChecker.checkApi(apiResponse);
      }

      notifyListeners();

    }
  }

  SellerModel? filteredSellerModel;
  Future<void> getFilteredSellerList({required int offset, required String type, bool isUpdate = true}) async {

    if(offset == 1) {
      filteredSellerModel = null;

      if(isUpdate) {
        notifyListeners();
      }
    }

    if(offset == 1) {
      DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: ()=> shopServiceInterface!.getSellerList(type: type, limit: 10, offset: offset, source: DataSourceEnum.local),
        fetchFromClient: ()=> shopServiceInterface!.getSellerList(type: type, limit: 10, offset: offset, source: DataSourceEnum.client),
        onResponse: (data, source) {
          filteredSellerModel = SellerModel.fromJson(data);
          notifyListeners();

        },
      );
    }else {
      final ApiResponseModel apiResponse = await shopServiceInterface!.getSellerList(type: type, limit: 10,  offset: offset, source: DataSourceEnum.client);

      if(apiResponse.response?.statusCode == 200) {
        final SellerModel parseSellerModel = SellerModel.fromJson(apiResponse.response.data);

        filteredSellerModel?.offset  = parseSellerModel.offset;
        filteredSellerModel?.limit  = parseSellerModel.limit;
        filteredSellerModel?.sellers?.addAll(parseSellerModel.sellers ?? []);

      }else {
        ApiChecker.checkApi(apiResponse);
      }

      notifyListeners();

    }
  }

  SellerModel? allSellerModel;
  Future<void> getAllSellerList({required int offset, bool isUpdate = true}) async {

    if(offset == 1) {
      allSellerModel = null;

      if(isUpdate) {
        notifyListeners();
      }
    }

    if(offset == 1) {
      DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: ()=> shopServiceInterface!.getSellerList(type: 'all', limit: 100,  offset: offset, source: DataSourceEnum.local),
        fetchFromClient: ()=> shopServiceInterface!.getSellerList(type: 'all', limit: 100, offset: offset, source: DataSourceEnum.client),
        onResponse: (data, source) {
          allSellerModel = SellerModel.fromJson(data);

          notifyListeners();

        },
      );
    }else {
      final ApiResponseModel apiResponse = await shopServiceInterface!.getSellerList(type: 'all', limit: 100, offset: offset, source: DataSourceEnum.client);

      if(apiResponse.response?.statusCode == 200) {
        final SellerModel parseSellerModel = SellerModel.fromJson(apiResponse.response.data);

        allSellerModel?.offset  = parseSellerModel.offset;
        allSellerModel?.limit  = parseSellerModel.limit;
        allSellerModel?.sellers?.addAll(parseSellerModel.sellers ?? []);

      }else {
        ApiChecker.checkApi(apiResponse);
      }

      notifyListeners();

    }
  }





  ProductModel? clearanceProductModel;
  Future<void> getClearanceShopProductList(String type, String offset, String sellerId, {bool reload = false}) async {

    var localData =  await database.getCacheResponseById("${AppConstants.clearanceShopProductUri}$sellerId/products?guest_id=1&limit=10&offset=$offset&offer_type=$type");

    if(localData != null) {
      clearanceProductModel = ProductModel.fromJson(jsonDecode(localData.response));
      notifyListeners();
    }

    ApiResponseModel apiResponse = await shopServiceInterface!.getClearanceShopProductList(type, offset, sellerId);

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      if(offset == '1'){
        clearanceProductModel = null;
        // SellerModel.fromJson(apiResponse.response?.data);
        clearanceProductModel = ProductModel.fromJson(apiResponse.response?.data);
      }else{
        clearanceProductModel?.products?.addAll(ProductModel.fromJson(apiResponse.response!.data).products??[]);
        clearanceProductModel?.offset  = (ProductModel.fromJson(apiResponse.response!.data).offset!);
        clearanceProductModel?.totalSize  = (ProductModel.fromJson(apiResponse.response!.data).totalSize!);
      }

      if (localData != null) {
        await database.updateCacheResponse("${AppConstants.clearanceShopProductUri}$sellerId/products?guest_id=1&limit=10&offset=$offset&offer_type=$type", CacheResponseCompanion(
          endPoint: Value("${AppConstants.clearanceShopProductUri}$sellerId/products?guest_id=1&limit=10&offset=$offset&offer_type=$type"),
          header: Value(jsonEncode(apiResponse.response!.headers.map)),
          response: Value(jsonEncode(apiResponse.response!.data)),
        ));
      } else {
        await database.insertCacheResponse(
          CacheResponseCompanion(
            endPoint: Value("${AppConstants.clearanceShopProductUri}$sellerId/products?guest_id=1&limit=10&offset=$offset&offer_type=$type"),
            header: Value(jsonEncode(apiResponse.response!.headers.map)),
            response: Value(jsonEncode(apiResponse.response!.data)),
          ),
        );
      }
    }
    notifyListeners();
  }


  void emptyClearanceProductList() {
    clearanceProductModel = null;
  }


  ProductModel? clearanceSearchProductModel;
  bool isSearchLoading = false;
  bool isSearchActive = false;
  bool isFilterActive = false;
  Future <ApiResponseModel> getClearanceSearchProduct(String sellerId, int offset, String productId, {
    bool reload = true,
    String search = '',
    String? categoryIds = '[]',
    String? brandIds = '[]',
    String? authorIds = '[]',
    String? publishingIds = '[]',
    String? productType = 'all',
    String? offerType = 'clearance_sale',
    bool fromPaginantion = false
  }) async {

    !fromPaginantion ? isSearchLoading = true : null;
    notifyListeners();

    // if(reload) {
    //   sellerProduct = null;
    // }

    ApiResponseModel apiResponse = await shopServiceInterface!.getClearanceSearchProduct(
        sellerId, offset.toString(),
        productId, categoryIds : categoryIds,
        brandIds: brandIds, search: search,
        authorIds: authorIds, publishingIds: publishingIds,
        productType: productType,
        offerType: offerType
    );
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      if(offset == 1){
        clearanceSearchProductModel = null;
        clearanceSearchProductModel = ProductModel.fromJson(apiResponse.response!.data);
      }else{
        clearanceSearchProductModel?.products?.addAll(ProductModel.fromJson(apiResponse.response!.data).products!);
        clearanceSearchProductModel?.offset = (ProductModel.fromJson(apiResponse.response!.data).offset!);
        clearanceSearchProductModel?.totalSize = ProductModel.fromJson(apiResponse.response!.data).totalSize;
      }
    } else {
      ApiChecker.checkApi( apiResponse);
    }

    isSearchLoading = false;

    notifyListeners();
    return apiResponse;
  }


  int? _clearanceSaleProductSelectedIndex;
  int? get clearanceSaleProductSelectedIndex => _clearanceSaleProductSelectedIndex;

  void changeSelectedIndex(int selectedIndex) {
    _clearanceSaleProductSelectedIndex = selectedIndex;
    notifyListeners();
  }


  void setSearchText(String? value, {bool isUpdate = true}) {
    _searchText = value;
  }


  void toggleSearchActive(){
    isSearchActive = !isSearchActive;
    notifyListeners();
  }


  void disableSearch({bool isUpdate = true}) {
    isSearchActive = false;
    isSearchLoading = false;
    isFilterActive = false;
    if(isUpdate){
      notifyListeners();
    }
  }


}
