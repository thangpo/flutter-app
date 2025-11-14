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

  // ---- ICE restart control
  bool _iceRestarting = false;
  int _iceRestartTries = 0;
  static const int _iceRestartMaxTries = 2;

  // ---- Trạng thái UI: mic/cam/loa
  bool _micOn = true;
  bool _camOn = true;
  bool _speakerOn = true;

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
      final isVideo = widget.mediaType == 'video';

      // trạng thái UI ban đầu
      _micOn = true;
      _camOn = isVideo;
      _speakerOn = true;

      // bật loa ngoài (đặc biệt hữu ích cho video call)
      try {
        await Helper.setSpeakerphoneOn(true);
      } catch (_) {}

      // DỌN STATE CŨ (close pc/stream, clear srcObject; KHÔNG dispose renderer)
      await _disposeRtc();

      // 1) TẠO PEER CONNECTION TRƯỚC
      final configuration = {
        'iceServers': [
          {
            'urls': [
              'stun:stun.l.google.com:19302',
              'stun:stun1.l.google.com:19302',
            ],
          },
          // TURN của bạn — thêm cả hostname và IP
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
        // 'iceTransportPolicy': 'relay', // bật nếu muốn ép đi TURN
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

      // Quan sát trạng thái ICE để tự ICE-restart khi rớt
      _pc!.onIceConnectionState = (RTCIceConnectionState state) async {
        if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
            state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          await _attemptIceRestart();
        }
      };

      // fallback: nếu PC closed thì đóng màn luôn
      _pc!.onConnectionState = (RTCPeerConnectionState s) {
        if (s == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          _endAndPop();
        }
      };

      // 2) LẤY MEDIA SAU KHI CÓ PC
      final constraints = <String, dynamic>{
        'audio': true,
        'video': isVideo
            ? {
                'mandatory': {
                  'minWidth': '640',
                  'minHeight': '360',
                  'maxWidth': '1280',
                  'maxHeight': '720',
                  'minFrameRate': '15',
                  'maxFrameRate': '30',
                },
                'facingMode': 'user',
                'optional': [],
              }
            : false,
      };
      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      await _safeAttach(_localRenderer, _localStream!);

      // 3) ADD TRACK VÀO PC
      for (final t in _localStream!.getTracks()) {
        await _pc!.addTrack(t, _localStream!);
      }

      // 3.1) Giảm bitrate video gửi đi (~800 kbps) cho ổn định
      try {
        final senders = await _pc!.getSenders();
        for (final s in senders) {
          if (s.track?.kind == 'video') {
            await s.setParameters(RTCRtpParameters(
              encodings: <RTCRtpEncoding>[
                RTCRtpEncoding(
                  maxBitrate: 800 * 1000, // ~800 kbps
                  numTemporalLayers: 2,
                  rid: 'f',
                ),
              ],
            ));
          }
        }
      } catch (_) {
        // một số platform có thể không hỗ trợ setParameters -> bỏ qua
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
      }
    } catch (e) {
      _snack('Lỗi khởi tạo cuộc gọi: $e');
      _endAndPop();
    }
  }

  Future<void> _attemptIceRestart() async {
    // Chỉ thử vài lần để tránh vòng lặp vô hạn
    if (_pc == null ||
        _iceRestarting ||
        _iceRestartTries >= _iceRestartMaxTries) return;
    _iceRestarting = true;
    _iceRestartTries += 1;
    try {
      final offer = await _pc!.createOffer({'iceRestart': true});
      await _pc!.setLocalDescription(offer);
      await _cc.sendOffer(offer.sdp!);
    } catch (e) {
      _snack('ICE restart error: $e');
    } finally {
      // cho ICE gathering 1 lúc rồi mới cho phép lần kế tiếp
      Future.delayed(const Duration(seconds: 4), () {
        _iceRestarting = false;
      });
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

  // ===================== TOGGLE CONTROLS =====================

  void _toggleMic() {
    _micOn = !_micOn;
    try {
      _localStream?.getAudioTracks().forEach((t) {
        t.enabled = _micOn;
      });
    } catch (_) {}
    setState(() {});
  }

  void _toggleCameraEnabled() {
    if (widget.mediaType != 'video') return;
    _camOn = !_camOn;
    try {
      _localStream?.getVideoTracks().forEach((t) {
        t.enabled = _camOn;
      });
    } catch (_) {}
    setState(() {});
  }

  Future<void> _toggleSpeaker() async {
    _speakerOn = !_speakerOn;
    try {
      await Helper.setSpeakerphoneOn(_speakerOn);
    } catch (_) {}
    setState(() {});
  }

  Future<void> _switchCamera() async {
    if (widget.mediaType != 'video') return;
    try {
      final tracks = _localStream?.getVideoTracks();
      if (tracks != null && tracks.isNotEmpty) {
        await Helper.switchCamera(tracks.first);
      }
    } catch (_) {}
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _hangup, // back = kết thúc cuộc gọi
        ),
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

  // ===================== UI VIDEO =====================

  Widget _buildVideoUI(String name) {
    return Stack(
      children: [
        // Remote video full màn
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: RTCVideoView(
              _remoteRenderer,
              // cho giống app ngoài: fill màn hình, chấp nhận crop
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
        ),

        // Preview local góc trên/phải
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

        // Tên người kia / trạng thái, góc dưới/trái
        Positioned(
          left: 16,
          bottom: 110,
          child: Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),

        // Thanh control đáy màn (mic, loa, end, cam, switch)
        Positioned(
          left: 0,
          right: 0,
          bottom: 24,
          child: _buildBottomControls(isVideo: true),
        ),
      ],
    );
  }

  // ===================== UI AUDIO =====================

  Widget _buildAudioUI(String name) {
    return Column(
      children: [
        const Spacer(),
        const CircleAvatar(
          radius: 48,
          child: Icon(Icons.person, size: 48),
        ),
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 20)),
        const SizedBox(height: 6),
        const Text('Đang kết nối…', style: TextStyle(color: Colors.white70)),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: _buildBottomControls(isVideo: false),
        ),
      ],
    );
  }

  // ===================== COMMON BOTTOM BAR =====================

  Widget _buildBottomControls({required bool isVideo}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _roundButton(
          icon: _micOn ? Icons.mic : Icons.mic_off,
          onTap: _toggleMic,
        ),
        _roundButton(
          icon: _speakerOn ? Icons.volume_up : Icons.volume_off,
          onTap: _toggleSpeaker,
        ),
        _roundButton(
          icon: Icons.call_end,
          onTap: _hangup,
          isDanger: true,
          size: 68,
        ),
        if (isVideo)
          _roundButton(
            icon: _camOn ? Icons.videocam : Icons.videocam_off,
            onTap: _toggleCameraEnabled,
          ),
        if (isVideo)
          _roundButton(
            icon: Icons.cameraswitch,
            onTap: _switchCamera,
          ),
      ],
    );
  }

  Widget _roundButton({
    required IconData icon,
    required VoidCallback? onTap,
    bool isDanger = false,
    double size = 56,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDanger ? Colors.red : Colors.white10,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
        ),
      ),
    );
  }
}
