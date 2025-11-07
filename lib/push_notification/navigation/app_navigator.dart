import 'package:flutter/material.dart';

/// AppNavigator: giữ 1 navigatorKey toàn cục để điều hướng ở bất kỳ đâu.
class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  static NavigatorState? get nav => navigatorKey.currentState;
  static BuildContext? get context => navigatorKey.currentContext;

  /// Đẩy trang an toàn (nếu tree chưa sẵn sàng thì đợi post-frame).
  static Future<T?> pushPage<T>(Widget page) async {
    if (nav == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nav?.push(MaterialPageRoute(builder: (_) => page));
      });
      return null;
    }
    return nav!.push(MaterialPageRoute(builder: (_) => page));
  }
}
