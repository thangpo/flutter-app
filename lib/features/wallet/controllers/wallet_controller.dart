import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/domain/models/wallet_transaction_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/domain/models/wallet_bonus_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/domain/services/wallet_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/screens/add_fund_to_wallet_screen.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';

class WalletController extends ChangeNotifier {
  final WalletServiceInterface walletServiceInterface;
  WalletController({required this.walletServiceInterface});

  bool _isLoading = false;
  bool _firstLoading = false;
  bool _isConvert = false;
  bool get isConvert => _isConvert;
  bool get isLoading => _isLoading;
  bool get firstLoading => _firstLoading;
  int? _transactionPageSize;
  int? get transactionPageSize=> _transactionPageSize;
  WalletTransactionModel? _walletTransactionModel;
  WalletTransactionModel? get walletTransactionModel => _walletTransactionModel;

  DateTime? _startDate;
  DateTime? get startDate => _startDate;

  DateTime? _endDate;
  DateTime? get endDate => _endDate;

  String? _selectedFilterBy;
  String? get selectedFilterBy => _selectedFilterBy;

  Set<String>? _selectedEarnByList;
  Set<String>? get selectedEarnByList => _selectedEarnByList;





  Future<void> getTransactionList(int offset, {
    bool reload = false,
    bool isUpdate = true,
    String? filterBy,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? transactionTypes,

  }) async {
    if(reload || offset == 1) {
      _walletTransactionModel = null;

      if(isUpdate) {
        notifyListeners();
      }
    }

    ApiResponseModel apiResponse = await walletServiceInterface.getList(
      offset : offset, filterBy: filterBy, startDate: startDate,
      endDate: endDate, transactionTypes: transactionTypes,
    );

    if (apiResponse.response?.data != null && apiResponse.response?.statusCode == 200) {
      if(offset == 1) {
        _walletTransactionModel = WalletTransactionModel.fromJson(apiResponse.response?.data);
      }else {
        _walletTransactionModel?.offset  = WalletTransactionModel.fromJson(apiResponse.response?.data).offset;
        _walletTransactionModel?.totalWalletBalance  = WalletTransactionModel.fromJson(apiResponse.response?.data).totalWalletBalance;
        _walletTransactionModel?.totalSize  = WalletTransactionModel.fromJson(apiResponse.response?.data).totalSize;
        _walletTransactionModel?.walletTransactionList?.addAll(WalletTransactionModel.fromJson(apiResponse.response?.data).walletTransactionList ?? []);

      }

    } else {
      _walletTransactionModel?.walletTransactionList = [];
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }


  void showBottomLoader() {
    _isLoading = true;
    notifyListeners();
  }

  void removeFirstLoading() {
    _firstLoading = true;
    notifyListeners();
  }
  Future <void> addFundToWallet(String amount, String paymentMethod) async {
    _isConvert = true;
    notifyListeners();
    ApiResponseModel apiResponse = await walletServiceInterface.addFundToWallet(amount, paymentMethod);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _isConvert = false;
      Navigator.pushReplacement(Get.context!, MaterialPageRoute(builder: (_) =>
          AddFundToWalletScreen(url: apiResponse.response?.data['redirect_link'])));
    }else if (apiResponse.response?.statusCode == 202){
      showCustomSnackBar("Minimum= ${PriceConverter.convertPrice(Get.context!, double.tryParse('${apiResponse.response?.data['minimum_amount']}') )} and Maximum=${PriceConverter.convertPrice(Get.context!, double.tryParse('${apiResponse.response?.data['maximum_amount']}'))}" , Get.context!);
    }else{
      _isConvert = false;
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }



  WalletBonusModel? walletBonusModel;
  Future<void> getWalletBonusBannerList() async {
    ApiResponseModel apiResponse = await walletServiceInterface.getWalletBonusBannerList();
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      walletBonusModel = WalletBonusModel.fromJson(apiResponse.response?.data);
    } else {
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
  }

  int currentIndex = 0;
  void setCurrentIndex(int index) {
    currentIndex = index;
    notifyListeners();
  }


  Future<void> setSelectedDate({required DateTime? startDate, required DateTime? endDate}) async {
    _startDate = startDate;
    _endDate = endDate;
    notifyListeners();
  }


  void setSelectedProductType({String? type, bool isUpdate = true}){
    _selectedFilterBy = type;

    if(isUpdate){
      notifyListeners();
    }
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

    _selectedFilterBy = _walletTransactionModel?.filterBy;
    _selectedEarnByList = _walletTransactionModel?.transactionTypes?.toSet();

    _startDate = _walletTransactionModel?.startDate;
    _endDate = _walletTransactionModel?.endDate;


  }


}
