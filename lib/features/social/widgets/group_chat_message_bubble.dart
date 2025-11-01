// G:\flutter-app\lib\features\social\widgets\group_chat_message_bubble.dart

import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class GroupChatMessageBubble extends StatefulWidget {
  final Map<String, dynamic> message;
  final bool isMe;

  const GroupChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  State<GroupChatMessageBubble> createState() => _GroupChatMessageBubbleState();
}

class _GroupChatMessageBubbleState extends State<GroupChatMessageBubble> {
  Map<String, dynamic> get message => widget.message;
  bool get isMe => widget.isMe;

  String get _media => (message['media'] ?? '').toString();

  bool _isLocalUri(String? uri) {
    if (uri == null) return false;
    return uri.startsWith('file://') ||
        uri.startsWith('/') ||
        uri.startsWith('content://');
  }

  String _toLocalPath(String uri) {
    return uri.startsWith('file://') ? Uri.parse(uri).toFilePath() : uri;
  }

  bool get _looksImageByExt {
    final m = _media.toLowerCase();
    return m.endsWith('.jpg') ||
        m.endsWith('.jpeg') ||
        m.endsWith('.png') ||
        m.endsWith('.gif') ||
        m.endsWith('.webp') ||
        m.contains('mime=image');
  }

  bool get _looksVideoByExt {
    final m = _media.toLowerCase();
    return m.endsWith('.mp4') || m.endsWith('.mov') || m.endsWith('.mkv');
  }

  bool get _looksAudioByExt {
    final m = _media.toLowerCase();
    return m.endsWith('.mp3') ||
        m.endsWith('.m4a') ||
        m.endsWith('.aac') ||
        m.endsWith('.wav');
  }

  bool get _isImage =>
      message['is_image'] == true || (_looksImageByExt && !_looksVideoByExt);
  bool get _isVideo =>
      message['is_video'] == true || (_looksVideoByExt && !_looksAudioByExt);
  bool get _isAudio =>
      message['is_audio'] == true ||
      (message['type_two']?.toString() == 'voice') ||
      (_looksAudioByExt && !_looksVideoByExt);
  bool get _isFile =>
      message['is_file'] == true ||
      ((!_isImage && !_isVideo && !_isAudio) && _media.isNotEmpty);

  bool get _uploading => message['uploading'] == true;
  bool get _failed => message['failed'] == true;

  // video
  VideoPlayerController? _vp;
  ChewieController? _chewie;

  Future<void> _initVideo() async {
    _disposeVideo();
    final src = _media;
    if (src.isEmpty) return;

    try {
      if (_isLocalUri(src)) {
        _vp = VideoPlayerController.file(File(_toLocalPath(src)));
      } else {
        _vp = VideoPlayerController.networkUrl(Uri.parse(src));
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

  // audio
  AudioPlayer? _ap;
  Duration _pos = Duration.zero, _dur = Duration.zero;
  bool _vLoading = false, _vPlaying = false;

  Future<void> _initVoice() async {
    _disposeVoice();
    _ap = AudioPlayer();
    _ap!.positionStream
        .listen((d) => mounted ? setState(() => _pos = d) : null);
    _ap!.durationStream.listen(
        (d) => mounted ? setState(() => _dur = d ?? Duration.zero) : null);
    _ap!.playerStateStream.listen((st) {
      final playing = st.playing && st.processingState == ProcessingState.ready;
      if (mounted) setState(() => _vPlaying = playing);
    });

    final src = _media;
    if (src.isEmpty) return;

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

  // file open/download
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
    final uri = _media;
    final name = (message['mediaFileName'] ?? '').toString();
    if (uri.isEmpty) return;

    if (_isLocalUri(uri)) {
      await OpenFilex.open(_toLocalPath(uri));
      return;
    }

    final f = await _downloadToTemp(uri, filename: name.isEmpty ? null : name);
    if (f == null) return;
    await OpenFilex.open(f.path);
  }

  @override
  void initState() {
    super.initState();
    if (_isVideo) _initVideo();
    if (_isAudio) _initVoice();
  }

  @override
  void didUpdateWidget(covariant GroupChatMessageBubble oldWidget) {
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
    final text = (message['display_text'] ?? message['text'] ?? '').toString();
    return SelectableText(
      text.isEmpty ? ' ' : text,
      style: const TextStyle(fontSize: 15, height: 1.35),
    );
  }

  Widget _buildImage() {
    final uri = _media;

    Widget child;
    if (_isLocalUri(uri)) {
      final f = File(_toLocalPath(uri));
      child = f.existsSync()
          ? Image.file(f, fit: BoxFit.cover)
          : const Center(child: Icon(Icons.image_outlined));
    } else {
      child = CachedNetworkImage(imageUrl: uri, fit: BoxFit.cover);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(aspectRatio: 4 / 3, child: child),
        ),
        if (_uploading)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
      ],
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
                child: IgnorePointer(
                  ignoring: true,
                  child: Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
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
                        await _ap!.seek(Duration(milliseconds: v.toInt()));
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
