import 'dart:io';
import 'dart:convert';
import 'dart:async';

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
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:flutter_sixvalley_ecommerce/features/social/push/call_invite_stream_listener.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/push/push_call_handler.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/ice_candidate_lite.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/push/callkit_service.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/push/remote_rtc_log.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/screens/call_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/call_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/webrtc_signaling_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/fcm/fcm_chat_handler.dart';

// Group call
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/group_call_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/group_call_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/webrtc_group_signaling_repository.dart';

import 'di_container.dart' as di;
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_page_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_page_service_interface.dart';

// === ADD (n?u chua có bi?n này) ===
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// =================== FIREBASE ANALYTICS INSTANCES ===================
final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
final FirebaseAnalyticsObserver observer =
    FirebaseAnalyticsObserver(analytics: analytics);

// tr?nh m? m?n nh?n cu?c g?i tr?ng
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

// === Group-call end debounce helpers ===
Future<void> _markGroupEndedNow(String groupId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('recent_end_'+groupId, DateTime.now().millisecondsSinceEpoch ~/ 1000);
  } catch (_) {}
}

Future<bool> _wasGroupRecentlyEnded(String groupId, {int seconds = 8}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('recent_end_'+groupId) ?? 0;
    if (ts <= 0) return false;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (now - ts) < seconds;
  } catch (_) {
    return false;
  }
}

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

  // ==== X? L? CU?C G?I 1-1 ? BACKGROUND (data-only FCM) ====
  try {
  final data = message.data;
  final type = (data['type'] ?? '').toString();
  final hasGroupCallIds =
      data.containsKey('call_id') && data.containsKey('group_id');
  final isGroupInvite = type == 'call_invite_group' ||
      ((type.isEmpty || type == 'call_invite') && hasGroupCallIds) ||
      data.containsKey('group_id') ||
      (data['is_group'] ?? '') == '1' ||
      (data['is_group'] ?? '') == 1;

  if (type == 'call_group_end') {
    final gid = (data['group_id'] ?? '').toString();
    final cid = int.tryParse('${data['call_id'] ?? ''}') ?? 0;
    await CallkitService.I.handleRemoteGroupEnded(gid, cid);
    await _markGroupEndedNow(gid);
    print('? [BG] End incoming group call via push (call_id=$cid gid=$gid)');
  } else if (type == 'call_invite' ||
      type == 'call_invite_group' ||
      (type.isEmpty && hasGroupCallIds)) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final myId = prefs.getString(AppConstants.socialUserId);
        final callerId =
            (data['caller_id'] ?? data['from_id'] ?? data['sender_id'])
                ?.toString();
        if (myId != null &&
            myId.isNotEmpty &&
            callerId != null &&
            callerId.isNotEmpty &&
            callerId == myId) {
          return;
        }
      } catch (_) {}

      final bgCallId = int.tryParse('${data['call_id'] ?? ''}') ?? 0;

      if (isGroupInvite) {
        final gid = data['group_id']?.toString() ?? '';
        if (gid.isEmpty) return;
        if (bgCallId > 0 &&
            CallkitService.I.isGroupCallHandled(gid, bgCallId)) {
          print('? [BG] Skip group invite handled call_id=$bgCallId gid=$gid');
          return;
        }
        // Hien thi CallKit/ConnectionService cho cuoc goi nhom ca iOS & Android
        if (await _wasGroupRecentlyEnded(gid)) {
          print('[BG] Skip group invite (recently ended) gid=' + gid);
          await CallkitService.I.endGroupCall(gid, bgCallId);
        } else {
          await CallkitService.I.showIncomingGroupCall(data);
        }
      } else {
        if (bgCallId > 0 && CallkitService.I.isServerCallHandled(bgCallId)) {
          print('? [BG] Skip call_invite: already handled call_id=$bgCallId');
          return;
        }

        await CallkitService.I.showIncomingCall(data);
      }
      print('? [BG] Show incoming call (platform-specific)');
    }
  } catch (e) {
    print('? [BG] Error handling background call_invite: $e');
  }
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
      CallkitService.I.flushPendingActions();
      CallkitService.I.recoverActiveCalls();
    } else if (state == AppLifecycleState.paused) {
      // App v?o background
      analytics.logEvent(
        name: 'app_backgrounded',
        parameters: {'timestamp': DateTime.now().toIso8601String()},
      );
    }
  }
}

Future<void> _showIncomingCallNotification(Map<String, dynamic> data) async {
  final isVideo = (data['media']?.toString() == 'video');
  final title = isVideo ? 'Video call d?n' : 'Cu?c g?i d?n';
  final body =
      'T? #${data['caller_id'] ?? ''} (Call ID ${data['call_id'] ?? ''})';

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
    sound: RawResourceAndroidNotificationSound(
        'notification'), // T?n file ?m thanh (kh?ng c?n du?i .mp3)
  );

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    NotificationDetails(android: androidDetails),
    payload: jsonEncode(data),
  );
}

// === ADD ===
// Production: dùng UI h? th?ng (iOS CallKit / Android ConnectionService)
// -> KHÔNG d?y màn IncomingCallScreen Flutter n?a
class CallUiConfig {
  static const bool useSystemIncomingUI = true;
}

void _handleCallInviteOpen(Map<String, dynamic> data) {
  // Đã dùng CallKit/ConnectionService, không mở IncomingCallScreen Flutter nữa.
  debugPrint('?? Skip IncomingCallScreen (system UI in use)');
}

// ===== GROUP: open UI khi c? l?i m?i nh?m =====
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
            groupName: groupName ?? 'Cuộc gọi nhóm',
          ),
        ),
      )
      .whenComplete(() => _incomingCallRouting = false);
}

/// =========================
/// Helpers: d?m b?o navigator s?n s?ng
/// d?ng cho getInitialMessage (terminated app)
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

Future<void> _handleCallSignal(Map<String, dynamic> data) async {
  final ctx = navigatorKey.currentContext;
  if (ctx == null) return;

  final callId = int.tryParse('${data['call_id']}') ?? 0;
  if (callId <= 0) return;

  final offer = data['sdp_offer'] ?? data['offer'];
  final answer = data['sdp_answer'] ?? data['answer'];
  final status = (data['call_status'] ?? data['status'])?.toString();
  IceCandidateLite? cand;
  if (data['candidate'] != null && '${data['candidate']}'.isNotEmpty) {
    cand = IceCandidateLite(
      candidate: '${data['candidate']}',
      sdpMid: data['sdp_mid']?.toString(),
      sdpMLineIndex:
          int.tryParse('${data['sdp_mline_index'] ?? data['mline'] ?? ''}'),
    );
  }

  try {
    ctx.read<CallController>().ingestPushSignal(
          callId: callId,
          sdpOffer: offer?.toString(),
          sdpAnswer: answer?.toString(),
          candidate: cand,
          status: status,
        );

    unawaited(RemoteRtcLog.send(
      event: 'push_call_signal',
      callId: callId,
      details: {
        'status': status,
        'hasOffer': offer != null,
        'hasAnswer': answer != null,
        'hasCandidate': cand != null,
      },
    ));

    // N?u server báo ended/declined -> dóng CallKit/UI ngay c? khi chua có poll
    if (status == 'ended' || status == 'declined') {
      await CallkitService.I.endCallForServerId(callId);
      try {
        Navigator.of(ctx, rootNavigator: true).popUntil(
          (route) => route.settings.name != 'CallScreen',
        );
      } catch (_) {}
    }
  } catch (_) {}
}

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
  // Đảm bảo các action CallKit (accept từ background/cold start) được flush ngay frame đầu.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    CallkitService.I.flushPendingActions();
  });

  // Ðang ký listener CallKit càng s?m càng t?t d? không miss s? ki?n ANSWER khi app du?c m? t? CallKit (cold start).
  await CallkitService.I.init();

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

  // ==== SOCIAL FCM / CALL WIRING ====
  // 1) Local notifications (cho Android heads-up khi c?n)
  SocialCallPushHandler.I.initLocalNotifications();

  // 2) Listener foreground cho call_invite qua FCM (n?u b?n dùng)
  CallInviteForegroundListener.start();

  // 3) FCM chat
  FcmChatHandler.initialize();

  // SocialCallPushHandler.I.bindForegroundListener(); // KH?NG c?n d?ng n?a

  // =================== APP LIFECYCLE OBSERVER ===================
  WidgetsBinding.instance.addObserver(AppLifecycleObserver());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Khi app v?a d?ng frame d?u tiên (k? c? m? t? CallKit) thì flush action pending
    CallkitService.I.flushPendingActions();
    CallkitService.I.recoverActiveCalls();
  });

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
  // t?o k?nh heads-up cho call_invite (cu, d?ng chung plugin global n?u c?n)
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_callInviteChannel);

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

        if ((map['type'] ?? '') == 'call_invite') {
          _handleCallInviteOpen(map);
          return;
        }

        // GROUP
        if ((map['type'] ?? '') == 'call_invite_group') {
          _handleGroupCallInviteOpen(map);
          return;
        }

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
      final hasGroupIds = initialMessage.data.containsKey('call_id') &&
          initialMessage.data.containsKey('group_id');
      final isGroupInvite = t == 'call_invite_group' ||
          ((t.isEmpty || t == 'call_invite') && hasGroupIds);

      if (t == 'call_group_end') {
        final gid = (initialMessage.data['group_id'] ?? '').toString();
        final cid = int.tryParse('${initialMessage.data['call_id'] ?? ''}') ?? 0;
        await CallkitService.I.handleRemoteGroupEnded(gid, cid);
        await _markGroupEndedNow(gid);
      } else if (isGroupInvite) {
        await _scheduleGroupCallInviteOpen(initialMessage.data);
      } else if (t == 'call_invite') {
        await _scheduleCallInviteOpen(initialMessage.data);
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
      final hasGroupIds =
          message.data.containsKey('call_id') && message.data.containsKey('group_id');
      final isGroupInvite =
          t == 'call_invite_group' || ((t.isEmpty || t == 'call_invite') && hasGroupIds);

      if (t == 'call_group_end') {
        final gid = (message.data['group_id'] ?? '').toString();
        final cid = int.tryParse('${message.data['call_id'] ?? ''}') ?? 0;
        await CallkitService.I.handleRemoteGroupEnded(gid, cid);
        await _markGroupEndedNow(gid);
        return;
      }
      if (isGroupInvite) {
        _handleGroupCallInviteOpen(message.data);
        return;
      }
      if (t == 'call_invite') {
        _handleCallInviteOpen(message.data);
        return;
      }

      await handlePushNavigation(message);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = message.data;
      debugPrint('?? onMessage(foreground) data= $data');

      if ((data['type'] ?? '') == 'call_signal') {
        await _handleCallSignal(data);
        return;
      }
      if ((data['type'] ?? '') == 'call_group_end') {
        final gid = (data['group_id'] ?? '').toString();
        final cid = int.tryParse('${data['call_id'] ?? ''}') ?? 0;
        await CallkitService.I.handleRemoteGroupEnded(gid, cid);
        await _markGroupEndedNow(gid);
        return;
      }

      // ---- B? QUA T?T C? TH?NG ?I?P LI?N QUAN ??N CU?C G?I ----
      final type = (data['type'] ?? '').toString();
      final hasCallId = data.containsKey('call_id');

      final isOneToOneCall = type == 'call_invite' ||
          (hasCallId &&
              data.containsKey('media') &&
              !data.containsKey('group_id'));

      final isGroupCall = type == 'call_invite_group' ||
          (hasCallId && data.containsKey('group_id'));

      if (isOneToOneCall || isGroupCall) {
        // Incoming call d? du?c x? l? b?i CallInviteForegroundListener,
        // kh?ng c?n show notification thu?ng n?a.
        return;
      }

      // ---- C?C TH?NG B?O B?NH THU?NG (ORDER, SOCIAL, ...) ----
      String? title = message.notification?.title;
      String? bodyText = message.notification?.body;
      title ??= (data['title'] ?? data['notification_title'] ?? 'VNShop247')
          .toString();
      bodyText ??=
          (data['body'] ?? data['notification_body'] ?? 'B?n c? th?ng b?o m?i')
              .toString();

      if (title.isEmpty && bodyText.isEmpty) {
        debugPrint('?? No displayable title/body. Skip showing local notif.');
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'Th?ng b?o VNShop247',
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
