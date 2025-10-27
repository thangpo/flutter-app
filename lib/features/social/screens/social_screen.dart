import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/controllers/product_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/screens/product_details_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/create_post_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/create_story_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_post_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_story_viewer_screen.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/friends_list_screen.dart';


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
    // Refresh sau khi màn hình mount để chắc có token
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sc = context.read<SocialController>();
      sc.loadCurrentUser();
      if (sc.posts.isEmpty) {
        sc.refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;

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
                                return Column(
                                  children: [
                                    _StoriesSectionFromApi(
                                        stories: sc2.stories),
                                  ],
                                );
                              },
                            );
                          }

                          // Các post: bắt đầu từ i=2
                          final SocialPost p = sc.posts[i - 2];
                          return SocialPostCard(post: p);
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
    final theme = Theme.of(context);
    // ưu tiên appBarTheme.backgroundColor; fallback sang highlightColor (Home cũng đang dùng highlightColor)
    final Color appBarColor =
        theme.appBarTheme.backgroundColor ?? theme.highlightColor;
    // Chọn màu chữ/icon tương phản trên nền appBarColor
    final bool isDark =
        ThemeData.estimateBrightnessForColor(appBarColor) == Brightness.dark;
    final Color onAppBar = isDark ? Colors.white : Colors.black87;

    final sc = context.read<SocialController>();
    final token = sc.accessToken; 

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
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
                bubbleColor: onAppBar.withOpacity(0.08),
                onTap: () {
                  // TODO: nếu muốn mở màn tìm kiếm
                },
              ),
              const SizedBox(width: 12),
             _HeaderIcon(
                icon: Icons.messenger_outline,
                iconColor: onAppBar,
                bubbleColor: onAppBar.withOpacity(0.08),
                onTap: () {
                  final token = context.read<SocialController>().accessToken;
                  if (token == null || token.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng kết nối tài khoản WoWonder trước.')),
                    );
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => FriendsListScreen(accessToken: token)),
                  );
                },
              ),
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
  final VoidCallback? onTap;
  const _HeaderIcon({
    required this.icon,
    this.iconColor,
    this.bubbleColor,
     this.onTap, 
  });

 @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    final child = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bubbleColor ?? cs.surfaceVariant,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: iconColor ?? onSurface.withOpacity(.9), size: 24),
    );

    return onTap == null
        ? child
        : InkWell(borderRadius: BorderRadius.circular(100), onTap: onTap, child: child); 
  }
}

class _WhatsOnYourMind extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final social = context.watch<SocialController>();
    final user = social.currentUser;
    final profileCtrl = context.watch<ProfileController>();
    final fallbackProfile = profileCtrl.userInfoModel;
    final String? avatarUrl = () {
      final candidates = [
        user?.avatarUrl?.trim(),
        fallbackProfile?.imageFullUrl?.path?.trim(),
        fallbackProfile?.image?.trim(),
      ];
      for (final value in candidates) {
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
      return null;
    }();

    return Material(
      color: cs.surface,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SocialCreatePostScreen(),
              fullscreenDialog: true,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: cs.surfaceVariant,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Icon(Icons.person, color: cs.onSurface.withOpacity(.6))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  getTranslated('whats_on_your_mind', context) ??
                      'What’s on your mind?',
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(.7),
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
                child: Icon(Icons.add, color: cs.onSurface, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionSeparator extends StatelessWidget {
  const _SectionSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 8),
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
    final SocialUser? currentUser =
        context.select<SocialController, SocialUser?>((c) => c.currentUser);
    final SocialStory? myStory = context
        .select<SocialController, SocialStory?>((c) => c.currentUserStory);

    String storyKey(SocialStory story) {
      final userId = story.userId;
      if (userId != null && userId.isNotEmpty) {
        return 'user:$userId';
      }
      return 'story:${story.id}';
    }

    bool isCurrentUserStory(SocialStory story) {
      if (currentUser == null) return false;
      if (story.userId != null && story.userId == currentUser.id) {
        return true;
      }
      final storyName =
          story.userName != null ? story.userName!.trim().toLowerCase() : '';
      if (storyName.isEmpty) return false;
      final firstName = (currentUser.firstName ?? '').trim();
      final lastName = (currentUser.lastName ?? '').trim();
      final possibleNames = <String>{
        (currentUser.displayName ?? '').trim().toLowerCase(),
        (currentUser.userName ?? '').trim().toLowerCase(),
        ('$firstName $lastName').trim().toLowerCase(),
      }..removeWhere((value) => value.isEmpty);
      return possibleNames.contains(storyName);
    }

    final seenKeys = <String>{};
    final dedupedStories = <SocialStory>[];
    for (final story in stories) {
      final key = storyKey(story);
      if (seenKeys.add(key)) {
        dedupedStories.add(story);
      }
    }

    dedupedStories.removeWhere((story) => !story.hasItems);

    final List<SocialStory> orderedStories = <SocialStory>[];
    if (myStory != null) {
      final key = storyKey(myStory);
      dedupedStories.removeWhere((story) => storyKey(story) == key);
      orderedStories.add(myStory);
    } else if (currentUser != null) {
      final idx = dedupedStories.indexWhere(isCurrentUserStory);
      if (idx >= 0) {
        orderedStories.add(dedupedStories.removeAt(idx));
      }
    }

    orderedStories.addAll(dedupedStories);

    return Container(
      height: 200,
      color: cs.surface,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // intercept horizontal scroll events
          if (notification.metrics.axis == Axis.horizontal &&
              notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 100) {
            final sc = context.read<SocialController>();
            if (!sc.loading) sc.loadMoreStories();
          }
          return false;
        },
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          itemCount: orderedStories.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const _CreateStoryCard();
            }
            final storyIndex = index - 1;
            final story = orderedStories[storyIndex];
            return _StoryCardFromApi(
              story: story,
              onTap: story.items.isEmpty
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SocialStoryViewerScreen(
                            stories: List<SocialStory>.from(orderedStories),
                            initialStoryIndex: storyIndex,
                          ),
                        ),
                      );
                    },
            );
          },
        ),
      ),
    );
  }
}

class _StoryCardFromApi extends StatelessWidget {
  final SocialStory story;
  final VoidCallback? onTap;
  const _StoryCardFromApi({required this.story, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final thumb = story.thumbUrl ?? story.mediaUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}

class _CreateStoryCard extends StatelessWidget {
  const _CreateStoryCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final social = context.watch<SocialController>();
    final profileCtrl = context.watch<ProfileController>();
    final fallbackProfile = profileCtrl.userInfoModel;
    final SocialUser? user = social.currentUser;
    final String? avatar = () {
      final candidates = [
        user?.avatarUrl?.trim(),
        fallbackProfile?.imageFullUrl?.path?.trim(),
        fallbackProfile?.image?.trim(),
      ];
      for (final value in candidates) {
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
      return null;
    }();

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
                    Text(
                      getTranslated('your_story', context) ?? 'Your story',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SocialCreateStoryScreen(),
                      fullscreenDialog: true,
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: Text(getTranslated('create', context) ?? 'Create'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(32),
                ),
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

// ảnh full-width, tối đa tỷ lệ theo kích thước thật
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
      builder: (ctx, c) {
        final maxHeight = MediaQuery.of(ctx).size.height * 0.8;
        final width = c.maxWidth;
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
            child: Image(
              image: CachedNetworkImageProvider(widget.url),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
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
          aspectRatio: 1, // vùng ảnh Instagram
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
            child: Text(
              widget.title ?? (getTranslated('audio', context) ?? 'Audio'),
              style: TextStyle(color: onSurface),
            ),
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
    final height = width; // vùng giống FB
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
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final ratio = _c!.value.aspectRatio == 0 ? (16 / 9) : _c!.value.aspectRatio;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = MediaQuery.of(context).size.height * 0.6;
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
                VideoPlayer(_c!),
                Align(
                  alignment: Alignment.center,
                  child: IconButton(
                    iconSize: 48,
                    color: Colors.white,
                    icon: Icon(_c!.value.isPlaying
                        ? Icons.pause_circle
                        : Icons.play_circle),
                    onPressed: () {
                      _c!.value.isPlaying ? _c!.pause() : _c!.play();
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

class SocialPostCard extends StatelessWidget {
  final SocialPost post;
  const SocialPostCard({required this.post});

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

    Widget? _media() {
      // 0) VIDEO
      if (_isVideo(fileUrl)) {
        return _VideoPlayerTile(url: fileUrl!);
      }

      // 1) PRODUCT
      if (post.hasProduct == true &&
          (post.productImages?.isNotEmpty ?? false)) {
        return _ProductPostTile(post: post);
      }

      // 1.5) ẢNH + AUDIO => Carousel/AutoAudio
      if (images.isNotEmpty && _isAudio(fileUrl)) {
        return _ImagesWithAutoAudio(images: images, audioUrl: fileUrl!);
      }

      // 2) MULTI IMAGE GRID
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

      // 3) ẢNH ĐƠN
      if (hasSingle) {
        final String src = images.isNotEmpty ? images.first : (post.imageUrl!);
        return _AutoRatioNetworkImage(src);
      }

      // 4) FILE (âm thanh / PDF / Khác)
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
                        (getTranslated('audio', context) ?? 'Audio'),
                    style: TextStyle(color: onSurface),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {}, // hook player khi cần
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
                        (getTranslated('pdf_document', context) ??
                            'PDF document'),
                    style: TextStyle(color: onSurface),
                  ),
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

      // 5) Chỉ text
      return null;
    }

    final Color baseColor = Theme.of(context).scaffoldBackgroundColor;
    final Widget? mediaContent = _media();
    final List<String> topReactions = _topReactionLabels(post);
    final int shareCount = post.shareCount > 0 ? post.shareCount : 31;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: baseColor,
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
                              post.userName ?? '',
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
                                    ? (getTranslated('updated_profile_picture',
                                            context) ??
                                        'updated profile picture')
                                    : post.postType == 'profile_cover_picture'
                                        ? (getTranslated('updated_cover_photo',
                                                context) ??
                                            'updated cover photo')
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

          if (mediaContent != null) ...[
            const SizedBox(height: 12),
            mediaContent,
            const SizedBox(height: 8),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (topReactions.isNotEmpty)
                        _ReactionIconStack(labels: topReactions),
                      if (topReactions.isNotEmpty) const SizedBox(width: 6),
                      Text(
                        _formatSocialCount(post.reactionCount),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: onSurface.withOpacity(.85),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${_formatSocialCount(post.commentCount)} ${getTranslated('comments', context) ?? 'bình luận'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: onSurface.withOpacity(.7),
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_formatSocialCount(shareCount)} ${getTranslated('share_plural', context) ?? 'lượt chia sẻ'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: onSurface.withOpacity(.7),
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: .6,
            color: cs.surfaceVariant.withOpacity(.6),
          ),
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
                        // Tính tọa độ trung tâm nút Like để hiển popup ngay trên nút
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
                              _reactionActionLabel(context, post.myReaction),
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
                  label: (getTranslated('comment', context) ?? 'Comment'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SocialPostDetailScreen(post: post),
                      ),
                    );
                  },
                ),
                _PostAction(
                  icon: Icons.share_outlined,
                  label: (getTranslated('share', context) ?? 'Share'),
                ),
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
    // ép kích thước từng thẻ con bám trong cột/ràng buộc
    final double aspect = urls.length == 1 ? (16 / 9) : (16 / 9);
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
                    fit: StackFit.expand,
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

  // ảnh vuông dùng bên trong grid
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
List<String> _topReactionLabels(SocialPost post, {int limit = 3}) {
  final entries = post.reactionBreakdown.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  if (entries.isEmpty) {
    if (post.reactionCount > 0 || post.myReaction.isNotEmpty) {
      return <String>[
        post.myReaction.isNotEmpty ? post.myReaction : 'Like',
      ];
    }
    return const <String>[];
  }
  return entries.take(limit).map((e) => e.key).toList();
}

String _formatSocialCount(int value) {
  if (value <= 0) return '0';
  if (value < 1000) return value.toString();
  const units = [
    _CountUnit(threshold: 1000000000000, suffix: 'T'),
    _CountUnit(threshold: 1000000000, suffix: 'B'),
    _CountUnit(threshold: 1000000, suffix: 'M'),
    _CountUnit(threshold: 1000, suffix: 'K'),
  ];
  for (final unit in units) {
    if (value >= unit.threshold) {
      final double scaled = value / unit.threshold;
      final int precision = scaled >= 100 ? 0 : 1;
      final String formatted =
          _trimTrailingZeros(scaled.toStringAsFixed(precision));
      return '$formatted${unit.suffix}';
    }
  }
  return value.toString();
}

String _reactionActionLabel(BuildContext context, String reaction) {
  final String defaultLabel = getTranslated('like', context) ?? 'Thích';
  if (reaction.isEmpty || reaction == 'Like') return defaultLabel;
  switch (reaction) {
    case 'Love':
      return 'Yêu thích';
    case 'HaHa':
      return 'Haha';
    case 'Wow':
      return 'Wow';
    case 'Sad':
      return 'Buồn';
    case 'Angry':
      return 'Phẫn nộ';
    default:
      return reaction;
  }
}

class _ReactionIconStack extends StatelessWidget {
  final List<String> labels;
  final double size;
  const _ReactionIconStack({
    required this.labels,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    final double overlap = size * 0.67;
    final double width =
        size + (labels.length > 1 ? (labels.length - 1) * overlap : 0);
    final Color borderColor = Theme.of(context).scaffoldBackgroundColor;
    return SizedBox(
      height: size,
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = labels.length - 1; i >= 0; i--)
            Positioned(
              left: i * overlap,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: _reactionIcon(labels[i], size: size),
              ),
            ),
        ],
      ),
    );
  }
}

class _CountUnit {
  final int threshold;
  final String suffix;
  const _CountUnit({required this.threshold, required this.suffix});
}

String _trimTrailingZeros(String input) {
  if (!input.contains('.')) return input;
  return input.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
}

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

    // Kích thước khung popup, canh nằm ngay trên nút
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

class _ProductPostTile extends StatefulWidget {
  final SocialPost post;
  const _ProductPostTile({required this.post});

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
          if (images.isNotEmpty) _AutoRatioNetworkImage(images.first),
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
