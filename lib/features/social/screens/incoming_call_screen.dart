import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/call_controller.dart';
import 'call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final int callId;
  final String mediaType; // 'audio' | 'video'
  final String? callerName; // nếu bạn đã có
  final String? peerName; // <<< THÊM
  final String? peerAvatar; 
  final String? callerAvatar;

  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.mediaType,
    this.callerName,
    this.peerName, // <<< THÊM
    this.peerAvatar,  
    this.callerAvatar,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  bool _handling = false;

  Future<void> _onAccept() async {
    if (_handling) return;
    setState(() => _handling = true);

    // Đánh dấu answered trên server (nếu fail cũng không sao, vào CallScreen vẫn xử lý tiếp)
    try {
      await context.read<CallController>().action('answer');
    } catch (_) {}

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          isCaller: false, // callee
          callId: widget.callId,
          mediaType: widget.mediaType, // 'audio' | 'video'
          peerName: widget.callerName,
          peerAvatar: widget.callerAvatar,
        ),
      ),
    );
  }

  Future<void> _onDecline() async {
    if (_handling) return;
    setState(() => _handling = true);

    try {
      await context.read<CallController>().action('decline');
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.mediaType == 'video';
    final name = widget.callerName ?? 'Cuộc gọi đến';

    return Scaffold(
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
