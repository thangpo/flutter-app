import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/widgets/chat_message_bubble.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_chat_repository.dart';

class ChatScreen extends StatefulWidget {
  final String accessToken;
  final String peerUserId; // id người nhận (recipient_id)
  final String? receiverId; // để tương thích chỗ gọi cũ (không còn dùng)
  final String? peerName;
  final String? peerAvatar;

  const ChatScreen({
    super.key,
    required this.accessToken,
    required this.peerUserId,
    this.receiverId,
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

  /// Lấy thêm cũ hơn sẽ dùng `before_message_id = _beforeId`
  String? _beforeId;

  /// Luôn giữ **tăng dần theo id** (cũ → mới)
  List<Map<String, dynamic>> _messages = [];

  // ====== FlutterSound (ghi âm) ======
  final _recorder = FlutterSoundRecorder();
  bool _recReady = false;
  bool _recOn = false;
  String? _recPath;

  late final String _peerId;

  @override
  void initState() {
    super.initState();
    // peerUserId là required nên dùng trực tiếp, không cần ?? receiverId
    _peerId = widget.peerUserId;
    _initRecorder();
    _loadInit();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scroll.dispose();
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

  /// Merge + dedupe; giữ thứ tự tăng dần theo id.
  /// - toTail=true: thường dùng khi push tin mới (append nếu id lớn hơn).
  /// - toTail=false: thường dùng khi prepend older (id nhỏ hơn).
  void _mergeIncoming(List<Map<String, dynamic>> incoming,
      {required bool toTail}) {
    if (incoming.isEmpty) return;

    // sắp xếp incoming trước cho chắc
    _sortAscById(incoming);

    if (_messages.isEmpty) {
      _messages = [...incoming];
      return;
    }

    final exist = _messages.map(_msgIdStr).where((e) => e.isNotEmpty).toSet();
    final filtered = <Map<String, dynamic>>[];
    for (final m in incoming) {
      final idStr = _msgIdStr(m);
      if (idStr.isEmpty || exist.contains(idStr)) continue;
      filtered.add(m);
    }
    if (filtered.isEmpty) return;

    final curMin = _msgId(_messages.first);
    final curMax = _msgId(_messages.last);
    final incMin = _msgId(filtered.first);
    final incMax = _msgId(filtered.last);

    if (toTail) {
      // tất cả đều mới hơn
      if (incMin > curMax) {
        _messages.addAll(filtered);
        return;
      }
    } else {
      // tất cả đều cũ hơn
      if (incMax < curMin) {
        _messages.insertAll(0, filtered);
        return;
      }
    }

    // fallback: có id chen giữa → gộp rồi sort 1 lần
    _messages.addAll(filtered);
    _sortAscById(_messages);
  }

  // ===== recorder =====
  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
    _recReady = true;
    setState(() {});
  }

  // ===== data =====
  Future<void> _loadInit() async {
    await _fetchNew(); // lấy tin mới nhất (page đầu)
    // mark read
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

        // giữ viewport: chèn lên đầu nhưng không nhảy vị trí
        if (_scroll.hasClients) {
          _mergeIncoming(older, toTail: false);
          setState(() {});
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final newMax = _scroll.position.maxScrollExtent;
            final delta = newMax - oldMax;
            final want = _scroll.position.pixels + delta;
            _scroll.jumpTo(want.clamp(
              _scroll.position.minScrollExtent,
              _scroll.position.maxScrollExtent,
            ));
          });
        } else {
          _mergeIncoming(older, toTail: false);
          setState(() {});
        }
      } else {
        _hasMore = false;
        setState(() {});
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
    if (!_recReady) return;
    if (_recOn) {
      // stop & gửi
      final path = await _recorder.stopRecorder();
      _recOn = false;
      setState(() {});
      if (path != null) {
        setState(() => _sending = true);
        try {
          final sent = await repo.sendMessage(
            token: widget.accessToken,
            peerUserId: _peerId,
            filePath: path, // repo sẽ đoán content-type audio/*
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
      // start
      final dir = await getTemporaryDirectory();
      _recPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.startRecorder(toFile: _recPath!, codec: Codec.aacMP4);
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

          // ====== List messages (mới ở dưới) ======
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
                  reverse: false, // rất quan trọng: mới ở BOTTOM
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

          // ====== Input bar ======
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
                // Mic
                IconButton(
                  onPressed: _sending ? null : _toggleRecord,
                  icon: Icon(
                    _recOn ? Icons.stop_circle_outlined : Icons.mic_none,
                    color: _recOn ? Colors.red : null,
                  ),
                  tooltip: _recOn ? 'Dừng & gửi' : 'Ghi âm',
                ),
                // Send
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
