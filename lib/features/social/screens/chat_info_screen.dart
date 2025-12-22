import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/screens/chat_media_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/call/zego_call_service.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_chat_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/profile_screen.dart';

class ChatInfoScreen extends StatelessWidget {
  final String peerId;
  final String peerName;
  final String? peerAvatar;
  final String accessToken;

  const ChatInfoScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    required this.peerAvatar,
    required this.accessToken,
  });

  // ==== LOGIC GỌI THOẠI / VIDEO – Y NHƯ CHAT SCREEN ====
  Future<void> _startCall(BuildContext context, String mediaType) async {
    final repo = SocialChatRepository();

    try {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) throw 'Cần quyền Micro để thực hiện cuộc gọi';

      final isVideo = mediaType == 'video';
      if (isVideo) {
        final cam = await Permission.camera.request();
        if (!cam.isGranted) throw 'Cần quyền Camera để gọi video';
      }

      final callId = ZegoCallService.I.newOneOnOneCallId(peerId);
      final ok = await ZegoCallService.I.startOneOnOne(
        peerId: peerId,
        peerName: peerName,
        isVideoCall: isVideo,
        callID: callId,
      );
      if (!ok) throw 'Không gửi được lời mời gọi';

      final payload = {
        'type': 'zego_call_log',
        'call_id': callId, // string
        'media': mediaType,
        'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

      await repo.sendMessage(
        token: accessToken,
        peerUserId: peerId,
        text: jsonEncode(payload),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể bắt đầu cuộc gọi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông tin đoạn chat"),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SizedBox(height: 24),

          // ========== AVATAR + TÊN + PILL MÃ HOÁ ==========
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: peerAvatar != null && peerAvatar!.isNotEmpty
                      ? NetworkImage(peerAvatar!)
                      : null,
                  child: (peerAvatar == null || peerAvatar!.isEmpty)
                      ? Text(
                          peerName.isNotEmpty ? peerName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  peerName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, size: 14, color: Colors.black87),
                      const SizedBox(width: 6),
                      Text(
                        "Được mã hóa đầu cuối",
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ========== HÀNG NÚT NHANH ==========
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _roundButton(
                icon: Icons.call,
                text: "Gọi thoại",
                onTap: () => _startCall(context, 'audio'),
              ),
              _roundButton(
                icon: Icons.videocam,
                text: "Gọi video",
                onTap: () => _startCall(context, 'video'),
              ),
              _roundButton(
                icon: Icons.person,
                text: "Trang cá nhân",
                onTap: () {
                  // 👉 Mở trang cá nhân của người này
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(targetUserId: peerId),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ========== TÙY CHỈNH ==========
          _sectionHeader("Tuỳ chỉnh"),
          _menuTile(
            icon: Icons.brightness_1,
            iconColor: Colors.blue,
            title: "Chủ đề",
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // ========== HÀNH ĐỘNG KHÁC ==========
          _sectionHeader("Hành động khác"),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text("Xem file phương tiện, file và liên kết"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatMediaScreen(
                    accessToken: accessToken,
                    peerId: peerId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ====== NÚT TRÒN HÀNG TRÊN ======
  Widget _roundButton({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    final disabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Opacity(
        opacity: disabled ? 0.4 : 1,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ====== ITEM MENU ======
  Widget _menuTile({
    required IconData icon,
    required String title,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Colors.black87,
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14),
      ),
      onTap: onTap,
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
