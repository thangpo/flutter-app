import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/call_controller.dart';
import 'call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final int callId;
  final String mediaType; // 'audio' | 'video'
  final String? callerName;
  final String? peerName; // nếu có tên phía bên kia
  final String? peerAvatar; // nếu có avatar phía bên kia
  final String? callerAvatar; // legacy

  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.mediaType,
    this.callerName,
    this.peerName,
    this.peerAvatar,
    this.callerAvatar,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  late CallController _cc;
  late VoidCallback _ccListener;

  bool _handling = false;
  bool _attached = false;
  bool _viewAlive = false;

  @override
  void initState() {
    super.initState();
    _viewAlive = true;

    _cc = context.read<CallController>();
    _ccListener = _onControllerChanged;
    _cc.addListener(_ccListener);

    // Đảm bảo controller biết call hiện tại (nếu màn này mở từ push/Firebase)
    _ensureAttach();
  }

  void _onControllerChanged() {
    if (!_viewAlive) return;

    final st = _cc.callStatus;
    if (st == 'declined' || st == 'ended') {
      // Peer đã kết thúc / từ chối trong khi đang hiện màn "Cuộc gọi đến"
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  void _ensureAttach() {
    if (_cc.activeCallId != widget.callId) {
      _cc.attachCall(
        callId: widget.callId,
        mediaType: widget.mediaType,
        initialStatus: 'ringing',
      );
    }
    _attached = true;
  }

  Future<void> _onAccept() async {
    if (_handling) return;
    setState(() => _handling = true);

    // Gắn call lần nữa để chắc (idempotent)
    if (!_attached || _cc.activeCallId != widget.callId) {
      _ensureAttach();
    }

    // Đánh dấu answered trên server (idempotent, có thể fail im lặng)
    try {
      await _cc.action('answer');
    } catch (_) {}

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          isCaller: false, // callee
          callId: widget.callId,
          mediaType: widget.mediaType,
          peerName: widget.callerName ?? widget.peerName,
          peerAvatar: widget.callerAvatar ?? widget.peerAvatar,
        ),
      ),
    );
  }

  Future<void> _onDecline() async {
    if (_handling) return;
    setState(() => _handling = true);

    // Nếu chưa attach, attach để gọi action được
    if (!_attached || _cc.activeCallId != widget.callId) {
      _ensureAttach();
    }
    try {
      await _cc.action('decline');
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _viewAlive = false;
    _cc.removeListener(_ccListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.mediaType == 'video';
    final name = widget.callerName ?? widget.peerName ?? 'Cuộc gọi đến';

    return WillPopScope(
      onWillPop: () async {
        // Back = từ chối
        if (!_handling) {
          _onDecline();
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(child: Container(color: Colors.black)),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.white12,
                    child: Icon(
                      isVideo ? Icons.videocam : Icons.call,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isVideo ? 'Video call' : 'Audio call',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FloatingActionButton(
                        heroTag: 'decline',
                        backgroundColor: Colors.red,
                        onPressed: _onDecline,
                        child: const Icon(Icons.call_end),
                      ),
                      FloatingActionButton(
                        heroTag: 'accept',
                        backgroundColor: Colors.green,
                        onPressed: _onAccept,
                        child: Icon(isVideo ? Icons.videocam : Icons.call),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_handling)
                    const Text(
                      'Đang xử lý...',
                      style: TextStyle(color: Colors.white54),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
