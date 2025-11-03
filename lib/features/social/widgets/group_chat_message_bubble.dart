// G:\flutter-app\lib\features\social\widgets\group_chat_message_bubble.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:encrypt/encrypt.dart' as enc;

class ChatMessageBubble extends StatefulWidget {
  final Map<String, dynamic> message;
  final bool isMe;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  Map<String, dynamic> get message => widget.message;
  bool get isMe => widget.isMe;

  bool _isLocalUri(String? uri) {
    if (uri == null) return false;
    return uri.startsWith('file://') ||
        uri.startsWith('/') ||
        uri.startsWith('content://');
  }

  String _toLocalPath(String uri) {
    return uri.startsWith('file://') ? Uri.parse(uri).toFilePath() : uri;
  }

  String get _media {
    final m = (message['media'] ?? '').toString();
    if (m.isNotEmpty) return m;
    return (message['media_url'] ?? '').toString();
  }

  bool get _isImage => message['is_image'] == true;
  bool get _isVideo => message['is_video'] == true;
  bool get _isAudio =>
      (message['is_audio'] == true) ||
      (message['type_two']?.toString() == 'voice');
  bool get _isFile =>
      message['is_file'] == true ||
      ((!_isImage && !_isVideo && !_isAudio) && _media.isNotEmpty);
  bool get _uploading => message['uploading'] == true;
  bool get _failed => message['failed'] == true;

  // ---------- Decrypt WoWonder ----------
  static final RegExp _maybeBase64 = RegExp(r'^[A-Za-z0-9+/=]+$');

  Uint8List _keyBytes16(String keyStr) {
    final src = utf8.encode(keyStr); // decimal string of time()
    final out = Uint8List(16);
    final n = src.length > 16 ? 16 : src.length;
    for (int i = 0; i < n; i++) {
      out[i] = src[i];
    }
    return out;
  }

  String _cleanB64(String s) {
    return s
        .replaceAll('-', '+')
        .replaceAll('_', '/')
        .replaceAll(' ', '+')
        .replaceAll('\n', '');
  }

  String _stripZeroBytes(String s) {
    final bytes = utf8.encode(s);
    int end = bytes.length;
    while (end > 0 && bytes[end - 1] == 0) end--;
    return utf8.decode(bytes.sublist(0, end), allowMalformed: true);
  }

  String _tryDecryptText(String encText, dynamic timeVal) {
    if (encText.isEmpty) return encText;

    final keyStr = '${timeVal ?? ''}';
    if (keyStr.isEmpty) return encText;

    final b64 = _cleanB64(encText);
    if (!_maybeBase64.hasMatch(b64) || b64.length % 4 != 0) {
      return encText;
    }

    final key = enc.Key(_keyBytes16(keyStr));
    final encData = enc.Encrypted.fromBase64(b64);

    try {
      final e =
          enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb, padding: 'PKCS7'));
      return e.decrypt(encData, iv: enc.IV.fromLength(0));
    } catch (_) {}

    try {
      final e =
          enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb, padding: null));
      final out = e.decrypt(encData, iv: enc.IV.fromLength(0));
      if (out.isNotEmpty) return out;
    } catch (_) {}

    try {
      final e =
          enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb, padding: null));
      final out = e.decrypt(encData, iv: enc.IV.fromLength(0));
      return _stripZeroBytes(out);
    } catch (_) {}

    return encText;
  }

  String _resolvedText() {
    final display = (message['display_text'] ?? '').toString();
    if (display.isNotEmpty) return display;

    final raw = (message['text'] ?? '').toString();
    final timeVal = message['time'];
    if (raw.isEmpty) return '';

    return _tryDecryptText(raw, timeVal);
  }

  // ---------------- video ----------------
  VideoPlayerController? _vp;
  ChewieController? _chewie;

  Future<void> _initVideo() async {
    _disposeVideo();
    if (_media.isEmpty) return;

    try {
      if (_isLocalUri(_media)) {
        _vp = VideoPlayerController.file(File(_toLocalPath(_media)));
      } else {
        _vp = VideoPlayerController.networkUrl(Uri.parse(_media));
      }
      await _vp!.initialize();
      _chewie = ChewieController(
        videoPlayerController: _vp!,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        materialProgressColors: ChewieProgressColors(),
      );
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _disposeVideo() {
    _chewie?.dispose();
    _vp?.dispose();
    _chewie = null;
    _vp = null;
  }

  // ---------------- audio/voice ----------------
  AudioPlayer? _ap;
  Duration _pos = Duration.zero, _dur = Duration.zero;
  bool _vLoading = false, _vPlaying = false;

  Future<void> _initVoice() async {
    _disposeVoice();
    if (_media.isEmpty) return;

    _ap = AudioPlayer();
    _ap!.positionStream
        .listen((d) => mounted ? setState(() => _pos = d) : null);
    _ap!.durationStream.listen(
        (d) => mounted ? setState(() => _dur = d ?? Duration.zero) : null);
    _ap!.playerStateStream.listen((st) {
      final playing = st.playing && st.processingState == ProcessingState.ready;
      if (mounted) setState(() => _vPlaying = playing);
    });

    setState(() => _vLoading = true);
    try {
      if (_isLocalUri(_media)) {
        await _ap!.setAudioSource(AudioSource.uri(Uri.parse(_media)));
      } else {
        await _ap!.setUrl(_media);
      }
    } finally {
      if (mounted) setState(() => _vLoading = false);
    }
  }

  void _disposeVoice() {
    _ap?.dispose();
    _ap = null;
    _pos = Duration.zero;
    _dur = Duration.zero;
    _vPlaying = false;
  }

  // ---------------- file open/download ----------------
  double _dlProgress = 0;
  bool _downloading = false;

  Future<File?> _downloadToTemp(String url, {String? filename}) async {
    setState(() {
      _downloading = true;
      _dlProgress = 0;
    });
    try {
      final req = await http.Client().send(http.Request('GET', Uri.parse(url)));
      final total = req.contentLength ?? 0;
      final dir = await getTemporaryDirectory();
      final name = (filename?.trim().isNotEmpty == true)
          ? filename!.trim()
          : url.split('?').first.split('/').last;
      final file = File('${dir.path}/$name');
      final sink = file.openWrite();

      int received = 0;
      await for (final chunk in req.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (total > 0) {
          setState(() => _dlProgress = received / total);
        }
      }
      await sink.close();
      return file;
    } catch (_) {
      return null;
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _openFileAttachment() async {
    final name = (message['mediaFileName'] ?? '').toString();
    if (_media.isEmpty) return;

    if (_isLocalUri(_media)) {
      final path = _toLocalPath(_media);
      await OpenFilex.open(path);
      return;
    }

    final f =
        await _downloadToTemp(_media, filename: name.isEmpty ? null : name);
    if (f == null) return;
    await OpenFilex.open(f.path);
  }

  // ---------------- image preview ----------------
  void _openImagePreview() {
    if (_media.isEmpty) return;
    final tag = _media; // hero tag
    final isLocal = _isLocalUri(_media);
    final imgWidget = isLocal
        ? Image.file(File(_toLocalPath(_media)))
        : CachedNetworkImage(imageUrl: _media);

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.95),
        pageBuilder: (_, __, ___) {
          return GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: Center(
                  child: Hero(
                    tag: tag,
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.8,
                      maxScale: 5,
                      child: imgWidget,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- lifecycle ----------------
  @override
  void initState() {
    super.initState();
    if (_isVideo) _initVideo();
    if (_isAudio) _initVoice();
  }

  @override
  void didUpdateWidget(covariant ChatMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldSrc = (oldWidget.message['media'] ?? '').toString();
    final curSrc = _media;

    final oldIsVideo = (oldWidget.message['is_video'] == true) ||
        oldSrc.endsWith('.mp4') ||
        oldSrc.endsWith('.mov') ||
        oldSrc.endsWith('.mkv');
    final curIsVideo = _isVideo;

    final oldIsAudio = (oldWidget.message['is_audio'] == true) ||
        (oldWidget.message['type_two']?.toString() == 'voice') ||
        oldSrc.endsWith('.mp3') ||
        oldSrc.endsWith('.m4a') ||
        oldSrc.endsWith('.aac') ||
        oldSrc.endsWith('.wav');
    final curIsAudio = _isAudio;

    if (curIsVideo && (!oldIsVideo || oldSrc != curSrc)) {
      _initVideo();
    }
    if (curIsAudio && (!oldIsAudio || oldSrc != curSrc)) {
      _initVoice();
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    _disposeVoice();
    super.dispose();
  }

  // ---------------- UI builders ----------------
  @override
  Widget build(BuildContext context) {
    final bubbleColor =
        isMe ? const Color(0xFFE7F3FF) : const Color(0xFFF2F2F2);
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: isMe ? const Radius.circular(14) : const Radius.circular(4),
      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(14),
    );

    Widget content;
    if (_isImage) {
      content = _buildImage();
    } else if (_isVideo) {
      content = _buildVideo();
    } else if (_isAudio) {
      content = _buildVoice();
    } else if (_isFile) {
      content = _buildFile();
    } else {
      content = _buildText();
    }

    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(_isImage || _isVideo ? 4 : 10),
          decoration: BoxDecoration(color: bubbleColor, borderRadius: radius),
          child: content,
        ),
        const SizedBox(height: 4),
        if (message['is_local'] == true && _uploading)
          Text('Đang gửi…',
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        if (_failed)
          const Text('Gửi thất bại',
              style: TextStyle(fontSize: 11, color: Colors.red)),
      ],
    );
  }

  Widget _buildText() {
    final text = _resolvedText();
    return SelectableText(
      text.isEmpty ? ' ' : text,
      style: const TextStyle(fontSize: 15, height: 1.35),
    );
  }

  Widget _buildImage() {
    final child = _isLocalUri(_media)
        ? Image.file(File(_toLocalPath(_media)), fit: BoxFit.cover)
        : CachedNetworkImage(imageUrl: _media, fit: BoxFit.cover);

    return GestureDetector(
      onTap: _openImagePreview,
      child: Hero(
        tag: _media,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: child,
              ),
            ),
            if (_uploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideo() {
    final hasController =
        _vp != null && _vp!.value.isInitialized && _chewie != null;
    return SizedBox(
      width: 240,
      child: AspectRatio(
        aspectRatio: hasController ? _vp!.value.aspectRatio : 16 / 9,
        child: Stack(
          children: [
            if (hasController)
              Chewie(controller: _chewie!)
            else
              const Center(child: CircularProgressIndicator()),
            if (_uploading)
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoice() {
    final name = (message['mediaFileName'] ?? 'voice.m4a').toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (_vLoading) const LinearProgressIndicator(minHeight: 2),
        Row(
          children: [
            IconButton(
              icon: Icon(_vPlaying ? Icons.pause_circle : Icons.play_circle),
              onPressed: _ap == null
                  ? null
                  : () async {
                      if (_vPlaying) {
                        await _ap!.pause();
                      } else {
                        if (_ap!.audioSource == null) await _initVoice();
                        await _ap!.play();
                      }
                    },
            ),
            Expanded(
              child: Slider(
                value: _pos.inMilliseconds
                    .clamp(0, _dur.inMilliseconds)
                    .toDouble(),
                max: (_dur.inMilliseconds == 0 ? 1 : _dur.inMilliseconds)
                    .toDouble(),
                onChanged: _ap == null
                    ? null
                    : (v) async {
                        final seek = Duration(milliseconds: v.toInt());
                        await _ap!.seek(seek);
                      },
              ),
            ),
            Text('${_fmt(_pos)} / ${_fmt(_dur)}',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildFile() {
    final name = (message['mediaFileName'] ?? '').toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.insert_drive_file),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name.isEmpty ? 'Tệp đính kèm' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: _openFileAttachment,
              icon: const Icon(Icons.download),
              label: const Text('Mở'),
            ),
          ],
        ),
        if (_downloading)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: LinearProgressIndicator(
                value: _dlProgress == 0 ? null : _dlProgress),
          ),
      ],
    );
  }
}
