import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/enums/data_source_enum.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/domain/models/find_what_you_need.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/home_category_product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/most_demanded_product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/services/product_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/enums/product_type.dart';
import 'package:flutter_sixvalley_ecommerce/helper/data_sync_helper.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';

class ProductController extends ChangeNotifier {
  final ProductServiceInterface? productServiceInterface;
  ProductController({required this.productServiceInterface});




  ProductType _selectedProductType = ProductType.newArrival;


  ProductType get productType => _selectedProductType;

  Product? _recommendedProduct;
  Product? get recommendedProduct=> _recommendedProduct;

  ProductModel? _discountedProductModel;
  ProductModel? get discountedProductModel => _discountedProductModel;

  ProductModel? _selectedProductModel;
  ProductModel? get selectedProductModel => _selectedProductModel;

  ProductModel? _allProductModel;
  ProductModel? get allProductModel => _allProductModel;

  ProductModel? _latestProductModel;
  ProductModel? get latestProductModel => _latestProductModel;

  ProductModel? _featuredProductModel;
  ProductModel? get featuredProductModel => _featuredProductModel;

  final List<HomeCategoryProduct> _homeCategoryProductList = [];
  List<HomeCategoryProduct> get homeCategoryProductList => _homeCategoryProductList;

  MostDemandedProductModel? _mostDemandedProductModel;
  MostDemandedProductModel? get  mostDemandedProductModel => _mostDemandedProductModel;

  FindWhatYouNeedModel? _findWhatYouNeedModel;
  FindWhatYouNeedModel? get findWhatYouNeedModel => _findWhatYouNeedModel;

  ProductModel? _clearanceProductModel;
  ProductModel? get clearanceProductModel => _clearanceProductModel;


  bool filterApply = false;

  String? _searchText;
  String? get searchText => _searchText;

  int? _selectedCategoryId;
  int? get selectedCategoryId => _selectedCategoryId;

  String? _categorySearchProductText;
  String? get categorySearchProductText => _categorySearchProductText;

  void isFilterApply (bool apply, {bool reload = false}){
    filterApply = apply;
    if(reload){
      notifyListeners();
    }
  }



  Future<void> getSelectedProductModel(int offset, {bool isUpdate = true}) async {
    if(offset == 1) {
      _selectedProductModel = null;

      if(isUpdate) {
        notifyListeners();
      }
    }

    if(offset == 1) {
      DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: ()=> productServiceInterface!.getProductModelByType(offset: offset, productType: productType, source: DataSourceEnum.local),
        fetchFromClient: ()=> productServiceInterface!.getProductModelByType(offset: offset, productType: productType, source: DataSourceEnum.client),
        onResponse: (data, source){
          try{
            _selectedProductModel = ProductModel.fromJson(data);

          }catch(e){
            _selectedProductModel = ProductModel(offset: 1, products: []);

          }
          notifyListeners();
        },
      );
    }else {
      final ApiResponseModel? apiResponse = await productServiceInterface?.getProductModelByType<Response>(offset: offset , productType: _selectedProductType, source: DataSourceEnum.client);

      if (apiResponse?.response?.statusCode == 200) {
        final ProductModel parsedProductModel = ProductModel.fromJson(apiResponse?.response?.data);

        _selectedProductModel?.totalSize = parsedProductModel.totalSize;
        _selectedProductModel?.offset = parsedProductModel.offset;
        _selectedProductModel?.products?.addAll(parsedProductModel.products ?? []);
        notifyListeners();

      } else {
        ApiChecker.checkApi(apiResponse!);

      }
    }
  }


  Future<void> getAllProductModelByType({required int offset, required ProductType type, bool isUpdate = true}) async {
    if(offset == 1) {
      _allProductModel = null;

      if(isUpdate) {
        notifyListeners();
      }

    }

    if(offset == 1) {
      DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: ()=> productServiceInterface!.getProductModelByType(offset: offset, productType: type, source: DataSourceEnum.local),
        fetchFromClient: ()=> productServiceInterface!.getProductModelByType(offset: offset, productType: type, source: DataSourceEnum.client),
        onResponse: (data, source){
          try{
            _allProductModel = ProductModel.fromJson(data);

          }catch(e){
            _allProductModel = ProductModel(products: [], offset: offset);

          }
          notifyListeners();
        },
      );
    }else {
      final ApiResponseModel? apiResponse = await productServiceInterface?.getProductModelByType<Response>(offset: offset , productType: ProductType.latestProduct, source: DataSourceEnum.client);

      if (apiResponse?.response?.statusCode == 200) {
        final ProductModel parsedProductModel = ProductModel.fromJson(apiResponse?.response?.data);

        _allProductModel?.totalSize = parsedProductModel.totalSize;
        _allProductModel?.offset = parsedProductModel.offset;
        _allProductModel?.products?.addAll(parsedProductModel.products ?? []);

      } else {
        ApiChecker.checkApi(apiResponse!);

      }
      notifyListeners();
    }


  }



  Future<void> getLatestProductList(int offset, {bool isUpdate = false}) async {
    if(offset == 1) {
      _latestProductModel = null;

      if(isUpdate) {
        notifyListeners();
      }
    }

    if(offset == 1) {
      DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: ()=> productServiceInterface!.getProductModelByType(offset: offset, productType: ProductType.latestProduct, source: DataSourceEnum.local),
        fetchFromClient: ()=> productServiceInterface!.getProductModelByType(offset: offset, productType: ProductType.latestProduct, source: DataSourceEnum.client),
        onResponse: (data, source){
          try{
          _latestProductModel = ProductModel.fromJson(data);

          }catch(e){
            _latestProductModel = ProductModel(offset: offset, products: []);
          }
          notifyListeners();
        },
      );
    }else {
      final ApiResponseModel? apiResponse = await productServiceInterface?.getProductModelByType<Response>(offset: offset , productType: ProductType.latestProduct, source: DataSourceEnum.client);

      if (apiResponse?.response?.statusCode == 200) {
        final ProductModel parsedProductModel = ProductModel.fromJson(apiResponse?.response?.data);

        _latestProductModel?.totalSize = parsedProductModel.totalSize;
        _latestProductModel?.offset = parsedProductModel.offset;
        _latestProductModel?.products?.addAll(parsedProductModel.products ?? []);


      } else {
        ApiChecker.checkApi(apiResponse!);

      }
      notifyListeners();
    }

  }



  void onChangeSelectedProductType(ProductType type){
    _selectedProductType = type;

    getSelectedProductModel(1);

    notifyListeners();
 }


  TextEditingController sellerProductSearch = TextEditingController();
  void clearSearchField( String id){
    sellerProductSearch.clear();
    notifyListeners();
  }




  ProductModel? _brandOrCategoryProductList;

  ProductModel? get brandOrCategoryProductList => _brandOrCategoryProductList;

  Future<void> initBrandOrCategoryProductList({required bool isBrand, required int? id, String searchProduct = '', required int offset, bool isUpdate = true}) async {
    if(offset == 1) {
      _brandOrCategoryProductList = null;
    }
    if(isUpdate) {
      notifyListeners();
    }

    ApiResponseModel apiResponse = await productServiceInterface!.getBrandOrCategoryProductList(isBrand: isBrand, id: id!, searchProduct: searchProduct, offset: offset);

    if (apiResponse.response?.statusCode == 200) {
      if(offset == 1){
        _brandOrCategoryProductList = ProductModel.fromJson(apiResponse.response?.data);

      } else {
        _brandOrCategoryProductList?.products?.addAll(ProductModel.fromJson(apiResponse.response?.data).products ?? []);
        _brandOrCategoryProductList?.offset = ProductModel.fromJson(apiResponse.response?.data).offset;
        _brandOrCategoryProductList?.totalSize = ProductModel.fromJson(apiResponse.response?.data).totalSize;

      }
    } else {
      ApiChecker.checkApi( apiResponse);

    }

    notifyListeners();
  }


  List<Product>? _relatedProductList;
  List<Product>? get relatedProductList => _relatedProductList;

  void initRelatedProductList(String id, BuildContext context) async {
    ApiResponseModel apiResponse = await productServiceInterface!.getRelatedProductList(id);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _relatedProductList = [];
      apiResponse.response!.data.forEach((product) => _relatedProductList!.add(Product.fromJson(product)));
    } else {
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
  }



  void getMoreProductList(String id) async {
    ApiResponseModel apiResponse = await productServiceInterface!.getRelatedProductList(id);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _relatedProductList = [];
      apiResponse.response!.data.forEach((product) => _relatedProductList!.add(Product.fromJson(product)));
    } else {
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
  }

  void removePrevRelatedProduct() {
    _relatedProductList = null;
  }




  Future<void> getFeaturedProductModel(int offset, {bool isUpdate = false}) async {
    if(offset == 1) {
      _featuredProductModel = null;

      if(isUpdate) {
        notifyListeners();
      }
    }

    if(offset == 1) {
      DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: ()=> productServiceInterface!.getProductModelByType(offset: offset, productType: ProductType.featuredProduct, source: DataSourceEnum.local),
        fetchFromClient: ()=> productServiceInterface!.getProductModelByType(offset: offset, productType: ProductType.featuredProduct, source: DataSourceEnum.client),
        onResponse: (data, source){
          try{
            _featuredProductModel = ProductModel.fromJson(data);

          }catch(e){
            _featuredProductModel = ProductModel(products: [], offset: 1);
          }
          notifyListeners();
        },
      );
    }else {
      final ApiResponseModel? apiResponse = await productServiceInterface?.getProductModelByType<Response>(offset: offset , productType: ProductType.featuredProduct, source: DataSourceEnum.client);

      if (apiResponse?.response?.statusCode == 200) {
        final ProductModel parsedProductModel = ProductModel.fromJson(apiResponse?.response?.data);

        _featuredProductModel?.totalSize = parsedProductModel.totalSize;
        _featuredProductModel?.offset = parsedProductModel.offset;
        _featuredProductModel?.products?.addAll(parsedProductModel.products ?? []);


      } else {
        ApiChecker.checkApi(apiResponse!);

      }
      notifyListeners();
    }

  }


  Future<void> getRecommendedProduct() async {

    DataSyncHelper.fetchAndSyncData(
      fetchFromLocal: ()=> productServiceInterface!.getRecommendedProduct(source: DataSourceEnum.local),
      fetchFromClient: ()=> productServiceInterface!.getRecommendedProduct(source: DataSourceEnum.client),
      onResponse: (data, source) {

        try{
          if(data is List) {
            _recommendedProduct = Product(id: -1);
          } else {
            _recommendedProduct = Product.fromJson(data);
          }
        }catch(e){
          _recommendedProduct = null;
        }

        notifyListeners();

      },
    );

  }



  Future<void> getHomeCategoryProductList(bool reload) async {

    if(_homeCategoryProductList.isEmpty || reload) {
      DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: ()=> productServiceInterface!.getHomeCategoryProductList(source: DataSourceEnum.local),
        fetchFromClient: ()=> productServiceInterface!.getHomeCategoryProductList(source: DataSourceEnum.client),
        onResponse: (data, _) {
          _homeCategoryProductList.clear();

          data.forEach((homeCategory) => _homeCategoryProductList.add(HomeCategoryProduct.fromJson(homeCategory)));

          notifyListeners();

        },
      );
    }

  }


  Future<void> getMostDemandedProduct() async {

    DataSyncHelper.fetchAndSyncData(
      fetchFromLocal: ()=> productServiceInterface!.getMostDemandedProduct(source: DataSourceEnum.local),
      fetchFromClient: ()=> productServiceInterface!.getMostDemandedProduct(source: DataSourceEnum.client),
      onResponse: (data, _) {
        try{
          _mostDemandedProductModel = MostDemandedProductModel.fromJson(data);

        }catch(e){
          _mostDemandedProductModel = null;
        }

        notifyListeners();

      },
    );

  }


  Future<void> findWhatYouNeed() async {
    DataSyncHelper.fetchAndSyncData(
      fetchFromLocal: ()=> productServiceInterface!.getFindWhatYouNeed(source: DataSourceEnum.local),
      fetchFromClient: ()=> productServiceInterface!.getFindWhatYouNeed(source: DataSourceEnum.client),
      onResponse: (data, source) {
        try{
          _findWhatYouNeedModel = FindWhatYouNeedModel.fromJson(data);

        }catch(e){
          _findWhatYouNeedModel = null;
        }

        notifyListeners();

      },
    );
  }

  ProductModel? _justForYouProductModel;
  ProductModel? get justForYouProductModel => _justForYouProductModel;

  Future<void> getJustForYouProduct(int offset, {bool isUpdate = true, int? limit}) async {
    if(offset == 1) {
      _justForYouProductModel = null;

      if(isUpdate) {
        notifyListeners();
      }
    }

    if(offset == 1) {
      DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: ()=> productServiceInterface!.getProductModelByType(offset: offset, productType: ProductType.justForYou, source: DataSourceEnum.local),
        fetchFromClient: ()=> productServiceInterface!.getProductModelByType(offset: offset, productType: ProductType.justForYou, source: DataSourceEnum.client),
        onResponse: (data, source){
          try{
            _justForYouProductModel = ProductModel.fromJson(data);

          }finally{
            _justForYouProductModel = ProductModel(products: []);

          }
          notifyListeners();
        },
      );
    }else {
      final ApiResponseModel? apiResponse = await productServiceInterface?.getProductModelByType<Response>(offset: offset , productType: ProductType.justForYou, source: DataSourceEnum.client);

      if (apiResponse?.response?.statusCode == 200) {
        final ProductModel parsedProductModel = ProductModel.fromJson(apiResponse?.response?.data);

        _justForYouProductModel?.totalSize = parsedProductModel.totalSize;
        _justForYouProductModel?.offset = parsedProductModel.offset;
        _justForYouProductModel?.products?.addAll(parsedProductModel.products ?? []);

      } else {
        ApiChecker.checkApi(apiResponse!);

      }
      notifyListeners();
    }
  }

  ProductModel? _mostSearchingProduct;
  ProductModel? get mostSearchingProduct => _mostSearchingProduct;

  Future<void> getMostSearchingProduct(int offset, {bool isUpdate = true}) async {
    if(offset == 1) {
      _mostSearchingProduct = null;

      if(isUpdate) {
        notifyListeners();
      }
    }

    if(offset == 1) {
      DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: ()=> productServiceInterface!.getMostSearchingProductList(offset: offset, source: DataSourceEnum.local),
        fetchFromClient: ()=> productServiceInterface!.getMostSearchingProductList(offset: offset, source: DataSourceEnum.client),
        onResponse: (data, source){
          try{
            _mostSearchingProduct = ProductModel.fromJson(data);

          }finally{
            _mostSearchingProduct = ProductModel(products: []);

          }
          notifyListeners();
        },
      );
    }else {
      final ApiResponseModel? apiResponse = await productServiceInterface?.getMostSearchingProductList<Response>(offset: offset, source: DataSourceEnum.client);

      if (apiResponse?.response?.statusCode == 200) {
        final ProductModel parsedProductModel = ProductModel.fromJson(apiResponse?.response?.data);

        _mostSearchingProduct?.totalSize = parsedProductModel.totalSize;
        _mostSearchingProduct?.offset = parsedProductModel.offset;
        _mostSearchingProduct?.products?.addAll(parsedProductModel.products ?? []);

      } else {
        ApiChecker.checkApi(apiResponse!);

      }
      notifyListeners();
    }

  }


  Future<void> getDiscountedProductList(int offset, bool reload, { bool isUpdate = true}) async {

    if(reload) {
      _discountedProductModel = null;

      if(isUpdate) {
        notifyListeners();
      }
    }

    ApiResponseModel apiResponse = await productServiceInterface!.getFilteredProductList(Get.context!, offset.toString(), ProductType.discountedProduct);

    if (apiResponse.response?.data != null && apiResponse.response?.statusCode == 200) {
      if(offset == 1){
        _discountedProductModel = ProductModel.fromJson(apiResponse.response?.data);
      } else {
        _discountedProductModel?.totalSize = ProductModel.fromJson(apiResponse.response?.data).totalSize;
        _discountedProductModel?.offset = ProductModel.fromJson(apiResponse.response?.data).offset;
        _discountedProductModel?.products?.addAll(ProductModel.fromJson(apiResponse.response?.data).products ?? []);
      }

      notifyListeners();

    } else {
      ApiChecker.checkApi(apiResponse);

    }

  }


  Future<void> getClearanceAllProductList(int offset, {bool isUpdate = true}) async {
    if(offset == 1) {
      _clearanceProductModel = null;

      if(isUpdate) {
        notifyListeners();
      }
    }

    if(offset == 1) {
      DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: ()=> productServiceInterface!.getClearanceAllProductList(offset: offset, source: DataSourceEnum.local),
        fetchFromClient: ()=> productServiceInterface!.getClearanceAllProductList(offset: offset, source: DataSourceEnum.client),
        onResponse: (data, source){
          try{
            _clearanceProductModel = ProductModel.fromJson(data);

          }catch(_){
            _clearanceProductModel = ProductModel(products: [], offset: offset);

          }
          notifyListeners();
        },
      );
    }else {
      final ApiResponseModel? apiResponse = await productServiceInterface?.getClearanceAllProductList<Response>(offset: offset,source: DataSourceEnum.client);

      if (apiResponse?.response?.statusCode == 200) {
        final ProductModel parsedProductModel = ProductModel.fromJson(apiResponse?.response?.data);

        _clearanceProductModel?.totalSize = parsedProductModel.totalSize;
        _clearanceProductModel?.offset = parsedProductModel.offset;
        _clearanceProductModel?.products?.addAll(parsedProductModel.products ?? []);

      } else {
        ApiChecker.checkApi(apiResponse!);

      }
      notifyListeners();
    }
  }


  ProductModel? clearanceSearchProductModel;
  bool isSearchLoading = false;
  bool isSearchActive = false;
  bool isFilterActive = false;
  Future <ApiResponseModel> getClearanceSearchProduct({required String query, String? categoryIds, String? brandIds,  String? authorIds, String? publishingIds, String? sort, String? priceMin, String? priceMax, required int offset, String? productType, String offerType = 'clearance_sale', bool fromPaginantion = false, isNotify = true}) async {

    if(!fromPaginantion && isNotify){
      isSearchLoading = true;
      notifyListeners();
    }


    // if(reload) {
    //   sellerProduct = null;
    // }

    ApiResponseModel apiResponse = await productServiceInterface!.getClearanceSearchProducts(query, categoryIds, brandIds, authorIds, publishingIds, sort, priceMin, priceMax, offset, productType, offerType);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      if(offset == 1){
        // clearanceSearchProductModel = null;
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


  void setSearchText(String? value, {bool isUpdate = true}) {
    _searchText = value;
    if(isUpdate){
      notifyListeners();
    }
  }


  void toggleSearchActive(){
    isSearchActive = !isSearchActive;
    notifyListeners();
  }


  void disableSearch({bool isUpdate = true}) {
    clearanceSearchProductModel = null;
    isSearchActive = false;
    isSearchLoading = false;
    isFilterActive = false;
    if(isUpdate){
      notifyListeners();
    }
  }

  void updateSelectedCategoryId({required int id, bool isUpdate = true}){
    _selectedCategoryId = id;
    if(isUpdate){
      notifyListeners();
    }
  }

  void setCategorySearchProductText(String? value, {bool isUpdate = true}) {
    _categorySearchProductText = value;
    if(isUpdate){
      notifyListeners();
    }
  }


}

class ProductTypeModel{
  String? title;
  ProductType productType;

  ProductTypeModel(this.title, this.productType);
}

