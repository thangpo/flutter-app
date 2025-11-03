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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initRecorder();
      final ctrl = context.read<GroupChatController>();
      await ctrl.loadMessages(widget.groupId);
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

    // Auto scroll khi có tin mới (giống Messenger):
    // nếu số lượng tăng và người dùng đang gần cuối (< 200px) thì lướt xuống
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
      body: Stack(
        children: [
          Column(
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

                            // Lấy avatar của người gửi (nếu có)
                            final userData =
                                (msg['user_data'] ?? {}) as Map? ?? {};
                            final avatarUrl =
                                '${userData['avatar'] ?? ''}'.trim();

                            // Hàng theo kiểu Messenger: avatar trái + bubble
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

                            // Tin của mình: căn phải (không avatar)
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
                          },
                        ),
                      ),
              ),

              // -------- Composer kiểu Messenger (📎 & 🎤 trong ô, ➤ bên phải) --------
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

          // -------- Nút tròn trỏ xuống (hiện khi cuộn xa đáy) --------
          if (_showScrollToBottom)
            Positioned(
              right: 12,
              bottom: 76, // nằm trên composer
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
