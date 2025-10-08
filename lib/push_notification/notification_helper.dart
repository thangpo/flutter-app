import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/demo_reset_dialog_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/controllers/address_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/login_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/maintenance/maintenance_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/screens/order_details_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/screens/product_details_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/restock/controllers/restock_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/restock/widgets/restock_bottom_sheet.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/controllers/wallet_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/screens/wallet_screen.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/push_notification/models/notification_body.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/screens/inbox_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/notification/screens/notification_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class NotificationHelper {


  // {is_read: 0, image: , body: new-messages.demo_data_is_being_reset_to_default., type: demo_reset, title: Demo reset alert, order_id: }

  static Future<void> initialize(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    var androidInitialize = const AndroidInitializationSettings('notification_icon');
    var iOSInitialize = const DarwinInitializationSettings();
    var initializationsSettings = InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    flutterLocalNotificationsPlugin.initialize(initializationsSettings, onDidReceiveNotificationResponse: (NotificationResponse load) async {
      try{
        log("tyyuuyypee88=11=>$load");
        log("==Payload=11=>${load.payload}");
        NotificationBody payload;

        if(load.payload!.isNotEmpty) {
          payload = NotificationBody.fromJson(jsonDecode(load.payload!));
          log("-----------tyyuuyypee88==>${payload.type}");
          log("=============Payload==>${load.payload}");
          if(payload.type == 'order') {
            Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (BuildContext context) =>  OrderDetailsScreen(orderId: payload.orderId, isNotification: true)));
          } else if(payload.type == 'wallet') {
            Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (BuildContext context) =>  const WalletScreen()));
          } else if(payload.type == 'chatting') {
            Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (BuildContext context) =>  InboxScreen(isBackButtonExist: true, initIndex: payload.messageKey ==  'message_from_delivery_man' ? 0 : 1, fromNotification: true)));
          } else if(payload.type == 'product_restock_update') {
            Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (BuildContext context) =>  ProductDetails(productId: int.parse(payload.productId!), slug: payload.slug, isNotification: true)));
          } else if(payload.type == 'referral_code_used'){

          } else{
            Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (BuildContext context) =>  const NotificationScreen(fromNotification: true,)));
          }
        }
      }catch (_) {}
      return;
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (kDebugMode) {
        print("-----------onMessage: ${message.notification?.title}/${message.notification?.body}/${message.notification?.titleLocKey}");
        print("---------onMessage type: ${message.data['type']}/${message.data}");
        if(message.data['type'] == "block"){
            Provider.of<AuthController>(Get.context!,listen: false).clearSharedData();
            Provider.of<AddressController>(Get.context!, listen: false).getAddressList();
            Navigator.of(Get.context!).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);

        }
      }

      if(message.data['type'] == 'referral_code_used'){
        await Provider.of<WalletController>(Get.context!, listen: false).getTransactionList(1);
      }

      if(message.data['type'] == 'maintenance_mode') {
        final SplashController splashProvider = Provider.of<SplashController>(Get.context!,listen: false);
        await splashProvider.initConfig(Get.context!, null, null);

        ConfigModel? config = Provider.of<SplashController>(Get.context!,listen: false).configModel;

        bool isMaintenanceRoute = Provider.of<SplashController>(Get.context!,listen: false).isMaintenanceModeScreen();

        if(config?.maintenanceModeData?.maintenanceStatus == 1 && (config?.maintenanceModeData?.selectedMaintenanceSystem?.customerApp == 1)) {
          Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(
            builder: (_) => const MaintenanceScreen(),
            settings: const RouteSettings(name: 'MaintenanceScreen'),
          ));
        }else if (config?.maintenanceModeData?.maintenanceStatus == 0 && isMaintenanceRoute) {
          Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (_) => const DashBoardScreen()));
        }
      }

      if(message.data['type'] != 'maintenance_mode' || message.data['type'] != 'product_restock_update') {
        NotificationHelper.showNotification(message, flutterLocalNotificationsPlugin, false);
      }

      if(message.data['type'] == 'product_restock_update' && !Provider.of<RestockController>(Get.context!, listen: false).isBottomSheetOpen){
        NotificationBody notificationBody = convertNotification(message.data);
        Provider.of<RestockController>(Get.context!, listen: false).setBottomSheetOpen(true);
        final result = await showModalBottomSheet(context: Get.context!, isScrollControlled: true,
          backgroundColor: Theme.of(Get.context!).primaryColor.withValues(alpha:0),
          builder: (con) => RestockSheetWidget(notificationBody: notificationBody),
        );

        if (result == null) {
          Provider.of<RestockController>(Get.context!, listen: false).setBottomSheetOpen(false);
        } else {
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      if (kDebugMode) {
        print("onOpenApp: ${message.notification!.title}/${message.data}/${message.notification!.titleLocKey}");
      }
      if(message.data['type'] == 'demo_reset') {
        showDialog(context: Get.context!, builder: (context) => const Dialog(
          backgroundColor: Colors.transparent,
          child: DemoResetDialogWidget()));
      }
      try{
        if(message.data.isNotEmpty) {
          NotificationBody notificationBody = convertNotification(message.data);
          if(notificationBody.type == 'order') {
            Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (BuildContext context) =>  OrderDetailsScreen(orderId: notificationBody.orderId, isNotification: true,)));
          } else if(notificationBody.type == 'wallet') {
            Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (BuildContext context) =>  const WalletScreen()));
          } else if(notificationBody.type == 'notification') {
            Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (BuildContext context) =>  const NotificationScreen(fromNotification: true,)));
          } else if(notificationBody.type == 'chatting') {
            Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (BuildContext context) =>  InboxScreen(isBackButtonExist: true, fromNotification: true, initIndex: notificationBody.messageKey ==  'message_from_delivery_man' ? 0 : 1)));
          } else if(notificationBody.type == 'product_restock_update') {
            Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (BuildContext context) =>  ProductDetails(productId: int.parse(notificationBody.productId!), slug: notificationBody.slug, isNotification: true)));
          } else {
            Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (BuildContext context) =>  const NotificationScreen(fromNotification: true,)));
          }
        }
      }catch (_) {}

      if(message.data['type'] == 'maintenance_mode') {
        final SplashController splashProvider = Provider.of<SplashController>(Get.context!,listen: false);
        await splashProvider.initConfig(Get.context!, null, null);

        ConfigModel? config = Provider.of<SplashController>(Get.context!,listen: false).configModel;

        bool isMaintenanceRoute = Provider.of<SplashController>(Get.context!,listen: false).isMaintenanceModeScreen();

        if(config?.maintenanceModeData?.maintenanceStatus == 1 && (config?.maintenanceModeData?.selectedMaintenanceSystem?.customerApp == 1)) {
          Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(
            builder: (_) => const MaintenanceScreen(),
            settings: const RouteSettings(name: 'MaintenanceScreen'),
          ));
        }else if (config?.maintenanceModeData?.maintenanceStatus == 0 && isMaintenanceRoute) {
          Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (_) => const DashBoardScreen()));
        }
      }

    });
  }

  static Future<void> showNotification(RemoteMessage message, FlutterLocalNotificationsPlugin fln, bool data) async {
    if(!Platform.isIOS) {
      String? title;
      String? body;
      String? orderID;
      String? image;
      NotificationBody notificationBody = convertNotification(message.data);
      if(data) {
        title = message.data['title'];
        body = message.data['body'];
        orderID = message.data['order_id'];
        image = (message.data['image'] != null && message.data['image'].isNotEmpty)
            ? message.data['image'].startsWith('http') ? message.data['image']
            : '${AppConstants.baseUrl}/storage/app/public/notification/${message.data['image']}' : null;
      }else {
        title = message.notification?.title;
        body = message.notification?.body;
        orderID = message.notification?.titleLocKey;
        if(Platform.isAndroid) {
          image = (message.notification?.android?.imageUrl != null && message.notification!.android!.imageUrl!.isNotEmpty)
              ? message.notification!.android!.imageUrl!.startsWith('http') ? message.notification!.android!.imageUrl
              : '${AppConstants.baseUrl}/storage/app/public/notification/${message.notification?.android?.imageUrl}' : null;
        }else if(Platform.isIOS) {
          image = (message.notification?.apple?.imageUrl != null && message.notification!.apple!.imageUrl!.isNotEmpty)
              ? message.notification!.apple!.imageUrl!.startsWith('http') ? message.notification?.apple?.imageUrl
              : '${AppConstants.baseUrl}/storage/app/public/notification/${message.notification!.apple!.imageUrl}' : null;
        }
      }

      if(image != null && image.isNotEmpty) {
        try{
          await showBigPictureNotificationHiddenLargeIcon(title, body, orderID, notificationBody, image, fln);
        }catch(e) {
          await showBigTextNotification(title, body!, orderID, notificationBody, fln);
        }
      }else {
        await showBigTextNotification(title, body!, orderID, notificationBody, fln);
      }
    }
  }

  static Future<void> showTextNotification(String title, String body, String orderID, NotificationBody? notificationBody, FlutterLocalNotificationsPlugin fln) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      '6valley', '6valley', playSound: true,
      importance: Importance.max, priority: Priority.max, sound: RawResourceAndroidNotificationSound('notification'),
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics, payload: notificationBody != null ? jsonEncode(notificationBody.toJson()) : null);
  }

  static Future<void> showBigTextNotification(String? title, String body, String? orderID, NotificationBody? notificationBody, FlutterLocalNotificationsPlugin fln) async {
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body, htmlFormatBigText: true,
      contentTitle: title, htmlFormatContentTitle: true,
    );
    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      '6valley', '6valley', importance: Importance.max,
      styleInformation: bigTextStyleInformation, priority: Priority.max, playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics, payload: notificationBody != null ? jsonEncode(notificationBody.toJson()) : null);
  }

  static Future<void> showBigPictureNotificationHiddenLargeIcon(String? title, String? body, String? orderID, NotificationBody? notificationBody, String image, FlutterLocalNotificationsPlugin fln) async {
    final String largeIconPath = await _downloadAndSaveFile(image, 'largeIcon');
    final String bigPicturePath = await _downloadAndSaveFile(image, 'bigPicture');
    final BigPictureStyleInformation bigPictureStyleInformation = BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath), hideExpandedLargeIcon: true,
      contentTitle: title, htmlFormatContentTitle: true,
      summaryText: body, htmlFormatSummaryText: true,
    );
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      '6valley', '6valley',
      largeIcon: FilePathAndroidBitmap(largeIconPath), priority: Priority.max, playSound: true,
      styleInformation: bigPictureStyleInformation, importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics, payload: notificationBody != null ? jsonEncode(notificationBody.toJson()) : null);
  }

  static Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  static NotificationBody convertNotification(Map<String, dynamic> data){
    if(data['type'] == 'notification') {
      return NotificationBody(type: 'notification');
    }else if(data['type'] == 'order') {
      return NotificationBody(type: 'order', orderId: int.parse(data['order_id']));
    }else if(data['type'] == 'wallet') {
      return NotificationBody(type: 'wallet');
    }else if(data['type'] == 'block') {
      return NotificationBody(type: 'block');
    }else if(data['type'] == 'product_restock_update') {
      return NotificationBody(type: 'product_restock_update', title: data['title'], image: data['image'], productId: data['product_id'].toString(), slug: data['slug'], status: data['status']);
    } else if(data['type'] == 'referral_code_used') {
      return NotificationBody(type: 'referral_code_used', title: data['title'], messageKey: data['body'], image: data['image'], productId: data['product_id'].toString(), slug: data['slug'], status: data['status']);
    } else {
      return NotificationBody(type: 'chatting', messageKey: data['message_key']);
    }
  }

}

@pragma('vm:entry-point')
Future<dynamic> myBackgroundMessageHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print("onBackground: ${message.notification!.title}/${message.notification!.body}/${message.notification!.titleLocKey}");
  }
  // var androidInitialize = new AndroidInitializationSettings('notification_icon');
  // var iOSInitialize = new IOSInitializationSettings();
  // var initializationsSettings = new InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
  // FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  // flutterLocalNotificationsPlugin.initialize(initializationsSettings);
  // NotificationHelper.showNotification(message, flutterLocalNotificationsPlugin, true);
}