// lib/features/social/screens/call_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

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

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  late CallController _cc;
  late VoidCallback _callListener;

  bool _viewAlive = false;
  bool _ending = false;

  bool _offerHandled = false;
  bool _answerHandled = false;
  bool _remoteDescSet = false;

  final Set<String> _addedCandidates = {};

  // UI controls
  bool _micOn = true;
  bool _camOn = true;
  bool _speakerOn = true;

  @override
  void initState() {
    super.initState();
    _viewAlive = true;

    _cc = context.read<CallController>();
    _callListener = _onCallUpdated;
    _cc.addListener(_callListener);

    _initRenderers();
  }

  Future<void> _initRenderers() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
    } catch (_) {}

    _startCallFlow();
  }

  Future<void> _startCallFlow() async {
    if (!_viewAlive) return;

    try {
      final isVideo = (widget.mediaType == 'video');

      _micOn = true;
      _camOn = isVideo;
      _speakerOn = true;

      // bật loa ngoài
      try {
        await Helper.setSpeakerphoneOn(true);
      } catch (_) {}

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

      // remote track
      _pc!.onTrack = (e) async {
        if (e.streams.isNotEmpty) {
          try {
            _remoteRenderer.srcObject = e.streams.first;
          } catch (_) {}
          if (mounted) setState(() {});
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
      };

      // connection state
      _pc!.onConnectionState = (s) {
        if (s == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            s == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            s == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          _hangup();
        }
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
      } catch (_) {}

      // add local track vào PC
      for (var t in _localStream!.getTracks()) {
        await _pc!.addTrack(t, _localStream!);
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
        final offer = await _pc!.createOffer();
        await _pc!.setLocalDescription(offer);
        await _cc.sendOffer(offer.sdp!);
      }
    } catch (e) {
      _error('Lỗi khởi tạo call: $e');
      _hangup();
    }
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
        } catch (e) {
          final msg = '$e';
          // Nếu WebRTC báo "wrong state" thì coi như đã set trước đó, bỏ qua
          if (!msg.contains('Called in wrong state')) {
            _error('Lỗi set remote OFFER: $e');
          }
        }
      }

      // 2) Khi đã có remote offer & chưa gửi answer → tạo answer 1 lần
      if (_remoteDescSet && !_offerHandled) {
        _offerHandled = true; // đánh dấu đã xử lý để tránh lặp
        try {
          final answer = await _pc!.createAnswer();
          await _pc!.setLocalDescription(answer);
          await _cc.sendAnswer(answer.sdp!);
        } catch (e) {
          final msg = '$e';
          if (!msg.contains('Called in wrong state')) {
            _error('Lỗi xử lý OFFER: $e');
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
        } catch (e) {
          _error('Lỗi set ANSWER: $e');
        }
      }
    }

    // ICE từ peer
    if (_cc.iceCandidates.isNotEmpty) {
      for (var ic in _cc.iceCandidates) {
        final key = '${ic.candidate}|${ic.sdpMid}|${ic.sdpMLineIndex}';
        if (_addedCandidates.contains(key)) continue;
        _addedCandidates.add(key);

        try {
          await _pc!.addCandidate(
            RTCIceCandidate(ic.candidate, ic.sdpMid, ic.sdpMLineIndex),
          );
        } catch (_) {}
      }
    }
  }

  /// End call
  Future<void> _hangup() async {
    if (_ending) return;
    _ending = true;

    try {
      await _cc.action('end');
    } catch (_) {}

    _disposeRTC();

    if (mounted) Navigator.of(context).maybePop();
  }

  void _error(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _disposeRTC() async {
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
