// G:\flutter-app\lib\main.dart
import 'dart:io';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sixvalley_ecommerce/data/local/cache_response.dart';
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
import 'package:provider/provider.dart';
import 'di_container.dart' as di;
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_group_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_service_interface.dart';
import 'helper/custom_delegate.dart';
import 'localization/app_localization.dart';
import 'features/social/controllers/group_chat_controller.dart';
import 'features/social/domain/repositories/group_chat_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_notifications_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_notifications_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/firebase_token_updater.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/push_navigation_helper.dart';

// ====== CALL UI ======
import 'package:flutter_sixvalley_ecommerce/features/social/screens/incoming_call_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/call_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/call_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/webrtc_signaling_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/notification/screens/notification_screen.dart';

// ====== NEW: Call push handler (realtime incoming) ======
import 'package:flutter_sixvalley_ecommerce/features/social/push/push_call_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final database = AppDatabase();

// (Giữ nguyên channel mặc định cho app)
const AndroidNotificationChannel _callInviteChannel =
    AndroidNotificationChannel(
  'call_invite_channel',
  'Call Invites',
  description: 'Heads-up notifications for incoming calls',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

// (Giữ helper này cho các notif khác)
void _handleCallInviteOpen(Map<String, dynamic> data) {
  final nav = navigatorKey.currentState;
  if (nav == null) return;

  final callIdStr = data['call_id']?.toString();
  final media = (data['media']?.toString() == 'video') ? 'video' : 'audio';
  if (callIdStr == null) return;
  final callId = int.tryParse(callIdStr);
  if (callId == null) return;

  final ctx = nav.overlay?.context;
  if (ctx != null) {
    final cc = Provider.of<CallController>(ctx, listen: false);
    cc.attachCall(callId: callId, mediaType: media);

    nav.push(
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          callId: callId,
          mediaType: media,
          callerName: 'Cuộc gọi đến',
        ),
      ),
    );
  }
}

Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init
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
  }

  // 🔔 Đăng ký background handler MỚI cho cuộc gọi (show full-screen notif)
  FirebaseMessaging.onBackgroundMessage(socialCallFirebaseBgHandler);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: false, // tắt auto popup để mình tự điều hướng
    badge: true,
    sound: true,
  );

  // Quyền thông báo
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

  // 🔁 Sau khi app lên khung, cập nhật FCM token social
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await FirebaseTokenUpdater.update();
  });

  // Kênh mặc định
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_callInviteChannel);

  // Local notifications init (cho các notif thường)
  const androidInit = AndroidInitializationSettings('notification_icon');
  final initSettings = InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse resp) async {
      final payload = resp.payload;
      if (payload == null || payload.isEmpty) return;
      try {
        final Map<String, dynamic> map = (jsonDecode(payload) as Map)
            .map((k, v) => MapEntry(k.toString(), v));
        await handlePushNavigationFromMap(map);
      } catch (e) {
        debugPrint('parse payload error: $e');
      }
    },
  );

  // ✅ NEW: Khởi tạo + bind handler cho CUỘC GỌI
  await SocialCallPushHandler.I.initLocalNotifications();
  SocialCallPushHandler.I.bindForegroundListener();

  NotificationBody? body;
  try {
    // 1) App mở từ TERMINATED qua notif
    final RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      // Ưu tiên CALL INVITE → mở màn hình nhận
      if ((initialMessage.data['type'] ?? '') == 'call_invite') {
        _handleCallInviteOpen(initialMessage.data);
      } else if (initialMessage.data['api_status'] != null ||
          initialMessage.data['detail'] != null) {
        await handlePushNavigation(initialMessage);
      } else {
        await handlePushNavigation(initialMessage);
      }
    }

    // 2) NotificationHelper nội bộ
    await NotificationHelper.initialize(flutterLocalNotificationsPlugin);

    // 3) User TAP notif khi app background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      // CALL INVITE: điều hướng vào màn nhận
      if ((message.data['type'] ?? '') == 'call_invite') {
        _handleCallInviteOpen(message.data);
        return;
      }
      await handlePushNavigation(message);
    });

    // 4) App FOREGROUND: nhận FCM
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // ❗ Cuộc gọi đã do SocialCallPushHandler xử lý foreground → tránh trùng
      if ((message.data['type'] ?? '') == 'call_invite') {
        return;
      }

      // Các notif khác → hiển thị local notif như cũ
      String? title = message.notification?.title;
      String? bodyText = message.notification?.body;
      title ??= (message.data['title'] ??
          message.data['notification_title'] ??
          'VNShop247');
      bodyText ??=
          (message.data['body'] ?? message.data['notification_body'] ?? '');

      if ((title ?? '').isEmpty && (bodyText ?? '').isEmpty) return;

      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'Thông báo VNShop247',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        icon: 'notification_icon',
      );
      const details = NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        bodyText,
        details,
        payload: jsonEncode(message.data),
      );
    });

    // 5) Channel mặc định khác
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Thông báo VNShop247',
      description: 'Kênh thông báo mặc định cho VNShop247',
      importance: Importance.max,
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
      ChangeNotifierProvider(
        create: (_) =>
            SocialController(service: di.sl<SocialServiceInterface>())
              ..refresh(),
      ),
      ChangeNotifierProvider(
        create: (_) => di.sl<SocialGroupController>(),
      ),
      ChangeNotifierProvider(
        create: (_) => GroupChatController(GroupChatRepository()),
      ),
      ChangeNotifierProvider(
        create: (_) => CallController(
          signaling: WebRTCSignalingRepository(
            baseUrl: AppConstants.socialBaseUrl,
            serverKey: AppConstants.socialServerKey,
            accessTokenKey: AppConstants.socialAccessToken,
          ),
        )..init(),
      ),
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
    List<Locale> locals = [];
    for (var language in AppConstants.languages) {
      locals.add(Locale(language.languageCode!, language.countryCode));
    }
    return Consumer<ThemeController>(builder: (context, themeController, _) {
      return MaterialApp(
        title: AppConstants.appName,
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: themeController.darkTheme
            ? dark
            : light(
                primaryColor: themeController.selectedPrimaryColor,
                secondaryColor: themeController.selectedPrimaryColor,
              ),
        locale: Provider.of<LocalizationController>(context).locale,
        localizationsDelegates: [
          AppLocalization.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FallbackLocalizationDelegate()
        ],
        builder: (context, child) {
          return MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.noScaling),
              child: SafeArea(top: false, child: child!));
        },
        supportedLocales: locals,
        home: SplashScreen(
          body: body,
        ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/booking-confirm': (context) => const BookingConfirmScreen(),
          '/notifications': (context) => const NotificationScreen(),
        },
      );
    });
  }
}

class Get {
  static BuildContext? get context => navigatorKey.currentContext;
  static NavigatorState? get navigator => navigatorKey.currentState;
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
