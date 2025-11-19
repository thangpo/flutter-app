// lib/features/social/screens/chat_media_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_chat_repository.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class ChatMediaScreen extends StatefulWidget {
  final String peerId;
  final String accessToken;

  const ChatMediaScreen({
    super.key,
    required this.peerId,
    required this.accessToken,
  });

  @override
  State<ChatMediaScreen> createState() => _ChatMediaScreenState();
}

class _ChatMediaScreenState extends State<ChatMediaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final repo = SocialChatRepository();

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }


  /// media = images + videos
  List<Map<String, dynamic>> media = [];

  /// files = docs + audio + các file khác
  List<Map<String, dynamic>> files = [];

  /// links
  List<Map<String, dynamic>> links = [];

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    loadAll();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> loadAll() async {
    setState(() {
      _loading = true;
    });

    try {
      final imgs = await repo.getMedia(
        token: widget.accessToken,
        peerId: widget.peerId,
        mediaType: 'images',
      );
      final vids = await repo.getMedia(
        token: widget.accessToken,
        peerId: widget.peerId,
        mediaType: 'videos',
      );
      final audios = await repo.getMedia(
        token: widget.accessToken,
        peerId: widget.peerId,
        mediaType: 'audio',
      );
      final docs = await repo.getMedia(
        token: widget.accessToken,
        peerId: widget.peerId,
        mediaType: 'docs',
      );
      final lnks = await repo.getMedia(
        token: widget.accessToken,
        peerId: widget.peerId,
        mediaType: 'links',
      );

      List<Map<String, dynamic>> _cast(List raw) =>
          raw.map<Map<String, dynamic>>((e) {
            if (e is Map<String, dynamic>) return e;
            return Map<String, dynamic>.from(e as Map);
          }).toList();

      // gộp tất cả file-like, sau đó tự phân loại
      final allFileLike = <Map<String, dynamic>>[
        ..._cast(imgs),
        ..._cast(vids),
        ..._cast(audios),
        ..._cast(docs),
      ];

      final newMedia = <Map<String, dynamic>>[];
      final newFiles = <Map<String, dynamic>>[];

      for (final m in allFileLike) {
        final ext = _extFrom(m);
        final kind = _getKind(m);

        final isImg = _isImageExt(ext) ||
            kind == 'image' ||
            kind == 'photo' ||
            kind == 'photos';

        final isVid = _isVideoExt(ext) || kind == 'video';

        if (isImg || isVid) {
          newMedia.add(m);
        } else {
          newFiles.add(m);
        }
      }

      media = newMedia;
      files = newFiles;
      links = _cast(lnks);
    } catch (e) {
      debugPrint('loadAll media error: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  // =========== HELPERS ===========

  String _string(dynamic v) => v?.toString() ?? '';

  /// Lấy URL media từ nhiều khả năng (kiểu WoWonder)
  String _getMediaUrl(Map<String, dynamic> m) {
    final candidates = [
      'full',
      'media',
      'image',
      'image_org',
      'image_original',
      'video',
      'audio',
      'file',
      'file_path',
      'file_url',
      'download_link',
      'postFile',
      'postFile_full',
      'thumbnail',
      'url',
    ];
    for (final k in candidates) {
      final v = _string(m[k]);
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  String _resolveUrl(String? raw) {
    if (raw == null) return '';
    var url = raw.trim();
    if (url.isEmpty) return '';

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    final base = AppConstants.socialBaseUrl;
    if (url.startsWith('/')) {
      return '$base$url';
    }
    return '$base/$url';
  }

  String _getFileName(Map<String, dynamic> m) {
    final cands = [
      'file_name',
      'filename',
      'name',
      'title',
      'text',
    ];
    for (final k in cands) {
      final v = _string(m[k]);
      if (v.isNotEmpty) return v;
    }
    final url = _getMediaUrl(m);
    if (url.isNotEmpty) {
      final path = url.split('?').first;
      final segs = path.split('/');
      if (segs.isNotEmpty) return segs.last;
    }
    return 'File';
  }

  String _formatUnix(String s) {
    final n = int.tryParse(s);
    if (n == null) return s;
    final dt =
        DateTime.fromMillisecondsSinceEpoch(n * 1000, isUtc: true).toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year}  ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _getTimeText(Map<String, dynamic> m) {
    final v = _string(m['time_text'] ?? m['date'] ?? m['time']);
    if (v.isEmpty) return '';
    if (RegExp(r'^\d{9,}$').hasMatch(v)) {
      return _formatUnix(v);
    }
    return v;
  }

  String _getDateKey(Map<String, dynamic> m) {
    final t = _getTimeText(m);
    if (t.isEmpty) return '';
    return t.split(' ').first; // lấy phần dd/MM/yyyy
  }

  String _getKind(Map<String, dynamic> m) {
    return _string(m['type'] ?? m['media_type'] ?? m['file_type'])
        .toLowerCase();
  }

  String _extFrom(Map<String, dynamic> m) {
    final url = _getMediaUrl(m);
    final name = url.isNotEmpty ? url : _getFileName(m);
    final path = name.split('?').first;
    final dot = path.lastIndexOf('.');
    if (dot != -1 && dot != path.length - 1) {
      return path.substring(dot + 1).toLowerCase();
    }

    final kind = _getKind(m);
    switch (kind) {
      case 'image':
      case 'photo':
      case 'photos':
        return 'jpg';
      case 'video':
        return 'mp4';
      case 'audio':
      case 'sound':
        return 'mp3';
      default:
        return '';
    }
  }

  bool _isImageExt(String ext) =>
      ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);

  bool _isVideoExt(String ext) =>
      ['mp4', 'mkv', 'flv', 'mov', 'avi', 'webm', 'mpeg'].contains(ext);

  bool _isAudioExt(String ext) =>
      ['mp3', 'm4a', 'aac', 'ogg', 'wav'].contains(ext);

  IconData _fileIcon(String ext, Map<String, dynamic> m) {
    final kind = _getKind(m);

    if (_isImageExt(ext) ||
        kind == 'image' ||
        kind == 'photo' ||
        kind == 'photos') {
      return Icons.image;
    }
    if (_isVideoExt(ext) || kind == 'video') {
      return Icons.movie;
    }
    if (_isAudioExt(ext) || kind == 'audio' || kind == 'sound') {
      return Icons.audiotrack;
    }

    if (ext == 'apk') return Icons.android;
    if (ext == 'pdf') return Icons.picture_as_pdf;
    if (['doc', 'docx', 'txt'].contains(ext)) return Icons.description;
    if (['zip', 'rar'].contains(ext)) return Icons.archive;

    return Icons.insert_drive_file;
  }

  String _getFileSize(Map<String, dynamic> m) {
    final raw = _string(
      m['file_size'] ?? m['size'] ?? m['file_size_formatted'],
    );
    if (raw.isEmpty) return '';
    // nếu server đã format sẵn thì trả luôn
    if (raw.contains('KB') || raw.contains('MB') || raw.contains('GB')) {
      return raw;
    }
    final n = double.tryParse(raw);
    if (n == null) return '';
    double bytes = n;
    if (bytes < 1024) return '${bytes.toStringAsFixed(0)} B';
    double kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    double mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    double gb = mb / 1024;
    return '${gb.toStringAsFixed(1)} GB';
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _showImageViewer(String url) async {
    if (url.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenImagePage(url: url),
      ),
    );
  }

  Future<void> _showVideoViewer(String url) async {
    if (url.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenVideoPage(url: url),
      ),
    );
  }

  Map<String, String> _parseHtmlLink(String text) {
    final result = <String, String>{'url': '', 'label': ''};
    if (text.isEmpty) return result;

    final hrefRe = RegExp(r'href="([^"]+)"', caseSensitive: false);
    final labelRe = RegExp(r'>([^<]+)<\/a>', caseSensitive: false);

    final hrefMatch = hrefRe.firstMatch(text);
    final labelMatch = labelRe.firstMatch(text);

    if (hrefMatch != null) {
      result['url'] = hrefMatch.group(1) ?? '';
    }
    if (labelMatch != null) {
      result['label'] = labelMatch.group(1) ?? '';
    }

    if (result['url']!.isEmpty) {
      final urlRe = RegExp(r'https?:\/\/\S+');
      final m = urlRe.firstMatch(text);
      if (m != null) result['url'] = m.group(0) ?? '';
    }
    if (result['label']!.isEmpty && result['url']!.isNotEmpty) {
      result['label'] = result['url']!;
    }
    return result;
  }

  String _getHost(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    return uri.host;
  }

  // =========== BUILD ===========

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ảnh/Video, Files và Links'),
        bottom: TabBar(
          controller: _tab,
          labelColor: cs.primary,
          tabs: const [
            Tab(text: 'Image/Video'),
            Tab(text: 'Files'),
            Tab(text: 'Links'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _mediaGrid(media),
                _fileList(files),
                _linkList(links),
              ],
            ),
    );
  }

  // --------- TAB 1: MEDIA (Ảnh + video) ---------
  Widget _mediaGrid(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(6),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final m = list[i];
        final url = _resolveUrl(_getMediaUrl(m));
        final ext = _extFrom(m);
        final kind = _getKind(m);

        final isImg = _isImageExt(ext) ||
            kind == 'image' ||
            kind == 'photo' ||
            kind == 'photos';
        final isVid = _isVideoExt(ext) || kind == 'video';

        if (url.isEmpty) {
          return Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.image_not_supported),
          );
        }

        return GestureDetector(
          onTap: () {
            if (isImg) {
              _showImageViewer(url);
            } else if (isVid) {
              _showVideoViewer(url);
            } else {
              _openUrl(url);
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Ảnh: load trực tiếp
                if (isImg)
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  )
                // Video: chỉ hiển thị nền xám + icon play
                else if (isVid)
                  Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.play_circle_fill,
                      size: 40,
                      color: Colors.grey,
                    ),
                  )
                else
                  Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.insert_drive_file),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --------- TAB 2: FILE (group theo ngày, style giống Zalo) ---------
  // --------- TAB 2: FILE (đẹp hơn) ---------
  Widget _fileList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    // group theo ngày
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final f in list) {
      final key = _getDateKey(f);
      groups.putIfAbsent(key.isEmpty ? 'Khác' : key, () => []).add(f);
    }

    final todayKey = _dateOnly(DateTime.now());
    final keys = groups.keys.toList();

    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final dateKey = keys[index];
        final items = groups[dateKey]!;
        final label = dateKey == todayKey ? 'Hôm nay' : ' $dateKey';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel(label),
            ...items.map((f) {
              final url = _resolveUrl(_getMediaUrl(f));
              final name = _getFileName(f);
              final time = _getTimeText(f);
              final ext = _extFrom(f);
              final size = _getFileSize(f);

              final subtitleParts = <String>[];
              if (size.isNotEmpty) subtitleParts.add(size);
              if (time.isNotEmpty) subtitleParts.add(time);
              final subtitle = subtitleParts.join(' · ');

              return InkWell(
                onTap: url.isNotEmpty ? () => _openUrl(url) : null,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _fileIcon(ext, f),
                          size: 22,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }


  String _dateOnly(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year}';
  }

  // --------- TAB 3: LINK (hiển thị title + domain, group theo ngày) ---------
  // --------- TAB 3: LINK (đẹp hơn) ---------
  Widget _linkList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final l in list) {
      final key = _getDateKey(l);
      groups.putIfAbsent(key.isEmpty ? 'Khác' : key, () => []).add(l);
    }

    final todayKey = _dateOnly(DateTime.now());
    final keys = groups.keys.toList();

    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final dateKey = keys[index];
        final items = groups[dateKey]!;
        final label = dateKey == todayKey ? 'Hôm nay' : 'Ngày $dateKey';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel(label),
            ...items.map((l) {
              final rawTitle = _string(l['title'] ?? l['text'] ?? '');
              final rawUrlField =
                  _string(l['link'] ?? l['url'] ?? l['full'] ?? l['file']);

              String url = '';
              String title = '';

              if (rawUrlField.isNotEmpty) {
                url = _resolveUrl(rawUrlField);
                title = rawTitle.isNotEmpty ? rawTitle : url;
              } else {
                final parsed = _parseHtmlLink(rawTitle);
                url = _resolveUrl(parsed['url'] ?? '');
                title = parsed['label'] ?? '';
              }

              final host = _getHost(url);
              final subtitle = host.isNotEmpty ? host : url;

              return InkWell(
                onTap: url.isNotEmpty ? () => _openUrl(url) : null,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.link,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.isNotEmpty ? title : '(link)',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

}

/// ================== FULLSCREEN IMAGE ==================

class _FullScreenImagePage extends StatelessWidget {
  final String url;

  const _FullScreenImagePage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Ảnh',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(url),
        ),
      ),
    );
  }
}

/// ================== FULLSCREEN VIDEO ==================

class _FullScreenVideoPage extends StatefulWidget {
  final String url;

  const _FullScreenVideoPage({required this.url});

  @override
  State<_FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<_FullScreenVideoPage> {
  late VideoPlayerController _controller;
  bool _initing = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _initing = false;
      });
      _controller.play();
    }).catchError((e) {
      debugPrint('video init error: $e');
      if (!mounted) return;
      setState(() {
        _initing = false;
        _error = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_controller.value.isInitialized) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying =
        _controller.value.isInitialized && _controller.value.isPlaying;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Video',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: _initing
            ? const CircularProgressIndicator(color: Colors.white)
            : _error || !_controller.value.isInitialized
                ? const Text(
                    'Không phát được video',
                    style: TextStyle(color: Colors.white),
                  )
                : Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                      Positioned(
                        bottom: 32,
                        child: IconButton(
                          iconSize: 48,
                          color: Colors.white,
                          icon: Icon(
                            isPlaying ? Icons.pause_circle : Icons.play_circle,
                          ),
                          onPressed: _togglePlay,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
