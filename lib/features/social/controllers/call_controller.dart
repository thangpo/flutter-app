import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../domain/models/ice_candidate_lite.dart';
import '../domain/repositories/webrtc_signaling_repository.dart';

/// CallController quản lý state & signaling cho 1-1 call (WebRTC).
/// Tương thích với code cũ:
/// - getter: ready, activeCallId, activeMediaType
/// - methods: init(), startCall({calleeId, mediaType}), endCall(),
///            attachIncoming({callId, mediaType})
/// Đồng thời cung cấp: sendOffer/Answer/Candidate, action(), attachCall().
class CallController extends ChangeNotifier {
  CallController({WebRTCSignalingRepository? signaling})
      : signaling = signaling ?? WebRTCSignalingRepository();

  // ====== deps ======
  final WebRTCSignalingRepository signaling;

  // ====== state ======
  bool _ready = false;
  int? _callId;
  String _mediaType = 'audio'; // 'audio' | 'video'
  String _callStatus = 'ringing'; // ringing | answered | declined | ended
  String? _sdpOffer;
  String? _sdpAnswer;

  final List<IceCandidateLite> _iceCandidates = [];
  final Set<String> _seenOtherCandidates = {}; // de-dup theo candidate string

  Timer? _pollTimer;
  bool _isPolling = false;
  bool _disposed = false;

  String? lastError; // tiện debug

  // ====== getters (compat + extra) ======
  bool get ready => _ready;
  int? get activeCallId => _callId;
  String get activeMediaType => _mediaType;
  String get callStatus => _callStatus;
  String? get sdpOffer => _sdpOffer;
  String? get sdpAnswer => _sdpAnswer;
  List<IceCandidateLite> get iceCandidates => List.unmodifiable(_iceCandidates);

  // ====== lifecycle ======
  Future<void> init() async {
    // Nếu cần preload gì thêm thì thêm ở đây.
    _ready = true;
    notifyListeners();
  }

  // ====== public high-level APIs (compat với chat_screen cũ) ======

  /// Caller bắt đầu cuộc gọi.
  Future<int> startCall({
    required int calleeId,
    required String mediaType,
  }) async {
    try {
      final created = await signaling.create(
        recipientId: calleeId,
        mediaType: mediaType,
      );
      _attachCall(
        callId: created.callId,
        mediaType: created.mediaType,
        initialStatus: created.status,
      );
      return created.callId; // <<< quan trọng
    } catch (e) {
      lastError = '$e';
      rethrow;
    }
  }

  /// Callee/caller gắn vào call có sẵn (ví dụ từ tin nhắn invite).
  Future<void> attachIncoming({
    required int callId,
    required String mediaType,
  }) async {
    _attachCall(callId: callId, mediaType: mediaType, initialStatus: 'ringing');
  }

  /// Kết thúc cuộc gọi (cả 2 phía có thể gọi).
  Future<void> endCall() async {
    final id = _callId;
    if (id != null) {
      try {
        await signaling.action(callId: id, action: 'end');
      } catch (e) {
        lastError = '$e';
      }
    }
    await detachCall();
  }

  // ====== lower-level (để IncomingCallScreen/CallScreen dùng) ======

  /// Dùng khi caller muốn explicit "create" để lấy callId.
  Future<int> createCall({
    required int recipientId,
    required String mediaType,
  }) async {
    final res =
        await signaling.create(recipientId: recipientId, mediaType: mediaType);
    _attachCall(
      callId: res.callId,
      mediaType: res.mediaType,
      initialStatus: res.status,
    );
    return res.callId;
  }

  /// Cho phép gắn call khi đã có callId (ví dụ FCM call_invite).
  void attachCall({
    required int callId,
    required String mediaType,
    String initialStatus = 'ringing',
  }) {
    _attachCall(
      callId: callId,
      mediaType: mediaType,
      initialStatus: initialStatus,
    );
  }

  Future<void> detachCall() async {
    _stopPolling();
    _resetState(ended: true);
    notifyListeners();
  }

  Future<void> sendOffer(String sdp) async {
    final id = _callId;
    if (id == null) return;
    try {
      await signaling.offer(callId: id, sdp: sdp);
      // chờ answer qua poll
    } catch (e) {
      lastError = '$e';
      rethrow;
    }
  }

  Future<void> sendAnswer(String sdp) async {
    final id = _callId;
    if (id == null) return;
    try {
      await signaling.answer(callId: id, sdp: sdp);
      // server set status='answered' trong 'answer'
      _callStatus = 'answered';
      notifyListeners();

      // gọi action('answer') để chắc trạng thái đồng bộ (idempotent)
      try {
        final st = await signaling.action(callId: id, action: 'answer');
        _callStatus = st.isNotEmpty ? st : 'answered';
        notifyListeners();
      } catch (_) {}
    } catch (e) {
      lastError = '$e';
      rethrow;
    }
  }

  Future<void> sendCandidate({
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  }) async {
    final id = _callId;
    if (id == null) return;
    try {
      await signaling.candidate(
        callId: id,
        candidate: candidate,
        sdpMid: sdpMid,
        sdpMLineIndex: sdpMLineIndex,
      );
    } catch (e) {
      lastError = '$e';
      // không rethrow để không cản luồng ICE gửi tiếp
    }
  }

  /// action: 'answer' | 'decline' | 'end'
  Future<void> action(String action) async {
    final id = _callId;
    if (id == null) return;
    try {
      final st = await signaling.action(callId: id, action: action);
      _callStatus = st; // answered / declined / ended
      if (st == 'declined' || st == 'ended') {
        _stopPolling();
      }
      notifyListeners();
    } catch (e) {
      lastError = '$e';
      rethrow;
    }
  }

  // ====== internal ======
  void _attachCall({
    required int callId,
    required String mediaType,
    String initialStatus = 'ringing',
  }) {
    _callId = callId;
    _mediaType = (mediaType == 'video') ? 'video' : 'audio';
    _callStatus = initialStatus;
    _sdpOffer = null;
    _sdpAnswer = null;
    _iceCandidates.clear();
    _seenOtherCandidates.clear();
    _startPolling();
    notifyListeners();
  }

  void _startPolling() {
    if (_isPolling) return;
    _isPolling = true;

    // Hủy timer cũ nếu lỡ còn
    _pollTimer?.cancel();
    _pollTimer = null;

    _pollOnce(); // poll ngay 1 nhịp
    _pollTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      _pollOnce();
    });
  }

  void _stopPolling() {
    _isPolling = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollOnce() async {
    if (_disposed) return;
    final id = _callId;
    if (id == null) return;

    try {
      final p = await signaling.poll(callId: id);

      // status
      if (p.callStatus != null && p.callStatus!.isNotEmpty) {
        _callStatus = p.callStatus!;
      }

      // media type (phòng server đổi)
      if (p.mediaType != null && p.mediaType!.isNotEmpty) {
        _mediaType = (p.mediaType == 'video') ? 'video' : 'audio';
      }

      // SDP từ phía đối diện
      if (p.sdpOffer != null && p.sdpOffer!.isNotEmpty) {
        _sdpOffer = p.sdpOffer!;
      }
      if (p.sdpAnswer != null && p.sdpAnswer!.isNotEmpty) {
        _sdpAnswer = p.sdpAnswer!;
      }

      // ICE candidates của phía đối diện
      if (p.iceCandidates.isNotEmpty) {
        for (final c in p.iceCandidates) {
          // de-dup đơn giản theo candidate string
          if (_seenOtherCandidates.add(c.candidate)) {
            _iceCandidates.add(c);
          }
        }
      }

      // Nếu đã kết thúc -> dừng poll
      if (_callStatus == 'declined' || _callStatus == 'ended') {
        _stopPolling();
      }

      notifyListeners();
    } catch (e) {
      // im lặng 1 nhịp, tiếp tục poll; lưu lastError để debug
      lastError = '$e';
    }
  }

  void _resetState({bool ended = false}) {
    _callId = null;
    _sdpOffer = null;
    _sdpAnswer = null;
    _iceCandidates.clear();
    _seenOtherCandidates.clear();
    _callStatus = ended ? 'ended' : 'ringing';
  }

  @override
  void dispose() {
    _disposed = true;
    _stopPolling();
    super.dispose();
  }
}
