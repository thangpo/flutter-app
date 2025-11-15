import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/call_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/call_screen.dart';

/// Màn nhận cuộc gọi.
/// Mở màn này khi bạn biết callId + mediaType (từ push/Firebase, hoặc socket).
class IncomingCallScreen extends StatefulWidget {
  final int callId;
  final String mediaType; // 'audio' | 'video'
  final String? callerName;
  final String? callerAvatar;

  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.mediaType,
    this.callerName,
    this.callerAvatar,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachController();
    });
  }

  Future<void> _attachController() async {
    final call = context.read<CallController>();
    try {
      await call.ensureInitialized();
      await call.attachIncoming(
        callId: widget.callId,
        mediaType: widget.mediaType,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể kết nối cuộc gọi: $e')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _answer() async {
    final call = context.read<CallController>();
    try {
      await call.action('answer'); // báo server: đã nhận
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CallScreen(
            isCaller: false,
            callId: widget.callId,
            mediaType: widget.mediaType,
            peerName: widget.callerName,
            peerAvatar: widget.callerAvatar,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể trả lời: $e')),
      );
    }
  }

  Future<void> _decline() async {
    final call = context.read<CallController>();
    try {
      await call.action('decline');
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.callerName ?? 'Cuộc gọi đến';
    final isVideo = widget.mediaType == 'video';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<CallController>(
          builder: (ctx, call, _) {
            // Nếu caller đã end/decline, tự đóng
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
                  backgroundImage: (widget.callerAvatar != null &&
                          widget.callerAvatar!.isNotEmpty)
                      ? NetworkImage(widget.callerAvatar!)
                      : null,
                  child: (widget.callerAvatar == null ||
                          widget.callerAvatar!.isEmpty)
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
                )
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
            child: const Padding(
              padding: EdgeInsets.all(22),
              child: Icon(Icons.call, color: Colors.white, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
