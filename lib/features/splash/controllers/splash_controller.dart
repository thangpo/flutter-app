import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/data/local/cache_response.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/maintenance/maintenance_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/business_pages_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/services/splash_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/helper/app_globals.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/firebase_token_updater.dart';

class SplashController extends ChangeNotifier {
  final SplashServiceInterface? splashServiceInterface;
  SplashController({required this.splashServiceInterface});

  ConfigModel? _configModel;
  BaseUrls? _baseUrls;
  CurrencyList? _myCurrency;
  CurrencyList? _usdCurrency;
  CurrencyList? _defaultCurrency;
  int? _currencyIndex;
  bool _hasConnection = true;
  bool _fromSetting = false;
  bool _firstTimeConnectionCheck = true;
  bool _onOff = true;
  bool get onOff => _onOff;
  bool isConfigCall = false;

  ConfigModel? get configModel => _configModel;
  BaseUrls? get baseUrls => _baseUrls;
  CurrencyList? get myCurrency => _myCurrency;
  CurrencyList? get usdCurrency => _usdCurrency;
  CurrencyList? get defaultCurrency => _defaultCurrency;
  int? get currencyIndex => _currencyIndex;
  bool get hasConnection => _hasConnection;
  bool get fromSetting => _fromSetting;
  bool get firstTimeConnectionCheck => _firstTimeConnectionCheck;
  BuildContext? _buildContext;

  List<BusinessPageModel>? _defaultBusinessPages;
  List<BusinessPageModel>? get defaultBusinessPages => _defaultBusinessPages;

  List<BusinessPageModel>? _businessPages;
  List<BusinessPageModel>? get businessPages => _businessPages;

  Future<bool> initConfig(
    BuildContext context,
      Function(ConfigModel? configModel)? onLocalDataReceived,
      Function(ConfigModel? configModel)? onApiDataReceived,
      ) async {
   var configLocalData =  await database.getCacheResponseById(AppConstants.configUri);

   bool localMaintainanceMode = false;

   isConfigCall = false;

   if(configLocalData != null) {
     _configModel = ConfigModel.fromJson(jsonDecode(configLocalData.response));

     localMaintainanceMode = (_configModel?.maintenanceModeData?.maintenanceStatus == 1 && _configModel?.maintenanceModeData?.selectedMaintenanceSystem?.customerApp == 1);

     String? currencyCode = splashServiceInterface!.getCurrency();

     for(CurrencyList currencyList in _configModel!.currencyList!) {
       if(currencyList.id == _configModel!.systemDefaultCurrency) {
         if(currencyCode == null || currencyCode.isEmpty) {
           currencyCode = currencyList.code;
         }
         _defaultCurrency = currencyList;
       }
       if(currencyList.code == 'USD') {
         _usdCurrency = currencyList;
       }
     }
     getCurrencyData(currencyCode);

     if(onLocalDataReceived != null) {
       onLocalDataReceived(configModel);
     }

   }

    _hasConnection = true;
    ApiResponseModel apiResponse = await splashServiceInterface!.getConfig();
    bool isSuccess;
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      isSuccess = true;
      _configModel = ConfigModel.fromJson(apiResponse.response!.data);
      isConfigCall = true;

      _baseUrls = ConfigModel.fromJson(apiResponse.response!.data).baseUrls;

      _configModel?.hasLocaldb = configLocalData != null;

      _configModel?.localMaintenanceMode = localMaintainanceMode;

      if(onApiDataReceived != null) {
        onApiDataReceived(configModel);
      }


      String? currencyCode = splashServiceInterface!.getCurrency();

      try{
        await FirebaseMessaging.instance.subscribeToTopic(AppConstants.maintenanceModeTopic);
      }catch (e) {
        debugPrint("====FirebaseException===>>$e");
      }

      for(CurrencyList currencyList in _configModel!.currencyList!) {
        if(currencyList.id == _configModel!.systemDefaultCurrency) {
          if(currencyCode == null || currencyCode.isEmpty) {
            currencyCode = currencyList.code;
          }
          _defaultCurrency = currencyList;
        }
        if(currencyList.code == 'USD') {
          _usdCurrency = currencyList;
        }
      }
      getCurrencyData(currencyCode);

      if(_configModel?.maintenanceModeData?.maintenanceStatus == 0){
        if(_configModel?.maintenanceModeData?.selectedMaintenanceSystem?.customerApp == 1 ) {
          if(_configModel?.maintenanceModeData?.maintenanceTypeAndDuration?.maintenanceDuration == 'customize') {

            DateTime now = DateTime.now();
            DateTime specifiedDateTime = DateTime.parse(_configModel!.maintenanceModeData!.maintenanceTypeAndDuration!.startDate!);

            Duration difference = specifiedDateTime.difference(now);

            if(difference.inMinutes > 0 && (difference.inMinutes < 60 || difference.inMinutes == 60)){
              _startTimer(specifiedDateTime);
            }

          }
        }
      }

      if(configLocalData != null) {
        await database.updateCacheResponse(AppConstants.configUri, CacheResponseCompanion(
          endPoint: const Value(AppConstants.configUri),
          header: Value(jsonEncode(apiResponse.response!.headers.map)),
          response: Value(jsonEncode(apiResponse.response!.data)),
        ));
      } else {
        await database.insertCacheResponse(
          CacheResponseCompanion(
            endPoint: const Value(AppConstants.configUri),
            header: Value(jsonEncode(apiResponse.response!.headers.map)),
            response: Value(jsonEncode(apiResponse.response!.data)),
          ),
        );
      }
      _configModel = ConfigModel.fromJson(apiResponse.response!.data);

      isSuccess = true;
    } else {
      isSuccess = false;
      ApiChecker.checkApi(apiResponse);
      if(apiResponse.error.toString() == 'Connection to API server failed due to internet connection') {
        _hasConnection = false;
      }else{
        showCustomSnackBar(apiResponse.error.toString(), Get.context!);
      }
    }
    notifyListeners();

    return isSuccess;
  }


  void setFirstTimeConnectionCheck(bool isChecked) {
    _firstTimeConnectionCheck = isChecked;
  }

  void getCurrencyData(String? currencyCode) {
    for (var currency in _configModel!.currencyList!) {
      if(currencyCode == currency.code) {
        _myCurrency = currency;
        _currencyIndex = _configModel!.currencyList!.indexOf(currency);
        continue;
      }
    }
  }

  Future<void> getBusinessPagesList(String type) async {
    ApiResponseModel apiResponse = await splashServiceInterface!.getBusinessPages(type);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {

      if(type == 'default') {
        _defaultBusinessPages = [];
        apiResponse.response?.data.forEach((data) { _defaultBusinessPages?.add(BusinessPageModel.fromJson(data));});
      } else {
        _businessPages = [];
        apiResponse.response?.data.forEach((data) { _businessPages?.add(BusinessPageModel.fromJson(data));});
      }

    } else {
      ApiChecker.checkApi( apiResponse);
    }

    notifyListeners();
  }



  void setCurrency(int index) {
    splashServiceInterface!.setCurrency(_configModel!.currencyList![index].code!);
    getCurrencyData(_configModel!.currencyList![index].code);
    notifyListeners();
  }

  void initSharedPrefData() {
    splashServiceInterface!.initSharedData();
  }

  void setFromSetting(bool isSetting) {
    _fromSetting = isSetting;
  }

  bool? showIntro() {
    return splashServiceInterface!.showIntro();
  }

  void disableIntro() {
    splashServiceInterface!.disableIntro();
  }

  void changeAnnouncementOnOff(bool on){
    _onOff = !_onOff;
    notifyListeners();
  }


  void _startTimer (DateTime startTime) {
    Timer.periodic(const Duration(seconds: 30), (Timer timer) {

      DateTime now = DateTime.now();

      if (now.isAfter(startTime) || now.isAtSameMomentAs(startTime)) {
        timer.cancel();
        Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(
          builder: (_) => const MaintenanceScreen(),
          settings: const RouteSettings(name: 'MaintenanceScreen'),
        ));
      }

    });
  }

  void setMaintenanceContext(BuildContext context) {
    _buildContext = context;
  }

  void removeMaintenanceContext() {
    _buildContext = null;
  }

  bool isMaintenanceModeScreen() {
    if (_buildContext == null || configModel?.maintenanceModeData?.maintenanceStatus == 1) {
      return false;
    }
    return ModalRoute.of(_buildContext!)?.settings.name == 'MaintenanceScreen';
  }
}

