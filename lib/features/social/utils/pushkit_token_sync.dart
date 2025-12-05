// lib/features/social/utils/pushkit_token_sync.dart
//
// Đồng bộ PushKit (VoIP) token lên server Social khi đã có access_token.
// - Chỉ chạy trên iOS.
// - Gọi sau login/đăng ký Social hoặc khi muốn làm mới token.

import 'dart:io';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class PushkitTokenSync {
  /// Đồng bộ token hiện tại (nếu có) lên server Social.
  static Future<void> sync() async {
    if (!Platform.isIOS) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(AppConstants.socialAccessToken);
      if (accessToken == null || accessToken.isEmpty) {
        log('[PUSHKIT] skip sync: missing access_token');
        return;
      }

      final voipToken =
          await FlutterCallkitIncoming.getDevicePushTokenVoIP() ?? '';
      if (voipToken.isEmpty) {
        log('[PUSHKIT] skip sync: pushkit_token empty');
        return;
      }

      final apnsEnv = (kReleaseMode || kProfileMode) ? 'prod' : 'sandbox';
      final url = Uri.parse('${AppConstants.socialBaseUrl}/api/pushkit');
      final req = http.MultipartRequest('POST', url)
        ..fields['server_key'] = AppConstants.socialServerKey
        ..fields['access_token'] = accessToken
        ..fields['pushkit_token'] = voipToken
        ..fields['apns_env'] = apnsEnv;

      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();
      log('[PUSHKIT] sync status=${streamed.statusCode} env=$apnsEnv');
      log('[PUSHKIT] resp=$body');
    } catch (e, st) {
      log('[PUSHKIT] sync error: $e\n$st');
    }
  }

  /// Xoá pushkit_token trên server khi logout hoặc thu hồi quyền.
  static Future<void> clear({String? accessTokenOverride}) async {
    if (!Platform.isIOS) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken =
          accessTokenOverride ?? prefs.getString(AppConstants.socialAccessToken);
      if (accessToken == null || accessToken.isEmpty) {
        log('[PUSHKIT] skip clear: missing access_token');
        return;
      }

      final apnsEnv = (kReleaseMode || kProfileMode) ? 'prod' : 'sandbox';
      final url = Uri.parse(
          '${AppConstants.socialBaseUrl}/api/pushkit?access_token=$accessToken');
      final req = http.MultipartRequest('POST', url)
        ..fields['server_key'] = AppConstants.socialServerKey
        ..fields['apns_env'] = apnsEnv
        ..fields['action'] = 'delete';

      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();
      log('[PUSHKIT] clear status=${streamed.statusCode} env=$apnsEnv');
      log('[PUSHKIT] resp=$body');
    } catch (e, st) {
      log('[PUSHKIT] clear error: $e\n$st');
    }
  }
}
