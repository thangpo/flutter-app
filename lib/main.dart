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
// ====== CALL ======
import 'package:flutter_sixvalley_ecommerce/features/social/screens/incoming_call_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/call_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/call_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/webrtc_signaling_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/notification/screens/notification_screen.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/group_call_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/webrtc_group_signaling_repository.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/group_call_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/webrtc_group_signaling_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final database = AppDatabase();

// Chốt tránh mở IncomingCallScreen trùng khi nhận nhiều bản FCM
bool _incomingCallRouting = false;

// =================== Channel heads-up cho cuộc gọi đến ===================
const AndroidNotificationChannel _callInviteChannel =
    AndroidNotificationChannel(
  'call_invite_channel',
  'Call Invites',
  description: 'Heads-up notifications for incoming calls',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

// Background handler
Future<void> myBackgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

// =============== Helpers cho call_invite ===============
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
  final media = (data['media']?.toString() == 'video') ? 'video' : 'audio';
  final callId = int.tryParse(callIdStr ?? '');
  if (callId == null) {
    _incomingCallRouting = false;
    return;
  }

  final ctx = nav.overlay?.context;
  if (ctx != null) {
    final cc = Provider.of<CallController>(ctx, listen: false);
    cc.attachCall(callId: callId, mediaType: media);

    nav
        .push(
          MaterialPageRoute(
            builder: (_) => IncomingCallScreen(
              callId: callId,
              mediaType: media,
              callerName: 'Cuộc gọi đến',
            ),
          ),
        )
        .whenComplete(() => _incomingCallRouting = false);
  } else {
    _incomingCallRouting = false;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    home: Scaffold(
      body: Center(child: Text('iOS smoke test OK')),
    ),
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
