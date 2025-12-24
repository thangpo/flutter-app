import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zego_zpns/zego_zpns.dart';

import '../../../utill/app_constants.dart';
import 'zego_remote_logger.dart';

/// Đăng ký push ZPNs sau khi đã có social_access_token.
class ZpnsPushRegistrar {
  ZpnsPushRegistrar._();

  static const _prefKeyRegistered = 'zpns_push_registered';
  static bool _inProgress = false;

  /// Gọi hàm này sau khi user đã login (đã có social_access_token).
  static Future<void> registerIfNeeded() async {
    if (_inProgress) return;
    _inProgress = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(AppConstants.socialAccessToken) ?? '';
      if (accessToken.isEmpty) {
        _inProgress = false;
        return;
      }

      final already = prefs.getBool(_prefKeyRegistered) ?? false;
      if (already) {
        _inProgress = false;
        return;
      }

      final isProd = kReleaseMode || kProfileMode;
      try {
        ZPNs.enableDebug(!isProd);
      } catch (_) {}

      try {
        ZPNs.setPushConfig(ZPNsConfig()..enableFCMPush = true);
      } catch (e) {
        await ZegoRemoteLogger.I.log('zpns_set_push_config_failed', {
          'error': e.toString(),
        });
      }

      try {
        ZPNsEventHandler.onRegistered = (msg) {
          ZegoRemoteLogger.I.log('zpns_registered', {
            'push_id': msg.pushID,
            'error': msg.errorCode,
            'source': msg.pushSourceType.name,
            'error_message': msg.errorMessage,
          });
        };
        ZPNsEventHandler.onThroughMessageReceived = (msg) {
          ZegoRemoteLogger.I.log('zpns_through_message', {
            'title': msg.title,
            'content': msg.content,
            'payload': msg.payload,
            'extras_keys': msg.extras.keys.join(','),
            'source': msg.pushSourceType.name,
          });
        };
      } catch (_) {}

      await ZPNs.getInstance().registerPush(enableIOSVoIP: true);
      await prefs.setBool(_prefKeyRegistered, true);
      await ZegoRemoteLogger.I.log('zpns_register_success', {
        'access_token_present': 'true',
      });
    } catch (e) {
      await ZegoRemoteLogger.I.log('zpns_register_failed', {
        'error': e.toString(),
      });
    } finally {
      _inProgress = false;
    }
  }

  /// Reset flag để đăng ký lại (ví dụ sau khi logout).
  static Future<void> resetRegisteredFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyRegistered);
  }
}
