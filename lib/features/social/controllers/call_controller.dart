// lib/features/social/controllers/call_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../domain/models/ice_candidate_lite.dart';
import '../domain/repositories/webrtc_signaling_repository.dart';

class CallController extends ChangeNotifier {
  CallController({required this.signaling});

  // ===== DEPENDENCY =====
  final WebRTCSignalingRepository signaling;

  // ===== STATE =====
  bool _ready = false;

  int? _callId;
  String _mediaType = "audio"; // audio | video
  String _callStatus = "ringing"; // ringing | answered | declined | ended

  String? _sdpOffer;
  String? _sdpAnswer;

  final List<IceCandidateLite> _iceCandidates = [];
  final Set<String> _seen = {}; // dedup ICE

  Timer? _pollTimer;
  bool _polling = false;
  bool _disposed = false;

  String? lastError;

  // ===== GETTERS =====
  bool get ready => _ready;
  int? get activeCallId => _callId;
  String get activeMediaType => _mediaType;
  String get callStatus => _callStatus;
  String? get sdpOffer => _sdpOffer;
  String? get sdpAnswer => _sdpAnswer;
  List<IceCandidateLite> get iceCandidates => List.unmodifiable(_iceCandidates);

  // ===== INIT =====
  Future<void> init() async {
    _ready = true;
    notifyListeners();
  }

  // =====================================================================
  // PUBLIC APIs (để ChatScreen / IncomingCallScreen / CallScreen gọi tới)
  // =====================================================================

  /// Caller bắt đầu gọi
  Future<int> startCall({
    required int calleeId,
    required String mediaType,
  }) async {
    try {
      final res = await signaling.create(
        recipientId: calleeId,
        mediaType: mediaType,
      );

      _attach(
        res.callId,
        res.mediaType,
        res.status,
      );

      return res.callId;
    } catch (e) {
      lastError = "$e";
      rethrow;
    }
  }

  /// Từ FCM hoặc chỗ khác → gắn cuộc gọi có sẵn
  void attachCall({
    required int callId,
    required String mediaType,
    String initialStatus = "ringing",
  }) {
    _attach(callId, mediaType, initialStatus);
  }

  /// ✅ Giữ lại cho code cũ: attachIncoming() = alias của attachCall()
  Future<void> attachIncoming({
    required int callId,
    required String mediaType,
  }) async {
    attachCall(callId: callId, mediaType: mediaType, initialStatus: "ringing");
  }

  /// Khi nhấn từ chối / peer từ chối / peer end
  Future<void> detachCall() async {
    _stopPolling();
    _resetState(ended: true);
    notifyListeners();
  }

  /// Caller/Callee → gửi OFFER
  Future<void> sendOffer(String sdp) async {
    final id = _callId;
    if (id == null) return;

    try {
      await signaling.offer(callId: id, sdp: sdp);
    } catch (e) {
      lastError = "$e";
      rethrow;
    }
  }

  /// Gửi ANSWER
  Future<void> sendAnswer(String sdp) async {
    final id = _callId;
    if (id == null) return;

    try {
      await signaling.answer(callId: id, sdp: sdp);
      _callStatus = "answered";
      notifyListeners();

      // idempotent, update server status
      try {
        final st = await signaling.action(callId: id, action: "answer");
        if (st.isNotEmpty) _callStatus = st;
        notifyListeners();
      } catch (_) {}
    } catch (e) {
      lastError = "$e";
      rethrow;
    }
  }

  /// gửi ICE
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
      lastError = "$e";
    }
  }

  /// action: answer | decline | end
  Future<void> action(String action) async {
    final id = _callId;
    if (id == null) return;

    try {
      final st = await signaling.action(callId: id, action: action);
      _callStatus = st;

      if (st == "declined" || st == "ended") {
        _stopPolling();
      }
      notifyListeners();
    } catch (e) {
      lastError = "$e";
      rethrow;
    }
  }

  /// Caller nhấn "Hủy" khi đang gọi → end
  Future<void> endCall() async {
    final id = _callId;
    if (id != null) {
      try {
        await signaling.action(callId: id, action: "end");
      } catch (_) {}
    }
    await detachCall();
  }

  // =====================================================================
  // INTERNAL
  // =====================================================================

  void _attach(
    int callId,
    String mediaType,
    String initialStatus,
  ) {
    _callId = callId;
    _mediaType = (mediaType == "video") ? "video" : "audio";
    _callStatus = initialStatus;

    _sdpOffer = null;
    _sdpAnswer = null;
    _iceCandidates.clear();
    _seen.clear();

    _startPolling();
    notifyListeners();
  }

  void _startPolling() {
    if (_polling) return;

    _polling = true;
    _pollTimer?.cancel();

    _pollOnce(); // chạy ngay 1 nhịp

    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 900),
      (_) => _pollOnce(),
    );
  }

  void _stopPolling() {
    _polling = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollOnce() async {
    if (_disposed) return;

    final id = _callId;
    if (id == null) return;

    try {
      final pkt = await signaling.poll(callId: id);

      // status
      if (pkt.callStatus != null && pkt.callStatus!.isNotEmpty) {
        _callStatus = pkt.callStatus!;
      }

      // type
      if (pkt.mediaType != null && pkt.mediaType!.isNotEmpty) {
        _mediaType = pkt.mediaType!;
      }

      // SDP
      if (pkt.sdpOffer != null && pkt.sdpOffer!.isNotEmpty) {
        _sdpOffer = pkt.sdpOffer!;
      }
      if (pkt.sdpAnswer != null && pkt.sdpAnswer!.isNotEmpty) {
        _sdpAnswer = pkt.sdpAnswer!;
      }

      // ICE
      if (pkt.iceCandidates.isNotEmpty) {
        for (final c in pkt.iceCandidates) {
          if (_seen.add(c.candidate)) {
            _iceCandidates.add(c);
          }
        }
      }

      // if ended → stop
      if (_callStatus == "declined" || _callStatus == "ended") {
        _stopPolling();
      }

      notifyListeners();
    } catch (e) {
      lastError = "$e";
    }
  }

  void _resetState({bool ended = false}) {
    _callId = null;
    _sdpOffer = null;
    _sdpAnswer = null;
    _iceCandidates.clear();
    _seen.clear();
    _callStatus = ended ? "ended" : "ringing";
  }

  @override
  void dispose() {
    _disposed = true;
    _stopPolling();
    super.dispose();
  }
}
