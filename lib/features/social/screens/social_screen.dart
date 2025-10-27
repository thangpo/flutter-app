import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/create_post_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/create_story_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_post_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/share_post_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/widgets/shared_post_preview.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_story_viewer_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/widgets/social_post_media.dart';
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
    // Refresh sau khi màn hình mount d? ch?c có token
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
                            // Block "B?n dang nghi gì?"
                            return Column(
                              children: [
                                _WhatsOnYourMind(),
                                const _SectionSeparator(), // tách v?i Stories
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

                          // Các post: b?t d?u t? i=2
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
    // uu tiên appBarTheme.backgroundColor; fallback sang highlightColor (Home cung dang dùng highlightColor)
    final Color appBarColor =
        theme.appBarTheme.backgroundColor ?? theme.highlightColor;
    // Ch?n màu ch?/icon tuong ph?n trên n?n appBarColor
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
                  // TODO: n?u mu?n m? màn tìm ki?m
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
                      const SnackBar(
                          content: Text(
                              'Vui lòng k?t n?i tài kho?n WoWonder tru?c.')),
                    );
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => FriendsListScreen(accessToken: token)),
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
      child:
          Icon(icon, color: iconColor ?? onSurface.withOpacity(.9), size: 24),
    );

    return onTap == null
        ? child
        : InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: onTap,
            child: child);
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

class SocialPostCard extends StatelessWidget {
  final SocialPost post;
  const SocialPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final Color baseColor = Theme.of(context).scaffoldBackgroundColor;
    final SocialPost? sharedPost = post.sharedPost;
    final bool hasSharedPost = sharedPost != null;
    final Widget? mediaContent = hasSharedPost
        ? SharedPostPreviewCard(
            post: sharedPost!,
            compact: true,
            padding: const EdgeInsets.all(10),
            onTap: () => _openSharedPostDetail(context, sharedPost),
          )
        : buildSocialPostMedia(context, post);
    final List<String> topReactions = _topReactionLabels(post);
    final int shareCount = post.shareCount;
    final bool isSharing = context.select<SocialController, bool>(
      (ctrl) => ctrl.isSharing(post.id),
    );

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
                      if (hasSharedPost)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _sharedSubtitleText(context, post),
                            style: TextStyle(
                              color: onSurface.withOpacity(.7),
                              fontSize: 13,
                            ),
                          ),
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
                        '${_formatSocialCount(post.commentCount)} ${getTranslated('comments', context) ?? 'bình lu?n'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: onSurface.withOpacity(.7),
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_formatSocialCount(shareCount)} ${getTranslated('share_plural', context) ?? 'lu?t chia s?'}',
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
                // Nút Reaction: tap = Like/UnLike; long-press = ch?n reaction
                Expanded(
                  child: Builder(
                    builder: (itemCtx) => InkWell(
                      onTap: () {
                        final now = (post.myReaction == 'Like') ? '' : 'Like';
                        itemCtx.read<SocialController>().reactOnPost(post, now);
                      },
                      onLongPress: () {
                        // Tính t?a d? trung tâm nút Like d? hi?n popup ngay trên nút
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
                  loading: isSharing,
                  onTap: isSharing
                      ? null
                      : () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SharePostScreen(post: post),
                              fullscreenDialog: true,
                            ),
                          );
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openSharedPostDetail(BuildContext context, SocialPost shared) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SocialPostDetailScreen(post: shared),
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final List<String> urls;
  const _ImageGrid({required this.urls});

  @override
  Widget build(BuildContext context) {
    // ép kích thu?c t?ng th? con bám trong c?t/ràng bu?c
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

  // ?nh vuông dùng bên trong grid
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
      return 'Bu?n';
    case 'Angry':
      return 'Ph?n n?';
    default:
      return reaction;
  }
}

String _sharedSubtitleText(BuildContext context, SocialPost parent) {
  final SocialPost? shared = parent.sharedPost;
  if (shared == null) return '';
  final String owner =
      parent.userName ?? (getTranslated('user', context) ?? 'User');
  final String original =
      shared.userName ?? (getTranslated('user', context) ?? 'User');
  final String verb =
      getTranslated('shared_post_from', context) ?? 'shared a post from';
  return '$owner $verb $original';
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

    // Kích thu?c khung popup, canh n?m ngay trên nút
    const double popupWidth = 300;
    const double popupHeight = 56;

    return Stack(
      children: [
        // Tap ra ngoài d? t?t
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
  final bool loading;
  const _PostAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final bool enabled = onTap != null && !loading;
    final Color iconColor = onSurface.withOpacity(enabled ? .7 : .4);

    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(iconColor),
                  ),
                )
              else
                Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: iconColor,
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
