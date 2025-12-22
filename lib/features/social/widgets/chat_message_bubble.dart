// G:\flutter-app\lib\features\social\widgets\chat_message_bubble.dart
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:math';

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
    _vp?.dispose();
    _audio.dispose();
    super.dispose();
  }

  Future<void> _initVideo() async {
    try {
      _vp = VideoPlayerController.networkUrl(Uri.parse(_mediaUrl));
      await _vp!.initialize();
      await _vp!.setLooping(true);
      _vp!.addListener(() {
        if (!mounted) return;
        setState(() {});
      });
      if (mounted) setState(() => _videoReady = true);
    } catch (_) {}
  }

  void _toggleVideoPlayPause() {
    final controller = _vp;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() {});
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

  // ===================== CALL INVITE HELPERS =====================

  /// Lấy plain-text ưu tiên display_text -> decrypt(text,time) -> text gốc
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

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    // 🔔 Nếu nội dung là JSON log cuộc gọi => render bubble đặc biệt
    final plain = _getPlainTextForInvite();
    final zegoLog = plain != null ? _tryParseZegoCallLog(plain) : null;
    if (zegoLog != null) {
      return _buildZegoCallLogBubble(zegoLog);
    }
    final invite = plain != null ? CallInvite.tryParse(plain) : null;

    if (invite != null) {
      return _buildInviteBubble(invite);
    }

    final radius = Radius.circular(18);
    final bg = widget.isMe ? const Color(0xFF2F80ED) : const Color(0xFFEFEFEF);
    final fg = widget.isMe ? Colors.white : Colors.black87;

    final double maxBubbleWidth = MediaQuery.of(context).size.width * 0.5;
    final bubble = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
      child: Column(
        crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // ====== IMAGE ======
          if (_isImage && _mediaUrl.isNotEmpty)
            SizedBox(
              width: maxBubbleWidth,
              height: maxBubbleWidth * 1.25,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: GestureDetector(
                  onTap: () => _openImageFull(_mediaUrl),
                  child: CachedNetworkImage(
                    imageUrl: _mediaUrl,
                    fit: BoxFit.cover,
                    placeholder: (c, _) => Container(
                      color: Colors.black12,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    ),
                    errorWidget: (c, _, __) => Container(
                      color: Colors.black12,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),
            ),

          // ====== VIDEO ======
          if (_isVideo && _mediaUrl.isNotEmpty)
            SizedBox(
              width: maxBubbleWidth,
              height: maxBubbleWidth * 1.25,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _videoReady
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _vp!.value.size.width > 0
                                  ? _vp!.value.size.width
                                  : maxBubbleWidth,
                              height: _vp!.value.size.height > 0
                                  ? _vp!.value.size.height
                                  : maxBubbleWidth * 1.25,
                              child: VideoPlayer(_vp!),
                            ),
                          ),
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _toggleVideoPlayPause,
                                child: AnimatedOpacity(
                                  opacity: _vp!.value.isPlaying ? 0.0 : 0.9,
                                  duration: const Duration(milliseconds: 160),
                                  child: Container(
                                    color: Colors.black38,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.play_circle_fill,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
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
  ///
  /// ⚠️ Lưu ý:
  /// - Luồng "chuông + màn nghe/từ chối tự nhảy" đang được xử lý bằng FCM
  ///   ở main.dart (_handleCallInviteOpen -> IncomingCallScreen).
  /// - Bubble này chỉ dùng để HIỂN THỊ LỊCH SỬ + fallback "Trả lời" khi
  ///   user đang ở trong đoạn chat (giống Messenger mở lại log cuộc gọi).
  Widget _buildInviteBubble(CallInvite invite) {
    final isExpired = invite.isExpired();
    final isVideo = invite.media == 'video';
    final bg = widget.isMe ? const Color(0xFF2F80ED) : const Color(0xFFEFEFEF);
    final fg = widget.isMe ? Colors.white : Colors.black87;

    final title = widget.isMe
        ? (isVideo ? 'Bạn đã mời gọi video' : 'Bạn đã mời gọi thoại')
        : (isVideo ? 'Lời mời gọi video' : 'Lời mời gọi thoại');

    final subtitle = isExpired ? 'Đã hết hạn' : 'Đang chờ trả lời';

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
                title + (isExpired ? ' (hết hạn)' : ''),
                style: TextStyle(
                  color: fg,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: fg.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Không mở IncomingCallScreen nữa (CallKit/ConnectionService lo UI)
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
    final double progress =
        dur > 0 ? pos.clamp(0, dur).toDouble() / dur.toDouble() : 0;
    final List<double> samples =
        _generateWaveform(_mediaUrl.isNotEmpty ? _mediaUrl : 'audio');

    return Container(
        width: 220,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(2, 2),
            )
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
                size: 26,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _WaveformSeekBar(
                    progress: progress,
                    activeColor: fg,
                    inactiveColor: fg.withOpacity(0.25),
                    samples: samples,
                    maxHeight: 26,
                    onSeekPercent: !_audioInited
                        ? null
                        : (p) async {
                            final target =
                                Duration(seconds: (p * dur.toDouble()).toInt());
                            await _audio.seek(target);
                          },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fmt(_audioPos),
                    style: TextStyle(color: fg.withOpacity(0.9), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ));
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
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

    final double maxBubbleWidth = MediaQuery.of(context).size.width * 0.66;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisAlignment:
            widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
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
}

List<double> _generateWaveform(String key, {int count = 32}) {
  final rnd = Random(key.hashCode);
  final List<double> values = [];
  for (int i = 0; i < count; i++) {
    final double base = 0.25 + rnd.nextDouble() * 0.75;
    values.add(base);
  }
  return [
    ...values.take(count ~/ 2),
    ...(values.take(count - count ~/ 2).toList().reversed),
  ];
}

class _WaveformSeekBar extends StatelessWidget {
  final double progress; // 0..1
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<double>? onSeekPercent;
  final double maxHeight;
  final List<double>? samples;

  const _WaveformSeekBar({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    this.onSeekPercent,
    this.maxHeight = 26,
    this.samples,
  });

  static const List<double> _basePattern = [
    0.25,
    0.35,
    0.45,
    0.6,
    0.75,
    0.9,
    1.0,
    0.9,
    0.8,
    1.0,
    0.9,
    0.75,
    0.6,
    0.45,
    0.35,
    0.25
  ];
  static const double _barWidth = 4.0;
  static const double _barSpacing = 5.0;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final List<double> pattern = samples ?? _basePattern;
        final double totalWidth =
            (_barWidth * pattern.length) + _barSpacing * (pattern.length - 1);
        final double available =
            constraints.maxWidth.isFinite ? constraints.maxWidth : totalWidth;
        final double scale = available / totalWidth;
        final int activeBars =
            (clamped * pattern.length).floor().clamp(0, pattern.length);

        Widget bars = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < pattern.length; i++) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: _barWidth * scale,
                height: (pattern[i].clamp(0.18, 1.0) * maxHeight) * scale,
                decoration: BoxDecoration(
                  color: i <= activeBars ? activeColor : inactiveColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              if (i != pattern.length - 1) SizedBox(width: _barSpacing * scale),
            ],
          ],
        );

        if (onSeekPercent == null) return bars;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (details) {
            final double dx = details.localPosition.dx.clamp(0.0, available);
            onSeekPercent!(dx / available);
          },
          child: SizedBox(
            width: available,
            child: bars,
          ),
        );
      },
    );
  }
}
