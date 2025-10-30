import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_friends_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_friends_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_friend.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/group_chat_controller.dart';

class CreateGroupScreen extends StatefulWidget {
  final String accessToken;
  const CreateGroupScreen({super.key, required this.accessToken});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final friendsCtrl =
      Get.put(SocialFriendsController(SocialFriendsRepository()));
  final nameCtrl = TextEditingController();
  File? avatarFile;

  final Set<String> selectedIds = {};

  @override
  void initState() {
    super.initState();
    friendsCtrl.load(widget.accessToken, context: context);
  }

  Future<void> _pickImage() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
    );
    if (picked != null && picked.files.single.path != null) {
      setState(() {
        avatarFile = File(picked.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final groupCtrl = context.watch<GroupChatController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo nhóm chat'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🧱 Nhập tên nhóm
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên nhóm',
                hintText: 'VD: Nhóm lập trình Flutter',
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // 🖼️ Chọn ảnh nhóm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Chọn ảnh nhóm'),
                ),
                const SizedBox(width: 8),
                if (avatarFile != null)
                  CircleAvatar(
                    backgroundImage: FileImage(avatarFile!),
                    radius: 20,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(thickness: 0.5, color: cs.outlineVariant.withOpacity(.6)),
          const SizedBox(height: 4),
          const Text('Chọn thành viên',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),

          // 👥 Danh sách bạn bè
          Expanded(
            child: Obx(() {
              final list = friendsCtrl.filtered;
              if (friendsCtrl.isLoading.value && list.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (list.isEmpty) {
                return const Center(child: Text('Không có bạn bè nào để chọn'));
              }

              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => Divider(
                    height: 1, color: cs.outlineVariant.withOpacity(.4)),
                itemBuilder: (_, i) {
                  final friend = list[i];
                  final isSelected = selectedIds.contains(friend.id);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (friend.avatar?.isNotEmpty ?? false)
                          ? NetworkImage(friend.avatar ?? '')
                          : null,
                      child: (friend.avatar?.isEmpty ?? true)
                          ? Text(friend.name.isNotEmpty ? friend.name[0] : '?')
                          : null,
                    ),

                    title: Text(friend.name),
                    subtitle: Text(friend.isOnline
                        ? 'Đang hoạt động'
                        : (friend.lastSeen ?? '')),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (_) {
                        setState(() {
                          if (isSelected) {
                            selectedIds.remove(friend.id);
                          } else {
                            selectedIds.add(friend.id);
                          }
                        });
                      },
                    ),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedIds.remove(friend.id);
                        } else {
                          selectedIds.add(friend.id);
                        }
                      });
                    },
                  );
                },
              );
            }),
          ),

          // 🧩 Nút tạo nhóm
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: groupCtrl.creatingGroup
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Vui lòng nhập tên nhóm')),
                          );
                          return;
                        }
                        if (selectedIds.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Chọn ít nhất 1 thành viên')),
                          );
                          return;
                        }

                        final success = await groupCtrl.createGroup(
                          accessToken: widget.accessToken,
                          name: name,
                          memberIds: selectedIds.toList(),
                          avatarFile: avatarFile,
                        );

                        if (!mounted) return;
                        if (success) {
                          Navigator.pop(context, true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(groupCtrl.lastError ??
                                    'Tạo nhóm thất bại')),
                          );
                        }
                      },
                icon: groupCtrl.creatingGroup
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: const Text('Tạo nhóm'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
