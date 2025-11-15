import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/webrtc_signaling_repository.dart';

/// Quản lý WebRTC signaling (server WoWonder).
class CallController extends ChangeNotifier {
  WebRTCSignalingRepository? _repo;
  Future<void>? _initFuture;

  bool ready = false;
  String? lastError;

  int? activeCallId;
  String activeMediaType = 'audio'; // 'audio' | 'video'
  Timer? _pollTimer;

  // Trạng thái poll gần nhất
  String callStatus = ''; // ringing | answered | declined | ended
  String? sdpOffer;
  String? sdpAnswer;
  List<IceCandidatePayload> iceCandidates = const [];

  Future<void> init({bool force = false}) async {
    if (force) {
      _repo = null;
      ready = false;
      _initFuture = null;
    }
    await ensureInitialized();
  }

  Future<void> ensureInitialized() async {
    if (ready && _repo != null) return;
    _initFuture ??= _doInit();
    try {
      await _initFuture;
    } catch (e) {
      _initFuture = null;
      rethrow;
    }
  }

  Future<void> _doInit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.socialAccessToken) ?? '';
      final serverKey = AppConstants.socialServerKey;

      _repo = WebRTCSignalingRepository(
        baseUrl: '${AppConstants.socialBaseUrl}/api/webrtc',
        accessToken: token,
        serverKey: serverKey,
      );

      ready = true;
      lastError = null;
      notifyListeners();
    } catch (e) {
      ready = false;
      lastError = '$e';
      notifyListeners();
      rethrow;
    }
  }

  bool get isInCall => activeCallId != null;

  /// Caller bắt đầu gọi
  Future<int> startCall(
      {required int calleeId, String mediaType = 'video'}) async {
    await _ensureRepo();
    try {
      final id =
          await _repo!.createCall(recipientId: calleeId, mediaType: mediaType);
      activeCallId = id;
      activeMediaType = mediaType;
      _startPolling();
      notifyListeners();
      return id;
    } catch (e) {
      lastError = 'startCall: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Callee gắn vào một cuộc gọi đang đổ chuông (để poll & thao tác).
  Future<void> attachIncoming(
      {required int callId, required String mediaType}) async {
    await _ensureRepo();
    activeCallId = callId;
    activeMediaType = mediaType;
    _startPolling();
    notifyListeners();
  }

  /// Kết thúc cuộc gọi (gửi action=end + dọn trạng thái)
  Future<void> endCall() async {
    await _ensureRepo();
    final id = activeCallId;
    _stopPolling();
    if (id != null) {
      try {
        await _repo!.action(callId: id, action: 'end');
      } catch (_) {}
    }
    _clearState();
  }

  /// Gửi OFFER (Caller)
  Future<void> sendOffer(String sdp) async {
    await _ensureRepo();
    final id = _requireCallId();
    await _repo!.sendOffer(callId: id, sdp: sdp);
  }

  /// Gửi ANSWER (Callee)
  Future<void> sendAnswer(String sdp) async {
    await _ensureRepo();
    final id = _requireCallId();
    await _repo!.sendAnswer(callId: id, sdp: sdp);
  }

  /// Gửi ICE Candidate (hai bên)
  Future<void> sendCandidate({
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  }) async {
    await _ensureRepo();
    final id = _requireCallId();
    await _repo!.sendCandidate(
      callId: id,
      candidate: candidate,
      sdpMid: sdpMid,
      sdpMLineIndex: sdpMLineIndex,
    );
  }

  /// Thao tác nhanh: 'answer' | 'decline' | 'end'
  Future<String> action(String actionName) async {
    await _ensureRepo();
    final id = _requireCallId();
    final st = await _repo!.action(callId: id, action: actionName);
    callStatus = st;
    notifyListeners();
    return st;
  }

  /// Poll thủ công
  Future<void> pollOnce() async {
    await _ensureRepo();
    final id = _requireCallId();
    final pr = await _repo!.poll(callId: id);
    _applyPollResult(pr);
  }

  // ---------------- internal ----------------

  void _startPolling() {
    _stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        await pollOnce();
        if (callStatus == 'declined' || callStatus == 'ended') {
          _stopPolling();
        }
      } catch (e) {
        lastError = 'poll: $e';
        notifyListeners();
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _applyPollResult(PollResult pr) {
    callStatus = pr.callStatus;
    sdpOffer = pr.sdpOffer;
    sdpAnswer = pr.sdpAnswer;
    iceCandidates = pr.iceCandidates;
    notifyListeners();
  }

  void _clearState() {
    activeCallId = null;
    callStatus = '';
    sdpOffer = null;
    sdpAnswer = null;
    iceCandidates = const [];
    notifyListeners();
  }

  Future<void> _ensureRepo() async {
    await ensureInitialized();
    if (!ready || _repo == null) {
      throw StateError('CallController not ready. Hãy gọi init() trước.');
    }
  }

  int _requireCallId() {
    final id = activeCallId;
    if (id == null) throw StateError('Chưa có activeCallId.');
    return id;
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
