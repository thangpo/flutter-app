import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/create_post_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/create_story_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_post_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/share_post_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/widgets/shared_post_preview.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_story_viewer_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/widgets/social_post_media.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_search_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/friends_list_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/friends_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_group_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_group.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/profile_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/widgets/social_post_text_block.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/social_feeling_helper.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_post_full_with_screen.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  SocialFeedScreenState createState() => SocialFeedScreenState();
}

class SocialFeedScreenState extends State<SocialFeedScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sc = context.read<SocialController>();
      sc.loadCurrentUser();
      sc.loadPostBackgrounds();
      if (sc.posts.isEmpty) {
        sc.refresh();
      }
    });
  }

  bool get isAtTop {
    if (!_scrollController.hasClients) return true;
    return _scrollController.position.pixels <= 8;
  }

  Future<void> scrollToTop() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  Future<void> refreshFeed() async {
    if (!mounted) return;
    _refreshKey.currentState?.show();
    await context.read<SocialController>().refresh();
  }

  Future<void> handleTabReselect() async {
    if (!mounted) return;
    if (!isAtTop) {
      await scrollToTop();
    } else {
      await refreshFeed();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                    key: _refreshKey,
                    onRefresh: () => sc.refresh(),
                    child: NotificationListener<ScrollNotification>(
                      // onNotification: (n) {
                      //   if (n.metrics.pixels >=
                      //       n.metrics.maxScrollExtent - 200) {
                      //     sc.loadMore();
                      //   }
                      //   return false;
                      // },
                      child: ListView.builder(
                        controller: _scrollController,
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
                          // Prefetch: khi người dùng chạm tới “nửa sau” của lô hiện tại thì nạp thêm
                          const int pageSize = 10; // lô hiện tại đang là 10
                          const int prefetchAt = pageSize ~/
                              2; // 5  (tức là tới bài 5–6 sẽ gọi nạp)
                          final int itemIndex = i - 2; // index trong mảng posts

                          if (!sc.loading &&
                              itemIndex >= sc.posts.length - prefetchAt) {
                            sc.loadMore();
                          }

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
            height: 35,
            fit: BoxFit.contain,
          ),
          Row(
            children: [
              _HeaderIcon(
                icon: Icons.search,
                iconColor: onAppBar,
                bubbleColor: onAppBar.withOpacity(0.08),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SocialSearchScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              _HeaderIcon(
                icon: Icons.people_outline, // biểu tượng bạn bè
                iconColor: onAppBar,
                bubbleColor: onAppBar.withOpacity(0.08),
                onTap: () {
                  final token = context.read<SocialController>().accessToken;
                  if (token == null || token.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Vui lòng kết nối tài khoản WoWonder trước.')),
                    );
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FriendsScreen(),
                    ),
                  );
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
                      builder: (_) => FriendsListScreen(accessToken: token),
                    ),
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

    // ⚠️ Đổi .path -> .toString() để NetworkImage nhận URL đầy đủ
    final String? avatarUrl = () {
      final candidates = [
        user?.avatarUrl?.trim(),
        fallbackProfile?.imageFullUrl?.toString().trim(),
        fallbackProfile?.image?.trim(),
      ];
      for (final v in candidates) {
        if (v != null && v.isNotEmpty) return v;
      }
      return null;
    }();

    return Material(
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ===== Avatar: bấm -> ProfileScreen =====
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              borderRadius: BorderRadius.circular(999),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: cs.surfaceVariant,
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? Icon(Icons.person, color: cs.onSurface.withOpacity(.6))
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // ===== Ô “Bạn đang nghĩ gì?”: bấm -> tạo post =====
            Expanded(
              child: Material(
                // đảm bảo có Material ancestor cho InkWell
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SocialCreatePostScreen(),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Builder(
                    builder: (context) {
                      final cs =
                          Theme.of(context).colorScheme; // <-- thêm dòng này
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: cs.surfaceVariant.withOpacity(.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          getTranslated(
                                  'whats_on_your_mind', context) // <-- sửa key
                              ??
                              "What's on your mind?",
                          style: TextStyle(
                            color: cs.onSurface.withOpacity(.7),
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // (tuỳ chọn) nút +
            InkWell(
              onTap: () {/* TODO: action khác (ví dụ tạo story) */},
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, color: cs.onSurface, size: 20),
              ),
            ),
          ],
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
    final ColorScheme cs = Theme.of(context).colorScheme;
    final social = context.watch<SocialController>();
    final profileCtrl = context.watch<ProfileController>();
    final fallbackProfile = profileCtrl.userInfoModel;
    final SocialUser? user = social.currentUser;
    final String? avatar = () {
      final List<String?> candidates = <String?>[
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

    void openCreateStory() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SocialCreateStoryScreen(),
          fullscreenDialog: true,
        ),
      );
    }

    return Container(
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: openCreateStory,
            child: Stack(
              children: [
                if (avatar != null && avatar.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: avatar,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  )
                else
                  Container(color: cs.surfaceVariant),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.45),
                          Colors.black.withOpacity(0.05),
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 6)
                        ],
                      ),
                      child:
                          const Icon(Icons.add, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
  final ValueChanged<SocialPost>? onPostUpdated;
  const SocialPostCard({required this.post, this.onPostUpdated});

  @override
  Widget build(BuildContext context) {
    final SocialPost post = context.select<SocialController, SocialPost?>(
          (ctrl) => ctrl.findPostById(this.post.id),
        ) ??
        this.post;
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final Color baseColor = Theme.of(context).scaffoldBackgroundColor;
    final SocialPost? sharedPost = post.sharedPost;
    final bool hasSharedPost = sharedPost != null;
    final bool hasFeeling = SocialFeelingHelper.hasFeeling(post);
    final bool showFeelingInHeader = hasFeeling && !hasSharedPost;
    final String? feelingLabel = showFeelingInHeader
        ? SocialFeelingHelper.labelForPost(context, post)
        : null;
    final String? feelingEmoji =
        showFeelingInHeader ? SocialFeelingHelper.emojiForPost(post) : null;
    final Widget? mediaContent = hasSharedPost
        ? SharedPostPreviewCard(
            post: sharedPost!,
            compact: true,
            padding: const EdgeInsets.all(10),
            parentPostId: post.id,
            onTap: () => _openSharedPostDetail(context, sharedPost),
          )
        : buildSocialPostMedia(context, post);
    final List<String> topReactions = _topReactionLabels(post);
    final int shareCount = post.shareCount;
    final bool isSharing = context.select<SocialController, bool>(
      (ctrl) => ctrl.isSharing(post.id),
    );
    final bool postActionBusy = context.select<SocialController, bool>(
      (ctrl) => ctrl.isPostActionBusy(post.id),
    );

    final int reactionCount = post.reactionCount;
    final int commentCount = post.commentCount;
    // shareCount đã có ở trên

    final bool showReactions = reactionCount > 0;
    final bool showComments = commentCount > 0;
    final bool showShares = shareCount > 0;
    final bool showStats = showReactions || showComments || showShares;
    final String? postLocation = post.postMap?.trim();
    final bool hasLocation =
        !hasSharedPost && postLocation != null && postLocation.isNotEmpty;
    final bool hasBackgroundText =
        SocialPostFullViewComposer.allowsBackground(post);
    final bool hasInlineImages =
        SocialPostFullViewComposer.normalizeImages(post).isNotEmpty;
    final bool backgroundWithMedia = hasBackgroundText && hasInlineImages;
    final double mediaTopSpacing = backgroundWithMedia ? 4 : 12;

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
                // ==== Avatar (bấm để mở ProfileScreen) ====
                InkWell(
                  borderRadius: BorderRadius.circular(40),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ProfileScreen(targetUserId: post.publisherId),
                        // targetUserId: post.publisherId,
                      ),
                    );
                  },
                  child: CircleAvatar(
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
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                            ),
                          )
                        : null,
                  ),
                ),

                const SizedBox(width: 10),

                // ==== Cột tên + time (bấm để mở ProfileScreen) ====
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ProfileScreen(targetUserId: post.publisherId),
                          // targetUserId: post.publisherId,
                        ),
                      );
                    },
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
                                  color: onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (post.isGroupPost &&
                                ((post.groupTitle ?? post.groupName)
                                        ?.isNotEmpty ??
                                    false)) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: onSurface.withOpacity(.6),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: GestureDetector(
                                  onTap: (post.groupId?.isNotEmpty ?? false)
                                      ? () => _openGroupDetailFromPost(
                                          context, post)
                                      : null,
                                  child: Text(
                                    post.groupTitle ?? post.groupName ?? '',
                                    style: TextStyle(
                                      color: onSurface.withOpacity(.75),
                                      fontWeight: FontWeight.w600,
                                      decoration:
                                          (post.groupId?.isNotEmpty ?? false)
                                              ? TextDecoration.underline
                                              : TextDecoration.none,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            if (feelingLabel != null &&
                                feelingLabel.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              if (feelingEmoji != null)
                                Text(
                                  feelingEmoji,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontSize: 18),
                                )
                              else
                                Icon(
                                  SocialFeelingHelper.iconForPost(post),
                                  size: 16,
                                  color: onSurface.withOpacity(.7),
                                ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  feelingLabel,
                                  style: TextStyle(
                                    color: onSurface.withOpacity(.75),
                                    fontStyle: FontStyle.italic,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ] else if ((post.postType ?? '').isNotEmpty) ...[
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
                                      ? (getTranslated(
                                              'updated_profile_picture',
                                              context) ??
                                          'updated profile picture')
                                      : post.postType == 'profile_cover_picture'
                                          ? (getTranslated(
                                                  'updated_cover_photo',
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
                            color: onSurface.withOpacity(.6),
                            fontSize: 13,
                          ),
                        ),
                        if (hasLocation)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.place_outlined,
                                  size: 14,
                                  color: onSurface.withOpacity(.65),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    postLocation!,
                                    style: TextStyle(
                                      color: onSurface.withOpacity(.7),
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // if (hasSharedPost)
                        //   Padding(
                        //     padding: const EdgeInsets.only(top: 2),
                        //     child: Text(
                        //       _sharedSubtitleText(context, post),
                        //       style: TextStyle(
                        //         color: onSurface.withOpacity(.7),
                        //         fontSize: 13,
                        //       ),
                        //     ),
                        //   ),
                      ],
                    ),
                  ),
                ),

                IconButton(
                  icon: postActionBusy
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color?>(
                              onSurface.withOpacity(.7),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.more_horiz,
                          color: onSurface.withOpacity(.7),
                        ),
                  onPressed: postActionBusy
                      ? null
                      : () => _showPostOptions(context, post),
                ),
              ],
            ),
          ),

          // Text
          SocialPostTextBlock(post: post),

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
            SizedBox(height: mediaTopSpacing),
            mediaContent,
            const SizedBox(height: 8),
          ],

          if (showStats)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SocialPostDetailScreen(post: post),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          if (showReactions)
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (topReactions.isNotEmpty)
                                    _ReactionIconStack(labels: topReactions),
                                  if (topReactions.isNotEmpty)
                                    const SizedBox(width: 6),
                                  Text(
                                    _formatSocialCount(reactionCount),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: onSurface.withOpacity(.85),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            )
                          else
                            const Expanded(child: SizedBox.shrink()),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Wrap(
                                spacing: 12,
                                children: [
                                  if (showComments)
                                    Text(
                                      '${_formatSocialCount(commentCount)} ${getTranslated("comments", context) ?? "comments"}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: onSurface.withOpacity(.7),
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (showShares)
                                    Text(
                                      '${_formatSocialCount(shareCount)} ${getTranslated("share_plural", context) ?? "shares"}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: onSurface.withOpacity(.7),
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
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
                  ],
                ),
              ),
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
                        itemCtx
                            .read<SocialController>()
                            .reactOnPost(post, now)
                            .then((updated) {
                          if (onPostUpdated != null) {
                            onPostUpdated!(updated);
                          }
                        });
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
                                .reactOnPost(post, val)
                                .then((updated) {
                              if (onPostUpdated != null) {
                                onPostUpdated!(updated);
                              }
                            });
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

  Future<void> _showPostOptions(BuildContext context, SocialPost post) async {
    final controller = context.read<SocialController>();
    final String? currentUserId = controller.currentUser?.id;
    final bool isOwner = currentUserId != null &&
        currentUserId.isNotEmpty &&
        currentUserId == post.publisherId;
    final action = await showModalBottomSheet<_PostOptionsAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _PostOptionsSheet(
        isOwner: isOwner,
        onSelected: (action) => Navigator.of(sheetCtx).pop(action),
      ),
    );

    if (action == null) return;

    switch (action) {
      case _PostOptionsAction.save:
        await controller.toggleSavePost(post);
        break;
      case _PostOptionsAction.edit:
        final String? newText = await _promptEditPost(context, post);
        if (newText != null) {
          await controller.editPost(post, text: newText);
        }
        break;
      case _PostOptionsAction.delete:
        await controller.deletePost(post);
        break;
      case _PostOptionsAction.report:
        await controller.reportPost(post);
        break;
      case _PostOptionsAction.hide:
        await controller.hidePost(post);
        break;
    }
  }

  Future<String?> _promptEditPost(BuildContext context, SocialPost post) async {
    final String initialText = _editableTextFromPost(post);
    final TextEditingController textController =
        TextEditingController(text: initialText);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        return AlertDialog(
          title: Text(
            getTranslated('edit_post', dialogCtx) ?? 'Edit post',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            maxLines: null,
            minLines: 3,
            decoration: InputDecoration(
              hintText: getTranslated('what_on_your_mind', dialogCtx) ??
                  'What\'s on your mind?',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(getTranslated('cancel', dialogCtx) ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop(textController.text);
              },
              child: Text(
                getTranslated('save_changes', dialogCtx) ?? 'Save',
              ),
            ),
          ],
        );
      },
    );

    if (result == null) return null;
    final String trimmed = result.trim();
    final String original = initialText.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTranslated('post_text_required', context) ??
              'Post text cannot be empty'),
        ),
      );
      return null;
    }
    if (trimmed == original) {
      return null;
    }
    return trimmed;
  }

  void _openGroupDetailFromPost(BuildContext context, SocialPost post) {
    final String? groupId = post.groupId;
    if (groupId == null || groupId.isEmpty) return;
    SocialGroup? initial;
    final String? name = post.groupName ?? post.groupTitle;
    if ((name?.isNotEmpty ?? false) ||
        (post.groupAvatar?.isNotEmpty ?? false) ||
        (post.groupCover?.isNotEmpty ?? false)) {
      initial = SocialGroup(
        id: groupId,
        name: (name != null && name.trim().isNotEmpty) ? name.trim() : groupId,
        title: post.groupTitle,
        avatarUrl: post.groupAvatar,
        coverUrl: post.groupCover,
        memberCount: 0,
        pendingCount: 0,
        isJoined: false,
        isAdmin: false,
        isOwner: false,
        requiresApproval: false,
        joinRequestStatus: 0,
      );
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SocialGroupDetailScreen(
          groupId: groupId,
          initialGroup: initial,
        ),
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

enum _PostOptionsAction { save, edit, delete, report, hide }

class _PostOptionEntry {
  final _PostOptionsAction action;
  final IconData icon;
  final String labelKey;
  final String fallback;
  final bool highlighted;
  const _PostOptionEntry({
    required this.action,
    required this.icon,
    required this.labelKey,
    required this.fallback,
    this.highlighted = false,
  });
}

class _PostOptionsSheet extends StatelessWidget {
  final ValueChanged<_PostOptionsAction> onSelected;
  final bool isOwner;
  const _PostOptionsSheet({
    required this.onSelected,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final Color sheetColor = theme.dialogTheme.backgroundColor ?? cs.surface;
    final options = <_PostOptionEntry>[
      const _PostOptionEntry(
        action: _PostOptionsAction.save,
        icon: Icons.bookmark_border,
        labelKey: 'save_post',
        fallback: 'Save post',
        highlighted: true,
      ),
      if (isOwner) ...[
        const _PostOptionEntry(
          action: _PostOptionsAction.edit,
          icon: Icons.edit_outlined,
          labelKey: 'edit_post',
          fallback: 'Edit post',
          highlighted: true,
        ),
        const _PostOptionEntry(
          action: _PostOptionsAction.delete,
          icon: Icons.delete_outline,
          labelKey: 'delete_post',
          fallback: 'Delete',
          highlighted: true,
        ),
      ] else
        const _PostOptionEntry(
          action: _PostOptionsAction.report,
          icon: Icons.flag_outlined,
          labelKey: 'report_post',
          fallback: 'Report',
        ),
      const _PostOptionEntry(
        action: _PostOptionsAction.hide,
        icon: Icons.visibility_off_outlined,
        labelKey: 'hide_post',
        fallback: 'Hide',
      ),
    ];

    String label(String key, String fallback) =>
        getTranslated(key, context) ?? fallback;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Material(
        color: sheetColor,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label('post_options', 'Post options'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      splashRadius: 20,
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < options.length; i++) ...[
                      _PostOptionsTile(
                        entry: options[i],
                        labelBuilder: label,
                        theme: theme,
                        colorScheme: cs,
                        onTap: () => onSelected(options[i].action),
                      ),
                      if (i != options.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostOptionsTile extends StatelessWidget {
  final _PostOptionEntry entry;
  final String Function(String key, String fallback) labelBuilder;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  const _PostOptionsTile({
    required this.entry,
    required this.labelBuilder,
    required this.theme,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDestructive = entry.action == _PostOptionsAction.delete;
    final bool isAccent = entry.highlighted && !isDestructive;
    final Color accentColor = isDestructive
        ? colorScheme.error
        : (isAccent ? colorScheme.primary : colorScheme.onSurface);
    final Color tileColor = colorScheme.surfaceVariant.withOpacity(
      theme.brightness == Brightness.dark ? 0.35 : 0.65,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(entry.icon, color: accentColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                labelBuilder(entry.labelKey, entry.fallback),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      isDestructive ? colorScheme.error : colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _editableTextFromPost(SocialPost post) {
  final String? raw = post.rawText;
  if (raw != null && raw.trim().isNotEmpty) {
    return raw;
  }
  final String? htmlText = post.text;
  if (htmlText == null || htmlText.isEmpty) {
    return '';
  }
  String normalized = htmlText.replaceAll(
    RegExp(r'<br\s*/?>', caseSensitive: false),
    '\n',
  );
  normalized = normalized.replaceAll(
    RegExp(r'</p\s*>', caseSensitive: false),
    '\n',
  );
  normalized = normalized.replaceAll(
    RegExp(r'<p[^>]*>', caseSensitive: false),
    '',
  );
  normalized = normalized.replaceAll(RegExp(r'<[^>]+>'), '');
  normalized = _decodeBasicHtmlEntities(normalized);
  return normalized;
}

String _decodeBasicHtmlEntities(String input) {
  return input
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&#8217;', "'")
      .replaceAll('&#8220;', '"')
      .replaceAll('&#8221;', '"');
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
      return 'Buồn';
    case 'Angry':
      return 'Phẫn nộ';
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
  return '$verb $original';
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
