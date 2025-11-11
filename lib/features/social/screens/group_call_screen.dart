// G:\flutter-app\lib\features\social\screens\group_call_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/group_call_controller.dart';

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

  bool _starting = true;
  bool _leaving = false;
  String? _error;

  bool get _isVideo => widget.mediaType == 'video';

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
    _gc.onStatusChanged = (_) {
      if (mounted) setState(() {});
    };

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
    if (mounted) setState(() {});
  }

  Future<void> _reconcilePeers(Set<int> newPeers) async {
    final toRemove =
        _pcByUser.keys.where((id) => !newPeers.contains(id)).toList();
    for (final id in toRemove) {
      await _closePeer(id);
    }

    for (final id in newPeers) {
      if (!_pcByUser.containsKey(id)) {
        await _ensurePeerConnection(id);
        await _createAndSendOffer(id);
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _ensurePeerConnection(int peerId) async {
    if (_pcByUser.containsKey(peerId)) return;

    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        // TURN (nếu có):
        // {'urls': 'turn:turn.yourdomain.com:3478', 'username': 'user', 'credential': 'pass'},
      ],
      'sdpSemantics': 'unified-plan', // dùng Unified Plan chuẩn mới
    };

    final pc = await createPeerConnection(config);

    // ✅ Unified Plan: dùng addTrack thay cho addStream
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    }

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

    // ✅ Unified Plan: nhận remote qua onTrack
    pc.onTrack = (RTCTrackEvent event) async {
      if (event.streams.isEmpty) return;
      final stream = event.streams[0];
      final r = _remoteRendererByUser[peerId] ?? RTCVideoRenderer();
      if (!_remoteRendererByUser.containsKey(peerId)) {
        await r.initialize();
        _remoteRendererByUser[peerId] = r;
      }
      r.srcObject = stream;
      if (mounted) setState(() {});
    };

    // (Không dùng onAddStream khi Unified Plan)
    pc.onIceConnectionState = (state) {
      // có thể log / xử lý reconnect nếu muốn
    };

    _pcByUser[peerId] = pc;

    final pend = _pendingIceByUser.remove(peerId);
    if (pend != null) {
      for (final cand in pend) {
        try {
          await pc.addCandidate(cand);
        } catch (_) {}
      }
    }
  }

  Future<void> _createAndSendOffer(int peerId) async {
    final pc = _pcByUser[peerId];
    if (pc == null) return;

    final offer = await pc.createOffer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': _isVideo ? 1 : 0,
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
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': _isVideo ? 1 : 0,
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

    final c = RTCIceCandidate(
      cand,
      (ev['sdpMid'] ?? '').toString().isEmpty ? null : ev['sdpMid'] as String?,
      ev['sdpMLineIndex'] is int ? ev['sdpMLineIndex'] as int? : null,
    );

    final pc = _pcByUser[fromId];
    if (pc == null) {
      final list = _pendingIceByUser[fromId] ?? <RTCIceCandidate>[];
      list.add(c);
      _pendingIceByUser[fromId] = list;
      return;
    }
    try {
      await pc.addCandidate(c);
    } catch (_) {}
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    try {
      final callId = _gc.currentCallId;
      if (callId != null) {
        await _gc.leaveRoom(callId);
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
    if (callId != null) {
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
        await _leave();
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
              tooltip: 'Kết thúc',
              icon: const Icon(Icons.call_end, color: Colors.red),
              onPressed: _leave,
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
          icon: Icons.call_end,
          iconColor: Colors.white,
          onTap: _leave,
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
