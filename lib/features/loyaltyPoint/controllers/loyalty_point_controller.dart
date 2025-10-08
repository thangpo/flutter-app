import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/loyaltyPoint/domain/models/loyalty_point_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/loyaltyPoint/domain/services/loyalty_point_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';

class LoyaltyPointController extends ChangeNotifier {
  final LoyaltyPointServiceInterface loyaltyPointServiceInterface;
  LoyaltyPointController({required this.loyaltyPointServiceInterface});


  bool _isConvert = false;
  bool get isConvert => _isConvert;

  LoyaltyPointModel? _loyaltyPointModel;
  LoyaltyPointModel? get loyaltyPointModel => _loyaltyPointModel;

  String? _selectedFilterBy;
  String? get selectedFilterBy => _selectedFilterBy;

  DateTime? _startDate;
  DateTime? get startDate => _startDate;

  DateTime? _endDate;
  DateTime? get endDate => _endDate;

  Set<String>? _selectedEarnByList;
  Set<String>? get selectedEarnByList => _selectedEarnByList;




  Future<void> getLoyaltyPointList(BuildContext context, int offset, {
    bool reload = false,
    bool isUpdate = true,
    String? filterBy,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? transactionTypes,

  }) async {
    if(reload || offset == 1) {
      _loyaltyPointModel = null;

      if(isUpdate) {
        notifyListeners();
      }
    }

    ApiResponseModel apiResponse = await loyaltyPointServiceInterface.getList(
      offset : offset, filterBy: filterBy, startDate: startDate,
      endDate: endDate, transactionTypes: transactionTypes,
    );

    if (apiResponse.response?.data != null && apiResponse.response?.statusCode == 200) {
      if(offset == 1) {
        _loyaltyPointModel = LoyaltyPointModel.fromJson(apiResponse.response?.data);
      }else {
        _loyaltyPointModel?.offset = LoyaltyPointModel.fromJson(apiResponse.response?.data).offset;
        _loyaltyPointModel?.totalLoyaltyPoint = LoyaltyPointModel.fromJson(apiResponse.response?.data).totalLoyaltyPoint;
        _loyaltyPointModel?.loyaltyPointList?.addAll(LoyaltyPointModel.fromJson(apiResponse.response?.data).loyaltyPointList ?? []);

      }

    } else {
      _loyaltyPointModel?.loyaltyPointList = [];
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
  }


  Future convertPointToCurrency(BuildContext context, int point) async {
    _isConvert = true;
    notifyListeners();
    ApiResponseModel apiResponse = await loyaltyPointServiceInterface.convertPointToCurrency(point);
    if (apiResponse.response != null && apiResponse.response?.statusCode == 200) {
      _isConvert = false;
      showCustomSnackBar("${getTranslated('point_converted_successfully', Get.context!)}", Get.context!, isError: false);
    }else{
      _isConvert = false;
      showCustomSnackBar("${getTranslated('point_converted_failed', Get.context!)}", Get.context!);
    }
    notifyListeners();
  }





  void setSelectedProductType({String? type, bool isUpdate = true}){
    _selectedFilterBy = type;

    if(isUpdate){
      notifyListeners();
    }
  }



  void setSelectedDate({required DateTime? startDate, required DateTime? endDate}) async {
    _startDate = startDate;
    _endDate = endDate;
    notifyListeners();
  }


  void onUpdateEarnBy(String value, {bool isUpdate = true}) {
    _selectedEarnByList ??= <String>{};

    // Toggle logic
    if (!_selectedEarnByList!.add(value)) {
      _selectedEarnByList!.remove(value);
    }

    if (isUpdate) {
      notifyListeners();
    }
  }

  void initFilterData(){

    _selectedFilterBy = _loyaltyPointModel?.filterBy;
    _selectedEarnByList = _loyaltyPointModel?.transactionTypes?.toSet();

    _startDate = _loyaltyPointModel?.startDate;
    _endDate = _loyaltyPointModel?.endDate;


  }



}
