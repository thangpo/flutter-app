// lib/features/social/screens/group_call_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// dÃ¹ng navigatorKey lÃ m fallback pop
import 'package:flutter_sixvalley_ecommerce/helper/app_globals.dart' show navigatorKey;

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/group_call_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/group_chat_controller.dart';
import '../utils/ice_server_config.dart';

import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
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
  bool _connecting = false;
  String? _error;

  bool get _isVideo => widget.mediaType == 'video';
  bool get _isCreator => _gc.isCreator;

  // LuÃ´n tráº£ vá» int an toÃ n
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
    // Chống glare: id nhỏ tạo offer trước. Nếu chưa lấy được myId (0) thì vẫn offer để tránh kẹt.
    if (_myId != 0 && peerId != 0) return _myId < peerId;
    return true; // fallback an toàn
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
    _gc.onStatusChanged = (st) async {
      // Khi server bÃ¡o ended/idle á»Ÿ nÆ¡i khÃ¡c -> tá»± Ä‘Ã³ng UI
      if ((st == CallStatus.ended || st == CallStatus.idle) && !_leaving) {
        _leaving = true;
        await _disposeMediaAndPCs();
        await _popScreen();
        return;
      }
      if (mounted) setState(() {});
    };

    _start();
  }

  Future<void> _start() async {
    setState(() {
      _starting = true;
      _connecting = false;
      _error = null;
    });

    try {
      // Limit startup time to avoid getting stuck
      await _prepareLocalMedia().timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw TimeoutException('prepare_media_timeout'),
      );

      if (!mounted) return;
      setState(() {
        _starting = false;
        _connecting = true;
      });

      final Future<void> joinFuture = widget.callId != null
          ? _gc.attachAndJoin(callId: widget.callId!, groupId: widget.groupId)
          : _gc.joinRoom(
              groupId: widget.groupId,
              mediaType: widget.mediaType,
              invitees: widget.invitees,
            );

      await joinFuture.timeout(const Duration(seconds: 12), onTimeout: () {
        throw TimeoutException('join_room_timeout');
      });

      if (mounted) {
        setState(() {
          _connecting = false;
        });
      }

      _reconcilePeers(_gc.participants);
    } catch (e) {
      _error = 'Khong the bat dau cuoc goi nhom: $e';
      _sendDebugLog('start_failed', {
        'group_id': widget.groupId,
        'call_id': '${widget.callId ?? ''}',
        'error': '$e'
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_error!)));
        await _popScreen();
      }
      return;
    } finally {
      if (mounted) {
        setState(() {
          _starting = false;
          _connecting = false;
        });
      }
    }
  }

  Future<void> _prepareLocalMedia() async {
    await _localRenderer.initialize();

    final Map<String, dynamic> constraints = {
      'audio': true,
      'video': _isVideo
          ? {
              'facingMode': 'user',
              // Giảm độ phân giải để khởi tạo/ICE nhanh hơn
              'width': {'ideal': 480, 'max': 640},
              'height': {'ideal': 640, 'max': 720},
              'frameRate': {'ideal': 18, 'max': 24},
              'degradationPreference': 'maintain-framerate',
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
      if (id == _myId) continue; // khÃ´ng táº¡o PC vá»›i chÃ­nh mÃ¬nh
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
      'iceServers': kDefaultIceServers,
      'sdpSemantics': 'unified-plan',
      // Ưu tiên kết nối trực tiếp trước, fallback TURN khi cần để giảm trễ
      'iceTransportPolicy': 'all',
      'bundlePolicy': 'max-bundle',
      'iceCandidatePoolSize': 2,
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

    // ===== transceiver recv cho unified-plan =====
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

    // (TÃ¹y chá»n) giá»›i háº¡n bitrate video gá»­i Ä‘i (~800 kbps)
    try {
      final senders = await pc.getSenders();
      for (final sn in senders) {
        if (sn.track?.kind == 'video') {
          await sn.setParameters(RTCRtpParameters(
            encodings: <RTCRtpEncoding>[
              RTCRtpEncoding(
                maxBitrate: 600 * 1000,
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
      // 1) Æ°u tiÃªn dÃ¹ng stream cÃ³ sáºµn
      MediaStream? stream = e.streams.isNotEmpty ? e.streams.first : null;

      // 2) fallback khi streams trá»‘ng (unified-plan)
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

    // Debug/khÃ´i phá»¥c ICE
    pc.onIceConnectionState = (st) async {
      debugPrint('[ICE][$peerId] $st');
      if (st == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          st == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        await _attemptIceRestart(peerId, pc);
        // Náº¿u Ä‘Ã£ thá»­ restart nhiá»u láº§n mÃ  váº«n failed/disconnected, Ä‘Ã³ng peer Ä‘á»ƒ trÃ¡nh hÃ¬nh treo
        final tries = _iceRestartTriesByUser[peerId] ?? 0;
        if (tries >= _iceRestartMaxTries) {
          await _closePeer(peerId);
        }
      } else if (st == RTCIceConnectionState.RTCIceConnectionStateClosed) {
        await _closePeer(peerId);
      }
    };
    pc.onConnectionState = (st) => debugPrint('[PC][$peerId] $st');

    // (Optional) há»— trá»£ Plan-B cÅ©: onAddStream
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

    // apply pending ICE (náº¿u cÃ³)
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
      // Ä‘áº£m báº£o nháº­n media khi tráº£ lá»i
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

    // de-dupe ICE per peer
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
    final int participantsCount = _gc.participants.length;
    bool preferEnd = false;
    int? callId = _gc.currentCallId;
    try {
      final hasPeers = _gc.participants.isNotEmpty;
      preferEnd = _isCreator || !hasPeers; // nếu chỉ còn mình thì kết thúc phòng
      _sendDebugLog('leave_pressed', {
        'call_id': '${callId ?? ''}',
        'is_creator': '$_isCreator',
        'has_peers': '$hasPeers',
        'prefer_end': '$preferEnd',
        'participants': '$participantsCount',
      });
      if (callId != null) {
        // Gửi request end/leave ở nền để UI không bị kẹt
        unawaited(() async {
          try {
            final future =
                preferEnd ? _gc.endRoom(callId) : _gc.leaveRoom(callId);
            await future.timeout(const Duration(seconds: 8), onTimeout: () {
              throw TimeoutException('leave_timeout');
            });
            await _sendDebugLog('leave_done', {
              'call_id': '$callId',
              'action': preferEnd ? 'end' : 'leave',
              'participants': '$participantsCount',
            });
          } catch (e) {
            // Nếu không phải creator nhưng muốn end, fallback sang leave
            if (preferEnd && !_isCreator) {
              try {
                await _gc
                    .leaveRoom(callId)
                    .timeout(const Duration(seconds: 5), onTimeout: () {
                  throw TimeoutException('leave_timeout_fallback');
                });
                await _sendDebugLog('leave_done_fallback_leave', {
                  'call_id': '$callId',
                  'participants': '$participantsCount',
                  'reason': '$e',
                });
              } catch (_) {}
            } else {
              await _sendDebugLog('leave_error', {
                'error': '$e',
                'prefer_end': '$preferEnd',
                'participants': '$participantsCount',
              });
            }
          }
        }());
      }
    } catch (e) {
      _sendDebugLog('leave_error', {
        'error': '$e',
        'prefer_end': '$preferEnd',
        'participants': '$participantsCount',
      });
    } finally {
      unawaited(_disposeMediaAndPCs().timeout(const Duration(seconds: 3), onTimeout: () => null));
      // Đóng UI ngay, không chờ network
      await _forceCloseUi(callId);
    }
  }

  Future<void> _forceCloseUi(int? callId) async {
    // Kết thúc CallKit/ConnectionService nếu còn kẹt (legacy CallKit đã gỡ, best-effort)
    try {} catch (_) {}

    // Pop mạnh tay: thử nhiều lần để chắc chắn
    await _popScreen();
    Future.microtask(() => _popScreen());
    Future.delayed(const Duration(milliseconds: 350), () => _popScreen());
  }

  // helper pop cứng: thử nhiều đường + removeRoute fallback
  Future<void> _popScreen() async {
    if (!mounted) return;
    unawaited(_sendDebugLog('pop_screen_start', {}));

    // Ưu tiên pop tất cả GroupCallScreen khỏi root stack
    try {
      final nav = Navigator.of(context, rootNavigator: true);
      bool poppedAny = false;
      nav.popUntil((route) {
        final name = route.settings.name ?? '';
        final keep = name != 'GroupCallScreen';
        if (!keep) poppedAny = true;
        return keep;
      });
      if (poppedAny) {
        unawaited(_sendDebugLog('pop_screen_end', {'popped': 'true', 'step': 'popUntilRoot'}));
        return;
      }
    } catch (_) {}

    // 1) Pop bằng context hiện tại
    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        unawaited(_sendDebugLog('pop_screen_end', {'popped': 'true', 'step': 'context'}));
        return;
      }
    } catch (_) {}

    // 2) Pop rootNavigator
    try {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
        unawaited(_sendDebugLog('pop_screen_end', {'popped': 'true', 'step': 'rootNavigator'}));
        return;
      }
    } catch (_) {}

    // 3) Pop qua navigatorKey (nếu màn được mở bằng navigatorKey)
    try {
      if ((navigatorKey.currentState?.canPop() ?? false)) {
        navigatorKey.currentState?.pop();
        unawaited(_sendDebugLog('pop_screen_end', {'popped': 'true', 'step': 'navigatorKey'}));
        return;
      }
    } catch (_) {}

    // 4) Hạ sách: removeRoute(thisRoute) khỏi stack
    try {
      final route = ModalRoute.of(context);
      if (route != null) {
        navigatorKey.currentState?.removeRoute(route);
        unawaited(_sendDebugLog('pop_screen_end', {'popped': 'true', 'step': 'removeRoute'}));
        return;
      }
    } catch (_) {}

    // 5) Cùng lắm thì về root
    try {
      navigatorKey.currentState?.popUntil((r) => r.isFirst);
      unawaited(_sendDebugLog('pop_screen_end', {'popped': 'true', 'step': 'popUntilRootFallback'}));
      return;
    } catch (_) {}

    unawaited(_sendDebugLog('pop_screen_end', {'popped': 'false', 'step': 'no_route'}));
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
    if (callId != null && !_leaving) {
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
        : (isVideo ? 'Video call nhÃ³m' : 'Thoáº¡i nhÃ³m');

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
              tooltip: _isCreator ? 'Káº¿t thÃºc phÃ²ng' : 'Rá»i cuá»™c gá»i',
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
                      ? 'Äang khá»Ÿi táº¡o phÃ²ng video...'
                      : 'Äang khá»Ÿi táº¡o phÃ²ng thoáº¡i...')
                  : (_error != null ? _hint(_error!) : _callContent()),
            ),
            if (_connecting && !_starting)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: _connectingBanner(),
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

  Widget _connectingBanner() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Äang káº¿t ná»i...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

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
                  ? 'Äang káº¿t ná»‘i nhá»¯ng ngÆ°á»i tham gia...'
                  : 'Äang káº¿t ná»‘i Ã¢m thanh nhÃ³m...',
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

  Future<void> _sendDebugLog(String tag, Map<String, String> details) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.socialAccessToken);
      final base = AppConstants.socialBaseUrl.endsWith('/')
          ? AppConstants.socialBaseUrl.substring(0, AppConstants.socialBaseUrl.length - 1)
          : AppConstants.socialBaseUrl;
      final uri = Uri.parse(
        token != null && token.isNotEmpty
            ? '$base/api/webrtc_group?access_token=$token'
            : '$base/api/webrtc_group',
      );
      final body = <String, String>{
        'action': 'client_log',
        'server_key': AppConstants.socialServerKey,
        'message': tag,
        'type': 'webrtc_group',
        'details_json': jsonEncode(details),
      };
      details.forEach((k, v) {
        body['details[$k]'] = v;
      });
      await http.post(uri, body: body).timeout(const Duration(seconds: 5));
    } catch (_) {
      // best effort
    }
  }
}
