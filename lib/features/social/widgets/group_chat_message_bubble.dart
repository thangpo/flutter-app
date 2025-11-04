// G:\flutter-app\lib\features\social\widgets\group_chat_message_bubble.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
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

class _ChatMessageBubbleState extends State<ChatMessageBubble>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Map<String, dynamic> get message => widget.message;
  bool get isMe => widget.isMe;

  // Base URL cho các path tương đối (upload/...)
  static const String kBaseUrl = 'https://social.vnshop247.com/';

  // Ghép URL tuyệt đối
  String _resolveMediaUrl(String s) {
    if (s.isEmpty) return s;
    if (s.startsWith('http://') ||
        s.startsWith('https://') ||
        s.startsWith('file://') ||
        s.startsWith('/')) {
      return s;
    }
    if (s.startsWith('upload/')) {
      return kBaseUrl + s;
    }
    return s;
  }

  bool _isContentUri(String? uri) =>
      uri != null && uri.startsWith('content://');
  bool _isFileLike(String? uri) =>
      uri != null && (uri.startsWith('file://') || uri.startsWith('/'));
  bool _isLocalUri(String? uri) => _isContentUri(uri) || _isFileLike(uri);
  String _toLocalPath(String uri) =>
      uri.startsWith('file://') ? Uri.parse(uri).toFilePath() : uri;

  String get _media {
    final m = (message['media'] ?? '').toString();
    if (m.isNotEmpty) return m;
    return (message['media_url'] ?? '').toString();
  }

  bool get _isImage => message['is_image'] == true;
  bool _looksLikeVideo(String s) {
    final u = s.toLowerCase();
    return u.endsWith('.mp4') ||
        u.endsWith('.mov') ||
        u.endsWith('.mkv') ||
        u.endsWith('.webm') ||
        _isContentUri(s);
  }

  bool get _isVideo {
    final src = _resolveMediaUrl(_media);
    return (message['is_video'] == true) || _looksLikeVideo(src);
  }

  bool get _isAudio {
    final src = _resolveMediaUrl(_media).toLowerCase();
    return (message['is_audio'] == true) ||
        (message['type_two']?.toString() == 'voice') ||
        src.endsWith('.mp3') ||
        src.endsWith('.m4a') ||
        src.endsWith('.aac') ||
        src.endsWith('.wav');
  }

  bool get _isFile =>
      message['is_file'] == true ||
      ((!_isImage && !_isVideo && !_isAudio) && _media.isNotEmpty);

  bool get _uploading => message['uploading'] == true;
  bool get _failed => message['failed'] == true;

  // ---------- Decrypt ----------
  static final RegExp _maybeBase64 = RegExp(r'^[A-Za-z0-9+/=]+$');
  Uint8List _keyBytes16(String keyStr) {
    final src = utf8.encode(keyStr);
    final out = Uint8List(16);
    final n = src.length > 16 ? 16 : src.length;
    for (int i = 0; i < n; i++) out[i] = src[i];
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

  // ---------------- VIDEO: VideoPlayer (no autoplay) ----------------
  VideoPlayerController? _vp;
  bool _videoReady = false;
  bool _videoInitializing = false;
  bool _userStarted = false;

  Future<File?> _downloadTempVideo(String url) async {
    try {
      final dir = await getTemporaryDirectory();
      final name = url.split('?').first.split('/').last;
      final file = File('${dir.path}/$name');
      if (await file.exists()) return file;
      final req = await http.Client().send(http.Request('GET', Uri.parse(url)));
      final sink = file.openWrite();
      await req.stream.pipe(sink);
      await sink.close();
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<void> _initVideo() async {
    if (_videoInitializing || _videoReady || _media.isEmpty) return;
    _videoInitializing = true;
    if (mounted) setState(() {});

    final src = _resolveMediaUrl(_media);
    // debugPrint('[VIDEO SRC] $src');

    Future<VideoPlayerController> _buildCtrl() async {
      if (_isContentUri(src)) {
        return VideoPlayerController.contentUri(
          Uri.parse(src),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      } else if (_isFileLike(src)) {
        return VideoPlayerController.file(
          File(_toLocalPath(src)),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      } else {
        return VideoPlayerController.networkUrl(
          Uri.parse(src),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          // headers tuỳ chọn nếu server nhạy UA/CORS/Range
          httpHeaders: const {
            'User-Agent': 'VNShop247/1.0 (Flutter-VideoPlayer)',
          },
        );
      }
    }

    try {
      _vp = await _buildCtrl();
      await _vp!.initialize();
      await _vp!.setLooping(false);
      await _vp!.pause(); // ❗ không tự chạy trong chat
      await _vp!.seekTo(Duration.zero);
      _videoReady = true;
    } catch (_) {
      if (!_isLocalUri(src) &&
          (src.startsWith('http://') || src.startsWith('https://'))) {
        try {
          final f = await _downloadTempVideo(src);
          if (f != null) {
            _vp = VideoPlayerController.file(
              f,
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
            );
            await _vp!.initialize();
            await _vp!.setLooping(false);
            await _vp!.pause();
            await _vp!.seekTo(Duration.zero);
            _videoReady = true;
          }
        } catch (_) {}
      }
    } finally {
      _videoInitializing = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _playOnTap() async {
    if (_vp == null) return;
    try {
      _userStarted = true;
      await _vp!.setVolume(1.0);
      await _vp!.play();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _disposeVideo() {
    _vp?.dispose();
    _vp = null;
    _videoReady = false;
    _videoInitializing = false;
    _userStarted = false;
  }

  // ---------------- audio/voice ----------------
  AudioPlayer? _ap;
  Duration _pos = Duration.zero, _dur = Duration.zero;
  bool _vLoading = false, _vPlaying = false;

  Future<void> _initVoice() async {
    _disposeVoice();
    final src = _resolveMediaUrl(_media);
    if (src.isEmpty) return;

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
      if (_isLocalUri(src)) {
        await _ap!.setAudioSource(AudioSource.uri(Uri.parse(src)));
      } else {
        await _ap!.setUrl(src);
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
    final raw = _media;
    final name = (message['mediaFileName'] ?? '').toString();
    final src = _resolveMediaUrl(raw);
    if (src.isEmpty) return;

    if (_isLocalUri(src)) {
      final path = _toLocalPath(src);
      await OpenFilex.open(path);
      return;
    }

    final f = await _downloadToTemp(src, filename: name.isEmpty ? null : name);
    if (f == null) return;
    await OpenFilex.open(f.path);
  }

  void _openImagePreview() {
    final src = _resolveMediaUrl(_media);
    if (src.isEmpty) return;

    final isLocal = _isLocalUri(src);
    final imgWidget = isLocal
        ? Image.file(File(_toLocalPath(src)), fit: BoxFit.contain)
        : CachedNetworkImage(imageUrl: src, fit: BoxFit.contain);

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
                    tag: src,
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
    if (_isAudio) _initVoice();
    if (_isVideo) _initVideo(); // ❗ KHÔNG autoplay
  }

  @override
  void didUpdateWidget(covariant ChatMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldSrc =
        (oldWidget.message['media'] ?? oldWidget.message['media_url'] ?? '')
            .toString();
    final curSrc = _media;

    final oldIsAudio = (oldWidget.message['is_audio'] == true) ||
        (oldWidget.message['type_two']?.toString() == 'voice') ||
        _resolveMediaUrl(oldSrc).toLowerCase().endsWith('.mp3') ||
        _resolveMediaUrl(oldSrc).toLowerCase().endsWith('.m4a') ||
        _resolveMediaUrl(oldSrc).toLowerCase().endsWith('.aac') ||
        _resolveMediaUrl(oldSrc).toLowerCase().endsWith('.wav');
    final curIsAudio = _isAudio;

    if (curIsAudio && (!oldIsAudio || oldSrc != curSrc)) {
      _initVoice();
    }

    final oldIsVideo = (oldWidget.message['is_video'] == true) ||
        _looksLikeVideo(_resolveMediaUrl(oldSrc));
    if (_isVideo && (!oldIsVideo || oldSrc != curSrc)) {
      _disposeVideo();
      _initVideo(); // ❗ KHÔNG autoplay khi đổi nguồn
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    _disposeVoice();
    super.dispose();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    super.build(context); // keepAlive
    final isMediaBubble = _isImage || _isVideo;
    final bubbleColor = (_isAudio || _isFile || isMediaBubble)
        ? Colors.transparent
        : (isMe ? const Color(0xFF0084FF) : const Color(0xFFF0F2F5));

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: isMe ? const Radius.circular(14) : const Radius.circular(4),
      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(14),
    );

    Widget content;
    if (_isVideo) {
      content = _buildVideo();
    } else if (_isImage) {
      content = _buildImage();
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
          padding: EdgeInsets.all(isMediaBubble ? 0 : 10),
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
      style: TextStyle(
          fontSize: 15,
          height: 1.35,
          color: isMe ? Colors.white : const Color(0xFF050505)),
    );
  }

  Widget _buildImage() {
    final src = _resolveMediaUrl(_media);
    final child = _isLocalUri(src)
        ? Image.file(File(_toLocalPath(src)), fit: BoxFit.cover)
        : CachedNetworkImage(imageUrl: src, fit: BoxFit.cover);

    return GestureDetector(
      onTap: _openImagePreview,
      child: Hero(
        tag: src,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(aspectRatio: 4 / 3, child: child),
        ),
      ),
    );
  }

  Widget _buildVideo() {
    final ready = _videoReady && _vp != null && _vp!.value.isInitialized;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 260,
        child: AspectRatio(
          aspectRatio: ready ? _vp!.value.aspectRatio : 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.black),
              if (!ready && _videoInitializing)
                const Center(child: CircularProgressIndicator()),

              if (ready) VideoPlayer(_vp!),

              // Nút Play lớn ở giữa, chỉ hiện khi chưa user-started hoặc đang pause
              if (ready && (!_userStarted || !_vp!.value.isPlaying))
                Center(
                  child: InkWell(
                    onTap: _playOnTap,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow,
                          size: 48, color: Colors.white),
                    ),
                  ),
                ),

              // Thanh tiến trình
              if (ready)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: VideoProgressIndicator(
                    _vp!,
                    allowScrubbing: true,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                ),

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
      ),
    );
  }

  Widget _buildVoice() {
    final bg = isMe ? const Color(0xFF0084FF) : const Color(0xFFE4E6EB);

    return Container(
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_vLoading)
            const LinearProgressIndicator(minHeight: 2, color: Colors.white),
          Row(
            children: [
              InkWell(
                onTap: _ap == null
                    ? null
                    : () async {
                        if (_vPlaying) {
                          await _ap!.pause();
                        } else {
                          if (_ap!.audioSource == null) await _initVoice();
                          await _ap!.play();
                        }
                      },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: Icon(_vPlaying ? Icons.pause : Icons.play_arrow,
                      color: bg),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    overlayColor: Colors.white30,
                  ),
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
              ),
              const SizedBox(width: 10),
              Text(_fmt(_dur),
                  style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildFile() {
    final name = (message['mediaFileName'] ?? '').toString().trim();
    final sizeAny =
        message['file_size'] ?? message['size'] ?? message['media_size'];
    final sizeStr =
        (sizeAny is int) ? _readableSize(sizeAny) : (sizeAny?.toString() ?? '');

    return Container(
      decoration: BoxDecoration(
          color: isMe ? const Color(0xFFDCEAFF) : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      width: 300,
      child: InkWell(
        onTap: _openFileAttachment,
        borderRadius: BorderRadius.circular(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                  color: Color(0xFFE0E3EB), shape: BoxShape.circle),
              child:
                  const Icon(Icons.insert_drive_file, color: Color(0xFF6B7280)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isEmpty ? 'Tệp đính kèm' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    if (sizeStr.isNotEmpty)
                      Text(sizeStr,
                          style: const TextStyle(
                              color: Color(0xFF6B7280), fontSize: 12)),
                  ]),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.download_rounded, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }

  String _readableSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double v = bytes.toDouble();
    int i = 0;
    while (v >= 1024 && i < units.length - 1) {
      v /= 1024;
      i++;
    }
    return '${v.toStringAsFixed(v < 10 && i > 0 ? 1 : 0)} ${units[i]}';
  }
}
