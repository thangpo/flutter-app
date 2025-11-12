//G:\flutter-app\lib\features\social\controllers\group_call_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/webrtc_group_signaling_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/group_call_screen.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart' show navigatorKey;

enum CallStatus { idle, ringing, ongoing, ended }

class GroupCallController extends ChangeNotifier {
  final GroupWebRTCSignalingRepository signaling;
  GroupCallController({required this.signaling});

  int? currentCallId;
  CallStatus status = CallStatus.idle;
  final Set<int> participants = <int>{};

  bool _pollingEnabled = false;
  Timer? _pollTimer;
  bool _pollInFlight = false;

  int _tick = 0;

  void Function(Map<String, dynamic> ev)? onOffer;
  void Function(Map<String, dynamic> ev)? onAnswer;
  void Function(Map<String, dynamic> ev)? onCandidate;

  void Function(Set<int> peers)? onPeersChanged;
  void Function(CallStatus status)? onStatusChanged;

  void init() {}

  // ====================== WATCH INBOX ======================
  Timer? _inboxTimer;
  String? _watchGroupId;
  int? _lastNotifiedCallId; // dedupe theo call_id
  bool _opening = false;
  void Function(Map<String, dynamic> call)? onIncoming;

  void watchGroupInbox(
    String groupId, {
    Duration period = const Duration(seconds: 3),
    bool autoOpen = true,
  }) {
    if (_watchGroupId != null && _watchGroupId != groupId) {
      stopWatchingInbox();
    }
    _watchGroupId = groupId;
    _inboxTick(autoOpen: autoOpen);
    _inboxTimer?.cancel();
    _inboxTimer = Timer.periodic(period, (_) => _inboxTick(autoOpen: autoOpen));
    debugPrint(
        '[GROUP-INBOX] Watching group=$groupId every ${period.inSeconds}s');
  }

  void stopWatchingInbox() {
    _inboxTimer?.cancel();
    _inboxTimer = null;
    _watchGroupId = null;
    _lastNotifiedCallId = null;
    _opening = false;
    debugPrint('[GROUP-INBOX] Stopped watching.');
  }

  Future<void> forceCheckInbox({bool autoOpen = true}) async {
    await _inboxTick(autoOpen: autoOpen);
  }

  Future<void> _inboxTick({required bool autoOpen}) async {
    final gid = _watchGroupId;
    if (gid == null) return;

    try {
      final call = await signaling.inbox(groupId: gid);
      if (call == null) return;

      final callId = _asInt(call['call_id']) ?? _asInt(call['id']);
      final statusStr = '${call['status'] ?? ''}';
      final media = (call['media'] == 'video') ? 'video' : 'audio';

      // ✅ DEDUPE theo call_id, KHÔNG dựa vào 'joined' (server có thể trả sai)
      if (callId == null || _lastNotifiedCallId == callId) return;
      if (statusStr != 'ringing' && statusStr != 'ongoing') return;

      debugPrint(
          '[GROUP-INBOX] Incoming group-call: call_id=$callId, gid=$gid, media=$media, status=$statusStr');
      _lastNotifiedCallId = callId;

      onIncoming?.call({
        'call_id': callId,
        'group_id': gid,
        'media': media,
        'status': statusStr,
      });

      // Chỉ autoOpen khi được yêu cầu và chưa mở
      if (autoOpen && !_opening) {
        _opening = true;
        final nav = navigatorKey.currentState;
        if (nav != null) {
          await nav.push(
            MaterialPageRoute(
              builder: (_) => GroupCallScreen(
                groupId: gid,
                mediaType: media,
                callId: callId, // attach & join
                groupName: 'Cuộc gọi nhóm',
              ),
            ),
          );
        }
        _opening = false;
      }
    } catch (e) {
      debugPrint('[GROUP-INBOX] inbox error: $e');
    }
  }

  // ====================== CALLER FLOW ======================
  Future<Map<String, dynamic>> joinRoom({
    required String groupId,
    required String mediaType,
    List<int>? invitees,
  }) async {
    final resp = await signaling.create(
      groupId: groupId,
      media: (mediaType == 'video') ? 'video' : 'audio',
      participants: invitees,
    );
    final callId = _extractCallId(resp);
    if (callId == null) {
      throw Exception('no_call_id');
    }
    currentCallId = callId;
    status = CallStatus.ringing;
    notifyListeners();
    _emitStatus();

    await _joinInternal(callId);
    _startPolling();
    return resp;
  }

  // ====================== CALLEE FLOW ======================
  Future<void> attachAndJoin({required int callId}) async {
    currentCallId = callId;
    status = CallStatus.ongoing;
    notifyListeners();
    _emitStatus();

    await _joinInternal(callId);
    _startPolling();
  }

  // ====================== LEAVE / END ======================
  Future<void> leaveRoom(int callId) async {
    try {
      await signaling.leave(callId: callId);
    } finally {
      _cleanup();
    }
  }

  Future<void> endRoom(int callId) async {
    try {
      await signaling.end(callId: callId);
    } finally {
      _cleanup();
    }
  }

  // ====================== SEND SIGNALS ======================
  Future<void> sendOffer(
      {required int callId, required int toUserId, required String sdp}) async {
    await signaling.offer(callId: callId, toUserId: toUserId, sdp: sdp);
  }

  Future<void> sendAnswer(
      {required int callId, required int toUserId, required String sdp}) async {
    await signaling.answer(callId: callId, toUserId: toUserId, sdp: sdp);
  }

  Future<void> sendCandidate({
    required int callId,
    required int toUserId,
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  }) async {
    await signaling.candidate(
      callId: callId,
      toUserId: toUserId,
      candidate: candidate,
      sdpMid: sdpMid,
      sdpMLineIndex: sdpMLineIndex,
    );
  }

  // ====================== POLLING SIGNALS ======================
  void _startPolling() {
    if (currentCallId == null) return;
    _pollingEnabled = true;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) => _pollOnce());
  }

  void _stopPolling() {
    _pollingEnabled = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollOnce() async {
    if (!_pollingEnabled || _pollInFlight) return;
    final callId = currentCallId;
    if (callId == null) return;

    _pollInFlight = true;
    try {
      final events = await signaling.poll(callId: callId);
      if (events.isNotEmpty) {
        for (final ev in events) {
          final type = (ev['type'] ?? '').toString();
          switch (type) {
            case 'offer':
              onOffer?.call(ev);
              break;
            case 'answer':
              onAnswer?.call(ev);
              break;
            case 'candidate':
              onCandidate?.call(ev);
              break;
            default:
              break;
          }
        }
      }

      // refresh peers mỗi 5s
      _tick = (_tick + 1) % 5;
      if (_tick == 0) {
        final newPeers = await signaling.peers(callId: callId);
        final newSet = newPeers.toSet();
        if (!_setEquals(participants, newSet)) {
          participants
            ..clear()
            ..addAll(newSet);
          onPeersChanged?.call(Set<int>.from(participants));
          notifyListeners();
        }
      }
    } catch (_) {
    } finally {
      _pollInFlight = false;
    }
  }

  // ====================== INTERNALS ======================
  Future<void> _joinInternal(int callId) async {
    final peers = await signaling.join(callId: callId);
    participants
      ..clear()
      ..addAll(peers);
    status = CallStatus.ongoing;
    notifyListeners();
    _emitStatus();
    onPeersChanged?.call(Set<int>.from(participants));
  }

  void _cleanup() {
    _stopPolling();
    participants.clear();
    status = CallStatus.idle;
    final oldId = currentCallId;
    currentCallId = null;
    notifyListeners();
    _emitStatus();
    if (kDebugMode) {
      print('GroupCallController: cleaned up (old call $oldId)');
    }
  }

  int? _extractCallId(dynamic resp) {
    if (resp is Map) {
      dynamic v = resp['call_id'] ??
          resp['id'] ??
          (resp['data'] is Map ? (resp['data'] as Map)['call_id'] : null) ??
          (resp['call'] is Map ? (resp['call'] as Map)['id'] : null) ??
          (resp['call'] is Map ? (resp['call'] as Map)['call_id'] : null);
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
    }
    return null;
  }

  bool _setEquals(Set<int> a, Set<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  void _emitStatus() {
    onStatusChanged?.call(status);
  }

  @override
  void dispose() {
    _stopPolling();
    stopWatchingInbox();
    super.dispose();
  }
}
