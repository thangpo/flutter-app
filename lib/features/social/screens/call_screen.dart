// lib/features/social/screens/call_screen.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

import '../domain/models/ice_candidate_lite.dart';

import '../controllers/call_controller.dart';

class CallScreen extends StatefulWidget {
  final bool isCaller; // true: caller, false: callee
  final int callId;
  final String mediaType; // 'audio' | 'video'
  final String? peerName;
  final String? peerAvatar;

  const CallScreen({
    super.key,
    required this.isCaller,
    required this.callId,
    required this.mediaType,
    this.peerName,
    this.peerAvatar,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  bool _localTracksAdded = false;

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  late CallController _cc;
  late VoidCallback _callListener;

  bool _viewAlive = false;
  bool _ending = false;

  bool _offerHandled = false;
  bool _answerHandled = false;
  bool _remoteDescSet = false;
  String? _localOfferSdp;
  DateTime? _offerSentAt;
  bool _offerResent = false;
  bool _detached = false;

  final Set<String> _addedCandidates = {};
  final List<IceCandidateLite> _pendingCandidates = [];

  // UI controls
  bool _micOn = true;
  bool _camOn = true;
  bool _speakerOn = true;

  bool _flowStarted = false;

  @override
  void initState() {
    super.initState();
    _viewAlive = true;

    _cc = context.read<CallController>();
    _callListener = _onCallUpdated;
    _cc.addListener(_callListener);

    // Nếu controller chưa attach, gắn lại để bảo đảm polling/SDP/ICE cho callee
    if (_cc.activeCallId != widget.callId) {
      _cc.attachCall(
        callId: widget.callId,
        mediaType: widget.mediaType,
        initialStatus: 'answered', // đang ở CallScreen rồi
      );
    }

    // Quan trọng: đợi renderer initialize xong rồi mới start call flow
    Future.microtask(() async {
      await _initRenderers();
      await _startCallFlow();
      // “đập” cập nhật sớm để không lỡ OFFER tới sát lúc này
      Future.delayed(const Duration(milliseconds: 250), _onCallUpdated);
    });
  }

  Future<void> _initRenderers() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
    } catch (e, st) {
      _log('initRenderers error: $e', st: st);
    }

    // “đập” cập nhật sớm để không lỡ OFFER tới sát lúc này
    Future.delayed(const Duration(milliseconds: 250), _onCallUpdated);

    _startCallFlow();
  }

  Future<void> _startCallFlow() async {
    if (!_viewAlive) return;
    if (_flowStarted) return; // chống chạy lặp
    _flowStarted = true;
    try {
      final isVideo =
          (widget.mediaType == 'video') || (_cc.activeMediaType == 'video');

      _micOn = true;
      _camOn = isVideo;
      _speakerOn = true;
      _log(
          'startCallFlow | isCaller=${widget.isCaller} media=${widget.mediaType}');

      // bật loa ngoài
      try {
        await Helper.setSpeakerphoneOn(true);
      } catch (e, st) {
        _log('setSpeakerphoneOn error: $e', st: st);
      }

      // tạo PeerConnection
      final config = {
        'iceServers': [
          {
            'urls': ['stun:stun.l.google.com:19302'],
          },
          {
            'urls': [
              'turn:social.vnshop247.com:3478?transport=udp',
              'turn:social.vnshop247.com:3478?transport=tcp',
              'turn:147.93.98.63:3478?transport=udp',
              'turn:147.93.98.63:3478?transport=tcp',
            ],
            'username': 'webrtc',
            'credential': 'supersecret',
          },
        ],
        'sdpSemantics': 'unified-plan',
      };

      _pc = await createPeerConnection(config);
      _log('PeerConnection created');

      // remote track
      _pc!.onTrack = (e) async {
        MediaStream? stream = e.streams.isNotEmpty ? e.streams.first : null;

        // fallback khi unified-plan không gắn stream
        if (stream == null) {
          stream = await createLocalMediaStream('remote_peer');
          await stream.addTrack(e.track);
        }

        // Chỉ gán renderer khi track video để tránh âm thanh ghi đè stream video
        if (e.track.kind == 'video') {
          try {
            _remoteStream = stream;
            _remoteRenderer.srcObject = stream;
            _log(
                'onTrack kind=${e.track.kind} id=${e.track.id} remoteStream=${stream.id}');
            _logRemoteSizeLater();
            _kickRemoteRenderIfBlank();
          } catch (err, st) {
            _log('onTrack set renderer error: $err', st: st);
          }
          if (mounted) setState(() {});
        } else {
          _log(
              'onTrack kind=${e.track.kind} id=${e.track.id} (ignored for renderer)');
        }
      };

      // ICE local
      _pc!.onIceCandidate = (c) {
        if (c.candidate == null) return;
        _cc.sendCandidate(
          candidate: c.candidate!,
          sdpMid: c.sdpMid,
          sdpMLineIndex: c.sdpMLineIndex,
        );
        _log(
            'onIceCandidate mid=${c.sdpMid} mline=${c.sdpMLineIndex} len=${c.candidate?.length}');
      };

      // connection state
      _pc!.onConnectionState = (s) {
        _log('connectionState -> $s');

        // Đừng cúp máy khi callee chưa SRD — iOS có thể "Closed/Disconnected" thoáng khi đổi route
        if (!_remoteDescSet && !widget.isCaller) {
          return;
        }

        if (s == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            s == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          _hangup();
        } else if (s ==
            RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          Future.delayed(const Duration(seconds: 3), () {
            if (!_viewAlive || _pc == null) return;
            if (_pc!.connectionState ==
                RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
              _hangup();
            }
          });
        }
      };

      // Plan-B fallback (một số thiết bị Android gửi addStream)
      _pc!.onAddStream = (MediaStream stream) async {
        try {
          _remoteRenderer.srcObject = stream;
          _log(
              'onAddStream id=${stream.id} tracks=${stream.getTracks().length}');
        } catch (err, st) {
          _log('onAddStream set renderer error: $err', st: st);
        }
        if (mounted) setState(() {});
      };

      // lấy local media — tăng chất lượng video
      final constraints = {
        'audio': true,
        'video': isVideo
            ? {
                'mandatory': {
                  'minWidth': '720',
                  'minHeight': '480',
                  'maxWidth': '1280',
                  'maxHeight': '720',
                  'minFrameRate': '24',
                  'maxFrameRate': '30',
                },
                'facingMode': 'user',
              }
            : false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      try {
        _localRenderer.srcObject = _localStream;
        _log(
            'local stream id=${_localStream?.id} tracks=${_localStream?.getTracks().length}');
      } catch (err, st) {
        _log('set local renderer error: $err', st: st);
      }

      // add local track vào PC
      var addedOk = true;
      for (var t in _localStream!.getTracks()) {
        try {
          await _pc!.addTrack(t, _localStream!);
          _log('addTrack kind=${t.kind} id=${t.id}');
        } catch (e, st) {
          _log('addTrack error: $e, try addTransceiver', st: st);
          try {
            await _pc!.addTransceiver(
              track: t,
              init: RTCRtpTransceiverInit(
                  direction: TransceiverDirection.SendRecv),
            );
            _log('addTransceiver fallback ok kind=${t.kind} id=${t.id}');
          } catch (e2, st2) {
            addedOk = false;
            _log('addTransceiver fallback error: $e2', st: st2);
          }
        }
      }
      _localTracksAdded = addedOk;
      if (!addedOk) {
        // retry gắn track nếu lần đầu lỗi (trạng thái thiết bị/permission)
        await _ensureLocalMedia(wantVideo: isVideo);
      }

      // tăng bitrate gửi đi (giống style cũ — KHÔNG dùng getParameters)
      try {
        final senders = await _pc!.getSenders();
        for (var s in senders) {
          if (s.track?.kind == 'video') {
            await s.setParameters(
              RTCRtpParameters(
                encodings: [
                  RTCRtpEncoding(
                    maxBitrate: 1500 * 1000, // ~1.5 Mbps
                  ),
                ],
              ),
            );
          }
        }
      } catch (_) {}

      // Caller tạo OFFER → gửi
      if (widget.isCaller) {
        if (!_localTracksAdded || _localStream == null) {
          await _ensureLocalMedia(wantVideo: isVideo);
        }
        final offer = await _pc!.createOffer({
          'offerToReceiveAudio': 1,
          'offerToReceiveVideo': 1,
        });
        await _pc!.setLocalDescription(offer);
        _localOfferSdp = offer.sdp;
        _offerSentAt = DateTime.now();
        await _cc.sendOffer(offer.sdp!);
        _log('offer created len=${offer.sdp?.length}');
      }
    } catch (e, st) {
      _error('Lỗi khởi tạo call: $e');
      _log('startCallFlow error: $e', st: st);
      _hangup();
    }
    await Future.microtask(_onCallUpdated);
  }

  /// Lắng nghe CallController để nhận OFFER / ANSWER / ICE
  void _onCallUpdated() async {
    if (!_viewAlive || _pc == null) return;

    final st = _cc.callStatus;

    // peer end / decline
    if (st == 'declined' || st == 'ended') {
      _hangup();
      return;
    }

    // CALLEE xử lý OFFER
    // CALLEE xử lý OFFER: set remote + trả lời đúng 1 lần
    if (!widget.isCaller) {
      final offer = _cc.sdpOffer;

      // 1) Chỉ setRemoteDescription nếu chưa set
      if (offer != null && !_remoteDescSet) {
        try {
          await _pc!.setRemoteDescription(
            RTCSessionDescription(offer, 'offer'),
          );
          _remoteDescSet = true;
          _log('callee setRemoteDescription(offer) ${_sdpSummary(offer)}');
          _flushPendingCandidates();

          // Hoãn ép sendrecv một nhịp để tránh race/“transceiver disposed” trên Android
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!_viewAlive || _pc == null || !_remoteDescSet) return;
            _ensureSendRecvTransceivers();
          });
        } catch (e) {
          final msg = '$e';
          // Nếu WebRTC báo "wrong state" thì coi như đã set trước đó, bỏ qua
          if (!msg.contains('Called in wrong state')) {
            _error('Lỗi set remote OFFER: $e');
            _log('callee setRemoteDescription(offer) error: $e');
          }
        }
      }

      // 2) Khi đã có remote offer & chưa gửi answer → tạo answer 1 lần
      if (_remoteDescSet && !_offerHandled) {
        _offerHandled = true; // đánh dấu đã xử lý để tránh lặp
        try {
          // Nếu chưa có local media (do payload sai mediaType), đảm bảo mở media trước khi answer
          // Chỉ bổ sung nếu THIẾU stream; tránh addTrack lần 2 gây "addTrack failed"
          if (_localStream == null) {
            await _ensureLocalMedia(
              wantVideo: (_cc.activeMediaType == 'video' ||
                  widget.mediaType == 'video'),
            );
          }

          final answer = await _pc!.createAnswer({
            'offerToReceiveAudio': 1,
            'offerToReceiveVideo': 1,
          });
          final patchedSdp = _forceSendRecvSdp(answer.sdp ?? '');
          final patched = RTCSessionDescription(patchedSdp, 'answer');

          await _pc!.setLocalDescription(patched);
          await _cc.sendAnswer(patchedSdp);
          _log('callee answer created ${_sdpSummary(patchedSdp)}');
        } catch (e) {
          final msg = '$e';
          if (!msg.contains('Called in wrong state')) {
            _error('Lỗi xử lý OFFER: $e');
            _log('callee create/send answer error: $e');
          }
        }
      }
    }

    // CALLER nhận ANSWER
    if (widget.isCaller && !_answerHandled) {
      final ans = _cc.sdpAnswer;
      if (ans != null && !_remoteDescSet) {
        try {
          await _pc!.setRemoteDescription(
            RTCSessionDescription(ans, 'answer'),
          );
          _remoteDescSet = true;
          _answerHandled = true;
          _log('caller setRemoteDescription(answer) ${_sdpSummary(ans)}');
          _ensureSendRecvTransceivers();
          _flushPendingCandidates();
        } catch (e) {
          _error('Lỗi set ANSWER: $e');
          _log('caller setRemoteDescription(answer) error: $e');
        }
      }
    }

    // CALLER fallback: n?u server chua tr? offer trong poll, resend 1 l?n sau 2s
    if (widget.isCaller &&
        !_offerResent &&
        _localOfferSdp != null &&
        _cc.sdpOffer == null &&
        _offerSentAt != null &&
        DateTime.now().difference(_offerSentAt!).inSeconds > 2) {
      _offerResent = true;
      try {
        await _cc.sendOffer(_localOfferSdp!);
        _log('resend offer len=');
      } catch (e) {
        _log('resend offer error: ');
      }
    }
// ICE từ peer
    if (_cc.iceCandidates.isNotEmpty) {
      for (var ic in _cc.iceCandidates) {
        final key = '${ic.candidate}|${ic.sdpMid}|${ic.sdpMLineIndex}';
        if (_addedCandidates.contains(key)) continue;

        if (!_remoteDescSet) {
          _pendingCandidates.add(ic);
          _log(
              'queue remoteCandidate (no remoteDesc yet) mid=${ic.sdpMid} mline=${ic.sdpMLineIndex}');
        } else {
          _addCandidate(ic, key);
        }
      }
    }
  }

  Future<void> _addCandidate(IceCandidateLite ic, String key) async {
    _addedCandidates.add(key);
    try {
      await _pc!.addCandidate(
        RTCIceCandidate(ic.candidate, ic.sdpMid, ic.sdpMLineIndex),
      );
      _log('addRemoteCandidate mid=${ic.sdpMid} mline=${ic.sdpMLineIndex}');
    } catch (e, st) {
      _log('addRemoteCandidate error: $e', st: st);
    }
  }

  void _flushPendingCandidates() {
    if (!_remoteDescSet || _pendingCandidates.isEmpty) return;
    final pending = List<IceCandidateLite>.from(_pendingCandidates);
    _pendingCandidates.clear();
    for (final ic in pending) {
      final key = '${ic.candidate}|${ic.sdpMid}|${ic.sdpMLineIndex}';
      if (_addedCandidates.contains(key)) continue;
      _addCandidate(ic, key);
    }
  }

  /// End call
  Future<void> _hangup() async {
    if (_ending) return;
    _ending = true;

    try {
      await _cc.action('end');
    } catch (_) {}
    await _detachController();

    _disposeRTC();

    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _detachController() async {
    if (_detached) return;
    _detached = true;
    try {
      await _cc.detachCall();
    } catch (_) {}
  }

  void _error(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _log(String msg, {StackTrace? st}) {
    developer.log(msg, name: 'CallScreen', stackTrace: st);
  }

  void _logRemoteSizeLater() {
    Future.delayed(const Duration(milliseconds: 300), () {
      try {
        final w = _remoteRenderer.videoWidth;
        final h = _remoteRenderer.videoHeight;
        _log('remoteRenderer size ${w}x$h');
      } catch (_) {}
    });
  }

  void _kickRemoteRenderIfBlank() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!_viewAlive) return;
      try {
        final w = _remoteRenderer.videoWidth;
        final h = _remoteRenderer.videoHeight;
        if ((w == 0 || h == 0) && _remoteStream != null) {
          // thử gán lại stream để renderer refresh
          _remoteRenderer.srcObject = _remoteStream;
          _log('remoteRenderer blank -> reattach stream ${_remoteStream?.id}');
          _logRemoteSizeLater();
          if (mounted) setState(() {});
        }
      } catch (_) {}
    });
  }

  Future<void> _ensureLocalMedia({required bool wantVideo}) async {
    if (_pc == null) return;
    // Nếu đã add đầy đủ track rồi thì thôi, tránh add lại gây lỗi native
    if (_localTracksAdded) return;
    // Tạo local stream nếu chưa có
    if (_localStream == null) {
      final constraints = {
        'audio': true,
        'video': wantVideo
            ? {
                'mandatory': {
                  'minWidth': '720',
                  'minHeight': '480',
                  'maxWidth': '1280',
                  'maxHeight': '720',
                  'minFrameRate': '24',
                  'maxFrameRate': '30',
                },
                'facingMode': 'user',
              }
            : false,
      };
      try {
        if (_localRenderer.textureId != null) {
          _localRenderer.srcObject = _localStream;
        } else {
          // retry rất ngắn khi texture chưa sẵn sàng
          Future.delayed(const Duration(milliseconds: 50), () {
            if (_viewAlive && _localRenderer.textureId != null) {
              _localRenderer.srcObject = _localStream;
            }
          });
        }
        _log(
            'local stream id=${_localStream?.id} tracks=${_localStream?.getTracks().length}');
      } catch (err, st) {
        _log('set local renderer error: $err', st: st);
      }
    }

    // Add missing tracks to PeerConnection
    if (!_localTracksAdded) {
      try {
        final senders = await _pc!.getSenders();
        final existingTrackIds = senders
            .where((s) => s.track != null)
            .map((s) => s.track!.id)
            .toSet();
        var ok = true;
        for (var t in _localStream!.getTracks()) {
          if (!existingTrackIds.contains(t.id)) {
            try {
              await _pc!.addTrack(t, _localStream!);
              _log('ensureLocalMedia: addTrack kind=${t.kind} id=${t.id}');
            } catch (e, st) {
              _log('ensureLocalMedia addTrack error: $e, try transceiver',
                  st: st);
              try {
                await _pc!.addTransceiver(
                  track: t,
                  init: RTCRtpTransceiverInit(
                      direction: TransceiverDirection.SendRecv),
                );
                _log(
                    'ensureLocalMedia: addTransceiver fallback ok kind=${t.kind} id=${t.id}');
              } catch (e2, st2) {
                ok = false;
                _log('ensureLocalMedia addTransceiver fallback error: $e2',
                    st: st2);
              }
            }
          }
        }
        _localTracksAdded = ok;
      } catch (e, st) {
        _log('ensureLocalMedia addTrack error: $e', st: st);
      }
    }
  }

  Future<void> _ensureSendRecvTransceivers() async {
    if (_pc == null) return;
    try {
      final trans = await _pc!.getTransceivers();
      for (final t in trans) {
        try {
          if (t.sender.track != null) {
            await t.setDirection(TransceiverDirection.SendRecv);
            _log(
                'force transceiver ${t.mid ?? '-'} kind=${t.sender.track?.kind} to sendrecv');
          }
        } catch (e, st) {
          _log('ensureSendRecvTransceivers skip(setDirection): $e', st: st);
        }
      }
    } catch (e, st) {
      _log('ensureSendRecvTransceivers error: $e', st: st);
    }
  }

  String _forceSendRecvSdp(String sdp) {
    // Thay thế mọi recvonly/sendonly/inactive thành sendrecv để chắc chắn gửi hình/tiếng
    var patched =
        sdp.replaceAll(RegExp(r'^a=recvonly$', multiLine: true), 'a=sendrecv');
    patched = patched.replaceAll(
        RegExp(r'^a=sendonly$', multiLine: true), 'a=sendrecv');
    patched = patched.replaceAll(
        RegExp(r'^a=inactive$', multiLine: true), 'a=sendrecv');
    return patched;
  }

  String _sdpSummary(String sdp) {
    // Quick summary for debugging: check if m=audio/video and direction lines.
    final audio = sdp.contains('\nm=audio');
    final video = sdp.contains('\nm=video');
    String dir = '';
    for (final line in [
      'a=sendrecv',
      'a=recvonly',
      'a=sendonly',
      'a=inactive',
    ]) {
      if (sdp.contains('\n$line')) {
        dir = line.replaceFirst('a=', '');
        break;
      }
    }
    return 'audio=${audio ? 'y' : 'n'} video=${video ? 'y' : 'n'} dir=${dir.isEmpty ? '?' : dir} len=${sdp.length}';
  }

  Future<void> _disposeRTC() async {
    _localTracksAdded = false;
    _remoteStream = null;

    try {
      await _pc?.close();
    } catch (_) {}
    _pc = null;

    try {
      _localStream?.getTracks().forEach((t) => t.stop());
      await _localStream?.dispose();
    } catch (_) {}
    _localStream = null;

    try {
      _localRenderer.srcObject = null;
      _remoteRenderer.srcObject = null;
    } catch (_) {}
  }

  @override
  void dispose() {
    _viewAlive = false;
    _ending = true;

    _cc.removeListener(_callListener);
    // TrA�nh notifyListeners trong khi tree �`ang lock khi dispose
    scheduleMicrotask(_detachController);
    _disposeRTC();

    try {
      _localRenderer.dispose();
      _remoteRenderer.dispose();
    } catch (_) {}

    super.dispose();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.mediaType == 'video';
    final name = widget.peerName ?? 'Đang kết nối…';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(isVideo ? 'Video call' : 'Audio call'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _hangup,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red),
            onPressed: _hangup,
          ),
        ],
      ),
      body: isVideo ? _videoUI(name) : _audioUI(name),
    );
  }

  Widget _videoUI(String name) {
    return Stack(
      children: [
        // remote video
        Positioned.fill(
          child: RTCVideoView(
            _remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
        ),

        // local preview
        Positioned(
          top: 16,
          right: 16,
          width: 110,
          height: 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: RTCVideoView(
              _localRenderer,
              mirror: true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
        ),

        // bottom controls
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: _controls(video: true),
        ),
      ],
    );
  }

  Widget _audioUI(String name) {
    return Column(
      children: [
        const Spacer(),
        CircleAvatar(
          radius: 48,
          backgroundColor: Colors.white10,
          child: const Icon(Icons.person, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 20)),
        const SizedBox(height: 8),
        const Text('Đang kết nối…', style: TextStyle(color: Colors.white70)),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: _controls(video: false),
        ),
      ],
    );
  }

  Widget _controls({required bool video}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _btn(
          icon: _micOn ? Icons.mic : Icons.mic_off,
          action: _toggleMic,
        ),
        _btn(
          icon: _speakerOn ? Icons.volume_up : Icons.volume_off,
          action: _toggleSpeaker,
        ),
        _btn(
          icon: Icons.call_end,
          action: _hangup,
          danger: true,
          size: 70,
        ),
        if (video)
          _btn(
            icon: _camOn ? Icons.videocam : Icons.videocam_off,
            action: _toggleCamera,
          ),
        if (video)
          _btn(
            icon: Icons.cameraswitch,
            action: _switchCamera,
          ),
      ],
    );
  }

  Widget _btn({
    required IconData icon,
    required VoidCallback action,
    bool danger = false,
    double size = 56,
  }) {
    return InkWell(
      onTap: action,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: danger ? Colors.red : Colors.white12,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  // toggles
  void _toggleMic() {
    _micOn = !_micOn;
    _localStream?.getAudioTracks().forEach((t) => t.enabled = _micOn);
    setState(() {});
  }

  void _toggleCamera() {
    if (widget.mediaType != 'video') return;
    _camOn = !_camOn;
    _localStream?.getVideoTracks().forEach((t) => t.enabled = _camOn);
    setState(() {});
  }

  void _toggleSpeaker() async {
    _speakerOn = !_speakerOn;
    try {
      await Helper.setSpeakerphoneOn(_speakerOn);
    } catch (_) {}
    setState(() {});
  }

  Future<void> _switchCamera() async {
    if (widget.mediaType != 'video') return;
    try {
      final videoTrack = _localStream?.getVideoTracks().first;
      if (videoTrack != null) {
        await Helper.switchCamera(videoTrack);
      }
    } catch (_) {}
  }
}
