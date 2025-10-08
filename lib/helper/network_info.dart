import 'dart:async';


import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:provider/provider.dart';

class NetworkInfo {
  final Connectivity connectivity;
  NetworkInfo(this.connectivity);


  Future<bool> get isConnected async {
    List<ConnectivityResult> result = await connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.wifi)  || result.contains(ConnectivityResult.mobile);
  }


  static void checkConnectivity(BuildContext context) {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      if(Provider.of<SplashController>(Get.context!, listen: false).firstTimeConnectionCheck) {
        Provider.of<SplashController>(Get.context!, listen: false).setFirstTimeConnectionCheck(false);
      }else {
        bool isConnected = result.contains(ConnectivityResult.wifi)  || result.contains(ConnectivityResult.mobile);
        !isConnected ? const SizedBox() : ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
        ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(
          backgroundColor: !isConnected ? Colors.red : Colors.green,
          duration: Duration(seconds: !isConnected ? 6000 : 3),
          content: Text(
            !isConnected ? getTranslated('no_connection', Get.context!)! : getTranslated('connected', Get.context!)!,
            textAlign: TextAlign.center,
          ),
        ));
      }
    });
  }
}
