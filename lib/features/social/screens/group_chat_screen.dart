// G:\flutter-app\lib\features\social\screens\group_chat_screen.dart
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;


import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_chat_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';



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
  String? _avatarOverridePath; // http(s) hoặc file path/local uri

  // Flag chống bấm gọi liên tiếp
  bool _launchingCall = false;

  // NEW: chống mở nhiều dialog "cuộc gọi đến"
  bool _ringingDialogOpen = false;

  // NEW: reply preview
  Map<String, dynamic>? _replyTo;

  // NEW: realtime polling
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Không autoOpen; dùng dialog Chấp nhận/Từ chối qua onIncoming
      _bindIncomingWatcher();

      await _initRecorder();
      final ctrl = context.read<GroupChatController>();
      await ctrl.loadMessages(widget.groupId);
      // Thử lấy meta từ store nếu widget không có
      _hydrateFromStore();
      _scrollToBottom(immediate: true);

      // Bật vòng lặp realtime
      _startRealtimePolling();
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

  // Gắn watcher inbox cho group này & thiết lập onIncoming
  void _bindIncomingWatcher() {
    final gcc = context.read<GroupCallController>();
    final gchat = context.read<GroupChatController>();

    // Ngắt watcher cũ (nếu có) trước khi gắn mới
    gcc.stopWatchingInbox();

    // Không auto mở phòng; chỉ callback cho UI
    gcc.watchGroupInbox(widget.groupId, autoOpen: false);

    // Khi có cuộc gọi đến -> hiện dialog Chấp nhận / Từ chối
    gcc.onIncoming = (call) async {
      if (!mounted) return;
      if (_ringingDialogOpen) return; // tránh trùng lặp

      // Dữ liệu call từ API inbox
      final callId = (call['call_id'] ?? call['id']) is int
          ? (call['call_id'] ?? call['id']) as int
          : int.tryParse('${call['call_id'] ?? call['id'] ?? 0}') ?? 0;
      final media = (call['media'] ?? 'audio').toString();
      final joined = call['joined'] == true;

      // user hiện tại & creator
      final meId = int.tryParse('${gchat.currentUserId}') ?? 0;
      final creatorId = int.tryParse('${call['creator_id'] ?? 0}') ?? 0;

      // ⛔️ Không hiển thị dialog nếu:
      // - đã join rồi (bao gồm creator vì create() đã mark joined_at)
      // - mình chính là creator (caller)
      // - controller đang ở đúng call này (đang trên màn call)
      if (joined ||
          creatorId == meId ||
          (gcc.currentCallId != null && gcc.currentCallId == callId)) {
        return;
      }

      _ringingDialogOpen = true;
      final gName = _finalTitle(context.read<GroupChatController>());
      await Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (ctx) => _GroupIncomingCallPage(
            groupId: widget.groupId,
            groupName: gName,
            media: media,
            callId: callId,
            onDecline: () async {
              try {
                await gcc.leaveRoom(callId);
              } catch (_) {}
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            onAccept: () {
              Navigator.of(ctx).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => GroupCallScreen(
                    groupId: widget.groupId,
                    mediaType: media,
                    callId: callId,
                    groupName: gName,
                  ),
                ),
              );
            },
          ),
        ),
      );
      _ringingDialogOpen = false;
    };
  }

  // ====== REALTIME POLLING ======
  void _startRealtimePolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      try {
        await context
            .read<GroupChatController>()
            .fetchNewMessages(widget.groupId);
      } catch (_) {}
    });
  }

  void _stopRealtimePolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // mỗi lần build lại có thể groups đã có dữ liệu -> hydrate
    _hydrateFromStore();
  }

  @override
  void didUpdateWidget(covariant GroupChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      // ✅ Nếu chuyển sang group khác, gắn watcher mới (không autoOpen)
      _bindIncomingWatcher();
      _startRealtimePolling();
      setState(() {
        _replyTo = null;
      });
    }
  }

  @override
  void dispose() {
    // ✅ Dừng watcher inbox khi rời màn và bỏ callback
    final gcc = context.read<GroupCallController>();
    gcc.stopWatchingInbox();
    gcc.onIncoming = null;

    _stopRealtimePolling();

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

    final replying = _replyTo;

    _textCtrl.clear();
    setState(() => _sending = true);
    try {
      await context.read<GroupChatController>().sendMessage(
            widget.groupId,
            text,
            replyTo: replying,
          );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _replyTo = null; // gửi xong thì clear reply
        });
      }
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

  // Thu thập danh sách userId thành viên nhóm (trừ mình) để mời vào cuộc gọi
  Future<List<int>> _collectInvitees() async {
    final ids = <int>{};
    try {
      final gc = context.read<GroupChatController>();

      // đảm bảo có danh sách thành viên trước khi lấy
      try {
        await gc.loadGroupMembers(widget.groupId);
      } catch (e) {
        debugPrint('⚠️ loadGroupMembers error: $e');
      }

      final members = gc.membersOf(widget.groupId);
      final meStr = gc.currentUserId?.toString();
      final meId = meStr != null ? int.tryParse(meStr) : null;

      // 1) Lấy từ danh sách thành viên
      for (final m in members) {
        final v = m['user_id'] ?? m['id'] ?? m['uid'];
        int? id;
        if (v is int) id = v;
        if (v is String) id = int.tryParse(v);
        if (id != null && (meId == null || id != meId)) {
          ids.add(id);
        }
      }

      // 2) UNION với người từng nhắn trong nhóm
      final msgs = gc.messagesOf(widget.groupId);
      for (final msg in msgs) {
        final v = msg['from_id'] ?? msg['user_id'];
        int? id;
        if (v is int) id = v;
        if (v is String) id = int.tryParse(v);
        if (id != null && (meId == null || id != meId)) {
          ids.add(id);
        }
      }

      if (ids.isEmpty) {
        debugPrint('⚠️ _collectInvitees: không tìm thấy ai để mời.');
      }
    } catch (e) {
      debugPrint('⚠️ _collectInvitees error: $e');
    }

    final list = ids.toList()..sort();
    debugPrint('[GROUP CALL] Invitees (final) => $list');
    return list;
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

      // ✅ Thu thập invitees và truyền sang GroupCallScreen
      final invitees = await _collectInvitees();

      // 🔇 Tắt watcher để caller KHÔNG thấy dialog "tham gia"
      final gcc = context.read<GroupCallController>();
      gcc.stopWatchingInbox();

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GroupCallScreen(
            groupId: widget.groupId,
            mediaType: isVideo ? 'video' : 'audio',
            invitees: invitees, // server sẽ bắn FCM cho thành viên
            groupName: _finalTitle(context.read<GroupChatController>()),
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
      // 🔔 Bật lại watcher khi quay về màn chat
      if (mounted) _bindIncomingWatcher();
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
      setState(() => _titleOverride = textCtrl.text.trim());
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(ok ? 'Đã cập nhật ảnh nhóm' : 'Cập nhật ảnh thất bại')),
    );
  }

  Future<void> _leaveGroup() async {
    // Hỏi confirm trước
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rời nhóm'),
        content: const Text('Bạn chắc chắn muốn rời nhóm này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rời nhóm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Lấy access_token lưu trong local
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString(AppConstants.socialAccessToken) ?? '';

      if (token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Không tìm thấy access token, vui lòng đăng nhập lại')),
        );
        return;
      }

     
      final uri = Uri.parse(
        '${AppConstants.socialBaseUrl}/api/group_chat?access_token=$token',
      );

      final req = http.MultipartRequest('POST', uri)
        ..fields['server_key'] =
            AppConstants.socialServerKey // nhớ đúng key hằng số
        ..fields['type'] = 'leave'
        ..fields['id'] = widget.groupId; // ví dụ "8"

      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();

      Map<String, dynamic>? json;
      try {
        json = jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        json = null;
      }

      final success = streamed.statusCode == 200 &&
          json != null &&
          json!['api_status'] == 200;

      if (!mounted) return;

      if (success) {
        // Option: reload list group trước khi pop, nếu bố muốn
        // await context.read<GroupChatController>().loadGroups();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn đã rời nhóm thành công')),
        );

        // Thoát khỏi màn chat nhóm
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rời nhóm thất bại: ${json?['message_data'] ?? 'Vui lòng thử lại'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi rời nhóm: $e')),
      );
    }
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

  Future<void> _openGroupInfoSheet() async {
    final gc = context.read<GroupChatController>();

    // ---- Check mÃ¬nh cÃ³ pháº£i chá»§ nhÃ³m khÃ´ng ----
    bool isOwner = false;
    try {
      await gc.loadGroupMembers(widget.groupId);
      final members = gc.membersOf(widget.groupId);
      final meId = gc.currentUserId?.toString();

      isOwner = members.any((m) {
        final mIsOwner = '${m['is_owner']}' == '1';
        final uid = '${m['user_id'] ?? m['id'] ?? ''}';
        return mIsOwner && uid == meId;
      });
    } catch (_) {}

    final avatarProvider = _finalAvatarProvider(gc);
    final name = _finalTitle(gc);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DefaultTabController(
          length: 3, // áº¢nh/Video, File, Link
          child: Padding(
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
                      itemBuilder: (ctx) {
                        final items = <PopupMenuEntry<String>>[
                          
                          // Nếu là chủ nhóm thì hiện "Đổi ảnh" và "Đổi tên", nếu không thì ẩn
                          if (isOwner) ...[
                            PopupMenuItem(
                              value: 'change_photo',
                              child: Text(
                                getTranslated('change_group_photo', context)!,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'change_name',
                              child: Text(
                                getTranslated('change_name', context)!,
                              ),
                            ),
                          ],
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              getTranslated('delete_conversation', context)!,
                            ),
                          ),
                        ];

                        // 🚫 Nếu là chủ nhóm thì KHÔNG thêm menu "Rời nhóm"
                        if (!isOwner) {
                          items.add(
                            PopupMenuItem(
                              value: 'leave',
                              child: Text(
                                getTranslated('leave_group', context)!,
                              ),
                            ),
                          );
                        }

                        items.add(
                          PopupMenuItem(
                            value: 'report',
                            child: Text(
                              getTranslated('report_technical_issue', context)!,
                            ),
                          ),
                        );

                        return items;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Tiếp theo là các phần khác của group info giữ nguyên.
                // Avatar + tên nhóm + online status
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
                      onTap: () => _startGroupCall(isVideo: false),
                    ),
                    _circleAction(
                      icon: Icons.videocam,
                      label: getTranslated('video_call', context)!,
                      onTap: () => _startGroupCall(isVideo: true),
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

                // Tiêu đề "group_members" + chủ nhóm (giữ nguyên)
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
                    final owners = members
                        .where((m) => '${m['is_owner']}' == '1')
                        .toList();

                    if (owners.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          getTranslated('no_group_owner_found', context)!,
                        ),
                      );
                    }

                    final m = owners.first;
                    final name =
                        '${m['name'] ?? m['username'] ?? 'Người dùng'}';
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

                const SizedBox(height: 12),

                // ====== TAB MEDIA ======
                Align(
                  alignment: Alignment.centerLeft,
                  child: TabBar(
                    isScrollable: true,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.black54,
                    indicatorColor: Theme.of(context).primaryColor,
                    tabs: const [
                      Tab(text: 'Ảnh / Video'),
                      Tab(text: 'File'),
                      Tab(text: 'Link'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                SizedBox(
                  height: 260,
                  child: TabBarView(
                    children: [
                      _GroupMediaTab(
                        groupId: widget.groupId,
                        mediaType: 'images',
                        labelEmpty: 'Chưa có ảnh / video',
                        isFileLike: false,
                      ),
                      _GroupMediaTab(
                        groupId: widget.groupId,
                        mediaType: 'docs',
                        labelEmpty: 'Chưa có tệp nào',
                        isFileLike: true,
                      ),
                      _GroupMediaTab(
                        groupId: widget.groupId,
                        mediaType: 'links',
                        labelEmpty: 'Chưa có link nào',
                        isFileLike: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

  // ===== Long press menu (reactions + actions, Messenger-style) =====
  void _onMessageLongPress(Map<String, dynamic> message, bool isMe) {
    if (message['is_system'] == true) return;
    final idStr = '${message['id'] ?? ''}';
    if (idStr.isEmpty) return;
    final ctrl = context.read<GroupChatController>();

    final rawText =
        (message['display_text'] ?? message['text'] ?? '').toString().trim();
    final canCopy = rawText.isNotEmpty;

    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) {
        return Stack(
          children: [
            // tap nền để đóng
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(color: Colors.transparent),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16, left: 12, right: 12),
                child: Material(
                  color: Colors.white,
                  elevation: 12,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // reactions row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _reactionChip('Like', '👍', () {
                              Navigator.of(ctx).pop();
                              ctrl.reactToMessage(
                                groupId: widget.groupId,
                                messageId: idStr,
                                reactionKey: 'Like',
                              );
                            }),
                            _reactionChip('Love', '❤️', () {
                              Navigator.of(ctx).pop();
                              ctrl.reactToMessage(
                                groupId: widget.groupId,
                                messageId: idStr,
                                reactionKey: 'Love',
                              );
                            }),
                            _reactionChip('HaHa', '😂', () {
                              Navigator.of(ctx).pop();
                              ctrl.reactToMessage(
                                groupId: widget.groupId,
                                messageId: idStr,
                                reactionKey: 'HaHa',
                              );
                            }),
                            _reactionChip('Wow', '😮', () {
                              Navigator.of(ctx).pop();
                              ctrl.reactToMessage(
                                groupId: widget.groupId,
                                messageId: idStr,
                                reactionKey: 'Wow',
                              );
                            }),
                            _reactionChip('Sad', '😢', () {
                              Navigator.of(ctx).pop();
                              ctrl.reactToMessage(
                                groupId: widget.groupId,
                                messageId: idStr,
                                reactionKey: 'Sad',
                              );
                            }),
                            _reactionChip('Angry', '😡', () {
                              Navigator.of(ctx).pop();
                              ctrl.reactToMessage(
                                groupId: widget.groupId,
                                messageId: idStr,
                                reactionKey: 'Angry',
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 6),
                        // actions row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _actionButton(
                              icon: Icons.reply,
                              label: 'Trả lời',
                              onTap: () {
                                Navigator.of(ctx).pop();
                                setState(() {
                                  _replyTo = message;
                                });
                              },
                            ),
                            if (canCopy)
                              _actionButton(
                                icon: Icons.content_copy,
                                label: 'Sao chép',
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  Clipboard.setData(
                                      ClipboardData(text: rawText));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Đã sao chép')),
                                  );
                                },
                              ),
                            _actionButton(
                              icon: Icons.delete_outline,
                              label: 'Xoá',
                              destructive: true,
                              onTap: isMe
                                  ? () {
                                      Navigator.of(ctx).pop();
                                      // TODO: nối API xoá message group
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Tính năng xoá tin nhắn: chờ kết nối API')),
                                      );
                                    }
                                  : null,
                            ),
                            _actionButton(
                              icon: Icons.forward,
                              label: 'Chuyển tiếp',
                              onTap: () {
                                Navigator.of(ctx).pop();
                                // TODO: nối API forward group chat
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Tính năng chuyển tiếp: chờ kết nối API server'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _reactionChip(String label, String emoji, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 26),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool destructive = false,
  }) {
    final bool disabled = onTap == null;
    Color color;
    if (disabled) {
      color = Colors.grey;
    } else if (destructive) {
      color = Colors.red;
    } else {
      color = Colors.black87;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- REPLY HELPERS (giống 1-1) ----------

  String _plainTextOf(Map<String, dynamic> m) {
    final display = (m['display_text'] ?? '').toString();
    if (display.isNotEmpty) return display.trim();
    return (m['text'] ?? '').toString().trim();
  }

  bool _hasReplyTag(Map<String, dynamic> m) {
    final v = m['reply_id'] ?? m['reply_to_id'] ?? (m['reply']?['id']);
    if (v == null) return false;
    final s = v.toString();
    return s.isNotEmpty && s != '0';
  }

  Map<String, dynamic>? _findRepliedMessage(
      Map<String, dynamic> m, List<Map<String, dynamic>> all) {
    final r = m['reply'];
    if (r is Map<String, dynamic>) {
      return r;
    }
    final id = '${m['reply_id'] ?? m['reply_to_id'] ?? ''}';
    if (id.isEmpty || id == '0') return null;

    for (final msg in all) {
      final mid = '${msg['id'] ?? msg['message_id'] ?? msg['msg_id'] ?? ''}';
      if (mid == id) return msg;
    }
    return null;
  }

  Widget _buildReplyHeader({
    required Map<String, dynamic> message,
    Map<String, dynamic>? replyMsg,
    required bool isMe,
  }) {
    final gchat = context.read<GroupChatController>();
    final meId = gchat.currentUserId?.toString();

    final userData =
        (message['user_data'] ?? {}) as Map<Object?, Object?>? ?? {};
    final senderName = (userData['name'] ??
            userData['username'] ??
            message['from_name'] ??
            message['from_id'] ??
            '')
        .toString()
        .trim();

    String replyUserId = '';
    String repliedName = '';
    if (replyMsg != null) {
      final rUser =
          (replyMsg['user_data'] ?? {}) as Map<Object?, Object?>? ?? {};
      replyUserId =
          (rUser['user_id'] ?? replyMsg['user_id'] ?? replyMsg['from_id'] ?? '')
              .toString();
      repliedName = (rUser['name'] ??
              rUser['username'] ??
              replyMsg['from_name'] ??
              replyMsg['from_id'] ??
              '')
          .toString()
          .trim();
    }

    final fromId =
        (userData['user_id'] ?? message['user_id'] ?? message['from_id'] ?? '')
            .toString();

    final senderIsMe = isMe;
    final repliedIsMe =
        replyUserId.isNotEmpty && meId != null && replyUserId == meId;
    final selfReply =
        replyUserId.isNotEmpty && fromId.isNotEmpty && replyUserId == fromId;

    String text;
    if (senderIsMe && selfReply) {
      text = 'Bạn đã trả lời tin nhắn của chính mình';
    } else if (senderIsMe && !repliedIsMe && repliedName.isNotEmpty) {
      text = 'Bạn đã trả lời $repliedName';
    } else if (!senderIsMe && repliedIsMe) {
      final name = senderName.isNotEmpty ? senderName : 'Người kia';
      text = '$name đã trả lời bạn';
    } else if (!senderIsMe && selfReply) {
      final name = senderName.isNotEmpty ? senderName : 'Người kia';
      text = '$name đã trả lời tin nhắn của chính mình';
    } else if (!senderIsMe && repliedName.isNotEmpty) {
      final name = senderName.isNotEmpty ? senderName : 'Người kia';
      text = '$name đã trả lời $repliedName';
    } else {
      final name = senderName.isNotEmpty ? senderName : 'Người kia';
      text = '$name đã trả lời một tin nhắn';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.reply, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyQuote(
    Map<String, dynamic> replyMsg, {
    required bool isMe,
  }) {
    final text = _plainTextOf(replyMsg);
    final bgColor = Colors.grey.shade200;
    final maxWidth = MediaQuery.of(context).size.width * 0.6;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text.isEmpty ? '(Tin nhắn)' : text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    final msg = _replyTo!;
    final text = _plainTextOf(msg);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              text.isEmpty ? '(Tin nhắn)' : text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              setState(() => _replyTo = null);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGroupEmptyState({
    required ImageProvider? avatarProvider,
    required String title,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundImage: avatarProvider,
                  backgroundColor: Colors.grey.shade300,
                  child: avatarProvider == null
                      ? const Icon(Icons.group, size: 46, color: Colors.white70)
                      : null,
                ),
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(bottom: 4, right: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ban da tao nhom nay',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _EmptyActionButton(
                  icon: Icons.person_add_alt,
                  label: 'Them',
                  onTap: _openAddMembersPicker,
                ),
                const SizedBox(width: 12),
                _EmptyActionButton(
                  icon: Icons.edit,
                  label: 'Ten',
                  onTap: _changeGroupName,
                ),
                const SizedBox(width: 12),
                _EmptyActionButton(
                  icon: Icons.group_outlined,
                  label: 'Thanh vien',
                  onTap: _openMembersSheet,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Ban da dat ten nhom la $title.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
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
            onPressed: () => _startGroupCall(isVideo: false),
          ),
          IconButton(
            tooltip: 'Gọi video',
            icon: const Icon(Icons.videocam),
            onPressed: () => _startGroupCall(isVideo: true),
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
                        child: items.isEmpty
                            ? LayoutBuilder(
                                builder: (context, constraints) {
                                  return SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                          minHeight: constraints.maxHeight),
                                      child: _buildGroupEmptyState(
                                        avatarProvider: avatarProvider,
                                        title: title,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: items.length,
                          itemBuilder: (ctx, i) {
                            final msg = items[i];
                            final isMe = ctrl.isMyMessage(msg);
                            final isSystem = msg['is_system'] == true;

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

                            final hasReply = _hasReplyTag(msg);
                            final replyMsg = hasReply
                                ? _findRepliedMessage(msg, items)
                                : null;

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
                                        child: _SwipeReplyWrapper(
                                          isMe: false,
                                          onReply: () {
                                            setState(() {
                                              _replyTo = msg;
                                            });
                                          },
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onLongPress: () =>
                                                _onMessageLongPress(msg, isMe),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (hasReply)
                                                  _buildReplyHeader(
                                                    message: msg,
                                                    replyMsg: replyMsg,
                                                    isMe: false,
                                                  ),
                                                if (replyMsg != null)
                                                  _buildReplyQuote(
                                                    replyMsg,
                                                    isMe: false,
                                                  ),
                                                ChatMessageBubble(
                                                  key: ValueKey(
                                                      '${msg['id'] ?? msg.hashCode}'),
                                                  message: msg,
                                                  isMe: false,
                                                ),
                                              ],
                                            ),
                                          ),
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
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.78,
                                      ),
                                      child: _SwipeReplyWrapper(
                                        isMe: true,
                                        onReply: () {
                                          setState(() {
                                            _replyTo = msg;
                                          });
                                        },
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onLongPress: () =>
                                              _onMessageLongPress(msg, isMe),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              if (hasReply)
                                                _buildReplyHeader(
                                                  message: msg,
                                                  replyMsg: replyMsg,
                                                  isMe: true,
                                                ),
                                              if (replyMsg != null)
                                                _buildReplyQuote(
                                                  replyMsg,
                                                  isMe: true,
                                                ),
                                              ChatMessageBubble(
                                                key: ValueKey(
                                                    '${msg['id'] ?? msg.hashCode}'),
                                                message: msg,
                                                isMe: true,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),

              // Composer
              SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_replyTo != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 0.0),
                        child: _buildReplyPreview(),
                      ),
                    Padding(
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
                                hintText: _sending
                                    ? 'Đang gửi...'
                                    : 'Nhập tin nhắn...',
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
                  ],
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

// ================== SWIPE REPLY WRAPPER ==================

class _SwipeReplyWrapper extends StatefulWidget {
  final Widget child;
  final bool isMe;
  final VoidCallback onReply;

  const _SwipeReplyWrapper({
    required this.child,
    required this.isMe,
    required this.onReply,
  });

  @override
  State<_SwipeReplyWrapper> createState() => _SwipeReplyWrapperState();
}

class _SwipeReplyWrapperState extends State<_SwipeReplyWrapper> {
  double _dragDx = 0;
  static const double _maxShift = 80; // kéo tối đa ~80px

  @override
  Widget build(BuildContext context) {
    // Giới hạn theo hướng cho phép
    double effectiveDx;
    if (widget.isMe) {
      // mình: chỉ cho kéo sang trái (âm)
      effectiveDx = _dragDx.clamp(-_maxShift, 0);
    } else {
      // người khác: chỉ cho kéo sang phải (dương)
      effectiveDx = _dragDx.clamp(0, _maxShift);
    }

    final progress =
        (effectiveDx.abs() / _maxShift).clamp(0.0, 1.0); // 0 -> 1 cho icon

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragDx += details.delta.dx;
        });
      },
      onHorizontalDragEnd: (_) {
        final threshold =
            _maxShift * 0.6; // phải kéo > ~60% maxShift mới trigger

        bool trigger = false;
        if (widget.isMe) {
          trigger = effectiveDx <= -threshold;
        } else {
          trigger = effectiveDx >= threshold;
        }

        if (trigger) {
          widget.onReply();
        }

        setState(() {
          _dragDx = 0; // snap bubble về chỗ cũ
        });
      },
      onHorizontalDragCancel: () {
        setState(() {
          _dragDx = 0;
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Icon reply nằm ở phía “kéo ra”
          Positioned(
            left: widget.isMe ? null : 0,
            right: widget.isMe ? 0 : null,
            child: Opacity(
              opacity: progress,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.0),
                child: Icon(
                  Icons.reply,
                  size: 18,
                  color: Colors.blueGrey,
                ),
              ),
            ),
          ),
          // Bubble dịch chuyển theo tay
          Transform.translate(
            offset: Offset(effectiveDx, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }



  
}


class _GroupMediaTab extends StatefulWidget {
  final String groupId;
  final String mediaType; // images | videos | audio | links | docs
  final String labelEmpty;
  final bool isFileLike; // true = ListTile (file/link), false = grid

  const _GroupMediaTab({
    required this.groupId,
    required this.mediaType,
    required this.labelEmpty,
    required this.isFileLike,
  });

  @override
  State<_GroupMediaTab> createState() => _GroupMediaTabState();
}

class _GroupMediaTabState extends State<_GroupMediaTab> {
  final SocialChatRepository _repo = SocialChatRepository();

  bool _loading = false;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ============= LOAD DATA =============

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _items = [];
    });

    try {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString(AppConstants.socialAccessToken) ?? '';
      if (token.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final List<String> types;
      if (widget.mediaType == 'images') {
        // Tab 1: Ảnh / Video
        types = ['images', 'videos'];
      } else if (widget.mediaType == 'docs') {
        // Tab 2: File -> gộp cả docs + audio (voice, nhạc...)
        types = ['docs', 'audio'];
      } else {
        // Tab 3: links (hoặc loại khác nếu sau này thêm)
        types = [widget.mediaType];
      }

      final List<Map<String, dynamic>> fetched = [];
      for (final t in types) {
        final list = await _repo.getChatMedia(
          token: token,
          groupId: widget.groupId,
          mediaType: t,
          limit: 50,
          offset: 0,
        );
        fetched.addAll(list);
      }

      // Dedupe theo (id + media_url)
      final seen = <String>{};
      final result = <Map<String, dynamic>>[];

      for (final raw in fetched) {
        final m = Map<String, dynamic>.from(raw);
        final id = '${m['id'] ?? m['message_id'] ?? ''}';
        final mediaUrl = _getMediaUrl(m);
        final key = '$id|$mediaUrl';
        if (key.trim().isEmpty) continue;
        if (seen.add(key)) {
          result.add(m);
        }
      }


      if (!mounted) return;
      setState(() {
        _items = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _items = [];
      });
    }
  }

  // ============= HELPERS =============

  String _string(dynamic v) => v?.toString() ?? '';

  /// URL media chính (đã được SocialChatRepository hydrate sẵn)
  String _getMediaUrl(Map<String, dynamic> m) {
    final v = _string(m['media_url']);
    if (v.isNotEmpty) return v;
    return _string(m['media']);
  }

  String _resolveUrl(String? raw) {
    if (raw == null) return '';
    var url = raw.trim();
    if (url.isEmpty) return '';

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    final base = AppConstants.socialBaseUrl;
    if (url.startsWith('/')) {
      return '$base$url';
    }
    return '$base/$url';
  }

  String _getKind(Map<String, dynamic> m) {
    return _string(m['type'] ?? m['media_type'] ?? m['file_type'])
        .toLowerCase();
  }

  String _getFileName(Map<String, dynamic> m) {
    final cands = [
      'file_name',
      'filename',
      'name',
      'title',
      'text',
    ];
    for (final k in cands) {
      final v = _string(m[k]);
      if (v.isNotEmpty) return v;
    }
    final url = _getMediaUrl(m);
    if (url.isNotEmpty) {
      final path = url.split('?').first;
      final segs = path.split('/');
      if (segs.isNotEmpty) return segs.last;
    }
    return 'File';
  }

  String _extFrom(Map<String, dynamic> m) {
    final url = _getMediaUrl(m);
    final name = url.isNotEmpty ? url : _getFileName(m);
    final path = name.split('?').first;
    final dot = path.lastIndexOf('.');
    if (dot != -1 && dot != path.length - 1) {
      return path.substring(dot + 1).toLowerCase();
    }
    return '';
  }

  // Theo list bố đưa
  bool _isImageExt(String ext) =>
      ['jpg', 'jpeg', 'png', 'gif'].contains(ext);

  bool _isVideoExt(String ext) =>
      ['mkv', 'mp4', 'flv', 'mov', 'avi', 'webm', 'mpeg'].contains(ext);

  bool _isAudioExt(String ext) =>
      ['mp3', 'm4a', 'aac', 'ogg', 'wav'].contains(ext);

  IconData _fileIcon(String ext, Map<String, dynamic> m) {
    final kind = _getKind(m);

    if (_isImageExt(ext) ||
        kind == 'image' ||
        kind == 'photo' ||
        kind == 'photos' ||
        m['is_image'] == true) {
      return Icons.image;
    }
    if (_isVideoExt(ext) || kind == 'video' || m['is_video'] == true) {
      return Icons.movie;
    }
    if (_isAudioExt(ext) ||
        kind == 'audio' ||
        kind == 'sound' ||
        m['is_audio'] == true) {
      return Icons.audiotrack;
    }

    if (ext == 'apk') return Icons.android;
    if (ext == 'pdf') return Icons.picture_as_pdf;
    if (['doc', 'docx', 'txt'].contains(ext)) return Icons.description;
    if (['zip', 'rar'].contains(ext)) return Icons.archive;

    return Icons.insert_drive_file;
  }

  String _formatUnix(String s) {
    final n = int.tryParse(s);
    if (n == null) return s;
    final dt =
        DateTime.fromMillisecondsSinceEpoch(n * 1000, isUtc: true).toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year}  ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _getTimeText(Map<String, dynamic> m) {
    final v = _string(m['time_text'] ?? m['date'] ?? m['time']);
    if (v.isEmpty) return '';
    if (RegExp(r'^\d{9,}$').hasMatch(v)) {
      return _formatUnix(v);
    }
    return v;
  }

  String _getFileSize(Map<String, dynamic> m) {
    final raw = _string(
      m['file_size'] ?? m['size'] ?? m['file_size_formatted'],
    );
    if (raw.isEmpty) return '';
    // nếu server đã format sẵn thì trả luôn
    if (raw.contains('KB') || raw.contains('MB') || raw.contains('GB')) {
      return raw;
    }
    final n = double.tryParse(raw);
    if (n == null) return '';
    double bytes = n;
    if (bytes < 1024) return '${bytes.toStringAsFixed(0)} B';
    double kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    double mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    double gb = mb / 1024;
    return '${gb.toStringAsFixed(1)} GB';
  }

  Map<String, String> _parseHtmlLink(String text) {
    final result = <String, String>{'url': '', 'label': ''};
    if (text.isEmpty) return result;

    final hrefRe = RegExp(r'href="([^"]+)"', caseSensitive: false);
    final labelRe = RegExp(r'>([^<]+)<\/a>', caseSensitive: false);

    final hrefMatch = hrefRe.firstMatch(text);
    final labelMatch = labelRe.firstMatch(text);

    if (hrefMatch != null) {
      result['url'] = hrefMatch.group(1) ?? '';
    }
    if (labelMatch != null) {
      result['label'] = labelMatch.group(1) ?? '';
    }

    if (result['url']!.isEmpty) {
      final urlRe = RegExp(r'https?:\/\/\S+');
      final m = urlRe.firstMatch(text);
      if (m != null) result['url'] = m.group(0) ?? '';
    }
    if (result['label']!.isEmpty && result['url']!.isNotEmpty) {
      result['label'] = result['url']!;
    }
    return result;
  }

  String _getHost(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    return uri.host;
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ============= BUILD =============

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          widget.labelEmpty,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    // ---------- TAB 1: ẢNH / VIDEO (GRID) ----------
    if (!widget.isFileLike) {
      return GridView.builder(
        padding: const EdgeInsets.only(top: 4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _items.length,
        itemBuilder: (ctx, i) {
          final m = _items[i];
          final url = _resolveUrl(_getMediaUrl(m));
          final ext = _extFrom(m);
          final kind = _getKind(m);

          final isImage = m['is_image'] == true ||
              _isImageExt(ext) ||
              kind == 'image' ||
              kind == 'photo' ||
              kind == 'photos';

          final isVideo =
              m['is_video'] == true || _isVideoExt(ext) || kind == 'video';

          if (url.isEmpty) {
            return Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.image_not_supported),
            );
          }

          return GestureDetector(
            onTap: () {
              if (isImage) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _FullScreenImagePage(url: url),
                  ),
                );
              } else if (isVideo) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _FullScreenVideoPage(url: url),
                  ),
                );
              } else {
                _openUrl(url);
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isImage)
                    Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: Colors.grey.shade300,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.play_circle_fill,
                        size: 36,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    }

    // ---------- TAB 3: LINK ----------
    if (widget.mediaType == 'links') {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _items.length,
        itemBuilder: (ctx, i) {
          final m = _items[i];

          final rawTitle = _string(m['title'] ?? m['text'] ?? '');
          final rawUrlField =
              _string(m['link'] ?? m['url'] ?? m['full'] ?? m['file']);

          String url = '';
          String title = '';

          if (rawUrlField.isNotEmpty) {
            url = _resolveUrl(rawUrlField);
            title = rawTitle.isNotEmpty ? rawTitle : url;
          } else {
            final parsed = _parseHtmlLink(rawTitle);
            url = _resolveUrl(parsed['url'] ?? '');
            title = parsed['label'] ?? '';
          }

          final host = _getHost(url);
          final subtitle = host.isNotEmpty ? host : url;

          return ListTile(
            dense: true,
            leading: const Icon(Icons.link),
            title: Text(
              title.isNotEmpty ? title : '(link)',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: subtitle.isNotEmpty
                ? Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  )
                : null,
            onTap: url.isNotEmpty ? () => _openUrl(url) : null,
          );
        },
      );
    }

    // ---------- TAB 2: FILE ----------
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _items.length,
      itemBuilder: (ctx, i) {
        final m = _items[i];
        final rawUrl = _getMediaUrl(m);
        final url = _resolveUrl(rawUrl);

        final name = _getFileName(m);
        final ext = _extFrom(m);
        final size = _getFileSize(m);
        final time = _getTimeText(m);
        final icon = _fileIcon(ext, m);

        final subtitleParts = <String>[];
        if (size.isNotEmpty) subtitleParts.add(size);
        if (time.isNotEmpty) subtitleParts.add(time);
        final subtitle = subtitleParts.join(' · ');

        return ListTile(
          dense: true,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 22,
              color: Colors.grey.shade800,
            ),
          ),
          title: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: subtitle.isNotEmpty
              ? Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                )
              : null,
          onTap: url.isNotEmpty ? () => _openUrl(url) : null,
        );
      },
    );
  }
}

class _EmptyActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _EmptyActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}


class _FullScreenImagePage extends StatelessWidget {
  final String url;

  const _FullScreenImagePage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Ảnh',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(url),
        ),
      ),
    );
  }
}

class _FullScreenVideoPage extends StatefulWidget {
  final String url;

  const _FullScreenVideoPage({required this.url});

  @override
  State<_FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<_FullScreenVideoPage> {
  late VideoPlayerController _controller;
  bool _initing = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _initing = false;
      });
      _controller.play();
    }).catchError((e) {
      debugPrint('video init error: $e');
      if (!mounted) return;
      setState(() {
        _initing = false;
        _error = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_controller.value.isInitialized) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying =
        _controller.value.isInitialized && _controller.value.isPlaying;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Video',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: _initing
            ? const CircularProgressIndicator(color: Colors.white)
            : _error || !_controller.value.isInitialized
                ? const Text(
                    'Không phát được video',
                    style: TextStyle(color: Colors.white),
                  )
                : Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                      Positioned(
                        bottom: 32,
                        child: IconButton(
                          iconSize: 48,
                          color: Colors.white,
                          icon: Icon(
                            isPlaying ? Icons.pause_circle : Icons.play_circle,
                          ),
                          onPressed: _togglePlay,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

/// Fullscreen incoming UI cho cuộc gọi nhóm (nhận / từ chối)
class _GroupIncomingCallPage extends StatelessWidget {
  final String groupId;
  final String groupName;
  final String media;
  final int callId;
  final VoidCallback onAccept;
  final Future<void> Function() onDecline;

  const _GroupIncomingCallPage({
    required this.groupId,
    required this.groupName,
    required this.media,
    required this.callId,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = media == 'video';
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
                    isVideo ? 'Cuộc gọi nhóm video' : 'Cuộc gọi nhóm thoại',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    groupName.isNotEmpty ? groupName : 'Nhóm $groupId',
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
                    label: 'Từ chối',
                    color: Colors.redAccent,
                    icon: Icons.call_end,
                    onTap: () async {
                      await onDecline();
                    },
                  ),
                  _IncomingButton(
                    label: 'Nghe',
                    color: Colors.green,
                    icon: isVideo ? Icons.videocam : Icons.call,
                    onTap: onAccept,
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
