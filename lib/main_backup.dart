import 'dart:io';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_sixvalley_ecommerce/helper/app_globals.dart';

import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/facebook_login_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/google_login_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/banner/controllers/banner_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/controllers/checkout_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/compare/controllers/compare_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/contact_us/controllers/contact_us_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/deal/controllers/featured_deal_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/deal/controllers/flash_deal_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/location/controllers/location_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/loyaltyPoint/controllers/loyalty_point_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/notification/controllers/notification_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/onboarding/controllers/onboarding_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/controllers/order_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/controllers/order_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/seller_product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/controllers/product_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/refund/controllers/refund_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/reorder/controllers/re_order_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/restock/controllers/restock_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/review/controllers/review_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/shipping/controllers/shipping_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/screens/splash_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/support/controllers/support_ticket_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/controllers/wallet_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/wishlist/controllers/wishlist_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/controllers/localization_controller.dart';
import 'package:flutter_sixvalley_ecommerce/push_notification/models/notification_body.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/controllers/address_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/brand/controllers/brand_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/cart/controllers/cart_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/controllers/category_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/controllers/chat_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/coupon/controllers/coupon_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/search_product/controllers/search_product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/controllers/shop_controller.dart';
import 'package:flutter_sixvalley_ecommerce/push_notification/notification_helper.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/theme/dark_theme.dart';
import 'package:flutter_sixvalley_ecommerce/theme/light_theme.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/login_screen.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/screens/booking_confirm_screen.dart';

// Localization
import 'helper/custom_delegate.dart';
import 'localization/app_localization.dart';

// Notification screen
import 'package:flutter_sixvalley_ecommerce/features/notification/screens/notification_screen.dart';

// Social modules
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_group_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_service_interface.dart';
import 'features/social/controllers/group_chat_controller.dart';
import 'features/social/domain/repositories/group_chat_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_notifications_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_notifications_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/firebase_token_updater.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/push_navigation_helper.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/screens/incoming_call_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/call_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/call_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/webrtc_signaling_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/fcm/fcm_chat_handler.dart';

// Group call
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/group_call_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/group_call_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/webrtc_group_signaling_repository.dart';

import 'di_container.dart' as di;
import 'package:flutter_sixvalley_ecommerce/features/notification/screens/notification_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/group_call_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/webrtc_group_signaling_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_page_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_page_service_interface.dart';


// =================== FIREBASE ANALYTICS INSTANCES ===================
final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);


// tránh mở màn nhận cuộc gọi trùng
bool _incomingCallRouting = false;

const AndroidNotificationChannel _callInviteChannel =
AndroidNotificationChannel(
  'call_invite_channel',
  'Call Invites',
  description: 'Heads-up notifications for incoming calls',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

// Background FCM
@pragma('vm:entry-point')
Future<void> myBackgroundMessageHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      if (Platform.isAndroid) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: AppConstants.fcmApiKey,
            appId: AppConstants.fcmMobilesdkAppId,
            messagingSenderId: AppConstants.fcmProjectNumber,
            projectId: AppConstants.fcmProjectId,
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
      print('✅ [BG] Firebase initialized in background isolate');
    } else {
      Firebase.app(); // dùng app hiện có (phòng khi bị reuse)
      print('ℹ️ [BG] Firebase already initialized in background');
    }
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      print('⚠️ [BG] Firebase duplicate-app in background, using existing app.');
      Firebase.app();
    } else {
      print('❌ [BG] Firebase init error in background: $e');
    }
  } catch (e) {
    print('❌ [BG] Firebase init error in background: $e');
  }
  // nếu sau này cần xử lý message ở background thì làm tiếp ở đây
}

Future<void> _debugPrintFcmToken() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    print('🔥 FCM TOKEN (device) = $token');
  } catch (e) {
    print('❌ Error getting FCM token: $e');
  }
}
// =================== ANALYTICS HELPER ===================
class AnalyticsHelper {
  // Log khi app được mở
  static Future<void> logAppOpen() async {
    await analytics.logAppOpen();
    await analytics.logEvent(
      name: 'app_launch',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
        'platform': Platform.operatingSystem,
      },
    );
    print('📊 Analytics: App opened');
  }

  // Log khi user active (vào foreground)
  static Future<void> logUserActive() async {
    await analytics.logEvent(
      name: 'user_active',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
        'session_id': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    print('📊 Analytics: User active');
  }

  // Log screen view
  static Future<void> logScreenView(String screenName) async {
    await analytics.logScreenView(screenName: screenName);
    print('📊 Analytics: Screen viewed - $screenName');
  }

  // Log khi user login
  static Future<void> logLogin(String method) async {
    await analytics.logLogin(loginMethod: method);
    print('📊 Analytics: User logged in - $method');
  }

  // Set user ID
  static Future<void> setUserId(String userId) async {
    await analytics.setUserId(id: userId);
    print('📊 Analytics: User ID set - $userId');
  }

  // Set user properties
  static Future<void> setUserProperty(String name, String value) async {
    await analytics.setUserProperty(name: name, value: value);
    print('📊 Analytics: User property set - $name: $value');
  }
}

// =================== APP LIFECYCLE OBSERVER ===================
class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App vào foreground
      AnalyticsHelper.logUserActive();
    } else if (state == AppLifecycleState.paused) {
      // App vào background
      analytics.logEvent(
        name: 'app_backgrounded',
        parameters: {'timestamp': DateTime.now().toIso8601String()},
      );
    }
  }
}

Future<void> _showIncomingCallNotification(Map<String, dynamic> data) async {
  final isVideo = (data['media']?.toString() == 'video');
  final title = isVideo ? 'Video call đến' : 'Cuộc gọi đến';
  final body =
      'Từ #${data['caller_id'] ?? ''} (Call ID ${data['call_id'] ?? ''})';

  final androidDetails = AndroidNotificationDetails(
    _callInviteChannel.id,
    _callInviteChannel.name,
    channelDescription: _callInviteChannel.description,
    importance: Importance.max,
    priority: Priority.high,
    category: AndroidNotificationCategory.call,
    fullScreenIntent: true,
    ticker: 'incoming_call',
    styleInformation: const DefaultStyleInformation(true, true),
    sound: RawResourceAndroidNotificationSound('notification'),  // Tên file âm thanh (không cần đuôi .mp3)
  );

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    NotificationDetails(android: androidDetails),
    payload: jsonEncode(data),
  );
}


void _handleCallInviteOpen(Map<String, dynamic> data) {
  if (_incomingCallRouting) return;
  _incomingCallRouting = true;

  final nav = navigatorKey.currentState;
  if (nav == null) {
    _incomingCallRouting = false;
    return;
  }

  final callIdStr = data['call_id']?.toString();
  final callId = int.tryParse(callIdStr ?? '');
  final media = (data['media']?.toString() == 'video') ? 'video' : 'audio';

  if (callId == null) {
    _incomingCallRouting = false;
    return;
  }

  final callerName = data['caller_name']?.toString();
  final callerAvatar = data['caller_avatar']?.toString();

  nav
      .push(
        MaterialPageRoute(
          builder: (_) => IncomingCallScreen(
            callId: callId,
            mediaType: media,
            callerName: callerName ?? 'Cuộc gọi đến',
            callerAvatar: callerAvatar,
          ),
        ),
      )
      .whenComplete(() => _incomingCallRouting = false);
}

// ===== GROUP: open UI khi có lời mời nhóm =====
void _handleGroupCallInviteOpen(Map<String, dynamic> data) {
  if (_incomingCallRouting) return;
  _incomingCallRouting = true;

  final nav = navigatorKey.currentState;
  if (nav == null) {
    _incomingCallRouting = false;
    return;
  }

  final callId = int.tryParse(data['call_id']?.toString() ?? '');
  final groupId = data['group_id']?.toString();
  final groupName = data['group_name']?.toString();
  final media = (data['media']?.toString() == 'video') ? 'video' : 'audio';

  if (callId == null || groupId == null || groupId.isEmpty) {
    _incomingCallRouting = false;
    return;
  }

  final ctx = nav.overlay?.context ?? navigatorKey.currentContext;
  if (ctx != null) {
    final cc = Provider.of<CallController>(ctx, listen: false);
    cc.attachCall(callId: callId, mediaType: media);

    analytics.logEvent(
      name: 'incoming_group_call_received',
      parameters: {
        'call_id': callId.toString(),
        'media_type': media,
        'group_id': groupId,
      },
    );
  }

  nav
      .push(
        MaterialPageRoute(
          builder: (_) => GroupCallScreen(
            groupId: groupId,
            mediaType: media,
            callId: callId,
            groupName: groupName ?? 'Cu?c g?i nh�m',
          ),
        ),
      )
      .whenComplete(() => _incomingCallRouting = false);
}
/// =========================
/// Helpers: đảm bảo navigator sẵn sàng
/// dùng cho getInitialMessage (terminated app)
/// =========================
Future<void> _waitNavigatorAndOpen(void Function() openFn) async {
  for (int i = 0; i < 20; i++) {
    final nav = navigatorKey.currentState;
    if (nav != null) {
      openFn();
      return;
    }
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

Future<void> _scheduleCallInviteOpen(Map<String, dynamic> data) async {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _waitNavigatorAndOpen(() => _handleCallInviteOpen(data));
  });
}

Future<void> _scheduleGroupCallInviteOpen(Map<String, dynamic> data) async {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _waitNavigatorAndOpen(() => _handleGroupCallInviteOpen(data));
  });
}

Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();


  // =================== FIREBASE INITIALIZATION ===================
  try {
    if (Firebase.apps.isEmpty) {
      if (Platform.isAndroid) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: AppConstants.fcmApiKey,
            appId: AppConstants.fcmMobilesdkAppId,
            messagingSenderId: AppConstants.fcmProjectNumber,
            projectId: AppConstants.fcmProjectId,
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
      print('✅ Firebase initialized successfully');
    } else {
      Firebase.app(); // dùng app hiện có
      print('ℹ️ Firebase already initialized (Dart).');
    }

    await analytics.setAnalyticsCollectionEnabled(true);
    print('✅ Firebase Analytics enabled');
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      print('⚠️ Firebase duplicate-app, using existing app.');
      Firebase.app();
    } else {
      print('Firebase init error: $e');
    }
  }


  FcmChatHandler.initialize();

  // =================== APP LIFECYCLE OBSERVER ===================
  WidgetsBinding.instance.addObserver(AppLifecycleObserver());

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: false,
    badge: true,
    sound: true,
  );


  NotificationSettings settings =
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  await di.init();

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await FirebaseTokenUpdater.update();

    // =================== LOG APP OPEN ===================
    await AnalyticsHelper.logAppOpen();
    await _debugPrintFcmToken();
  });

  // tạo kênh heads-up
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_callInviteChannel);

  const androidInit = AndroidInitializationSettings('notification_icon');
  const initSettings = InitializationSettings(android: androidInit);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse resp) async {
      final payload = resp.payload;
      debugPrint('🔔 onDidReceiveNotificationResponse payload(raw)= $payload');
      if (payload == null || payload.isEmpty) return;
      try {
        final Map<String, dynamic> map = (jsonDecode(payload) as Map)
            .map((k, v) => MapEntry(k.toString(), v));

        if ((map['type'] ?? '') == 'call_invite') {
          _handleCallInviteOpen(map);
          return;
        }

        // GROUP
        if ((map['type'] ?? '') == 'call_invite_group') {
          _handleGroupCallInviteOpen(map);
          return;
        }

        //  điều hướng social
        if ((map['type'] ?? '') == 'interact') {
          await handlePushNavigationFromMap(map);
          return;
        }
      } catch (e) {
        debugPrint('parse payload error: $e');
      }
    },
  );

  FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);

  NotificationBody? body;

  try {
    // app mở từ TERMINATED
    final RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      final t = (initialMessage.data['type'] ?? '').toString();

      if (t == 'call_invite') {
        await _scheduleCallInviteOpen(initialMessage.data);
      } else if (t == 'call_invite_group' ||
          (initialMessage.data.containsKey('call_id') &&
              initialMessage.data.containsKey('group_id'))) {
        await _scheduleGroupCallInviteOpen(initialMessage.data);
      } else if (initialMessage.data['api_status'] != null ||
          initialMessage.data['type'] != null) {
        await handlePushNavigation(initialMessage);
      } else {
        await handlePushNavigation(initialMessage);
      }
    }

    // NotificationHelper
    await NotificationHelper.initialize(flutterLocalNotificationsPlugin);

    // user click notification khi BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print('🔥 onMessageOpenedApp (main): ${message.data}');
      final t = (message.data['type'] ?? '').toString();

      if (t == 'call_invite') {
        _handleCallInviteOpen(message.data);
        return;
      }
      if (t == 'call_invite_group' ||
          (message.data.containsKey('call_id') &&
              message.data.containsKey('group_id'))) {
        _handleGroupCallInviteOpen(message.data);
        return;
      }

      await handlePushNavigation(message);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = message.data;
      debugPrint('🔥 onMessage(foreground) data= $data');

      final type = (data['type'] ?? '').toString();

      // ưu tiên cuộc gọi: mở UI ngay
      // 1-1
      if (type == 'call_invite' ||
          (data.containsKey('call_id') &&
              data.containsKey('media') &&
              !data.containsKey('group_id'))) {
        _handleCallInviteOpen(data);
        return;
      }

      // GROUP
      if (type == 'call_invite_group' ||
          (data.containsKey('call_id') && data.containsKey('group_id'))) {
        _handleGroupCallInviteOpen(data);
        return;
      }

      // social notif mặc định
      String? title = message.notification?.title;
      String? bodyText = message.notification?.body;
      title ??= (data['title'] ?? data['notification_title'] ?? 'VNShop247')
          .toString();
      bodyText ??=
          (data['body'] ?? data['notification_body'] ?? 'Bạn có thông báo mới')
              .toString();

      if (title.isEmpty && bodyText.isEmpty) {
        debugPrint('ℹ️ No displayable title/body. Skip showing local notif.');
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'Thông báo VNShop247',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        icon: 'notification_icon',
        sound: RawResourceAndroidNotificationSound('notification'),
      );
      const details = NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        bodyText,
        details,
        payload: jsonEncode(data),
      );
    });

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Thông báo VNShop247',
      description: 'Kênh thông báo mặc định cho VNShop247',
      importance: Importance.max,
      playSound: true, // Bật âm thanh
      enableVibration: true, // Bật rung
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  } catch (e, st) {
    debugPrint('❌ FCM wiring error in main(): $e');
    debugPrint('$st');
  }

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => di.sl<CategoryController>()),
      ChangeNotifierProvider(create: (context) => di.sl<ShopController>()),
      ChangeNotifierProvider(create: (context) => di.sl<FlashDealController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<FeaturedDealController>()),
      ChangeNotifierProvider(create: (context) => di.sl<BrandController>()),
      ChangeNotifierProvider(create: (context) => di.sl<ProductController>()),
      ChangeNotifierProvider(create: (context) => di.sl<BannerController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<ProductDetailsController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<OnBoardingController>()),
      ChangeNotifierProvider(create: (context) => di.sl<AuthController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<SearchProductController>()),
      ChangeNotifierProvider(create: (context) => di.sl<CouponController>()),
      ChangeNotifierProvider(create: (context) => di.sl<ChatController>()),
      ChangeNotifierProvider(create: (context) => di.sl<OrderController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<NotificationController>()),
      ChangeNotifierProvider(create: (context) => di.sl<ProfileController>()),
      ChangeNotifierProvider(create: (context) => di.sl<WishListController>()),
      ChangeNotifierProvider(create: (context) => di.sl<SplashController>()),
      ChangeNotifierProvider(create: (context) => di.sl<CartController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<SupportTicketController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<LocalizationController>()),
      ChangeNotifierProvider(create: (context) => di.sl<ThemeController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<GoogleSignInController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<FacebookLoginController>()),
      ChangeNotifierProvider(create: (context) => di.sl<AddressController>()),
      ChangeNotifierProvider(create: (context) => di.sl<WalletController>()),
      ChangeNotifierProvider(create: (context) => di.sl<CompareController>()),
      ChangeNotifierProvider(create: (context) => di.sl<CheckoutController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<LoyaltyPointController>()),
      ChangeNotifierProvider(create: (context) => di.sl<LocationController>()),
      ChangeNotifierProvider(create: (context) => di.sl<ContactUsController>()),
      ChangeNotifierProvider(create: (context) => di.sl<ShippingController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<OrderDetailsController>()),
      ChangeNotifierProvider(create: (context) => di.sl<RefundController>()),
      ChangeNotifierProvider(create: (context) => di.sl<ReOrderController>()),
      ChangeNotifierProvider(create: (context) => di.sl<ReviewController>()),
      ChangeNotifierProvider(
          create: (context) => di.sl<SellerProductController>()),
      ChangeNotifierProvider(create: (context) => di.sl<RestockController>()),

      // Social
      ChangeNotifierProvider(
        create: (_) =>
        SocialController(service: di.sl<SocialServiceInterface>())
          ..refresh(),
      ),
      ChangeNotifierProvider(create: (_) => di.sl<SocialGroupController>()),
      ChangeNotifierProvider(
          create: (_) => GroupChatController(GroupChatRepository())),
      ChangeNotifierProvider(create: (context) => di.sl<SocialPageController>()),
      ChangeNotifierProvider(
        create: (_) => SocialNotificationsController(
          repo: SocialNotificationsRepository(),
        ),
      ),

      // 1-1 call
      ChangeNotifierProvider(
        create: (_) => CallController(
          signaling: WebRTCSignalingRepository(
            baseUrl: AppConstants.socialBaseUrl,
            serverKey: AppConstants.socialServerKey,
            accessTokenKey: AppConstants.socialAccessToken,
          ),
        )..init(),
      ),

      // Group call
      ChangeNotifierProvider(
        create: (_) {
          final repo = WebRTCGroupSignalingRepositoryImpl(
            baseUrl: AppConstants.socialBaseUrl,
            serverKey: AppConstants.socialServerKey,
            getAccessToken: () async {
              final sp = await SharedPreferences.getInstance();
              return sp.getString(AppConstants.socialAccessToken);
            },
          );
          return GroupCallController(signaling: repo)..init();
        },
      ),
    ],
    child: MyApp(body: body),
  ));
}

class MyApp extends StatelessWidget {
  final NotificationBody? body;
  const MyApp({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    final locals = [
      for (var language in AppConstants.languages)
        Locale(language.languageCode!, language.countryCode)
    ];

    return Consumer<ThemeController>(builder: (context, themeController, _) {
      return MaterialApp(
        title: AppConstants.appName,
        navigatorKey: navigatorKey,

        // =================== THÊM ANALYTICS OBSERVER ===================
        navigatorObservers: [observer],

        debugShowCheckedModeBanner: false,
        theme: themeController.darkTheme
            ? dark
            : light(
          primaryColor: themeController.selectedPrimaryColor,
          secondaryColor: themeController.selectedPrimaryColor,
        ),
        locale: Provider.of<LocalizationController>(context).locale,
        // KHÔNG đặt const vì có delegate runtime
        localizationsDelegates: [
          AppLocalization.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FallbackLocalizationDelegate(),
        ],
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.noScaling),
            child: SafeArea(top: false, child: child!),
          );
        },
        supportedLocales: locals,
        home: SplashScreen(body: body),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/booking-confirm': (context) => const BookingConfirmScreen(),
          '/notifications': (context) => const NotificationScreen(),
        },
      );
    });
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
