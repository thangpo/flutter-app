// G:\flutter-app\lib\features\social\screens\chat_screen.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// UI + data
import 'package:flutter_sixvalley_ecommerce/features/social/widgets/chat_message_bubble.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_chat_repository.dart';

// 🔔 Calling
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/call_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/call_invite.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/incoming_call_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/call_screen.dart';

import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;


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

  // Messenger-like
  bool _showScrollToBottom = false;
  int _lastItemCount = 0;

  late final String _peerId;

  @override
  void initState() {
    super.initState();
    _peerId = widget.peerUserId;
    _initRecorder();
    _loadInit();

    _scroll.addListener(() {
      // Hiện nút mũi tên khi cách đáy > 300px
      final dist = _scroll.position.hasContentDimensions
          ? (_scroll.position.maxScrollExtent - _scroll.position.pixels)
          : 0.0;
      final show = dist > 300;
      if (_showScrollToBottom != show) {
        setState(() => _showScrollToBottom = show);
      }

      // Kéo lên gần đầu thì nạp tin cũ
      if (_scroll.position.pixels <= 80 && _hasMore && !_loading) {
        _fetchOlder();
      }
    });
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

  String _plainTextOf(Map<String, dynamic> m) {
    final display = (m['display_text'] ?? '').toString();
    if (display.isNotEmpty) return display;

    final raw = (m['text'] ?? '').toString();
    final timeStr = '${m['time'] ?? ''}';
    final dec = _tryDecryptWoWonder(raw, timeStr);
    return (dec ?? raw).trim();
  }

  /// Giải mã theo chuẩn WoWonder: AES-ECB, key = 16 byte từ 'time'
  String? _tryDecryptWoWonder(String base64Text, String timeStr) {
    if (base64Text.isEmpty || timeStr.isEmpty) return null;
    final keyStr = timeStr.padRight(16, '0').substring(0, 16);
    try {
      final data = base64.decode(base64.normalize(base64Text));
      // Thử PKCS7
      final e1 = enc.Encrypter(enc.AES(
        enc.Key(Uint8List.fromList(utf8.encode(keyStr))),
        mode: enc.AESMode.ecb,
        padding: 'PKCS7',
      ));
      final p1 = e1.decrypt(enc.Encrypted(data));
      return p1.replaceAll('\x00', '').trim();
    } catch (_) {
      try {
        final data = base64.decode(base64.normalize(base64Text));
        // Thử no padding
        final e2 = enc.Encrypter(enc.AES(
          enc.Key.fromUtf8(keyStr),
          mode: enc.AESMode.ecb,
          padding: null,
        ));
        final p2 = e2.decrypt(enc.Encrypted(data));
        return p2.replaceAll('\x00', '').trim();
      } catch (_) {
        return null;
      }
    }
  }

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
    _scrollToBottom(immediate: true); // vào là ở tin mới nhất
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
      _scrollToBottom(immediate: true);
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

  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent + 40;
      if (immediate) {
        _scroll.jumpTo(target);
      } else {
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ===== send =====
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
        _scrollToBottom();
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
        _scrollToBottom();
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
            _scrollToBottom();
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

  // ====== NEW: Bắt đầu cuộc gọi, gửi invite và hiển thị "Đang gọi..." ======
  Future<void> _startCall(String mediaType) async {
    final call = context.read<CallController>();
    try {
      if (!call.ready) {
        await call.init();
      }

      final calleeId = int.tryParse(_peerId) ?? 0;
      if (calleeId <= 0) throw 'peerUserId không hợp lệ';

      // 1) Tạo cuộc gọi trên server signaling
      final callId =
          await call.startCall(calleeId: calleeId, mediaType: mediaType);

      // 2) Gửi message mời gọi (để bên kia thấy “Cuộc gọi thoại/video”)
      final payload = CallInvite.build(callId, mediaType);
      final sent = await repo.sendMessage(
        token: widget.accessToken,
        peerUserId: _peerId,
        text: payload,
      );
      if (sent != null) {
        _mergeIncoming([sent], toTail: true);
        setState(() {});
        _scrollToBottom();
      }

      // 3) Mở dialog chờ trả lời
      if (mounted) _showCallingDialog(mediaType: mediaType);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể bắt đầu cuộc gọi: $e')),
      );
    }
  }


  // ====== Calling dialog (vào CallScreen sau khi answer) ======
  void _showCallingDialog({required String mediaType}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Consumer<CallController>(
          builder: (ctx, call, _) {
            if (call.callStatus == 'answered') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
                if (call.activeCallId != null && mounted) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CallScreen(
                      isCaller: true,
                      callId: call.activeCallId!,
                      mediaType: call.activeMediaType, // 'audio' | 'video'
                      peerName: widget.peerName,
                      peerAvatar: widget.peerAvatar,
                    ),
                  ));
                }
              });
            } else if (call.callStatus == 'declined' ||
                call.callStatus == 'ended') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cuộc gọi đã ${call.callStatus}')),
                );
              });
            }

            return AlertDialog(
              title: Text(mediaType == 'audio'
                  ? 'Đang gọi thoại...'
                  : 'Đang gọi video...'),
              content: const Text('Chờ đối phương trả lời...'),
              actions: [
                TextButton(
                  onPressed: () async {
                    try {
                      await context.read<CallController>().endCall();
                    } catch (_) {}
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Hủy'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final title = widget.peerName ?? 'Chat';
    final peerAvatar = widget.peerAvatar ?? '';

    // Auto scroll về cuối khi có tin mới và đang ở gần đáy
    final distFromBottom = _scroll.hasClients
        ? (_scroll.position.maxScrollExtent - _scroll.position.pixels)
        : 0.0;
    final nearBottom = distFromBottom < 200;
    if (_messages.length != _lastItemCount) {
      if (_messages.length > _lastItemCount && nearBottom) {
        _scrollToBottom();
      }
      _lastItemCount = _messages.length;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (peerAvatar.isNotEmpty)
              CircleAvatar(
                  radius: 16, backgroundImage: NetworkImage(peerAvatar)),
            if (peerAvatar.isNotEmpty) const SizedBox(width: 8),
            Flexible(
              child: Text(title, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        elevation: 0,
        centerTitle: false,

        // 👇 Nút gọi thoại & video
        actions: [
          Consumer<CallController>(
            builder: (ctx, call, _) {
              final enabled = call.ready;
              return Row(children: [
                IconButton(
                  tooltip: 'Gọi thoại',
                  icon: const Icon(Icons.call),
                  onPressed: enabled ? () => _startCall('audio') : null,
                ),
                IconButton(
                  tooltip: 'Gọi video',
                  icon: const Icon(Icons.videocam),
                  onPressed: enabled ? () => _startCall('video') : null,
                ),
              ]);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_loading && _messages.isEmpty)
                const LinearProgressIndicator(minHeight: 2),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    controller: _scroll,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final m = _messages[i];
                      final isMe = (m['position'] == 'right');

                      // 🔍 NEW: Bắt CallInvite trong text/display_text
                      final dText =
                          (m['display_text'] ?? m['text'] ?? '').toString();
                          debugPrint('[INV-DEBUG] plain=${_plainTextOf(m)}');
                      final inv = CallInvite.tryParse(dText);
                      if (inv != null && !inv.isExpired()) {
                        if (!isMe) {
                          final msgAvatar =
                              (m['user_data']?['avatar'] ?? '').toString();
                          final leftAvatar =
                              msgAvatar.isNotEmpty ? msgAvatar : peerAvatar;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: leftAvatar.isNotEmpty
                                      ? NetworkImage(leftAvatar)
                                      : null,
                                  child: leftAvatar.isEmpty
                                      ? const Icon(Icons.person, size: 18)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: _buildCallInviteTile(inv, isMe: false),
                                ),
                              ],
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                  child: _buildCallInviteTile(inv, isMe: true)),
                            ],
                          ),
                        );
                      }

                      // avatar trái cho đối phương (kiểu Messenger)
                      if (!isMe) {
                        final msgAvatar =
                            (m['user_data']?['avatar'] ?? '').toString();
                        final leftAvatar =
                            msgAvatar.isNotEmpty ? msgAvatar : peerAvatar;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: leftAvatar.isNotEmpty
                                    ? NetworkImage(leftAvatar)
                                    : null,
                                child: leftAvatar.isEmpty
                                    ? const Icon(Icons.person, size: 18)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: ChatMessageBubble(
                                  key: ValueKey('${m['id'] ?? m.hashCode}'),
                                  message: m,
                                  isMe: false,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // tin của mình: căn phải, không avatar
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: ChatMessageBubble(
                                key: ValueKey('${m['id'] ?? m.hashCode}'),
                                message: m,
                                isMe: true,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Composer kiểu Messenger
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        enabled: !_sending,
                        minLines: 1,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText:
                              _sending ? 'Đang gửi...' : 'Nhập tin nhắn...',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: IconButton(
                            icon: const Icon(Icons.attach_file),
                            onPressed: _sending ? null : _pickAndSendFile,
                            tooltip: 'Đính kèm',
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _recOn ? Icons.mic_off : Icons.mic,
                              color: _recOn ? Colors.red : null,
                            ),
                            onPressed: _sending ? null : _toggleRecord,
                            tooltip: _recOn ? 'Dừng & gửi' : 'Ghi âm',
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
                      onPressed: _sending ? null : _sendText,
                      icon: const Icon(Icons.send),
                      tooltip: 'Gửi',
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Nút tròn mũi tên xuống
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

  // ===== NEW: tile hiển thị lời mời gọi + mở IncomingCallScreen =====
  Widget _buildCallInviteTile(CallInvite inv, {required bool isMe}) {
    final isVideo = inv.mediaType == 'video';
    final bg = isMe ? const Color(0xFF2F80ED) : const Color(0xFFEFEFEF);
    final fg = isMe ? Colors.white : Colors.black87;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IncomingCallScreen(
              callId: inv.callId,
              mediaType: inv.mediaType,
              peerName: widget.peerName, // đổi về peerName
              peerAvatar: widget.peerAvatar, 
            ),
          ),
        );
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isVideo ? Icons.videocam : Icons.call, color: fg, size: 16),
            const SizedBox(width: 8),
            Text(isVideo ? 'Cuộc gọi video' : 'Cuộc gọi thoại',
                style: TextStyle(color: fg)),
          ],
        ),
      ),
    );
  }
}
