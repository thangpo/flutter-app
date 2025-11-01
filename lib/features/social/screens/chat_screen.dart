import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/widgets/chat_message_bubble.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_chat_repository.dart';

class ChatScreen extends StatefulWidget {
  final String accessToken;
  final String peerUserId; // id người nhận
  final String? peerName;
  final String? peerAvatar;

  const ChatScreen({
    super.key,
    required this.accessToken,
    required this.peerUserId,
    this.peerName,
    this.peerAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final repo = SocialChatRepository();

  final _inputCtrl = TextEditingController();
  final _scroll = ScrollController();

  bool _loading = false;
  bool _sending = false;
  bool _hasMore = true;
  String? _beforeId;
  List<Map<String, dynamic>> _messages = [];

  // ===== Recorder =====
  final _recorder = FlutterSoundRecorder();
  bool _recReady = false;
  bool _recOn = false;
  String? _recPath;

  late final String _peerId;

  @override
  void initState() {
    super.initState();
    _peerId = widget.peerUserId;
    _initRecorder();
    _loadInit();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scroll.dispose();
    if (_recOn) _recorder.stopRecorder();
    _recorder.closeRecorder();
    super.dispose();
  }

  // ===== utils =====
  int _msgId(Map<String, dynamic> m) =>
      int.tryParse('${m['id'] ?? m['message_id'] ?? m['msg_id'] ?? ''}') ?? 0;

  String _msgIdStr(Map<String, dynamic> m) =>
      '${m['id'] ?? m['message_id'] ?? m['msg_id'] ?? ''}';

  void _sortAscById(List<Map<String, dynamic>> list) {
    list.sort((a, b) => _msgId(a).compareTo(_msgId(b)));
  }

  void _mergeIncoming(List<Map<String, dynamic>> incoming,
      {required bool toTail}) {
    if (incoming.isEmpty) return;
    _sortAscById(incoming);

    if (_messages.isEmpty) {
      _messages = [...incoming];
      return;
    }

    final exist = _messages.map(_msgIdStr).toSet();
    final filtered = incoming.where((m) {
      final id = _msgIdStr(m);
      return id.isNotEmpty && !exist.contains(id);
    }).toList();

    if (filtered.isEmpty) return;

    if (toTail) {
      _messages.addAll(filtered);
    } else {
      _messages.insertAll(0, filtered);
    }
    _sortAscById(_messages);
  }

  // ===== recorder =====
  Future<void> _initRecorder() async {
    final micOk = await _ensureMic();
    if (!micOk) return;

    await _recorder.openRecorder();
    await _recorder.setSubscriptionDuration(const Duration(milliseconds: 100));
    _recReady = true;
    setState(() {});
  }

  Future<bool> _ensureMic() async {
    final st = await Permission.microphone.status;
    if (st.isGranted) return true;
    final rs = await Permission.microphone.request();
    return rs.isGranted;
  }

  // ===== data =====
  Future<void> _loadInit() async {
    await _fetchNew();
    await repo.readChats(token: widget.accessToken, peerUserId: _peerId);
  }

  Future<void> _fetchNew() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final list = await repo.getUserMessages(
        token: widget.accessToken,
        peerUserId: _peerId,
        limit: 30,
      );
      _sortAscById(list);
      _messages = list;
      if (list.isNotEmpty) _beforeId = _msgIdStr(list.first);
      _hasMore = list.length >= 30;
      setState(() {});
      _jumpToBottom();
    } catch (e) {
      debugPrint('load messages error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchOlder() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    final oldMax = _scroll.hasClients ? _scroll.position.maxScrollExtent : 0.0;

    try {
      final older = await repo.getUserMessages(
        token: widget.accessToken,
        peerUserId: _peerId,
        limit: 30,
        beforeMessageId: _beforeId,
      );
      if (older.isNotEmpty) {
        _sortAscById(older);
        _beforeId = _msgIdStr(older.first);
        _mergeIncoming(older, toTail: false);

        if (_scroll.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final newMax = _scroll.position.maxScrollExtent;
            final delta = newMax - oldMax;
            final want = _scroll.position.pixels + delta;
            _scroll.jumpTo(want.clamp(
              _scroll.position.minScrollExtent,
              _scroll.position.maxScrollExtent,
            ));
          });
        }
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('load older error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendText() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final sent = await repo.sendMessage(
        token: widget.accessToken,
        peerUserId: _peerId,
        text: text,
      );
      _inputCtrl.clear();
      if (sent != null) {
        _mergeIncoming([sent], toTail: true);
        setState(() {});
        _jumpToBottom();
      }
    } catch (e) {
      debugPrint('send text error: $e');
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendFile() async {
    if (_sending) return;
    final res = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (res == null || res.files.isEmpty) return;
    final path = res.files.single.path;
    if (path == null) return;

    setState(() => _sending = true);
    try {
      final sent = await repo.sendMessage(
        token: widget.accessToken,
        peerUserId: _peerId,
        filePath: path,
      );
      if (sent != null) {
        _mergeIncoming([sent], toTail: true);
        setState(() {});
        _jumpToBottom();
      }
    } catch (e) {
      debugPrint('send file error: $e');
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _toggleRecord() async {
    if (!_recReady) {
      await _initRecorder();
      if (!_recReady) return;
    }

    if (_recOn) {
      // Stop & gửi file
      final path = await _recorder.stopRecorder();
      _recOn = false;
      setState(() {});
      if (path != null) {
        setState(() => _sending = true);
        try {
          final sent = await repo.sendMessage(
            token: widget.accessToken,
            peerUserId: _peerId,
            filePath: path,
          );
          if (sent != null) {
            _mergeIncoming([sent], toTail: true);
            setState(() {});
            _jumpToBottom();
          }
        } catch (e) {
          debugPrint('send voice error: $e');
        } finally {
          setState(() => _sending = false);
        }
      }
    } else {
      // Start ghi âm
      final dir = await getTemporaryDirectory();
      final filename = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final fullPath = '${dir.path}/$filename';

      await _recorder.startRecorder(
        toFile: fullPath,
        codec: Codec.aacMP4,
        bitRate: 64000,
        sampleRate: 44100,
        numChannels: 1,
      );

      _recOn = true;
      setState(() {});
    }
  }

  Future<void> _onRefresh() async {
    await _fetchNew();
    await repo.readChats(token: widget.accessToken, peerUserId: _peerId);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.peerName ?? 'Chat';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_loading && _messages.isEmpty)
            const LinearProgressIndicator(minHeight: 2),

          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.pixels <= 80 && _hasMore && !_loading) {
                  _fetchOlder();
                }
                return false;
              },
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (ctx, i) {
                    final m = _messages[i];
                    final isMe = (m['position'] == 'right');
                    return ChatMessageBubble(
                      message: m,
                      isMe: isMe,
                    );
                  },
                ),
              ),
            ),
          ),

          // Input bar
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: _sending ? null : _pickAndSendFile,
                  icon: const Icon(Icons.attach_file),
                ),
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    minLines: 1,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendText(),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: _sending ? null : _toggleRecord,
                  icon: Icon(
                    _recOn ? Icons.stop_circle_outlined : Icons.mic_none,
                    color: _recOn ? Colors.red : null,
                  ),
                  tooltip: _recOn ? 'Dừng & gửi' : 'Ghi âm',
                ),
                IconButton(
                  onPressed: _sending ? null : _sendText,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
