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

/// Đối tượng hiển thị reaction gọn gàng
class _ReactionView {
  final String keyName;
  final String emoji;
  final int count;

  const _ReactionView({
    required this.keyName,
    required this.emoji,
    required this.count,
  });
}

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

  static const String kBaseUrl = 'https://social.vnshop247.com/';

  String _resolveMediaUrl(String s) {
    if (s.isEmpty) return s;
    if (s.startsWith('http') || s.startsWith('file://') || s.startsWith('/')) {
      return s;
    }
    if (s.startsWith('upload/')) return kBaseUrl + s;
    return s;
  }

  bool _isContentUri(String? uri) =>
      uri != null && uri.startsWith('content://');
  bool _isFileLike(String? uri) =>
      uri != null && (uri.startsWith('file://') || uri.startsWith('/'));
  bool _isLocalUri(String? uri) => _isContentUri(uri) || _isFileLike(uri);
  String _toLocalPath(String uri) =>
      uri.startsWith('file://') ? Uri.parse(uri).toFilePath() : uri;

  String get _media =>
      (message['media'] ?? message['media_url'] ?? '').toString();

  bool get _isImage => message['is_image'] == true;
  bool get _isVideo =>
      message['is_video'] == true || _looksLikeVideo(_resolveMediaUrl(_media));
  bool get _isAudio =>
      message['is_audio'] == true ||
      message['type_two']?.toString() == 'voice' ||
      _resolveMediaUrl(_media).toLowerCase().endsWith('.mp3') ||
      _resolveMediaUrl(_media).toLowerCase().endsWith('.m4a') ||
      _resolveMediaUrl(_media).toLowerCase().endsWith('.aac') ||
      _resolveMediaUrl(_media).toLowerCase().endsWith('.wav');
  bool get _isFile =>
      message['is_file'] == true ||
      ((!_isImage && !_isVideo && !_isAudio) && _media.isNotEmpty);

  bool get _uploading => message['uploading'] == true;
  bool get _failed => message['failed'] == true;

  bool _looksLikeVideo(String s) {
    final u = s.toLowerCase();
    return u.endsWith('.mp4') ||
        u.endsWith('.mov') ||
        u.endsWith('.mkv') ||
        u.endsWith('.webm') ||
        _isContentUri(s);
  }

  // 🔒 Decrypt
  static final RegExp _maybeBase64 = RegExp(r'^[A-Za-z0-9+/=]+$');
  Uint8List _keyBytes16(String keyStr) {
    final src = utf8.encode(keyStr);
    final out = Uint8List(16);
    for (int i = 0; i < src.length && i < 16; i++) {
      out[i] = src[i];
    }
    return out;
  }

  String _cleanB64(String s) =>
      s.replaceAll('-', '+').replaceAll('_', '/').replaceAll(' ', '+');
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
      return _stripZeroBytes(e.decrypt(encData, iv: enc.IV.fromLength(0)));
    } catch (_) {}
    return encText;
  }

  String _resolvedText() {
    final display = (message['display_text'] ?? '').toString();
    if (display.isNotEmpty) return display;
    final raw = (message['text'] ?? '').toString();
    final timeVal = message['time'];
    return _tryDecryptText(raw, timeVal);
  }

  Map<String, dynamic>? _tryParseZegoCallLog(String raw) {
    var s = raw.replaceAll(RegExp(r'[\u2063\u200b\u200c\u200d]'), '').trim();
    if (s.contains('&quot;')) {
      s = s.replaceAll('&quot;', '"').replaceAll('&amp;', '&');
    }
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start == -1 || end <= start) return null;
    s = s.substring(start, end + 1);
    try {
      final decoded = jsonDecode(s);
      if (decoded is! Map) return null;
      final map = decoded.map((k, v) => MapEntry(k.toString(), v));
      if ((map['type'] ?? '').toString() != 'zego_call_log') return null;
      final media = (map['media'] ?? '').toString().toLowerCase();
      if (media != 'audio' && media != 'video') return null;
      return map;
    } catch (_) {
      return null;
    }
  }

  // 🎬 Lazy video
  VideoPlayerController? _vp;
  bool _videoReady = false;
  bool _initializingVideo = false;

  Future<void> _initVideo() async {
    if (_initializingVideo || _videoReady || _media.isEmpty) return;
    _initializingVideo = true;
    setState(() {});
    final src = _resolveMediaUrl(_media);
    try {
      if (_isContentUri(src)) {
        _vp = VideoPlayerController.contentUri(Uri.parse(src));
      } else if (_isFileLike(src)) {
        _vp = VideoPlayerController.file(File(_toLocalPath(src)));
      } else {
        _vp = VideoPlayerController.networkUrl(Uri.parse(src));
      }
      await _vp!.initialize();
      await _vp!.setLooping(false);
      await _vp!.pause();
      _videoReady = true;
    } catch (_) {
    } finally {
      _initializingVideo = false;
      if (mounted) setState(() {});
    }
  }

  void _disposeVideo() {
    _vp?.dispose();
    _vp = null;
    _videoReady = false;
    _initializingVideo = false;
  }

  Future<void> _playOnTap() async {
    if (!_videoReady) await _initVideo();
    if (_vp == null) return;
    try {
      await _vp!.setVolume(1.0);
      await _vp!.play();
      setState(() {});
    } catch (_) {}
  }

  // 🔊 Audio
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

  // 📎 File
  Future<void> _openFileAttachment() async {
    final raw = _media;
    final name = (message['mediaFileName'] ?? '').toString();
    final src = _resolveMediaUrl(raw);
    if (src.isEmpty) return;
    if (_isLocalUri(src)) {
      await OpenFilex.open(_toLocalPath(src));
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${name.isEmpty ? 'file' : name}');
    final res = await http.get(Uri.parse(src));
    await file.writeAsBytes(res.bodyBytes);
    await OpenFilex.open(file.path);
  }

  // 🖼 Image
  void _openImagePreview() {
    final src = _resolveMediaUrl(_media);
    if (src.isEmpty) return;
    final isLocal = _isLocalUri(src);
    final imgWidget = isLocal
        ? Image.file(File(_toLocalPath(src)), fit: BoxFit.contain)
        : CachedNetworkImage(imageUrl: src, fit: BoxFit.contain);
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withOpacity(0.95),
      pageBuilder: (_, __, ___) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Hero(
              tag: src,
              child: InteractiveViewer(child: imgWidget),
            ),
          ),
        ),
      ),
    ));
  }

  @override
  void initState() {
    super.initState();
    if (_isAudio) _initVoice();
  }

  @override
  void dispose() {
    _disposeVideo();
    _disposeVoice();
    super.dispose();
  }

  // =============== REACTIONS UI ===============

  String? _emojiForReactionKey(String key) {
    switch (key.toLowerCase()) {
      case 'like':
        return '👍';
      case 'love':
        return '❤️';
      case 'haha':
        return '😂';
      case 'wow':
        return '😮';
      case 'sad':
        return '😢';
      case 'angry':
        return '😡';
      default:
        return null;
    }
  }

  List<_ReactionView> _extractReactions() {
    final result = <_ReactionView>[];

    dynamic raw = message['reaction'] ?? message['reactions'];
    if (raw == null) return result;

    // Case 1: Map kiểu Wo_GetPostReactionsTypes
    if (raw is Map) {
      raw.forEach((k, v) {
        final key = k.toString();
        if (key == 'all' || key == 'wondered' || key == 'is_reacted') return;
        int count = 0;
        if (v is Map && v['count'] != null) {
          count = int.tryParse('${v['count']}') ?? 0;
        } else if (v is int) {
          count = v;
        } else if (v is String) {
          count = int.tryParse(v) ?? 0;
        }
        if (count <= 0) return;
        final emoji = _emojiForReactionKey(key);
        if (emoji == null) return;
        result.add(_ReactionView(keyName: key, emoji: emoji, count: count));
      });
    }

    // Case 2: List các object {reaction: 'Like', count: X}
    else if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final key = (item['reaction'] ?? item['type'] ?? '').toString();
        if (key.isEmpty) continue;
        int count = 0;
        if (item['count'] != null) {
          count = int.tryParse('${item['count']}') ?? 0;
        }
        if (count <= 0) continue;
        final emoji = _emojiForReactionKey(key);
        if (emoji == null) continue;
        result.add(_ReactionView(keyName: key, emoji: emoji, count: count));
      }
    }

    return result;
  }

  Widget _buildReactionsStrip() {
    final items = _extractReactions();
    if (items.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 2, left: 4, right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < items.length && i < 3; i++) ...[
              Text(items[i].emoji, style: const TextStyle(fontSize: 13)),
              if (i < items.length - 1 && i < 2) const SizedBox(width: 2),
            ],
            const SizedBox(width: 4),
            Text(
              items.fold<int>(0, (sum, e) => sum + e.count).toString(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============== BUILD UI ===============

  @override
  Widget build(BuildContext context) {
    super.build(context);

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

    // 🔔 Tin nhắn hệ thống
    if (message['is_system'] == true) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Text(
            message['display_text'] ?? '',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Nội dung chính của bubble
    Widget baseContent;
    if (_isVideo) {
      baseContent = _buildVideo();
    } else if (_isImage) {
      baseContent = _buildImage();
    } else if (_isAudio) {
      baseContent = _buildVoice();
    } else if (_isFile) {
      baseContent = _buildFile();
    } else {
      baseContent = _buildText();
    }

    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isMediaBubble ? 0 : 10),
          decoration: BoxDecoration(color: bubbleColor, borderRadius: radius),
          child: baseContent,
        ),
        const SizedBox(height: 2),
        _buildReactionsStrip(),
        const SizedBox(height: 2),
        if (message['is_local'] == true && _uploading)
          Text(
            'Đang gửi…',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        if (_failed)
          const Text(
            'Gửi thất bại',
            style: TextStyle(fontSize: 11, color: Colors.red),
          ),
      ],
    );
  }

  Widget _buildText() {
    final raw = _resolvedText();
    final callLog = _tryParseZegoCallLog(raw);
    if (callLog != null) return _buildZegoCallLogBubble(callLog);

    return Text(
      raw.isEmpty ? ' ' : raw,
      style: TextStyle(
        fontSize: 15,
        height: 1.35,
        color: isMe ? Colors.white : const Color(0xFF050505),
      ),
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
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildVideo() {
    final ready = _videoReady && _vp != null && _vp!.value.isInitialized;
    final src = _resolveMediaUrl(_media);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 240,
        child: AspectRatio(
          aspectRatio: ready ? _vp!.value.aspectRatio : 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.black),
              if (ready) VideoPlayer(_vp!),
              if (!ready && !_initializingVideo)
                Center(
                  child: InkWell(
                    onTap: _playOnTap,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(10),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              if (_initializingVideo)
                const Center(child: CircularProgressIndicator()),
              if (ready)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: VideoProgressIndicator(
                    _vp!,
                    allowScrubbing: true,
                  ),
                ),
              if (_uploading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.05),
                          Colors.black.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (ready)
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      if (_vp == null) return;
                      if (_vp!.value.isPlaying) {
                        await _vp!.pause();
                      } else {
                        await _vp!.play();
                      }
                      setState(() {});
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70, width: 1.2),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        _vp!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZegoCallLogBubble(Map<String, dynamic> log) {
    final media = (log['media'] ?? 'audio').toString();
    final isVideo = media == 'video';
    final bg = widget.isMe ? const Color(0xFF2F80ED) : const Color(0xFFEFEFEF);
    final fg = widget.isMe ? Colors.white : Colors.black87;

    final groupName = (log['group_name'] ?? '').toString().trim();

    final title = widget.isMe
        ? (isVideo ? 'Bạn đã gọi video' : 'Bạn đã gọi thoại')
        : (isVideo ? 'Cuộc gọi video' : 'Cuộc gọi thoại');

    final subtitle =
        groupName.isNotEmpty ? 'Nhóm: $groupName' : 'ZEGOCLOUD Call';

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(isVideo ? Icons.videocam : Icons.call, color: fg),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: fg,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: fg.withOpacity(0.7), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: content,
    );
  }

  Widget _buildVoice() {
    final bg = isMe ? const Color(0xFF0084FF) : const Color(0xFFE4E6EB);
    final textColor = isMe ? Colors.white : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      width: 230,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_vLoading)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: bg.withOpacity(0.4),
              valueColor: AlwaysStoppedAnimation<Color>(
                isMe ? Colors.white : Colors.black87,
              ),
            ),
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
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _vPlaying ? Icons.pause : Icons.play_arrow,
                    color: bg,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 26,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 12),
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
                              await _ap!
                                  .seek(Duration(milliseconds: v.toInt()));
                            },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _fmt(_dur),
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      width: 300,
      child: InkWell(
        onTap: _openFileAttachment,
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFE0E3EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.insert_drive_file,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Tệp đính kèm' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (sizeStr.isNotEmpty)
                    Text(
                      sizeStr,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.download_rounded,
              color: Color(0xFF6B7280),
            ),
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
