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

  // Pickers
  final _picker = ImagePicker();

  // Voice recorder (tap to start, tap again to stop & send)
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recReady = false;
  bool _recording = false;
  String? _recPath; // last recording temp path

  @override
  void initState() {
    super.initState();
    // Load messages when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initRecorder();
      final ctrl = context.read<GroupChatController>();
      await ctrl.loadMessages(widget.groupId);
      _jumpToBottom();
    });

    // infinite scroll (pull older when reaching top ~ 100px)
    _scroll.addListener(() async {
      if (_scroll.position.pixels <= 100) {
        final ctrl = context.read<GroupChatController>();
        // fetch older only if there is at least one message
        final list = ctrl.messagesOf(widget.groupId);
        if (list.isNotEmpty) {
          final first = list.first;
          final beforeId = '${first['id'] ?? ''}';
          if (beforeId.isNotEmpty) {
            await ctrl.loadOlderMessages(widget.groupId, beforeId);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _textCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ----------------------- Recorder helpers -----------------------

  Future<void> _initRecorder() async {
    if (_recReady) return;
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return;
    await _recorder.openRecorder();
    _recReady = true;
  }

  Future<void> _toggleRecord() async {
    if (!_recReady) {
      await _initRecorder();
      if (!_recReady) return;
    }
    if (!_recording) {
      // start
      try {
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.startRecorder(
          toFile: path,
          codec: Codec.aacMP4, // .m4a (AAC)
          bitRate: 128000,
          sampleRate: 44100,
        );
        setState(() {
          _recording = true;
          _recPath = path;
        });
      } catch (_) {}
    } else {
      // stop & send
      try {
        final path = await _recorder.stopRecorder();
        setState(() => _recording = false);
        final realPath = path ?? _recPath;
        if (realPath == null) return;
        await context.read<GroupChatController>().sendMessage(
              widget.groupId,
              '',
              file: File(realPath),
              type: 'voice',
            );
        _scrollToBottom();
      } catch (_) {
        setState(() => _recording = false);
      }
    }
  }

  // ----------------------- Actions -----------------------

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
    final r = await FilePicker.platform.pickFiles(
      withData: false,
      allowMultiple: false,
      type: FileType.any,
    );
    if (r == null || r.files.isEmpty || r.files.single.path == null) return;
    final f = File(r.files.single.path!);
    await context
        .read<GroupChatController>()
        .sendMessage(widget.groupId, '', file: f, type: 'file');
    _scrollToBottom();
  }

  // ----------------------- Scroll helpers -----------------------

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

  // ----------------------- UI -----------------------

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
                backgroundImage: NetworkImage(widget.groupAvatar!),
              ),
            if ((widget.groupAvatar ?? '').isNotEmpty) const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.groupName ?? 'Nhóm',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading && items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () =>
                        context.read<GroupChatController>().loadMessages(
                              widget.groupId,
                            ),
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
                                    MediaQuery.of(context).size.width * 0.78,
                              ),
                              child: ChatMessageBubble(
                                message: msg,
                                isMe: isMe,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),

          // Composer
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
                    onPressed: _pickImage,
                  ),
                  IconButton(
                    tooltip: 'Video',
                    icon: const Icon(Icons.videocam),
                    onPressed: _pickVideo,
                  ),
                  IconButton(
                    tooltip: 'Tệp',
                    icon: const Icon(Icons.attach_file),
                    onPressed: _pickAnyFile,
                  ),
                  IconButton(
                    tooltip:
                        _recording ? 'Dừng ghi & gửi' : 'Nhấn để ghi âm / gửi',
                    icon: Icon(
                      _recording ? Icons.mic_off : Icons.mic,
                      color: _recording ? Colors.red : null,
                    ),
                    onPressed: _toggleRecord,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      minLines: 1,
                      maxLines: 4,
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
                    onPressed: _sendText,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
