import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/animated_custom_dialog_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/order_place_dialog_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';

class DigitalPaymentScreen extends StatefulWidget {
  final String url;
  final bool fromWallet;
  const DigitalPaymentScreen({super.key, required this.url,  this.fromWallet = false});

  @override
  DigitalPaymentScreenState createState() => DigitalPaymentScreenState();
}

class DigitalPaymentScreenState extends State<DigitalPaymentScreen> {
  String? selectedUrl;
  double value = 0.0;
  final bool _isLoading = true;

  PullToRefreshController? pullToRefreshController;
  late MyInAppBrowser browser;

  @override
  void initState() {
    super.initState();
    selectedUrl = widget.url;
    _initData();
  }

  void _initData() async {
    browser = MyInAppBrowser(context);

    final settings = InAppBrowserClassSettings(
      browserSettings: InAppBrowserSettings(hideUrlBar: false),
      webViewSettings: InAppWebViewSettings(javaScriptEnabled: true, isInspectable: kDebugMode, useShouldOverrideUrlLoading: false, useOnLoadResource: false),
    );

    await browser.openUrlRequest(
      urlRequest: URLRequest(url: WebUri(selectedUrl ?? '')),
      settings: settings,
    );

  }



  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (val, _) => _exitApp(context),
      child: Scaffold(
        appBar: AppBar(title: const Text(''),backgroundColor: Theme.of(context).cardColor),
        body: Column(crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,children: [

            _isLoading ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor))) : const SizedBox.shrink()])),
    );
  }


  Future<void> _exitApp(BuildContext context) async {

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const DashBoardScreen()), (route) => false);

      showAnimatedDialog(
        context,
        OrderPlaceDialogWidget(
          icon: Icons.clear,
          title: getTranslated('payment_cancelled', context),
          description: getTranslated('your_payment_cancelled', context),
          isFailed: true,
        ),
        dismissible: false,
        willFlip: true,
      );
    });
  }

}



class MyInAppBrowser extends InAppBrowser {

  final BuildContext context;

  MyInAppBrowser(this.context,  {
    super.windowId,
    super.initialUserScripts,
  });

  bool _canRedirect = true;

  @override
  Future onBrowserCreated() async {
    if (kDebugMode) {
      print("\n\nBrowser Created!\n\n");
    }
  }

  @override
  Future onLoadStart(url) async {
    if (kDebugMode) {
      print("\n\nStarted: $url\n\n");
    }
    bool isNewUser = getIsNewUser(url.toString());
    _pageRedirect(url.toString(), isNewUser);
  }

  @override
  Future onLoadStop(url) async {
    pullToRefreshController?.endRefreshing();
    if (kDebugMode) {
      print("\n\nStopped: $url\n\n");
    }
    bool isNewUser = getIsNewUser(url.toString());
    _pageRedirect(url.toString(), isNewUser);
  }

  @override
  void onLoadError(url, code, message) {
    pullToRefreshController?.endRefreshing();
    if (kDebugMode) {
      print("Can't load [$url] Error: $message");
    }
  }

  @override
  void onProgressChanged(progress) {
    if (progress == 100) {
      pullToRefreshController?.endRefreshing();
    }
    if (kDebugMode) {
      print("Progress: $progress");
    }
  }


  bool getIsNewUser(String url) {
    List<String> parts = url.split('?');
    if (parts.length < 2) {
      return false;
    }

    String queryString = parts[1];
    List<String> queryParams = queryString.split('&');

    for (String param in queryParams) {
      List<String> keyValue = param.split('=');
      if (keyValue.length == 2) {
        if (keyValue[0] == 'new_user') {
          return keyValue[1] == '1';
        }
      }
    }
    return false;
  }

  @override
  void onExit() {
    if(_canRedirect) {
      _canRedirect = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const DashBoardScreen()), (route) => false);


        showAnimatedDialog(context, OrderPlaceDialogWidget(
          icon: Icons.clear,
          title: getTranslated('payment_failed', context),
          description: getTranslated('your_payment_failed', context),
          isFailed: true,
        ), dismissible: false, willFlip: true);
      });
    }

    if (kDebugMode) {
      print("\n\nBrowser closed!\n\n");
    }
  }

  @override
  Future<NavigationActionPolicy> shouldOverrideUrlLoading(navigationAction) async {
    if (kDebugMode) {
      print("\n\nOverride ${navigationAction.request.url}\n\n");
    }
    return NavigationActionPolicy.ALLOW;
  }

  @override
  void onLoadResource(resource) {
  }

  @override
  void onConsoleMessage(consoleMessage) {
    if (kDebugMode) {
      print("""
    console output:
      message: ${consoleMessage.message}
      messageLevel: ${consoleMessage.messageLevel.toValue()}
   """);
    }
  }

  void _pageRedirect(String url, bool isNewUser) {
    if (_canRedirect) {
      final isSuccess = url.contains('success') && url.contains(AppConstants.baseUrl);
      final isFailed = url.contains('fail') && url.contains(AppConstants.baseUrl);
      final isCancel = url.contains('cancel') && url.contains(AppConstants.baseUrl);

      if (isSuccess || isFailed || isCancel) {
        _canRedirect = false;
        close();
      }

      if (isSuccess || isFailed || isCancel) {
        final icon = isSuccess ? Icons.done : Icons.clear;
        final title = getTranslated(
          isSuccess
              ? (isNewUser ? 'order_placed_Account_Created' : 'order_placed')
              : isFailed
              ? 'payment_failed'
              : 'payment_cancelled',
          context,
        );
        final description = getTranslated(
          isSuccess
              ? 'your_order_placed'
              : isFailed
              ? 'your_payment_failed'
              : 'your_payment_cancelled',
          context,
        );
        final isDialogFailed = !isSuccess;


        WidgetsBinding.instance.addPostFrameCallback((_) {

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashBoardScreen()), (route) => false);

          showAnimatedDialog(
            context,
            OrderPlaceDialogWidget(
              icon: icon,
              title: title,
              description: description,
              isFailed: isDialogFailed,
            ),
            dismissible: false,
            willFlip: true,
          );

        });
      }
    }
  }

}