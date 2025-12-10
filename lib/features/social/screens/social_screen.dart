import 'dart:math';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sixvalley_ecommerce/features/ads/domain/models/ads_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/event_controller.dart';
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
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_page_controller.dart'
    as page_ctrl;
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_get_page.dart'
    as page_models;
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_page_detail.dart'
    as page_screens;
import 'package:flutter_sixvalley_ecommerce/features/social/widgets/social_post_text_block.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/social_feeling_helper.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_post_full_with_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_event.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/event_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/widgets/social_event_attachment_loader.dart';

bool _listsEqual<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _isPrefix<T>(List<T> prefix, List<T> complete) {
  if (prefix.length > complete.length) return false;
  for (int i = 0; i < prefix.length; i++) {
    if (prefix[i] != complete[i]) return false;
  }
  return true;
}

class SocialFeedScreen extends StatefulWidget {
  final ValueChanged<bool>? onChromeVisibilityChanged;
  const SocialFeedScreen({super.key, this.onChromeVisibilityChanged});

  @override
  SocialFeedScreenState createState() => SocialFeedScreenState();
}

class SocialFeedScreenState extends State<SocialFeedScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();
  final Random _adsRandom = Random();
  List<int> _postAdSlots = <int>[];
  List<String> _eligiblePostSnapshot = <String>[];
  List<int?> _postAdIdSnapshot = <int?>[];
  bool _chromeVisible = true;
  double _lastScrollOffset = 0.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sc = context.read<SocialController>();
      sc.loadCurrentUser();
      sc.loadPostBackgrounds();
      sc.fetchAdsForFeed();
      sc.refreshBirthdays();
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
    _setChromeVisible(true);
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _ensurePostAdSlots(
    List<SocialPost> posts,
    List<AdsModel> ads,
    Set<String> eligiblePostIds,
  ) {
    final List<_EligiblePostEntry> eligibleEntries = <_EligiblePostEntry>[];
    for (int i = 0; i < posts.length; i++) {
      final String? id = posts[i].id;
      if (id != null && id.isNotEmpty && eligiblePostIds.contains(id)) {
        eligibleEntries.add(_EligiblePostEntry(index: i, id: id));
      }
    }

    final int eligibleCount = eligibleEntries.length;
    final int adCount = ads.length;
    final List<int?> adIds = List<int?>.generate(
      adCount,
      (index) => ads[index].id,
    );

    final List<String> newEligibleKeys =
        eligibleEntries.map((entry) => entry.id).toList();
    final List<String> previousKeys = List<String>.from(_eligiblePostSnapshot);
    final bool adsChanged = !_listsEqual(adIds, _postAdIdSnapshot);
    final bool eligibleExtended = _isPrefix(previousKeys, newEligibleKeys) &&
        newEligibleKeys.length >= previousKeys.length;

    _eligiblePostSnapshot = newEligibleKeys;
    _postAdIdSnapshot = adIds;

    if (eligibleCount <= 0 || adCount <= 0) {
      _postAdSlots = <int>[];
      return;
    }

    final int targetSlots = min(adCount, max(1, (eligibleCount / 2).ceil()));

    final bool requireFullReset =
        _postAdSlots.isEmpty || adsChanged || !eligibleExtended;

    final List<int> eligibleIndexes =
        eligibleEntries.map((entry) => entry.index).toList();

    if (requireFullReset) {
      eligibleIndexes.shuffle(_adsRandom);
      _postAdSlots = eligibleIndexes.take(targetSlots).toList()..sort();
      return;
    }

    if (_postAdSlots.length > targetSlots) {
      _postAdSlots = _postAdSlots.take(targetSlots).toList()..sort();
      return;
    }

    if (_postAdSlots.length >= targetSlots) return;

    final int previousCount = previousKeys.length;
    final Set<int> existing = _postAdSlots.toSet();
    final List<int> newEligibleIndexes = eligibleEntries
        .skip(previousCount)
        .map((entry) => entry.index)
        .where((index) => !existing.contains(index))
        .toList();
    final List<int> available =
        eligibleIndexes.where((index) => !existing.contains(index)).toList();
    final List<int> candidate =
        newEligibleIndexes.isNotEmpty ? newEligibleIndexes : available;
    candidate.shuffle(_adsRandom);
    final int needed = targetSlots - _postAdSlots.length;
    _postAdSlots.addAll(candidate.take(needed));
    _postAdSlots.sort();
  }

  AdsModel? _postAdForIndex(int postIndex, List<AdsModel> ads) {
    if (ads.isEmpty || postIndex < 0) return null;
    final int slotIdx = _postAdSlots.indexOf(postIndex);
    if (slotIdx != -1) {
      return ads[slotIdx % ads.length];
    }
    return null;
  }

  Future<void> refreshFeed() async {
    if (!mounted) return;
    _refreshKey.currentState?.show();
    _resetPostAdSlots();
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
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _resetPostAdSlots() {
    _postAdSlots = <int>[];
    _eligiblePostSnapshot = <String>[];
    _postAdIdSnapshot = <int?>[];
  }

  void _setChromeVisible(bool visible) {
    if (_chromeVisible == visible) return;
    setState(() {
      _chromeVisible = visible;
    });
    widget.onChromeVisibilityChanged?.call(visible);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final double offset = _scrollController.position.pixels;
    final double delta = offset - _lastScrollOffset;
    _lastScrollOffset = offset;

    if (offset <= 0) {
      _setChromeVisible(true);
      return;
    }

    const double threshold = 8.0;
    if (delta > threshold) {
      _setChromeVisible(false);
    } else if (delta < -threshold) {
      _setChromeVisible(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bool isLightTheme = theme.brightness == Brightness.light;
    final bool isDarkTheme = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final bool isIOSPlatform = !kIsWeb && Platform.isIOS;
    final double statusBar = mediaQuery.padding.top;
    final Color pageBg = isLightTheme ? cs.surface : cs.background;
    const double iosToolbarHeight = 52;
    final double toolbarHeight =
        isIOSPlatform ? iosToolbarHeight : kToolbarHeight;
    final double listTopPadding =
    _chromeVisible ? 8.0 : statusBar + 8.0;
    final double listBottomPadding = mediaQuery.padding.bottom + 16;

    final Widget feedContent = Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
              child: ColoredBox(
                color: pageBg,
                child: SafeArea(
                top: false,
                bottom: false,
                child: Consumer<SocialController>(
                  builder: (context, sc, _) {
                    if (sc.loading && sc.posts.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    const int headerCount = 3;
                    final List<AdsModel> postAds = sc.postAds;
                    final List<SocialPost> posts = sc.posts;
                    final Set<String> eligibleIds = sc.postAdEligibleIds;
                    _ensurePostAdSlots(posts, postAds, eligibleIds);
                    return RefreshIndicator(
                      key: _refreshKey,
                      onRefresh: () async {
                        _resetPostAdSlots();
                        await Future.wait([
                          sc.refresh(),
                          sc.fetchAdsForFeed(force: true),
                          sc.refreshBirthdays(force: true),
                        ]);
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.only(
                          top: listTopPadding,
                          bottom: listBottomPadding,
                        ),
                        itemCount: posts.length + headerCount,
                        itemBuilder: (ctx, i) {
                          if (i == 0) {
                            // Block "B?n dang nghi gÃ¬?"
                            return Column(
                              children: [
                                _WhatsOnYourMind(),
                                const _SectionSeparator(), // tÃ¡ch v?i Stories
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
                                      stories: sc2.stories,
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                          if (i == 2) {
                            return _BirthdaySection(
                              users: sc.birthdayUsers, // ⭐ dùng list từ controller
                            );
                          }

                          final int postIndex = i - headerCount;
                          if (postIndex < 0 || postIndex >= posts.length) {
                            return const SizedBox.shrink();
                          }

                          final SocialPost p = posts[postIndex];
                          const int pageSize = 10;
                          const int prefetchAt = pageSize ~/ 2;

                          if (!sc.loading &&
                              postIndex >= posts.length - prefetchAt) {
                            sc.loadMore();
                          }

                          final AdsModel? inlineAd = _postAdForIndex(
                            postIndex,
                            postAds,
                          );

                          return Column(
                            children: [
                              SocialPostCard(post: p),
                              if (inlineAd != null) _PostAdCard(ad: inlineAd),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );

    final sc = context.read<SocialController>();
    final String logoAsset = isDarkTheme
        ? Images.logoWithNameSocialImageWhite
        : Images.logoWithNameSocialImage;

    void openSearch() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SocialSearchScreen(),
        ),
      );
    }

    void openFriends() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FriendsScreen(),
        ),
      );
    }

    void openMessages() {
      final token = sc.accessToken;
      if (token == null || token.isEmpty) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FriendsListScreen(
            accessToken: token,
          ),
        ),
      );
    }

    final PreferredSizeWidget? materialAppBar = !isIOSPlatform
        ? AppBar(
      backgroundColor: pageBg,
      elevation: 0,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Image.asset(
          logoAsset,
          height: 32,
          fit: BoxFit.contain,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _HeaderActionsPill(
            onSearch: openSearch,
            onFriends: openFriends,
            onMessages: openMessages,
          ),
        ),
      ],
    )
        : null;

    final AdaptiveAppBar adaptiveAppBar = AdaptiveAppBar(
      useNativeToolbar: isIOSPlatform,
      title: null,
      leading: isIOSPlatform
          ? Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Image.asset(
                logoAsset,
                height: 34,
                fit: BoxFit.contain,
              ),
            )
          : null,
      actions: isIOSPlatform
          ? [
              AdaptiveAppBarAction(
                iosSymbol: 'magnifyingglass',
                icon: Icons.search,
                onPressed: openSearch,
              ),
              AdaptiveAppBarAction(
                iosSymbol: 'person.2',
                icon: Icons.people_alt_outlined,
                onPressed: openFriends,
              ),
              AdaptiveAppBarAction(
                iosSymbol: 'message',
                icon: Icons.message_outlined,
                onPressed: openMessages,
              ),
            ]
          : null,
      appBar: materialAppBar,
    );

    return AdaptiveScaffold(
      appBar: _chromeVisible ? adaptiveAppBar : null,
      body: feedContent,
    );
  }
}

Future<void> _launchAdUrl(BuildContext context, String? url) async {
  if (url == null || url.trim().isEmpty) {
    _showAdLaunchError(context);
    return;
  }
  final Uri? uri = Uri.tryParse(url.trim());
  if (uri == null) {
    _showAdLaunchError(context);
    return;
  }
  try {
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      _showAdLaunchError(context);
    }
  } catch (_) {
    _showAdLaunchError(context);
  }
}

void _showAdLaunchError(BuildContext context) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Khng th?y qu?ng co')));
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
        fallbackProfile?.imageFullUrl?.toString().trim(),
        fallbackProfile?.image?.trim(),
      ];
      for (final v in candidates) {
        if (v != null && v.isNotEmpty) return v;
      }
      return null;
    }();

    final String placeholder =
        getTranslated('whats_on_your_mind', context) ??
            "What's on your mind?";

    void openComposer() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SocialCreatePostScreen(),
          fullscreenDialog: true,
        ),
      );
    }

    void openProfile() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        ),
      );
    }

    return Material(
      color: cs.surface,
      elevation: 1, // giống card FB
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Avatar
                InkWell(
                  onTap: openProfile,
                  borderRadius: BorderRadius.circular(999),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: cs.surfaceVariant,
                    backgroundImage: (avatarUrl != null &&
                        avatarUrl.isNotEmpty)
                        ? CachedNetworkImageProvider(avatarUrl)
                        : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? Icon(
                      Icons.person,
                      color: cs.onSurface.withOpacity(.6),
                    )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),

                // Ô nhập status
                Expanded(
                  child: InkWell(
                    onTap: openComposer,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceVariant.withOpacity(
                          theme.brightness == Brightness.light ? 0.7 : 0.3,
                        ),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: cs.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        placeholder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(.7),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Nút +
                InkWell(
                  onTap: openComposer,
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary,
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Đường kẻ mảnh phía dưới giống Facebook
          Divider(
            height: 1,
            thickness: 0.6,
            color: cs.outlineVariant.withOpacity(
              theme.brightness == Brightness.light ? 0.6 : 0.4,
            ),
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
    return const Column(children: [SizedBox(height: 8)]);
  }
}

class _StoriesSectionFromApi extends StatefulWidget {
  final List<SocialStory> stories;
  const _StoriesSectionFromApi({required this.stories});

  @override
  State<_StoriesSectionFromApi> createState() => _StoriesSectionFromApiState();
}

class _StoriesSectionFromApiState extends State<_StoriesSectionFromApi> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final SocialUser? currentUser =
    context.select<SocialController, SocialUser?>((c) => c.currentUser);
    final SocialStory? myStory = context.select<SocialController, SocialStory?>(
          (c) => c.currentUserStory,
    );

    final List<SocialStory> orderedStories = _orderedStories(
      widget.stories,
      currentUser,
      myStory,
    );

    return Container(
      height: 190, // thấp hơn một chút giống FB
      color: cs.surface,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          itemCount: orderedStories.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const _CreateStoryCard();
            }
            final int entryIndex = index - 1;
            final SocialStory story = orderedStories[entryIndex];
            return _StoryCardFromApi(
              story: story,
              onTap: story.items.isEmpty
                  ? null
                  : () {
                final int initialItem = _firstUnviewedItemIndex(story);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SocialStoryViewerScreen(
                      stories: List<SocialStory>.from(orderedStories),
                      initialStoryIndex: entryIndex,
                      initialItemIndex: initialItem,
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

  int _firstUnviewedItemIndex(SocialStory story) {
    if (story.items.isEmpty) return 0;
    final int index = story.items.indexWhere((item) => item.isViewed == false);
    if (index >= 0) return index;
    return 0;
  }

  List<SocialStory> _orderedStories(
    List<SocialStory> stories,
    SocialUser? currentUser,
    SocialStory? myStory,
  ) {
    final seenKeys = <String>{};
    final dedupedStories = <SocialStory>[];
    for (final story in stories) {
      final key = _storyKey(story);
      if (seenKeys.add(key)) {
        dedupedStories.add(story);
      }
    }

    dedupedStories.removeWhere((story) => !story.hasItems);

    final List<SocialStory> orderedStories = <SocialStory>[];
    if (myStory != null) {
      final key = _storyKey(myStory);
      dedupedStories.removeWhere((story) => _storyKey(story) == key);
      orderedStories.add(myStory);
    } else if (currentUser != null) {
      final idx = dedupedStories.indexWhere(
        (story) => _isCurrentUserStory(story, currentUser),
      );
      if (idx >= 0) {
        orderedStories.add(dedupedStories.removeAt(idx));
      }
    }

    orderedStories.addAll(dedupedStories);
    return orderedStories;
  }

  String _storyKey(SocialStory story) {
    final userId = story.userId;
    if (userId != null && userId.isNotEmpty) {
      return 'user:$userId';
    }
    return 'story:${story.id}';
  }

  bool _isCurrentUserStory(SocialStory story, SocialUser currentUser) {
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
    final bool hasUnviewed = story.items.any((item) => item.isViewed == false);
    final Color activeRingColor = cs.primary;
    final double ringBorderWidth = hasUnviewed ? 3 : 1.5;

    return Container(
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Material(
                color: cs.surfaceVariant,
                child: InkWell(
                  onTap: onTap,
                  child: Stack(
                    children: [
                      // ảnh story
                      if (thumb != null && thumb.isNotEmpty)
                        Positioned.fill(
                          child: Image(
                            image: CachedNetworkImageProvider(thumb),
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Positioned.fill(
                          child: Container(color: cs.surfaceVariant),
                        ),

                      // gradient dưới
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.6),
                                Colors.black.withOpacity(0.05),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // avatar + viền xanh ở góc trên trái
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: hasUnviewed
                                ? activeRingColor
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: hasUnviewed
                                  ? cs.surface
                                  : Colors.white.withOpacity(0.5),
                              width: ringBorderWidth,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: cs.surfaceVariant,
                            backgroundImage: (story.userAvatar != null &&
                                story.userAvatar!.isNotEmpty)
                                ? CachedNetworkImageProvider(
                              story.userAvatar!,
                            )
                                : null,
                            child: (story.userAvatar == null ||
                                story.userAvatar!.isEmpty)
                                ? Icon(
                              Icons.person,
                              color: onSurface.withOpacity(.7),
                              size: 20,
                            )
                                : null,
                          ),
                        ),
                      ),

                      // tên user ở đáy
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: Text(
                          story.userName ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // label "Ads" nếu là quảng cáo
                      if (story.isAd)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Ads',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionsPill extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onFriends;
  final VoidCallback onMessages;

  const _HeaderActionsPill({
    required this.onSearch,
    required this.onFriends,
    required this.onMessages,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    final Color bgColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.95);

    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.05);

    final Color iconColor = isDark
        ? Colors.white.withOpacity(0.9)
        : cs.onSurface.withOpacity(0.85);

    return Container(
      // tăng padding để pill dài & cao hơn
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pillIconButton(
            context: context,
            icon: Icons.search,
            color: iconColor,
            onTap: onSearch,
          ),
          const SizedBox(width: 6),
          _pillIconButton(
            context: context,
            icon: Icons.people_alt_outlined,
            color: iconColor,
            onTap: onFriends,
          ),
          const SizedBox(width: 6),
          _pillIconButton(
            context: context,
            icon: Icons.message_outlined,
            color: iconColor,
            onTap: onMessages,
          ),
        ],
      ),
    );
  }

  Widget _pillIconButton({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        // tăng vùng tap cho từng icon
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Icon(
          icon,
          size: 22, // có thể tăng lên 24 nếu muốn
          color: color,
        ),
      ),
    );
  }
}

class _EligiblePostEntry {
  final int index;
  final String id;
  const _EligiblePostEntry({required this.index, required this.id});
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
        fallbackProfile?.imageFullUrl?.toString().trim(),
        fallbackProfile?.image?.trim(),
      ];
      for (final value in candidates) {
        if (value != null && value.isNotEmpty) return value;
      }
      return null;
    }();

    final String label =
        getTranslated('add_to_story', context) ??
            getTranslated('create_story', context) ??
            'Add to Story';

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
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: cs.surfaceVariant,
          child: InkWell(
            onTap: openCreateStory,
            child: Stack(
              children: [
                Positioned.fill(
                  child: avatar != null && avatar.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: avatar,
                    fit: BoxFit.cover,
                  )
                      : Container(color: cs.surfaceVariant),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.05),
                          Colors.black.withOpacity(0.45),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(0, 1),
                          blurRadius: 3,
                        ),
                      ],
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

class _BirthdaySection extends StatelessWidget {
  final List<SocialUser> users;
  const _BirthdaySection({required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    // ===== TEXT MULTI-LANG =====
    final String birthdayTitle =
        getTranslated('birthday_today_title', context) ?? 'Sinh nh?t hm nay';

    final String singleTemplate =
        getTranslated('birthday_single_template', context) ??
            'Hm nay l sinh nh?t c?a {name}';

    final String doubleTemplate =
        getTranslated('birthday_double_template', context) ??
            'Hm nay sinh nh?t {first} v {second}';

    final String multiTemplate =
        getTranslated('birthday_multi_template', context) ??
            'Hm nay sinh nh?t {first} v {count} ngu?i b?n khc';

    final String congratulateLabel =
        getTranslated('birthday_congratulate', context) ?? 'Chc m?ng';

    final String fallbackFriend =
        getTranslated('birthday_friend_fallback', context) ?? 'b?n b';

    // ===== GHP CU =====
    final SocialUser first = users.first;

    String pickName(SocialUser u) {
      final c = [
        u.displayName,
        u.userName,
        u.firstName,
        u.lastName,
      ]
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (c.isEmpty) return fallbackFriend;
      return c.first;
    }

    final String firstName = pickName(first);
    final int others = users.length - 1;

    String subtitle;
    if (users.length == 1) {
      subtitle = singleTemplate.replaceFirst('{name}', firstName);
    } else if (users.length == 2) {
      final secondName = pickName(users[1]);
      subtitle = doubleTemplate
          .replaceFirst('{first}', firstName)
          .replaceFirst('{second}', secondName);
    } else {
      subtitle = multiTemplate
          .replaceFirst('{first}', firstName)
          .replaceFirst('{count}', others.toString());
    }

    void goToFirstProfile() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProfileScreen(targetUserId: first.id),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: goToFirstProfile,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                cs.primary.withOpacity(0.9),
                cs.secondary.withOpacity(0.9),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // avatar ch?ng
              _StackedBirthdayAvatars(
                users: users.take(3).toList(),
              ),
              const SizedBox(width: 8),

              // text co gin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cake_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            birthdayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // nt co l?i cho v?a hng
              Flexible(
                flex: 0,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: cs.primary,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: goToFirstProfile,
                    child: Text(
                      congratulateLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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

class _StackedBirthdayAvatars extends StatelessWidget {
  final List<SocialUser> users;
  const _StackedBirthdayAvatars({required this.users});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    const double size = 32;
    const double overlap = 14;

    return SizedBox(
      width: size + (users.length - 1).clamp(0, 2) * overlap,
      height: size,
      child: Stack(
        children: [
          for (int i = 0; i < users.length && i < 3; i++)
            Positioned(
              left: i * overlap,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: _buildAvatar(users[i], cs, onSurface),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(SocialUser u, ColorScheme cs, Color onSurface) {
    final String? avatarUrl =
        (u.avatarUrl != null && u.avatarUrl!.trim().isNotEmpty)
            ? u.avatarUrl!.trim()
            : null;

    if (avatarUrl != null) {
      return CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(avatarUrl),
      );
    }
    return CircleAvatar(
      backgroundColor: cs.surfaceVariant,
      child: Icon(Icons.person, color: onSurface.withOpacity(.6), size: 18),
    );
  }
}

// ti?n cho .firstOrNull
extension _IterableFirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
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
                child: Icon(
                  Icons.person,
                  color: onSurface.withOpacity(.6),
                  size: 20,
                ),
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

  page_models.SocialGetPage _buildStubPage(
      SocialPost post, String pageIdStr) {
    final int id = int.tryParse(pageIdStr) ?? 0;
    final String name = (post.userName ?? '').trim();
    final String avatar = post.userAvatar ?? '';
    return page_models.SocialGetPage(
      pageId: id,
      ownerUserId: 0,
      username: name.isNotEmpty ? name : pageIdStr,
      name: name.isNotEmpty ? name : 'Page $pageIdStr',
      pageName: pageIdStr,
      description: null,
      avatarUrl: avatar,
      coverUrl: avatar,
      url: '',
      category: '',
      subCategory: null,
      usersPost: 0,
      likesCount: 0,
      rating: 0,
      isVerified: false,
      isPageOwner: false,
      isLiked: false,
      isReported: false,
      registered: null,
      type: null,
      website: null,
      facebook: null,
      instagram: null,
      youtube: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final SocialPost post = context.select<SocialController, SocialPost?>(
          (ctrl) => ctrl.findPostById(this.post.id),
        ) ??
        this.post;
    // lấy eventId từ nội dung post (link /events/123)
    final String? attachedEventId = extractEventIdFromPost(post);
    final bool hasEventAttachment = attachedEventId != null;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bool isLightTheme = theme.brightness == Brightness.light;
    final onSurface = cs.onSurface;
    final Color baseColor =
        isLightTheme ? Colors.white : theme.scaffoldBackgroundColor;
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
    final bool hasBackgroundText = SocialPostFullViewComposer.allowsBackground(
      post,
    );
    final bool hasInlineImages = SocialPostFullViewComposer.normalizeImages(
      post,
    ).isNotEmpty;
    final bool backgroundWithMedia = hasBackgroundText && hasInlineImages;
    final double mediaTopSpacing = backgroundWithMedia ? 4 : 12;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Material(
        color: baseColor,
        elevation: 1,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // ==== Avatar (page post -> PageDetail, otherwise Profile) ====
                  InkWell(
                    borderRadius: BorderRadius.circular(40),
                    onTap: () {
                      final String? pageIdStr = (post.pageId?.trim().isNotEmpty ?? false)
                          ? post.pageId!.trim()
                          : post.sharedPost?.pageId?.trim();
                      if (pageIdStr != null && pageIdStr.isNotEmpty) {
                        try {
                          final pageCtrl = context.read<page_ctrl.SocialPageController>();
                          final page_models.SocialGetPage? page =
                              pageCtrl.findPageByIdString(pageIdStr);
                          if (page != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    page_screens.SocialPageDetailScreen(page: page),
                              ),
                            );
                            return;
                          }
                        } catch (_) {
                          // no page controller in tree -> fall back
                        }
                        // fallback: chưa cache page -> dùng stub để mở PageDetail, controller sẽ fetch
                        final page_models.SocialGetPage stub =
                            _buildStubPage(post, pageIdStr);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                page_screens.SocialPageDetailScreen(page: stub),
                          ),
                        );
                        return;
                      }

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ProfileScreen(targetUserId: post.publisherId),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: cs.surfaceVariant,
                      backgroundImage: (post.userAvatar != null &&
                              post.userAvatar!.isNotEmpty)
                          ? CachedNetworkImageProvider(post.userAvatar!)
                          : null,
                      child:
                          (post.userAvatar == null || post.userAvatar!.isEmpty)
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

                  // ==== C?t tn + time (uu tin m? Page n?u l page post) ====
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        final String? pageIdStr = (post.pageId?.trim().isNotEmpty ?? false)
                            ? post.pageId!.trim()
                            : post.sharedPost?.pageId?.trim();
                        if (pageIdStr != null && pageIdStr.isNotEmpty) {
                          try {
                            final pageCtrl = context.read<page_ctrl.SocialPageController>();
                            final page_models.SocialGetPage? page =
                                pageCtrl.findPageByIdString(pageIdStr);
                            if (page != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      page_screens.SocialPageDetailScreen(page: page),
                                ),
                              );
                              return;
                            }
                          } catch (_) {
                            // ignore and fall back
                          }
                          final page_models.SocialGetPage stub =
                              _buildStubPage(post, pageIdStr);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  page_screens.SocialPageDetailScreen(page: stub),
                            ),
                          );
                          return;
                        }

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ProfileScreen(targetUserId: post.publisherId),
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
                                              context,
                                              post,
                                            )
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
                                              context,
                                            ) ??
                                            'updated profile picture')
                                        : post.postType ==
                                                'profile_cover_picture'
                                            ? (getTranslated(
                                                  'updated_cover_photo',
                                                  context,
                                                ) ??
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final opt in post.pollOptions!) ...[
                      Text(opt['text']?.toString() ?? ''),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (((double.tryParse(
                                        (opt['percentage_num'] ?? '0')
                                            .toString(),
                                      ) ??
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

            if (mediaContent != null || hasEventAttachment) ...[
              SizedBox(height: mediaTopSpacing),
              if (mediaContent != null) mediaContent,
              if (hasEventAttachment && attachedEventId != null)
                SocialEventAttachmentLoader(eventId: attachedEventId),
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
                          horizontal: 12,
                          vertical: 8,
                        ),
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
                          final overlayBox = Overlay.of(itemCtx)
                              .context
                              .findRenderObject() as RenderBox;
                          final box = itemCtx.findRenderObject() as RenderBox?;
                          final Offset centerGlobal = (box != null)
                              ? box.localToGlobal(
                                  box.size.center(Offset.zero),
                                  ancestor: overlayBox,
                                )
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
        await _handleReportPost(context, controller, post);
        break;

      case _PostOptionsAction.hide:
        await controller.hidePost(post);
        break;
    }
  }

  Future<void> _handleReportPost(
    BuildContext context,
    SocialController controller,
    SocialPost post,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(getTranslated('report_post', ctx) ?? 'Report post'),
        content: Text(
          getTranslated('report_post_confirm', ctx) ??
              'Are you sure you want to report this post?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(getTranslated('cancel', ctx) ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(getTranslated('report', ctx) ?? 'Report'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      await controller.reportPost(post);
      if (!context.mounted) return;
      showCustomSnackBar(
        getTranslated('post_reported', context) ?? 'Post has been reported.',
        context,
        isError: false,
      );
    } catch (e) {
      if (!context.mounted) return;
      showCustomSnackBar(e.toString(), context, isError: true);
    }
  }

  Future<String?> _promptEditPost(BuildContext context, SocialPost post) async {
    final String initialText = _editableTextFromPost(post);
    final TextEditingController textController = TextEditingController(
      text: initialText,
    );
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
              child: Text(getTranslated('save_changes', dialogCtx) ?? 'Save'),
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
          content: Text(
            getTranslated('post_text_required', context) ??
                'Post text cannot be empty',
          ),
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
        builder: (_) =>
            SocialGroupDetailScreen(groupId: groupId, initialGroup: initial),
      ),
    );
  }

  void _openSharedPostDetail(BuildContext context, SocialPost shared) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SocialPostDetailScreen(post: shared)),
    );
  }
}


class _PostAdCard extends StatefulWidget {
  final AdsModel ad;
  const _PostAdCard({required this.ad});

  @override
  State<_PostAdCard> createState() => _PostAdCardState();
}

class _PostAdCardState extends State<_PostAdCard> {
  bool _viewLogged = false;

  String _title(BuildContext context) {
    final String defaultTitle =
        getTranslated('ad_default_title', context) ?? 'Qu?ng co';

    if (widget.ad.headline?.trim().isNotEmpty ?? false) {
      return widget.ad.headline!.trim();
    }

    if (widget.ad.name?.trim().isNotEmpty ?? false) {
      return widget.ad.name!.trim();
    }

    return defaultTitle;
  }

  String? _description() {
    final String? desc = widget.ad.description?.trim();
    if (desc == null || desc.isEmpty) return null;
    return desc;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleViewLog();
  }

  @override
  void didUpdateWidget(covariant _PostAdCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ad.id != widget.ad.id) {
      _viewLogged = false;
      _scheduleViewLog();
    }
  }

  void _scheduleViewLog() {
    if (_viewLogged) return;
    if (widget.ad.id == null) return;
    _viewLogged = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final SocialController controller = context.read<SocialController>();
      controller.trackAdView(ad: widget.ad);
    });
  }

  Future<void> _handleAdClick() async {
    final SocialController controller = context.read<SocialController>();
    controller.trackAdClick(ad: widget.ad);
    await _launchAdUrl(context, widget.ad.website);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String? media = widget.ad.mediaUrl;
    final String? description = _description();

    final String sponsoredLabel =
        getTranslated('ad_sponsored', context) ?? 'u?c ti tr?';
    final String learnMoreLabel =
        getTranslated('ad_learn_more', context) ?? 'Tm hi?u thm';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: cs.surface,
        elevation: 1,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _handleAdClick,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (media != null && media.isNotEmpty)
                _AdResponsiveImage(url: media),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sponsoredLabel,
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _title(context),
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(.85),
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton(
                        onPressed: _handleAdClick,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(learnMoreLabel),
                      ),
                    ),
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

class _AdResponsiveImage extends StatefulWidget {
  final String url;
  final double maxHeightFactor;
  final double maxHeightToWidthRatio;
  const _AdResponsiveImage({
    required this.url,
    this.maxHeightFactor = 0.8,
    this.maxHeightToWidthRatio = 1.5,
  });

  @override
  State<_AdResponsiveImage> createState() => _AdResponsiveImageState();
}

class _AdResponsiveImageState extends State<_AdResponsiveImage> {
  double? _ratio;

  @override
  void initState() {
    super.initState();
    final Image image = Image(image: CachedNetworkImageProvider(widget.url));
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        if (!mounted) return;
        if (info.image.height == 0) return;
        setState(() {
          _ratio = info.image.width / info.image.height;
        });
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double fallbackRatio = 16 / 9;
    final double ratio = _ratio ?? fallbackRatio;
    return LayoutBuilder(
      builder: (BuildContext ctx, BoxConstraints constraints) {
        final double screenHeight =
            MediaQuery.of(ctx).size.height * widget.maxHeightFactor;
        final double resolvedWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(ctx).size.width;
        final double naturalHeight = resolvedWidth / ratio;
        final double ratioLimitedHeight =
            resolvedWidth * widget.maxHeightToWidthRatio;
        final double allowedHeight = min(
          naturalHeight,
          min(screenHeight, ratioLimitedHeight),
        );
        final bool shouldClip = allowedHeight < naturalHeight;
        final Widget image = CachedNetworkImage(
          imageUrl: widget.url,
          fit: BoxFit.cover,
          width: resolvedWidth,
          height: naturalHeight,
        );
        if (!shouldClip) {
          return SizedBox(
            width: resolvedWidth,
            height: naturalHeight,
            child: image,
          );
        }
        return SizedBox(
          width: resolvedWidth,
          height: allowedHeight,
          child: ClipRect(
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: resolvedWidth,
                height: naturalHeight,
                child: image,
              ),
            ),
          ),
        );
      },
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
  const _PostOptionsSheet({required this.onSelected, required this.isOwner});

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
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
  Widget _square(String u) => AspectRatio(aspectRatio: 1, child: _tile(u));

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
              .map(
                (e) => IconButton(
                  iconSize: 32,
                  onPressed: () => Navigator.pop(context, e),
                  icon: _reactionIcon(e),
                  tooltip: e,
                ),
              )
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
      return <String>[post.myReaction.isNotEmpty ? post.myReaction : 'Like'];
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
      final String formatted = _trimTrailingZeros(
        scaled.toStringAsFixed(precision),
      );
      return '$formatted${unit.suffix}';
    }
  }
  return value.toString();
}

String _reactionActionLabel(BuildContext context, String reaction) {
  final String defaultLabel = getTranslated('like', context) ?? 'Like';

  if (reaction.isEmpty || reaction == 'Like') return defaultLabel;

  switch (reaction) {
    case 'Love':
      return getTranslated('love', context) ?? 'Love';
    case 'HaHa':
      return getTranslated('haha', context) ?? 'Haha';
    case 'Wow':
      return getTranslated('wow', context) ?? 'Wow';
    case 'Sad':
      return getTranslated('sad', context) ?? 'Bu?n';
    case 'Angry':
      return getTranslated('angry', context) ?? 'Angry';
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
  const _ReactionIconStack({required this.labels, this.size = 20});

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

  entry = OverlayEntry(
    builder: (_) {
      final RenderBox overlayBox =
          overlay.context.findRenderObject() as RenderBox;
      final Offset local = overlayBox.globalToLocal(globalPos);

      // Kích thu?c khung popup, canh n?m ngay trên nút
      const double popupWidth = 300;
      const double popupHeight = 56;

      return Stack(
        children: [
          // Tap ra ngoài d? t?t
          Positioned.fill(child: GestureDetector(onTap: () => entry.remove())),
          Positioned(
            left: (local.dx - popupWidth / 2).clamp(
              8.0,
              overlayBox.size.width - popupWidth - 8.0,
            ),
            top: (local.dy - popupHeight - 12).clamp(
              8.0,
              overlayBox.size.height - popupHeight - 8.0,
            ),
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
    },
  );

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

  _Story({required this.name, this.imageUrl, this.isCreateStory = false});
}

// Small helper to avoid EdgeInsets.zero import everywhere
class EdgeBox {
  static const zero = EdgeInsets.zero;
}
