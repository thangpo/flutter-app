import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/webrtc_signaling_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_live_repository.dart';

class AgoraCallSession {
  final int callId;
  final String channelName;
  final String token;
  final int uid;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const AgoraCallSession({
    required this.callId,
    required this.channelName,
    required this.token,
    required this.uid,
    required this.createdAt,
    this.expiresAt,
  });

  bool get isExpired =>
      expiresAt != null ? DateTime.now().isAfter(expiresAt!) : false;
}

/// Quản lý signaling cùng trạng thái cuộc gọi.
class CallController extends ChangeNotifier {
  WebRTCSignalingRepository? _repo;
  Future<void>? _initFuture;
  final SocialLiveRepository _agoraRepo = SocialLiveRepository(
    apiBaseUrl: AppConstants.socialBaseUrl,
    serverKey: AppConstants.socialServerKey,
  );

  String? _accessToken;
  AgoraCallSession? _agoraSession;

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
      _accessToken = token.isNotEmpty ? token : null;

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

  /// Gửi OFFER (Caller) — giữ lại để tương thích với backend signaling
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

  /// Poll thường xuyên
  Future<void> pollOnce() async {
    await _ensureRepo();
    final id = _requireCallId();
    final pr = await _repo!.poll(callId: id);
    _applyPollResult(pr);
  }

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
    _agoraSession = null;
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

  Future<AgoraCallSession> prepareAgoraSession() async {
    final int callId = _requireCallId();
    final String defaultChannel = 'call_$callId';
    final String? accessToken = _accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('Thiếu accessToken để lấy Agora token.');
    }

    final AgoraCallSession? cached = _agoraSession;
    if (cached != null && cached.callId == callId && !cached.isExpired) {
      return cached;
    }

    final Map<String, dynamic>? payload = await _agoraRepo.generateAgoraToken(
      accessToken: accessToken,
      channelName: defaultChannel,
      uid: 0,
      role: 'publisher',
    );

    final Map<String, dynamic> normalized = payload ?? <String, dynamic>{};
    final String? token = _extractToken(normalized);
    if (token == null || token.isEmpty) {
      throw StateError('Không lấy được token Agora cho cuộc gọi.');
    }

    final String resolvedChannel =
        (normalized['channel_name'] ?? normalized['channel'])
                ?.toString()
                .trim() ??
            defaultChannel;

    DateTime? expiresAt;
    final int? expireEpoch = _toInt(
      normalized['expire_at'] ??
          normalized['expire_time'] ??
          normalized['expiry'] ??
          normalized['expire_ts'],
    );
    if (expireEpoch != null && expireEpoch > 0) {
      if (expireEpoch > 1000000000000) {
        expiresAt = DateTime.fromMillisecondsSinceEpoch(
          expireEpoch,
          isUtc: true,
        ).toLocal();
      } else if (expireEpoch > 1000000000) {
        expiresAt = DateTime.fromMillisecondsSinceEpoch(
          expireEpoch * 1000,
          isUtc: true,
        ).toLocal();
      }
    }

    final AgoraCallSession session = AgoraCallSession(
      callId: callId,
      channelName: resolvedChannel,
      token: token,
      uid: 0,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
    );
    _agoraSession = session;
    notifyListeners();
    return session;
  }

  String? _extractToken(Map<String, dynamic> map) {
    final List<String> keys = <String>[
      'agora_token',
      'token_agora',
      'rtc_token',
      'token',
    ];
    for (final String key in keys) {
      final String? value = map[key]?.toString();
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
