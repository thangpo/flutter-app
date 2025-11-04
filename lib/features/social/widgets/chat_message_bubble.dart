import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

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
  // VIDEO
  VideoPlayerController? _vp;
  ChewieController? _chewie;
  bool _videoReady = false;

  // AUDIO
  final _audio = AudioPlayer();
  bool _audioInited = false;
  bool _audioPlaying = false;
  Duration _audioPos = Duration.zero;
  Duration _audioDur = Duration.zero;

  Map<String, dynamic> get m => widget.message;
  String get _text => (m['display_text'] ?? '').toString();
  String get _mediaUrl => (m['media_url'] ?? '').toString();
  bool get _isImage => m['is_image'] == true;
  bool get _isVideo => m['is_video'] == true;
  bool get _isAudio => m['is_audio'] == true;

  @override
  void initState() {
    super.initState();
    if (_isVideo && _mediaUrl.isNotEmpty) _initVideo();
    if (_isAudio && _mediaUrl.isNotEmpty) _initAudio();
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _vp?.dispose();
    _audio.dispose();
    super.dispose();
  }

  Future<void> _initVideo() async {
    try {
      _vp = VideoPlayerController.networkUrl(Uri.parse(_mediaUrl));
      await _vp!.initialize();
      _chewie = ChewieController(
        videoPlayerController: _vp!,
        autoPlay: false,
        looping: false,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(),
      );
      if (mounted) setState(() => _videoReady = true);
    } catch (_) {}
  }

  Future<void> _initAudio() async {
    try {
      await _audio.setUrl(_mediaUrl);
      _audioDur = await _audio.duration ?? Duration.zero;
      _audioInited = true;
      _audio.positionStream.listen((p) {
        if (!mounted) return;
        setState(() => _audioPos = p);
      });
      _audio.playerStateStream.listen((s) {
        if (!mounted) return;
        setState(() => _audioPlaying = s.playing);
      });
      setState(() {});
    } catch (_) {}
  }

  Future<void> _openFile(String url) async {
    try {
      final uri = Uri.parse(url);
      final filename = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : 'file_${DateTime.now().millisecondsSinceEpoch}';

      // 🕓 Hiển thị SnackBar tải file
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang tải tệp...')),
      );

      // 📥 Tải file về thư mục tạm
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$filename';
      final file = File(filePath);

      if (!await file.exists()) {
        final response = await http.get(uri);
        await file.writeAsBytes(response.bodyBytes);
      }

      // 📂 Mở file đã tải
      final result = await OpenFilex.open(file.path);

      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở tệp: ${result.message}')),
        );
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi mở file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở tệp này')),
      );
    }
  }

  Future<void> _openImageFull(String url) async {
    await showDialog(
      context: context,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: InteractiveViewer(
            child: CachedNetworkImage(imageUrl: url),
          ),
        ),
      ),
    );
  }

  Future<void> _openPdfInline(String url) async {
    final temp = await getTemporaryDirectory();
    final file = File('${temp.path}/${url.split('/').last}');
    if (!await file.exists()) {
      final res = await http.get(Uri.parse(url));
      await file.writeAsBytes(res.bodyBytes);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: PDFView(filePath: file.path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(18);
    final bg = widget.isMe ? const Color(0xFF2F80ED) : const Color(0xFFEFEFEF);
    final fg = widget.isMe ? Colors.white : Colors.black87;

    final bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Column(
        crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // ====== IMAGE ======
          if (_isImage && _mediaUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: GestureDetector(
                onTap: () => _openImageFull(_mediaUrl),
                child: CachedNetworkImage(
                  imageUrl: _mediaUrl,
                  fit: BoxFit.cover,
                  placeholder: (c, _) => Container(
                    height: 220,
                    color: Colors.black12,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  ),
                  errorWidget: (c, _, __) => Container(
                    height: 120,
                    color: Colors.black12,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),

          // ====== VIDEO ======
          if (_isVideo && _mediaUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: _videoReady ? _vp!.value.aspectRatio : 1,
                child: _videoReady
                    ? Chewie(controller: _chewie!)
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),

          // ====== AUDIO ======
          if (_isAudio && _mediaUrl.isNotEmpty)
            _buildAudioPlayer(bg: bg, fg: fg),

          // ====== FILE / TEXT ======
          // ====== TEXT / FILE ======
          if (!_isImage && !_isVideo && !_isAudio) ...[
            if (_mediaUrl.isNotEmpty)
              GestureDetector(
                onTap: () => _openFile(_mediaUrl),
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _text.isNotEmpty
                        ? _text
                        : (m['mediaFileName']
                                    ?.toString()
                                    .toLowerCase()
                                    .endsWith('.pdf') ??
                                false)
                            ? '📄 Mở tài liệu PDF'
                            : '📎 Tệp đính kèm',
                    style: TextStyle(
                      color: fg,
                      fontSize: 15,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              )
            else if (_text.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _text,
                  style: TextStyle(color: fg, fontSize: 15),
                ),
              ),
          ]

        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisAlignment:
            widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [bubble],
      ),
    );
  }

  Widget _buildAudioPlayer({required Color bg, required Color fg}) {
    final pos = _audioPos.inSeconds;
    final dur = _audioDur.inSeconds == 0 ? 1 : _audioDur.inSeconds;

    return Container(
      width: 200,
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(2, 2))
        ],
      ),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: !_audioInited
                ? null
                : () async {
                    if (_audioPlaying) {
                      await _audio.pause();
                    } else {
                      await _audio.play();
                    }
                  },
            icon: Icon(
                _audioPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
                color: fg,
                size: 26),
          ),
          Expanded(
            child: Slider(
              value: pos.toDouble().clamp(0, dur.toDouble()),
              min: 0,
              max: dur.toDouble(),
              activeColor: Colors.white,
              inactiveColor: Colors.white24,
              onChanged: !_audioInited
                  ? null
                  : (v) async {
                      await _audio.seek(Duration(seconds: v.toInt()));
                    },
            ),
          ),
          Text(
            _fmt(_audioPos),
            style: TextStyle(color: fg.withOpacity(0.9), fontSize: 11),
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
}
