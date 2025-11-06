// lib/features/social/screens/incoming_call_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/call_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final int callId;
  final String mediaType; // 'audio' | 'video'
  final String? peerName;
  final String? peerAvatar;

  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.mediaType,
    this.peerName,
    this.peerAvatar,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  @override
  void initState() {
    super.initState();
    // attach to the ringing call so controller starts polling
    context
        .read<CallController>()
        .attachIncoming(callId: widget.callId, mediaType: widget.mediaType);
  }

  Future<void> _answer() async {
    final call = context.read<CallController>();
    try {
      await call.action('answer');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            isCaller: false,
            callId: widget.callId,
            mediaType: widget.mediaType,
            peerName: widget.peerName,
            peerAvatar: widget.peerAvatar,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không thể trả lời: $e')));
    }
  }

  Future<void> _decline() async {
    try {
      await context.read<CallController>().action('decline');
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.mediaType == 'video';
    final name = widget.peerName ?? 'Cuộc gọi đến';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<CallController>(
          builder: (ctx, call, _) {
            // auto-close if caller ended/declined
            if (call.callStatus == 'ended' || call.callStatus == 'declined') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
              });
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                CircleAvatar(
                  radius: 56,
                  backgroundImage: (widget.peerAvatar?.isNotEmpty ?? false)
                      ? NetworkImage(widget.peerAvatar!)
                      : null,
                  child: (widget.peerAvatar?.isEmpty ?? true)
                      ? const Icon(Icons.person, size: 56)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(name,
                    style: const TextStyle(color: Colors.white, fontSize: 22)),
                const SizedBox(height: 8),
                Text(isVideo ? 'Cuộc gọi video' : 'Cuộc gọi thoại',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _bigRoundBtn(
                      icon: Icons.call_end,
                      color: Colors.red,
                      onTap: _decline,
                      label: 'Từ chối',
                    ),
                    const SizedBox(width: 48),
                    _bigRoundBtn(
                      icon: isVideo ? Icons.videocam : Icons.call,
                      color: Colors.green,
                      onTap: _answer,
                      label: 'Trả lời',
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _bigRoundBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String label,
  }) {
    return Column(
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Icon(icon, color: Colors.white, size: 32), // <-- use param
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
