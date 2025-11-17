// lib/features/social/screens/chat_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Bubble + repo
import 'package:flutter_sixvalley_ecommerce/features/social/widgets/chat_message_bubble.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_chat_repository.dart';

// Call
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/call_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/call_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/incoming_call_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/call_invite.dart';

// FCM Realtime
import 'package:flutter_sixvalley_ecommerce/features/social/fcm/fcm_chat_handler.dart';

class ChatScreen extends StatefulWidget {
  final String accessToken;
  final String peerUserId;
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
  // ============ Core ===============
  final repo = SocialChatRepository();
  final _inputCtrl = TextEditingController();
  final _scroll = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _loading = false;
  bool _sending = false;
  bool _hasMore = true;
  String? _beforeId;

  late final String _peerId;

  // =========== Recorder ==============
  final _recorder = FlutterSoundRecorder();
  bool _recReady = false;
  bool _recOn = false;

  // UI scroll logic
  bool _showScrollToBottom = false;
  int _lastItemCount = 0;

  // Tránh mở nhiều lần IncomingCall
  final Set<int> _handledIncoming = {};

  // FCM realtime stream
  StreamSubscription? _fcmStream;

  // ===== POLLING REALTIME (fallback nếu FCM không bắn) =====
  Timer? _pollTimer;
  bool _pollInFlight = false;
  Duration _pollInterval = const Duration(seconds: 5);

  // =========== Reactions ============
  // 1: 👍, 2: ❤️, 3: 😂, 4: 😮, 5: 😢, 6: 😡
  static const Map<int, String> _reactionEmojis = {
    1: '👍',
    2: '❤️',
    3: '😂',
    4: '😮',
    5: '😢',
    6: '😡',
  };

  /// Lưu reaction local: { messageId(String) : reactionId(int) }
  Map<String, int> _localReactions = {};

  @override
  void initState() {
    super.initState();
    _peerId = widget.peerUserId;

    _initRecorder();
    _loadLocalReactions(); // load map reaction local
    _loadInitialMessages();

    // Realtime từ FCM (nếu có)
    _listenRealtime();

    // Polling fallback
    _startPolling();

    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scroll.dispose();
    _fcmStream?.cancel();

    _stopPolling();

    if (_recOn) _recorder.stopRecorder();
    _recorder.closeRecorder();

    super.dispose();
  }

  // =================================================
  // REACTIONS LOCAL STORAGE
  // =================================================
  String get _reactionsStorageKey => 'chat_reactions_$_peerId';

  Future<void> _loadLocalReactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_reactionsStorageKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;

      final map = <String, int>{};
      decoded.forEach((k, v) {
        if (k is! String) return;
        int val;
        if (v is int) {
          val = v;
        } else if (v is String) {
          val = int.tryParse(v) ?? 0;
        } else if (v is num) {
          val = v.toInt();
        } else {
          return;
        }
        if (val > 0) map[k] = val;
      });

      _localReactions = map;
    } catch (e) {
      debugPrint('loadLocalReactions error: $e');
    }
  }

  Future<void> _saveLocalReactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_reactionsStorageKey, jsonEncode(_localReactions));
    } catch (e) {
      debugPrint('saveLocalReactions error: $e');
    }
  }

  int _getReactionForMessage(Map<String, dynamic> m) {
    final local = _localReactions[_msgIdStr(m)];
    if (local != null && local > 0) return local;

    final val = m['reaction'];
    if (val is int) return val;
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  void _applyLocalReactionsToMessages() {
    if (_localReactions.isEmpty) return;
    for (final m in _messages) {
      final idStr = _msgIdStr(m);
      final r = _localReactions[idStr];
      if (r != null && r > 0) {
        m['reaction'] = r;
      }
    }
  }

  // =================================================
  // REALTIME LISTENER (FCM)
  // =================================================
  void _listenRealtime() {
    _fcmStream = FcmChatHandler.messagesStream.listen((evt) {
      if (evt.peerId != _peerId) return;
      _reloadLatest();
    });
  }

  // =================================================
  // POLLING REALTIME (fallback)
  // =================================================
  void _startPolling() {
    _stopPolling();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollOnce());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollOnce() async {
    if (!mounted) return;
    if (_pollInFlight) return;

    _pollInFlight = true;
    try {
      // dùng cùng logic với FCM realtime
      await _reloadLatest();
    } finally {
      _pollInFlight = false;
    }
  }

  // =================================================
  // INITIAL LOAD
  // =================================================
  Future<void> _loadInitialMessages() async {
    await _fetchNew();
    await repo.readChats(
      token: widget.accessToken,
      peerUserId: _peerId,
    );
    _scrollToBottom(immediate: true);
  }

  // =================================================
  // SCROLL
  // =================================================
  void _onScroll() {
    if (!_scroll.hasClients) return;

    final dist = _scroll.position.maxScrollExtent - _scroll.position.pixels;

    final show = dist > 300;
    if (show != _showScrollToBottom) {
      setState(() => _showScrollToBottom = show);
    }

    if (_scroll.position.pixels <= 80 && _hasMore && !_loading) {
      _fetchOlder();
    }
  }

  // =================================================
  // MESSAGE FETCHING
  // =================================================

  Future<void> _reloadLatest() async {
    try {
      final list = await repo.getUserMessages(
        token: widget.accessToken,
        peerUserId: _peerId,
        limit: 30,
      );

      list.sort((a, b) => (_msgId(a)).compareTo(_msgId(b)));

      // merge + apply reactions local
      _mergeIncoming(list, toTail: true);
      _applyLocalReactionsToMessages();

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint("realtime reload error: $e");
    }
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

      list.sort((a, b) => _msgId(a).compareTo(_msgId(b)));
      _messages = list;
      _applyLocalReactionsToMessages();

      if (list.isNotEmpty) _beforeId = _msgIdStr(list.first);

      _hasMore = list.length >= 30;

      setState(() {});
      _scrollToBottom(immediate: true);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
        older.sort((a, b) => _msgId(a).compareTo(_msgId(b)));

        _beforeId = _msgIdStr(older.first);
        _mergeIncoming(older, toTail: false);
        _applyLocalReactionsToMessages();

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
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // =================================================
  // MERGE
  // =================================================
  void _mergeIncoming(List<Map<String, dynamic>> incoming,
      {required bool toTail}) {
    if (incoming.isEmpty) return;

    if (_messages.isEmpty) {
      _messages = [...incoming];
      return;
    }

    incoming.sort((a, b) => _msgId(a).compareTo(_msgId(b)));

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

    _messages.sort((a, b) => _msgId(a).compareTo(_msgId(b)));
  }

  // =================================================
  // ID
  // =================================================
  int _msgId(Map<String, dynamic> m) =>
      int.tryParse('${m['id'] ?? m['message_id'] ?? m['msg_id'] ?? ''}') ?? 0;

  String _msgIdStr(Map<String, dynamic> m) =>
      '${m['id'] ?? m['message_id'] ?? m['msg_id'] ?? ''}';

  // =================================================
  // SCROLL
  // =================================================
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

  // =================================================
  // SEND TEXT
  // =================================================
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
        _applyLocalReactionsToMessages();
        if (mounted) {
          setState(() {});
          _scrollToBottom();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  // =================================================
  // FILE & VOICE
  // =================================================

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
        _applyLocalReactionsToMessages();
        if (mounted) {
          setState(() {});
          _scrollToBottom();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _toggleRecord() async {
    if (!_recReady) {
      await _initRecorder();
      if (!_recReady) return;
    }

    if (_recOn) {
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
            _applyLocalReactionsToMessages();
            if (mounted) {
              setState(() {});
              _scrollToBottom();
            }
          }
        } finally {
          if (mounted) {
            setState(() => _sending = false);
          }
        }
      }
    } else {
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

  Future<void> _initRecorder() async {
    final micOk = await _ensureMic();
    if (!micOk) return;

    await _recorder.openRecorder();
    await _recorder.setSubscriptionDuration(
      const Duration(milliseconds: 100),
    );
    _recReady = true;
    setState(() {});
  }

  Future<bool> _ensureMic() async {
    final st = await Permission.microphone.status;
    if (st.isGranted) return true;

    final rs = await Permission.microphone.request();
    return rs.isGranted;
  }

  // =================================================
  // REFRESH
  // =================================================
  Future<void> _onRefresh() async {
    await _fetchNew();
    await repo.readChats(token: widget.accessToken, peerUserId: _peerId);
  }

  // =================================================
  // CALL
  // =================================================
  Future<void> _startCall(String mediaType) async {
    final call = context.read<CallController>();

    try {
      if (!call.ready) await call.init();

      final calleeId = int.tryParse(_peerId) ?? 0;
      if (calleeId <= 0) throw 'peerUserId không hợp lệ';

      final callId = await call.startCall(
        calleeId: calleeId,
        mediaType: mediaType,
      );

      final payload = {
        'type': 'call_invite',
        'call_id': callId,
        'media': mediaType,
        'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

      await repo.sendMessage(
        token: widget.accessToken,
        peerUserId: _peerId,
        text: jsonEncode(payload),
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            isCaller: true,
            callId: callId,
            mediaType: mediaType,
            peerName: widget.peerName,
            peerAvatar: widget.peerAvatar,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể bắt đầu cuộc gọi: $e')),
      );
    }
  }

  // =================================================
  // DECRYPT
  // =================================================
  String _plainTextOf(Map<String, dynamic> m) {
    final display = (m['display_text'] ?? '').toString();
    if (display.isNotEmpty) return display;

    final raw = (m['text'] ?? '').toString();
    final timeStr = '${m['time'] ?? ''}';

    final dec = _tryDecryptWoWonder(raw, timeStr);
    return (dec ?? raw).trim();
  }

  String? _tryDecryptWoWonder(String base64Text, String timeStr) {
    if (base64Text.isEmpty || timeStr.isEmpty) return null;

    final keyStr = timeStr.padRight(16, '0').substring(0, 16);

    try {
      final data = base64.decode(base64.normalize(base64Text));
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

  // =================================================
  // REACTION HANDLERS
  // =================================================
  Future<void> _onLongPressMessage(Map<String, dynamic> message) async {
    final id = _msgId(message);
    if (id <= 0) return;

    final current = _getReactionForMessage(message);
    final selected = await _showReactionPicker(current);
    if (selected == null) return;

    await _toggleReactionForMessage(message, selected);
  }

  Future<int?> _showReactionPicker(int current) {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16, left: 40, right: 40),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 8,
                  offset: Offset(0, -2),
                  color: Colors.black26,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _reactionEmojis.entries.map((entry) {
                final isSelected = entry.key == current;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(ctx).pop(entry.key),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: isSelected ? 28 : 24,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleReactionForMessage(
      Map<String, dynamic> message, int pickedId) async {
    final idStr = _msgIdStr(message);
    if (idStr.isEmpty) return;

    final current = _getReactionForMessage(message);
    final newReaction = current == pickedId ? 0 : pickedId;
    final reactionStr = newReaction == 0 ? '' : newReaction.toString();

    // Cập nhật UI + local cache
    setState(() {
      message['reaction'] = newReaction;
      if (newReaction == 0) {
        _localReactions.remove(idStr);
      } else {
        _localReactions[idStr] = newReaction;
      }
    });
    _saveLocalReactions();

    // Gọi API (không rollback nếu lỗi)
    try {
      await repo.reactMessage(
        token: widget.accessToken,
        messageId: idStr,
        reaction: reactionStr,
      );
    } catch (e) {
      debugPrint('reactMessage error: $e');
    }
  }

  Widget _buildReactionBadge(int reactionId, {required bool isMe}) {
    if (reactionId == 0) return const SizedBox.shrink();
    final emoji = _reactionEmojis[reactionId] ?? '👍';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 4,
            offset: Offset(0, 1),
            color: Colors.black26,
          ),
        ],
      ),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  // =================================================
  // UI
  // =================================================
  @override
  Widget build(BuildContext context) {
    final title = widget.peerName ?? 'Chat';
    final peerAvatar = widget.peerAvatar ?? '';

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
                radius: 16,
                backgroundImage: NetworkImage(peerAvatar),
              ),
            if (peerAvatar.isNotEmpty) const SizedBox(width: 8),
            Flexible(
              child: Text(title, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        elevation: 0,
        centerTitle: false,
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

                      final plain = _plainTextOf(m);
                      final inv = CallInvite.tryParse(plain);

                      if (inv != null && !inv.isExpired()) {
                        final callId = inv.callId;
                        if (!isMe && !_handledIncoming.contains(callId)) {
                          _handledIncoming.add(callId);

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => IncomingCallScreen(
                                  callId: inv.callId,
                                  mediaType: inv.mediaType,
                                  peerName: widget.peerName,
                                  peerAvatar: widget.peerAvatar,
                                ),
                              ),
                            );
                          });
                        }

                        if (!isMe) {
                          final msgAvatar =
                              (m['user_data']?['avatar'] ?? '').toString();
                          final leftAvatar =
                              msgAvatar.isNotEmpty ? msgAvatar : peerAvatar;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
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

                        // yourself
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: _buildCallInviteTile(inv, isMe: true),
                              ),
                            ],
                          ),
                        );
                      }

                      final reactionId = _getReactionForMessage(m);

                      // normal bubble
                      if (!isMe) {
                        final msgAvatar =
                            (m['user_data']?['avatar'] ?? '').toString();
                        final leftAvatar =
                            msgAvatar.isNotEmpty ? msgAvatar : peerAvatar;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onLongPress: () => _onLongPressMessage(m),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      ChatMessageBubble(
                                        key: ValueKey(
                                            '${m['id'] ?? m.hashCode}'),
                                        message: m,
                                        isMe: false,
                                      ),
                                      if (reactionId != 0)
                                        Positioned(
                                          bottom: -14,
                                          left: 8,
                                          child: _buildReactionBadge(reactionId,
                                              isMe: false),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // my message
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onLongPress: () => _onLongPressMessage(m),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    ChatMessageBubble(
                                      key: ValueKey('${m['id'] ?? m.hashCode}'),
                                      message: m,
                                      isMe: true,
                                    ),
                                    if (reactionId != 0)
                                      Positioned(
                                        bottom: -14,
                                        right: 8,
                                        child: _buildReactionBadge(reactionId,
                                            isMe: true),
                                      ),
                                  ],
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

  // =================================================
  // CALL INVITE TILE
  // =================================================
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
              peerName: widget.peerName,
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
            Text(
              isVideo ? 'Cuộc gọi video' : 'Cuộc gọi thoại',
              style: TextStyle(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
