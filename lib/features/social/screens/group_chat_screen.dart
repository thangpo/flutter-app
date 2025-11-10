// G:\flutter-app\lib\features\social\screens\group_chat_screen.dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/group_chat_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/widgets/group_chat_message_bubble.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/add_group_members_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/group_call_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/group_call_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String? groupName;
  final String? groupAvatar;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    this.groupName,
    this.groupAvatar,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _textCtrl = TextEditingController();
  final _scroll = ScrollController();

  // Pickers
  final _picker = ImagePicker();

  // Voice recorder
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recReady = false;
  bool _recording = false;
  String? _recPath;

  // Chống gửi đúp
  bool _sending = false;

  // Messenger-like UX
  bool _showScrollToBottom = false;
  int _lastItemCount = 0;

  // --- override tên & avatar để cập nhật ngay ---
  String? _titleOverride; // tên nhóm sau khi đổi
  String? _avatarOverridePath; // có thể là http(s) hoặc file path/local uri

  // Flag chống bấm gọi liên tiếp
  bool _launchingCall = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initRecorder();
      final ctrl = context.read<GroupChatController>();
      await ctrl.loadMessages(widget.groupId);
      // Thử lấy meta từ store nếu widget không có
      _hydrateFromStore();
      _scrollToBottom(immediate: true);
    });

    _scroll.addListener(() {
      // Hiện nút "xuống cuối" khi ở cách cuối danh sách > 300px
      final distanceFromBottom =
          _scroll.position.maxScrollExtent - _scroll.position.pixels;
      final show = distanceFromBottom > 300;
      if (show != _showScrollToBottom) {
        setState(() => _showScrollToBottom = show);
      }

      // Nạp tin cũ khi kéo lên gần đỉnh
      if (_scroll.position.pixels <= 100) {
        final ctrl = context.read<GroupChatController>();
        final list = ctrl.messagesOf(widget.groupId);
        if (list.isNotEmpty) {
          final first = list.first;
          final beforeId = '${first['id'] ?? ''}';
          if (beforeId.isNotEmpty) {
            ctrl.loadOlderMessages(widget.groupId, beforeId);
          }
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // mỗi lần build lại có thể groups đã có dữ liệu -> hydrate
    _hydrateFromStore();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _textCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ---------------- Recorder ----------------
  Future<void> _initRecorder() async {
    if (_recReady) return;
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return;
    await _recorder.openRecorder();
    _recReady = true;
  }

  Future<void> _toggleRecord() async {
    if (_sending) return;
    if (!_recReady) {
      await _initRecorder();
      if (!_recReady) return;
    }
    if (!_recording) {
      try {
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.startRecorder(
          toFile: path,
          codec: Codec.aacMP4,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        );
        setState(() {
          _recording = true;
          _recPath = path;
        });
      } catch (_) {}
    } else {
      try {
        final path = await _recorder.stopRecorder();
        setState(() => _recording = false);
        final realPath = path ?? _recPath;
        if (realPath == null) return;

        if (_sending) return;
        setState(() => _sending = true);
        try {
          await context.read<GroupChatController>().sendMessage(
                widget.groupId,
                '',
                file: File(realPath),
                type: 'voice',
              );
        } finally {
          if (mounted) setState(() => _sending = false);
        }
        _scrollToBottom();
      } catch (_) {
        setState(() => _recording = false);
      }
    }
  }

  // ---------------- Actions ----------------
  Future<void> _sendText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    _textCtrl.clear();
    setState(() => _sending = true);
    try {
      await context
          .read<GroupChatController>()
          .sendMessage(widget.groupId, text);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    if (_sending) return;
    final x =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;

    setState(() => _sending = true);
    try {
      await context
          .read<GroupChatController>()
          .sendMessage(widget.groupId, '', file: File(x.path), type: 'image');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    _scrollToBottom();
  }

  Future<void> _pickVideo() async {
    if (_sending) return;
    final x = await _picker.pickVideo(source: ImageSource.gallery);
    if (x == null) return;

    setState(() => _sending = true);
    try {
      await context
          .read<GroupChatController>()
          .sendMessage(widget.groupId, '', file: File(x.path), type: 'video');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    _scrollToBottom();
  }

  Future<void> _pickAnyFile() async {
    if (_sending) return;
    final r = await FilePicker.platform.pickFiles(
      withData: false,
      allowMultiple: false,
      type: FileType.any,
    );
    if (r == null || r.files.isEmpty || r.files.single.path == null) return;

    setState(() => _sending = true);
    try {
      final f = File(r.files.single.path!);
      await context
          .read<GroupChatController>()
          .sendMessage(widget.groupId, '', file: f, type: 'file');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    _scrollToBottom();
  }

  Future<void> _openAttachSheet() async {
    if (_sending) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Ảnh từ thư viện'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Video từ thư viện'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Tệp bất kỳ'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickAnyFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ====== GỌI NHÓM: xin quyền + điều hướng vào GroupCallRoom ======
  Future<void> _startGroupCall({required bool isVideo}) async {
    if (_launchingCall) return;
    _launchingCall = true;
    try {
      // mic
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Cần quyền Micro để thực hiện cuộc gọi')),
          );
        }
        return;
      }
      // camera (nếu video)
      if (isVideo) {
        final cam = await Permission.camera.request();
        if (!cam.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cần quyền Camera để gọi video')),
            );
          }
          return;
        }
      }

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GroupCallScreen(
            groupId: widget.groupId,
            mediaType: isVideo ? 'video' : 'audio',
          ),
        ),
      );


    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không mở được cuộc gọi: $e')),
        );
      }
    } finally {
      _launchingCall = false;
    }
  }

  // ---------------- Edit/Info helpers ----------------

  // Lấy meta nhóm từ store nếu widget không có
  void _hydrateFromStore() {
    final ctrl = context.read<GroupChatController>();
    final idx = ctrl.groups
        .indexWhere((g) => '${g['group_id'] ?? g['id']}' == widget.groupId);
    if (idx != -1) {
      final g = ctrl.groups[idx];
      if (_titleOverride == null &&
          (widget.groupName == null || widget.groupName!.isEmpty)) {
        _titleOverride = '${g['group_name'] ?? g['name'] ?? ''}'.trim().isEmpty
            ? null
            : '${g['group_name'] ?? g['name']}';
      }
      if (_avatarOverridePath == null &&
          (widget.groupAvatar == null || widget.groupAvatar!.isEmpty)) {
        final av = '${g['avatar'] ?? g['group_avatar'] ?? ''}'.trim();
        if (av.isNotEmpty) _avatarOverridePath = av;
      }
      if (mounted) setState(() {});
    }
  }

  String _finalTitle(GroupChatController ctrl) {
    // Ưu tiên override -> widget -> từ store
    if ((_titleOverride ?? '').isNotEmpty) return _titleOverride!;
    if ((widget.groupName ?? '').isNotEmpty) return widget.groupName!;
    final idx = ctrl.groups
        .indexWhere((g) => '${g['group_id'] ?? g['id']}' == widget.groupId);
    if (idx != -1) {
      final g = ctrl.groups[idx];
      final name = '${g['group_name'] ?? g['name'] ?? ''}'.trim();
      if (name.isNotEmpty) return name;
    }
    return 'Nhóm';
  }

  ImageProvider? _finalAvatarProvider(GroupChatController ctrl) {
    // Ưu tiên override path (có thể là file) -> widget -> store
    String? path = _avatarOverridePath;
    if ((path ?? '').isEmpty) path = widget.groupAvatar;
    if ((path ?? '').isEmpty) {
      final idx = ctrl.groups
          .indexWhere((g) => '${g['group_id'] ?? g['id']}' == widget.groupId);
      if (idx != -1) {
        path =
            '${ctrl.groups[idx]['avatar'] ?? ctrl.groups[idx]['group_avatar'] ?? ''}';
      }
    }
    if ((path ?? '').isEmpty) return null;

    final p = path!;
    if (p.startsWith('http://') || p.startsWith('https://')) {
      return NetworkImage(p);
    }
    // local: file:// hoặc absolute path
    final localPath = p.startsWith('file://') ? Uri.parse(p).toFilePath() : p;
    if (File(localPath).existsSync()) {
      return FileImage(File(localPath));
    }
    // fallback: nếu là base64 hay gì khác thì bỏ qua
    return null;
  }

  Future<void> _changeGroupName() async {
    final ctrl = context.read<GroupChatController>();
    final current = _titleOverride ?? widget.groupName ?? _finalTitle(ctrl);
    final textCtrl = TextEditingController(text: current);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi tên nhóm'),
        content: TextField(
          controller: textCtrl,
          decoration: const InputDecoration(hintText: 'Tên mới'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lưu')),
        ],
      ),
    );
    if (ok == true) {
      // Cập nhật ngay UI
      setState(() => _titleOverride = textCtrl.text.trim());
      // Gọi API
      final success = await ctrl.editGroup(
        groupId: widget.groupId,
        name: _titleOverride,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                success ? 'Đã cập nhật tên nhóm' : 'Cập nhật tên thất bại')),
      );
    }
  }

  Future<void> _pickNewAvatar() async {
    final ctrl = context.read<GroupChatController>();
    final x =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (x == null) return;

    // Hiển thị ngay ảnh local lên AppBar (trước khi upload xong)
    setState(() => _avatarOverridePath = x.path);

    // Gọi API cập nhật
    final ok = await ctrl.editGroup(
      groupId: widget.groupId,
      avatarFile: File(x.path),
    );

    if (!mounted) return;
    // Nếu server có URL mới, lần build sau _hydrateFromStore() sẽ thay thế bằng URL
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(ok ? 'Đã cập nhật ảnh nhóm' : 'Cập nhật ảnh thất bại')),
    );
  }

  Future<void> _leaveGroup() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng rời nhóm: chờ kết nối API')),
    );
  }

  Future<void> _deleteConversation() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng xoá cuộc trò chuyện: chờ API')),
    );
  }

  Future<void> _openMembersSheet() async {
    final ctrl = context.read<GroupChatController>();
    await ctrl.loadGroupMembers(widget.groupId);
    final members = ctrl.membersOf(widget.groupId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Thành viên nhóm',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: members.length,
                itemBuilder: (_, i) {
                  final m = members[i];
                  final name = '${m['name'] ?? m['username'] ?? 'Người dùng'}';
                  final avatar = '${m['avatar'] ?? ''}';
                  final id = '${m['user_id'] ?? m['id'] ?? ''}';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          avatar.isNotEmpty ? NetworkImage(avatar) : null,
                      child: avatar.isEmpty
                          ? const Icon(Icons.person, size: 20)
                          : null,
                    ),
                    title: Text(name),
                    subtitle: Text('ID: $id'),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx2) => AlertDialog(
                          title: Text('Xóa $name khỏi nhóm?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx2, false),
                                child: const Text('Hủy')),
                            ElevatedButton(
                                onPressed: () => Navigator.pop(ctx2, true),
                                child: const Text('Xóa')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final ok = await ctrl.removeUsers(widget.groupId, [id]);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(ok
                                ? 'Đã xóa $name khỏi nhóm'
                                : 'Xóa thất bại')));
                        Navigator.pop(ctx); // Đóng sheet
                        _openMembersSheet(); // Mở lại để refresh
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddMembersPicker() async {
    // bên trong GroupChatScreen, trước khi push màn add:
    final ctrl = context.read<GroupChatController>();
    await ctrl.loadGroupMembers(widget.groupId);
    final existing = ctrl.existingMemberIdsOf(widget.groupId).toSet();

    final added = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddGroupMembersScreen(
          groupId: widget.groupId,
          existingMemberIds: existing,
        ),
      ),
    );
    if (added == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm thành viên')),
      );
    }
  }

  // NEW: Dialog thêm thành viên theo danh sách userId phân tách dấu phẩy
  Future<void> _openAddMembersDialog() async {
    final ctrl = context.read<GroupChatController>();
    final textCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm thành viên'),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nhập user IDs, ví dụ: 2,3,4',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final raw = textCtrl.text.trim();
    if (raw.isEmpty) return;

    final ids = raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    if (ids.isEmpty) return;

    final success = await ctrl.addUsers(widget.groupId, ids);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              success ? 'Đã thêm thành viên' : 'Thêm thành viên thất bại')),
    );
  }

  void _openGroupInfoSheet() {
    final avatarProvider =
        _finalAvatarProvider(context.read<GroupChatController>());
    final name = _finalTitle(context.read<GroupChatController>());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top bar with menu
              Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: Center(
                      child: Text(
                        getTranslated('chat_info', context)!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (v) async {
                      switch (v) {
                        case 'change_photo':
                          await _pickNewAvatar();
                          break;
                        case 'change_name':
                          await _changeGroupName();
                          break;
                        case 'delete':
                          await _deleteConversation();
                          break;
                        case 'leave':
                          await _leaveGroup();
                          break;
                        case 'report':
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Đã ghi nhận báo cáo')),
                          );
                          break;
                        default:
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'bubble',
                        child:
                            Text(getTranslated('open_chat_bubble', context)!),
                      ),
                      PopupMenuItem(
                        value: 'change_photo',
                        child:
                            Text(getTranslated('change_group_photo', context)!),
                      ),
                      PopupMenuItem(
                        value: 'change_name',
                        child: Text(getTranslated('change_name', context)!),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                            getTranslated('delete_conversation', context)!),
                      ),
                      PopupMenuItem(
                        value: 'leave',
                        child: Text(getTranslated('leave_group', context)!),
                      ),
                      PopupMenuItem(
                        value: 'report',
                        child: Text(
                            getTranslated('report_technical_issue', context)!),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 8),

              // Avatar + name + online dot
              Stack(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundImage: avatarProvider,
                    child: avatarProvider == null
                        ? const Icon(Icons.group, size: 40)
                        : null,
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 18)),
              const SizedBox(height: 12),

              // Row actions: call / video / add / mute
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _circleAction(
                    icon: Icons.call,
                    label: getTranslated('voice_call', context)!,
                    onTap: () => _startGroupCall(isVideo: false), // ⬅️ thêm
                  ),
                  _circleAction(
                    icon: Icons.videocam,
                    label: getTranslated('video_call', context)!,
                    onTap: () => _startGroupCall(isVideo: true), // ⬅️ thêm
                  ),
                  _circleAction(
                    icon: Icons.group_add,
                    label: getTranslated('add_members', context)!,
                    onTap: _openAddMembersPicker,
                  ),
                  _circleAction(
                    icon: Icons.group,
                    label: getTranslated('members', context)!,
                    onTap: _openMembersSheet,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Hiển thị danh sách thành viên trong sheet
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 6),
                  child: Text(
                    getTranslated('group_members', context)!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              FutureBuilder(
                future: context
                    .read<GroupChatController>()
                    .loadGroupMembers(widget.groupId),
                builder: (ctx2, snapshot) {
                  final ctrl = context.read<GroupChatController>();
                  final members = ctrl.membersOf(widget.groupId);
                  // Lấy ra chủ nhóm
                  final owners =
                      members.where((m) => '${m['is_owner']}' == '1').toList();

                  if (owners.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        getTranslated('no_group_owner_found', context)!,
                      ),
                    );
                  }

                  final m = owners.first;
                  final name = '${m['name'] ?? m['username'] ?? 'Người dùng'}';
                  final avatar = '${m['avatar'] ?? ''}';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          avatar.isNotEmpty ? NetworkImage(avatar) : null,
                      child: avatar.isEmpty
                          ? const Icon(Icons.person, size: 22)
                          : null,
                    ),
                    title: Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle:
                        Text('👑 ${getTranslated('group_owner', context)!}'),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _circleAction(
      {required IconData icon, required String label, VoidCallback? onTap}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
                color: Color(0xFFF2F4F7), shape: BoxShape.circle),
            child: Icon(icon, color: Color(0xFF3C4043)),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // ---------------- Scroll helpers ----------------
  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;
      if (immediate) {
        _scroll.jumpTo(target);
      } else {
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GroupChatController>();
    final items = ctrl.messagesOf(widget.groupId);
    final isLoading = ctrl.messagesLoading(widget.groupId);

    // Auto scroll khi có tin mới:
    final distanceFromBottom = _scroll.hasClients
        ? (_scroll.position.maxScrollExtent - _scroll.position.pixels)
        : 0;
    final nearBottom = distanceFromBottom < 200;

    if (items.length != _lastItemCount) {
      if (items.length > _lastItemCount && nearBottom) {
        _scrollToBottom();
      }
      _lastItemCount = items.length;
    }

    final title = _finalTitle(ctrl);
    final avatarProvider = _finalAvatarProvider(ctrl);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: avatarProvider,
              child: avatarProvider == null
                  ? const Icon(Icons.group, size: 18)
                  : null,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(title, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Gọi thoại',
            icon: const Icon(Icons.call),
            onPressed: () => _startGroupCall(isVideo: false), // ⬅️ gọi ngay
          ),
          IconButton(
            tooltip: 'Gọi video',
            icon: const Icon(Icons.videocam),
            onPressed: () => _startGroupCall(isVideo: true), // ⬅️ gọi ngay
          ),
          IconButton(
            tooltip: 'Thông tin',
            icon: const Icon(Icons.info_outline),
            onPressed: _openGroupInfoSheet,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: isLoading && items.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: () => context
                            .read<GroupChatController>()
                            .loadMessages(widget.groupId),
                        child: ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            itemCount: items.length,
                            itemBuilder: (ctx, i) {
                              final msg = items[i];
                              final isMe = ctrl.isMyMessage(msg);
                              final isSystem = msg['is_system'] == true;

                              // 🔹 Nếu là tin nhắn hệ thống -> hiển thị đơn giản, không avatar
                              if (isSystem) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Center(
                                    child: ChatMessageBubble(
                                      key: ValueKey(
                                          '${msg['id'] ?? msg.hashCode}'),
                                      message: msg,
                                      isMe: false,
                                    ),
                                  ),
                                );
                              }

                              final userData =
                                  (msg['user_data'] ?? {}) as Map? ?? {};
                              final avatarUrl =
                                  '${userData['avatar'] ?? ''}'.trim();

                              if (!isMe) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundImage: avatarUrl.isNotEmpty
                                            ? NetworkImage(avatarUrl)
                                            : null,
                                        child: avatarUrl.isEmpty
                                            ? const Icon(Icons.person, size: 18)
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.78,
                                          ),
                                          child: ChatMessageBubble(
                                            key: ValueKey(
                                                '${msg['id'] ?? msg.hashCode}'),
                                            message: msg,
                                            isMe: false,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              // tin nhắn của chính mình
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Flexible(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.78,
                                        ),
                                        child: ChatMessageBubble(
                                          key: ValueKey(
                                              '${msg['id'] ?? msg.hashCode}'),
                                          message: msg,
                                          isMe: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            })),
              ),

              // Composer
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 6.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textCtrl,
                          enabled: !_sending,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText:
                                _sending ? 'Đang gửi...' : 'Nhập tin nhắn...',
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: IconButton(
                              icon: const Icon(Icons.attach_file),
                              onPressed: _sending ? null : _openAttachSheet,
                              tooltip: 'Đính kèm',
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _recording ? Icons.mic_off : Icons.mic,
                                color: _recording ? Colors.red : null,
                              ),
                              onPressed: _sending ? null : _toggleRecord,
                              tooltip: _recording
                                  ? 'Dừng ghi & gửi'
                                  : 'Nhấn để ghi âm / gửi',
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                  color: Colors.blue.shade200, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                  color: Colors.blue.shade400, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 8),
                          ),
                          onSubmitted: (_) => _sendText(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Gửi',
                        icon: const Icon(Icons.send),
                        onPressed: _sending ? null : _sendText,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Nút tròn trỏ xuống
          if (_showScrollToBottom)
            Positioned(
              right: 12,
              bottom: 76,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 3,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _scrollToBottom(),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.arrow_downward),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
