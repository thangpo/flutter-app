import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class ChatMessageBubble extends StatefulWidget {
  final Map<String, dynamic> message; // m đã được hydrate ở repository
  final bool isMe; // căn phải/trái theo vị trí người gửi

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

  Future<void> _openExternal(String url) async {
    final ok = await canLaunchUrl(Uri.parse(url));
    if (ok)
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(18);
    final bg = widget.isMe ? const Color(0xFF1976D2) : const Color(0xFFEFEFEF);
    final fg = widget.isMe ? Colors.white : Colors.black87;

    final bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Column(
        crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // ====== IMAGE ======
          if (_isImage && _mediaUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: GestureDetector(
                onTap: () => _openExternal(_mediaUrl),
                child: CachedNetworkImage(
                  imageUrl: _mediaUrl,
                  fit: BoxFit.cover,
                  placeholder: (c, _) => Container(
                    height: 180,
                    color: Colors.black12,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(),
                    ),
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
                aspectRatio: _videoReady ? _vp!.value.aspectRatio : 16 / 9,
                child: _videoReady
                    ? Chewie(controller: _chewie!)
                    : Container(
                        color: Colors.black12,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(),
                        ),
                      ),
              ),
            ),

          // ====== AUDIO ======
          if (_isAudio && _mediaUrl.isNotEmpty)
            _buildAudioPlayer(
                bg: bg, fg: widget.isMe ? Colors.white : Colors.black87),

          // ====== TEXT / TÀI LIỆU (filename) ======
          if (_text.isNotEmpty)
            Container(
              margin: EdgeInsets.only(
                  top: (_isImage || _isVideo || _isAudio) ? 8 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.only(
                  topLeft: radius,
                  topRight: radius,
                  bottomLeft: widget.isMe ? radius : const Radius.circular(4),
                  bottomRight: widget.isMe ? const Radius.circular(4) : radius,
                ),
              ),
              child: GestureDetector(
                onTap: () {
                  // Nếu là tài liệu: có media_url -> mở
                  if (!_isImage &&
                      !_isVideo &&
                      !_isAudio &&
                      _mediaUrl.isNotEmpty) {
                    _openExternal(_mediaUrl);
                  }
                },
                child: Text(
                  _text,
                  style: TextStyle(color: fg, fontSize: 15),
                ),
              ),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
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
                size: 30),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: pos.clamp(0, dur).toDouble(),
                  min: 0,
                  max: dur.toDouble(),
                  onChanged: !_audioInited
                      ? null
                      : (v) async {
                          await _audio.seek(Duration(seconds: v.toInt()));
                        },
                ),
                Text(
                  _fmt(_audioPos) + ' / ' + _fmt(_audioDur),
                  style: TextStyle(color: fg.withOpacity(0.9), fontSize: 12),
                ),
              ],
            ),
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
