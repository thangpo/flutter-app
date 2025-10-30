import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_friends_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_friends_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_friend.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/chat_screen.dart';

// 👇 nhóm chat
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/group_chat_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/create_group_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/group_chats_screen.dart';

class FriendsListScreen extends StatefulWidget {
  final String accessToken;
  const FriendsListScreen({super.key, required this.accessToken});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  final friendsCtrl =
      Get.put(SocialFriendsController(SocialFriendsRepository()));
  final searchCtrl = TextEditingController();

  int _tabIndex = 0;
  int chatBadgeCount = 1;
  bool notifDot = true;

  @override
  void initState() {
    super.initState();
    friendsCtrl.load(widget.accessToken, context: context);
  }

  Future<void> _onRefresh() async {
    await friendsCtrl.load(widget.accessToken, context: context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đoạn chat'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Tạo nhóm chat',
            icon: const Icon(Icons.group_add),
            onPressed: () async {
              final success = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CreateGroupScreen(accessToken: widget.accessToken),
                ),
              );
              if (success == true) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tạo nhóm thành công')),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.edit),
      ),
      bottomNavigationBar: _MessengerFooter(
        currentIndex: _tabIndex,
        chatBadgeCount: chatBadgeCount,
        showNotifDot: notifDot,
        onTap: (i) {
          setState(() => _tabIndex = i);
          if (i == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    GroupChatsScreen(accessToken: widget.accessToken),
              ),
            );
          }
        },
      ),
      body: Column(
        children: [
          // 🔍 ô tìm kiếm
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: TextField(
              controller: searchCtrl,
              onChanged: friendsCtrl.search,
              decoration: InputDecoration(
                hintText: 'Hỏi Meta AI hoặc tìm kiếm',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: cs.surfaceVariant.withOpacity(.5),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 👥 dải avatar ngang
          SizedBox(
            height: 102,
            child: Obx(() {
              final list = friendsCtrl.friends;
              if (friendsCtrl.isLoading.value && list.isEmpty) {
                return const _AvatarStripSkeleton();
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final u = list[i];
                  return _AvatarStoryTile(
                    name: u.name,
                    avatar: u.avatar,
                    online: u.isOnline,
                    onTap: () => _openChat(u),
                  );
                },
              );
            }),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: cs.outlineVariant.withOpacity(.6),
            ),
          ),

          // 📜 danh sách bạn bè (dọc)
          Expanded(
            child: Obx(() {
              if (friendsCtrl.isLoading.value && friendsCtrl.filtered.isEmpty) {
                return const _MessengerSkeleton();
              }
              final list = friendsCtrl.filtered;
              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: list.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 36),
                          Center(child: Text('Chưa có bạn bè.')),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          thickness: 0.5,
                          color: cs.outlineVariant.withOpacity(.6),
                          indent: 76,
                        ),
                        itemBuilder: (_, i) {
                          final u = list[i];
                          final preview = u.isOnline
                              ? 'Đang hoạt động'
                              : (u.lastSeen ?? '');
                          return InkWell(
                            onTap: () => _openChat(u),
                            onLongPress:
                                _openCreateGroupDialog, // ✨ thêm tùy chọn nhanh
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  _ChatAvatar(
                                    url: u.avatar,
                                    online: u.isOnline,
                                    label: u.name,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          u.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: cs.onSurface,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          preview.isEmpty ? ' ' : preview,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: cs.onSurface.withOpacity(.7),
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _openChat(SocialFriend u) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          receiverId: u.id,
          accessToken: widget.accessToken,
          title: u.name,
          avatar: u.avatar,
        ),
      ),
    );
  }

  /// 🧩 Dialog tạo nhóm chat nhanh
  void _openCreateGroupDialog() {
    final nameCtrl = TextEditingController();
    final partsCtrl = TextEditingController(); // nhập: 2,3,4
    File? avatarFile;

    showDialog(
      context: context,
      builder: (ctx) {
        final groupCtrl = context.watch<GroupChatController>();
        return AlertDialog(
          title: const Text('Tạo nhóm chat'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên nhóm',
                    hintText: 'VD: Team Dev',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: partsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ID thành viên (phân tách dấu phẩy)',
                    hintText: 'VD: 2,3,4',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await FilePicker.platform.pickFiles(
                          allowMultiple: false,
                          type: FileType.image,
                        );
                        if (picked != null &&
                            picked.files.single.path != null) {
                          setState(() {
                            avatarFile = File(picked.files.single.path!);
                          });
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Chọn ảnh nhóm (tùy chọn)'),
                    ),
                    const SizedBox(width: 8),
                    if (avatarFile != null)
                      const Icon(Icons.check_circle,
                          size: 18, color: Colors.green),
                  ],
                ),
                if (groupCtrl.lastError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    groupCtrl.lastError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: groupCtrl.creatingGroup
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final raw = partsCtrl.text.trim();
                      if (name.isEmpty || raw.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Nhập tên nhóm và ID thành viên hợp lệ'),
                          ),
                        );
                        return;
                      }
                      final ids = raw
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();

                      final success =
                          await context.read<GroupChatController>().createGroup(
                                name: name,
                                memberIds: ids,
                                avatarFile: avatarFile,
                              );

                      if (!mounted) return;
                      if (success) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tạo nhóm thành công!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Không thể tạo nhóm!')),
                        );
                      }
                    },
              child: groupCtrl.creatingGroup
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Tạo nhóm'),
            ),
          ],
        );
      },
    );
  }
}

/* ===== FOOTER (Messenger style) ===== */
class _MessengerFooter extends StatelessWidget {
  final int currentIndex;
  final int chatBadgeCount;
  final bool showNotifDot;
  final ValueChanged<int> onTap;

  const _MessengerFooter({
    required this.currentIndex,
    required this.chatBadgeCount,
    required this.showNotifDot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget item({
      required int index,
      required IconData icon,
      required String label,
      int? badge,
      bool dot = false,
    }) {
      final bool active = currentIndex == index;
      final Color iconColor = active ? Colors.blue : Colors.grey.shade700;
      final Color textColor = active ? Colors.blue : Colors.grey.shade700;

      return Expanded(
        child: InkWell(
          onTap: () => onTap(index),
          child: SizedBox(
            height: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, size: 24, color: iconColor),
                    if ((badge ?? 0) > 0)
                      Positioned(
                        right: -10,
                        top: -6,
                        child: _Badge(text: (badge!).toString()),
                      ),
                    if (dot)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: _Dot(color: Colors.red),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: textColor),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      elevation: 6,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: cs.outlineVariant, width: .5)),
        ),
        child: Row(
          children: [
            item(
                index: 0,
                icon: Icons.chat_bubble,
                label: 'Đoạn chat',
                badge: chatBadgeCount),
            item(index: 1, icon: Icons.video_collection, label: 'Tin'),
            item(
                index: 2,
                icon: Icons.groups,
                label: 'Nhóm Chat',
                dot: showNotifDot),
            item(index: 3, icon: Icons.menu, label: 'Menu'),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

/* ===== Avatar components & skeletons ===== */

class _AvatarStoryTile extends StatelessWidget {
  final String name;
  final String? avatar;
  final bool online;
  final VoidCallback? onTap;
  const _AvatarStoryTile(
      {required this.name,
      required this.avatar,
      required this.online,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 74,
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: cs.surfaceVariant,
                  backgroundImage: (avatar != null && avatar!.isNotEmpty)
                      ? NetworkImage(avatar!)
                      : null,
                  child: (avatar == null || avatar!.isEmpty)
                      ? Text(name.isNotEmpty ? name[0] : '?',
                          style: TextStyle(
                              color: cs.onSurface, fontWeight: FontWeight.bold))
                      : null,
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: online ? Colors.green : cs.surfaceVariant,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: cs.onSurface)),
          ],
        ),
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  final String? url;
  final bool online;
  final String label;
  const _ChatAvatar(
      {required this.url, required this.online, required this.label});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: cs.surfaceVariant,
          backgroundImage:
              (url != null && url!.isNotEmpty) ? NetworkImage(url!) : null,
          child: (url == null || url!.isEmpty)
              ? Text(label.isNotEmpty ? label[0] : '?',
                  style: TextStyle(
                      color: cs.onSurface, fontWeight: FontWeight.bold))
              : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: online ? Colors.green : cs.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarStripSkeleton extends StatelessWidget {
  const _AvatarStripSkeleton();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemBuilder: (_, __) => Column(
        children: [
          CircleAvatar(radius: 28, backgroundColor: cs.surfaceVariant),
          const SizedBox(height: 6),
          Container(width: 54, height: 10, color: cs.surfaceVariant),
        ],
      ),
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemCount: 8,
    );
  }
}

class _MessengerSkeleton extends StatelessWidget {
  const _MessengerSkeleton();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 10,
      itemBuilder: (_, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(radius: 26, backgroundColor: cs.surfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 140, color: cs.surfaceVariant),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 220, color: cs.surfaceVariant),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
