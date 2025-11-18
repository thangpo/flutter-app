import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/chat_media_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông tin đoạn chat"),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),

          // Avatar + tên
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: peerAvatar != null && peerAvatar!.isNotEmpty
                      ? NetworkImage(peerAvatar!)
                      : null,
                  child: (peerAvatar == null || peerAvatar!.isEmpty)
                      ? Text(peerName[0],
                          style: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(height: 12),
                Text(peerName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text("Đoạn Chat được mã hóa",
                    style: TextStyle(
                        color: cs.onSurface.withOpacity(.6), fontSize: 13)),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Divider(),

          // Các nút truy cập nhanh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _roundButton(Icons.call, "Gọi thoại"),
              _roundButton(Icons.videocam, "Gọi video"),
              _roundButton(Icons.person, "Trang cá nhân"),
            ],
          ),

          const SizedBox(height: 24),
          Divider(),

          // Tuỳ chỉnh
          _sectionHeader("Tuỳ chỉnh"),
          _menuTile(Icons.color_lens, "Chủ đề"),
          const SizedBox(height: 24),
          Divider(),

          // Hành động khác
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

  Widget _roundButton(IconData icon, String text) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          child: Icon(icon, size: 22),
        ),
        const SizedBox(height: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _menuTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }
}
