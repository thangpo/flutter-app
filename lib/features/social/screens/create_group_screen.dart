import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_friends_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_friends_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/group_chat_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_friend.dart';

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
        title: const Text(
          'Nhóm mới',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: groupCtrl.creatingGroup
                ? null
                : () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nhập tên nhóm')),
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
                            content: Text(
                                groupCtrl.lastError ?? 'Tạo nhóm thất bại')),
                      );
                    }
                  },
            child: groupCtrl.creatingGroup
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'TẠO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔹 Avatar nhóm & tên nhóm
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                            avatarFile != null ? FileImage(avatarFile!) : null,
                        child: avatarFile == null
                            ? const Icon(Icons.camera_alt, color: Colors.white)
                            : null,
                      ),
                      if (avatarFile != null)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(
                              Icons.edit,
                              size: 14,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Tên nhóm (không bắt buộc)',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Thanh hiển thị thành viên đã chọn
          if (selectedIds.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: friendsCtrl.filtered
                    .where((f) => selectedIds.contains(f.id))
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundImage:
                                        (f.avatar?.isNotEmpty ?? false)
                                            ? NetworkImage(f.avatar!)
                                            : null,
                                    child: (f.avatar?.isEmpty ?? true)
                                        ? Text(
                                            f.name.isNotEmpty
                                                ? f.name[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedIds.remove(f.id);
                                        });
                                      },
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                f.name,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),

          // 🔹 Ô tìm kiếm bạn bè
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              onChanged: friendsCtrl.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Tìm kiếm',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(left: 16, top: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Gợi ý',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // 🔹 Danh sách bạn bè
          Expanded(
            child: Obx(() {
              final list = friendsCtrl.filtered;
              if (friendsCtrl.isLoading.value && list.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (list.isEmpty) {
                return const Center(child: Text('Không có bạn bè nào để chọn'));
              }

              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final friend = list[i];
                  final isSelected = selectedIds.contains(friend.id);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (friend.avatar?.isNotEmpty ?? false)
                          ? NetworkImage(friend.avatar!)
                          : null,
                      child: (friend.avatar?.isEmpty ?? true)
                          ? Text(friend.name.isNotEmpty
                              ? friend.name[0].toUpperCase()
                              : '?')
                          : null,
                    ),
                    title: Text(friend.name),
                    trailing: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: isSelected ? Colors.blue : Colors.grey,
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
        ],
      ),
    );
  }
}
