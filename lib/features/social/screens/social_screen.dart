import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_post_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Gọi refresh sau khi màn hình mount để chắc chắn lúc này đã có token
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sc = context.read<SocialController>();
      if (sc.posts.isEmpty) {
        sc.refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.background,
      body: SafeArea(
        child: Column(
          children: [
            _FacebookHeader(),
            Expanded(
              child: Consumer<SocialController>(
                builder: (context, sc, _) {
                  if (sc.loading && sc.posts.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return RefreshIndicator(
                    onRefresh: () => sc.refresh(),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.pixels >=
                            n.metrics.maxScrollExtent - 200) {
                          sc.loadMore();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: sc.posts.length +
                            2, // +1: What'sOnYourMind, +1: Stories
                        itemBuilder: (ctx, i) {
                          if (i == 0) {
                            // Block "Bạn đang nghĩ gì?"
                            return Column(
                              children: [
                                _WhatsOnYourMind(),
                                const _SectionSeparator(), // tách với Stories
                              ],
                            );
                          }
                          if (i == 1) {
                            // Block Stories + separator
                            return Consumer<SocialController>(
                              builder: (context, sc2, __) {
                                if (sc2.stories.isEmpty) {
                                  // Nếu chưa có stories, có thể trả spacer mỏng cho đều layout
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  children: [
                                    _StoriesSectionFromApi(
                                        stories: sc2.stories),
                                    // const _SectionSeparator(), // <-- khoảng cách & Divider giống post
                                  ],
                                );
                              },
                            );
                          }

                          // Các post: bắt đầu từ i=2
                          final SocialPost p = sc.posts[i - 2];
                          return _PostCardFromApi(post: p);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FacebookHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final theme = Theme.of(context);
// Ưu tiên appBarTheme.backgroundColor; fallback sang highlightColor của app (Home cũng đang dùng highlightColor)
    final Color appBarColor =
        theme.appBarTheme.backgroundColor ?? theme.highlightColor;
// Chọn màu chữ/icon tương phản trên nền appBarColor
    final bool isDark =
        ThemeData.estimateBrightnessForColor(appBarColor) == Brightness.dark;
    final Color onAppBar = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      // surface cho thanh trên
      color: appBarColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            Theme.of(context).brightness == Brightness.dark
                ? Images.logoWithNameSocialImageWhite
                : Images.logoWithNameSocialImage,
            height: 28,
            fit: BoxFit.contain,
          ),
          Row(
            children: [
              _HeaderIcon(
                  icon: Icons.search,
                  iconColor: onAppBar,
                  bubbleColor: onAppBar.withOpacity(0.08)),
              const SizedBox(width: 12),
              _HeaderIcon(
                  icon: Icons.messenger_outline,
                  iconColor: onAppBar,
                  bubbleColor: onAppBar.withOpacity(0.08)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? bubbleColor;
  const _HeaderIcon({
    required this.icon,
    this.iconColor,
    this.bubbleColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        // elevated container theo surfaceVariant
        color: bubbleColor ?? cs.surfaceVariant,
        shape: BoxShape.circle,
      ),
      child:
          Icon(icon, color: iconColor ?? onSurface.withOpacity(.9), size: 24),
    );
  }
}

class _WhatsOnYourMind extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: cs.surfaceVariant,
            child: Icon(Icons.person, color: onSurface.withOpacity(.6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bạn đang nghĩ gì?',
              style: TextStyle(
                color: onSurface.withOpacity(.7),
                fontSize: 16,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, color: onSurface, size: 20),
          ),
        ],
      ),
    );
  }
}

class _SectionSeparator extends StatelessWidget {
  const _SectionSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        const SizedBox(height: 8),
      ],
    );
  }
}

class _StoriesSectionFromApi extends StatelessWidget {
  final List<SocialStory> stories;
  const _StoriesSectionFromApi({required this.stories});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 200,
      color: cs.surface,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          // chỉ bắt event của scroll ngang
          if (n.metrics.axis == Axis.horizontal &&
              n.metrics.pixels >= n.metrics.maxScrollExtent - 100) {
            final sc = context.read<SocialController>();
            if (!sc.loading) sc.loadMoreStories();
          }
          return false;
        },
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          itemCount: stories.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _CreateStoryCard(); // ô tạo tin
            }
            return _StoryCardFromApi(story: stories[index - 1]);
          },
        ),
      ),
    );
  }
}

class _StoryCardFromApi extends StatelessWidget {
  final SocialStory story;
  const _StoryCardFromApi({required this.story});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final thumb = story.thumbUrl ?? story.mediaUrl;

    return Container(
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.surfaceVariant,
      ),
      child: Stack(
        children: [
          if (thumb != null && thumb.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image(
                image: CachedNetworkImageProvider(thumb),
                width: 110,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
                border: Border.all(color: cs.surface, width: 3),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: cs.surfaceVariant,
                backgroundImage:
                    (story.userAvatar != null && story.userAvatar!.isNotEmpty)
                        ? CachedNetworkImageProvider(story.userAvatar!)
                        : null,
                child: (story.userAvatar == null || story.userAvatar!.isEmpty)
                    ? Icon(Icons.person,
                        color: onSurface.withOpacity(.6), size: 20)
                    : null,
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Text(
              story.userName ?? '',
              style: TextStyle(
                color: onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateStoryCard extends StatelessWidget {
  const _CreateStoryCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // TODO: lấy avatar user hiện tại từ provider/config của app (nếu có)
    final String? avatar = null;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SizedBox(
        width: 110,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  color: cs.surfaceVariant,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: cs.surface,
                      backgroundImage: (avatar != null && avatar.isNotEmpty)
                          ? CachedNetworkImageProvider(avatar)
                          : null,
                      child: avatar == null
                          ? Icon(Icons.person, color: cs.onSurface)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text('Tạo tin',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: điều hướng tới màn hình tạo tin
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tạo'),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(32)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final _Story story;
  const _StoryCard({required this.story});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Container(
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.surfaceVariant,
      ),
      child: Stack(
        children: [
          if (!story.isCreateStory && story.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: story.imageUrl!,
                width: 110,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          if (story.isCreateStory)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
                border: Border.all(color: cs.surface, width: 3),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: cs.surfaceVariant,
                child: Icon(Icons.person,
                    color: onSurface.withOpacity(.6), size: 20),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Text(
              story.name,
              style: TextStyle(
                color: onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
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

// ảnh full-width, tự giữ tỷ lệ theo kích thước thật
class _AutoRatioNetworkImage extends StatefulWidget {
  final String url;
  const _AutoRatioNetworkImage(this.url, {super.key});
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
      builder: (ctx, c) => SizedBox(
        width: double.infinity,
        height: c.maxWidth / ratio,
        child: Image(
            image: CachedNetworkImageProvider(widget.url), fit: BoxFit.cover),
      ),
    );
  }
}

class _MediaCarousel extends StatefulWidget {
  final List<Widget> pages;
  const _MediaCarousel({required this.pages, super.key});
  @override
  State<_MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<_MediaCarousel> {
  final _pc = PageController();
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1, // vuông như Instagram, hoặc 4/5 nếu thích
          child: PageView(
            controller: _pc,
            onPageChanged: (i) => setState(() => _index = i),
            children: widget.pages,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.pages.length, (i) {
            final active = i == _index;
            return Container(
              width: active ? 10 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: active ? Colors.white70 : Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _AudioTile extends StatefulWidget {
  final String url;
  final String? title;
  const _AudioTile({required this.url, this.title, super.key});
  @override
  State<_AudioTile> createState() => _AudioTileState();
}

class _AudioTileState extends State<_AudioTile> {
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(.35),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_playing ? Icons.pause_circle : Icons.play_circle),
            onPressed: () async {
              if (_playing) {
                await _player.pause();
              } else {
                await _player.play(UrlSource(widget.url));
              }
              setState(() => _playing = !_playing);
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(widget.title ?? 'Audio',
                style: TextStyle(color: onSurface)),
          ),
        ],
      ),
    );
  }
}

class _ImagesWithAutoAudio extends StatefulWidget {
  final List<String> images;
  final String audioUrl;
  const _ImagesWithAutoAudio(
      {required this.images, required this.audioUrl, super.key});

  @override
  State<_ImagesWithAutoAudio> createState() => _ImagesWithAutoAudioState();
}

class _ImagesWithAutoAudioState extends State<_ImagesWithAutoAudio> {
  final _pc = PageController();
  int _index = 0;
  final _player = AudioPlayer();
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
    if (nowVisible == _visible) return; // không làm gì nếu state không đổi
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
    final height = width; // vuông giống FB
    return VisibilityDetector(
      key: ValueKey(widget.audioUrl),
      onVisibilityChanged: _onVisibilityChanged,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: height,
            child: PageView.builder(
              controller: _pc,
              onPageChanged: (i) {
                setState(() => _index = i);
              },
              itemCount: widget.images.length,
              itemBuilder: (_, i) {
                return Image.network(widget.images[i], fit: BoxFit.cover);
              },
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
  const _VideoPlayerTile({required this.url, super.key});
  @override
  State<_VideoPlayerTile> createState() => _VideoPlayerTileState();
}

class _VideoPlayerTileState extends State<_VideoPlayerTile> {
  VideoPlayerController? _c;
  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!(_c?.value.isInitialized ?? false)) {
      return const AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(child: CircularProgressIndicator()));
    }
    final ratio = _c!.value.aspectRatio == 0 ? (16 / 9) : _c!.value.aspectRatio;
    return AspectRatio(
      aspectRatio: ratio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoPlayer(_c!),
          Align(
            alignment: Alignment.center,
            child: IconButton(
              iconSize: 48,
              color: Colors.white,
              icon: Icon(
                  _c!.value.isPlaying ? Icons.pause_circle : Icons.play_circle),
              onPressed: () {
                _c!.value.isPlaying ? _c!.pause() : _c!.play();
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCardFromApi extends StatelessWidget {
  final SocialPost post;
  const _PostCardFromApi({required this.post});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final images = post.imageUrls ?? const <String>[];
    final hasMulti = images.length >= 2;
    final hasSingle = images.length == 1 || (post.imageUrl ?? '').isNotEmpty;
    final fileUrl = post.fileUrl;

    String _fmtCurrency(num v, String? code) {
      final name = (code == null || code.isEmpty) ? null : code;
      try {
        final f = NumberFormat.currency(
            name: name, decimalDigits: (name == 'VND') ? 0 : 2);
        return f.format(v);
      } catch (_) {
        return '${v.toString()} ${code ?? ''}'.trim();
      }
    }

    // VIDEO: ưu tiên render trước ảnh
    // if (_isVideo(fileUrl)) {
    //   return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    //     ClipRRect(
    //       borderRadius: BorderRadius.circular(12),
    //       child: _VideoPlayerTile(url: fileUrl!),
    //     ),
    //     const SizedBox(height: 8),
    //     Padding(
    //       padding: const EdgeInsets.symmetric(horizontal: 12),
    //       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    //         if ((post.userName??'').isNotEmpty) Text(post.userName!, style: TextStyle(fontWeight: FontWeight.w600)),
    //         if ((post.text??'').isNotEmpty) const SizedBox(height:4),
    //         if ((post.text??'').isNotEmpty) Html(data: post.text!),
    //       ]),
    //     ),
    //   ]);
    // }

    Widget _media() {
      // 0) VIDEO
      if (_isVideo(fileUrl)) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _VideoPlayerTile(url: fileUrl!),
        );
      }

      // 1) PRODUCT
      if (post.hasProduct == true &&
          (post.productImages?.isNotEmpty ?? false)) {
        final imgs = post.productImages!;
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
              if (post.productTitle != null && post.productTitle!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(post.productTitle!,
                      style: TextStyle(
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      )),
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _AutoRatioNetworkImage(imgs.first),
              ),
              const SizedBox(height: 6),
              if (post.productPrice != null) ...[
                Text(
                  (() {
                    final p = post.productPrice;
                    if (p == null) return '';
                    final asDouble = (p is num)
                        ? p.toDouble()
                        : double.tryParse(p.toString()) ?? 0;
                    return PriceConverter.convertPrice(context, asDouble);
                  })(),
                  style: TextStyle(
                    color: onSurface.withOpacity(.9),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ],
          ),
        );
      }

      // 1.5) ẢNH + AUDIO => Carousel
      // if (images.isNotEmpty && _isAudio(fileUrl)) {
      //   final pages = <Widget>[
      //     for (final u in images)
      //       ClipRRect(
      //         borderRadius: BorderRadius.circular(12),
      //         child: Image.network(u, fit: BoxFit.cover),
      //       ),
      //     _AudioTile(url: fileUrl!, title: post.fileName),
      //   ];
      //   return _MediaCarousel(pages: pages);
      // }
      if (images.isNotEmpty && _isAudio(fileUrl)) {
        return _ImagesWithAutoAudio(images: images, audioUrl: fileUrl!);
      }

      // 2) MULTI IMAGE GRID (2,3,4 ảnh…)
      if (hasMulti) {
        // tránh lỗi layout: luôn có width, height xác định
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
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
                        child: (images.length > 3)
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
          ),
        );
      }

      // 3) ẢNH ĐƠN
      if (hasSingle) {
        final String src = images.isNotEmpty ? images.first : (post.imageUrl!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _AutoRatioNetworkImage(src),
        );
      }

      // 4) FILE (Âm thanh / PDF / Khác)
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
                  child: Text(post.fileName ?? 'Âm thanh',
                      style: TextStyle(color: onSurface)),
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {}, // TODO: hook player nếu cần
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
                  child: Text(post.fileName ?? 'Tài liệu PDF',
                      style: TextStyle(color: onSurface)),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () async {
                    final uri = Uri.parse(fileUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
          );
        } else {
          // fallback file khác
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
                  child: Text(post.fileName ?? 'Tệp đính kèm',
                      style: TextStyle(color: onSurface)),
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

      // 5) Chỉ text
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: cs.surfaceVariant,
                  backgroundImage:
                      (post.userAvatar != null && post.userAvatar!.isNotEmpty)
                          ? CachedNetworkImageProvider(post.userAvatar!)
                          : null,
                  child: (post.userAvatar == null || post.userAvatar!.isEmpty)
                      ? Text(
                          (post.userName?.isNotEmpty ?? false)
                              ? post.userName![0].toUpperCase()
                              : '?',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: onSurface),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // userName + postType cùng 1 dòng
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.userName ?? '—',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: onSurface),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if ((post.postType ?? '').isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Icon(
                              post.postType == 'profile_picture'
                                  ? Icons.person_outline
                                  : post.postType == 'profile_cover_picture'
                                      ? Icons.collections
                                      : Icons.article_outlined,
                              size: 16,
                              color: onSurface.withOpacity(.6),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                post.postType == 'profile_picture'
                                    ? 'đã cập nhật ảnh đại diện'
                                    : post.postType == 'profile_cover_picture'
                                        ? 'đã cập nhật ảnh bìa'
                                        : post.postType!,
                                style: TextStyle(
                                  color: onSurface.withOpacity(.7),
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        post.timeText ?? '',
                        style: TextStyle(
                            color: onSurface.withOpacity(.6), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon:
                      Icon(Icons.more_horiz, color: onSurface.withOpacity(.7)),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Text
          if ((post.text ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Html(
                data: post.text!,
                style: {
                  'body': Style(
                    color: onSurface,
                    fontSize: FontSize(15),
                    lineHeight: LineHeight(1.35),
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                  ),
                },
                onLinkTap: (url, _, __) async {
                  if (url != null) {
                    final uri = Uri.parse(url);
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ),

          // Poll
          if (post.pollOptions != null && post.pollOptions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final opt in post.pollOptions!) ...[
                    Text(opt['text']?.toString() ?? ''),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (((double.tryParse((opt['percentage_num'] ?? '0')
                                        .toString()) ??
                                    0.0) /
                                100.0))
                            .clamp(0, 1),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),

          // Media block (đã chống lỗi layout)
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _media(),
          ),

          const SizedBox(height: 8),
          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Nút Reaction: tap = Like/UnLike; long-press = chọn reaction
                Expanded(
                  child: Builder(
                    builder: (itemCtx) => InkWell(
                      onTap: () {
                        final now = (post.myReaction == 'Like') ? '' : 'Like';
                        itemCtx.read<SocialController>().reactOnPost(post, now);
                      },
                      onLongPress: () {
                        // Tính toạ độ trung tâm nút Like để hiện popup NGAY TRÊN nút
                        final overlayBox = Overlay.of(itemCtx)
                            .context
                            .findRenderObject() as RenderBox;
                        final box = itemCtx.findRenderObject() as RenderBox?;
                        final Offset centerGlobal = (box != null)
                            ? box.localToGlobal(box.size.center(Offset.zero),
                                ancestor: overlayBox)
                            : overlayBox.size.center(Offset.zero);

                        _showReactionsOverlay(
                          itemCtx,
                          centerGlobal,
                          onSelect: (val) {
                            itemCtx
                                .read<SocialController>()
                                .reactOnPost(post, val);
                          },
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _reactionIcon(post.myReaction),
                            const SizedBox(width: 6),
                            Text(
                              post.reactionCount.toString(),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _PostAction(
                  icon: Icons.mode_comment_outlined,
                  label: 'Bình luận',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SocialPostDetailScreen(post: post),
                      ),
                    );
                  },
                ),
                const _PostAction(icon: Icons.share_outlined, label: 'Chia sẻ'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final List<String> urls;
  const _ImageGrid({required this.urls});

  @override
  Widget build(BuildContext context) {
    // Ép kích thước tổng thể để con bên trong có ràng buộc (không bị MISSING size)
    final double aspect = urls.length == 1
        ? (16 / 9)
        : (16 / 9); // có thể đổi 1.0 nếu muốn ô vuông
    return AspectRatio(
      aspectRatio: aspect,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (urls.length == 1) {
      return _tile(urls[0]);
    } else if (urls.length == 2) {
      return Row(
        children: [
          Expanded(child: _square(urls[0])),
          const SizedBox(width: 4),
          Expanded(child: _square(urls[1])),
        ],
      );
    } else if (urls.length == 3) {
      return Row(
        children: [
          Expanded(child: _square(urls[0])),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _square(urls[1])),
                const SizedBox(height: 4),
                Expanded(child: _square(urls[2])),
              ],
            ),
          ),
        ],
      );
    } else {
      // >= 4
      final remain = urls.length - 4;
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _square(urls[0])),
                const SizedBox(width: 4),
                Expanded(child: _square(urls[1])),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _square(urls[2])),
                const SizedBox(width: 4),
                Expanded(
                  child: Stack(
                    fit: StackFit
                        .expand, // BÂY GIỜ đã có ràng buộc từ Expanded cha
                    children: [
                      _square(urls[3]),
                      if (remain > 0)
                        Container(
                          color: Colors.black45,
                          alignment: Alignment.center,
                          child: Text(
                            '+$remain',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  // Ảnh vuông dùng bên trong grid
  Widget _square(String u) => AspectRatio(
        aspectRatio: 1,
        child: _tile(u),
      );

  Widget _tile(String u) => Image(
        image: CachedNetworkImageProvider(u),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black12),
      );
}

class _ReactionPicker extends StatelessWidget {
  final String initial;
  const _ReactionPicker({required this.initial});

  @override
  Widget build(BuildContext context) {
    final items = const ['Like', 'Love', 'HaHa', 'Wow', 'Sad', 'Angry'];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          alignment: WrapAlignment.spaceEvenly,
          children: items
              .map((e) => IconButton(
                    iconSize: 32,
                    onPressed: () => Navigator.pop(context, e),
                    icon: _reactionIcon(e),
                    tooltip: e,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// PNG version
Widget _reactionIcon(String r, {double size = 22}) {
  final String path = _reactionPngPath(r);
  return Image.asset(
    path,
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
  );
}

String _reactionPngPath(String r) {
  switch (r) {
    case 'Love':
      return 'assets/images/reactions/love.png';
    case 'HaHa':
      return 'assets/images/reactions/haha.png';
    case 'Wow':
      return 'assets/images/reactions/wow.png';
    case 'Sad':
      return 'assets/images/reactions/sad.png';
    case 'Angry':
      return 'assets/images/reactions/angry.png';
    case 'Like':
      return 'assets/images/reactions/like.png';
    default:
      return 'assets/images/reactions/like_outline.png';
  }
}

typedef _OnReactionSelect = void Function(String);

void _showReactionsOverlay(
  BuildContext context,
  Offset globalPos, {
  required _OnReactionSelect onSelect,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(builder: (_) {
    final RenderBox overlayBox =
        overlay.context.findRenderObject() as RenderBox;
    final Offset local = overlayBox.globalToLocal(globalPos);

    // Kích thước khung popup (ước lượng), để canh nằm ngay trên nút
    const double popupWidth = 300;
    const double popupHeight = 56;

    return Stack(
      children: [
        // Tap ra ngoài để tắt
        Positioned.fill(
          child: GestureDetector(onTap: () => entry.remove()),
        ),
        Positioned(
          left: (local.dx - popupWidth / 2)
              .clamp(8.0, overlayBox.size.width - popupWidth - 8.0),
          top: (local.dy - popupHeight - 12)
              .clamp(8.0, overlayBox.size.height - popupHeight - 8.0),
          width: popupWidth,
          height: popupHeight,
          child: _ReactionBar(
            onPick: (v) {
              onSelect(v);
              entry.remove();
            },
          ),
        ),
      ],
    );
  });

  overlay.insert(entry);
}

class _ReactionBar extends StatelessWidget {
  final ValueChanged<String> onPick;
  const _ReactionBar({required this.onPick});

  @override
  Widget build(BuildContext context) {
    const items = ['Like', 'Love', 'HaHa', 'Wow', 'Sad', 'Angry'];
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: items.map((e) {
              return GestureDetector(
                onTap: () => onPick(e),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _reactionIcon(e, size: 28),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _PostAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: onSurface.withOpacity(.7)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: onSurface.withOpacity(.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Post {
  final String userName;
  final String timeAgo;
  final String text;
  final String? imageUrl;
  final bool isOnline;

  _Post({
    required this.userName,
    required this.timeAgo,
    required this.text,
    this.imageUrl,
    this.isOnline = false,
  });
}

class _Story {
  final String name;
  final String? imageUrl;
  final bool isCreateStory;

  _Story({
    required this.name,
    this.imageUrl,
    this.isCreateStory = false,
  });
}

// Small helper to avoid EdgeInsets.zero import everywhere
class EdgeBox {
  static const zero = EdgeInsets.zero;
}
