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
import 'package:flutter_sixvalley_ecommerce/main.dart'; // navigatorKey, flutterLocalNotificationsPlugin, Get
import 'package:flutter_sixvalley_ecommerce/push_notification/models/notification_body.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/screens/inbox_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/notification/screens/notification_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/push_navigation_helper.dart';

// gọi đến: auto navigate + attach controller
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/call_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/incoming_call_screen.dart';

class NotificationHelper {
  // tránh double navigate nếu FCM bắn liên tiếp
  static bool _callRouting = false;

  static Future<void> initialize(
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    // 🔔 Tạo Channel mặc định (Android 8+)
    const AndroidNotificationChannel defaultChannel =
        AndroidNotificationChannel(
      'vnshop247_channel',
      'VNShop247 Notifications',
      description: 'Kênh mặc định cho thông báo VNShop247',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(defaultChannel);

    var androidInitialize =
        const AndroidInitializationSettings('notification_icon');
    var iOSInitialize = const DarwinInitializationSettings();
    var initializationsSettings =
        InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // (Giữ helper này nếu sau này muốn dùng lại,
    //  hiện tại main.dart đã xử lý call_invite nên không gọi tới)
    Future<void> _openIncomingCallUI(Map<String, dynamic> data) async {
      final nav = navigatorKey.currentState;
      final ctx = nav?.overlay?.context ?? navigatorKey.currentContext;
      if (ctx == null) return;

      final callId = int.tryParse('${data['call_id'] ?? ''}');
      final media = (data['media']?.toString() == 'video') ? 'video' : 'audio';
      if (callId == null) return;

      try {
        final cc = Provider.of<CallController>(ctx, listen: false);
        cc.attachCall(callId: callId, mediaType: media);
      } catch (_) {}

      if (_callRouting) return;
      _callRouting = true;
      try {
        await nav!.push(
          MaterialPageRoute(
            builder: (_) => IncomingCallScreen(
              callId: callId,
              mediaType: media,
              callerName: (data['caller_name'] ?? 'Cuộc gọi đến').toString(),
              callerAvatar: data['caller_avatar']?.toString(),
            ),
          ),
        );
      } finally {
        _callRouting = false;
      }
    }

    // ===== FOREGROUND =====
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = message.data;
      final String t = (data['type'] ?? '').toString();

      // ⚠️ Social (WoWonder) → main.dart xử lý hiển thị riêng (payload = data)
      if (data.containsKey('api_status') || data.containsKey('detail')) {
        return;
      }

      // ✅ CUỘC GỌI TỚI: để main.dart xử lý hết
      if (t == 'call_invite' ||
          t == 'call_invite_group' ||
          (data.containsKey('call_id') && data.containsKey('media'))) {
        return;
      }

      if (kDebugMode) {
        print(
            "-----------onMessage: ${message.notification?.title}/${message.notification?.body}/${message.notification?.titleLocKey}");
        print("---------onMessage type: $t/$data");
        if (t == "block") {
          Provider.of<AuthController>(Get.context!, listen: false)
              .clearSharedData();
          Provider.of<AddressController>(Get.context!, listen: false)
              .getAddressList();
          Navigator.of(Get.context!).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }

      if (t == 'referral_code_used') {
        await Provider.of<WalletController>(Get.context!, listen: false)
            .getTransactionList(1);
      }

      if (t == 'maintenance_mode') {
        final SplashController splashProvider =
            Provider.of<SplashController>(Get.context!, listen: false);
        await splashProvider.initConfig(Get.context!, null, null);

        ConfigModel? config =
            Provider.of<SplashController>(Get.context!, listen: false)
                .configModel;

        bool isMaintenanceRoute =
            Provider.of<SplashController>(Get.context!, listen: false)
                .isMaintenanceModeScreen();

        if (config?.maintenanceModeData?.maintenanceStatus == 1 &&
            (config?.maintenanceModeData?.selectedMaintenanceSystem
                    ?.customerApp ==
                1)) {
          Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(
            builder: (_) => const MaintenanceScreen(),
            settings: const RouteSettings(name: 'MaintenanceScreen'),
          ));
        } else if (config?.maintenanceModeData?.maintenanceStatus == 0 &&
            isMaintenanceRoute) {
          Navigator.of(Get.context!).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashBoardScreen()),
          );
        }
      }

      // ✅ Chỉ show local notif khi KHÔNG phải maintenance/restock/call_invite
      if (t != 'maintenance_mode' &&
          t != 'product_restock_update' &&
          t != 'call_invite' &&
          t != 'call_invite_group') {
        NotificationHelper.showNotification(
          message,
          flutterLocalNotificationsPlugin,
          false,
        );
      }

      // Restock bottom sheet
      if (t == 'product_restock_update' &&
          !Provider.of<RestockController>(Get.context!, listen: false)
              .isBottomSheetOpen) {
        NotificationBody notificationBody = convertNotification(message.data);
        Provider.of<RestockController>(Get.context!, listen: false)
            .setBottomSheetOpen(true);
        final result = await showModalBottomSheet(
          context: Get.context!,
          isScrollControlled: true,
          backgroundColor:
              Theme.of(Get.context!).primaryColor.withValues(alpha: 0),
          builder: (con) =>
              RestockSheetWidget(notificationBody: notificationBody),
        );

        if (result == null) {
          Provider.of<RestockController>(Get.context!, listen: false)
              .setBottomSheetOpen(false);
        } else {}
      }
    });

    // ===== User TAP notification (BACKGROUND → FOREGROUND) =====
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      final data = message.data;
      final type = (data['type'] ?? '').toString();

      //  SOCIAL notifications (WoWonder)
      if ((data['api_status'] != null) || (data['detail'] != null)) {
        debugPrint('📬 [SOCIAL] User tapped social notification');
        await handlePushNavigation(message);
        return;
      }

      // CUỘC GỌI TỚI: để main.dart.onMessageOpenedApp xử lý
      if (type == 'call_invite' ||
          type == 'call_invite_group' ||
          (data.containsKey('call_id') && data.containsKey('media'))) {
        return;
      }

      if (kDebugMode) {
        print(
            "onOpenApp: ${message.notification?.title}/${data}/${message.notification?.titleLocKey}");
      }

      if (data['type'] == 'demo_reset') {
        showDialog(
          context: Get.context!,
          builder: (context) => const Dialog(
            backgroundColor: Colors.transparent,
            child: DemoResetDialogWidget(),
          ),
        );
      }

      try {
        if (data.isNotEmpty) {
          NotificationBody notificationBody = convertNotification(data);

          if (notificationBody.type == 'order') {
            Navigator.of(Get.context!).pushReplacement(
              MaterialPageRoute(
                builder: (BuildContext context) => OrderDetailsScreen(
                  orderId: notificationBody.orderId,
                  isNotification: true,
                ),
              ),
            );
          } else if (notificationBody.type == 'wallet') {
            Navigator.of(Get.context!).pushReplacement(
              MaterialPageRoute(
                builder: (BuildContext context) => const WalletScreen(),
              ),
            );
          } else if (notificationBody.type == 'notification') {
            Navigator.of(Get.context!).pushReplacement(
              MaterialPageRoute(
                builder: (BuildContext context) =>
                    const NotificationScreen(fromNotification: true),
              ),
            );
          } else if (notificationBody.type == 'chatting') {
            Navigator.of(Get.context!).pushReplacement(
              MaterialPageRoute(
                builder: (BuildContext context) => InboxScreen(
                  isBackButtonExist: true,
                  fromNotification: true,
                  initIndex:
                      notificationBody.messageKey == 'message_from_delivery_man'
                          ? 0
                          : 1,
                ),
              ),
            );
          } else if (notificationBody.type == 'product_restock_update') {
            Navigator.of(Get.context!).pushReplacement(
              MaterialPageRoute(
                builder: (BuildContext context) => ProductDetails(
                  productId: int.parse(notificationBody.productId!),
                  slug: notificationBody.slug,
                  isNotification: true,
                ),
              ),
            );
          } else {
            Navigator.of(Get.context!).pushReplacement(
              MaterialPageRoute(
                builder: (BuildContext context) =>
                    const NotificationScreen(fromNotification: true),
              ),
            );
          }
        }
      } catch (_) {}

      if (data['type'] == 'maintenance_mode') {
        final SplashController splashProvider =
            Provider.of<SplashController>(Get.context!, listen: false);
        await splashProvider.initConfig(Get.context!, null, null);

        ConfigModel? config =
            Provider.of<SplashController>(Get.context!, listen: false)
                .configModel;

        bool isMaintenanceRoute =
            Provider.of<SplashController>(Get.context!, listen: false)
                .isMaintenanceModeScreen();

        if (config?.maintenanceModeData?.maintenanceStatus == 1 &&
            (config?.maintenanceModeData?.selectedMaintenanceSystem
                    ?.customerApp ==
                1)) {
          Navigator.of(Get.context!).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const MaintenanceScreen(),
              settings: const RouteSettings(name: 'MaintenanceScreen'),
            ),
          );
        } else if (config?.maintenanceModeData?.maintenanceStatus == 0 &&
            isMaintenanceRoute) {
          Navigator.of(Get.context!).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashBoardScreen()),
          );
        }
      }
    });
  }

  static Future<void> showNotification(RemoteMessage message,
      FlutterLocalNotificationsPlugin fln, bool data) async {
    if (!Platform.isIOS) {
      String? title;
      String? body;
      String? orderID;
      String? image;
      NotificationBody notificationBody = convertNotification(message.data);
      if (data) {
        title = message.data['title'];
        body = message.data['body'];
        orderID = message.data['order_id'];
        image = (message.data['image'] != null &&
                message.data['image'].isNotEmpty)
            ? message.data['image'].startsWith('http')
                ? message.data['image']
                : '${AppConstants.baseUrl}/storage/app/public/notification/${message.data['image']}'
            : null;
      } else {
        title = message.notification?.title;
        body = message.notification?.body;
        orderID = message.notification?.titleLocKey;
        if (Platform.isAndroid) {
          image = (message.notification?.android?.imageUrl != null &&
                  message.notification!.android!.imageUrl!.isNotEmpty)
              ? message.notification!.android!.imageUrl!.startsWith('http')
                  ? message.notification!.android!.imageUrl
                  : '${AppConstants.baseUrl}/storage/app/public/notification/${message.notification?.android?.imageUrl}'
              : null;
        } else if (Platform.isIOS) {
          image = (message.notification?.apple?.imageUrl != null &&
                  message.notification!.apple!.imageUrl!.isNotEmpty)
              ? message.notification!.apple!.imageUrl!.startsWith('http')
                  ? message.notification?.apple?.imageUrl
                  : '${AppConstants.baseUrl}/storage/app/public/notification/${message.notification!.apple!.imageUrl}'
              : null;
        }
      }

      if (image != null && image.isNotEmpty) {
        try {
          await showBigPictureNotificationHiddenLargeIcon(
              title, body, orderID, notificationBody, image, fln);
        } catch (e) {
          await showBigTextNotification(
              title, body!, orderID, notificationBody, fln);
        }
      } else {
        await showBigTextNotification(
            title, body!, orderID, notificationBody, fln);
      }
    }
  }

  static Future<void> showTextNotification(
      String title,
      String body,
      String orderID,
      NotificationBody? notificationBody,
      FlutterLocalNotificationsPlugin fln) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      '6vallvnshop247_channel',
      'vnshop247_channel',
      playSound: true,
      importance: Importance.max,
      priority: Priority.max,
      sound: RawResourceAndroidNotificationSound('notification'),
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics,
        payload: notificationBody != null
            ? jsonEncode(notificationBody.toJson())
            : null);
  }

  static Future<void> showBigTextNotification(
      String? title,
      String body,
      String? orderID,
      NotificationBody? notificationBody,
      FlutterLocalNotificationsPlugin fln) async {
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body,
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
    );
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'vnshop247_channel',
      'vnshop247_channel',
      importance: Importance.max,
      styleInformation: bigTextStyleInformation,
      priority: Priority.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics,
        payload: notificationBody != null
            ? jsonEncode(notificationBody.toJson())
            : null);
  }

  static Future<void> showBigPictureNotificationHiddenLargeIcon(
      String? title,
      String? body,
      String? orderID,
      NotificationBody? notificationBody,
      String image,
      FlutterLocalNotificationsPlugin fln) async {
    final String largeIconPath = await _downloadAndSaveFile(image, 'largeIcon');
    final String bigPicturePath =
        await _downloadAndSaveFile(image, 'bigPicture');
    final BigPictureStyleInformation bigPictureStyleInformation =
        BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath),
      hideExpandedLargeIcon: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
      summaryText: body,
      htmlFormatSummaryText: true,
    );
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'vnshop247_channel',
      'vnshop247_channel',
      largeIcon: FilePathAndroidBitmap(largeIconPath),
      priority: Priority.max,
      playSound: true,
      styleInformation: bigPictureStyleInformation,
      importance: Importance.max,
      sound: const RawResourceAndroidNotificationSound('notification'),
    );
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, title, body, platformChannelSpecifics,
        payload: notificationBody != null
            ? jsonEncode(notificationBody.toJson())
            : null);
  }

  static Future<String> _downloadAndSaveFile(
      String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  static NotificationBody convertNotification(Map<String, dynamic> data) {
    if (data['type'] == 'notification') {
      return NotificationBody(type: 'notification');
    } else if (data['type'] == 'order') {
      return NotificationBody(
          type: 'order', orderId: int.parse(data['order_id']));
    } else if (data['type'] == 'wallet') {
      return NotificationBody(type: 'wallet');
    } else if (data['type'] == 'block') {
      return NotificationBody(type: 'block');
    } else if (data['type'] == 'product_restock_update') {
      return NotificationBody(
          type: 'product_restock_update',
          title: data['title'],
          image: data['image'],
          productId: data['product_id'].toString(),
          slug: data['slug'],
          status: data['status']);
    } else if (data['type'] == 'referral_code_used') {
      return NotificationBody(
          type: 'referral_code_used',
          title: data['title'],
          messageKey: data['body'],
          image: data['image'],
          productId: data['product_id'].toString(),
          slug: data['slug'],
          status: data['status']);
    } else {
      return NotificationBody(
          type: 'chatting', messageKey: data['message_key']);
    }
  }
}

@pragma('vm:entry-point')
Future<dynamic> myBackgroundMessageHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print(
        "onBackground: ${message.notification?.title}/${message.notification?.body}/${message.notification?.titleLocKey}");
  }
}
