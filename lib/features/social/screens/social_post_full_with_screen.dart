import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/mention_formatter.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/post_background_presets.dart';

enum SocialPostFullItemType { background, image, video }

class SocialPostFullViewItem {
  final SocialPostFullItemType type;
  final String? url;
  final String? htmlText;
  final PostBackgroundPreset? preset;
  const SocialPostFullViewItem._({
    required this.type,
    this.url,
    this.htmlText,
    this.preset,
  });
  factory SocialPostFullViewItem.image(String url) {
    return SocialPostFullViewItem._(
        type: SocialPostFullItemType.image, url: url);
  }
  factory SocialPostFullViewItem.video(String url) {
    return SocialPostFullViewItem._(
        type: SocialPostFullItemType.video, url: url);
  }
  factory SocialPostFullViewItem.background({
    required String htmlText,
    required PostBackgroundPreset preset,
  }) {
    return SocialPostFullViewItem._(
      type: SocialPostFullItemType.background,
      htmlText: htmlText,
      preset: preset,
    );
  }
}

class SocialPostFullViewComposer {
  final SocialPost post;
  final SocialController controller;
  late final List<SocialPostFullViewItem> items;
  late final bool hasBackgroundItem;
  late final int imageCount;
  late final bool hasVideoItem;
  SocialPostFullViewComposer({
    required this.post,
    required this.controller,
  }) {
    items = _compose();
    hasBackgroundItem =
        items.any((item) => item.type == SocialPostFullItemType.background);
    imageCount =
        items.where((item) => item.type == SocialPostFullItemType.image).length;
    hasVideoItem =
        items.any((item) => item.type == SocialPostFullItemType.video);
  }
  static bool allowsBackground(SocialPost post) {
    if ((post.backgroundColorId ?? '').isEmpty) return false;
    if ((post.text ?? '').trim().isEmpty) return false;
    if ((post.videoUrl ?? '').isNotEmpty) return false;
    if ((post.fileUrl ?? '').isNotEmpty) return false;
    if ((post.audioUrl ?? '').isNotEmpty) return false;
    if ((post.pollOptions?.isNotEmpty ?? false)) return false;
    if (post.sharedPost != null) return false;
    if (post.hasProduct) return false;
    return true;
  }

  static List<String> normalizeImages(SocialPost post) {
    final List<String> urls = post.imageUrls
        .where((url) => url.trim().isNotEmpty)
        .toList(growable: true);
    final String? fallback = post.imageUrl;
    if (urls.isEmpty && fallback != null && fallback.trim().isNotEmpty) {
      urls.add(fallback);
    }
    return urls;
  }

  static String? resolveVideoUrl(SocialPost post) {
    final String? candidate = post.videoUrl ?? post.fileUrl;
    if (_isVideo(candidate)) return candidate;
    return null;
  }

  int get defaultIndex => 0;
  int? indexFor(
    SocialPostFullItemType type, {
    int imageIndex = 0,
  }) {
    switch (type) {
      case SocialPostFullItemType.background:
        return hasBackgroundItem ? 0 : null;
      case SocialPostFullItemType.image:
        if (imageCount == 0) return null;
        final int clamped =
            imageIndex.clamp(0, imageCount > 0 ? imageCount - 1 : 0);
        final int offset = hasBackgroundItem ? 1 : 0;
        return offset + clamped;
      case SocialPostFullItemType.video:
        if (!hasVideoItem) return null;
        final int offset = (hasBackgroundItem ? 1 : 0) + imageCount;
        return offset;
    }
  }

  List<SocialPostFullViewItem> _compose() {
    final List<SocialPostFullViewItem> result = <SocialPostFullViewItem>[];
    if (allowsBackground(post)) {
      final PostBackgroundPreset? preset =
          controller.findBackgroundPreset(post.backgroundColorId);
      if (preset != null) {
        final String formatted = MentionFormatter.decorate(
          post.text!,
          controller,
          mentions: post.mentions,
        );
        result.add(
          SocialPostFullViewItem.background(
              htmlText: formatted, preset: preset),
        );
      } else {
        final String? bgId = post.backgroundColorId;
        if (bgId != null && bgId.isNotEmpty) {
          controller.ensureBackgroundPreset(bgId);
        }
      }
    }
    final List<String> images = normalizeImages(post);
    for (final String url in images) {
      result.add(SocialPostFullViewItem.image(url));
    }
    final String? videoUrl = resolveVideoUrl(post);
    if (videoUrl != null) {
      result.add(SocialPostFullViewItem.video(videoUrl));
    }
    return result;
  }
}

class SocialPostFullWithScreen extends StatefulWidget {
  final SocialPost post;
  final List<SocialPostFullViewItem> items;
  final int initialIndex;
  const SocialPostFullWithScreen({
    super.key,
    required this.post,
    required this.items,
    required this.initialIndex,
  });
  static Future<void> open(
    BuildContext context, {
    required SocialPost post,
    SocialPostFullItemType? focus,
    int imageIndex = 0,
  }) async {
    final SocialController controller = context.read<SocialController>();
    final SocialPostFullViewComposer composer = SocialPostFullViewComposer(
      post: post,
      controller: controller,
    );
    if (composer.items.isEmpty) return;
    final int defaultIndex = composer.defaultIndex;
    final int initialIndex = focus == null
        ? defaultIndex
        : (composer.indexFor(focus, imageIndex: imageIndex) ?? defaultIndex);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SocialPostFullWithScreen(
          post: post,
          items: composer.items,
          initialIndex: initialIndex.clamp(
            0,
            composer.items.length - 1,
          ),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<SocialPostFullWithScreen> createState() =>
      _SocialPostFullWithScreenState();
}

class _SocialPostFullWithScreenState extends State<SocialPostFullWithScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.items.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final double? velocity = details.primaryVelocity;
    if (velocity != null && velocity > 600) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: _handleVerticalDragEnd,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final SocialPostFullViewItem item = widget.items[index];
                  switch (item.type) {
                    case SocialPostFullItemType.image:
                      return _FullScreenImage(url: item.url!);
                    case SocialPostFullItemType.video:
                      return _FullScreenVideoPlayer(url: item.url!);
                    case SocialPostFullItemType.background:
                      return _FullScreenBackground(
                        htmlText: item.htmlText ?? '',
                        preset: item.preset,
                      );
                  }
                },
              ),
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${widget.items.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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
}

class _FullScreenImage extends StatelessWidget {
  final String url;
  const _FullScreenImage({required this.url});
  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 4,
      child: Center(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          placeholder: (_, __) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (_, __, ___) => const Icon(
            Icons.broken_image,
            color: Colors.white54,
            size: 48,
          ),
        ),
      ),
    );
  }
}

class _FullScreenBackground extends StatelessWidget {
  final String htmlText;
  final PostBackgroundPreset? preset;
  const _FullScreenBackground({
    required this.htmlText,
    required this.preset,
  });
  @override
  Widget build(BuildContext context) {
    final BoxDecoration decoration =
        preset?.decoration() ?? BoxDecoration(color: Colors.blueGrey.shade700);
    final Color textColor = preset?.textColor ?? Colors.white;
    return Container(
      decoration: decoration,
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Center(
        child: SingleChildScrollView(
          child: Html(
            data: htmlText,
            style: {
              'body': Style(
                color: textColor,
                fontSize: FontSize(26),
                lineHeight: LineHeight(1.4),
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                textAlign: TextAlign.center,
                fontWeight: FontWeight.w600,
              ),
              'a.tagged-user': Style(
                color: textColor,
                fontWeight: FontWeight.w700,
                textDecoration: TextDecoration.none,
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _FullScreenVideoPlayer extends StatefulWidget {
  final String url;
  const _FullScreenVideoPlayer({required this.url});
  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  VideoPlayerController? _controller;
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        _controller?.setLooping(true);
        _controller?.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!(_controller?.value.isInitialized ?? false)) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio == 0
                ? (9 / 16)
                : _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: IconButton(
              iconSize: 64,
              color: Colors.white,
              icon: Icon(
                _controller!.value.isPlaying
                    ? Icons.pause_circle
                    : Icons.play_circle,
              ),
              onPressed: () {
                if (_controller!.value.isPlaying) {
                  _controller!.pause();
                } else {
                  _controller!.play();
                }
                setState(() {});
              },
            ),
          ),
        ),
      ],
    );
  }
}

bool _isVideo(String? url) {
  if (url == null || url.isEmpty) return false;
  final String lower = url.toLowerCase();
  return lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.m4v');
}
