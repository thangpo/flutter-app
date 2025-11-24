// lib/features/social/push/call_invite_stream_listener.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter_sixvalley_ecommerce/helper/app_globals.dart'
    show navigatorKey;

import '../controllers/call_controller.dart';
import '../controllers/group_call_controller.dart';
import '../domain/models/call_invite.dart';
import '../fcm/fcm_chat_handler.dart';
import '../screens/incoming_call_screen.dart';
import '../screens/group_call_screen.dart';

/// Listen to chat FCM stream and show the incoming-call UI immediately on call_invite.
class CallInviteForegroundListener {
  CallInviteForegroundListener._();

  static StreamSubscription? _chatSub;
  static StreamSubscription? _fcmSub;
  static final Set<int> _handledCallIds = <int>{};
  static final Set<String> _handledGroupCalls =
      <String>{}; // key: callId|groupId
  static bool _routing = false;

  static void start() {
    if (_chatSub == null) {
      _chatSub = FcmChatHandler.messagesStream.listen(_handleChatEvent);
    }
    if (_fcmSub == null) {
      _fcmSub = FirebaseMessaging.onMessage.listen(_handleFcmDirect);
    }
  }

  static Future<void> _handleChatEvent(FcmChatEvent evt) async {
    final raw = evt.text ?? '';
    if (raw.isEmpty) return;
    _tryOpenFromPayload(raw, null, null);
  }

  /// FCM trực tiếp khi app đang foreground
  static Future<void> _handleFcmDirect(RemoteMessage msg) async {
    final data = msg.data;
    if (data.isEmpty) return;

    final type = (data['type'] ?? '').toString();

    // --------------------
    // GROUP CALL
    // --------------------
    final hasGroup = data.containsKey('group_id');
    if (hasGroup &&
        (type == 'call_invite_group' || data.containsKey('call_id'))) {
      _openGroupFromData(data);
      return;
    }

    // --------------------
    // 1-1 CALL
    // --------------------
    final raw = data['text']?.toString() ?? '';
    final callerName = data['caller_name']?.toString();
    final callerAvatar = data['caller_avatar']?.toString();

    // 1) Ưu tiên parse call_invite từ text (embed trong message)
    if (raw.isNotEmpty) {
      final invite = CallInvite.tryParse(raw);
      if (invite != null && !invite.isExpired()) {
        // chống trùng call_id
        if (!_handledCallIds.add(invite.callId)) return;

        _openIncoming(
          invite,
          callerName: callerName,
          callerAvatar: callerAvatar,
        );
        return;
      }
    }

    // 2) Fallback: payload native (type = call_invite hoặc có call_id + media ở root)
    final looksLikeCallInvite = type == 'call_invite' ||
        (data.containsKey('call_id') &&
            data.containsKey('media') &&
            !data.containsKey('group_id'));

    if (!looksLikeCallInvite) return;

    _tryOpenFromPayload(
      '',
      callerName,
      callerAvatar,
      extraData: data,
    );
  }

  static void _openGroupFromData(Map<String, dynamic> data) {
    final callId = int.tryParse('${data['call_id'] ?? ''}') ?? 0;
    final groupId = '${data['group_id'] ?? ''}';
    if (callId <= 0 || groupId.isEmpty) return;

    final media = (data['media']?.toString() == 'video') ? 'video' : 'audio';
    final name = data['group_name']?.toString();

    final key = '$callId|$groupId';
    if (!_handledGroupCalls.add(key)) return;

    _openGroupIncoming(
      callId: callId,
      groupId: groupId,
      media: media,
      groupName: name,
    );
  }

  static void _tryOpenFromPayload(
    String raw,
    String? callerName,
    String? callerAvatar, {
    Map<String, dynamic>? extraData,
  }) {
    CallInvite? inv = CallInvite.tryParse(raw);
    // fallback: parse trực tiếp data map nếu không embed trong text
    if (inv == null && extraData != null) {
      final callId = int.tryParse('${extraData['call_id'] ?? ''}') ?? 0;
      final media =
          (extraData['media']?.toString() == 'video') ? 'video' : 'audio';
      final ts = int.tryParse('${extraData['ts'] ?? 0}') ??
          DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (callId > 0) {
        inv = CallInvite(
          callId: callId,
          media: media,
          issuedAt: DateTime.fromMillisecondsSinceEpoch(ts * 1000),
        );
      }
    }
    if (inv == null || inv.isExpired()) return;

    if (!_handledCallIds.add(inv.callId)) return; // dedup same call_id

    _openIncoming(inv, callerName: callerName, callerAvatar: callerAvatar);
  }

  static void _openIncoming(CallInvite inv,
      {String? callerName, String? callerAvatar}) {
    if (_routing) return;

    final nav = navigatorKey.currentState;
    final ctx = nav?.overlay?.context ?? navigatorKey.currentContext;

    if (nav == null || ctx == null || !ctx.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openIncoming(inv,
          callerName: callerName, callerAvatar: callerAvatar));
      return;
    }

    _routing = true;

    try {
      ctx.read<CallController>().attachCall(
            callId: inv.callId,
            mediaType: inv.mediaType,
            initialStatus: 'ringing',
          );
    } catch (_) {}

    nav
        .push(
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          callId: inv.callId,
          mediaType: inv.mediaType,
          callerName: callerName,
          callerAvatar: callerAvatar,
        ),
      ),
    )
        .whenComplete(() {
      _routing = false;
    });
  }

  static void _openGroupIncoming({
    required int callId,
    required String groupId,
    required String media,
    String? groupName,
  }) {
    if (_routing) return;

    final nav = navigatorKey.currentState;
    final ctx = nav?.overlay?.context ?? navigatorKey.currentContext;

    if (nav == null || ctx == null || !ctx.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openGroupIncoming(
            callId: callId,
            groupId: groupId,
            media: media,
            groupName: groupName,
          ));
      return;
    }

    _routing = true;

    try {
      // Warm up controller state if needed
      final gc = ctx.read<GroupCallController>();
      gc.currentCallId = callId;
      gc.status = CallStatus.ringing;
    } catch (_) {}

    nav
        .push(
      MaterialPageRoute(
        builder: (_) => GroupCallScreen(
          groupId: groupId,
          mediaType: media,
          callId: callId,
          groupName: groupName,
        ),
      ),
    )
        .whenComplete(() {
      _routing = false;
    });
  }
}
