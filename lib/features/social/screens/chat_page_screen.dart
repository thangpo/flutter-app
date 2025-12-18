import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show FontFeature;
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_page_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_page_mess.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_get_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_page_detail.dart';


class PageChatScreen extends StatefulWidget {
  final int pageId;
  final String pageTitle;
  final String pageAvatar;
  final String recipientId;
  final String pageSubtitle;

  const PageChatScreen({
    super.key,
    required this.pageId,
    required this.pageTitle,
    required this.pageAvatar,
    required this.recipientId,
    required this.pageSubtitle,
  });

  @override
  State<PageChatScreen> createState() => _PageChatScreenState();
}

enum _ComposerMode { idle, recording, preview }

enum _AttachChoice { file, galleryMedia }

class _PageChatScreenState extends State<PageChatScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _recording = false;
  bool _recorderReady = false;
  bool _playerReady = false;
  String? _playingUrl;
  final Map<String, Duration> _voiceDurations = {};
  final Map<String, Duration> _voicePositions = {};
  StreamSubscription? _progressSub;
  String? _recordingPath;
  bool _sending = false;
  String? _voiceDraftPath;
  Duration _voiceDraftDuration = Duration.zero;
  Timer? _recTimer;
  Duration _recElapsed = Duration.zero;
  final FlutterSoundPlayer _draftPlayer = FlutterSoundPlayer();
  bool _draftPlaying = false;
  Duration _draftPos = Duration.zero;
  StreamSubscription? _draftSub;
  List<_PendingAttachment> _pendingAttachments = [];
  bool _recOn = false;
  bool _recPaused = false;
  Duration _draftDur = Duration.zero;
  late final SocialPageController _pageCtrl;
  DateTime? _lastProgressUi;
  static const Duration _progressUiThrottle = Duration(milliseconds: 250);
  int _prevMsgCount = 0;
  bool _didInitialScroll = false;
  _ComposerMode get _mode {
    if (_recOn) return _ComposerMode.recording;
    if (_voiceDraftPath != null) return _ComposerMode.preview;
    return _ComposerMode.idle;
  }

  int _localSeq = 0;
  int _nextLocalId() => -(DateTime.now().millisecondsSinceEpoch) - (_localSeq++);

  List<Map<String, dynamic>> _localOutbox = [];
  bool _showScrollToBottom = false;

  bool _isLocalMsg(dynamic item) => item is Map<String, dynamic> && item['local_id'] != null;

  String _localMsgKey(Map<String, dynamic> m) => 'local_${m['local_id']}';

  Map<String, dynamic> _makeLocalMsg({
    required String type,
    String text = '',
    String? filePath,
    Duration? duration,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return {
      'local_id': _nextLocalId(),
      'time': now,
      'local_type': type,
      'local_text': text,
      'local_file_path': filePath,
      if (duration != null) 'local_duration_ms': duration.inMilliseconds,
      'local_status': 'sending',
      'local_error': null,
    };
  }

  @override
  void initState() {
    super.initState();

    _pageCtrl = context.read<SocialPageController>();
    _pageCtrl.addListener(_onPageChatChanged);
    _scrollCtrl.addListener(_onScroll);

    Future.microtask(() async {
      _pageCtrl.initPageChat(
        pageId: widget.pageId,
        recipientId: widget.recipientId,
      );

      await _initRecorder();
      await _initPlayer();

      await _draftPlayer.openPlayer();
      await _draftPlayer.setSubscriptionDuration(const Duration(milliseconds: 200));
      _draftSub = _draftPlayer.onProgress?.listen((e) {
        if (!mounted) return;
        setState(() {
          _draftPos = e.position ?? Duration.zero;
          _draftDur = e.duration ?? _draftDur;
        });
      });
    });
  }

  @override
  void dispose() {
    _pageCtrl.removeListener(_onPageChatChanged);

    _scrollCtrl.removeListener(_onScroll);

    _progressSub?.cancel();
    _draftSub?.cancel();
    _recTimer?.cancel();

    _inputCtrl.dispose();
    _scrollCtrl.dispose();

    _recorder.closeRecorder();
    _player.closePlayer();
    _draftPlayer.closePlayer();

    _pageCtrl.disposePageChat();
    super.dispose();
  }


  void _startRecTimer() {
    _recTimer?.cancel();
    _recElapsed = Duration.zero;
    _recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_recPaused) return;
      setState(() => _recElapsed += const Duration(seconds: 1));
    });
  }

  void _onPageChatChanged() {
    if (!mounted) return;
    if (_pageCtrl.loadingPageMessages) return;

    final msgs = _pageCtrl.pageMessages;

    if (msgs.length != _prevMsgCount) {
      _prevMsgCount = msgs.length;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToBottom(jump: !_didInitialScroll);
        _didInitialScroll = true;
      });
    }
  }

  void _stopRecTimer() {
    _recTimer?.cancel();
    _recTimer = null;
  }

  Widget _localStatusLine(Map<String, dynamic> m) {
    final status = (m['local_status'] ?? '').toString();
    if (status.isEmpty) return const SizedBox.shrink();

    final text = status == 'failed' ? 'Gửi lỗi · chạm để thử lại' : 'Đang gửi...';
    final color = status == 'failed' ? Colors.redAccent : Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(text, style: TextStyle(fontSize: 10.5, color: color)),
    );
  }

  Widget _buildLocalBubble(Map<String, dynamic> m, {required bool isDark}) {
    final t = (m['local_type'] ?? '').toString();
    final txt = (m['local_text'] ?? '').toString();
    final path = (m['local_file_path'] ?? '').toString();

    final bg = const Color(0xFF2F80ED);
    final fg = Colors.white;

    Widget child;
    if (t == 'text') {
      child = Text(txt, style: TextStyle(color: fg, fontSize: 14));
    } else if (t == 'image' && path.isNotEmpty) {
      final heroTag = _heroTagForLocalImage(m);

      child = GestureDetector(
        onTap: () => _openImageViewer(heroTag: heroTag, filePath: path),
        child: Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Text('Ảnh lỗi', style: TextStyle(color: fg)),
            ),
          ),
        ),
      );
    } else if ((t == 'video' || t == 'file') && path.isNotEmpty) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(t == 'video' ? Icons.videocam : Icons.insert_drive_file, color: fg, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              p.basename(path),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg),
            ),
          ),
        ],
      );
    } else if (t == 'voice' && path.isNotEmpty) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic, color: fg, size: 18),
          const SizedBox(width: 8),
          Text('Tin nhắn thoại', style: TextStyle(color: fg)),
        ],
      );
    } else {
      child = Text('(Đang chuẩn bị...)', style: TextStyle(color: fg));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final dist = _scrollCtrl.position.maxScrollExtent - _scrollCtrl.position.pixels;
    final show = dist > 300;
    if (show != _showScrollToBottom && mounted) {
      setState(() => _showScrollToBottom = show);
    }
  }

  void _scrollToBottomSmart({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final target = _scrollCtrl.position.maxScrollExtent + 120;
      if (jump) {
        _scrollCtrl.jumpTo(target);
      } else {
        _scrollCtrl.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _plainTextOf(SocialPageMessage m) {
    final raw = m.text.trim();
    final timeStr = m.time.toString();

    if (raw.isEmpty) return "";
    if (raw.startsWith("http")) return raw;

    final dec = _tryDecryptWoWonder(raw, timeStr);
    return dec ?? raw;
  }

  String _msgKey(SocialPageMessage m) {
    return 'msg_${m.time}_${m.position}_${m.type}_${m.media}_${m.text.hashCode}_${m.stickers.hashCode}';
  }

  String? _tryDecryptWoWonder(String base64Text, String timeStr) {
    if (base64Text.isEmpty || timeStr.isEmpty) return null;

    try {
      final keyStr = timeStr.padRight(16, '0').substring(0, 16);

      final data = base64.decode(base64.normalize(base64Text));
      final aes = enc.Encrypter(enc.AES(
        enc.Key(Uint8List.fromList(utf8.encode(keyStr))),
        mode: enc.AESMode.ecb,
        padding: 'PKCS7',
      ));

      final decrypted = aes.decrypt(enc.Encrypted(data));
      return decrypted.replaceAll('\x00', '').trim();
    } catch (_) {
      return null;
    }
  }

  Future<void> _initRecorder() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      debugPrint('Microphone permission denied');
      return;
    }
    await _recorder.openRecorder();
    _recorderReady = true;
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
    await _player.setSubscriptionDuration(const Duration(milliseconds: 200));
    _progressSub = _player.onProgress?.listen(_handleProgress);
    _playerReady = true;
  }

  Future<void> _pickAndSendFile() async {
    if (_sending) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final _AttachChoice? choice = await showModalBottomSheet<_AttachChoice>(
      context: context,
      barrierColor: Colors.black54,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: const Text('Chọn tệp'),
                  onTap: () => Navigator.pop(context, _AttachChoice.file),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Thư viện (ảnh/video)'),
                  onTap: () => Navigator.pop(context, _AttachChoice.galleryMedia),
                ),
              ],
            ),
          ),
        );
      },
    );

    switch (choice) {
      case _AttachChoice.file:
        await _handlePickFile();
        break;
      case _AttachChoice.galleryMedia:
        await _handlePickMedia();
        break;
      default:
        return;
    }
  }

  Future<void> _handlePickFile() async {
    final res = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (res == null || res.files.isEmpty) return;
    final path = res.files.single.path;
    if (path == null) return;
    _addPendingAttachments([path]);
  }

  Future<void> _handlePickMedia() async {
    final picked = await _picker.pickMultipleMedia(requestFullMetadata: false) ?? <XFile>[];
    if (picked.isEmpty) return;
    _addPendingAttachments(picked.map((e) => e.path).toList());
  }

  void _addPendingAttachments(List<String> paths) {
    if (paths.isEmpty) return;
    final items = paths
        .where((p) => p.isNotEmpty)
        .map((p) => _PendingAttachment(path: p, type: _detectAttachmentType(p)))
        .toList();
    if (items.isEmpty) return;
    setState(() => _pendingAttachments.addAll(items));
  }

  _AttachmentType _detectAttachmentType(String path) {
    final ext = p.extension(path).toLowerCase();
    const img = {'.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp', '.heic', '.heif'};
    const vid = {'.mp4', '.mov', '.m4v', '.mkv', '.avi', '.webm', '.wmv'};
    if (img.contains(ext)) return _AttachmentType.image;
    if (vid.contains(ext)) return _AttachmentType.video;
    return _AttachmentType.file;
  }

  Future<void> _startRecording() async {
    if (_sending) return;

    if (!_recorderReady) {
      await _initRecorder();
      if (!_recorderReady) return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/page_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _draftPlayer.stopPlayer();
    HapticFeedback.mediumImpact();
    setState(() {
      _voiceDraftPath = null;
      _voiceDraftDuration = Duration.zero;
      _draftPos = Duration.zero;
      _draftDur = Duration.zero;
      _draftPlaying = false;

      _recElapsed = Duration.zero;
      _recOn = true;
      _recPaused = false;
    });

    await _recorder.startRecorder(
      toFile: path,
      codec: Codec.aacMP4,
      bitRate: 64000,
      sampleRate: 44100,
      numChannels: 1,
    );

    _startRecTimer();
    _recordingPath = path;
  }

  Future<void> _finishRecording({required SocialPageController pageCtrl, bool sendNow = false}) async {
    if (!_recOn) return;

    _stopRecTimer();
    final path = await _recorder.stopRecorder();
    final filePath = path ?? _recordingPath;
    _recordingPath = null;
    HapticFeedback.lightImpact();
    if (filePath == null) {
      if (!mounted) return;
      setState(() {
        _recOn = false;
        _recPaused = false;
        _recElapsed = Duration.zero;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _recOn = false;
      _recPaused = false;
      _voiceDraftPath = filePath;
      _voiceDraftDuration = _recElapsed > Duration.zero ? _recElapsed : _voiceDraftDuration;
      _recElapsed = Duration.zero;

      _draftPos = Duration.zero;
      _draftDur = Duration.zero;
      _draftPlaying = false;
    });

    if (sendNow) {
      await _sendVoiceDraft(pageCtrl);
    }
  }

  Future<void> _cancelRecording() async {
    if (_recOn) {
      _stopRecTimer();
      try { await _recorder.stopRecorder(); } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _recOn = false;
      _recPaused = false;
      _recElapsed = Duration.zero;
      _recordingPath = null;
    });
  }

  Future<void> _togglePauseRecording() async {
    if (!_recOn) return;
    try {
      if (_recPaused) {
        await _recorder.resumeRecorder();
        setState(() => _recPaused = false);
      } else {
        await _recorder.pauseRecorder();
        setState(() => _recPaused = true);
      }
    } catch (_) {}
  }

  Future<void> _sendAll(SocialPageController pageCtrl) async {
    if (_sending) return;

    final text = _inputCtrl.text.trim();
    final attachments = List<_PendingAttachment>.from(_pendingAttachments);
    final voicePath = _voiceDraftPath;

    if (text.isEmpty && attachments.isEmpty && voicePath == null) return;

    _inputCtrl.clear();
    setState(() {
      _pendingAttachments = [];
      _sending = true;
    });

    final locals = <Map<String, dynamic>>[];

    if (text.isNotEmpty) {
      locals.add(_makeLocalMsg(type: 'text', text: text));
    }

    for (final a in attachments) {
      locals.add(_makeLocalMsg(
        type: a.type == _AttachmentType.image
            ? 'image'
            : a.type == _AttachmentType.video
            ? 'video'
            : 'file',
        filePath: a.path,
      ));
    }

    if (voicePath != null) {
      locals.add(_makeLocalMsg(type: 'voice', filePath: voicePath, duration: _voiceDraftDuration));
    }

    setState(() {
      _localOutbox.addAll(locals);
    });

    final distFromBottom = _scrollCtrl.hasClients
        ? (_scrollCtrl.position.maxScrollExtent - _scrollCtrl.position.pixels)
        : 0.0;
    if (distFromBottom < 200) _scrollToBottomSmart();

    for (final local in locals) {
      final localId = local['local_id'] as int;

      try {
        final t = (local['local_type'] ?? '').toString();
        final file = (local['local_file_path'] ?? '').toString();
        final txt = (local['local_text'] ?? '').toString();

        if (t == 'text') {
          await pageCtrl.sendPageChatMessage(text: txt);
        } else if (t == 'voice') {
          final part = await MultipartFile.fromFile(file, filename: p.basename(file));
          await pageCtrl.sendPageChatMessage(voiceFile: part, text: '');
        } else {
          final part = await MultipartFile.fromFile(file, filename: p.basename(file));
          await pageCtrl.sendPageChatMessage(file: part, text: '');
        }

        if (!mounted) return;
        setState(() {
          _localOutbox.removeWhere((m) => (m['local_id'] ?? 0) == localId);
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          final idx = _localOutbox.indexWhere((m) => (m['local_id'] ?? 0) == localId);
          if (idx >= 0) {
            _localOutbox[idx]['local_status'] = 'failed';
            _localOutbox[idx]['local_error'] = '$e';
          }
        });
      }
    }

    if (mounted) {
      setState(() {
        _sending = false;
        _voiceDraftPath = null;
        _voiceDraftDuration = Duration.zero;
        _draftPos = Duration.zero;
        _draftDur = Duration.zero;
        _draftPlaying = false;
      });
    }

    _scrollToBottomSmart();
  }

  Future<void> _retryLocalOutbox(Map<String, dynamic> localMsg, SocialPageController pageCtrl) async {
    final localId = localMsg['local_id'];
    if (localId is! int) return;

    setState(() {
      final idx = _localOutbox.indexWhere((m) => (m['local_id'] ?? 0) == localId);
      if (idx >= 0) _localOutbox[idx]['local_status'] = 'sending';
    });

    try {
      final t = (localMsg['local_type'] ?? '').toString();
      final file = (localMsg['local_file_path'] ?? '').toString();
      final txt = (localMsg['local_text'] ?? '').toString();

      if (t == 'text') {
        await pageCtrl.sendPageChatMessage(text: txt);
      } else if (t == 'voice') {
        final part = await MultipartFile.fromFile(file, filename: p.basename(file));
        await pageCtrl.sendPageChatMessage(voiceFile: part, text: '');
      } else {
        final part = await MultipartFile.fromFile(file, filename: p.basename(file));
        await pageCtrl.sendPageChatMessage(file: part, text: '');
      }

      if (!mounted) return;
      setState(() {
        _localOutbox.removeWhere((m) => (m['local_id'] ?? 0) == localId);
      });
      _scrollToBottomSmart();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        final idx = _localOutbox.indexWhere((m) => (m['local_id'] ?? 0) == localId);
        if (idx >= 0) {
          _localOutbox[idx]['local_status'] = 'failed';
          _localOutbox[idx]['local_error'] = '$e';
        }
      });
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(e.toString()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageCtrl = context.watch<SocialPageController>();
    final List<SocialPageMessage> messages = pageCtrl.pageMessages;
    final items = <dynamic>[
      ...messages,
      ..._localOutbox,
    ];
    items.sort((a, b) {
      int ta = 0, tb = 0;
      if (a is SocialPageMessage) ta = a.time;
      if (a is Map) ta = int.tryParse('${a['time'] ?? 0}') ?? 0;
      if (b is SocialPageMessage) tb = b.time;
      if (b is Map) tb = int.tryParse('${b['time'] ?? 0}') ?? 0;
      return ta.compareTo(tb);
    });

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _openPageDetailFromChat,
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: widget.pageAvatar.isNotEmpty
                      ? CachedNetworkImageProvider(widget.pageAvatar, maxHeight: 160, maxWidth: 160)
                      : null,
                  child: widget.pageAvatar.isEmpty
                      ? Text(
                    widget.pageTitle.isNotEmpty ? widget.pageTitle[0].toUpperCase() : 'P',
                  )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _openPageDetailFromChat,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.pageTitle,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.pageSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: pageCtrl.loadingPageMessages
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                controller: _scrollCtrl,
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  if (_isLocalMsg(item)) {
                    final m = item as Map<String, dynamic>;
                    final status = (m['local_status'] ?? '').toString();
                    final isDark = Theme.of(context).brightness == Brightness.dark;

                    return KeyedSubtree(
                      key: ValueKey(_localMsgKey(m)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: status == 'failed' ? () => _retryLocalOutbox(m, pageCtrl) : null,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _buildLocalBubble(m, isDark: isDark),
                                    _localStatusLine(m),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final msg = item as SocialPageMessage;
                  final bool isMe = msg.position == "right";
                  final bool isImage = _isImageMessage(msg);
                  final bool isSticker = msg.stickers.isNotEmpty;
                  final bool isVoice = _isVoiceMessage(msg);

                  return KeyedSubtree(
                    key: ValueKey(_msgKey(msg)),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (msg.reply != null) _buildReplyBubble(msg.reply!, isMe),
                        if (isVoice)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: _buildVoiceBubble(msg, isMe),
                          )
                        else
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: EdgeInsets.symmetric(
                              horizontal: (isImage || isSticker) ? 0 : 12,
                              vertical: (isImage || isSticker) ? 0 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: (isImage || isSticker)
                                  ? Colors.transparent
                                  : isMe
                                  ? Colors.blue.shade600
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _buildMessageBody(msg, isMe),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_pendingAttachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: _buildPendingAttachments(),
              ),
            _buildInputArea(pageCtrl),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingAttachments() {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _pendingAttachments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final att = _pendingAttachments[index];
          return Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildAttachmentPreview(att),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: _sending
                      ? null
                      : () => setState(() => _pendingAttachments.removeAt(index)),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAttachmentPreview(_PendingAttachment att) {
    switch (att.type) {
      case _AttachmentType.image:
        return Image.file(
          File(att.path),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackPreview(att),
        );
      case _AttachmentType.video:
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.black12),
            const Center(child: Icon(Icons.play_circle_fill, size: 34, color: Colors.white70)),
          ],
        );
      default:
        return _fallbackPreview(att);
    }
  }

  Widget _fallbackPreview(_PendingAttachment att) {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file, size: 28, color: Colors.black54),
          const SizedBox(height: 6),
          Text(
            p.basename(att.path),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBody(SocialPageMessage msg, bool isMe) {
    if (_isVoiceMessage(msg)) {
      return _buildVoiceBubble(msg, isMe);
    }

    if (_isImageMessage(msg)) {
      final heroTag = _heroTagForNetImage(msg);

      return GestureDetector(
        onTap: () => _openImageViewer(heroTag: heroTag, url: msg.media),
        child: Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: msg.media,
              width: 240,
              height: 240,
              fit: BoxFit.cover,
              memCacheWidth: 480,
              placeholder: (_, __) => Container(
                width: 240,
                height: 240,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (_, __, ___) => Container(
                width: 240,
                height: 240,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
        ),
      );
    }

    if (msg.stickers.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: msg.stickers,
          width: 160,
          height: 160,
          fit: BoxFit.cover,
          memCacheWidth: 320,
          placeholder: (_, __) => const SizedBox(
            width: 160,
            height: 160,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (_, __, ___) => const SizedBox(
            width: 160,
            height: 160,
            child: Center(child: Icon(Icons.broken_image)),
          ),
        ),
      );
    }

    final txt = _plainTextOf(msg);

    return Text(
      txt.isNotEmpty ? txt : "[Media]",
      style: TextStyle(color: isMe ? Colors.white : Colors.black87),
    );
  }

  Widget _buildRecordingBar(SocialPageController pageCtrl, {required bool isDark}) {
    final grad = LinearGradient(
      colors: isDark
          ? const [Color(0xFF3F45C8), Color(0xFF3A2A7A)]
          : const [Color(0xFF5663FF), Color(0xFF6D3BFF)],
    );

    return Row(
      children: [
        IconButton(
          tooltip: 'Xóa',
          onPressed: _sending ? null : _cancelRecording,
          icon: const Icon(Icons.delete_outline),
        ),
        Expanded(
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: grad,
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 22,
                    onPressed: _sending
                        ? null
                        : () => _finishRecording(pageCtrl: pageCtrl, sendNow: false),
                    icon: const Icon(Icons.pause, color: Colors.black87),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DottedLine(
                    tick: _recElapsed.inSeconds,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(width: 10),
                Row(
                  children: [
                    _BlinkDot(),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(_recElapsed),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceDraftCard(SocialPageController pageCtrl, {required bool isDark}) {
    final theme = Theme.of(context);

    final Duration effectiveDur = _draftDur > Duration.zero
        ? _draftDur
        : (_voiceDraftDuration > Duration.zero ? _voiceDraftDuration : _draftPos);

    final double progress = (effectiveDur.inMilliseconds > 0)
        ? (_draftPos.inMilliseconds.clamp(0, effectiveDur.inMilliseconds) / effectiveDur.inMilliseconds)
        : 0;

    final cardBg = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0);
    final barBg = isDark ? const Color(0xFF151515) : const Color(0xFF1B1B1B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trượt lên waveform để phát từ bất kỳ điểm nào.',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(height: 10),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: barBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _toggleDraftPlay,
                  icon: Icon(
                    _draftPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: _WaveformSeekBar(
                    progress: progress,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white24,
                    maxHeight: 26,
                    samples: _generateWaveform(_voiceDraftPath ?? 'voice_preview'),
                    onSeekPercent: (p) async {
                      if (effectiveDur.inMilliseconds > 0) {
                        final ms = (p * effectiveDur.inMilliseconds).toInt();
                        await _draftPlayer.seekToPlayer(Duration(milliseconds: ms));
                        setState(() => _draftPos = Duration(milliseconds: ms));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(effectiveDur),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(width: 10),
                Container(width: 1, height: 40, color: Colors.white24),
                IconButton(
                  tooltip: 'Ghi lại',
                  onPressed: () async {
                    await _draftPlayer.stopPlayer();
                    setState(() {
                      _voiceDraftPath = null;
                      _voiceDraftDuration = Duration.zero;
                      _draftPos = Duration.zero;
                      _draftDur = Duration.zero;
                      _draftPlaying = false;
                    });
                    await _startRecording();
                  },
                  icon: const Icon(Icons.mic, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                tooltip: 'Xóa',
                onPressed: () async {
                  await _draftPlayer.stopPlayer();
                  setState(() {
                    _voiceDraftPath = null;
                    _voiceDraftDuration = Duration.zero;
                    _draftPos = Duration.zero;
                    _draftDur = Duration.zero;
                    _draftPlaying = false;
                  });
                },
                icon: const Icon(Icons.delete, color: Colors.redAccent),
              ),
              IconButton(
                tooltip: 'Ghi lại',
                onPressed: () async {
                  await _draftPlayer.stopPlayer();
                  setState(() {
                    _voiceDraftPath = null;
                    _voiceDraftDuration = Duration.zero;
                    _draftPos = Duration.zero;
                    _draftDur = Duration.zero;
                    _draftPlaying = false;
                  });
                  await _startRecording();
                },
                icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _sending ? null : () => _sendVoiceDraft(pageCtrl),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('Gửi', style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(width: 10),
                    Icon(Icons.send, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBubble(SocialPageReplyMessage reply, bool isMe) {
    final replyText = reply.text;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      width: 240,
      decoration: BoxDecoration(
        color: isMe ? Colors.white24 : Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        replyText.isNotEmpty ? replyText : "[Media]",
        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildInputArea(SocialPageController pageCtrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final barBg = isDark ? const Color(0xFF141414) : Colors.transparent;
    final inputFill = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.blue.shade200;
    final focusBorder = isDark ? Colors.white38 : Colors.blue.shade400;
    final hintColor = isDark ? Colors.white54 : Colors.black54;
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    final sendBg = Theme.of(context).colorScheme.primary;
    final Color bg = switch (_mode) {
      _ComposerMode.idle => barBg,
      _ComposerMode.recording => Colors.transparent,
      _ComposerMode.preview => Colors.transparent,
    };

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) {
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(anim);
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: _buildComposerByMode(
              key: ValueKey(_mode),
              pageCtrl: pageCtrl,
              isDark: isDark,
              inputFill: inputFill,
              borderColor: borderColor,
              focusBorder: focusBorder,
              hintColor: hintColor,
              iconColor: iconColor,
              sendBg: sendBg,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComposerByMode({
    required Key key,
    required SocialPageController pageCtrl,
    required bool isDark,
    required Color inputFill,
    required Color borderColor,
    required Color focusBorder,
    required Color hintColor,
    required Color iconColor,
    required Color sendBg,
  }) {
    if (_mode == _ComposerMode.recording) {
      return Container(
        key: key,
        child: _buildRecordingBar(pageCtrl, isDark: isDark),
      );
    }

    if (_mode == _ComposerMode.preview) {
      return Container(
        key: key,
        child: _buildVoiceDraftCard(pageCtrl, isDark: isDark),
      );
    }

    void _dismissKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

    return Container(
      key: key,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              enabled: !_sending,
              minLines: 1,
              maxLines: 5,
              cursorColor: isDark ? Colors.white : Colors.black,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: _sending ? 'Đang gửi...' : 'Nhập tin nhắn...',
                hintStyle: TextStyle(color: hintColor),
                isDense: true,
                filled: true,
                fillColor: inputFill,
                prefixIcon: IconButton(
                  icon: Icon(Icons.attach_file, color: iconColor),
                  onPressed: _sending
                      ? null
                      : () {
                    _dismissKeyboard();
                    _pickAndSendFile();
                  },
                ),
                suffixIcon: _MicPressButton(
                  color: iconColor,
                  disabled: _sending,
                  onTap: () {
                    _dismissKeyboard();
                    _startRecording();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: borderColor, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: borderColor, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: focusBorder, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              ),
              onSubmitted: (_) {
                _dismissKeyboard();
                _sendAll(pageCtrl);
              },
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: sendBg,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _sending
                  ? null
                  : () {
                _dismissKeyboard();
                _sendAll(pageCtrl);
              },
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.send, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildVoiceDraftPreview(SocialPageController pageCtrl) {
    final dur = _voiceDraftDuration > Duration.zero ? _voiceDraftDuration : _draftPos;
    final maxMs = dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1.0;
    final valMs = _draftPos.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_draftPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
            onPressed: _toggleDraftPlay,
          ),
          Expanded(
            child: Slider(
              value: valMs,
              max: maxMs,
              onChanged: (v) async {
                final d = Duration(milliseconds: v.toInt());
                await _draftPlayer.seekToPlayer(d);
                setState(() => _draftPos = d);
              },
            ),
          ),
          Text(_formatDuration(dur)),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              await _draftPlayer.stopPlayer();
              setState(() {
                _voiceDraftPath = null;
                _voiceDraftDuration = Duration.zero;
                _draftPos = Duration.zero;
                _draftPlaying = false;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: () => _sendVoiceDraft(pageCtrl),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleDraftPlay() async {
    if (_voiceDraftPath == null) return;

    if (_draftPlayer.isPlaying) {
      await _draftPlayer.pausePlayer();
      setState(() => _draftPlaying = false);
      return;
    }

    await _draftPlayer.startPlayer(
      fromURI: _voiceDraftPath,
      codec: Codec.aacMP4,
      whenFinished: () {
        if (!mounted) return;
        setState(() {
          _draftPlaying = false;
          _draftPos = Duration.zero;
        });
      },
    );
    setState(() => _draftPlaying = true);
  }

  Future<void> _sendVoiceDraft(SocialPageController pageCtrl, {bool manageSending = true}) async {
    if (_voiceDraftPath == null) return;
    if (manageSending && _sending) return;

    if (manageSending) setState(() => _sending = true);
    try {
      final voicePart = await MultipartFile.fromFile(
        _voiceDraftPath!,
        filename: p.basename(_voiceDraftPath!),
      );
      await pageCtrl.sendPageChatMessage(voiceFile: voicePart, text: '');
      await _draftPlayer.stopPlayer();

      setState(() {
        _voiceDraftPath = null;
        _voiceDraftDuration = Duration.zero;
        _draftPos = Duration.zero;
        _draftPlaying = false;
      });
      _scrollToBottom();
    } catch (e) {
      _showError(e);
    } finally {
      if (manageSending && mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;

      final target = _scrollCtrl.position.maxScrollExtent + 120;

      if (jump) {
        _scrollCtrl.jumpTo(target);
      } else {
        _scrollCtrl.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isVoiceMessage(SocialPageMessage msg) {
    final lower = msg.type.toLowerCase();
    final media = msg.media.toLowerCase();
    return lower.contains('voice') ||
        lower.contains('audio') ||
        media.endsWith('.aac') ||
        media.endsWith('.m4a') ||
        media.endsWith('.mp3') ||
        media.endsWith('.wav');
  }

  bool _isImageMessage(SocialPageMessage msg) {
    return msg.media.isNotEmpty &&
        (msg.media.endsWith('.jpg') ||
            msg.media.endsWith('.jpeg') ||
            msg.media.endsWith('.png') ||
            msg.media.endsWith('.gif') ||
            msg.media.endsWith('.webp'));
  }

  Widget _buildVoiceBubble(SocialPageMessage msg, bool isMe) {
    final url = msg.media;
    final bool isPlaying = _playingUrl == url && _player.isPlaying;

    final Duration total =
        _voiceDurations[url] ?? _durationFromMessage(msg) ?? Duration.zero;
    final Duration pos = _voicePositions[url] ?? Duration.zero;

    final Duration effectiveTotal = total > Duration.zero
        ? total
        : (pos > Duration.zero ? pos : const Duration(seconds: 1));

    final double progress = (effectiveTotal.inMilliseconds <= 0)
        ? 0
        : (pos.inMilliseconds.clamp(0, effectiveTotal.inMilliseconds) /
        effectiveTotal.inMilliseconds);

    final grad = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: isMe
          ? const [Color(0xFF5B6CFF), Color(0xFF6D3BFF)]
          : const [Color(0xFF5B6CFF), Color(0xFF6D3BFF)],
    );

    return Material(
      color: Colors.transparent,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          gradient: grad,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                shape: BoxShape.circle,
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _togglePlay(url, knownDuration: total),
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.black87,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),

            SizedBox(
              width: 140,
              child: _WaveformSeekBar(
                progress: progress.clamp(0.0, 1.0),
                activeColor: Colors.white.withOpacity(0.95),
                inactiveColor: Colors.white.withOpacity(0.35),
                maxHeight: 18,
                samples: _generateWaveform(url),
                onSeekPercent: effectiveTotal.inMilliseconds <= 0
                    ? null
                    : (p) async {
                  final ms = (p * effectiveTotal.inMilliseconds).toInt();
                  final d = Duration(milliseconds: ms);
                  await _player.seekToPlayer(d);
                  setState(() => _voicePositions[url] = d);
                },
              ),
            ),

            const SizedBox(width: 10),

            Text(
              _formatDuration(effectiveTotal),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePlay(String url, {Duration? knownDuration}) async {
    if (!_playerReady || url.isEmpty) return;

    if (_player.isPlaying) {
      await _player.stopPlayer();
      if (_playingUrl == url) {
        setState(() => _playingUrl = null);
        return;
      }
    }

    _playingUrl = url;
    _voicePositions[url] = Duration.zero;
    if (knownDuration != null) {
      _voiceDurations[url] = knownDuration;
    }
    await _player.startPlayer(
      fromURI: url,
      codec: Codec.aacADTS,
      whenFinished: () {
        if (mounted) {
          setState(() => _playingUrl = null);
        }
      },
    );
    if (mounted) {
      setState(() {});
    }
  }

  Duration? _durationFromMessage(SocialPageMessage msg) {
    final raw = msg.fileSize.trim();
    if (raw.isEmpty) return null;
    final RegExp mmss = RegExp(r'^(\\d{1,2}):(\\d{2})$');
    final m = mmss.firstMatch(raw);
    if (m != null) {
      final int minutes = int.tryParse(m.group(1)!) ?? 0;
      final int seconds = int.tryParse(m.group(2)!) ?? 0;
      return Duration(minutes: minutes, seconds: seconds);
    }
    return null;
  }

  String _formatDuration(Duration d) {
    int totalSeconds = d.inSeconds;
    if (totalSeconds < 0) totalSeconds = 0;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _handleProgress(dynamic event) {
    final url = _playingUrl;
    if (url == null) return;

    try {
      final Duration? pos = event.position;
      final Duration? dur = event.duration;

      if (dur != null && dur != Duration.zero) {
        _voiceDurations[url] = dur;
      }
      if (pos != null) {
        _voicePositions[url] = pos;
      }
    } catch (_) {}

    final now = DateTime.now();
    if (_lastProgressUi != null &&
        now.difference(_lastProgressUi!) < _progressUiThrottle) {
      return;
    }
    _lastProgressUi = now;

    if (mounted) setState(() {});
  }

  SocialGetPage? _findPageInCache(SocialPageController ctrl) {
    final pools = <SocialGetPage>[
      ...ctrl.myPages,
      ...ctrl.suggestedPages,
      ...ctrl.likedPages,
    ];

    for (final p in pools) {
      if (p.pageId == widget.pageId) return p;
    }
    return null;
  }

  Future<void> _openPageDetailFromChat() async {
    final ctrl = context.read<SocialPageController>();
    final page = _findPageInCache(ctrl);

    if (page == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin trang. Vui lòng quay lại danh sách Pages và mở lại.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SocialPageDetailScreen(page: page),
      ),
    );
  }

  void _openImageViewer({
    required String heroTag,
    String? url,
    String? filePath,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (_, __, ___) => _FullscreenImageViewer(
          heroTag: heroTag,
          url: url,
          filePath: filePath,
        ),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  String _heroTagForNetImage(SocialPageMessage msg) => 'img_${_msgKey(msg)}';
  String _heroTagForLocalImage(Map<String, dynamic> m) => 'img_${_localMsgKey(m)}';
}

List<double> _generateWaveform(String key, {int count = 32}) {
  final rnd = Random(key.hashCode);
  final List<double> values = [];
  for (int i = 0; i < count; i++) {
    final double base = 0.25 + rnd.nextDouble() * 0.75;
    values.add(base);
  }
  final List<double> mirrored = [
    ...values.take(count ~/ 2),
    ...(values.take(count - count ~/ 2).toList().reversed),
  ];
  return mirrored;
}

class _WaveformSeekBar extends StatelessWidget {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<double>? onSeekPercent;
  final double maxHeight;
  final List<double>? samples;

  const _WaveformSeekBar({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    this.onSeekPercent,
    this.maxHeight = 30,
    this.samples,
  });

  static const List<double> _basePattern = [
    0.25,0.35,0.45,0.6,0.75,0.9,1.0,0.9,0.8,1.0,0.9,0.75,0.6,0.45,0.35,0.25
  ];
  static const double _barWidth = 5;
  static const double _barSpacing = 6;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final List<double> pattern = samples ?? _basePattern;
        final double totalWidth = (_barWidth * pattern.length) + _barSpacing * (pattern.length - 1);
        final double available = constraints.maxWidth.isFinite ? constraints.maxWidth : totalWidth;
        final double scale = available / totalWidth;
        final int activeBars = (clamped * pattern.length).floor().clamp(0, pattern.length);

        Widget bars = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < pattern.length; i++) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: _barWidth * scale,
                height: (pattern[i].clamp(0.18, 1.0) * maxHeight) * scale,
                decoration: BoxDecoration(
                  color: i <= activeBars ? activeColor : inactiveColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              if (i != pattern.length - 1) SizedBox(width: _barSpacing * scale),
            ],
          ],
        );

        if (onSeekPercent == null) return bars;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (details) {
            final double dx = details.localPosition.dx.clamp(0.0, available);
            onSeekPercent!(dx / available);
          },
          child: SizedBox(width: available, child: bars),
        );
      },
    );
  }
}

class _DottedLine extends StatelessWidget {
  final int tick;
  final Color color;

  const _DottedLine({required this.tick, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth.isFinite ? c.maxWidth : 220.0;
        final count = (w / 6).floor().clamp(18, 60);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(count, (i) {
            final phase = (tick % 8);
            final dist = (i - (count - 1 - phase)).abs();
            final opacity = (dist <= 4) ? 0.45 : 0.95;

            return Container(
              width: 2.2,
              height: 2.2,
              decoration: BoxDecoration(
                color: color.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

enum _AttachmentType { image, video, file }

class _PendingAttachment {
  final String path;
  final _AttachmentType type;

  const _PendingAttachment({required this.path, required this.type});
}

class _MicPressButton extends StatefulWidget {
  final Color color;
  final bool disabled;
  final VoidCallback onTap;

  const _MicPressButton({
    required this.color,
    required this.disabled,
    required this.onTap,
  });

  @override
  State<_MicPressButton> createState() => _MicPressButtonState();
}

class _MicPressButtonState extends State<_MicPressButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.disabled
          ? null
          : (_) {
        HapticFeedback.selectionClick();
        setState(() => _down = true);
      },
      onTapCancel: () => setState(() => _down = false),
      onTapUp: widget.disabled
          ? null
          : (_) async {
        setState(() => _down = false);
        await Future.delayed(const Duration(milliseconds: 10));
        widget.onTap();
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 90),
        scale: _down ? 0.92 : 1.0,
        child: Icon(Icons.mic, color: widget.disabled ? widget.color.withOpacity(0.4) : widget.color),
      ),
    );
  }
}

class _BlinkDot extends StatefulWidget {
  @override
  State<_BlinkDot> createState() => _BlinkDotState();
}

class _BlinkDotState extends State<_BlinkDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_c),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _FullscreenImageViewer extends StatefulWidget {
  final String heroTag;
  final String? url;
  final String? filePath;

  const _FullscreenImageViewer({
    required this.heroTag,
    this.url,
    this.filePath,
  });

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer>
    with SingleTickerProviderStateMixin {
  final TransformationController _tc = TransformationController();

  late final AnimationController _anim =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 180));

  double _scale = 1.0;
  double _dragDy = 0.0;

  bool get _canDragToDismiss => _scale <= 1.01;

  @override
  void initState() {
    super.initState();
    _tc.addListener(_onMatrixChanged);
  }

  void _onMatrixChanged() {
    final m = _tc.value.storage;
    final sx = m[0]; // scale X
    if ((_scale - sx).abs() > 0.01) {
      setState(() => _scale = sx);
    }
  }

  @override
  void dispose() {
    _tc.removeListener(_onMatrixChanged);
    _tc.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _animateBack() {
    _anim.stop();
    final start = _dragDy;
    _anim.reset();
    _anim.addListener(() {
      setState(() {
        _dragDy = start * (1 - _anim.value);
      });
    });
    _anim.forward();
  }

  void _dismiss() {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final Widget imageChild = (widget.filePath != null && widget.filePath!.isNotEmpty)
        ? Image.file(File(widget.filePath!), fit: BoxFit.contain)
        : CachedNetworkImage(
      imageUrl: widget.url ?? '',
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
      errorWidget: (_, __, ___) =>
      const Center(child: Icon(Icons.broken_image, color: Colors.white)),
    );

    final double fade = (1 - (_dragDy / 280)).clamp(0.0, 1.0);
    final Color bg = Colors.black.withOpacity(0.95 * fade);
    final content = Center(
      child: Hero(
        tag: widget.heroTag,
        child: InteractiveViewer(
          transformationController: _tc,
          panEnabled: !_canDragToDismiss,
          minScale: 1.0,
          maxScale: 4.0,
          child: imageChild,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _dismiss,
                child: Container(color: bg),
              ),
            ),

            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragUpdate: (d) {
                  if (!_canDragToDismiss) return;
                  final next = (_dragDy + d.delta.dy);
                  setState(() => _dragDy = next.clamp(0.0, 420.0));
                },
                onVerticalDragEnd: (d) {
                  if (!_canDragToDismiss) return;

                  final v = d.primaryVelocity ?? 0.0;
                  final bool flingDown = v > 900;
                  final bool pulledEnough = _dragDy > 140;

                  if (flingDown || pulledEnough) {
                    _dismiss();
                  } else {
                    _animateBack();
                  }
                },
                child: Transform.translate(
                  offset: Offset(0, _dragDy),
                  child: content,
                ),
              ),
            ),

            Positioned(
              top: 10,
              right: 10,
              child: Material(
                color: Colors.white12,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _dismiss,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}