import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_plugin_adapter/zego_plugin_adapter.dart';

import '../../../utill/app_constants.dart';
import '../../../helper/app_globals.dart' show navigatorKey;
import 'zego_call_config.dart';
import 'zego_remote_logger.dart';
import 'zego_token_repository.dart';

class ZegoCallService {
  ZegoCallService._();

  static final ZegoCallService I = ZegoCallService._();

  static const _prefTokenKey = 'zego_call_token';
  static const _prefExpireKey = 'zego_call_token_expire_at';
  static const _prefHandlerInfoKey = 'handler_info';

  final ZegoTokenRepository _tokenRepo = ZegoTokenRepository();
  final ZegoRemoteLogger _remoteLogger = ZegoRemoteLogger.I;

  bool _inited = false;
  String? _userId;
  String? _userName;
  bool _refreshingToken = false;
  int? _cachedExpireAt;
  Future<void>? _initFuture;
  bool _forcingReenter = false;
  String? _lastIncomingCallId;
  String? _lastIncomingInviterId;
  String? _lastIncomingInviterName;
  String? _lastIncomingCustomData;
  final Map<String, _CallProfile> _profiles = {}; // userId/groupId -> info

  bool get isInited => _inited;
  String? get userId => _userId;
  String? get userName => _userName;

  Future<void> initIfPossible({
    required String userId,
    required String userName,
  }) async {
    if (_inited && _userId == userId) return;
    if (_initFuture != null) {
      await _initFuture;
      if (_inited && _userId == userId) return;
    }

    final completer = Completer<void>();
    _initFuture = completer.future;

    try {
      if (ZegoCallConfig.appID <= 0) {
        debugPrint('[ZEGO] Missing ZEGO_APP_ID, skip init call service.');
        return;
      }

    debugPrint(
        '[ZEGO] Init requested for user=$userId appID=${ZegoCallConfig.appID}');
    unawaited(_remoteLogger.log('init_requested', {
      'user_id': userId,
      'user_name': userName,
    }));

      final token = await _getValidToken(userId: userId);
      if (token == null || token.isEmpty) {
        debugPrint('[ZEGO] Không lấy được token từ server, bỏ qua init.');
        return;
      }
      // Lưu lại expire để biết khi nào cần renew sớm.
      _cachedExpireAt = await _getCachedExpireAt();

    final isProd = kReleaseMode || kProfileMode;
    final notificationConfig = ZegoCallInvitationNotificationConfig(
      iOSNotificationConfig: ZegoCallIOSNotificationConfig(
        appName: AppConstants.appName,
        isSandboxEnvironment: !isProd,
      ),
      androidNotificationConfig: ZegoCallAndroidNotificationConfig(
        callIDVisibility: true,
        showOnLockedScreen: true,
        showOnFullScreen:
            true, // cần full-screen để Android 13/14 hiển thị incoming call khi app bị kill
        callChannel: ZegoCallAndroidNotificationChannelConfig(
          channelID: 'zego_incoming_call',
          channelName: 'Incoming Calls',
          icon: 'notification_icon',
          sound: '',
          vibrate: true,
        ),
        missedCallChannel: ZegoCallAndroidNotificationChannelConfig(
          channelID: 'zego_missed_call',
          channelName: 'Missed Calls',
          icon: 'notification_icon',
          sound: '',
          vibrate: false,
        ),
      ),
    );

    _userId = userId;
    _userName = userName;

      try {
        await ZegoUIKitPrebuiltCallInvitationService().init(
          appID: ZegoCallConfig.appID,
          appSign: '', // AppSign nằm ở server, client chỉ dùng token
          token: token,
          userID: userId,
          userName: userName,
          plugins: [ZegoUIKitSignalingPlugin()],
          events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (event, defaultAction) {
            unawaited(_remoteLogger.log('call_end', {
              'user_id': _userId ?? '',
              'call_id': event.callID,
              'reason': event.reason.name,
              'kicker': event.kickerUserID ?? '',
            }));
            defaultAction.call();
          },
          room: ZegoCallRoomEvents(
            onStateChanged: (state) {
              if (state.reason == ZegoRoomStateChangedReason.LoginFailed &&
                  state.errorCode != 0) {
                unawaited(_remoteLogger.log('room_login_failed', {
                  'user_id': _userId ?? '',
                  'error': state.errorCode,
                  'reason': state.reason.name,
                }));
                unawaited(_renewTokenAndRetry(
                  source: 'room_login_failed',
                  errorCode: state.errorCode,
                ));
              }
              unawaited(_remoteLogger.log('room_state_changed', {
                'user_id': _userId ?? '',
                'reason': state.reason.name,
                'error': state.errorCode,
                'extended': state.extendedData.toString(),
              }));
            },
            onTokenExpired: (remainSeconds) {
              unawaited(_remoteLogger.log('room_token_expired', {
                'user_id': _userId ?? '',
                'remain': remainSeconds,
              }));
              unawaited(_renewTokenAndRetry(
                source: 'room_token_expired',
              ));
              return '';
            },
          ),
          user: ZegoCallUserEvents(
            onEnter: (user) {
              unawaited(_remoteLogger.log('user_enter', {
                'uid': user.id,
                'name': user.name,
              }));
            },
            onLeave: (user) {
              unawaited(_remoteLogger.log('user_leave', {
                'uid': user.id,
                'name': user.name,
              }));
            },
          ),
          audioVideo: ZegoCallAudioVideoEvents(
            onCameraStateChanged: (on) {
              unawaited(
                  _remoteLogger.log('camera_state', {'on': on.toString()}));
            },
            onMicrophoneStateChanged: (on) {
              unawaited(
                  _remoteLogger.log('microphone_state', {'on': on.toString()}));
            },
          ),
          onError: (err) {
            unawaited(_remoteLogger.log('call_event_error', {
              'code': err.code,
              'message': err.message,
            }));
            final code = int.tryParse(err.code.toString());
            if (code != null && (code == 1002067 || code == 1002052)) {
              unawaited(_renewTokenAndRetry(
                source: 'call_event_error_$code',
                errorCode: code,
              ));
            }
            if (code == 1000002 || code == 1002002) {
              unawaited(_forceReenterAfterNotLogin(
                source: 'call_event_error_$code',
                errorCode: code,
              ));
            }
          },
        ),
        invitationEvents: ZegoUIKitPrebuiltCallInvitationEvents(
          onIncomingCallAcceptButtonPressed: () {
            unawaited(_remoteLogger.log('incoming_accept_pressed', {
              'user_id': userId,
              'call_id': _lastIncomingCallId ?? '',
              'inviter_id': _lastIncomingInviterId ?? '',
              'inviter_name': _lastIncomingInviterName ?? '',
              'custom_len': _lastIncomingCustomData?.length.toString() ?? '',
            }));

            // ✅ Quan trọng: đảm bảo init xong rồi mới enter
            unawaited(ensureEnterAcceptedOfflineCall(source: 'callkit_accept'));
          },
          onIncomingCallDeclineButtonPressed: () {
            unawaited(_remoteLogger.log('incoming_decline_pressed', {
              'user_id': userId,
              'call_id': _lastIncomingCallId ?? '',
              'inviter_id': _lastIncomingInviterId ?? '',
              'inviter_name': _lastIncomingInviterName ?? '',
              'custom_len': _lastIncomingCustomData?.length.toString() ?? '',
            }));
          },
          onIncomingCallReceived: (
            String callID,
            ZegoCallUser caller,
            ZegoCallInvitationType callType,
            List<ZegoCallUser> callees,
            String customData,
          ) {
            _lastIncomingCallId = callID;
            _lastIncomingInviterId = caller.id;
            _lastIncomingInviterName = caller.name;
            _lastIncomingCustomData = customData;
            unawaited(_remoteLogger.log('incoming_received', {
              'call_id': callID,
              'caller_id': caller.id,
              'caller_name': caller.name,
              'call_type': callType.name,
              'callees': callees.map((e) => e.id).toList(),
              'custom_len': customData.length.toString(),
            }));
            // Backup: khi app vừa được wake từ push, thử mở UI nếu đã có accept.
            unawaited(
              _enterAcceptedOfflineCallWithLog(source: 'incoming_received'),
            );
          },
          onIncomingCallCanceled: (callID, caller, customData) {
            unawaited(_remoteLogger.log('incoming_canceled', {
              'call_id': callID,
              'caller_id': caller.id,
              'caller_name': caller.name,
              'custom_len': customData.length.toString(),
            }));
          },
          onIncomingCallTimeout: (callID, caller) {
            unawaited(_remoteLogger.log('incoming_timeout', {
              'call_id': callID,
              'caller_id': caller.id,
              'caller_name': caller.name,
            }));
          },
          onInvitationUserStateChanged: (users) {
            unawaited(_remoteLogger.log('invitation_user_state', {
              'call_id': _lastIncomingCallId ?? '',
              'users': users
                  .map((u) => {
                        'id': u.userID,
                        'state': u.state.toString(),
                      })
                  .toList()
                  .toString(),
            }));
          },
          onOutgoingCallSent: (
            String callID,
            ZegoCallUser caller,
            ZegoCallInvitationType callType,
            List<ZegoCallUser> callees,
            String customData,
          ) {
            unawaited(_remoteLogger.log('outgoing_sent', {
              'call_id': callID,
              'caller_id': caller.id,
              'caller_name': caller.name,
              'call_type': callType.name,
              'callees': callees.map((e) => e.id).toList().toString(),
              'custom_len': customData.length.toString(),
            }));
          },
          onOutgoingCallAccepted: (callID, callee) {
            unawaited(_remoteLogger.log('outgoing_accepted', {
              'call_id': callID,
              'callee_id': callee.id,
              'callee_name': callee.name,
            }));
          },
          onOutgoingCallDeclined: (callID, callee, customData) {
            unawaited(_remoteLogger.log('outgoing_declined', {
              'call_id': callID,
              'callee_id': callee.id,
              'callee_name': callee.name,
              'custom_len': customData.length.toString(),
            }));
          },
          onOutgoingCallRejectedCauseBusy: (callID, callee, customData) {
            unawaited(_remoteLogger.log('outgoing_rejected_busy', {
              'call_id': callID,
              'callee_id': callee.id,
              'callee_name': callee.name,
              'custom_len': customData.length.toString(),
            }));
          },
          onOutgoingCallTimeout: (callID, callees, isVideoCall) {
            unawaited(_remoteLogger.log('outgoing_timeout', {
              'call_id': callID,
              'callees': callees.map((e) => e.id).toList().toString(),
              'is_video': isVideoCall.toString(),
            }));
          },
          ),
          config: ZegoCallInvitationConfig(
            offline: ZegoCallInvitationOfflineConfig(
              autoEnterAcceptedOfflineCall: false,
            ),
          ),
          notificationConfig: notificationConfig,
          requireConfig: (ZegoCallInvitationData data) {
            if (data.callID.isNotEmpty) {
              _lastIncomingCallId = data.callID;
            }
            if (data.inviter != null) {
              _lastIncomingInviterId = data.inviter!.id;
              _lastIncomingInviterName = data.inviter!.name;
            }
            if (data.customData.isNotEmpty) {
              _lastIncomingCustomData = data.customData;
            }
            _ingestCustomProfiles(data);
            final isVideo = data.type == ZegoCallInvitationType.videoCall;
            final isGroup = data.invitees.length > 1;
            final config = isGroup
                ? (isVideo
                    ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
                    : ZegoUIKitPrebuiltCallConfig.groupVoiceCall())
                : (isVideo
                    ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                    : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall());
            unawaited(_remoteLogger.log('require_config', {
              'call_id': data.callID,
              'invitation_id': data.invitationID,
              'is_group': isGroup,
              'is_video': isVideo,
              'invitees': data.invitees.map((e) => e.id).toList(),
              'inviter': data.inviter?.id ?? '',
            }));
            _applyAvatarAndText(config, data);
            _attachRequiredUsers(config, data);
            return config;
          },
        );
      } catch (e) {
        debugPrint('[ZEGO] Lỗi init service: $e');
        unawaited(_remoteLogger.log('init_failed', {
          'user_id': userId,
          'error': e.toString(),
        }));
        return;
      }

      _inited = true;
      debugPrint('[ZEGO] Call invitation service inited for user=$userId');
      unawaited(_remoteLogger.log('init_success', {
        'user_id': userId,
        'user_name': userName,
      }));
      unawaited(_ensureIosCallKitSupportsVideo(notificationConfig));

      // Extra attempt: khi app được mở lại từ CallKit (cold start) cố gắng vào UI gọi.
      Future.delayed(const Duration(milliseconds: 600), () {
        try {
          unawaited(
            _maybeForceAndroidOfflineRealJoin(source: 'after_init'),
          );
          ZegoUIKitPrebuiltCallInvitationService().enterAcceptedOfflineCall();
          unawaited(_remoteLogger.log('enter_offline_after_init', {
            'user_id': userId,
          }));
        } catch (_) {}
      });
    } finally {
      if (!completer.isCompleted) {
        completer.complete();
      }
      _initFuture = null;
    }
  }

  Future<String?> _myAvatarFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.socialUserAvatar);
  }

  Future<void> _ensureIosCallKitSupportsVideo(
    ZegoCallInvitationNotificationConfig notificationConfig,
  ) async {
    if (!Platform.isIOS) return;
    try {
      final appName = notificationConfig.iOSNotificationConfig?.appName ??
          AppConstants.appName;
      final iconName =
          notificationConfig.iOSNotificationConfig?.systemCallingIconName ?? '';
      await ZegoUIKit().getSignalingPlugin().setInitConfiguration(
            ZegoSignalingPluginProviderConfiguration(
              localizedName: appName,
              iconTemplateImageName: iconName,
              supportsVideo: true,
              maximumCallsPerCallGroup: 1,
              maximumCallGroups: 1,
            ),
          );
      unawaited(_remoteLogger.log('ios_callkit_supports_video_on', {
        'user_id': _userId ?? '',
        'app_name': appName,
      }));
    } catch (e) {
      unawaited(_remoteLogger.log('ios_callkit_supports_video_failed', {
        'user_id': _userId ?? '',
        'error': e.toString(),
      }));
    }
  }

  void _setProfile(String id, String? name, String? avatar) {
    if (id.isEmpty) return;
    _profiles[id] = _CallProfile(id: id, name: name ?? id, avatar: avatar);
  }

  void _ingestCustomProfiles(ZegoCallInvitationData data) {
    Map<String, dynamic>? parsed;
    try {
      if (data.customData.isNotEmpty) {
        parsed = jsonDecode(data.customData);
      }
    } catch (_) {}

    if (parsed != null) {
      final callerId = data.inviter?.id ?? '';
      final callerName = parsed['caller_name']?.toString();
      final callerAvatar = parsed['caller_avatar']?.toString();
      if (callerId.isNotEmpty) {
        _setProfile(callerId, callerName, callerAvatar);
      }
      final peerId = parsed['peer_id']?.toString();
      final peerAvatar = parsed['peer_avatar']?.toString();
      final peerName = parsed['peer_name']?.toString();
      if (peerId != null && peerId.isNotEmpty) {
        _setProfile(peerId, peerName ?? peerId, peerAvatar);
      }
      final groupId = parsed['group_id']?.toString();
      if (groupId != null && groupId.isNotEmpty) {
        _setProfile(
          groupId,
          parsed['group_name']?.toString() ?? groupId,
          parsed['group_avatar']?.toString(),
        );
      }
    }
  }

  String? _parsedGroupId(ZegoCallInvitationData data) {
    try {
      if (data.customData.isNotEmpty) {
        final parsed = jsonDecode(data.customData);
        if (parsed is Map && parsed['group_id'] != null) {
          return parsed['group_id'].toString();
        }
      }
    } catch (_) {}
    return null;
  }

  void _applyAvatarAndText(
    ZegoUIKitPrebuiltCallConfig config,
    ZegoCallInvitationData data,
  ) {
    final groupId = _parsedGroupId(data);
    final groupProfile = groupId != null ? _profiles[groupId] : null;

    config.audioVideoView.foregroundBuilder =
        (BuildContext context, Size size, ZegoUIKitUser? user, Map extraInfo) {
      final widgets = <Widget>[];

      // Let Zego prebuilt UI show participant names to avoid duplicates.
      if (groupProfile != null && groupProfile.name != null) {
        widgets.add(Positioned(
          left: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              groupProfile.name!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ));
      }

      return Stack(children: widgets);
    };

    config.avatarBuilder =
        (BuildContext context, Size size, ZegoUIKitUser? user, Map extraInfo) {
      final uid = user?.id ?? '';
      final p = _profiles[uid];
      if (p != null && (p.avatar?.isNotEmpty ?? false)) {
        return CircleAvatar(
          radius: size.width / 2,
          backgroundImage: NetworkImage(p.avatar!),
        );
      }
      if (p != null) {
        final initial = (p.name ?? p.id).isNotEmpty
            ? (p.name ?? p.id)[0].toUpperCase()
            : '?';
        return CircleAvatar(
          radius: size.width / 2,
          child: Text(initial),
        );
      }
      if ((user?.id ?? '').isNotEmpty) {
        return CircleAvatar(
          radius: size.width / 2,
          child: Text(user!.id.substring(0, 1).toUpperCase()),
        );
      }
      return const SizedBox.shrink();
    };

    // translationText của prebuilt không có setter cho title gọi, bỏ qua.
  }

  Future<void> uninit() async {
    if (!_inited) return;
    ZegoUIKitPrebuiltCallInvitationService().uninit();
    _inited = false;
    _userId = null;
    _userName = null;
    debugPrint('[ZEGO] Call invitation service uninited');
  }

  Future<void> tryInitFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(AppConstants.socialUserId);
    if (userId == null || userId.isEmpty) return;

    final display = prefs.getString(AppConstants.socialUserName) ?? userId;
    unawaited(_remoteLogger.log('init_from_prefs', {
      'user_id': userId,
      'user_name': display,
    }));
    await initIfPossible(userId: userId, userName: display);
  }

  /// Cho phép cache thủ công profile (vd: thành viên nhóm) trước khi gọi.
  void cacheProfile(String id, {String? name, String? avatar}) {
    _setProfile(id, name, avatar);
  }

  Future<String?> _getValidToken({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();

    // ✅ 1) dùng cache trước
    final cached = prefs.getString(AppConstants.zegoToken) ?? '';
    final rawExp = prefs.getInt(AppConstants.zegoTokenExpireAt);
    final exp = _normalizeExpireAt(rawExp);
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (cached.isNotEmpty && exp > (nowSec + 60)) {
      unawaited(_remoteLogger.log('token_cache_hit', {
        'user_id': userId,
        'expire_at': exp,
        'now': nowSec,
        'raw_expire': rawExp,
      }));
      unawaited(_syncHandlerInfoToken(cached));
      _cachedExpireAt = exp;
      return cached;
    }

    // ✅ 2) fallback fetch server
    unawaited(_remoteLogger.log('token_cache_miss', {
      'user_id': userId,
      'expire_at': exp,
      'now': nowSec,
      'raw_expire': rawExp,
    }));
    return _fetchFreshToken(prefs: prefs, userId: userId);
  }

  Future<int?> _getCachedExpireAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.zegoTokenExpireAt);
  }

  int _normalizeExpireAt(int? raw) {
    if (raw == null) return 0;
    // Một số backend trả mili giây, cần quy đổi về giây
    return raw > 1000000000000 ? (raw ~/ 1000) : raw;
  }

  Future<void> _syncHandlerInfoToken(String token) async {
    if (token.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefHandlerInfoKey) ?? '';
      if (raw.isEmpty) return;
      final parsed = jsonDecode(raw);
      if (parsed is! Map<String, dynamic>) return;
      if (parsed['tkn'] == token) return;
      parsed['tkn'] = token;
      await prefs.setString(_prefHandlerInfoKey, jsonEncode(parsed));
      unawaited(_remoteLogger.log('handler_info_token_updated', {
        'user_id': _userId ?? '',
        'token_len': token.length.toString(),
      }));
    } catch (e) {
      unawaited(_remoteLogger.log('handler_info_token_update_failed', {
        'user_id': _userId ?? '',
        'error': e.toString(),
      }));
    }
  }

  Future<String?> _fetchFreshToken({
    required SharedPreferences prefs,
    required String userId,
  }) async {
    final accessToken = prefs.getString(AppConstants.socialAccessToken) ?? '';
    if (accessToken.isEmpty) {
      debugPrint('[ZEGO] Không có social access_token để xin token');
      unawaited(_remoteLogger.log('token_fetch_skip_no_access_token', {
        'user_id': userId,
      }));
      return null;
    }

    unawaited(_remoteLogger.log('token_fetch_start', {
      'user_id': userId,
    }));
    final res = await _tokenRepo.fetchToken(
      accessToken: accessToken,
      userId: userId,
    );

    await prefs.setString(AppConstants.zegoToken, res.token);
    await prefs.setInt(AppConstants.zegoTokenExpireAt, res.expireAt);
    _cachedExpireAt = res.expireAt;

    unawaited(_remoteLogger.log('token_cache_saved', {
      'user_id': userId,
      'expire_at': res.expireAt,
    }));
    unawaited(_syncHandlerInfoToken(res.token));
    unawaited(_remoteLogger.log('token_fetch_success', {
      'user_id': userId,
      'expire_at': res.expireAt,
      'expire_in': res.expireIn,
      'token_len': res.token.length.toString(),
    }));

    return res.token;
  }

  String newOneOnOneCallId(String peerId) {
    final me = _userId ?? '0';
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'c1_${me}_${peerId}_$ts';
  }

  String newGroupCallId(String groupId) {
    final me = _userId ?? '0';
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'cg_${groupId}_${me}_$ts';
  }

  Future<void> _enterAcceptedOfflineCallWithLog(
      {required String source}) async {
    try {
      ZegoUIKitPrebuiltCallInvitationService().enterAcceptedOfflineCall();
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final exp = _cachedExpireAt ?? 0;
      unawaited(_remoteLogger.log('enter_offline_call', {
        'source': source,
        'user_id': _userId ?? '',
        'call_id': _lastIncomingCallId ?? '',
        'inited': _inited,
        'nav_ready': navigatorKey.currentState != null &&
            navigatorKey.currentContext?.mounted == true,
        'token_expire_at': exp,
        'token_ttl': exp > 0 ? (exp - nowSec) : 0,
      }));
    } catch (e) {
      unawaited(_remoteLogger.log('enter_offline_call_failed', {
        'source': source,
        'user_id': _userId ?? '',
        'call_id': _lastIncomingCallId ?? '',
        'inited': _inited,
        'error': e.toString(),
      }));
    }
  }

  Future<void> _maybeForceAndroidOfflineRealJoin({
    required String source,
  }) async {
    if (!Platform.isAndroid) return;
    final service = ZegoUIKitPrebuiltCallInvitationService();
    final isAcceptedOffline = service.private
        .isCurrentInvitationFromAcceptedAndroidOffline(
            selfDestructing: false);
    if (!isAcceptedOffline) return;

    final roomId = ZegoUIKit().getRoom().id;
    if (roomId.isNotEmpty) {
      unawaited(_remoteLogger.log('offline_accept_room_ready', {
        'source': source,
        'room_id': roomId,
      }));
      return;
    }

    // Fallback: nếu callkit offline chưa join room ở background, ép UI join thật.
    service.private
        .isCurrentInvitationFromAcceptedAndroidOffline(selfDestructing: true);
    unawaited(_remoteLogger.log('offline_accept_force_real_join', {
      'source': source,
      'room_id': roomId,
    }));
  }

  /// Gọi sau khi navigator đã sẵn sàng (post-frame) để chắc chắn vào màn hình gọi.
  /// ✅ FIX: cold start cần đảm bảo init xong mới enter + retry vài nhịp
  Future<void> ensureEnterAcceptedOfflineCall(
      {String source = 'post_frame'}) async {
    const int maxAttempts = 40; // ~ 40 * 250ms = 10s, đủ margin cho cold start
    // Kiểm tra token trước khi join phòng để tránh lỗi 1002067 khi vừa mở app.
    await _renewIfExpiringSoon(source: source);
    for (int i = 0; i < maxAttempts; i++) {
      try {
        if (!_inited) {
          await tryInitFromPrefs(); // ✅ quan trọng
        }
        final navReady = navigatorKey.currentState != null &&
            navigatorKey.currentContext?.mounted == true;
        if (_inited && navReady) {
          await _maybeForceAndroidOfflineRealJoin(source: source);
          await _enterAcceptedOfflineCallWithLog(source: '$source#${i + 1}');
          return;
        }
      } catch (e) {
        unawaited(_remoteLogger.log('ensure_enter_offline_call_err', {
          'source': source,
          'attempt': i + 1,
          'error': e.toString(),
        }));
      }
      await Future.delayed(const Duration(milliseconds: 250));
    }

    unawaited(_remoteLogger.log('ensure_enter_offline_call_giveup', {
      'source': source,
      'user_id': _userId ?? '',
      'inited': _inited,
    }));
  }

  Future<void> _renewTokenAndRetry({
    required String source,
    int? errorCode,
  }) async {
    if (_refreshingToken) return;
    _refreshingToken = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = _userId ?? prefs.getString(AppConstants.socialUserId);
      if (uid == null || uid.isEmpty) return;

      final freshToken = await _fetchFreshToken(prefs: prefs, userId: uid);
      if (freshToken == null || freshToken.isEmpty) return;

      await ZegoUIKit().renewRoomToken(freshToken);
      try {
        ZegoUIKit().getSignalingPlugin().renewToken(freshToken);
      } catch (_) {}

      unawaited(_remoteLogger.log('token_renew_success', {
        'user_id': uid,
        'error': errorCode,
      }));

      await ensureEnterAcceptedOfflineCall(source: source);
    } catch (e) {
      unawaited(_remoteLogger.log('token_renew_failed', {
        'user_id': _userId ?? '',
        'error': e.toString(),
      }));
    } finally {
      _refreshingToken = false;
    }
  }

  Future<void> _forceReenterAfterNotLogin({
    required String source,
    int? errorCode,
  }) async {
    if (_forcingReenter) return;
    _forcingReenter = true;
    try {
      await _maybeForceAndroidOfflineRealJoin(source: source);
      unawaited(_remoteLogger.log('force_reenter_after_not_login', {
        'source': source,
        'error': errorCode?.toString() ?? '',
      }));
      await ensureEnterAcceptedOfflineCall(source: '${source}_force');
    } finally {
      _forcingReenter = false;
    }
  }

  Future<void> _renewIfExpiringSoon({required String source}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expRaw = prefs.getInt(AppConstants.zegoTokenExpireAt);
      final exp = _normalizeExpireAt(expRaw);
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      const int ahead = 120; // renew trước 2 phút
      if (exp == 0 || exp <= now + ahead) {
        unawaited(_remoteLogger.log('token_renew_ahead', {
          'user_id': _userId ?? '',
          'expire_at': exp,
          'source': source,
        }));
        await _renewTokenAndRetry(source: '$source-ahead');
      }
    } catch (_) {
      // bỏ qua
    }
  }

  Future<bool> startOneOnOne({
    required String peerId,
    required String peerName,
    required bool isVideoCall,
    String? callID,
    String? peerAvatar,
  }) async {
    if (!_inited) {
      await tryInitFromPrefs();
    }
    if (!_inited) return false;

    final actualCallId = callID ?? newOneOnOneCallId(peerId);
    unawaited(_remoteLogger.log('caller_press_call', {
      'call_id': actualCallId,
      'peer_id': peerId,
      'peer_name': peerName,
      'is_video': isVideoCall.toString(),
    }));

    _setProfile(peerId, peerName, peerAvatar);
    // lưu luôn profile của mình để callee hiển thị
    _setProfile(_userId ?? '', _userName, await _myAvatarFromPrefs());

    final result = await ZegoUIKitPrebuiltCallInvitationService().send(
      invitees: [ZegoCallUser(peerId, peerName)],
      isVideoCall: isVideoCall,
      callID: actualCallId,
      resourceID: ZegoCallConfig.callResourceID.isEmpty
          ? null
          : ZegoCallConfig.callResourceID,
      customData: jsonEncode({
        'scope': 'social',
        'mode': 'one_on_one',
        'peer_id': peerId,
        'peer_name': peerName,
        'is_video': isVideoCall,
        'peer_avatar': peerAvatar ?? '',
        'caller_name': _userName ?? _userId ?? '',
        'caller_avatar': await _myAvatarFromPrefs(),
      }),
    );
    unawaited(_remoteLogger.log('caller_send_result', {
      'call_id': actualCallId,
      'peer_id': peerId,
      'result': result.toString(),
    }));
    return result;
  }

  Future<bool> startGroup({
    required List<ZegoCallUser> invitees,
    required bool isVideoCall,
    required String groupId,
    String? callID,
    Map<String, dynamic>? customData,
    String? callerName,
    String? callerAvatar,
    String? groupName,
    String? groupAvatar,
  }) async {
    _setProfile(groupId, groupName, groupAvatar);

    if (!_inited) {
      await tryInitFromPrefs();
    }
    if (!_inited) return false;

    final actualCallId = callID ?? newGroupCallId(groupId);
    unawaited(_remoteLogger.log('caller_press_group_call', {
      'call_id': actualCallId,
      'group_id': groupId,
      'invitees': invitees.map((e) => e.id).toList().toString(),
      'is_video': isVideoCall.toString(),
    }));

    final data = <String, dynamic>{
      'scope': 'social',
      'mode': 'group',
      'is_video': isVideoCall,
      // Dùng tên/ảnh nhóm làm "caller" để CallKit/popup hiển thị nhóm thay vì host.
      'caller_name': groupName?.isNotEmpty == true
          ? groupName
          : (callerName ?? _userName ?? _userId ?? ''),
      'caller_avatar': groupAvatar?.isNotEmpty == true
          ? groupAvatar
          : (callerAvatar ?? await _myAvatarFromPrefs()),
      'group_id': groupId,
      'group_name': groupName ?? '',
      'group_avatar': groupAvatar ?? '',
      if (customData != null) ...customData,
    };

    final result = await ZegoUIKitPrebuiltCallInvitationService().send(
      invitees: invitees,
      isVideoCall: isVideoCall,
      callID: actualCallId,
      resourceID: ZegoCallConfig.callResourceID.isEmpty
          ? null
          : ZegoCallConfig.callResourceID,
      customData: jsonEncode(data),
      notificationTitle: groupName ?? 'Cuộc gọi nhóm',
      notificationMessage:
          isVideoCall ? 'Cuộc gọi video nhóm' : 'Cuộc gọi thoại nhóm',
    );
    unawaited(_remoteLogger.log('caller_group_send_result', {
      'call_id': actualCallId,
      'group_id': groupId,
      'result': result.toString(),
    }));
    return result;
  }
}

class _CallProfile {
  final String id;
  final String? name;
  final String? avatar;

  _CallProfile({required this.id, this.name, this.avatar});
}

void _attachRequiredUsers(
  ZegoUIKitPrebuiltCallConfig config,
  ZegoCallInvitationData data,
) {
  if (config.user.requiredUsers.enabled) return;

  final required = <ZegoUIKitUser>[];
  final selfId = ZegoCallService.I.userId ?? '';
  if (data.inviter != null &&
      data.inviter!.id.isNotEmpty &&
      data.inviter!.id != selfId) {
    required.add(
      ZegoUIKitUser(id: data.inviter!.id, name: data.inviter!.name),
    );
  }
  for (final u in data.invitees) {
    if (u.id.isEmpty || u.id == selfId) continue;
    required.add(ZegoUIKitUser(id: u.id, name: u.name));
  }
  if (required.isEmpty) {
    return;
  }
  config.user.requiredUsers = ZegoCallRequiredUserConfig(
    enabled: true,
    detectSeconds: 8,
    users: required,
  );
}
