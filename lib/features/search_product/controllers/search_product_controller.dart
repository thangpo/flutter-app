
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/compare/controllers/compare_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/domain/models/author_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/domain/models/suggestion_product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/domain/services/search_product_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:provider/provider.dart';

class SearchProductController with ChangeNotifier {
  final SearchProductServiceInterface? searchProductServiceInterface;
  SearchProductController({required this.searchProductServiceInterface});

  int _filterIndex = 0;
  List<String> _historyList = [];
  List<AuthorModel>? _authorsList;
  List<AuthorModel>? _publishingHouseList;
  List<AuthorModel>? _sellerAuthorsList;
  List<AuthorModel>? _sellerPublishingHouseList;


  int get filterIndex => _filterIndex;
  List<String> get historyList => _historyList;
  List<AuthorModel>? get authorsList => _authorsList;
  List<AuthorModel>? get publishingHouseList => _publishingHouseList;
  List<AuthorModel>? get sellerAuthorsList => _sellerAuthorsList;
  List<AuthorModel>? get sellerPublishingHouseList => _sellerPublishingHouseList;

  final List<int> _selectedAuthorIds = [];
  List<int> get selectedAuthorIds => _selectedAuthorIds;

  final List<int> _publishingHouseIds = [];
  List<int> get publishingHouseIds => _publishingHouseIds;

  List<int> _selectedSellerAuthorIds = [];
  List<int> get selectedSellerAuthorIds => _selectedSellerAuthorIds;

  List<int> _sellerPublishingHouseIds = [];
  List<int> get sellerPublishingHouseIds => _sellerPublishingHouseIds;

  double minPriceForFilter = AppConstants.minFilter;
  double maxPriceForFilter = AppConstants.maxFilter;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _productTypeIndex = 0;
  int get productTypeIndex => _productTypeIndex;

  void setMinMaxPriceForFilter(RangeValues currentRangeValues){
    minPriceForFilter = currentRangeValues.start;
    maxPriceForFilter = currentRangeValues.end;
    notifyListeners();
  }


  bool _isFilterApplied = false;
  bool _isSortingApplied = false;

  bool get isFilterApplied => _isFilterApplied;
  bool get isSortingApplied => _isSortingApplied;


  void setFilterApply({bool? isFiltered, bool? isSorted}){
    if(isFiltered != null) {
      _isFilterApplied = isFiltered;
    }

    if(isSorted != null) {
      _isSortingApplied = isSorted;
    }

    notifyListeners();
  }

  String sortText = 'low-high';
  void setFilterIndex(int index) {
    _filterIndex = index;
    if(index == 0){
      sortText = 'latest';
    }else if(index == 1){
      sortText = 'a-z';
    }else if(index == 2){
      sortText = 'z-a';
    }
    else if(index == 3){
      sortText = 'low-high';
    }else if(index ==4){
      sortText = 'high-low';
    }
    notifyListeners();
  }

  double minFilterValue = 0;
  double maxFilterValue = 0;
  void setFilterValue(double min, double max){
  minFilterValue = min;
  maxFilterValue = max;
  }



  bool _isClear = true;
  bool get isClear => _isClear;

  void cleanSearchProduct({bool notify = false}) {
    // searchedProduct = ProductModel(products: []);
    searchedProduct = null;
    minFilterValue = 0;
    maxFilterValue = 0;
    _isClear = true;
    if(notify){
      notifyListeners();
    }
  }






  ProductModel? searchedProduct;
  Future searchProduct({required String query, String? categoryIds, String? brandIds,  String? authorIds, String? publishingIds, String? sort, String? priceMin, String? priceMax, required int offset}) async {
    if(query.isNotEmpty){
      searchController.text = query;
    }

    if(offset == 1) {
      _isLoading = true;
      notifyListeners();
    }

    ApiResponseModel apiResponse = await searchProductServiceInterface!.getSearchProductList(query, categoryIds, brandIds, authorIds, publishingIds, sort, priceMin, priceMax, offset, _productTypeIndex == 0 ? 'all' : _productTypeIndex == 1 ? 'physical' : 'digital');
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      if(offset == 1) {
        searchedProduct = null;
        if(ProductModel.fromJson(apiResponse.response!.data).products != null) {
          searchedProduct = ProductModel.fromJson(apiResponse.response!.data);
          if(searchedProduct?.minPrice != null){
            minFilterValue = searchedProduct!.minPrice!;
          }
          if(searchedProduct?.maxPrice != null){
            maxFilterValue = searchedProduct!.maxPrice!;
          }
        }
        if(offset == 1) {
          _isLoading = false;
          notifyListeners();
        }
      }else{
        if(ProductModel.fromJson(apiResponse.response!.data).products != null){
          searchedProduct?.products?.addAll(ProductModel.fromJson(apiResponse.response!.data).products!) ;
          searchedProduct?.offset = (ProductModel.fromJson(apiResponse.response!.data).offset) ;
          searchedProduct?.totalSize = (ProductModel.fromJson(apiResponse.response!.data).totalSize) ;
        }
      }
    } else {
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
  }


  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();

  SuggestionModel? suggestionModel;
  List<String> nameList = [];
  List<int> idList = [];
  Future<void> getSuggestionProductName(String name) async {

    ApiResponseModel apiResponse = await searchProductServiceInterface!.getSearchProductName(name);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      nameList = [];
      idList = [];
      suggestionModel = SuggestionModel.fromJson(apiResponse.response?.data);
      for(int i=0; i< suggestionModel!.products!.length; i++){
        nameList.add(suggestionModel!.products![i].name!);
        idList.add(suggestionModel!.products![i].id!);
      }
    }
    notifyListeners();
  }

  void initHistoryList() {
    _historyList = [];
    _historyList.addAll(searchProductServiceInterface!.getSavedSearchProductName());
  }

  int selectedSearchedProductId = 0;
  void setSelectedProductId(int index, int? compareId){
    if(suggestionModel!.products!.isNotEmpty){
      selectedSearchedProductId = suggestionModel!.products![index].id!;
    }
    if(compareId != null){
      Provider.of<CompareController>(Get.context!, listen: false).replaceCompareList(compareId ,selectedSearchedProductId);
    }else{
      Provider.of<CompareController>(Get.context!, listen: false).addCompareList(selectedSearchedProductId);
    }
    notifyListeners();
  }

  void saveSearchAddress(String searchAddress) async {
    searchProductServiceInterface!.saveSearchProductName(searchAddress);
    if (!_historyList.contains(searchAddress)) {
      _historyList.add(searchAddress);
    }
    notifyListeners();
  }

  void removeSearchAddress(int? index) async {
    _historyList.removeAt(index!);
    searchProductServiceInterface!.clearSavedSearchProductName();
    for(int i =0; i<_historyList.length; i++ ) {
      searchProductServiceInterface!.saveSearchProductName(_historyList[i]);
    }
    notifyListeners();
  }

  void clearSearchAddress() async {
    searchProductServiceInterface!.clearSavedSearchProductName();
    _historyList = [];
    notifyListeners();
  }

  void setInitialFilerData() {
    _filterIndex = 0;
  }


  Future<void> getAuthorList(int? sellerId) async {
    ApiResponseModel apiResponse = await searchProductServiceInterface!.getAuthorList(sellerId);

    if(sellerId != null && apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _sellerAuthorsList = [];

      apiResponse.response!.data.forEach((author) {
        _sellerAuthorsList!.add(AuthorModel.fromJson(author));
      });
    } else if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _authorsList = [];

      apiResponse.response!.data.forEach((author) {
        _authorsList!.add(AuthorModel.fromJson(author));
      });
    }
    notifyListeners();
  }

  Future<void> getPublishingHouseList(int? sellerId) async {
    ApiResponseModel apiResponse = await searchProductServiceInterface!.getPublishingHouse(sellerId);
    if(sellerId != null && apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _sellerPublishingHouseList = [];
      apiResponse.response!.data.forEach((house) {
        _sellerPublishingHouseList!.add(AuthorModel.fromJson(house));
      });
    } else if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _publishingHouseList = [];
      apiResponse.response?.data.forEach((house) {
        _publishingHouseList?.add(AuthorModel.fromJson(house));
      });
    }
    notifyListeners();
  }

  void checkedToggleAuthors(int index, bool formShop) {
    if(formShop) {
      _sellerAuthorsList![index].isChecked = !_sellerAuthorsList![index].isChecked!;

      if(_sellerAuthorsList![index].isChecked ?? false) {
        if(!_selectedSellerAuthorIds.contains(_sellerAuthorsList![index].id)) {
          _selectedSellerAuthorIds.add(_sellerAuthorsList![index].id!);
        }
      }else {
        _selectedSellerAuthorIds.remove(_sellerAuthorsList![index].id!);
      }
    } else {
      _authorsList![index].isChecked = !_authorsList![index].isChecked!;

      if(_authorsList![index].isChecked ?? false) {
        if(!_selectedAuthorIds.contains(_authorsList![index].id)) {
          _selectedAuthorIds.add(_authorsList![index].id!);
        }
      }else {
        _selectedAuthorIds.remove(_authorsList![index].id!);
      }
    }
    notifyListeners();
  }



  void checkedTogglePublishingHouse(int index, bool fromShop, {bool fromHomePage = false}) {
    if(fromHomePage){
      _sellerPublishingHouseIds = [];
      _publishingHouseList?.map((house) {
        house.isChecked = false;
      }).toList();
    }

    if(fromShop){
      _sellerPublishingHouseList![index].isChecked = !_sellerPublishingHouseList![index].isChecked!;

      if(_sellerPublishingHouseList![index].isChecked ?? false) {
        if(!_sellerPublishingHouseIds.contains(_sellerPublishingHouseList![index].id!)) {
          _sellerPublishingHouseIds.add(_sellerPublishingHouseList![index].id!);
        }
      }else {
        _sellerPublishingHouseIds.remove(_sellerPublishingHouseList![index].id!);
      }
    }else{
      _publishingHouseList![index].isChecked = !_publishingHouseList![index].isChecked!;
      if(_publishingHouseList![index].isChecked ?? false) {
        if(!_publishingHouseIds.contains(_publishingHouseList![index].id)) {
          _publishingHouseIds.add(_publishingHouseList![index].id!);
        }
      }else {
        _publishingHouseIds.remove(_publishingHouseList![index].id!);
      }
    }
    notifyListeners();
  }

  void setProductTypeIndex(int index, bool notify) {
    _productTypeIndex = index;
    if(notify) {
      notifyListeners();
    }
  }

  void clearSellerAuthorHouse() {
    _selectedSellerAuthorIds = [];
    _sellerAuthorsList =[];
    _sellerPublishingHouseList = [];
    _sellerPublishingHouseIds = [];
  }

  Future<void> resetChecked(int? id, bool fromShop) async{
    if(fromShop){
      getAuthorList(id);
      getPublishingHouseList(id);

    }else{
      getAuthorList(null);
      getPublishingHouseList(null);
    }
  }

}
