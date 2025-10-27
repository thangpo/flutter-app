import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/controllers/product_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/screens/product_details_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

Widget? buildSocialPostMedia(
  BuildContext context,
  SocialPost post, {
  bool compact = false,
}) {
  final cs = Theme.of(context).colorScheme;
  final onSurface = cs.onSurface;
  final images = post.imageUrls;
  final bool hasMulti = images.length >= 2;
  final bool hasSingle = images.length == 1 || (post.imageUrl ?? '').isNotEmpty;
  final String? fileUrl = post.fileUrl;

  // 0) Video
  if (_isVideo(fileUrl)) {
    return _VideoPlayerTile(
      url: fileUrl!,
      maxHeightFactor: compact ? 0.5 : 0.6,
    );
  }

  // 1) Product
  if (post.hasProduct == true && (post.productImages?.isNotEmpty ?? false)) {
    return _ProductPostTile(post: post, compact: compact);
  }

  // 1.5) Images + Audio overlay
  if (images.isNotEmpty && _isAudio(fileUrl)) {
    return _ImagesWithAutoAudio(images: images, audioUrl: fileUrl!);
  }

  // 2) Multi image grid
  if (hasMulti) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(images[0], fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(images[1], fit: BoxFit.cover),
              ),
            ),
          ],
        ),
        if (images.length > 2) const SizedBox(height: 4),
        if (images.length > 2)
          Row(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(images[2], fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: images.length > 3
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(images[3], fit: BoxFit.cover),
                            Container(
                              alignment: Alignment.center,
                              color: Colors.black45,
                              child: Text(
                                '+${images.length - 4}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // 3) Single image
  if (hasSingle) {
    final String src = images.isNotEmpty ? images.first : (post.imageUrl!);
    return _AutoRatioNetworkImage(
      src,
      maxHeightFactor: compact ? 0.5 : 0.8,
    );
  }

  // 4) File attachments (audio/pdf/others)
  if (fileUrl != null && fileUrl.isNotEmpty) {
    if (_isAudio(fileUrl) && images.isNotEmpty) {
      return _ImagesWithAutoAudio(images: images, audioUrl: fileUrl);
    }
    if (_isAudio(fileUrl)) {
      return Container(
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(.35),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.audiotrack),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                post.fileName ??
                    (getTranslated('audio', context) ?? 'Audio file'),
                style: TextStyle(color: onSurface),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {}, // Hook into audio player if needed
            ),
          ],
        ),
      );
    } else if (_isPdf(fileUrl)) {
      return Container(
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(.35),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                post.fileName ??
                    (getTranslated('pdf_document', context) ?? 'PDF document'),
                style: TextStyle(color: onSurface),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () async {
                final uri = Uri.parse(fileUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(.35),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                post.fileName ??
                    (getTranslated('attachment', context) ?? 'Attachment'),
                style: TextStyle(color: onSurface),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () {},
            ),
          ],
        ),
      );
    }
  }

  return null;
}

class _AutoRatioNetworkImage extends StatefulWidget {
  final String url;
  final double maxHeightFactor;
  const _AutoRatioNetworkImage(
    this.url, {
    this.maxHeightFactor = 0.8,
  });

  @override
  State<_AutoRatioNetworkImage> createState() => _AutoRatioNetworkImageState();
}

class _AutoRatioNetworkImageState extends State<_AutoRatioNetworkImage> {
  double? _ratio;

  @override
  void initState() {
    super.initState();
    final img = Image(image: CachedNetworkImageProvider(widget.url));
    img.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((info, _) {
        if (mounted && info.image.height != 0) {
          setState(() => _ratio = info.image.width / info.image.height);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _ratio ?? (16 / 9);
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final maxHeight =
            MediaQuery.of(ctx).size.height * widget.maxHeightFactor;
        final width = constraints.maxWidth;
        double height = width / ratio;
        double finalWidth = width;
        if (height > maxHeight) {
          height = maxHeight;
          finalWidth = height * ratio;
        }
        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: finalWidth,
            height: height,
            child: CachedNetworkImage(
              imageUrl: widget.url,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}

class _ImagesWithAutoAudio extends StatefulWidget {
  final List<String> images;
  final String audioUrl;
  const _ImagesWithAutoAudio({
    required this.images,
    required this.audioUrl,
  });

  @override
  State<_ImagesWithAutoAudio> createState() => _ImagesWithAutoAudioState();
}

class _ImagesWithAutoAudioState extends State<_ImagesWithAutoAudio> {
  final PageController _pc = PageController();
  int _index = 0;
  final AudioPlayer _player = AudioPlayer();
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    () async {
      try {
        await _player.setSourceUrl(widget.audioUrl);
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.setPlaybackRate(1.0);
      } catch (_) {}
    }();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final nowVisible = info.visibleFraction > 0.6;
    if (nowVisible == _visible) return;
    _visible = nowVisible;
    final state = _player.state;
    if (nowVisible) {
      if (state != PlayerState.playing) {
        _player.resume();
      }
    } else {
      if (state == PlayerState.playing) {
        _player.pause();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return VisibilityDetector(
      key: ValueKey(widget.audioUrl),
      onVisibilityChanged: _onVisibilityChanged,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: width,
            child: PageView.builder(
              controller: _pc,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: widget.images.length,
              itemBuilder: (_, i) =>
                  Image.network(widget.images[i], fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.images.length, (i) {
              final active = i == _index;
              return Container(
                width: active ? 10 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.white54,
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _VideoPlayerTile extends StatefulWidget {
  final String url;
  final double maxHeightFactor;
  const _VideoPlayerTile({
    required this.url,
    this.maxHeightFactor = 0.6,
  });

  @override
  State<_VideoPlayerTile> createState() => _VideoPlayerTileState();
}

class _VideoPlayerTileState extends State<_VideoPlayerTile> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() {});
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
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final ratio = _controller!.value.aspectRatio == 0
        ? (16 / 9)
        : _controller!.value.aspectRatio;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight =
            MediaQuery.of(context).size.height * widget.maxHeightFactor;
        final width = constraints.maxWidth;
        double targetHeight = width / ratio;
        double targetWidth = width;
        if (targetHeight > maxHeight) {
          targetHeight = maxHeight;
          targetWidth = targetHeight * ratio;
        }
        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: targetWidth,
            height: targetHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                VideoPlayer(_controller!),
                Align(
                  alignment: Alignment.center,
                  child: IconButton(
                    iconSize: 48,
                    color: Colors.white,
                    icon: Icon(_controller!.value.isPlaying
                        ? Icons.pause_circle
                        : Icons.play_circle),
                    onPressed: () {
                      _controller!.value.isPlaying
                          ? _controller!.pause()
                          : _controller!.play();
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductPostTile extends StatefulWidget {
  final SocialPost post;
  final bool compact;
  const _ProductPostTile({
    required this.post,
    this.compact = false,
  });

  @override
  State<_ProductPostTile> createState() => _ProductPostTileState();
}

class _ProductPostTileState extends State<_ProductPostTile> {
  static const int _collapsedLines = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final List<String> images = widget.post.productImages ?? const <String>[];
    final String title = widget.post.productTitle ?? '';
    final double? price = widget.post.productPrice;
    final String? priceText =
        price != null ? PriceConverter.convertPrice(context, price) : null;
    final String description = _plainText(widget.post.productDescription);
    final bool hasDescription = description.isNotEmpty;
    final bool showToggle = hasDescription && description.length > 160;
    final int? productId = widget.post.ecommerceProductId;
    final bool canNavigate = productId != null && productId > 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(.35),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                title,
                style: TextStyle(
                  color: onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          if (images.isNotEmpty)
            _AutoRatioNetworkImage(
              images.first,
              maxHeightFactor: widget.compact ? 0.45 : 0.8,
            ),
          const SizedBox(height: 6),
          if (priceText != null)
            Text(
              priceText,
              style: TextStyle(
                color: onSurface.withOpacity(.9),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          if (hasDescription) ...[
            const SizedBox(height: 8),
            Text(
              description,
              maxLines: _expanded ? null : _collapsedLines,
              overflow:
                  _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: TextStyle(
                color: onSurface.withOpacity(.8),
                fontSize: 13,
              ),
            ),
            if (showToggle)
              TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _expanded
                      ? (getTranslated('collapse', context) ?? 'Collapse')
                      : (getTranslated('see_more', context) ?? 'See more'),
                ),
              ),
          ],
          if (canNavigate) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _navigateToEcommerceProduct(
                  context,
                  productId: productId!,
                  initialSlug: widget.post.productSlug,
                ),
                child: Text(
                    getTranslated('view_detail', context) ?? 'View detail'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _plainText(String? source) {
    if (source == null || source.trim().isEmpty) return '';
    final withoutTags = source.replaceAll(RegExp(r'<[^>]*>'), ' ');
    final decoded = withoutTags.replaceAll('&nbsp;', ' ');
    return decoded.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

Future<void> _navigateToEcommerceProduct(
  BuildContext context, {
  required int productId,
  String? initialSlug,
}) async {
  if (productId <= 0) {
    showCustomSnackBar(
      getTranslated('product_not_found', context) ?? 'Product unavailable',
      context,
    );
    return;
  }

  final String? slug = await _ensureSlugForProduct(
    context,
    productId: productId,
    initialSlug: initialSlug,
  );
  if (!context.mounted) return;

  if (slug == null) {
    showCustomSnackBar(
      getTranslated('product_not_found', context) ?? 'Product unavailable',
      context,
    );
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ProductDetails(
        productId: productId,
        slug: slug,
      ),
    ),
  );
}

Future<String?> _ensureSlugForProduct(
  BuildContext context, {
  required int productId,
  String? initialSlug,
}) async {
  final String? sanitized = _sanitizeSlugValue(initialSlug);
  if (sanitized != null) return sanitized;
  final controller = context.read<ProductDetailsController>();
  return controller.resolveSlugByProductId(productId, silent: true);
}

String? _sanitizeSlugValue(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  final lower = trimmed.toLowerCase();
  if (lower == 'null' || lower == 'undefined') return null;
  return trimmed;
}

bool _isAudio(String? url) {
  if (url == null) return false;
  final u = url.toLowerCase();
  return u.endsWith('.mp3') || u.contains('/sounds/');
}

bool _isPdf(String? url) {
  if (url == null) return false;
  final u = url.toLowerCase();
  return u.endsWith('.pdf');
}

bool _isVideo(String? url) {
  if (url == null) return false;
  final u = url.toLowerCase();
  return u.endsWith('.mp4') || u.endsWith('.mov') || u.endsWith('.m4v');
}
