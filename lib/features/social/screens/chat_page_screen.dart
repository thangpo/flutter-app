import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as enc;   // 👈 thêm thư viện decrypt
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
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _recorder.closeRecorder();
    _progressSub?.cancel();
    _player.closePlayer();
    context.read<SocialPageController>().disposePageChat();
    super.dispose();
  }

  // ============================================================
  // 🔐 1) DECRYPT giống ChatScreen
  // ============================================================

  String _plainTextOf(SocialPageMessage m) {
    final raw = m.text.trim();
    final timeStr = m.time.toString();

    if (raw.isEmpty) return "";
    if (raw.startsWith("http")) return raw; // tránh decrypt media

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

  Future<void> _pickImage(SocialPageController pageCtrl) async {
    if (_sending) return;
    final XFile? x =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;

    setState(() => _sending = true);
    try {
      final file = await MultipartFile.fromFile(
        x.path,
        filename: p.basename(x.path),
      );
      await pageCtrl.sendPageChatMessage(file: file, text: '');
      _scrollToBottom();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleRecord(SocialPageController pageCtrl) async {
    if (!_recorderReady) {
      await _initRecorder();
      if (!_recorderReady) return;
    }

    if (!_recording) {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/page_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _recordingPath = path;
      await _recorder.startRecorder(toFile: path, codec: Codec.aacMP4);
      setState(() => _recording = true);
    } else {
      final path = await _recorder.stopRecorder();
      setState(() => _recording = false);
      final filePath = path ?? _recordingPath;
      _recordingPath = null;
      if (filePath == null) return;

      try {
        final voicePart = await MultipartFile.fromFile(
          filePath,
          filename: p.basename(filePath),
        );
        await pageCtrl.sendPageChatMessage(
          voiceFile: voicePart,
          text: '',
        );
        _scrollToBottom();
      } catch (e) {
        _showError(e);
      }
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

  // ============================================================
  // UI
  // ============================================================

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
          _buildInputArea(pageCtrl),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE BODY (UPDATE để dùng decrypt)
  // ============================================================

  Widget _buildMessageBody(SocialPageMessage msg, bool isMe) {
    if (_isVoiceMessage(msg)) {
      return _buildVoiceBubble(msg, isMe);
    }
    // 1) Ảnh
    if (msg.media.isNotEmpty &&
        (msg.media.endsWith(".jpg") ||
            msg.media.endsWith(".jpeg") ||
            msg.media.endsWith(".png") ||
            msg.media.endsWith(".gif") ||
            msg.media.endsWith(".webp"))) {
      return Image.network(msg.media, width: 240, fit: BoxFit.cover);
    }

    // 2) Sticker
    if (msg.stickers.isNotEmpty) {
      return Image.network(msg.stickers, width: 160);
    }

    // 3) TEXT — dùng decrypt
    final txt = _plainTextOf(msg);

    return Text(
      txt.isNotEmpty ? txt : "[Media]",
      style: TextStyle(color: isMe ? Colors.white : Colors.black87),
    );
  }

  // ============================================================
  // REPLY
  // ============================================================

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

  // ============================================================
  // INPUT
  // ============================================================

  Widget _buildInputArea(SocialPageController pageCtrl) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image),
              onPressed: () => _pickImage(pageCtrl),
            ),
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Nhập tin nhắn...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                _recording ? Icons.mic : Icons.mic_none,
                color: _recording ? Colors.red : null,
              ),
              onPressed: () => _toggleRecord(pageCtrl),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: _sending
                  ? null
                  : () async {
                      final text = _inputCtrl.text.trim();
                      if (text.isEmpty) return;

                      _inputCtrl.clear();
                      setState(() => _sending = true);
                      try {
                        await pageCtrl.sendPageChatMessage(text: text);
                        _scrollToBottom();
                      } catch (e) {
                        _showError(e);
                      } finally {
                        if (mounted) setState(() => _sending = false);
                      }
                    },
            )
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SCROLL
  // ============================================================

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
    // PlaybackDisposition has position/duration
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
      // ignore bad progress events
    }
  }

}
