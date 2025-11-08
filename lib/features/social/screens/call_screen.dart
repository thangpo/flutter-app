// G:\flutter-app\lib\features\social\screens\call_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/call_controller.dart';

class CallScreen extends StatefulWidget {
  final bool isCaller; // true: caller, false: callee
  final int callId; // id cuộc gọi từ server
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
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();

  late CallController _cc;
  late VoidCallback _ccListener;

  bool _remoteDescSet = false;
  bool _offerHandled = false;
  bool _answerHandled = false;
  final Set<String> _addedCandidates = {};

  // ---- Guards vòng đời UI/renderer
  bool _viewAlive = false;
  bool _ending = false;

  @override
  void initState() {
    super.initState();
    _viewAlive = true;

    _cc = context.read<CallController>();
    _ccListener = _onControllerChanged;
    _cc.addListener(_ccListener);

    _initRenderers().then((_) => _start());
  }

  Future<void> _initRenderers() async {
    try {
      await _localRenderer.initialize();
    } catch (_) {}
    try {
      await _remoteRenderer.initialize();
    } catch (_) {}
  }

  /// Gán stream vào renderer nhưng an toàn nếu renderer lỡ bị dispose/chưa init
  Future<void> _safeAttach(RTCVideoRenderer r, MediaStream stream) async {
    if (!_viewAlive || _ending) return;
    try {
      r.srcObject = stream;
    } catch (_) {
      // nếu bị dispose hoặc chưa init: init lại rồi gán
      try {
        await r.initialize();
      } catch (_) {}
      try {
        r.srcObject = stream;
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  Future<void> _start() async {
    try {
      // DỌN STATE CŨ (close pc/stream, clear srcObject; KHÔNG dispose renderer)
      await _disposeRtc();

      // 1) TẠO PEER CONNECTION TRƯỚC (tránh NPE getTransceivers)
      final configuration = {
        'iceServers': [
          {
            'urls': [
              'stun:stun.l.google.com:19302',
              'stun:stun1.l.google.com:19302',
            ],
          },
          {
            'urls': [
              'turn:social.vnshop247.com:3478?transport=udp',
              'turn:social.vnshop247.com:3478?transport=tcp',
            ],
            'username': 'webrtc',
            'credential': 'supersecret',
          },
        ],
        'sdpSemantics': 'unified-plan',
        // Debug NAT: nếu cần ép đi qua TURN, bật dòng sau
        // 'iceTransportPolicy': 'relay',
      };
      _pc = await createPeerConnection(configuration, {});

      // REMOTE track/stream
      _pc!.onTrack = (RTCTrackEvent e) async {
        if (e.streams.isEmpty) return;
        await _safeAttach(_remoteRenderer, e.streams.first);
      };

      // ICE local -> gửi lên server
      _pc!.onIceCandidate = (RTCIceCandidate c) {
        if (c.candidate != null) {
          _cc.sendCandidate(
            candidate: c.candidate!,
            sdpMid: c.sdpMid,
            sdpMLineIndex: c.sdpMLineIndex,
          );
        }
      };

      _pc!.onConnectionState = (RTCPeerConnectionState s) {
        if (s == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            s == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            s == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          _endAndPop();
        }
      };

      // 2) LẤY MEDIA SAU KHI CÓ PC
      final isVideo = widget.mediaType == 'video';
      final constraints = <String, dynamic>{
        'audio': true,
        'video': isVideo
            ? {
                'facingMode': 'user',
                'width': {'ideal': 1280},
                'height': {'ideal': 720},
                'frameRate': {'ideal': 30},
              }
            : false,
      };
      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      await _safeAttach(_localRenderer, _localStream!);

      // 3) ADD TRACK VÀO PC
      for (final t in _localStream!.getTracks()) {
        await _pc!.addTrack(t, _localStream!);
      }

      // 4) OFFER / ANSWER
      if (widget.isCaller) {
        // Caller: tạo OFFER -> setLocal -> gửi OFFER
        final offer = await _pc!.createOffer();
        await _pc!.setLocalDescription(offer);
        await _cc.sendOffer(offer.sdp!);
        // Controller sẽ poll & mang ANSWER/ICE về qua listener
      } else {
        // Callee: Controller đã poll sẵn OFFER; listener sẽ xử lý khi nhận được
        // (sau khi setLocal(answer) sẽ gửi answer + action('answer'))
      }
    } catch (e) {
      _snack('Lỗi khởi tạo cuộc gọi: $e');
      _endAndPop();
    }
  }

  void _onControllerChanged() async {
    if (!mounted || _pc == null) return;

    // Kết thúc khi peer decline/end
    final st = _cc.callStatus;
    if (st == 'declined' || st == 'ended') {
      _endAndPop();
      return;
    }

    // CALLEE: nhận OFFER -> setRemote -> create ANSWER -> setLocal -> gửi
    if (!widget.isCaller && !_offerHandled) {
      final offerSdp = _cc.sdpOffer;
      if (offerSdp != null) {
        try {
          await _pc!.setRemoteDescription(
            RTCSessionDescription(offerSdp, 'offer'),
          );
          _remoteDescSet = true;
          _offerHandled = true;

          final answer = await _pc!.createAnswer();
          await _pc!.setLocalDescription(answer);

          await _cc.sendAnswer(answer.sdp!);
          // Đảm bảo status chuyển answered (webrtc.php 'answer' đã làm, nhưng gọi action để chắc)
          try {
            await _cc.action('answer');
          } catch (_) {}
        } catch (e) {
          _snack('Lỗi xử lý OFFER: $e');
        }
      }
    }

    // CALLER: nhận ANSWER -> setRemote
    if (widget.isCaller && !_answerHandled) {
      final answerSdp = _cc.sdpAnswer;
      if (answerSdp != null && !_remoteDescSet) {
        try {
          await _pc!.setRemoteDescription(
            RTCSessionDescription(answerSdp, 'answer'),
          );
          _remoteDescSet = true;
          _answerHandled = true;
        } catch (e) {
          _snack('Lỗi set ANSWER: $e');
        }
      }
    }

    // ICE từ peer (server trả delivered=0 mỗi lần poll) -> addCandidate
    if (_cc.iceCandidates.isNotEmpty) {
      for (final ic in _cc.iceCandidates) {
        final key = '${ic.candidate}|${ic.sdpMid}|${ic.sdpMLineIndex}';
        if (_addedCandidates.contains(key)) continue;
        try {
          await _pc!.addCandidate(
            RTCIceCandidate(ic.candidate, ic.sdpMid, ic.sdpMLineIndex),
          );
          _addedCandidates.add(key);
        } catch (_) {}
      }
    }
  }

  Future<void> _hangup() async {
    try {
      await _cc.action('end');
    } catch (_) {}
    _endAndPop();
  }

  void _endAndPop() {
    if (_ending) return;
    _ending = true;
    _disposeRtc();
    if (mounted) Navigator.of(context).maybePop();
  }

  /// Dọn state RTC: close pc/stream & clear renderer srcObject
  /// KHÔNG dispose renderer ở đây (chỉ dispose trong dispose() của widget)
  Future<void> _disposeRtc() async {
    try {
      await _pc?.close();
    } catch (_) {}
    _pc = null;

    try {
      _localStream?.getTracks().forEach((t) {
        try {
          t.stop();
        } catch (_) {}
      });
    } catch (_) {}
    try {
      await _localStream?.dispose();
    } catch (_) {}
    _localStream = null;

    try {
      _localRenderer.srcObject = null;
    } catch (_) {}
    try {
      _remoteRenderer.srcObject = null;
    } catch (_) {}
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _viewAlive = false;
    _ending = true;

    _cc.removeListener(_ccListener);
    _disposeRtc(); // close pc/stream + clear srcObject

    // Chỉ dispose renderer khi rời màn hình
    try {
      _localRenderer.dispose();
    } catch (_) {}
    try {
      _remoteRenderer.dispose();
    } catch (_) {}

    super.dispose();
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red),
            onPressed: _hangup,
          ),
        ],
      ),
      body: isVideo ? _buildVideoUI(name) : _buildAudioUI(name),
    );
  }

  Widget _buildVideoUI(String name) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: RTCVideoView(
              _remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
            ),
          ),
        ),
        Positioned(
          right: 16,
          top: 16,
          width: 120,
          height: 180,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.black54,
              child: RTCVideoView(
                _localRenderer,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          bottom: 24,
          child: Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioUI(String name) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 48,
            child: Icon(Icons.person, size: 48),
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 6),
          const Text('Đang kết nối…', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 24),
          IconButton(
            iconSize: 56,
            onPressed: _hangup,
            icon: const Icon(Icons.call_end, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
