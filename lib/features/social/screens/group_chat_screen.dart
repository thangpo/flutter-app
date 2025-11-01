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

  final _picker = ImagePicker();

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recReady = false;
  bool _recording = false;
  bool _busyRec = false;

  bool _pagingBusy = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initRecorder();
      await context
          .read<GroupChatController>()
          .loadMessages(widget.groupId, limit: 200);
      _jumpToBottom();
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _recorder.closeRecorder();
    _textCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() async {
    if (!_scroll.hasClients || _pagingBusy) return;
    final pos = _scroll.position;
    if (pos.pixels <= pos.minScrollExtent + 64) {
      final ctrl = context.read<GroupChatController>();
      if (!ctrl.messagesLoading(widget.groupId) &&
          ctrl.hasMore(widget.groupId)) {
        _pagingBusy = true;
        final oldPixelsFromBottom = pos.maxScrollExtent - pos.pixels;
        await ctrl.loadOlder(widget.groupId, limit: 200);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scroll.hasClients) return;
          final newPixels =
              _scroll.position.maxScrollExtent - oldPixelsFromBottom;
          _scroll.jumpTo(newPixels.clamp(_scroll.position.minScrollExtent,
              _scroll.position.maxScrollExtent));
          _pagingBusy = false;
        });
      }
    }
  }

  Future<void> _ensureMicPermissions() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) throw Exception('Ứng dụng cần quyền Micro để ghi âm.');
    if (Platform.isAndroid) await Permission.storage.request();
  }

  Future<void> _initRecorder() async {
    try {
      await _ensureMicPermissions();
      await _recorder.openRecorder();
      _recReady = true;
    } catch (e) {
      _recReady = false;
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Không mở được micro: $e')));
      }
    }
  }

  Future<void> _startRec() async {
    if (_busyRec) return;
    _busyRec = true;
    if (!_recReady) {
      await _initRecorder();
      if (!_recReady) {
        _busyRec = false;
        return;
      }
    }
    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.aacMP4,
        bitRate: 128000,
        sampleRate: 44100,
      );
      setState(() => _recording = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể bắt đầu ghi âm: $e')));
      }
    } finally {
      _busyRec = false;
    }
  }

  Future<void> _stopRecAndSend() async {
    if (_busyRec) return;
    _busyRec = true;
    try {
      final path = await _recorder.stopRecorder();
      setState(() => _recording = false);
      if (path == null) return;
      await context.read<GroupChatController>().sendMessage(
            widget.groupId,
            '',
            file: File(path),
            type: 'voice',
          );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Không thể dừng/ghi âm: $e')));
      }
    } finally {
      _busyRec = false;
    }
  }

  Future<void> _toggleRec() async {
    if (_recording) {
      await _stopRecAndSend();
    } else {
      await _startRec();
    }
  }

  Future<void> _sendText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    await context.read<GroupChatController>().sendMessage(widget.groupId, text);
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final x =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    await context
        .read<GroupChatController>()
        .sendMessage(widget.groupId, '', file: File(x.path), type: 'image');
    _scrollToBottom();
  }

  Future<void> _pickVideo() async {
    final x = await _picker.pickVideo(source: ImageSource.gallery);
    if (x == null) return;
    await context
        .read<GroupChatController>()
        .sendMessage(widget.groupId, '', file: File(x.path), type: 'video');
    _scrollToBottom();
  }

  Future<void> _pickAnyFile() async {
    final r = await FilePicker.platform
        .pickFiles(withData: false, allowMultiple: false, type: FileType.any);
    if (r == null || r.files.isEmpty || r.files.single.path == null) return;
    final f = File(r.files.single.path!);
    await context
        .read<GroupChatController>()
        .sendMessage(widget.groupId, '', file: f, type: 'file');
    _scrollToBottom();
  }

  void _jumpToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GroupChatController>();
    final items = ctrl.messagesOf(widget.groupId);
    final isLoading = ctrl.messagesLoading(widget.groupId);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if ((widget.groupAvatar ?? '').isNotEmpty)
              CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(widget.groupAvatar!)),
            if ((widget.groupAvatar ?? '').isNotEmpty) const SizedBox(width: 8),
            Flexible(
                child: Text(widget.groupName ?? 'Nhóm',
                    overflow: TextOverflow.ellipsis)),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          if (_recording)
            Container(
              color: Colors.red.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.mic, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Đang ghi… nhấn lần nữa để gửi',
                      style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          Expanded(
            child: isLoading && items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => context
                        .read<GroupChatController>()
                        .loadMessages(widget.groupId, limit: 200),
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) {
                        final msg = items[i];
                        final isMe = ctrl.isMyMessage(msg);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.78),
                              child: GroupChatMessageBubble(
                                  message: msg, isMe: isMe),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              child: Row(
                children: [
                  IconButton(
                      tooltip: 'Ảnh',
                      icon: const Icon(Icons.image),
                      onPressed: _recording ? null : _pickImage),
                  IconButton(
                      tooltip: 'Video',
                      icon: const Icon(Icons.videocam),
                      onPressed: _recording ? null : _pickVideo),
                  IconButton(
                      tooltip: 'Tệp',
                      icon: const Icon(Icons.attach_file),
                      onPressed: _recording ? null : _pickAnyFile),
                  IconButton(
                    tooltip: _recording ? 'Dừng & gửi' : 'Nhấn để ghi',
                    icon: Icon(_recording ? Icons.stop_circle : Icons.mic,
                        color: _recording ? Colors.red : null),
                    onPressed: _toggleRec,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      minLines: 1,
                      maxLines: 4,
                      enabled: !_recording,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendText(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                      tooltip: 'Gửi',
                      icon: const Icon(Icons.send),
                      onPressed: _recording ? null : _sendText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
