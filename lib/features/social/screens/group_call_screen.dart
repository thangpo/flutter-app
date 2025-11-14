// G:\flutter-app\lib\features\social\screens\group_call_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/group_call_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/group_chat_controller.dart';

class GroupCallScreen extends StatefulWidget {
  final String groupId;
  final String mediaType; // 'audio' | 'video'
  final int? callId;
  final List<int>? invitees;
  final String? groupName;

  const GroupCallScreen({
    super.key,
    required this.groupId,
    required this.mediaType,
    this.callId,
    this.invitees,
    this.groupName,
  });

  @override
  State<GroupCallScreen> createState() => _GroupCallScreenState();
}

class _GroupCallScreenState extends State<GroupCallScreen> {
  late final GroupCallController _gc;

  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  bool _micOn = true;
  bool _camOn = true;

  final Map<int, RTCPeerConnection> _pcByUser = {};
  final Map<int, RTCVideoRenderer> _remoteRendererByUser = {};
  final Map<int, List<RTCIceCandidate>> _pendingIceByUser = {};

  // De-duplicate ICE per peer
  final Map<int, Set<String>> _addedCandKeysByUser = {};

  // ICE restart guards per peer
  final Map<int, bool> _iceRestartingByUser = {};
  final Map<int, int> _iceRestartTriesByUser = {};
  static const int _iceRestartMaxTries = 2;

  bool _starting = true;
  bool _leaving = false;
  String? _error;

  // Auto-close guard when status becomes idle/ended
  bool _closingByStatus = false;

  bool get _isVideo => widget.mediaType == 'video';
  bool get _isCreator => _gc.isCreator;

  // ✅ Luôn trả về int an toàn
  int get _myId {
    try {
      final ctrl = context.read<GroupChatController>();
      final val = ctrl.currentUserId;
      if (val == null) return 0;
      final parsed = int.tryParse(val);
      if (parsed != null) return parsed;
      return 0;
    } catch (_) {
      return 0;
    }
  }

  bool _shouldOfferTo(int peerId) {
    // Chống glare: id nhỏ tạo offer trước
    if (_myId != 0 && peerId != 0) return _myId < peerId;
    // Fallback: nếu mình là người tạo cuộc gọi (không có callId truyền vào)
    return widget.callId == null;
  }

  void _handleStatusChanged(CallStatus st) {
    if (!mounted) return;
    setState(() {}); // sync UI như cũ

    if (_leaving) return; // đã rời thủ công

    // Khi controller cleanup (idle) hoặc báo ended → tự đóng màn hình
    if (st == CallStatus.idle || st == CallStatus.ended) {
      if (_closingByStatus) return;
      _closingByStatus = true;
      _leaving = true; // tránh leave trùng trong dispose

      _disposeMediaAndPCs().whenComplete(() {
        if (mounted) {
          Navigator.of(context).maybePop();
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _gc = context.read<GroupCallController>();

    _gc.onOffer = _onOffer;
    _gc.onAnswer = _onAnswer;
    _gc.onCandidate = _onCandidate;
    _gc.onPeersChanged = (peers) {
      _reconcilePeers(peers);
    };
    _gc.onStatusChanged = _handleStatusChanged;

    _start();
  }

  Future<void> _start() async {
    setState(() {
      _starting = true;
      _error = null;
    });

    try {
      await _prepareLocalMedia();

      if (widget.callId != null) {
        await _gc.attachAndJoin(callId: widget.callId!);
      } else {
        await _gc.joinRoom(
          groupId: widget.groupId,
          mediaType: widget.mediaType,
          invitees: widget.invitees,
        );
      }

      _reconcilePeers(_gc.participants);
    } catch (e) {
      _error = 'Không thể bắt đầu cuộc gọi: $e';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_error!)));
        Navigator.of(context).maybePop();
      }
      return;
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _prepareLocalMedia() async {
    await _localRenderer.initialize();

    final Map<String, dynamic> constraints = {
      'audio': true,
      'video': _isVideo
          ? {
              'facingMode': 'user',
              'width': {'ideal': 720},
              'height': {'ideal': 1280},
              'frameRate': {'ideal': 24},
            }
          : false,
    };
    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    _localRenderer.srcObject = _localStream;

    _micOn = true;
    _camOn = _isVideo;
    _applyTrackEnabled();
  }

  void _applyTrackEnabled() {
    final s = _localStream;
    if (s == null) return;
    for (var t in s.getAudioTracks()) {
      t.enabled = _micOn;
    }
    for (var t in s.getVideoTracks()) {
      t.enabled = _camOn;
    }
  }

  Future<void> _closePeer(int peerId) async {
    final pc = _pcByUser.remove(peerId);
    if (pc != null) {
      try {
        await pc.close();
      } catch (_) {}
    }
    final r = _remoteRendererByUser.remove(peerId);
    if (r != null) {
      try {
        r.srcObject = null;
        await r.dispose();
      } catch (_) {}
    }
    _pendingIceByUser.remove(peerId);
    _addedCandKeysByUser.remove(peerId);
    _iceRestartingByUser.remove(peerId);
    _iceRestartTriesByUser.remove(peerId);
    if (mounted) setState(() {});
  }

  Future<void> _reconcilePeers(Set<int> newPeers) async {
    // Close peers that left
    final toRemove =
        _pcByUser.keys.where((id) => !newPeers.contains(id)).toList();
    for (final id in toRemove) {
      await _closePeer(id);
    }

    // Ensure PCs for new peers
    for (final id in newPeers) {
      if (id == _myId) continue; // không tạo PC với chính mình
      if (!_pcByUser.containsKey(id)) {
        await _ensurePeerConnection(id);
        if (_shouldOfferTo(id)) {
          await _createAndSendOffer(id);
        }
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _ensurePeerConnection(int peerId) async {
    if (_pcByUser.containsKey(peerId)) return;

    final config = {
      'iceServers': [
        {
          'urls': [
            'stun:stun.l.google.com:19302',
            'stun:stun1.l.google.com:19302',
          ],
        },
        // ✅ TURN fallback
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
      // 'iceTransportPolicy': 'relay', // bật khi cần ép đi TURN
      'bundlePolicy': 'max-bundle',
    };

    final pc = await createPeerConnection(config);

    // ===== Local tracks (send) =====
    final s = _localStream;
    if (s != null) {
      for (final t in s.getAudioTracks()) {
        await pc.addTrack(t, s);
      }
      for (final t in s.getVideoTracks()) {
        await pc.addTrack(t, s);
      }
    }

    // ===== BẮT BUỘC: transceiver recv cho unified-plan =====
    try {
      await pc.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
      await pc.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
    } catch (_) {}

    // (Tùy chọn) giới hạn bitrate video gửi đi (~800 kbps)
    try {
      final senders = await pc.getSenders();
      for (final sn in senders) {
        if (sn.track?.kind == 'video') {
          await sn.setParameters(RTCRtpParameters(
            encodings: <RTCRtpEncoding>[
              RTCRtpEncoding(
                maxBitrate: 800 * 1000,
                numTemporalLayers: 2,
                rid: 'f',
              ),
            ],
          ));
        }
      }
    } catch (_) {}

    // ICE out
    pc.onIceCandidate = (c) {
      if (c.candidate == null) return;
      final callId = _gc.currentCallId;
      if (callId == null) return;
      _gc.sendCandidate(
        callId: callId,
        toUserId: peerId,
        candidate: c.candidate!,
        sdpMid: c.sdpMid,
        sdpMLineIndex: c.sdpMLineIndex,
      );
    };

    // ===== Remote media in =====
    pc.onTrack = (RTCTrackEvent e) async {
      // 1) ưu tiên dùng stream có sẵn
      MediaStream? stream = e.streams.isNotEmpty ? e.streams.first : null;

      // 2) fallback khi streams trống (unified-plan)
      if (stream == null) {
        stream = await createLocalMediaStream('remote_$peerId');
        await stream.addTrack(e.track);
      }

      var r = _remoteRendererByUser[peerId];
      if (r == null) {
        r = RTCVideoRenderer();
        await r.initialize();
        _remoteRendererByUser[peerId] = r;
      }
      r.srcObject = stream;
      if (mounted) setState(() {});
    };

    // Debug/khôi phục ICE
    pc.onIceConnectionState = (st) async {
      debugPrint('[ICE][$peerId] $st');
      if (st == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          st == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        await _attemptIceRestart(peerId, pc);
      }
    };
    pc.onConnectionState = (st) => debugPrint('[PC][$peerId] $st');

    // (Optional) hỗ trợ Plan-B cũ: onAddStream
    pc.onAddStream = (MediaStream stream) async {
      var r = _remoteRendererByUser[peerId];
      if (r == null) {
        r = RTCVideoRenderer();
        await r.initialize();
        _remoteRendererByUser[peerId] = r;
      }
      r.srcObject = stream;
      if (mounted) setState(() {});
    };

    _pcByUser[peerId] = pc;

    // apply pending ICE (nếu có)
    final pend = _pendingIceByUser.remove(peerId);
    if (pend != null) {
      for (final cand in pend) {
        await pc.addCandidate(cand);
      }
    }
  }

  Future<void> _attemptIceRestart(int peerId, RTCPeerConnection pc) async {
    final tries = _iceRestartTriesByUser[peerId] ?? 0;
    final restarting = _iceRestartingByUser[peerId] ?? false;

    if (restarting || tries >= _iceRestartMaxTries) return;
    _iceRestartingByUser[peerId] = true;
    _iceRestartTriesByUser[peerId] = tries + 1;

    try {
      final offer = await pc.createOffer({'iceRestart': true});
      await pc.setLocalDescription(offer);
      final callId = _gc.currentCallId;
      if (callId != null) {
        await _gc.sendOffer(
          callId: callId,
          toUserId: peerId,
          sdp: offer.sdp ?? '',
        );
      }
    } catch (_) {
      // ignore
    } finally {
      Future.delayed(const Duration(seconds: 4), () {
        _iceRestartingByUser[peerId] = false;
      });
    }
  }

  Future<void> _createAndSendOffer(int peerId) async {
    final pc = _pcByUser[peerId];
    if (pc == null) return;

    final offer = await pc.createOffer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': 1,
    });
    await pc.setLocalDescription(offer);

    final callId = _gc.currentCallId;
    if (callId == null) return;

    await _gc.sendOffer(
      callId: callId,
      toUserId: peerId,
      sdp: offer.sdp ?? '',
    );
  }

  Future<void> _onOffer(Map<String, dynamic> ev) async {
    final fromId = _asInt(ev['from_id']);
    final sdp = (ev['sdp'] ?? '').toString();
    if (fromId == null || sdp.isEmpty) return;

    await _ensurePeerConnection(fromId);
    final pc = _pcByUser[fromId]!;
    await pc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));

    final answer = await pc.createAnswer({
      // ✅ đảm bảo nhận media khi trả lời
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': 1,
    });
    await pc.setLocalDescription(answer);

    final callId = _gc.currentCallId;
    if (callId == null) return;

    await _gc.sendAnswer(
      callId: callId,
      toUserId: fromId,
      sdp: answer.sdp ?? '',
    );
  }

  Future<void> _onAnswer(Map<String, dynamic> ev) async {
    final fromId = _asInt(ev['from_id']);
    final sdp = (ev['sdp'] ?? '').toString();
    if (fromId == null || sdp.isEmpty) return;

    final pc = _pcByUser[fromId];
    if (pc == null) return;

    await pc.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
  }

  Future<void> _onCandidate(Map<String, dynamic> ev) async {
    final fromId = _asInt(ev['from_id']);
    final cand = (ev['candidate'] ?? '').toString();
    if (fromId == null || cand.isEmpty) return;

    int? mline;
    final rawIdx = ev['sdpMLineIndex'];
    if (rawIdx is int) {
      mline = rawIdx;
    } else if (rawIdx is String) {
      mline = int.tryParse(rawIdx);
    }
    final mid = (ev['sdpMid'] ?? '').toString().isEmpty
        ? null
        : ev['sdpMid'] as String?;

    // ✅ de-dupe ICE per peer
    final key = '$cand|${mid ?? ""}|${mline ?? -1}';
    final seen = _addedCandKeysByUser.putIfAbsent(fromId, () => <String>{});
    if (seen.contains(key)) return;
    seen.add(key);

    final c = RTCIceCandidate(cand, mid, mline);

    final pc = _pcByUser[fromId];
    if (pc == null) {
      final list = _pendingIceByUser[fromId] ?? <RTCIceCandidate>[];
      list.add(c);
      _pendingIceByUser[fromId] = list;
      return;
    }
    await pc.addCandidate(c);
  }

  Future<void> _endOrLeave() async {
    if (_leaving) return;
    _leaving = true;
    try {
      final callId = _gc.currentCallId;
      if (callId != null) {
        if (_isCreator) {
          await _gc.endRoom(callId); // ✅ creator đóng phòng
        } else {
          await _gc.leaveRoom(callId);
        }
      }
    } catch (_) {
    } finally {
      await _disposeMediaAndPCs();
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  Future<void> _disposeMediaAndPCs() async {
    for (final pc in _pcByUser.values) {
      try {
        await pc.close();
      } catch (_) {}
    }
    _pcByUser.clear();

    for (final r in _remoteRendererByUser.values) {
      try {
        r.srcObject = null;
        await r.dispose();
      } catch (_) {}
    }
    _remoteRendererByUser.clear();

    try {
      _localRenderer.srcObject = null;
      await _localRenderer.dispose();
    } catch (_) {}
    try {
      _localStream?.getTracks().forEach((t) {
        try {
          t.stop();
        } catch (_) {}
      });
      await _localStream?.dispose();
    } catch (_) {}
    _localStream = null;
  }

  @override
  void dispose() {
    _gc.onOffer = null;
    _gc.onAnswer = null;
    _gc.onCandidate = null;
    _gc.onPeersChanged = null;
    _gc.onStatusChanged = null;

    final callId = _gc.currentCallId;
    final st = _gc.status;

    // Chỉ gọi leave nếu còn trong call và chưa rời bằng luồng khác
    if (callId != null &&
        !_leaving &&
        (st == CallStatus.ongoing || st == CallStatus.ringing)) {
      _gc.leaveRoom(callId).catchError((_) {});
    }

    _disposeMediaAndPCs();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = _isVideo;
    final title = (widget.groupName?.isNotEmpty == true)
        ? widget.groupName!
        : (isVideo ? 'Video call nhóm' : 'Thoại nhóm');

    return WillPopScope(
      onWillPop: () async {
        await _endOrLeave();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(title),
          actions: [
            IconButton(
              tooltip: _isCreator ? 'Kết thúc phòng' : 'Rời cuộc gọi',
              icon: Icon(
                _isCreator ? Icons.call_end : Icons.exit_to_app,
                color: Colors.red,
              ),
              onPressed: _endOrLeave,
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: _starting
                  ? _hint(isVideo
                      ? 'Đang khởi tạo phòng video...'
                      : 'Đang khởi tạo phòng thoại...')
                  : (_error != null ? _hint(_error!) : _callContent()),
            ),
            Positioned(left: 0, right: 0, bottom: 24, child: _controls()),
          ],
        ),
      ),
    );
  }

  Widget _hint(String text) => Center(
        child: Text(text,
            style: const TextStyle(color: Colors.white70, fontSize: 16)),
      );

  Widget _callContent() {
    final tiles = <Widget>[];
    _remoteRendererByUser.forEach((uid, r) {
      tiles.add(_videoTile(renderer: r, label: 'User $uid'));
    });

    if (tiles.isEmpty) {
      tiles.add(Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_isVideo ? Icons.videocam : Icons.call,
                size: 64, color: Colors.white70),
            const SizedBox(height: 12),
            Text(
              _isVideo
                  ? 'Đang kết nối những người tham gia...'
                  : 'Đang kết nối âm thanh nhóm...',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ));
    }

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
          child: GridView.count(
            crossAxisCount: _remoteRendererByUser.length > 1 ? 2 : 1,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 9 / 16,
            children: tiles,
          ),
        ),
        if (_isVideo && _localStream != null)
          Positioned(
            right: 12,
            top: 12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.black54,
                width: 110,
                height: 180,
                child: RTCVideoView(_localRenderer, mirror: true),
              ),
            ),
          ),
      ],
    );
  }

  Widget _videoTile({required RTCVideoRenderer renderer, String? label}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black54),
          RTCVideoView(renderer),
          if ((label ?? '').isNotEmpty)
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(label!,
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _controls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _roundBtn(
          icon: _micOn ? Icons.mic : Icons.mic_off,
          onTap: () {
            setState(() {
              _micOn = !_micOn;
              _applyTrackEnabled();
            });
          },
        ),
        if (_isVideo) const SizedBox(width: 16),
        if (_isVideo)
          _roundBtn(
            icon: _camOn ? Icons.videocam : Icons.videocam_off,
            onTap: () {
              setState(() {
                _camOn = !_camOn;
                _applyTrackEnabled();
              });
            },
          ),
        const SizedBox(width: 16),
        _roundBtn(
          bg: Colors.red,
          icon: _isCreator ? Icons.call_end : Icons.exit_to_app,
          iconColor: Colors.white,
          onTap: _endOrLeave,
          big: true,
        ),
        if (_isVideo) const SizedBox(width: 16),
        if (_isVideo)
          _roundBtn(
            icon: Icons.cameraswitch,
            onTap: () async {
              try {
                final vTracks = _localStream?.getVideoTracks() ?? [];
                if (vTracks.isNotEmpty) {
                  await Helper.switchCamera(vTracks.first);
                }
              } catch (_) {}
            },
          ),
      ],
    );
  }

  Widget _roundBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color bg = const Color(0x22FFFFFF),
    Color iconColor = Colors.white,
    bool big = false,
  }) {
    final double size = big ? 66 : 52;
    return Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: iconColor, size: big ? 28 : 22)),
      ),
    );
  }

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
