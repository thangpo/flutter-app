// lib/features/social/controllers/group_call_controller.dart
//
// Controller quản lý vòng đời group call (P2P full-mesh):
// - Caller: create -> join -> peers -> start polling
// - Callee: attachAndJoin(callId) -> peers -> start polling
// - Polling 1s: nhận offer/answer/candidate gửi cho mình và bắc cầu ra callbacks
// - Theo dõi participants (peers online), trạng thái call
// - NEW: watchGroupInbox(groupId) -> 3s/poll inbox để auto mời vào phòng call
//
// YÊU CẦU:
// - Repo: GroupWebRTCSignalingRepository có method inbox({groupId})
// - Có navigatorKey trong main.dart
// - GroupCallScreen(groupId, mediaType) đã sẵn
//
// TÍCH HỢP NHANH TRONG GroupChatScreen:
//   context.read<GroupCallController>().watchGroupInbox(widget.groupId, autoOpen: true);
//   @override dispose() { context.read<GroupCallController>().stopWatchingInbox(); super.dispose(); }

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

  /// Call hiện tại (nếu có)
  int? currentCallId;

  /// Trạng thái call
  CallStatus status = CallStatus.idle;

  /// Danh sách userId peers đang tham gia (trừ mình)
  final Set<int> participants = <int>{};

  /// Tự động polling?
  bool _pollingEnabled = false;
  Timer? _pollTimer;
  bool _pollInFlight = false;

  /// Đếm nhịp để refresh peers định kỳ (5s/lần)
  int _tick = 0;

  /// Callbacks bắc cầu sang lớp WebRTC/PeerManager
  void Function(Map<String, dynamic> ev)? onOffer;
  void Function(Map<String, dynamic> ev)? onAnswer;
  void Function(Map<String, dynamic> ev)? onCandidate;

  /// Callback khi đổi peers (đã lọc trùng)
  void Function(Set<int> peers)? onPeersChanged;

  /// Callback khi trạng thái thay đổi
  void Function(CallStatus status)? onStatusChanged;

  /// no-op để giữ tương thích nếu nơi khác có gọi
  void init() {}

  // ====================== WATCH INBOX (NEW) ======================
  Timer? _inboxTimer;
  String? _watchGroupId;
  int? _lastNotifiedCallId; // chống notify/mở trùng
  bool _opening = false; // chống mở màn call trùng
  void Function(Map<String, dynamic> call)? onIncoming; // nếu muốn tự UI

  /// Bắt đầu theo dõi inbox call của 1 group.
  /// - [period]: chu kỳ poll, mặc định 3s.
  /// - [autoOpen]: nếu true và phát hiện cuộc gọi, tự push GroupCallScreen.
  void watchGroupInbox(
    String groupId, {
    Duration period = const Duration(seconds: 3),
    bool autoOpen = true,
  }) {
    if (_watchGroupId != null && _watchGroupId != groupId) {
      stopWatchingInbox();
    }
    _watchGroupId = groupId;

    // Tick ngay 1 lần
    _inboxTick(autoOpen: autoOpen);

    _inboxTimer?.cancel();
    _inboxTimer = Timer.periodic(period, (_) => _inboxTick(autoOpen: autoOpen));
    debugPrint(
        '[GROUP-INBOX] Watching group=$groupId every ${period.inSeconds}s');
  }

  /// Dừng watcher (gọi khi rời màn chat)
  void stopWatchingInbox() {
    _inboxTimer?.cancel();
    _inboxTimer = null;
    _watchGroupId = null;
    _lastNotifiedCallId = null;
    _opening = false;
    debugPrint('[GROUP-INBOX] Stopped watching.');
  }

  /// Thực hiện 1 lần poll ngay
  Future<void> forceCheckInbox({bool autoOpen = true}) async {
    await _inboxTick(autoOpen: autoOpen);
  }

  Future<void> _inboxTick({required bool autoOpen}) async {
    final gid = _watchGroupId;
    if (gid == null) return;

    try {
      final call = await signaling.inbox(groupId: gid);
      if (call == null) return;

      final callId = _asInt(call['call_id']);
      final statusStr =
          '${call['status'] ?? ''}'; // 'ringing' | 'ongoing' | ...
      final media = (call['media'] == 'video') ? 'video' : 'audio';
      final joined = call['joined'] == true || '${call['joined']}' == '1';

      if (callId != null && _lastNotifiedCallId == callId) return;
      if (joined) {
        _lastNotifiedCallId = callId;
        return;
      }
      if (statusStr != 'ringing' && statusStr != 'ongoing') return;

      debugPrint(
          '[GROUP-INBOX] Incoming group-call: call_id=$callId, gid=$gid, media=$media, status=$statusStr');
      _lastNotifiedCallId = callId;

      // Cho phép app tự hiện UI nếu muốn
      if (onIncoming != null) onIncoming!(call);

      // Tự mở phòng gọi nếu bật autoOpen
      if (autoOpen && !_opening) {
        _opening = true;
        final nav = navigatorKey.currentState;
        if (nav != null) {
          await nav.push(
            MaterialPageRoute(
              builder: (_) => GroupCallScreen(
                groupId: gid,
                mediaType: media, // 'audio' | 'video'
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
  /// Caller: tạo call mới, join vào, tải peers ban đầu, khởi động polling.
  /// Trả về response từ server (chứa call_id).
  Future<Map<String, dynamic>> joinRoom({
    required String groupId,
    required String mediaType, // 'audio' | 'video'
    List<int>? invitees, // optional: mời người khác, server có thể push FCM
  }) async {
    // Create
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

    // Join
    await _joinInternal(callId);

    // Start polling
    _startPolling();

    return resp;
  }

  // ====================== CALLEE FLOW ======================
  /// Callee: gắn vào call đã có (callId) và bắt đầu polling.
  Future<void> attachAndJoin({required int callId}) async {
    currentCallId = callId;
    status = CallStatus.ongoing; // có thể set ringing -> ongoing khi join xong
    notifyListeners();
    _emitStatus();

    await _joinInternal(callId);
    _startPolling();
  }

  // ====================== LEAVE / END ======================
  /// Người thường rời call
  Future<void> leaveRoom(int callId) async {
    try {
      await signaling.leave(callId: callId);
    } finally {
      _cleanup();
    }
  }

  /// Creator kết thúc call
  Future<void> endRoom(int callId) async {
    try {
      await signaling.end(callId: callId);
    } finally {
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
      // 1) Nhận tín hiệu gửi cho mình
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

      // 2) 5s/lần: refresh danh sách peers (đã join)
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
      // có thể log chi tiết nếu cần
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
    status = CallStatus.ongoing; // sau join coi như ongoing
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
      // ignore: avoid_print
      print('GroupCallController: cleaned up (old call $oldId)');
    }
  }

  int? _extractCallId(dynamic resp) {
    if (resp is Map) {
      dynamic v = resp['call_id'] ??
          resp['id'] ??
          (resp['data'] is Map ? (resp['data'] as Map)['call_id'] : null) ??
          (resp['call'] is Map ? (resp['call'] as Map)['id'] : null);
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
