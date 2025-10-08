import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/enums/data_source_enum.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/domain/models/category_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/domain/services/category_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/seller_product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/helper/data_sync_helper.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/features/brand/controllers/brand_controller.dart';
import 'package:provider/provider.dart';

class CategoryController extends ChangeNotifier {
  final CategoryServiceInterface? categoryServiceInterface;
  CategoryController({required this.categoryServiceInterface});



  final List<CategoryModel> _filteredCategoryList = [];
  final List<CategoryModel> _categoryList = [];
  final List<CategoryModel> _sellerWiseCategoryList = [];
  int? _categorySelectedIndex;

  List<CategoryModel> get categoryList => _categoryList;
  List<CategoryModel> get sellerWiseCategoryList => _sellerWiseCategoryList;
  List<CategoryModel> get filteredCategoryList => _filteredCategoryList;

  int? get categorySelectedIndex => _categorySelectedIndex;

  Future<void> getCategoryList(bool reload) async {
    if(_categoryList.isEmpty || reload) {
      await DataSyncHelper.fetchAndSyncData(
        fetchFromLocal: ()=> categoryServiceInterface!.getList(source: DataSourceEnum.local),
        fetchFromClient: ()=> categoryServiceInterface!.getList(source: DataSourceEnum.client),
        onResponse: (data, source) {
          if(data != null) {
            _categoryList.clear();

            data.forEach((category) => _categoryList.add(CategoryModel.fromJson(category)));
            _categorySelectedIndex = 0;

            onUpdateFilteredCategoryList(isSeller: false);
            notifyListeners();

          }
        },
      );
    }

  }


  void onUpdateFilteredCategoryList({required bool isSeller}) {
    _filteredCategoryList.clear();
    _filteredCategoryList.addAll(isSeller ? _sellerWiseCategoryList : _categoryList);
  }




  Future<void> getSellerWiseCategoryList(int sellerId) async {
      ApiResponseModel apiResponse = await categoryServiceInterface!.getSellerWiseCategoryList(sellerId);

      if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
        _sellerWiseCategoryList.clear();
        apiResponse.response!.data.forEach((category) => _sellerWiseCategoryList.add(CategoryModel.fromJson(category)));

      } else {
        ApiChecker.checkApi( apiResponse);
      }

      onUpdateFilteredCategoryList(isSeller: true);

      notifyListeners();

  }

  final List<int> _selectedCategoryIds = [];
  List<int> get selectedCategoryIds => _selectedCategoryIds;

  void checkedToggleCategory(int index){
    _filteredCategoryList[index].isSelected = !_filteredCategoryList[index].isSelected!;

    if(_filteredCategoryList[index].isSelected ?? false) {
      if(!_selectedCategoryIds.contains(index)) {
        _selectedCategoryIds.add(index);
      }

    }else {
      _selectedCategoryIds.remove(index);

      _onDisableSubCategorySelection(index);


    }
    notifyListeners();
  }

  void _onDisableSubCategorySelection(int index) {
    _filteredCategoryList[index].subCategories?.forEach((subCategory){
      subCategory.isSelected = false;
    });
  }

  void checkedToggleSubCategory(int index, int subCategoryIndex){
    _filteredCategoryList[index].subCategories![subCategoryIndex].isSelected = !_filteredCategoryList[index].subCategories![subCategoryIndex].isSelected!;
    notifyListeners();
  }

  Future<void> resetChecked(int? id, bool fromShop) async {
    if(fromShop){
      await getSellerWiseCategoryList(id!);
      Provider.of<BrandController>(Get.context!, listen: false).getSellerWiseBrandList(id);
      Provider.of<SellerProductController>(Get.context!, listen: false).getSellerProductList(id.toString(), 1, "");
    }else{
      await getCategoryList(true);
      Provider.of<BrandController>(Get.context!, listen: false).getBrandList(offset: 1);
    }

  }

  void onChangeSelectedIndex(int selectedIndex, {bool isUpdate = true}) {
    _categorySelectedIndex = selectedIndex;
    if(isUpdate){
      notifyListeners();
    }
  }
}
