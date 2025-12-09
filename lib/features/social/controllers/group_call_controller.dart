// lib/features/social/controllers/group_call_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/webrtc_group_signaling_repository.dart';

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
  // ⏱ cấu hình poll
  static const Duration _pollInterval = Duration(milliseconds: 300); // poll 0.3s
  static const int _peersRefreshEveryNTicks = 10; // 10 * 0.3s ≈ 3s refresh peers
  static const int _emptyPeersCloseThreshold = 10; // 10 tick trống ≈ 3s mới auto close

  void Function(Map<String, dynamic> ev)? onOffer;
  void Function(Map<String, dynamic> ev)? onAnswer;
  void Function(Map<String, dynamic> ev)? onCandidate;

  void Function(Set<int> peers)? onPeersChanged;
  void Function(CallStatus status)? onStatusChanged;

  bool _isCreator = false;
  bool get isCreator => _isCreator;

  // ✅ auto-close khi peer rỗng liên tục (member)
  int _emptyPeersCount = 0;

  void init() {}

  // ====================== WATCH INBOX ======================
  Timer? _inboxTimer;
  String? _watchGroupId;
  int? _lastNotifiedCallId;
  void Function(Map<String, dynamic> call)? onIncoming;

  void watchGroupInbox(
    String groupId, {
    Duration period = const Duration(seconds: 3),
    bool autoOpen = false, // giữ tham số cho tương thích
  }) {
    if (_watchGroupId != null && _watchGroupId != groupId) {
      stopWatchingInbox();
    }
    _watchGroupId = groupId;
    _inboxTick();
    _inboxTimer?.cancel();
    _inboxTimer = Timer.periodic(period, (_) => _inboxTick());
    debugPrint(
        '[GROUP-INBOX] Watching group=$groupId every ${period.inSeconds}s');
  }

  void stopWatchingInbox() {
    _inboxTimer?.cancel();
    _inboxTimer = null;
    _watchGroupId = null;
    _lastNotifiedCallId = null;
    debugPrint('[GROUP-INBOX] Stopped watching.');
  }

  Future<void> forceCheckInbox() async => _inboxTick();

  Future<void> _inboxTick() async {
    final gid = _watchGroupId;
    if (gid == null) return;

    try {
      final call = await signaling.inbox(groupId: gid);
      if (call == null) return;

      final callId = _asInt(call['call_id']) ?? _asInt(call['id']);
      final statusStr = '${call['status'] ?? ''}';
      final media = (call['media'] == 'video') ? 'video' : 'audio';

      if (callId == null || _lastNotifiedCallId == callId) return;
      if (statusStr != 'ringing' && statusStr != 'ongoing') return;

      debugPrint(
          '[GROUP-INBOX] Incoming call: call_id=$callId, gid=$gid, media=$media, status=$statusStr');
      _lastNotifiedCallId = callId;

      onIncoming?.call({
        'call_id': callId,
        'group_id': gid,
        'media': media,
        'status': statusStr,
      });
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
      debugPrint('[GROUP-CALL] ❌ no_call_id from response: $resp');
      throw Exception('no_call_id');
    }

    _isCreator = true;
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
    _isCreator = false;
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
      // Phát 1 nhịp 'ended' để UI nắm bắt rồi cleanup → idle
      status = CallStatus.ended;
      _emitStatus();
      _cleanup();
    }
  }

  // ====================== SEND SIGNALS ======================
  Future<void> sendOffer({
    required int callId,
    required int toUserId,
    required String sdp,
  }) async {
    await signaling.offer(callId: callId, toUserId: toUserId, sdp: sdp);
  }

  Future<void> sendAnswer({
    required int callId,
    required int toUserId,
    required String sdp,
  }) async {
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
      sdpMLineIndex: sdpMLineIndex?.toString(),
    );
  }

  // ====================== POLLING SIGNALS ======================
  void _startPolling() {
    if (currentCallId == null) return;
    _pollingEnabled = true;
    _pollTimer?.cancel();
    _tick = 0;
    _emptyPeersCount = 0;
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollOnce());
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
            case 'ended':
              status = CallStatus.ended;
              _emitStatus();
              _cleanup();
              return;
            case 'offer':
              onOffer?.call(ev);
              break;
            case 'answer':
              onAnswer?.call(ev);
              break;
            case 'candidate':
              onCandidate?.call(ev);
              break;
          }
        }
      }

      // refresh peers mỗi 2s (prod có thể tăng 5s)
      _tick = (_tick + 1) % _peersRefreshEveryNTicks;
      if (_tick == 0) {
        final newPeers = await signaling.peers(callId: callId);
        final newSet = newPeers.toSet();

        // cập nhật participants
        if (!_setEquals(participants, newSet)) {
          participants
            ..clear()
            ..addAll(newSet);
          onPeersChanged?.call(Set<int>.from(participants));
          notifyListeners();
        }

        // ✅ Auto-close cho member nếu không còn ai trong 3 lần liên tiếp (~3s)
        if (!_isCreator) {
          _emptyPeersCount = participants.isEmpty ? (_emptyPeersCount + 1) : 0;
          if (_emptyPeersCount >= _emptyPeersCloseThreshold) {
            _cleanup();
            return;
          }
        } else {
          _emptyPeersCount = 0;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GROUP-POLL] error: $e');
      }
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
    _isCreator = false;
    notifyListeners();
    _emitStatus();
    if (kDebugMode) {
      debugPrint('GroupCallController: cleaned up (old call $oldId)');
    }
  }

  int? _extractCallId(dynamic resp) {
    if (resp == null) return null;
    if (resp is Map) {
      dynamic v = resp['call_id'] ??
          resp['id'] ??
          resp['data']?['call_id'] ??
          resp['call']?['id'] ??
          resp['call']?['call_id'];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
    }
    debugPrint('[GROUP-CALL] ⚠️ _extractCallId failed: $resp');
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
