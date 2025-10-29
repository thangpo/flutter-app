import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/group_chat_controller.dart';

class CreateGroupScreen extends StatefulWidget {
  final String accessToken;
  final List<String>? selectedMemberIds;

  const CreateGroupScreen({
    super.key,
    required this.accessToken,
    this.selectedMemberIds,
  });

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameCtrl = TextEditingController();
  final _idsCtrl = TextEditingController();
  File? _avatarFile;

  @override
  void initState() {
    super.initState();
    // Gán danh sách ID thành viên nếu có từ FriendsListScreen
    if (widget.selectedMemberIds != null &&
        widget.selectedMemberIds!.isNotEmpty) {
      _idsCtrl.text = widget.selectedMemberIds!.join(',');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GroupChatController>();
    final isCreating = ctrl.creatingGroup;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo nhóm chat'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tên nhóm',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  hintText: 'VD: Team Dev, Bạn thân...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 20),
              const Text('ID thành viên (phân tách dấu phẩy)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              TextField(
                controller: _idsCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'VD: 319,343,341',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Ảnh nhóm (tùy chọn)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: isCreating
                        ? null
                        : () async {
                            final picked = await FilePicker.platform.pickFiles(
                              allowMultiple: false,
                              type: FileType.image,
                            );
                            if (picked != null &&
                                picked.files.single.path != null) {
                              setState(() {
                                _avatarFile = File(picked.files.single.path!);
                              });
                            }
                          },
                    icon: const Icon(Icons.image),
                    label: const Text('Chọn ảnh'),
                  ),
                  const SizedBox(width: 12),
                  if (_avatarFile != null)
                    CircleAvatar(
                      radius: 26,
                      backgroundImage: FileImage(_avatarFile!),
                    ),
                ],
              ),
              const SizedBox(height: 30),

              // 🟢 Nút tạo nhóm
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isCreating ? null : _createGroup,
                  icon: isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    isCreating ? 'Đang tạo nhóm...' : 'Tạo nhóm',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              if (ctrl.lastError != null)
                Text(
                  ctrl.lastError!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createGroup() async {
    final name = _nameCtrl.text.trim();
    final idsRaw = _idsCtrl.text.trim();

    if (name.isEmpty || idsRaw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập tên nhóm và ID thành viên')),
      );
      return;
    }

    final ids = idsRaw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final ctrl = context.read<GroupChatController>();
    final success = await ctrl.createGroup(
      accessToken: widget.accessToken,
      name: name,
      memberIds: ids,
      avatarFile: _avatarFile,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo nhóm thành công!')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tạo nhóm!')),
      );
    }
  }
}
