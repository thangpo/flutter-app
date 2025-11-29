// lib/features/social/screens/incoming_call_screen.dart
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/call_controller.dart';
import 'call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final int callId;
  final String mediaType; // audio | video

  final String? callerName;
  final String? callerAvatar; // giữ cho code cũ
  final String? peerName; // dùng trong ChatScreen
  final String? peerAvatar; // avatar general

  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.mediaType,
    this.callerName,
    this.callerAvatar,
    this.peerName,
    this.peerAvatar,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  late CallController _cc;
  late VoidCallback _listener;

  bool _handling = false;
  bool _viewAlive = true;
  bool _detaching = false;
  bool _declineRequested = false;

  @override
  void initState() {
    super.initState();

    _cc = context.read<CallController>();
    _listener = _onControllerChanged;
    _cc.addListener(_listener);

    // Delay attach 1 frame để tránh notifyListeners trong lúc build gây assert
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachIfNeeded());
  }

  void _attachIfNeeded() {
    if (!_viewAlive) return;
    if (_cc.isCallHandled(widget.callId)) {
      Navigator.of(context).maybePop();
      return;
    }
    if (_cc.activeCallId != widget.callId) {
      _log('attachCall callId=${widget.callId} media=${widget.mediaType}');
      _cc.attachCall(
        callId: widget.callId,
        mediaType: widget.mediaType,
        initialStatus: 'ringing',
      );
    }
  }

  void _onControllerChanged() async {
    if (!_viewAlive) return;

    final st = _cc.callStatus;
    if (st == 'declined' || st == 'ended') {
      await _safeDetachAndPop();
    }
  }

  Future<void> _safeDetachAndPop() async {
    if (_detaching) return;
    _detaching = true;
    _viewAlive = false;
    _cc.removeListener(_listener);

    try {
      await _cc.detachCall();
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _onAccept() async {
    if (_handling) return;
    setState(() => _handling = true);

    if (_cc.activeCallId != widget.callId) {
      _log('accept: attaching callId=${widget.callId} media=${widget.mediaType}');
      _cc.attachCall(
        callId: widget.callId,
        mediaType: widget.mediaType,
        initialStatus: 'ringing',
      );
    }

    try {
      _log('accept: action(answer) start callId=${widget.callId}');
      await _cc
          .action('answer')
          .timeout(const Duration(seconds: 2), onTimeout: () {
        _log('action(answer) timeout, continue to CallScreen');
      });
    } catch (e, st) {
      _log('action(answer) error: $e', st: st);
    }

    if (!mounted) return;
    _goToCallScreen();
  }

  void _goToCallScreen() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          isCaller: false,
          callId: widget.callId,
          mediaType: widget.mediaType,
          peerName: widget.callerName ?? widget.peerName,
          peerAvatar: widget.peerAvatar ?? widget.callerAvatar,
        ),
      ),
    );
  }

  Future<void> _onDecline() async {
    if (_handling) return;
    _declineRequested = true;
    _log('decline: action(decline) start callId=${widget.callId}');
    setState(() => _handling = true);

    if (_cc.activeCallId != widget.callId) {
      _log('decline: attaching callId=${widget.callId} media=${widget.mediaType}');
      _cc.attachCall(
        callId: widget.callId,
        mediaType: widget.mediaType,
        initialStatus: 'ringing',
      );
    }

    try {
      await _cc
          .action('decline')
          .timeout(const Duration(seconds: 2), onTimeout: () {
        _log('action(decline) timeout');
      });
    } catch (e, st) {
      _log('action(decline) error: $e', st: st);
    }

    await _safeDetachAndPop();
  }

  @override
  void dispose() {
    _viewAlive = false;
    if (!_detaching) {
      _cc.removeListener(_listener);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.mediaType == 'video';
    final name = widget.callerName ?? widget.peerName ?? 'Cuộc gọi đến';
    final avatar = widget.peerAvatar ?? widget.callerAvatar;

    return WillPopScope(
      onWillPop: () async {
        if (!_handling) {
          _log('onWillPop ignored (no auto-decline) callId=${widget.callId}');
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
                    backgroundImage: (avatar != null && avatar.isNotEmpty)
                        ? NetworkImage(avatar)
                        : null,
                    child: (avatar == null || avatar.isEmpty)
                        ? Icon(
                            isVideo ? Icons.videocam : Icons.call,
                            size: 48,
                            color: Colors.white,
                          )
                        : null,
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
                        onPressed: () {
                          _log('tap_decline callId=${widget.callId}');
                          _onDecline();
                        },
                        child: const Icon(Icons.call_end),
                      ),
                      FloatingActionButton(
                        heroTag: 'accept',
                        backgroundColor: Colors.green,
                        onPressed: () {
                          _log('tap_accept callId=${widget.callId}');
                          _onAccept();
                        },
                        child: Icon(
                          isVideo ? Icons.videocam : Icons.call,
                        ),
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

  void _log(String msg, {StackTrace? st}) {
    developer.log(msg, name: 'IncomingCallScreen', stackTrace: st);
  }
}
