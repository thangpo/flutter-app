import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/group_call_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/group_call_screen.dart';

/// Fullscreen incoming UI for group calls (accept / decline) shown anywhere in app.
class GroupIncomingCallScreen extends StatelessWidget {
  final String groupId;
  final String? groupName;
  final String media;
  final int callId;

  const GroupIncomingCallScreen({
    super.key,
    required this.groupId,
    required this.media,
    required this.callId,
    this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = media == 'video';

    Future<void> _decline() async {
      try {
        await context.read<GroupCallController>().leaveRoom(callId);
      } catch (_) {}
      if (context.mounted) Navigator.of(context).pop();
    }

    void _accept() {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GroupCallScreen(
            groupId: groupId,
            mediaType: media,
            callId: callId,
            groupName: groupName ?? 'Nh\u00f3m $groupId',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: 12),
                  Text(
                    isVideo ? 'Cu\u1ed9c g\u1ecdi nh\u00f3m video' : 'Cu\u1ed9c g\u1ecdi nh\u00f3m th\u01a1\u0323i',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (groupName ?? '').isNotEmpty ? groupName! : 'Nh\u00f3m $groupId',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Call ID: $callId',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
              Icon(
                isVideo ? Icons.videocam : Icons.call,
                size: 96,
                color: isVideo ? Colors.lightBlueAccent : Colors.greenAccent,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _IncomingButton(
                    label: 'T\u1eeb ch\u1ed1i',
                    color: Colors.redAccent,
                    icon: Icons.call_end,
                    onTap: _decline,
                  ),
                  _IncomingButton(
                    label: 'Nghe',
                    color: Colors.green,
                    icon: isVideo ? Icons.videocam : Icons.call,
                    onTap: _accept,
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

class _IncomingButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _IncomingButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(36),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }
}
