// G:\flutter-app\lib\features\social\screens\chat_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'package:encrypt/encrypt.dart' as enc;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:get/get.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_friends_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_friend.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/chat_info_screen.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/group_chat_controller.dart';

// Bubble + repo
import 'package:flutter_sixvalley_ecommerce/features/social/widgets/chat_message_bubble.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_chat_repository.dart';

// Call
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/call_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/push/callkit_service.dart';
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

  /// ✅ dùng để báo ngược lại FriendsList: trong phiên này có tin mới hay không
  bool _hasNewMessage = false;

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

  /// Tin nhắn đang được "trả lời"
  Map<String, dynamic>? _replyingToMessage;

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
  // SEND TEXT (có reply_id)
  // =================================================
  Future<void> _sendText() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    final replying = _replyingToMessage;
    String? replyId;
    if (replying != null) {
      replyId = _msgIdStr(replying);
    }

    setState(() {
      _sending = true;
      _replyingToMessage = null;
    });

    try {
      final sent = await repo.sendMessage(
        token: widget.accessToken,
        peerUserId: _peerId,
        text: text,
        replyToMessageId: replyId,
      );

      _inputCtrl.clear();

      if (sent != null) {
        if (replyId != null &&
            (sent['reply_id'] == null || '${sent['reply_id']}' == '0')) {
          sent['reply_id'] = replyId;
        }
        if (replying != null) {
          sent['reply'] ??= Map<String, dynamic>.from(replying);
        }

        _mergeIncoming([sent], toTail: true);
        _applyLocalReactionsToMessages();

        if (mounted) {
          setState(() {
            _hasNewMessage =
                true; // ✅ đánh dấu: đã có tin nhắn mới trong phiên này
          });
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
          setState(() {
            _hasNewMessage = true; // ✅ gửi file cũng tính là tin mới
          });
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
              setState(() {
                _hasNewMessage = true; // ✅ voice cũng tính là tin mới
              });
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
      // Đánh dấu call_id này đã được xử lý (để chính caller không nhận lại CallKit)
      CallkitService.I.markServerCallHandled(callId);

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
  // REPLY HELPERS
  // =================================================

  bool _hasReplyTag(Map<String, dynamic> m) {
    final v = m['reply_id'] ?? m['reply_to_id'] ?? (m['reply']?['id']);
    if (v == null) return false;
    final s = v.toString();
    return s.isNotEmpty && s != '0';
  }

  Map<String, dynamic>? _findRepliedMessage(Map<String, dynamic> m) {
    final r = m['reply'];
    if (r is Map<String, dynamic>) {
      return r;
    }
    final id = '${m['reply_id'] ?? m['reply_to_id'] ?? ''}';
    if (id.isEmpty || id == '0') return null;

    for (final msg in _messages) {
      if (_msgIdStr(msg) == id) return msg;
    }
    return null;
  }

  /// Header nhỏ: "Tran đã trả lời tin nhắn của chính mình" / "Bạn đã trả lời Tran" ...
  /// Dòng text: "Bạn đã trả lời Tran" / "Tran đã trả lời tin nhắn của chính mình"
  Widget _buildReplyHeader({
    required Map<String, dynamic> message,
    Map<String, dynamic>? replyMsg,
    required bool isMe,
  }) {
    final peerName = widget.peerName ?? '';

    // Đoán người được reply có phải chính người gửi message hay không
    bool repliedIsMe = false;
    if (replyMsg != null) {
      final rpPos = replyMsg['position'];

      if (rpPos == 'right') {
        repliedIsMe = isMe;
      } else if (rpPos == 'left') {
        repliedIsMe = !isMe;
      } else {
        final fromUserId = message['user_data']?['user_id']?.toString() ??
            message['from_id']?.toString();
        final replyUserId = replyMsg['user_data']?['user_id']?.toString() ??
            replyMsg['from_id']?.toString();

        if (fromUserId != null &&
            replyUserId != null &&
            fromUserId.isNotEmpty &&
            replyUserId.isNotEmpty) {
          repliedIsMe = fromUserId == replyUserId;
        }
      }
    }

    final senderName =
        message['user_data']?['name']?.toString().trim().isNotEmpty == true
            ? message['user_data']['name'].toString()
            : peerName;

    String text;
    if (isMe && repliedIsMe) {
      text = 'Bạn đã trả lời tin nhắn của chính mình';
    } else if (isMe && !repliedIsMe) {
      text = senderName.isNotEmpty
          ? 'Bạn đã trả lời $senderName'
          : 'Bạn đã trả lời';
    } else if (!isMe && repliedIsMe) {
      final name = senderName.isNotEmpty ? senderName : 'Người kia';
      text = '$name đã trả lời tin nhắn của chính mình';
    } else {
      final name = senderName.isNotEmpty ? senderName : 'Người kia';
      text = '$name đã trả lời bạn';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Align(
        alignment: isMe
            ? Alignment.centerRight
            : Alignment.centerLeft, // dóng theo bubble
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.reply, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 10, // chữ bé hơn 1 tẹo
                  color: Colors.grey, // không nền, chỉ chữ xám
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Thanh nội dung tin nhắn được reply (quote)
  Widget _buildReplyPreview(
    Map<String, dynamic> replyMsg, {
    required bool isMe,
  }) {
    final text = _plainTextOf(replyMsg);

    final bgColor = Colors.grey.shade200; // nền xám nhẹ
    final maxWidth = MediaQuery.of(context).size.width * 0.6; // ~ nửa màn hình

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
              color: Colors.black87, // chữ đen
              fontStyle: FontStyle.italic, // nghiêng
            ),
          ),
        ),
      ),
    );
  }

  // =================================================
  // REACTION + ACTION HANDLERS
  // =================================================

  Future<void> _onLongPressMessage(
      Map<String, dynamic> message, bool isMe) async {
    final id = _msgId(message);
    if (id <= 0) return;

    final current = _getReactionForMessage(message);

    final result = await _showMessageMenu(current, isMe: isMe);
    if (result == null) return;

    if (result.reactionId != null) {
      await _toggleReactionForMessage(message, result.reactionId!);
      return;
    }

    switch (result.action) {
      case _MessageAction.reply:
        setState(() {
          _replyingToMessage = message;
        });
        break;
      case _MessageAction.copy:
        final text = _plainTextOf(message);
        if (text.isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: text));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã sao chép tin nhắn')),
            );
          }
        }
        break;
      case _MessageAction.delete:
        await _deleteMessage(message);
        break;
      case _MessageAction.forward:
        if (!mounted) break;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _ForwardMessageScreen(
              originalMessage: message,
              accessToken: widget.accessToken,
              repo: repo,
            ),
          ),
        );
        break;

      case null:
        break;
    }
  }

  Future<_MessageMenuResult?> _showMessageMenu(int currentReaction,
      {required bool isMe}) {
    return showModalBottomSheet<_MessageMenuResult>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thanh reaction
                Container(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ..._reactionEmojis.entries.map((entry) {
                        final isSelected = entry.key == currentReaction;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.of(ctx).pop(
                            _MessageMenuResult(reactionId: entry.key),
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: isSelected ? 28 : 24,
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 4),
                      const Icon(Icons.add, size: 22),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Hàng action
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 8,
                        offset: Offset(0, -2),
                        color: Colors.black26,
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _MessageActionButton(
                        icon: Icons.reply,
                        label: 'Trả lời',
                        onTap: () => Navigator.of(ctx).pop(
                          const _MessageMenuResult(
                              action: _MessageAction.reply),
                        ),
                      ),
                      _MessageActionButton(
                        icon: Icons.copy,
                        label: 'Sao chép',
                        onTap: () => Navigator.of(ctx).pop(
                          const _MessageMenuResult(action: _MessageAction.copy),
                        ),
                      ),
                      _MessageActionButton(
                        icon: Icons.delete_outline,
                        label: 'Xóa',
                        onTap: () => Navigator.of(ctx).pop(
                          const _MessageMenuResult(
                              action: _MessageAction.delete),
                        ),
                      ),
                      _MessageActionButton(
                        icon: Icons.forward,
                        label: 'Chuyển tiếp',
                        onTap: () => Navigator.of(ctx).pop(
                          const _MessageMenuResult(
                              action: _MessageAction.forward),
                        ),
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

  Future<void> _deleteMessage(Map<String, dynamic> message) async {
    final idStr = _msgIdStr(message);
    if (idStr.isEmpty) return;

    try {
      final ok = await repo.deleteMessage(
        token: widget.accessToken,
        messageId: idStr,
      );

      if (ok) {
        setState(() {
          _messages.removeWhere((m) => _msgIdStr(m) == idStr);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không xóa được tin nhắn')),
          );
        }
      }
    } catch (e) {
      debugPrint('deleteMessage error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không xóa được tin nhắn: $e')),
        );
      }
    }
  }

  Future<void> _toggleReactionForMessage(
      Map<String, dynamic> message, int pickedId) async {
    final idStr = _msgIdStr(message);
    if (idStr.isEmpty) return;

    final current = _getReactionForMessage(message);
    final newReaction = current == pickedId ? 0 : pickedId;
    final reactionStr = newReaction == 0 ? '' : newReaction.toString();

    setState(() {
      message['reaction'] = newReaction;
      if (newReaction == 0) {
        _localReactions.remove(idStr);
      } else {
        _localReactions[idStr] = newReaction;
      }
    });
    _saveLocalReactions();

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

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatInfoScreen(
          peerId: widget.peerUserId,
          peerName: widget.peerName ?? '',
          peerAvatar: widget.peerAvatar ?? '',
          accessToken: widget.accessToken,
        ),
      ),
    );
  }

  Widget _buildEmptyChatState({
    required String peerAvatar,
    required String title,
  }) {
    final handle = widget.peerUserId.isNotEmpty
        ? '@${widget.peerUserId.replaceAll('@', '')}'
        : '';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
                  peerAvatar.isNotEmpty ? NetworkImage(peerAvatar) : null,
              child: peerAvatar.isEmpty
                  ? const Icon(Icons.person, size: 52, color: Colors.white70)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            if (handle.isNotEmpty)
              Text(
                handle,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Hai ban chua co tin nhan nao.\nHay gui loi chao de bat dau ket noi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: _openProfile,
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Xem trang ca nhan'),
            ),
          ],
        ),
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

    return WillPopScope(
      onWillPop: () async {
        // ✅ khi bấm back vật lý – trả _hasNewMessage về FriendsList
        Navigator.pop(context, _hasNewMessage);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // ✅ khi bấm nút back trên AppBar – cũng trả flag
              Navigator.pop(context, _hasNewMessage);
            },
          ),
          title: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _openProfile();
            },
            child: Row(
              children: [
                if (peerAvatar.isNotEmpty)
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(peerAvatar),
                  ),
                if (peerAvatar.isNotEmpty) const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            Consumer<CallController>(
              builder: (ctx, call, _) {
                final enabled = call.ready;
                return Row(
                  children: [
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
                  ],
                );
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
                    child: _messages.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight),
                                  child: _buildEmptyChatState(
                                    peerAvatar: peerAvatar,
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
                            itemCount: _messages.length,
                            itemBuilder: (ctx, i) {
                              final m = _messages[i];
                              final isMe = (m['position'] == 'right');

                              final plain = _plainTextOf(m);
                              final inv = CallInvite.tryParse(plain);

                              if (inv != null && !inv.isExpired()) {
                                final callId = inv.callId;
                                final cc =
                                    Provider.of<CallController>(context, listen: false);
                                final alreadyHandled = _handledIncoming.contains(callId) ||
                                    cc.isCallHandled(callId);

        if (!isMe && !alreadyHandled) {
          _handledIncoming.add(callId);
          cc.markCallHandled(callId);

          // iOS đang dùng CallKit (UI hệ thống), không auto mở IncomingCallScreen Flutter
          if (!Platform.isIOS) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
          builder: (_) => CallScreen(
            isCaller: false,
            callId: inv.callId,
            mediaType: inv.mediaType,
            peerName: widget.peerName,
            peerAvatar: widget.peerAvatar,
          ),
        ),
      );
            });
          }
        }

                                if (!isMe) {
                                  final msgAvatar =
                                      (m['user_data']?['avatar'] ?? '')
                                          .toString();
                                  final leftAvatar = msgAvatar.isNotEmpty
                                      ? msgAvatar
                                      : peerAvatar;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundImage: leftAvatar.isNotEmpty
                                              ? NetworkImage(leftAvatar)
                                              : null,
                                          child: leftAvatar.isEmpty
                                              ? const Icon(Icons.person,
                                                  size: 18)
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: _buildCallInviteTile(inv,
                                              isMe: false),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                // yourself
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        child: _buildCallInviteTile(inv,
                                            isMe: true),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final reactionId = _getReactionForMessage(m);
                              final hasReply = _hasReplyTag(m);
                              final replyMsg =
                                  hasReply ? _findRepliedMessage(m) : null;

                              // normal bubble
                              if (!isMe) {
                                final msgAvatar =
                                    (m['user_data']?['avatar'] ?? '')
                                        .toString();
                                final leftAvatar = msgAvatar.isNotEmpty
                                    ? msgAvatar
                                    : peerAvatar;

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundImage: leftAvatar.isNotEmpty
                                            ? NetworkImage(leftAvatar)
                                            : null,
                                        child: leftAvatar.isEmpty
                                            ? const Icon(Icons.person,
                                                size: 18)
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: _SwipeReplyWrapper(
                                          isMe: false,
                                          onReply: () {
                                            setState(() {
                                              _replyingToMessage = m;
                                            });
                                          },
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onLongPress: () =>
                                                _onLongPressMessage(
                                                    m, false),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (hasReply)
                                                  _buildReplyHeader(
                                                    message: m,
                                                    replyMsg: replyMsg,
                                                    isMe: false,
                                                  ),
                                                if (replyMsg != null)
                                                  _buildReplyPreview(replyMsg,
                                                      isMe: false),
                                                Stack(
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
                                                        child:
                                                            _buildReactionBadge(
                                                                reactionId,
                                                                isMe: false),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              // my message
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Flexible(
                                      child: _SwipeReplyWrapper(
                                        isMe: true,
                                        onReply: () {
                                          setState(() {
                                            _replyingToMessage = m;
                                          });
                                        },
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onLongPress: () =>
                                              _onLongPressMessage(m, true),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              if (hasReply)
                                                _buildReplyHeader(
                                                  message: m,
                                                  replyMsg: replyMsg,
                                                  isMe: true,
                                                ),
                                              if (replyMsg != null)
                                                _buildReplyPreview(replyMsg,
                                                    isMe: true),
                                              Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  ChatMessageBubble(
                                                    key: ValueKey(
                                                        '${m['id'] ?? m.hashCode}'),
                                                    message: m,
                                                    isMe: true,
                                                  ),
                                                  if (reactionId != 0)
                                                    Positioned(
                                                      bottom: -14,
                                                      right: 8,
                                                      child:
                                                          _buildReactionBadge(
                                                              reactionId,
                                                              isMe: true),
                                                    ),
                                                ],
                                              ),
                                            ],
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
                // Thanh "Đang trả lời..."
                if (_replyingToMessage != null)
                  Container(
                    width: double.infinity,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                            _plainTextOf(_replyingToMessage!),
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
                            setState(() {
                              _replyingToMessage = null;
                            });
                          },
                        ),
                      ],
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
        if (Platform.isIOS) return; // iOS đã dùng CallKit UI
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

/// ================== HỖ TRỢ MENU ==================

enum _MessageAction { reply, copy, delete, forward }

class _MessageMenuResult {
  final int? reactionId;
  final _MessageAction? action;

  const _MessageMenuResult({this.reactionId, this.action});
}

class _MessageActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MessageActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

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

class _ForwardMessageScreen extends StatefulWidget {
  final Map<String, dynamic> originalMessage;
  final String accessToken;
  final SocialChatRepository repo;

  const _ForwardMessageScreen({
    super.key,
    required this.originalMessage,
    required this.accessToken,
    required this.repo,
  });

  @override
  State<_ForwardMessageScreen> createState() => _ForwardMessageScreenState();
}

class _ForwardMessageScreenState extends State<_ForwardMessageScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  SocialFriendsController? _friendsCtrl;
  GroupChatController? _groupCtrl;

  List<SocialFriend> _allFriends = [];
  List<Map<String, dynamic>> _allGroups = [];

  bool _loadingList = true;
  bool _sending = false;
  String _keyword = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _initData();
    _searchCtrl.addListener(() {
      setState(() {
        _keyword = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() {
      _loadingList = true;
      _error = null;
    });

    try {
      // 🔹 Friends (GetX)
      if (Get.isRegistered<SocialFriendsController>()) {
        _friendsCtrl = Get.find<SocialFriendsController>();

        // Ưu tiên filtered nếu đã search, không thì friends
        final friends = _friendsCtrl!.filtered.isNotEmpty
            ? _friendsCtrl!.filtered
            : _friendsCtrl!.friends;

        _allFriends = List<SocialFriend>.from(friends);
      }

      // 🔹 Groups (Provider)
      _groupCtrl = context.read<GroupChatController>();
      if (_groupCtrl!.groups.isEmpty) {
        await _groupCtrl!.loadGroups();
      }
      _allGroups = List<Map<String, dynamic>>.from(_groupCtrl!.groups as List);
    } catch (e, st) {
      debugPrint('Forward initData error: $e\n$st');
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _loadingList = false;
        });
      }
    }
  }

  Future<void> _forwardToFriend(SocialFriend f) async {
    await _forwardCore(
        targetId: f.id.toString(), isGroup: false, targetName: f.name ?? '');
  }

  Future<void> _forwardToGroup(Map<String, dynamic> g) async {
    final groupId = (g['group_id'] ?? g['id'] ?? '').toString();
    final groupName = (g['group_name'] ?? g['name'] ?? 'Nhóm').toString();
    if (groupId.isEmpty) return;

    await _forwardCore(targetId: groupId, isGroup: true, targetName: groupName);
  }

  Future<void> _forwardCore({
    required String targetId,
    required bool isGroup,
    required String targetName,
  }) async {
    if (_sending) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    final m = widget.originalMessage;

    try {
      Map<String, dynamic>? sent;

      final mediaUrl = (m['media_url'] ?? m['media'] ?? '').toString();
      final isMedia = (m['is_image'] == true) ||
          (m['is_video'] == true) ||
          (m['is_audio'] == true) ||
          (m['is_file'] == true);

      // caption dùng chung cho cả text lẫn media
      final caption = (m['display_text'] ?? m['text'] ?? '').toString().trim();

      // ================= MEDIA =================
      if (isMedia && mediaUrl.isNotEmpty && mediaUrl.startsWith('http')) {
        final uri = Uri.parse(mediaUrl);
        final res = await http.get(uri);

        if (res.statusCode == 200) {
          final dir = await getTemporaryDirectory();
          final name = uri.pathSegments.isNotEmpty
              ? uri.pathSegments.last
              : 'forward_${DateTime.now().millisecondsSinceEpoch}';
          final file = File('${dir.path}/$name');
          await file.writeAsBytes(res.bodyBytes);

          if (isGroup) {
            // 👉 forward vào nhóm
            final gc = _groupCtrl ?? context.read<GroupChatController>();

            // đoán type theo cờ is_image / is_video / is_audio / is_file
            String mediaType = 'file';
            if (m['is_image'] == true)
              mediaType = 'image';
            else if (m['is_video'] == true)
              mediaType = 'video';
            else if (m['is_audio'] == true) mediaType = 'voice';

            // ⬇️ Ở group: text là tham số bắt buộc
            await gc.sendMessage(
              targetId,
              caption, // có thể rỗng, không sao
              file: file,
              type: mediaType,
            );
            sent = {}; // đánh dấu là đã gửi xong
          } else {
            // 👉 forward 1-1
            sent = await widget.repo.sendMessage(
              token: widget.accessToken,
              peerUserId: targetId,
              filePath: file.path,
              // nếu có caption thì đính kèm luôn
              text: caption.isNotEmpty ? caption : null,
            );
          }
        }
      }

      // ================= TEXT =================
      if (sent == null) {
        final text = (m['display_text'] ?? m['text'] ?? '').toString().trim();
        if (text.isEmpty) {
          throw 'Tin nhắn này không thể chuyển tiếp (không có nội dung).';
        }

        if (isGroup) {
          final gc = _groupCtrl ?? context.read<GroupChatController>();

          await gc.sendMessage(
            targetId,
            text, // ⬅️ text bắt buộc
          );
        } else {
          sent = await widget.repo.sendMessage(
            token: widget.accessToken,
            peerUserId: targetId,
            text: text,
          );
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã chuyển tiếp cho ${targetName.isNotEmpty ? targetName : targetId}',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e, st) {
      debugPrint('forwardCore error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.originalMessage;
    final previewText =
        (m['display_text'] ?? m['text'] ?? '').toString().trim();
    final mediaUrl = (m['media_url'] ?? m['media'] ?? '').toString();
    final isImage = m['is_image'] == true && mediaUrl.startsWith('http');

    // Filter theo keyword
    var friends = _allFriends;
    var groups = _allGroups;
    if (_keyword.isNotEmpty) {
      friends = friends
          .where((f) =>
              (f.name ?? '').toLowerCase().contains(_keyword) ||
              f.id.toString().contains(_keyword))
          .toList();

      groups = groups.where((g) {
        final name =
            (g['group_name'] ?? g['name'] ?? '').toString().toLowerCase();
        final id = (g['group_id'] ?? g['id'] ?? '').toString();
        return name.contains(_keyword) || id.contains(_keyword);
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chuyển tiếp tin nhắn'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📌 Preview tin nhắn
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tin nhắn cần chuyển tiếp:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isImage)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            mediaUrl,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      if (previewText.isNotEmpty) ...[
                        if (isImage) const SizedBox(height: 6),
                        Text(
                          previewText,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (!isImage && previewText.isEmpty)
                        const Text('(Tin nhắn media)'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 🔍 Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm bạn bè hoặc nhóm...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),

          const SizedBox(height: 4),
          Expanded(
            child: _loadingList
                ? const Center(child: CircularProgressIndicator())
                : (friends.isEmpty && groups.isEmpty)
                    ? const Center(
                        child: Text(
                          'Không có bạn bè hoặc nhóm nào.\nHãy thử đổi từ khoá tìm kiếm.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13),
                        ),
                      )
                    : ListView(
                        children: [
                          if (friends.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
                              child: Text(
                                'Bạn bè',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            ...friends.map((f) {
                              final avatar = f.avatar ?? '';
                              final name = f.name ?? 'User #${f.id}';
                              return ListTile(
                                onTap:
                                    _sending ? null : () => _forwardToFriend(f),
                                leading: CircleAvatar(
                                  backgroundImage: avatar.isNotEmpty
                                      ? NetworkImage(avatar)
                                      : null,
                                  child: avatar.isEmpty
                                      ? Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : '?',
                                        )
                                      : null,
                                ),
                                title: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  'ID: ${f.id}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                              );
                            }),
                            const Divider(height: 16),
                          ],
                          if (groups.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
                              child: Text(
                                'Nhóm chat',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            ...groups.map((g) {
                              final groupId =
                                  (g['group_id'] ?? g['id'] ?? '').toString();
                              final groupName =
                                  (g['group_name'] ?? g['name'] ?? 'Không tên')
                                      .toString();
                              final avatar =
                                  (g['avatar'] ?? g['image'] ?? '').toString();

                              return ListTile(
                                onTap: (_sending || groupId.isEmpty)
                                    ? null
                                    : () => _forwardToGroup(g),
                                leading: CircleAvatar(
                                  backgroundImage: avatar.isNotEmpty
                                      ? NetworkImage(avatar)
                                      : null,
                                  child: avatar.isEmpty
                                      ? Text(
                                          groupName.isNotEmpty
                                              ? groupName[0].toUpperCase()
                                              : '?',
                                        )
                                      : null,
                                ),
                                title: Text(
                                  groupName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  'ID nhóm: $groupId',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                              );
                            }),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
