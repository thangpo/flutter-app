import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' show FontFeature;
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

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<SocialPageController>().initPageChat(
        pageId: widget.pageId,
        recipientId: widget.recipientId,
      );
      _initRecorder();
      _initPlayer();
      _draftPlayer.openPlayer().then((_) async {
        await _draftPlayer.setSubscriptionDuration(const Duration(milliseconds: 200));
        _draftSub = _draftPlayer.onProgress?.listen((e) {
          if (!mounted) return;
          setState(() => _draftPos = e.position ?? Duration.zero);
        });
      });
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _recorder.closeRecorder();
    _progressSub?.cancel();
    _player.closePlayer();
    _recTimer?.cancel();
    _draftSub?.cancel();
    _draftPlayer.closePlayer();
    context.read<SocialPageController>().disposePageChat();
    super.dispose();
  }

  void _startRecTimer() {
    _recTimer?.cancel();
    _recElapsed = Duration.zero;
    _recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _recElapsed += const Duration(seconds: 1));
    });
  }

  void _stopRecTimer() {
    _recTimer?.cancel();
    _recTimer = null;
  }


  String _plainTextOf(SocialPageMessage m) {
    final raw = m.text.trim();
    final timeStr = m.time.toString();

    if (raw.isEmpty) return "";
    if (raw.startsWith("http")) return raw;

    final dec = _tryDecryptWoWonder(raw, timeStr);
    return dec ?? raw;
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

  Future<void> _pickMedia() async {
    if (_sending) return;

    final List<XFile> picked =
    await _picker.pickMultipleMedia(requestFullMetadata: false);
    if (picked.isEmpty) return;

    setState(() {
      _pendingAttachments.addAll(
        picked.map((x) => _PendingAttachment(
          path: x.path,
          type: _detectAttachmentType(x.path),
        )),
      );
    });
  }

  _AttachmentType _detectAttachmentType(String path) {
    final ext = p.extension(path).toLowerCase();
    const img = {'.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp', '.heic', '.heif'};
    const vid = {'.mp4', '.mov', '.m4v', '.mkv', '.avi', '.webm', '.wmv'};
    if (img.contains(ext)) return _AttachmentType.image;
    if (vid.contains(ext)) return _AttachmentType.video;
    return _AttachmentType.file;
  }

  Future<void> _toggleRecord(SocialPageController pageCtrl) async {
    if (!_recorderReady) {
      await _initRecorder();
      if (!_recorderReady) return;
    }

    if (!_recording) {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/page_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _recordingPath = path;
      await _draftPlayer.stopPlayer();
      await _recorder.startRecorder(toFile: path, codec: Codec.aacMP4);
      _startRecTimer();

      setState(() {
        _voiceDraftPath = null;
        _voiceDraftDuration = Duration.zero;
        _draftPos = Duration.zero;
        _draftPlaying = false;
        _recording = true;
      });
    } else {
      _stopRecTimer();

      final path = await _recorder.stopRecorder();
      final filePath = path ?? _recordingPath;
      _recordingPath = null;

      if (filePath == null) {
        setState(() => _recording = false);
        return;
      }

      setState(() {
        _recording = false;
        _voiceDraftPath = filePath;
        _voiceDraftDuration = _recElapsed;
        _draftPos = Duration.zero;
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

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.pageAvatar.isNotEmpty
                  ? NetworkImage(widget.pageAvatar)
                  : null,
              child: widget.pageAvatar.isEmpty
                  ? Text(widget.pageTitle.isNotEmpty
                  ? widget.pageTitle[0].toUpperCase()
                  : 'P')
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.pageTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16)),
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
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final msg = messages[i];
                final bool isMe = msg.position == "right";
                final bool isImage = _isImageMessage(msg);
                final bool isSticker = msg.stickers.isNotEmpty;

                if (i == messages.length - 1) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottom());
                }

                return Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (msg.reply != null)
                      _buildReplyBubble(msg.reply!, isMe),

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
                );
              },
            ),
          ),
          if (_pendingAttachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: _buildPendingAttachments(),
            ),
          if (_voiceDraftPath != null && !_recording)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: _buildVoiceDraftPreview(pageCtrl),
            ),
          _buildInputArea(pageCtrl),
        ],
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
    if (msg.media.isNotEmpty &&
        (msg.media.endsWith(".jpg") ||
            msg.media.endsWith(".jpeg") ||
            msg.media.endsWith(".png") ||
            msg.media.endsWith(".gif") ||
            msg.media.endsWith(".webp"))) {
      return Image.network(msg.media, width: 240, fit: BoxFit.cover);
    }

    if (msg.stickers.isNotEmpty) {
      return Image.network(msg.stickers, width: 160);
    }

    final txt = _plainTextOf(msg);

    return Text(
      txt.isNotEmpty ? txt : "[Media]",
      style: TextStyle(color: isMe ? Colors.white : Colors.black87),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final barBg = isDark ? const Color(0xFF141414) : Colors.transparent;
    final inputFill = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    final borderColor = isDark ? Colors.white24 : Colors.blue.shade200;
    final focusBorder = isDark ? Colors.white38 : Colors.blue.shade400;

    final hintColor = isDark ? Colors.white54 : Colors.black54;
    final iconColor = isDark ? Colors.white70 : Colors.black54;

    final sendBg = theme.colorScheme.primary;

    Future<void> doSend() async {
      final text = _inputCtrl.text.trim();
      final hasText = text.isNotEmpty;
      final hasAtt = _pendingAttachments.isNotEmpty;
      final hasVoice = _voiceDraftPath != null;

      if (_sending) return;
      if (!hasText && !hasAtt && !hasVoice) return;

      _inputCtrl.clear();
      setState(() => _sending = true);

      try {
        if (hasText) {
          await pageCtrl.sendPageChatMessage(text: text);
        }

        if (hasAtt) {
          final items = List<_PendingAttachment>.from(_pendingAttachments);
          for (final att in items) {
            final part = await MultipartFile.fromFile(
              att.path,
              filename: p.basename(att.path),
            );
            await pageCtrl.sendPageChatMessage(file: part, text: '');
          }
          if (mounted) setState(() => _pendingAttachments.clear());
        }

        if (hasVoice) {
          await _sendVoiceDraft(pageCtrl, manageSending: false);
        }

        _scrollToBottom();
      } catch (e) {
        _showError(e);
      } finally {
        if (mounted) setState(() => _sending = false);
      }
    }

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Container(
        decoration: BoxDecoration(
          color: barBg,
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
                  hintText: _sending ? "Đang gửi..." : "Nhập tin nhắn...",
                  hintStyle: TextStyle(color: hintColor),
                  isDense: true,
                  filled: true,
                  fillColor: inputFill,

                  prefixIcon: IconButton(
                    icon: Icon(Icons.attach_file, color: iconColor),
                    onPressed: _sending ? null : _pickMedia,
                  ),

                  suffixIcon: IconButton(
                    icon: Icon(Icons.mic, color: iconColor),
                    onPressed: _sending ? null : () => _toggleRecord(pageCtrl),
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
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                ),
                onSubmitted: (_) => doSend(),
              ),
            ),
            const SizedBox(width: 8),

            Material(
              color: sendBg,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _sending ? null : doSend,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.send, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 120,
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
    final bool isPlaying = _playingUrl == msg.media && _player.isPlaying;
    final Duration total =
        _voiceDurations[msg.media] ?? _durationFromMessage(msg) ?? Duration.zero;
    final Duration position =
        _voicePositions[msg.media] ?? Duration.zero;
    final String label = _formatDuration(
      total > Duration.zero ? total : position,
    );

    final double max = total.inMilliseconds == 0
        ? 1
        : total.inMilliseconds.toDouble();
    final double value = position.inMilliseconds.clamp(0, max).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isMe ? Colors.blue.shade600 : Colors.blue.shade500,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            constraints: const BoxConstraints(),
            iconSize: 28,
            splashRadius: 22,
            icon: Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: Colors.white,
            ),
            onPressed: () => _togglePlay(msg.media, knownDuration: total),
          ),
          SizedBox(
            width: 110,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: value,
                max: max,
                onChanged: total.inMilliseconds == 0
                    ? null
                    : (v) async {
                        final Duration seekTo =
                            Duration(milliseconds: v.toInt());
                        await _player.seekToPlayer(seekTo);
                        setState(() {
                          _voicePositions[msg.media] = seekTo;
                        });
                      },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
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
    final String? url = _playingUrl;
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
      if (mounted) setState(() {});
    } catch (_) {

    }
  }
}

enum _AttachmentType { image, video, file }

class _PendingAttachment {
  final String path;
  final _AttachmentType type;

  const _PendingAttachment({required this.path, required this.type});
}