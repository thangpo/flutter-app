import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/call_controller.dart';

class CallScreen extends StatefulWidget {
  final bool isCaller;
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
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();

  bool _micOn = true;
  bool _camOn = true;

  @override
  void initState() {
    super.initState();
    _initRenderers().then((_) => _boot());
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> _boot() async {
    final call = context.read<CallController>();
    if (call.activeCallId != widget.callId) {
      call.activeCallId = widget.callId;
    }

    // 1) PeerConnection + local stream
    final pc = await createPeerConnection(
      {
        'sdpSemantics': 'unified-plan',
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:global.stun.twilio.com:3478?transport=udp'},
        ],
      },
      {},
    );
    _pc = pc;

    final constraints = <String, dynamic>{
      'audio': true,
      'video': widget.mediaType == 'video'
          ? {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
              'frameRate': {'ideal': 30},
            }
          : false,
    };

    final stream = await navigator.mediaDevices.getUserMedia(constraints);
    _localStream = stream;
    for (var track in stream.getTracks()) {
      await pc.addTrack(track, stream);
    }
    _localRenderer.srcObject = stream;

    pc.onTrack = (evt) {
      if (evt.streams.isNotEmpty) {
        _remoteRenderer.srcObject = evt.streams.first;
        setState(() {});
      }
    };

    pc.onIceCandidate = (cand) async {
      if (cand.candidate == null || cand.candidate!.isEmpty) return;
      try {
        await call.sendCandidate(
          candidate: cand.candidate!,
          sdpMid: cand.sdpMid,
          sdpMLineIndex: cand.sdpMLineIndex,
        );
      } catch (_) {}
    };

    // Lắng nghe thay đổi trạng thái/SDP/ICE từ CallController
    call.addListener(_onControllerChange);

    // 2) Khởi động theo vai trò
    if (widget.isCaller) {
      await _asCaller(call);
    } else {
      await _asCallee(call);
    }
  }

  Future<void> _asCaller(CallController call) async {
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    await call.sendOffer(offer.sdp!);
    // Answer & ICE sẽ tới qua polling -> _onControllerChange xử lý
  }

  Future<void> _asCallee(CallController call) async {
    // Có thể offer đã có sẵn trong controller
    await _tryApplyRemoteOfferAndAnswer(call);
    // Nếu chưa có, _onControllerChange sẽ gọi lại sau khi poll
  }

  Future<void> _tryApplyRemoteOfferAndAnswer(CallController call) async {
    final offerSdp = call.sdpOffer;
    if (offerSdp == null || offerSdp.isEmpty || _pc == null) return;

    final currentRemote = await _pc!.getRemoteDescription();
    if (currentRemote?.sdp != offerSdp) {
      await _pc!.setRemoteDescription(
        RTCSessionDescription(offerSdp, 'offer'),
      );
    }

    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    await call.sendAnswer(answer.sdp!);
  }

  Future<void> _onControllerChange() async {
    if (!mounted || _pc == null) return;
    final call = context.read<CallController>();

    // 1) Caller: khi có ANSWER → setRemote
    if (widget.isCaller &&
        call.sdpAnswer != null &&
        call.sdpAnswer!.isNotEmpty) {
      final currentRemote = await _pc!.getRemoteDescription();
      if (currentRemote?.sdp != call.sdpAnswer) {
        await _pc!.setRemoteDescription(
          RTCSessionDescription(call.sdpAnswer!, 'answer'),
        );
      }
    }

    // 2) Callee: nếu vừa nhận OFFER muộn thì xử lý
    if (!widget.isCaller &&
        call.sdpOffer != null &&
        call.sdpOffer!.isNotEmpty) {
      await _tryApplyRemoteOfferAndAnswer(call);
    }

    // 3) Apply ICE candidates nhận từ server
    if (call.iceCandidates.isNotEmpty) {
      for (final c in call.iceCandidates) {
        try {
          await _pc!.addCandidate(
            RTCIceCandidate(c.candidate, c.sdpMid, c.sdpMLineIndex),
          );
        } catch (_) {}
      }
      // Server sẽ đánh dấu delivered nên không bị lặp lại
    }

    // 4) Kết thúc từ server → đóng màn
    if (call.callStatus == 'declined' || call.callStatus == 'ended') {
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  Future<void> _toggleMic() async {
    _micOn = !_micOn;
    for (final t in _localStream?.getAudioTracks() ?? const []) {
      t.enabled = _micOn;
    }
    setState(() {});
  }

  Future<void> _toggleCam() async {
    if (widget.mediaType != 'video') return;
    _camOn = !_camOn;
    for (final t in _localStream?.getVideoTracks() ?? const []) {
      t.enabled = _camOn;
    }
    setState(() {});
  }

  Future<void> _switchCamera() async {
    if (widget.mediaType != 'video') return;
    for (final t in _localStream?.getVideoTracks() ?? const []) {
      await Helper.switchCamera(t);
    }
  }

  Future<void> _hangup() async {
    final call = context.read<CallController>();
    try {
      await call.endCall();
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    final call = context.read<CallController>();
    call.removeListener(_onControllerChange);

    _localRenderer.dispose();
    _remoteRenderer.dispose();

    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();

    _pc?.close();
    _pc?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.mediaType == 'video';
    final peerName =
        widget.peerName ?? (widget.isCaller ? 'Đang gọi...' : 'Cuộc gọi đến');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(peerName),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (isVideo)
            IconButton(
              icon: const Icon(Icons.cameraswitch),
              onPressed: _switchCamera,
              tooltip: 'Đổi camera',
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: isVideo
                  ? RTCVideoView(
                      _remoteRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                    )
                  : _AudioOnlyBackdrop(name: peerName),
            ),
            if (isVideo)
              Positioned(
                right: 12,
                top: 12,
                width: 120,
                height: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Colors.black54,
                    child: RTCVideoView(
                      _localRenderer,
                      mirror: true,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _circleBtn(
                      icon: _micOn ? Icons.mic : Icons.mic_off,
                      onTap: _toggleMic,
                    ),
                    const SizedBox(width: 16),
                    if (isVideo)
                      _circleBtn(
                        icon: _camOn ? Icons.videocam : Icons.videocam_off,
                        onTap: _toggleCam,
                      ),
                    const SizedBox(width: 16),
                    _circleBtn(
                      icon: Icons.call_end,
                      bg: Colors.red,
                      onTap: _hangup,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn({
    required IconData icon,
    Color bg = const Color(0x33FFFFFF),
    required VoidCallback onTap,
  }) {
    return Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _AudioOnlyBackdrop extends StatelessWidget {
  final String name;
  const _AudioOnlyBackdrop({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
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
        ],
      ),
    );
  }
}
