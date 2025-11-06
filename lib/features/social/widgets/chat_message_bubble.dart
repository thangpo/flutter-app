import 'dart:convert';
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
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/call_invite.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/call_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/call_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/incoming_call_screen.dart';



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

  /// text hiển thị từ server (đã qua normalize/decrypt)
  String get _text =>
      (m['display_text'] ?? m['text'] ?? m['message'] ?? '').toString();

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

// Lấy plain-text ưu tiên display_text -> decrypt(text,time) -> text gốc
  String? _getPlainTextForInvite() {
    final disp = (m['display_text'] ?? '').toString();
    if (disp.isNotEmpty) return disp;

    final raw = (m['text'] ?? '').toString();
    if (raw.isEmpty) return null;

    final timeKey = (m['time'] ?? '').toString(); // khóa 16 bytes từ 'time'
    final dec = _tryDecryptWoText(raw, timeKey);
    return dec ?? raw;
  }

  String? _tryDecryptWoText(String base64Text, String timeKey) {
    try {
      final clean = base64Text.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
      final k16 = timeKey.padRight(16, '0').substring(0, 16);

      // 1) Thử PKCS7
      try {
        final e1 = enc.Encrypter(
          enc.AES(enc.Key.fromUtf8(k16),
              mode: enc.AESMode.ecb, padding: 'PKCS7'),
        );
        final s1 = e1.decrypt64(clean);
        return _stripZeros(s1);
      } catch (_) {}

      // 2) Thử no-padding
      try {
        final e2 = enc.Encrypter(
          enc.AES(enc.Key.fromUtf8(k16), mode: enc.AESMode.ecb, padding: null),
        );
        final s2 = e2.decrypt64(clean);
        return _stripZeros(s2);
      } catch (_) {}

      return null;
    } catch (_) {
      return null;
    }
  }

  String _stripZeros(String s) => s.replaceAll(RegExp(r'\x00+\$'), '');



  @override
  Widget build(BuildContext context) {
    // 🔔 ƯU TIÊN: nếu là lời mời gọi thì render bubble đặc biệt
    final invite = CallInvite.tryParse(_getPlainTextForInvite() ?? '');
Widget _buildInviteBubble(CallInvite inv) {
      final isVideo = inv.mediaType == 'video';
      final title = widget.isMe
          ? 'Bạn đã mời gọi ${isVideo ? 'video' : 'thoại'}'
          : 'Mời bạn gọi ${isVideo ? 'video' : 'thoại'}';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:
              widget.isMe ? const Color(0xFF2F80ED) : const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!widget.isMe) ...[
                TextButton(
                  onPressed: () async {
                    final call = context.read<CallController>();
                    try {
                      // gắn vào cuộc gọi => controller bắt đầu poll
                      await call.attachIncoming(
                          callId: inv.callId, mediaType: inv.mediaType);

                      // báo trả lời để caller chuyển sang "answered"
                      await call.action('answer');

                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CallScreen(
                            isCaller: false,
                            callId: inv.callId,
                            mediaType: inv.mediaType, // 'audio' | 'video'
                            peerName: (m['user_data']?['name'] ??
                                    m['user_data']?['username'] ??
                                    '')
                                .toString(),
                            peerAvatar:
                                (m['user_data']?['avatar'] ?? '').toString(),
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Không thể nhận cuộc gọi: $e')),
                      );
                    }
                  },
                  child: const Text('Nhận'),
                ),
                TextButton(
                  onPressed: () async {
                    final call = context.read<CallController>();
                    try {
                      await call.attachIncoming(
                          callId: inv.callId, mediaType: inv.mediaType);
                      await call.action('decline');
                    } catch (_) {}
                  },
                  child: const Text('Từ chối'),
                ),
              ],
            ],
          )

      );
    }

    if (invite != null) {
      return _buildInviteBubble(invite);
    }

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
          if (!_isImage && !_isVideo && !_isAudio) ...[
            if (_mediaUrl.isNotEmpty)
              GestureDetector(
                onTap: () {
                  final name =
                      (m['mediaFileName'] ?? '').toString().toLowerCase();
                  if (name.endsWith('.pdf')) {
                    _openPdfInline(_mediaUrl);
                  } else {
                    _openFile(_mediaUrl);
                  }
                },
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
                        : ((m['mediaFileName'] ?? '')
                                .toString()
                                .toLowerCase()
                                .endsWith('.pdf'))
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

  /// Bubble đặc biệt cho lời mời gọi 1-1
  Widget _buildInviteBubble(CallInvite invite) {
    final isExpired = invite.isExpired();
    final isVideo = invite.media == 'video';
    final bg = widget.isMe ? const Color(0xFF2F80ED) : const Color(0xFFEFEFEF);
    final fg = widget.isMe ? Colors.white : Colors.black87;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(isVideo ? Icons.videocam : Icons.call, color: fg),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            widget.isMe
                ? (isVideo ? 'Bạn đã mời gọi video' : 'Bạn đã mời gọi thoại')
                : (isVideo ? 'Lời mời gọi video' : 'Lời mời gọi thoại') +
                    (isExpired ? ' (hết hạn)' : ''),
            style: TextStyle(color: fg, fontSize: 15),
          ),
        ),
        if (!widget.isMe && !isExpired)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => IncomingCallScreen(
                      callId: invite.callId,
                      mediaType: invite.media,
                    ),
                  ),
                );
              },
              child: const Text('Trả lời'),
            ),
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisAlignment:
            widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: content,
            ),
          ),
        ],
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
