import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class SocialStoryViewerScreen extends StatefulWidget {
  final List<SocialStory> stories;
  final int initialStoryIndex;
  final int initialItemIndex;

  const SocialStoryViewerScreen({
    super.key,
    required this.stories,
    this.initialStoryIndex = 0,
    this.initialItemIndex = 0,
  });

  @override
  State<SocialStoryViewerScreen> createState() =>
      _SocialStoryViewerScreenState();
}

class _SocialStoryViewerScreenState extends State<SocialStoryViewerScreen>
    with TickerProviderStateMixin {
  late List<SocialStory> _stories;
  late PageController _storyController;
  int _currentStoryIndex = 0;
  int _currentItemIndex = 0;
  AnimationController? _progressController;
  VideoPlayerController? _videoController;
  bool _isExiting = false;
  bool _viewerSheetOpen = false;
  SystemUiOverlayStyle? _baseOverlayStyle;
  SocialController? _socialController;
  Timer? _reactionDebounceTimer;
  String? _reactionOverride;
  final Queue<String> _reactionQueue = Queue<String>();
  bool _pausedForReaction = false;
  bool _reactionRequestInFlight = false;
  final BaseCacheManager _videoCacheManager = DefaultCacheManager();
  VideoPlayerController? _nextVideoController;
  String? _nextVideoUrl;
  VoidCallback? _videoListener;

  SocialStory get _currentStory => _stories[_currentStoryIndex];

  List<SocialStoryItem> get _storyItems => _currentStory.items;

  SocialStoryItem? get _currentItem {
    if (_storyItems.isEmpty) return null;
    if (_currentItemIndex >= _storyItems.length) {
      _currentItemIndex = _storyItems.length - 1;
    }
    return _storyItems[_currentItemIndex];
  }

  @override
  void initState() {
    super.initState();
    _stories = List<SocialStory>.from(widget.stories);
    _currentStoryIndex = widget.initialStoryIndex
        .clamp(0, _stories.isEmpty ? 0 : _stories.length - 1);
    _currentItemIndex = widget.initialItemIndex;
    _storyController = PageController(initialPage: _currentStoryIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCurrentItem(autoPlay: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _baseOverlayStyle ??= _defaultOverlayForTheme(Theme.of(context));
    final SocialController controller = context.read<SocialController>();
    if (!identical(controller, _socialController)) {
      _socialController?.removeListener(_onControllerUpdated);
      _socialController = controller;
      _socialController?.addListener(_onControllerUpdated);
    }
    _syncStoriesFromController();
  }

  @override
  void dispose() {
    _isExiting = true;
    _socialController?.removeListener(_onControllerUpdated);
    _progressController?.stop();
    _videoController?.pause();
    _progressController?.dispose();
    _disposeVideo(disposePrefetched: true);
    _storyController.dispose();
    _reactionDebounceTimer?.cancel();
    _restoreStatusBar();
    super.dispose();
  }

  void _onControllerUpdated() {
    if (!mounted) return;
    _syncStoriesFromController();
  }

  void _syncStoriesFromController() {
    final SocialController? controller = _socialController;
    if (controller == null) return;
    final List<SocialStory> latest = controller.stories;
    if (latest.isEmpty) return;
    final Map<String, SocialStory> lookup = <String, SocialStory>{
      for (final SocialStory story in latest) _storyKey(story): story,
    };
    bool changed = false;
    for (int i = 0; i < _stories.length; i++) {
      final SocialStory story = _stories[i];
      final SocialStory? replacement = lookup[_storyKey(story)];
      if (replacement != null && !identical(replacement, story)) {
        _stories[i] = replacement;
        changed = true;
      }
    }
    if (changed && mounted) {
      setState(() {});
    }
  }

  String _storyKey(SocialStory story) {
    final String? userId = story.userId;
    if (userId != null && userId.isNotEmpty) {
      return 'user:$userId';
    }
    return 'story:${story.id}';
  }

  void _startCurrentItem({bool autoPlay = false}) {
    _reactionDebounceTimer?.cancel();
    _reactionDebounceTimer = null;
    _reactionQueue.clear();
    _reactionOverride = null;
    if (_pausedForReaction) {
      _pausedForReaction = false;
    }

    _progressController?.dispose();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )
      ..addListener(() {
        if (!mounted || _isExiting) return;
        setState(() {});
      })
      ..addStatusListener((status) {
        if (!mounted || _isExiting) return;
        if (status == AnimationStatus.completed) {
          _onNext();
        }
      });

    _disposeVideo();

    if (_storyItems.isEmpty) {
      return;
    }

    final SocialStoryItem? item = _currentItem;
    if (item == null) {
      _progressController?.forward();
      _prefetchOwnStoryViewers();
      return;
    }

    final SocialStory storySnapshot = _currentStory;
    unawaited(_socialController?.markStoryItemViewed(
      story: storySnapshot,
      item: item,
    ));

    if (item.isVideo && item.mediaUrl != null && item.mediaUrl!.isNotEmpty) {
      if (_nextVideoController != null &&
          _nextVideoUrl == item.mediaUrl &&
          _nextVideoController!.value.isInitialized) {
        final VideoPlayerController controller = _nextVideoController!;
        _nextVideoController = null;
        _nextVideoUrl = null;
        _activateVideoController(controller, autoPlay,
            alreadyInitialized: true);
      } else {
        unawaited(_initializeVideoItem(item, autoPlay));
      }
    } else {
      _progressController?.duration = const Duration(seconds: 6);
      if (autoPlay) {
        _progressController?.forward(from: 0);
      }
    }

    _precacheNextImage();
    unawaited(_prefetchNextVideo());
    _prefetchOwnStoryViewers();
  }

  Future<void> _initializeVideoItem(
    SocialStoryItem item,
    bool autoPlay,
  ) async {
    final String url = item.mediaUrl!;
    File? cachedFile;
    try {
      cachedFile = await _videoCacheManager.getSingleFile(url);
    } catch (_) {
      cachedFile = null;
    }

    if (_isExiting || !mounted) return;
    VideoPlayerController controller;
    if (cachedFile != null && await cachedFile.exists()) {
      controller = VideoPlayerController.file(cachedFile);
    } else {
      controller = VideoPlayerController.networkUrl(Uri.parse(url));
    }

    try {
      await controller.initialize();
    } catch (e) {
      if (!mounted || _isExiting) {
        controller.dispose();
        return;
      }
      debugPrint('Failed to initialize story video: ${e.toString()}');
      controller.dispose();
      _progressController?.duration = const Duration(seconds: 6);
      if (autoPlay) {
        _progressController?.forward(from: 0);
      }
      return;
    }

    if (!mounted || _isExiting) {
      controller.dispose();
      return;
    }

    _activateVideoController(controller, autoPlay, alreadyInitialized: true);
  }

  void _activateVideoController(
    VideoPlayerController controller,
    bool autoPlay, {
    bool alreadyInitialized = false,
  }) {
    if (_videoListener != null && _videoController != null) {
      _videoController!.removeListener(_videoListener!);
      _videoListener = null;
    }
    _videoController?.dispose();

    _videoController = controller;

    if (!alreadyInitialized) {
      controller.initialize().catchError((_) {});
    }

    controller.setLooping(true);

    final Duration duration = controller.value.duration == Duration.zero
        ? const Duration(seconds: 10)
        : controller.value.duration;
    _progressController?.duration = duration;

    if (mounted && !_isExiting) {
      setState(() {});
    }

    if (autoPlay) {
      controller.play();
      _progressController?.forward(from: 0);
    }

    _videoListener = () {
      if (!mounted || _isExiting) return;
      if (controller.value.isPlaying) {
        _progressController?.forward();
      } else {
        _progressController?.stop();
      }
    };
    controller.addListener(_videoListener!);
  }

  void _pauseForReaction() {
    if (_pausedForReaction) return;
    _pausedForReaction = true;
    _pause();
  }

  void _resumeAfterReaction() {
    if (!_pausedForReaction) return;
    if (_reactionDebounceTimer != null) return;
    if (_reactionQueue.isNotEmpty) return;
    if (_reactionRequestInFlight) return;
    if (_viewerSheetOpen) return;
    _pausedForReaction = false;
    _resume();
  }

  void _dispatchPendingReaction() {
    _reactionDebounceTimer?.cancel();
    _reactionDebounceTimer = null;
    if (!mounted || _isExiting) {
      _reactionQueue.clear();
      return;
    }

    if (_reactionRequestInFlight) {
      _reactionDebounceTimer = Timer(
        const Duration(milliseconds: 200),
        _dispatchPendingReaction,
      );
      return;
    }

    if (_reactionQueue.isEmpty) {
      _resumeAfterReaction();
      return;
    }

    final SocialStoryItem? item = _currentItem;
    if (item == null) {
      _reactionQueue.clear();
      _resumeAfterReaction();
      return;
    }

    final SocialController? controller = _socialController;
    if (controller == null) {
      _reactionQueue.clear();
      _resumeAfterReaction();
      return;
    }

    final String sendValue = _reactionQueue.removeFirst();
    final SocialStory storySnapshot = _currentStory;
    final SocialStoryItem itemSnapshot = item;
    _reactionRequestInFlight = true;

    controller
        .reactOnStoryItem(
      story: storySnapshot,
      item: itemSnapshot,
      reaction: sendValue,
    )
        .whenComplete(() {
      if (!mounted) return;
      setState(() {
        _reactionRequestInFlight = false;
        if (_reactionQueue.isEmpty) {
          _reactionOverride = null;
        }
      });
      if (_reactionQueue.isNotEmpty) {
        _reactionDebounceTimer = Timer(
          const Duration(milliseconds: 0),
          _dispatchPendingReaction,
        );
      } else {
        _resumeAfterReaction();
      }
    });
  }

  void _precacheNextImage() {
    final SocialStoryItem? nextItem = _nextItem;
    if (nextItem == null || nextItem.isVideo) return;
    final String? url =
        _resolveStoryMediaUrl(nextItem.mediaUrl ?? nextItem.thumbUrl);
    if (url == null || url.isEmpty) return;
    precacheImage(CachedNetworkImageProvider(url), context);
  }

  Future<void> _prefetchNextVideo() async {
    final SocialStoryItem? nextItem = _nextItem;
    if (nextItem == null || !nextItem.isVideo) return;
    final String? url = _resolveStoryMediaUrl(nextItem.mediaUrl);
    if (url == null || url.isEmpty) return;

    if (_nextVideoUrl == url &&
        _nextVideoController != null &&
        _nextVideoController!.value.isInitialized) {
      return;
    }

    _disposePrefetchedVideo();

    File? cachedFile;
    try {
      cachedFile = await _videoCacheManager.getSingleFile(url);
    } catch (_) {
      cachedFile = null;
    }

    if (_isExiting || !mounted) return;

    VideoPlayerController controller;
    if (cachedFile != null && await cachedFile.exists()) {
      controller = VideoPlayerController.file(cachedFile);
    } else {
      controller = VideoPlayerController.networkUrl(Uri.parse(url));
    }

    try {
      await controller.initialize();
    } catch (_) {
      controller.dispose();
      return;
    }

    if (!mounted || _isExiting) {
      controller.dispose();
      return;
    }

    controller.setLooping(true);
    _nextVideoController = controller;
    _nextVideoUrl = url;
  }

  SocialStoryReaction? _footerReactionFor(SocialStoryItem? item) {
    if (item == null) return null;
    if (_reactionOverride == null) return item.reaction;
    final String override = _reactionOverride!;
    if (override.isEmpty) {
      return SocialStoryReaction(
        isReacted: false,
        type: '',
        count: item.reaction?.count,
      );
    }
    return SocialStoryReaction(
      isReacted: true,
      type: override,
      count: item.reaction?.count,
    );
  }

  SocialStoryItem? get _nextItem {
    if (_storyItems.isEmpty) return null;
    if (_currentItemIndex + 1 < _storyItems.length) {
      return _storyItems[_currentItemIndex + 1];
    }
    if (_currentStoryIndex + 1 < _stories.length) {
      final SocialStory nextStory = _stories[_currentStoryIndex + 1];
      if (nextStory.items.isNotEmpty) {
        return nextStory.items.first;
      }
    }
    return null;
  }

  void _disposeVideo({bool disposePrefetched = false}) {
    if (_videoListener != null && _videoController != null) {
      _videoController!.removeListener(_videoListener!);
      _videoListener = null;
    }
    _videoController?.dispose();
    _videoController = null;
    if (disposePrefetched) {
      _disposePrefetchedVideo();
    }
  }

  void _disposePrefetchedVideo() {
    _nextVideoController?.dispose();
    _nextVideoController = null;
    _nextVideoUrl = null;
  }

  void _prefetchOwnStoryViewers() {
    final SocialController? controller = _socialController;
    final SocialStoryItem? item = _currentItem;
    if (controller == null || item == null) return;
    final SocialStory story = _currentStory;
    final String? currentUserId = controller.currentUser?.id;
    if (currentUserId == null || story.userId != currentUserId) return;

    final StoryViewersState? state = controller.storyViewersState(item.id);
    if (state == null || (!state.loading && !state.fetched)) {
      controller.fetchStoryViewers(item, refresh: true);
    }
  }

  void _pause() {
    _progressController?.stop();
    _videoController?.pause();
  }

  void _resume() {
    if (_videoController != null) {
      _videoController?.play();
    }
    _progressController?.forward();
  }

  void _onNext() {
    if (!mounted || _isExiting) return;
    if (_storyItems.isEmpty) return;
    if (_currentItemIndex + 1 < _storyItems.length) {
      setState(() {
        _currentItemIndex += 1;
      });
      _startCurrentItem(autoPlay: true);
    } else if (_currentStoryIndex + 1 < _stories.length) {
      _navigateToStory(_currentStoryIndex + 1, itemIndex: 0);
    } else {
      _handleClose();
    }
  }

  void _onPrevious() {
    if (!mounted || _isExiting) return;
    if (_storyItems.isEmpty) return;
    if (_currentItemIndex > 0) {
      setState(() {
        _currentItemIndex -= 1;
      });
      _startCurrentItem(autoPlay: true);
    } else if (_currentStoryIndex > 0) {
      final SocialStory previousStory = _stories[_currentStoryIndex - 1];
      final int previousIndex =
          previousStory.items.isEmpty ? 0 : previousStory.items.length - 1;
      _navigateToStory(_currentStoryIndex - 1, itemIndex: previousIndex);
    }
  }

  void _navigateToStory(int index, {int itemIndex = 0}) {
    if (_isExiting || index < 0 || index >= _stories.length) return;
    setState(() {
      _currentStoryIndex = index;
      _currentItemIndex = itemIndex;
    });
    _storyController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
    _startCurrentItem(autoPlay: true);
  }

  void _onStoryPageChanged(int index) {
    if (_isExiting) return;
    setState(() {
      _currentStoryIndex = index;
      _currentItemIndex = 0;
    });
    _startCurrentItem(autoPlay: true);
  }

  void _handleReaction(SocialStoryItem item, String reaction) {
    if (_isExiting) return;
    final String tapped = normalizeSocialReaction(reaction);
    if (tapped.isEmpty) return;
    setState(() {
      _reactionOverride = tapped;
    });

    _reactionQueue.add(tapped);
    _pauseForReaction();

    _reactionDebounceTimer?.cancel();
    _reactionDebounceTimer =
        Timer(const Duration(milliseconds: 600), _dispatchPendingReaction);
  }

  void _handleClose() {
    if (!mounted || _isExiting) return;
    _isExiting = true;
    _progressController?.stop();
    _videoController?.pause();
    _reactionDebounceTimer?.cancel();
    _reactionDebounceTimer = null;
    _reactionQueue.clear();
    _restoreStatusBar();
    Navigator.of(context).pop();
  }

  void _restoreStatusBar() {
    final SystemUiOverlayStyle style =
        _baseOverlayStyle ?? _defaultOverlayForTheme(Theme.of(context));
    SystemChrome.setSystemUIOverlayStyle(style);
  }

  SystemUiOverlayStyle _defaultOverlayForTheme(ThemeData theme) {
    final SystemUiOverlayStyle? base = theme.appBarTheme.systemOverlayStyle;
    final bool isDark = theme.brightness == Brightness.dark;
    final SystemUiOverlayStyle fallback =
        (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );
    if (base == null) {
      return fallback;
    }
    return base.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          base.statusBarIconBrightness ?? fallback.statusBarIconBrightness,
      statusBarBrightness:
          base.statusBarBrightness ?? fallback.statusBarBrightness,
    );
  }

  Future<void> _openStoryViewers(
      SocialStory story, SocialStoryItem item) async {
    final SocialController? controller = _socialController;
    if (controller == null) return;
    setState(() {
      _viewerSheetOpen = true;
    });
    _pause();
    final StoryViewersState? state = controller.storyViewersState(item.id);
    if (state == null || (!state.loading && state.viewers.isEmpty)) {
      controller.fetchStoryViewers(item, refresh: true);
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ChangeNotifierProvider.value(
          value: controller,
          child: _StoryViewersSheet(
            story: story,
            item: item,
          ),
        );
      },
    );
    if (!mounted) return;
    setState(() {
      _viewerSheetOpen = false;
    });
    if (!_isExiting) {
      if (_pausedForReaction) {
        _resumeAfterReaction();
      } else {
        _resume();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final SocialStory story = _currentStory;
    final SocialStoryItem? item = _currentItem;
    final SocialController? controller = _socialController;

    final bool isOwnStory = controller?.currentUser?.id != null &&
        story.userId != null &&
        controller!.currentUser!.id == story.userId;

    final StoryViewersState? viewersState = (controller != null && item != null)
        ? controller.storyViewersState(item.id)
        : null;
    final int viewersCount = viewersState?.total ?? item?.viewCount ?? 0;
    final bool viewersLoading = viewersState?.loading ?? false;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            margin: _viewerSheetOpen
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 24)
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: _viewerSheetOpen
                  ? BorderRadius.circular(24)
                  : BorderRadius.zero,
              boxShadow: _viewerSheetOpen
                  ? const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: AnimatedScale(
              scale: _viewerSheetOpen ? 0.92 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _storyController,
                      onPageChanged: _onStoryPageChanged,
                      itemCount: _stories.length,
                      itemBuilder: (context, index) {
                        final SocialStory story = _stories[index];
                        final bool isCurrent = index == _currentStoryIndex;
                        final SocialStoryItem? pageItem = isCurrent
                            ? _currentItem
                            : (story.items.isNotEmpty
                                ? story.items.first
                                : null);

                        return Stack(
                          children: [
                            Positioned.fill(
                              child: _StoryMedia(
                                story: story,
                                item: pageItem,
                                videoController:
                                    isCurrent ? _videoController : null,
                                isCurrent: isCurrent,
                              ),
                            ),
                            if (isCurrent)
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTapUp: (details) {
                                    if (_isExiting) return;
                                    final double width =
                                        MediaQuery.of(context).size.width;
                                    if (details.localPosition.dx <
                                        width * 0.4) {
                                      _onPrevious();
                                    } else {
                                      _onNext();
                                    }
                                  },
                                  onLongPressStart: (_) => _pause(),
                                  onLongPressEnd: (_) => _resume(),
                                ),
                              ),
                            if (isCurrent)
                              Positioned(
                                left: 0,
                                right: 0,
                                top: 0,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _StoryProgressIndicators(
                                      itemCount: _storyItems.length,
                                      currentIndex: _currentItemIndex,
                                      progress: _progressController?.value ?? 0,
                                    ),
                                    const SizedBox(height: 12),
                                    _StoryHeader(
                                      story: story,
                                      currentItem: pageItem,
                                      onClose: _handleClose,
                                      viewCount: viewersCount,
                                      onViewers: (isOwnStory &&
                                              pageItem != null)
                                          ? () =>
                                              _openStoryViewers(story, pageItem)
                                          : null,
                                      showViewersButton:
                                          isOwnStory && pageItem != null,
                                      viewersLoading: viewersLoading,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: _StoryFooter(
                      caption: item?.description,
                      reaction: _footerReactionFor(item),
                      onReaction: (reaction) {
                        final SocialStoryItem? current = _currentItem;
                        if (current == null) return;
                        _handleReaction(current, reaction);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryMedia extends StatelessWidget {
  final SocialStory story;
  final SocialStoryItem? item;
  final VideoPlayerController? videoController;
  final bool isCurrent;

  const _StoryMedia({
    required this.story,
    required this.item,
    required this.videoController,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return Center(
        child: Text(
          getTranslated('story_unavailable', context) ?? 'Story unavailable',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    if (isCurrent && item!.isVideo) {
      final VideoPlayerController? controller = videoController;
      if (controller != null && controller.value.isInitialized) {
        return Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio == 0
                ? 9 / 16
                : controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        );
      }
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final String? url = _resolveStoryMediaUrl(
      item!.mediaUrl ?? item!.thumbUrl ?? story.mediaUrl ?? story.thumbUrl,
    );
    if (url == null || url.isEmpty) {
      return const SizedBox();
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, _) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (context, _, __) => const Center(
        child: Icon(Icons.broken_image, color: Colors.white),
      ),
    );
  }
}

class _StoryProgressIndicators extends StatelessWidget {
  final int itemCount;
  final int currentIndex;
  final double progress;

  const _StoryProgressIndicators({
    required this.itemCount,
    required this.currentIndex,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final int effectiveCount = itemCount > 0 ? itemCount : 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: List.generate(effectiveCount, (index) {
          double value;
          if (index < currentIndex) {
            value = 1;
          } else if (index == currentIndex || effectiveCount == 1) {
            value = progress.clamp(0, 1);
          } else {
            value = 0;
          }
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 3,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StoryHeader extends StatelessWidget {
  final SocialStory story;
  final SocialStoryItem? currentItem;
  final VoidCallback onClose;
  final int? viewCount;
  final VoidCallback? onViewers;
  final bool showViewersButton;
  final bool viewersLoading;

  const _StoryHeader({
    required this.story,
    required this.currentItem,
    required this.onClose,
    this.viewCount,
    this.onViewers,
    this.showViewersButton = false,
    this.viewersLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? timeText = _relativeTimeText(context, currentItem?.postedAt);
    final int watchers = viewCount ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage:
                (story.userAvatar != null && story.userAvatar!.isNotEmpty)
                    ? CachedNetworkImageProvider(story.userAvatar!)
                    : null,
            backgroundColor: Colors.grey.shade700,
            child: (story.userAvatar == null || story.userAvatar!.isEmpty)
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.userName?.isNotEmpty == true
                      ? story.userName!
                      : (getTranslated('story', context) ?? 'Story'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (timeText != null)
                  Text(
                    timeText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
          if (showViewersButton)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: viewersLoading
                  ? const SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    )
                  : TextButton.icon(
                      onPressed: onViewers,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white12,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(
                        Icons.remove_red_eye_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        '$watchers ${getTranslated('people_viewed', context) ?? 'viewers'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _StoryFooter extends StatefulWidget {
  final String? caption;
  final SocialStoryReaction? reaction;
  final ValueChanged<String> onReaction;

  const _StoryFooter({
    this.caption,
    required this.reaction,
    required this.onReaction,
  });

  @override
  State<_StoryFooter> createState() => _StoryFooterState();
}

class _StoryFooterState extends State<_StoryFooter>
    with TickerProviderStateMixin {
  static const List<String> _reactionOrder = <String>[
    'Like',
    'Love',
    'HaHa',
    'Wow',
    'Sad',
    'Angry',
  ];

  final Map<String, GlobalKey> _iconKeys = <String, GlobalKey>{
    'Like': GlobalKey(),
    'Love': GlobalKey(),
    'HaHa': GlobalKey(),
    'Wow': GlobalKey(),
    'Sad': GlobalKey(),
    'Angry': GlobalKey(),
  };

  final GlobalKey _effectsStackKey = GlobalKey();
  final List<_FlyingReaction> _flyingReactions = <_FlyingReaction>[];
  final Random _random = Random();

  @override
  void dispose() {
    for (final _FlyingReaction reaction in _flyingReactions) {
      reaction.controller.dispose();
    }
    super.dispose();
  }

  void _handleTap(String reactionLabel) {
    widget.onReaction(reactionLabel);
    _spawnFlyingReaction(reactionLabel);
  }

  void _spawnFlyingReaction(String reactionLabel) {
    final BuildContext? stackContext = _effectsStackKey.currentContext;
    final BuildContext? iconContext = _iconKeys[reactionLabel]?.currentContext;
    if (stackContext == null || iconContext == null) return;

    final RenderBox? stackBox = stackContext.findRenderObject() as RenderBox?;
    final RenderBox? iconBox = iconContext.findRenderObject() as RenderBox?;
    if (stackBox == null || iconBox == null) return;

    final Offset globalCenter =
        iconBox.localToGlobal(iconBox.size.center(Offset.zero));
    final Offset localStart = stackBox.globalToLocal(globalCenter);

    final AnimationController baseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final CurvedAnimation animation = CurvedAnimation(
      parent: baseController,
      curve: Curves.easeOut,
    );

    final _FlyingReaction flying = _FlyingReaction(
      controller: baseController,
      animation: animation,
      reaction: reactionLabel,
      startOffset: localStart,
      horizontalShift: (_random.nextDouble() * 80) - 40,
      verticalTravel: 120 + _random.nextDouble() * 40,
    );

    baseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        flying.controller.dispose();
        setState(() {
          _flyingReactions.remove(flying);
        });
      }
    });

    setState(() {
      _flyingReactions.add(flying);
    });
    baseController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String selected = normalizeSocialReaction(widget.reaction?.type);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // if (widget.caption != null && widget.caption!.trim().isNotEmpty)
          //   Padding(
          //     padding: const EdgeInsets.only(bottom: 12),
          //     child: Text(
          //       widget.caption!.replaceAll(
          //           RegExp(r'<br\s*/?>', caseSensitive: false), '\n'),
          //       style: theme.textTheme.bodyLarge?.copyWith(
          //         color: Colors.white,
          //         height: 1.4,
          //       ),
          //     ),
          //   ),
          SizedBox(
            height: 104,
            child: Stack(
              key: _effectsStackKey,
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: 56,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double width = constraints.maxWidth;
                        final double placeholderMin = width * .35;
                        final double placeholderMax = width * .65;

                        return ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            scrollbars: false,
                            overscroll: false,
                          ),
                          child: ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.zero,
                            scrollDirection: Axis.horizontal,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemCount: _reactionOrder.length + 1,
                            itemBuilder: (BuildContext context, int index) {
                              if (index == 0) {
                                return ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth:
                                        placeholderMin.clamp(140.0, width),
                                    maxWidth:
                                        placeholderMax.clamp(180.0, width),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: Colors.white24,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            getTranslated(
                                                    'send_message_placeholder',
                                                    context) ??
                                                'Send a message...',
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.send,
                                            color: Colors.white70, size: 20),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final String reactionLabel =
                                  _reactionOrder[index - 1];
                              final bool isSelected = selected == reactionLabel;
                              return GestureDetector(
                                onTap: () => _handleTap(reactionLabel),
                                child: Container(
                                  key: _iconKeys[reactionLabel],
                                  width: 48,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black54,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white24,
                                      width: 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: Colors.white
                                                  .withValues(alpha: .35),
                                              blurRadius: 14,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: _StoryReactionIcon(
                                    reaction: reactionLabel,
                                    size: isSelected ? 28 : 24,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
                ..._flyingReactions.map((flying) {
                  return AnimatedBuilder(
                    animation: flying.animation,
                    builder: (context, child) {
                      final double t = flying.animation.value;
                      final double dy =
                          flying.startOffset.dy - (flying.verticalTravel * t);
                      final double dx =
                          flying.startOffset.dx + (flying.horizontalShift * t);
                      final double opacity = (1 - t).clamp(0, 1);
                      final double scale = 1 + (0.25 * t);

                      return Positioned(
                        left: dx - 20,
                        top: dy - 20,
                        child: Opacity(
                          opacity: opacity,
                          child: Transform.scale(
                            scale: scale,
                            child: _StoryReactionIcon(
                              reaction: flying.reaction,
                              size: 32,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlyingReaction {
  final AnimationController controller;
  final CurvedAnimation animation;
  final String reaction;
  final Offset startOffset;
  final double horizontalShift;
  final double verticalTravel;

  _FlyingReaction({
    required this.controller,
    required this.animation,
    required this.reaction,
    required this.startOffset,
    required this.horizontalShift,
    required this.verticalTravel,
  });
}

class _StoryReactionIcon extends StatelessWidget {
  final String reaction;
  final double size;

  const _StoryReactionIcon({
    required this.reaction,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _storyReactionAsset(reaction),
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class _StackedReactionIcons extends StatelessWidget {
  final List<String> reactions;
  final double size;
  final double overlapFraction;
  final int maxVisible;

  const _StackedReactionIcons({
    required this.reactions,
    this.size = 20,
    this.overlapFraction = 1 / 3,
    this.maxVisible = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();
    final List<String> visible = (reactions.length > maxVisible
            ? reactions.sublist(reactions.length - maxVisible)
            : reactions)
        .toList();
    final double clampedOverlap = overlapFraction.clamp(0.0, 1.0);
    final double step = size * (1 - clampedOverlap);
    final double width =
        visible.length <= 1 ? size : size + step * (visible.length - 1);

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int index = visible.length - 1; index >= 0; index--)
            Positioned(
              left: step * index,
              child: _StoryReactionIcon(
                reaction: visible[index],
                size: size,
              ),
            ),
        ],
      ),
    );
  }
}

class _StoryViewersSheet extends StatelessWidget {
  final SocialStory story;
  final SocialStoryItem item;

  const _StoryViewersSheet({
    required this.story,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SocialController controller = context.watch<SocialController>();
    final StoryViewersState? state = controller.storyViewersState(item.id);
    final List<SocialStoryViewer> viewers =
        state?.viewers ?? const <SocialStoryViewer>[];
    final bool loading = state?.loading ?? viewers.isEmpty;
    final bool hasMore = state?.hasMore ?? false;
    final int total = state?.total ?? item.viewCount ?? viewers.length;

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                height: 4,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StoryPreviewThumbnail(
                      item: item,
                      fallback: story.thumbUrl ?? story.mediaUrl,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$total ${getTranslated('people_viewed', context) ?? 'viewers'}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: loading
                                ? null
                                : () => controller.refreshStoryViewers(item),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white12,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: Text(
                              getTranslated('refresh', context) ?? 'Refresh',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: loading && viewers.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: viewers.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Colors.white12, height: 1),
                        itemBuilder: (context, index) {
                          final SocialStoryViewer viewer = viewers[index];
                          return _StoryViewerTile(viewer: viewer);
                        },
                      ),
              ),
              if (loading && viewers.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: CircularProgressIndicator(color: Colors.white),
                )
              else if (!loading && hasMore)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: TextButton(
                    onPressed: () => controller.loadMoreStoryViewers(item),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white12,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      getTranslated('see_more', context) ?? 'See more',
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

class _StoryPreviewThumbnail extends StatelessWidget {
  final SocialStoryItem item;
  final String? fallback;

  const _StoryPreviewThumbnail({
    required this.item,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final String? url = item.thumbUrl ?? item.mediaUrl ?? fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        height: 120,
        color: Colors.white10,
        child: url == null || url.isEmpty
            ? const Icon(Icons.photo, color: Colors.white38)
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

class _StoryViewerTile extends StatelessWidget {
  final SocialStoryViewer viewer;

  const _StoryViewerTile({required this.viewer});

  @override
  Widget build(BuildContext context) {
    final List<String> reactions = viewer.reactions.isNotEmpty
        ? viewer.reactions
            .map((reaction) => normalizeSocialReaction(reaction))
            .where((reaction) => reaction.isNotEmpty)
            .toList()
        : (viewer.reaction.isNotEmpty
            ? <String>[normalizeSocialReaction(viewer.reaction)]
            : const <String>[]);
    Widget? trailing;
    if (reactions.isNotEmpty) {
      final double iconSize = reactions.length == 1 ? 24 : 20;
      trailing = _StackedReactionIcons(
        reactions: reactions,
        size: iconSize,
        overlapFraction: 1 / 3,
        maxVisible: 8,
      );
    }
    final String? timeText = _relativeTimeText(context, viewer.viewedAt);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: CircleAvatar(
        backgroundImage: viewer.avatar != null && viewer.avatar!.isNotEmpty
            ? CachedNetworkImageProvider(viewer.avatar!)
            : null,
        backgroundColor: Colors.white12,
        child: (viewer.avatar == null || viewer.avatar!.isEmpty)
            ? const Icon(Icons.person, color: Colors.white70)
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              viewer.name?.isNotEmpty == true
                  ? viewer.name!
                  : (getTranslated('user', context) ?? 'User'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (viewer.isVerified)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(
                Icons.check_circle,
                size: 16,
                color: Colors.lightBlueAccent,
              ),
            ),
        ],
      ),
      subtitle: timeText != null
          ? Text(
              timeText,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            )
          : null,
      trailing: trailing,
    );
  }
}

String _storyReactionAsset(String reaction) {
  switch (normalizeSocialReaction(reaction)) {
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

String? _relativeTimeText(BuildContext context, DateTime? time) {
  if (time == null) return null;
  final Duration diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) {
    return getTranslated('just_now', context) ?? 'Just now';
  }
  if (diff.inHours < 1) {
    final String unit = getTranslated('minutes_short', context) ?? 'm';
    return '${diff.inMinutes} $unit';
  }
  if (diff.inHours < 24) {
    final String unit = getTranslated('hours_short', context) ?? 'h';
    return '${diff.inHours} $unit';
  }
  if (diff.inDays < 7) {
    final String unit = getTranslated('days_short', context) ?? 'd';
    return '${diff.inDays} $unit';
  }
  final int weeks = (diff.inDays / 7).floor();
  final String unit = getTranslated('weeks_short', context) ?? 'w';
  return '$weeks $unit';
}

String? _resolveStoryMediaUrl(String? url) {
  if (url == null) return null;
  final String trimmed = url.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final String base = AppConstants.socialBaseUrl.replaceAll(RegExp(r'/$'), '');
  final String path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
  return '$base$path';
}
