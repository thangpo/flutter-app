import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/event_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/event_repository.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

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
import 'package:flutter_displaymode/flutter_displaymode.dart';

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
import 'package:flutter_sixvalley_ecommerce/features/social/fcm/fcm_chat_handler.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/call/zego_call_service.dart';

import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import 'di_container.dart' as di;
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_page_controller.dart';

// === ADD (n?u chua có bi?n này) ===
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// =================== FIREBASE ANALYTICS INSTANCES ===================
final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
final FirebaseAnalyticsObserver observer =
    FirebaseAnalyticsObserver(analytics: analytics);

// Background FCM
@pragma('vm:entry-point')
Future<void> myBackgroundMessageHandler(RemoteMessage message) async {
  // Ensure bindings are initialized in background isolate.
  try {
    WidgetsFlutterBinding.ensureInitialized();
  } catch (_) {}
  // Ensure plugins are registered for background isolate (needed for MethodChannels like callkit).
  try {
    DartPluginRegistrant.ensureInitialized();
  } catch (_) {}

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
      print('? [BG] Firebase initialized in background isolate');
    } else {
      Firebase.app(); // d?ng app hi?n c? (ph?ng khi b? reuse)
      print('?? [BG] Firebase already initialized in background');
    }
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      print(
          '?? [BG] Firebase duplicate-app in background, using existing app.');
      Firebase.app();
    } else {
      print('? [BG] Firebase init error in background: $e');
    }
  } catch (e) {
    print('? [BG] Firebase init error in background: $e');
  }

  // Legacy WebRTC call_invite flow is removed (migrated to ZEGOCLOUD).
  // Offline/online invitations are handled by `ZegoUIKitPrebuiltCallInvitationService`.
  try {
    final data = message.data;
    final type = (data['type'] ?? '').toString();
    if (type == 'call_invite' ||
        type == 'call_invite_group' ||
        type == 'call_group_end') {
      return;
    }
  } catch (_) {}
}

Future<void> _debugPrintFcmToken() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    print('?? FCM TOKEN (device) = $token');
  } catch (e) {
    print('? Error getting FCM token: $e');
  }
}

Future<void> _setHighRefreshRate() async {
  if (!Platform.isAndroid) return;

  try {
    // Uu tiên mode có refresh rate cao nh?t máy h? tr?
    await FlutterDisplayMode.setHighRefreshRate();
    debugPrint('High refresh rate mode applied');
  } catch (e) {
    debugPrint('Không set du?c high refresh rate: $e');
  }
}

// =================== ANALYTICS HELPER ===================
class AnalyticsHelper {
  // Log khi app du?c m?
  static Future<void> logAppOpen() async {
    await analytics.logAppOpen();
    await analytics.logEvent(
      name: 'app_launch',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
        'platform': Platform.operatingSystem,
      },
    );
    print('?? Analytics: App opened');
  }

  // Log khi user active (v?o foreground)
  static Future<void> logUserActive() async {
    await analytics.logEvent(
      name: 'user_active',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
        'session_id': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    print('?? Analytics: User active');
  }

  // Log screen view
  static Future<void> logScreenView(String screenName) async {
    await analytics.logScreenView(screenName: screenName);
    print('?? Analytics: Screen viewed - $screenName');
  }

  // Log khi user login
  static Future<void> logLogin(String method) async {
    await analytics.logLogin(loginMethod: method);
    print('?? Analytics: User logged in - $method');
  }

  // Set user ID
  static Future<void> setUserId(String userId) async {
    await analytics.setUserId(id: userId);
    print('?? Analytics: User ID set - $userId');
  }

  // Set user properties
  static Future<void> setUserProperty(String name, String value) async {
    await analytics.setUserProperty(name: name, value: value);
    print('?? Analytics: User property set - $name: $value');
  }
}

// =================== APP LIFECYCLE OBSERVER ===================
class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App v?o foreground
      AnalyticsHelper.logUserActive();
      // Flush pending navigation actions after CallKit accept (lock-screen) and recover active calls.
      unawaited(
        ZegoCallService.I
            .ensureEnterAcceptedOfflineCall(source: 'lifecycle_resumed'),
      );
    } else if (state == AppLifecycleState.paused) {
      // App v?o background
      analytics.logEvent(
        name: 'app_backgrounded',
        parameters: {'timestamp': DateTime.now().toIso8601String()},
      );
    }
  }
}

// Legacy WebRTC call notification/open handlers removed (migrated to ZEGOCLOUD).

// === REPLACE this function ===
Future<void> _ensureAndroidNotificationPermission() async {
  if (!Platform.isAndroid) return;

  final androidImpl =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (androidImpl == null) {
    debugPrint('?? No AndroidFlutterLocalNotificationsPlugin impl available.');
    return;
  }

  bool? granted;

  try {
    // flutter_local_notifications v17+
    granted = await androidImpl.requestNotificationsPermission();
    debugPrint('?? requestNotificationsPermission() => $granted');
  } catch (e1) {
    try {
      // M?t s? b?n cu dùng tên cu (n?u có)
      // ignore: deprecated_member_use
      // granted = await androidImpl.requestPermission(); // có th? v?n không t?n t?i
      debugPrint('?? requestPermission() not available on this version.');
    } catch (e2) {
      // b? qua
    }
  }

  // N?u SDK quá cu, không có API xin quy?n ? log c?nh báo
  if (granted == null) {
    debugPrint(
      '?? flutter_local_notifications b?n hi?n t?i không h? tr? xin POST_NOTIFICATIONS. '
      'Trên Android 13+ b?n c?n nâng c?p plugin (khuy?n ngh? v17+) '
      'ho?c dùng permission_handler(Permission.notification).',
    );
  }
}

Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  // Đăng ký navigator key cho Zego invitation để CallKit có context push trang gọi.
  ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);
  // Bật CallKit/ConnectionService TRƯỚC khi init để cold-start nhận sự kiện accept.
  try {
    await ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI(
      [ZegoUIKitSignalingPlugin()],
    );
  } catch (e) {
    debugPrint('[ZEGO] useSystemCallingUI failed: $e');
  }
  // Init Zego càng sớm càng tốt để xử lý accept từ CallKit (cold start).
  await ZegoCallService.I.tryInitFromPrefs();

  await _setHighRefreshRate();

  // V? full edge-to-edge, kh?ng d? system bar chi?m n?n den
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

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
      print('? Firebase initialized successfully');
    } else {
      Firebase.app(); // d?ng app hi?n c?
      print('?? Firebase already initialized (Dart).');
    }

    await analytics.setAnalyticsCollectionEnabled(true);
    print('? Firebase Analytics enabled');
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      print('?? Firebase duplicate-app, using existing app.');
      Firebase.app();
    } else {
      print('Firebase init error: $e');
    }
  }

  // ==== SOCIAL FCM WIRING ====
  // 1) FCM chat
  FcmChatHandler.initialize();

  // =================== APP LIFECYCLE OBSERVER ===================
  WidgetsBinding.instance.addObserver(AppLifecycleObserver());

  assert(() {
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, // b?t banner khi app dang foreground (dev d? test)
      badge: true,
      sound: true,
    );
    return true;
  }());

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
  // === ADD (tru?c khi t?o channel) ===
  await _ensureAndroidNotificationPermission();

  const androidInit = AndroidInitializationSettings('notification_icon');
  const iosInit = DarwinInitializationSettings();
  const initSettings =
      InitializationSettings(android: androidInit, iOS: iosInit);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse resp) async {
      final payload = resp.payload;
      debugPrint('?? onDidReceiveNotificationResponse payload(raw)= $payload');
      if (payload == null || payload.isEmpty) return;
      try {
        final Map<String, dynamic> map = (jsonDecode(payload) as Map)
            .map((k, v) => MapEntry(k.toString(), v));
        // Legacy `call_invite` notifications are ignored (migrated to ZEGOCLOUD).

        //  di?u hu?ng social
        if ((map['type'] ?? '') == 'interact') {
          await handlePushNavigationFromMap(map);
          return;
        }
      } catch (e) {
        debugPrint('parse payload error: $e');
      }
    },
  );

  // Background handler (g?m c? call_invite d? x? l? ? tr?n)
  FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);

  NotificationBody? body;

  try {
    // app m? t? TERMINATED
    final RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      final t = (initialMessage.data['type'] ?? '').toString();
      if (t == 'call_invite' ||
          t == 'call_invite_group' ||
          t == 'call_group_end') {
        // ignore legacy WebRTC call notifications
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
      print('?? onMessageOpenedApp (main): ${message.data}');
      final t = (message.data['type'] ?? '').toString();
      if (t == 'call_invite' ||
          t == 'call_invite_group' ||
          t == 'call_group_end') {
        return; // ignore legacy WebRTC call notifications
      }
      await handlePushNavigation(message);
    });

    // Foreground notifications đã được NotificationHelper xử lý (tránh double notify).
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = message.data;
      debugPrint('?? onMessage(foreground) data= $data');

      // Bỏ qua toàn bộ xử lý hiển thị ở đây để tránh trùng; CallInviteForegroundListener + NotificationHelper lo phần còn lại.
      final type = (data['type'] ?? '').toString();
      if (type == 'call_invite' ||
          type == 'call_invite_group' ||
          data.containsKey('call_id')) {
        return;
      }
    });

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Th?ng b?o VNShop247',
      description: 'K?nh th?ng b?o m?c d?nh cho VNShop247',
      importance: Importance.max,
      playSound: true, // B?t ?m thanh
      enableVibration: true, // B?t rung
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  } catch (e, st) {
    debugPrint('? FCM wiring error in main(): $e');
    debugPrint('$st');
  }

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<EventController>(
        create: (_) => EventController(repo: EventRepository()),
      ),
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
      ChangeNotifierProvider(
          create: (context) => di.sl<SocialPageController>()),
      ChangeNotifierProvider(
        create: (_) => SocialNotificationsController(
          repo: SocialNotificationsRepository(),
        ),
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
      return _CallkitResumeWrapper(
        child: MaterialApp(
          title: AppConstants.appName,
          navigatorKey: navigatorKey,

          // =================== TH?M ANALYTICS OBSERVER ===================
          navigatorObservers: [observer],

          debugShowCheckedModeBanner: false,
          theme: themeController.darkTheme
              ? dark
              : light(
                  primaryColor: themeController.selectedPrimaryColor,
                  secondaryColor: themeController.selectedPrimaryColor,
                ),
          locale: Provider.of<LocalizationController>(context).locale,
          // KH?NG d?t const v? c? delegate runtime
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
              child: SafeArea(
                top: false,
                bottom: false,
                child: child!,
              ),
            );
          },
          supportedLocales: locals,
          home: SplashScreen(body: body),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/booking-confirm': (context) => const BookingConfirmScreen(),
            '/notifications': (context) => const NotificationScreen(),
          },
        ),
      );
    });
  }
}

/// Đảm bảo sau khi UI dựng xong (post-frame) sẽ thử mở UI cuộc gọi offline.
class _CallkitResumeWrapper extends StatefulWidget {
  final Widget child;
  const _CallkitResumeWrapper({required this.child});

  @override
  State<_CallkitResumeWrapper> createState() => _CallkitResumeWrapperState();
}

class _CallkitResumeWrapperState extends State<_CallkitResumeWrapper> {
  bool _didResume = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_didResume) return;
      _didResume = true;

      // ✅ Nhịp 1: ngay sau frame đầu
      ZegoCallService.I.ensureEnterAcceptedOfflineCall(source: 'post_frame#1');

      // ✅ Nhịp 2..5: cold start iOS có thể nhận event trễ → gọi lại vài nhịp
      for (int i = 2; i <= 5; i++) {
        await Future.delayed(const Duration(milliseconds: 600));
        ZegoCallService.I.ensureEnterAcceptedOfflineCall(source: 'post_frame#$i');
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
