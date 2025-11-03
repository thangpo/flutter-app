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

  // ======== helpers ========
  bool _isLocalUri(String? uri) {
    if (uri == null) return false;
    return uri.startsWith('file://') ||
        uri.startsWith('/') ||
        uri.startsWith('content://');
  }

  String _toLocalPath(String uri) =>
      uri.startsWith('file://') ? Uri.parse(uri).toFilePath() : uri;

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

  // ======== decrypt WoWonder ========
  static final RegExp _maybeBase64 = RegExp(r'^[A-Za-z0-9+/=]+$');

  Uint8List _keyBytes16(String keyStr) {
    final src = utf8.encode(keyStr);
    final out = Uint8List(16);
    final n = src.length > 16 ? 16 : src.length;
    for (int i = 0; i < n; i++) {
      out[i] = src[i];
    }
    return out;
  }

  String _cleanB64(String s) => s
      .replaceAll('-', '+')
      .replaceAll('_', '/')
      .replaceAll(' ', '+')
      .replaceAll('\n', '');

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
    if (!_maybeBase64.hasMatch(b64) || b64.length % 4 != 0) return encText;

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

  // ======== video ========
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

  // ======== audio ========
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

  // ======== file open/download ========
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
        if (total > 0) setState(() => _dlProgress = received / total);
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

  // ======== lifecycle ========
  @override
  void initState() {
    super.initState();
    if (_isVideo) _initVideo();
    // audio: lazy init khi bấm play để mượt hơn
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

    if (curIsVideo && (!oldIsVideo || oldSrc != curSrc)) _initVideo();
    if (curIsAudio && (!oldIsAudio || oldSrc != curSrc)) {
      // lazy: không auto init voice
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    _disposeVoice();
    super.dispose();
  }

  // ======== styles ========
  static const _meBlue = Color(0xFF2F80ED); // xanh như ảnh
  Color get _bubbleColor => (_isImage || _isVideo)
      ? Colors.transparent
      : (isMe ? _meBlue : const Color(0xFFF2F2F2));

  Color get _textColor => (_isImage || _isVideo)
      ? Colors.black87
      : (isMe ? Colors.white : Colors.black87);

  BorderRadius get _radius => BorderRadius.circular(16);

  TextStyle get _textStyle =>
      TextStyle(fontSize: 15, height: 1.35, color: _textColor);

  // ======== UI builders ========
  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_isImage) {
      content = _buildImage();
    } else if (_isVideo) {
      content = _buildVideo();
    } else if (_isAudio) {
      content = _buildVoicePill(); // pill xanh như ảnh
    } else if (_isFile) {
      content = _buildFilePill(); // pill xanh như ảnh
    } else {
      content = _buildTextBubble();
    }

    // Với image/video: không bọc nền xanh để giống screenshot
    final wrap = (_isImage || _isVideo)
        ? content
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration:
                BoxDecoration(color: _bubbleColor, borderRadius: _radius),
            child: content,
          );

    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        wrap,
        const SizedBox(height: 6),
        if (message['is_local'] == true && _uploading)
          Text('Đang gửi…',
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        if (_failed)
          const Text('Gửi thất bại',
              style: TextStyle(fontSize: 11, color: Colors.red)),
      ],
    );
  }

  // ---- text (blue/gray bubble) ----
  Widget _buildTextBubble() {
    final text = _resolvedText();
    return SelectableText(text.isEmpty ? ' ' : text, style: _textStyle);
  }

  // ---- image (rounded, no blue bg) ----
  Widget _buildImage() {
    final child = _isLocalUri(_media)
        ? Image.file(File(_toLocalPath(_media)), fit: BoxFit.cover)
        : CachedNetworkImage(imageUrl: _media, fit: BoxFit.cover);

    return ClipRRect(
      borderRadius: _radius,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(aspectRatio: 4 / 3, child: child),
          if (_uploading)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  // ---- video (rounded, no blue bg) ----
  Widget _buildVideo() {
    final hasController =
        _vp != null && _vp!.value.isInitialized && _chewie != null;
    return ClipRRect(
      borderRadius: _radius,
      child: SizedBox(
        width: 260,
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
                      child: const Center(child: CircularProgressIndicator())),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- voice pill (blue) ----
  Widget _buildVoicePill() {
    final baseText = TextStyle(color: _textColor, fontWeight: FontWeight.w600);
    final timeText =
        TextStyle(color: _textColor.withOpacity(0.9), fontSize: 12);
    final sliderTheme = SliderTheme.of(context).copyWith(
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      overlayShape: SliderComponentShape.noOverlay,
      activeTrackColor: isMe ? Colors.white : Colors.black87,
      inactiveTrackColor:
          (isMe ? Colors.white : Colors.black87).withOpacity(0.35),
      thumbColor: isMe ? Colors.white : Colors.black87,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          padding: EdgeInsets.zero,
          icon: Icon(
              _vPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: _textColor,
              size: 28),
          onPressed: () async {
            if (_ap == null || _ap!.audioSource == null) await _initVoice();
            if (_vPlaying) {
              await _ap!.pause();
            } else {
              await _ap!.play();
            }
          },
        ),
        SizedBox(
          width: 140,
          child: SliderTheme(
            data: sliderTheme,
            child: Slider(
              value:
                  _pos.inMilliseconds.clamp(0, _dur.inMilliseconds).toDouble(),
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
        ),
        const SizedBox(width: 6),
        Text(_fmt(_vPlaying ? _pos : Duration.zero),
            style: timeText), // 00:00 như ảnh
      ],
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ---- file pill (blue) ----
  Widget _buildFilePill() {
    final name = (message['mediaFileName'] ?? '').toString();
    final display = name.isEmpty ? 'Tệp đính kèm' : name;

    final titleStyle = TextStyle(
      color: _textColor,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline, // giống link
      height: 1.15,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.insert_drive_file, color: _textColor),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 190),
          child: Text(
            display,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: _openFileAttachment,
          icon: Icon(Icons.download, color: _textColor, size: 18),
          label: Text('Mở',
              style: TextStyle(color: _textColor, fontWeight: FontWeight.w600)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}
