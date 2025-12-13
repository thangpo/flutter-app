import 'dart:async';

import 'package:flutter_sixvalley_ecommerce/features/product_details/controllers/product_details_controller.dart';
import 'dart:math';
import 'dart:io' as io show File;
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sixvalley_ecommerce/di_container.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_comment.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post_reaction.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_service_interface.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/screens/product_details_screen.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/share_post_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/chat_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/widgets/shared_post_preview.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/social_feeling_helper.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/widgets/social_post_media.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/live_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/widgets/social_post_text_block.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/profile_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/widgets/report_comment_dialog.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_page_controller.dart'
    as page_ctrl;
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_get_page.dart'
    as page_models;
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_page_detail.dart'
    as page_screens;

enum CommentSortOrder { newest, oldest }

class SocialPostDetailScreen extends StatefulWidget {
  final SocialPost post;
  const SocialPostDetailScreen({super.key, required this.post});
  @override
  State<SocialPostDetailScreen> createState() => _SocialPostDetailScreenState();
}

class _SocialPostDetailScreenState extends State<SocialPostDetailScreen> {
  bool _showInput = true;
  late Future<SocialPost?> _postFuture;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  bool _sendingComment = false;
  String? _commentImagePath;
  String? _commentImageUrl;
  String? _commentAudioPath;
  SocialComment? _replyingTo;
  final List<SocialComment> _comments = [];
  bool _loadingComments = false;
  bool _hasMore = true;
  final int _pageSize = 10;
  int? _commentOffsetId;
  final Set<String> _commentReactionLoading = <String>{};
  bool _showEmojiKeyboard = false;
  bool _showGifKeyboard = false;
  final FlutterSoundRecorder _commentRecorder = FlutterSoundRecorder();
  bool _commentRecorderReady = false;
  bool _recordingComment = false;
  String? _commentRecordingPath;
  Timer? _recordingTimer;
  Duration _recordingElapsed = Duration.zero;
  Duration _lastRecordingDuration = Duration.zero;
  final AudioPlayer _commentPreviewPlayer = AudioPlayer();
  StreamSubscription<void>? _previewCompleteSub;
  bool _previewPlaying = false;
  Duration _previewPos = Duration.zero;
  Duration _previewDur = Duration.zero;

  bool get _hasCommentPayload =>
      _commentController.text.trim().isNotEmpty ||
      _commentImagePath != null ||
      _commentImageUrl != null ||
      _commentAudioPath != null;
  CommentSortOrder _sortOrder = CommentSortOrder.newest;
  bool _handledLiveNavigation = false;

  @override
  void initState() {
    super.initState();
    final svc = sl<SocialServiceInterface>();
    _postFuture = svc.getPostById(postId: widget.post.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<SocialController>().loadPostBackgrounds();
      } catch (_) {}
    });
    _loadMoreComments();
    _previewCompleteSub =
        _commentPreviewPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() => _previewPlaying = false);
      } else {
        _previewPlaying = false;
      }
      _previewPos = Duration.zero;
    });
    _commentPreviewPlayer.onPositionChanged
        .listen((d) => setState(() => _previewPos = d));
    _commentPreviewPlayer.onDurationChanged
        .listen((d) => setState(() => _previewDur = d));
    _commentPreviewPlayer.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playAndRecord,
          options: {
            AVAudioSessionOptions.defaultToSpeaker,
            AVAudioSessionOptions.allowBluetooth,
          },
        ),
      ),
    );
  }

  Future<void> _refreshAll() async {
    final svc = sl<SocialServiceInterface>();
    setState(() {
      _postFuture = svc.getPostById(postId: widget.post.id);
      _comments.clear();
      _hasMore = true;
      _commentOffsetId = null;
    });
    await _loadMoreComments();
  }

  Future<void> _loadMoreComments() async {
    if (_loadingComments || !_hasMore) return;
    _loadingComments = true;
    try {
      final svc = sl<SocialServiceInterface>();
      final list = await svc.getPostComments(
        postId: widget.post.id,
        limit: _pageSize,
        offset: _commentOffsetId,
      );
      if (list.isEmpty) {
        _hasMore = false;
      }
      final existing = _comments.map((e) => e.id).toSet();
      setState(() {
        _comments.addAll(list.where((e) => !existing.contains(e.id)));
        _sortComments();
        // Lưu lại id nhỏ nhất để phân trang (backend trả DESC, offset là id cũ hơn)
        final ids = list
            .map((e) => int.tryParse(e.id))
            .whereType<int>()
            .toList(growable: false);
        if (ids.isNotEmpty) {
          final int minIdInBatch = ids.reduce(min);
          if (_commentOffsetId == null || minIdInBatch < _commentOffsetId!) {
            _commentOffsetId = minIdInBatch;
          }
        } else {
          _hasMore = false; // không thể phân trang nếu không lấy được id
        }
        if (list.length < _pageSize) _hasMore = false;
      });
    } finally {
      _loadingComments = false;
    }
  }

  bool _isActiveLivePost(SocialPost post) {
    final String type = (post.postType ?? '').toLowerCase();
    if (type != 'live') return false;
    if (post.liveEnded) return false;
    final String? streamName = post.liveStreamName;
    return streamName != null && streamName.isNotEmpty;
  }

  void _maybeOpenLive(SocialPost post) {
    if (_handledLiveNavigation) return;
    if (!_isActiveLivePost(post)) return;
    _handledLiveNavigation = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _openLiveScreen(post);
    });
  }

  Future<void> _openLiveScreen(SocialPost post) async {
    final String? streamName = post.liveStreamName;
    if (streamName == null || streamName.isEmpty) {
      _handledLiveNavigation = false;
      return;
    }

    SocialController? controller;
    try {
      controller = context.read<SocialController>();
    } on ProviderNotFoundException {
      controller = null;
    }
    final String? accessToken = controller?.accessToken;
    final bool hasAccessToken =
        accessToken != null && accessToken.trim().isNotEmpty;
    final String? preparedToken = post.liveAgoraToken;
    if (!hasAccessToken && (preparedToken == null || preparedToken.isEmpty)) {
      showCustomSnackBar(
        getTranslated('live_token_missing', context) ??
            'Unable to join livestream right now.',
        context,
        isError: true,
      );
      _handledLiveNavigation = false;
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveScreen(
          streamName: streamName,
          accessToken: accessToken ?? '',
          broadcasterUid: 0,
          initialToken: preparedToken,
          postId: post.id,
          isHost: false,
          hostDisplayName: post.userName,
          hostAvatarUrl: post.userAvatar,
        ),
      ),
    );
  }

  Future<void> _reactOnComment(SocialComment comment, String reaction) async {
    final idx = _comments.indexWhere((e) => e.id == comment.id);
    if (idx == -1) return;
    if (_commentReactionLoading.contains(comment.id)) return;
    final previous = _comments[idx];
    final was = previous.myReaction;
    final now = reaction;
    int delta = 0;
    if (was.isEmpty && now.isNotEmpty) {
      delta = 1;
    } else if (was.isNotEmpty && now.isEmpty) {
      delta = -1;
    }
    final optimistic = previous.copyWith(
      myReaction: now,
      reactionCount: (previous.reactionCount + delta).clamp(0, 1 << 31).toInt(),
    );
    setState(() {
      _comments[idx] = optimistic;
    });
    _commentReactionLoading.add(comment.id);
    try {
      final svc = sl<SocialServiceInterface>();
      await svc.reactToComment(commentId: comment.id, reaction: now);
    } catch (e) {
      setState(() {
        _comments[idx] = previous;
      });
      showCustomSnackBar(e.toString(), context, isError: true);
    } finally {
      _commentReactionLoading.remove(comment.id);
    }
  }

  Future<void> _handleSharePost(SocialPost post) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SharePostScreen(post: post),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _openReactionsSheet(
    SocialPost post, {
    String? focusReaction,
  }) async {
    if (post.reactionCount <= 0) return;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: 0.9,
          child: _PostReactionsSheet(
            targetId: post.id,
            targetType: 'post',
            totalCount: post.reactionCount,
            breakdown: post.reactionBreakdown,
            initialReaction: focusReaction,
            sheetTitle: getTranslated('reactions', context),
          ),
        ),
      ),
    );
  }

  Future<void> _openCommentReactionsSheet(
    SocialComment comment, {
    bool isReply = false,
  }) async {
    if (comment.reactionCount <= 0) return;
    if (!mounted) return;
    final String title = getTranslated(
          isReply ? 'reply_reactions' : 'comment_reactions',
          context,
        ) ??
        (isReply ? 'Reply reactions' : 'Comment reactions');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: 0.9,
          child: _PostReactionsSheet(
            targetId: comment.id,
            targetType: isReply ? 'reply' : 'comment',
            totalCount: comment.reactionCount,
            breakdown: const <String, int>{},
            sheetTitle: title,
          ),
        ),
      ),
    );
  }


  String _sharedSubtitleDetail(BuildContext context, SocialPost post) {
    final SocialPost? shared = post.sharedPost;
    if (shared == null) return '';
    final String owner =
        post.userName ?? (getTranslated('user', context) ?? 'User');
    final String original =
        shared.userName ?? (getTranslated('user', context) ?? 'User');
    final String verb =
        getTranslated('shared_post_from', context) ?? 'shared a post from';
    return '$owner $verb $original';
  }

  void _sortComments() {
    int comparison(SocialComment a, SocialComment b) {
      final DateTime? aTime = a.createdAt;
      final DateTime? bTime = b.createdAt;
      if (aTime != null && bTime != null) {
        final cmp = aTime.compareTo(bTime);
        if (cmp != 0) return cmp;
      } else if (aTime != null) {
        return -1;
      } else if (bTime != null) {
        return 1;
      }
      final int aId = int.tryParse(a.id) ?? 0;
      final int bId = int.tryParse(b.id) ?? 0;
      return aId.compareTo(bId);
    }

    final multiplier = _sortOrder == CommentSortOrder.newest ? -1 : 1;
    _comments.sort((a, b) => multiplier * comparison(a, b));
  }

  String _sortOrderLabel(BuildContext context, CommentSortOrder order) {
    switch (order) {
      case CommentSortOrder.newest:
        return getTranslated('latest', context) ?? 'Latest';
      case CommentSortOrder.oldest:
        return getTranslated('oldest', context) ?? 'Oldest';
    }
  }

  void _hideCustomKeyboards() {
    if (!_showEmojiKeyboard && !_showGifKeyboard) return;
    setState(() {
      _showEmojiKeyboard = false;
      _showGifKeyboard = false;
    });
  }

  Future<void> _handleImageAttachment() async {
    _hideCustomKeyboards();
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (!mounted || img == null) return;
    setState(() {
      _commentImagePath = img.path;
      _commentImageUrl = null;
      _showGifKeyboard = false;
      _showEmojiKeyboard = false;
    });
    FocusScope.of(context).requestFocus(_commentFocus);
  }

  Future<void> _toggleAudioRecording() async {
    if (_recordingComment) {
      try {
        final recordedDuration = _recordingElapsed;
        _stopRecordingTimer();
        final stoppedPath = await _commentRecorder.stopRecorder();
        final realPath = stoppedPath ?? _commentRecordingPath;
        if (realPath == null) {
          setState(() {
            _recordingComment = false;
            _commentRecordingPath = null;
            _recordingElapsed = Duration.zero;
          });
          return;
        }
        setState(() {
          _recordingComment = false;
          _commentRecordingPath = null;
          _commentImagePath = null;
          _commentImageUrl = null;
          _commentAudioPath = realPath;
          _lastRecordingDuration = recordedDuration;
          _recordingElapsed = Duration.zero;
          _previewPlaying = false;
        });
        FocusScope.of(context).requestFocus(_commentFocus);
      } catch (e) {
        _stopRecordingTimer();
        setState(() {
          _recordingComment = false;
          _commentRecordingPath = null;
          _recordingElapsed = Duration.zero;
        });
        showCustomSnackBar(
          getTranslated('recording_failed', context) ?? 'Recording failed',
          context,
          isError: true,
        );
      }
      return;
    }

    if (!_commentRecorderReady) {
      await _initCommentRecorder();
      if (!_commentRecorderReady) return;
    }
    _hideCustomKeyboards();
    FocusScope.of(context).unfocus();
    final dir = await getTemporaryDirectory();
    final fileName = 'comment_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final path = '${dir.path}/$fileName';
    try {
      if (_previewPlaying) {
        await _commentPreviewPlayer.stop();
        _previewPlaying = false;
      }
      _startRecordingTimer();
      await _commentRecorder.startRecorder(
        toFile: path,
        codec: Codec.aacMP4,
        bitRate: 64000,
        sampleRate: 44100,
        numChannels: 1,
      );
      setState(() {
        _recordingComment = true;
        _commentRecordingPath = path;
        _clearCommentAudioAttachment();
        _commentImagePath = null;
        _commentImageUrl = null;
      });
    } catch (e) {
      _stopRecordingTimer();
      setState(() {
        _recordingComment = false;
        _commentRecordingPath = null;
        _recordingElapsed = Duration.zero;
      });
      showCustomSnackBar(
        getTranslated('recording_failed', context) ?? 'Recording failed',
        context,
        isError: true,
      );
    }
  }

  Future<void> _pickGifFromFile() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['gif', 'webp', 'GIF', 'WEBP'],
    );
    if (!mounted || res == null || res.files.isEmpty) return;
    final file = res.files.first;
    if (file.path == null) return;
    setState(() {
      _commentImagePath = file.path;
      _commentImageUrl = null;
      _showGifKeyboard = false;
      _showEmojiKeyboard = false;
    });
    FocusScope.of(context).requestFocus(_commentFocus);
  }

  Future<void> _promptGifUrlSelection() async {
    final url = await _askGifUrl();
    if (!mounted || url == null || url.isEmpty) return;
    setState(() {
      _commentImageUrl = url;
      _commentImagePath = null;
      _showGifKeyboard = false;
      _showEmojiKeyboard = false;
    });
    FocusScope.of(context).requestFocus(_commentFocus);
  }

  void _toggleGifKeyboard() {
    final bool willShow = !_showGifKeyboard;
    setState(() {
      _showGifKeyboard = willShow;
      if (willShow) {
        _showEmojiKeyboard = false;
      }
    });
    if (willShow) {
      FocusScope.of(context).unfocus();
    } else {
      FocusScope.of(context).requestFocus(_commentFocus);
    }
  }

  void _toggleEmojiKeyboard() {
    final bool willShow = !_showEmojiKeyboard;
    setState(() {
      _showEmojiKeyboard = willShow;
      if (willShow) {
        _showGifKeyboard = false;
      }
    });
    if (willShow) {
      FocusScope.of(context).unfocus();
    } else {
      FocusScope.of(context).requestFocus(_commentFocus);
    }
  }

  void _startRecordingTimer() {
    _recordingElapsed = Duration.zero;
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _recordingElapsed += const Duration(seconds: 1);
      });
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);
    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Future<void> _initCommentRecorder() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          showCustomSnackBar(
            getTranslated('microphone_permission_required', context) ??
                'Microphone permission required',
            context,
            isError: true,
          );
        }
        return;
      }
      await _commentRecorder.openRecorder();
      await _commentRecorder
          .setSubscriptionDuration(const Duration(milliseconds: 100));
      _commentRecorderReady = true;
    } catch (e) {
      _commentRecorderReady = false;
      if (mounted) {
        showCustomSnackBar(
          getTranslated('recording_failed', context) ?? 'Recording failed',
          context,
          isError: true,
        );
      }
    }
  }

  Future<void> _togglePreviewPlayback() async {
    if (_commentAudioPath == null) return;
    if (_previewPlaying) {
      await _commentPreviewPlayer.stop();
      if (mounted)
        setState(() => _previewPlaying = false);
      else
        _previewPlaying = false;
      _previewPos = Duration.zero;
      return;
    }
    try {
      await _commentPreviewPlayer.stop();
      _previewPos = Duration.zero;
      if (_lastRecordingDuration > Duration.zero) {
        _previewDur = _lastRecordingDuration;
      }
      await _commentPreviewPlayer.play(DeviceFileSource(_commentAudioPath!));
      if (mounted) {
        setState(() => _previewPlaying = true);
      } else {
        _previewPlaying = true;
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          getTranslated('playback_failed', context) ?? 'Playback failed',
          context,
          isError: true,
        );
      }
    }
  }

  void _clearCommentAudioAttachment() {
    _commentAudioPath = null;
    _lastRecordingDuration = Duration.zero;
    _previewPlaying = false;
    _previewPos = Duration.zero;
    _previewDur = Duration.zero;
  }

  Future<String?> _askGifUrl() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(getTranslated('enter_gif_url', ctx) ?? 'Enter GIF URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'https://...gif'),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(getTranslated('cancel', ctx) ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(getTranslated('choose', ctx) ?? 'Choose'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final Color appBarColor = cs.surface;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: 68, // 64–72 cho thoáng 2 dòng
        titleSpacing: 12,
        backgroundColor: appBarColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: FutureBuilder<SocialPost?>(
          future: _postFuture,
          builder: (ctx, snap) {
            final basePost = snap.data ?? p;
            final ctrl = ctx.watch<SocialController>();
            final SocialPost current =
                ctrl.findPostById(basePost.id) ?? basePost;
            final SocialPost displayPost = current.sharedPost != null
                ? current
                : (p.sharedPost != null ? p : current);
            final onSurface = Theme.of(ctx).colorScheme.onSurface;
            final String? location = displayPost.postMap?.trim();
            final bool hasLocation = location != null && location.isNotEmpty;
            final String? profileOwnerId = displayPost.publisherId;
            final String? headerPageId =
                (displayPost.pageId?.trim().isNotEmpty ?? false)
                    ? displayPost.pageId!.trim()
                    : displayPost.sharedPost?.pageId?.trim();

            return Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _navigateToProfile(
                    ctx,
                    profileOwnerId,
                    pageId: headerPageId,
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: (displayPost.userAvatar != null &&
                            displayPost.userAvatar!.isNotEmpty)
                        ? NetworkImage(displayPost.userAvatar!)
                        : null,
                    child: (displayPost.userAvatar == null ||
                            displayPost.userAvatar!.isEmpty)
                        ? const Icon(Icons.person, size: 18)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _navigateToProfile(
                      ctx,
                      profileOwnerId,
                      pageId: headerPageId,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayPost.userName ??
                              (getTranslated('user', ctx) ?? 'User'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if ((displayPost.timeText ?? '').isNotEmpty)
                          Text(
                            displayPost.timeText!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                  color: onSurface.withOpacity(.6),
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
                                    location!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(ctx)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: onSurface.withOpacity(.75),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (displayPost.sharedPost != null)
                          Text(
                            _sharedSubtitleText(ctx, displayPost),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                  color: onSurface.withOpacity(.75),
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshAll,
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                    _loadMoreComments();
                  }
                  return false;
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    _hideCustomKeyboards();
                  },
                  child: SingleChildScrollView(
                    // padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<SocialPost?>(
                          future: _postFuture,
                          builder: (context, snap) {
                            final post = snap.data ?? p;
                            final ctrl = context.watch<SocialController>();
                            final Color onSurface =
                                Theme.of(context).colorScheme.onSurface;
                            final SocialPost current =
                                ctrl.findPostById(post.id) ?? post;
                            final SocialPost displayPost =
                                current.sharedPost != null
                                    ? current
                                    : (p.sharedPost != null ? p : current);
                            final SocialPost? sharedPost =
                                displayPost.sharedPost ?? p.sharedPost;
                            final bool isLiveDetail = sharedPost == null &&
                                _isActiveLivePost(displayPost);
                            if (isLiveDetail) {
                              _maybeOpenLive(displayPost);
                            }
                            final bool sharedIsLive = sharedPost != null &&
                                _isActiveLivePost(sharedPost!);
                            final String? postText =
                                (current.text?.isNotEmpty ?? false)
                                    ? current.text
                                    : p.text;
                            final List<dynamic>? pollOptions =
                                (current.pollOptions?.isNotEmpty ?? false)
                                    ? current.pollOptions
                                    : p.pollOptions;
                            final bool hasPoll =
                                pollOptions != null && pollOptions.isNotEmpty;
                            final Widget? detailMedia = buildSocialPostMedia(
                              context,
                              displayPost,
                              compact: false,
                            );
                            final Widget? mediaContent = sharedPost != null
                                ? sharedIsLive
                                    ? buildSocialPostMedia(
                                        context,
                                        sharedPost!.copyWith(
                                          id: '${sharedPost!.id}_detail_${displayPost.id}',
                                        ),
                                        compact: false)
                                    : SharedPostPreviewCard(
                                        post: sharedPost!,
                                        compact: true,
                                        padding: const EdgeInsets.all(10),
                                        parentPostId: displayPost.id,
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  SocialPostDetailScreen(
                                                      post: sharedPost!),
                                            ),
                                          );
                                        },
                                      )
                                : isLiveDetail
                                    ? null
                                    : detailMedia;
                            final myReaction = current.myReaction;
                            final bool isSharing = ctrl.isSharing(current.id);
                            final List<String> topReactions =
                                _topReactionLabels(current);
                            final int commentCount = current.commentCount;
                            final int shareCount = current.shareCount;
                            final int reactionCount = current.reactionCount;
                            final bool showReactions = reactionCount > 0;
                            final bool showComments = commentCount > 0;
                            final bool showShares = shareCount > 0;
                            final bool showStats =
                                showReactions || showComments || showShares;
                            final bool hasFeeling =
                                SocialFeelingHelper.hasFeeling(displayPost);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (hasFeeling)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    child: Row(
                                      children: [
                                        Builder(
                                          builder: (context) {
                                            final String? emoji =
                                                SocialFeelingHelper
                                                    .emojiForPost(displayPost);
                                            if (emoji != null) {
                                              return Text(
                                                emoji,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(fontSize: 20),
                                              );
                                            }
                                            return Icon(
                                              SocialFeelingHelper.iconForPost(
                                                  displayPost),
                                              size: 18,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            SocialFeelingHelper.labelForPost(
                                                    context, displayPost) ??
                                                '',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if ((postText ?? '').isNotEmpty) ...[
                                  SocialPostTextBlock(
                                    post: current,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                if (hasPoll) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        for (final opt in pollOptions!) ...[
                                          Text(opt['text']?.toString() ?? ''),
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: LinearProgressIndicator(
                                              value: (((double.tryParse(
                                                              (opt['percentage_num'] ??
                                                                      '0')
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
                                  const SizedBox(height: 12),
                                ],
                                if (mediaContent != null) ...[
                                  mediaContent,
                                  const SizedBox(height: 12),
                                ],
                                if (displayPost.hasProduct)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: _ProductBlock(
                                      title: displayPost.productTitle,
                                      images:
                                          displayPost.productImages ?? const [],
                                      price: displayPost.productPrice,
                                      currency: displayPost.productCurrency,
                                      description:
                                          displayPost.productDescription,
                                      productId: displayPost.ecommerceProductId,
                                      slug: displayPost.productSlug,
                                    ),
                                  ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 8, 12, 0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Builder(
                                          builder: (itemCtx) => InkWell(
                                            onTap: () {
                                              final was = myReaction;
                                              final now =
                                                  (was == 'Like') ? '' : 'Like';
                                              itemCtx
                                                  .read<SocialController>()
                                                  .reactOnPost(current, now);
                                            },
                                            onLongPress: () {
                                              final overlayBox =
                                                  Overlay.of(itemCtx)
                                                          .context
                                                          .findRenderObject()
                                                      as RenderBox;
                                              final box =
                                                  itemCtx.findRenderObject()
                                                      as RenderBox?;
                                              final Offset centerGlobal =
                                                  (box != null)
                                                      ? box.localToGlobal(
                                                          box.size.center(
                                                              Offset.zero),
                                                          ancestor: overlayBox)
                                                      : overlayBox.size
                                                          .center(Offset.zero);
                                              _showReactionsOverlay(
                                                itemCtx,
                                                centerGlobal,
                                                onSelect: (val) {
                                                  itemCtx
                                                      .read<SocialController>()
                                                      .reactOnPost(
                                                          current, val);
                                                },
                                              );
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  _reactionIcon(myReaction),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    _reactionActionLabel(
                                                        context, myReaction),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      _PostAction(
                                        icon: Icons.mode_comment_outlined,
                                        label:
                                            getTranslated('comment', context) ??
                                                'Comment',
                                        onTap: () {
                                          setState(() => _showInput = true);
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            if (mounted) {
                                              FocusScope.of(context)
                                                  .requestFocus(_commentFocus);
                                            }
                                          });
                                        },
                                      ),
                                      _PostAction(
                                        icon: Icons.share_outlined,
                                        label:
                                            getTranslated('share', context) ??
                                                'Share',
                                        loading: isSharing,
                                        onTap: isSharing
                                            ? null
                                            : () => _handleSharePost(current),
                                      ),
                                    ],
                                  ),
                                ),
                                if (showStats)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 2),
                                    child: Row(
                                      children: [
                                        if (showReactions)
                                          Expanded(
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                onTap: () =>
                                                    _openReactionsSheet(
                                                  current,
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 4),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      if (topReactions
                                                          .isNotEmpty)
                                                        _ReactionIconStack(
                                                            labels:
                                                                topReactions),
                                                      if (topReactions
                                                          .isNotEmpty)
                                                        const SizedBox(
                                                            width: 6),
                                                      Text(
                                                        _formatSocialCount(
                                                            reactionCount),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              color: onSurface
                                                                  .withOpacity(
                                                                      .85),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          const Expanded(
                                              child: SizedBox.shrink()),
                                        const SizedBox(width: 12),
                                        Flexible(
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Wrap(
                                              spacing: 12,
                                              children: [
                                                // if (showComments)
                                                //   Text(
                                                //     '${_formatSocialCount(commentCount)} ${getTranslated("comments", context) ?? "comments"}',
                                                //     style: Theme.of(context)
                                                //         .textTheme
                                                //         .bodySmall
                                                //         ?.copyWith(
                                                //           color: onSurface
                                                //               .withOpacity(.7),
                                                //         ),
                                                //     overflow:
                                                //         TextOverflow.ellipsis,
                                                //   ),
                                                if (showShares)
                                                  Text(
                                                    '${_formatSocialCount(shareCount)} ${getTranslated("share_plural", context) ?? "shares"}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: onSurface
                                                              .withOpacity(.7),
                                                        ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Divider(color: onSurface.withOpacity(.12)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  PopupMenuButton<CommentSortOrder>(
                                    tooltip:
                                        getTranslated('arrange', context) ??
                                            'Arrange',
                                    onSelected: (value) {
                                      if (_sortOrder != value) {
                                        setState(() {
                                          _sortOrder = value;
                                          _sortComments();
                                        });
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: CommentSortOrder.newest,
                                        child: Text(
                                            getTranslated('latest', context) ??
                                                'Latest'),
                                      ),
                                      PopupMenuItem(
                                        value: CommentSortOrder.oldest,
                                        child: Text(
                                            getTranslated('oldest', context) ??
                                                'Oldest'),
                                      ),
                                    ],
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(_sortOrderLabel(
                                            context, _sortOrder)),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.sort, size: 18),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Builder(
                                builder: (context) {
                                  if (_comments.isEmpty && _loadingComments) {
                                    return const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    );
                                  }
                                  if (_comments.isEmpty) {
                                    return Text(
                                      getTranslated(
                                              'no_comments_yet', context) ??
                                          'No comments yet',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: onSurface.withOpacity(.7),
                                          ),
                                    );
                                  }
                                  final svc = sl<SocialServiceInterface>();
                                  final replyActionStyle = Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: onSurface.withOpacity(.6));
                                  String? currentUserId;
                                  try {
                                    final socialCtrl =
                                        context.read<SocialController>();
                                    currentUserId = socialCtrl.currentUser?.id;
                                  } catch (_) {
                                    currentUserId = null;
                                  }
                                  return Column(
                                    children: [
                                      for (final c in _comments)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                onTap: () => _navigateToProfile(
                                                    context, c.userId),
                                                child: CircleAvatar(
                                                  radius: 16,
                                                  backgroundImage:
                                                      (c.userAvatar != null &&
                                                              c.userAvatar!
                                                                  .isNotEmpty)
                                                          ? NetworkImage(
                                                              c.userAvatar!)
                                                          : null,
                                                  child: (c.userAvatar ==
                                                              null ||
                                                          c.userAvatar!.isEmpty)
                                                      ? const Icon(Icons.person,
                                                          size: 16)
                                                      : null,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child:
                                                              GestureDetector(
                                                            onTap: () =>
                                                                _navigateToProfile(
                                                                    context,
                                                                    c.userId),
                                                            child: Text(
                                                              c.userName ??
                                                                  (getTranslated(
                                                                          'user',
                                                                          context) ??
                                                                      'User'),
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodyMedium
                                                                  ?.copyWith(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color:
                                                                        onSurface,
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                        if ((c.timeText ?? '')
                                                            .isNotEmpty)
                                                          Text(
                                                            _formatTimeText(
                                                                context,
                                                                c.timeText),
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodySmall
                                                                ?.copyWith(
                                                                    color: onSurface
                                                                        .withOpacity(
                                                                            .6)),
                                                          ),
                                                        if (currentUserId != null && currentUserId != c.userId)
                                                          PopupMenuButton<String>(
                                                            padding: EdgeInsets.zero,
                                                            icon: const Icon(Icons.more_vert, size: 18),
                                                            onSelected: (value) async {
                                                              if (value == 'report') {
                                                                await showReportCommentDialog(
                                                                context: context,
                                                                comment: c,
                                                                );  // gọi trực tiếp vì đang trong State cha
                                                              }
                                                            },
                                                            itemBuilder: (ctx) => [
                                                              PopupMenuItem<String>(
                                                                value: 'report',
                                                                child: Text(
                                                                  getTranslated('report_comment', ctx) ?? 'Report comment',
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                      ],
                                                    ),
                                                    if ((c.text ?? '')
                                                        .isNotEmpty)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 4),
                                                        child: Text(
                                                          c.text!,
                                                          style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodyMedium
                                                                  ?.copyWith(
                                                                    color:
                                                                        onSurface,
                                                                  ) ??
                                                              TextStyle(
                                                                color:
                                                                    onSurface,
                                                              ),
                                                        ),
                                                      ),
                                                    if ((c.imageUrl ?? '')
                                                        .isNotEmpty)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 6),
                                                        child:
                                                            _CommentImagePreview(
                                                                url: c
                                                                    .imageUrl!),
                                                      ),
                                                    if ((c.audioUrl ?? '')
                                                        .isNotEmpty)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 6),
                                                        child: _AudioPlayerBox(
                                                          url: c.audioUrl!,
                                                          autoplay: false,
                                                        ),
                                                      ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 6),
                                                      child: Row(
                                                        children: [
                                                          // TRÁI: Reply + số lượng reaction
                                                          Expanded(
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                TextButton(
                                                                  onPressed:
                                                                      () {
                                                                    setState(
                                                                        () {
                                                                      _replyingTo =
                                                                          c;
                                                                      _showInput =
                                                                          true;
                                                                      _commentImagePath =
                                                                          null;
                                                                      _commentImageUrl =
                                                                          null;
                                                                      _clearCommentAudioAttachment();
                                                                    });
                                                                    unawaited(
                                                                        _commentPreviewPlayer
                                                                            .stop());
                                                                    FocusScope.of(
                                                                            context)
                                                                        .requestFocus(
                                                                            _commentFocus);
                                                                  },
                                                                  child: Text(
                                                                    getTranslated(
                                                                            'reply',
                                                                            context) ??
                                                                        'Reply',
                                                                    style:
                                                                        replyActionStyle,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    width: 12),

                                                                // 👉 ICON LIKE CỐ ĐỊNH + SỐ LƯỢNG
                                                                if (c.reactionCount >
                                                                    0) ...[
                                                                  const SizedBox(
                                                                      width:
                                                                          12),
                                                                  GestureDetector(
                                                                    onTap: () =>
                                                                        _openCommentReactionsSheet(
                                                                            c),
                                                                    child: Row(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        _reactionIcon(
                                                                            'Like',
                                                                            size:
                                                                                18),
                                                                        const SizedBox(
                                                                            width:
                                                                                4),
                                                                        Text(
                                                                          _formatSocialCount(
                                                                              c.reactionCount),
                                                                          style: Theme.of(context)
                                                                              .textTheme
                                                                              .bodySmall
                                                                              ?.copyWith(
                                                                                color: onSurface.withOpacity(.6),
                                                                                fontWeight: FontWeight.w600,
                                                                              ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ],
                                                            ),
                                                          ),
                                                          // PHẢI: nút Reaction (icon + nhãn), tap/long-press như cũ
                                                          Builder(
                                                            builder:
                                                                (reactCtx) {
                                                              final reacted = c
                                                                  .myReaction
                                                                  .isNotEmpty;
                                                              final style =
                                                                  Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .bodySmall
                                                                      ?.copyWith(
                                                                        color: reacted
                                                                            ? Theme.of(context).colorScheme.primary
                                                                            : onSurface.withOpacity(.6),
                                                                        fontWeight: reacted
                                                                            ? FontWeight.w600
                                                                            : null,
                                                                      );

                                                              return GestureDetector(
                                                                behavior:
                                                                    HitTestBehavior
                                                                        .opaque,
                                                                onTap: () {
                                                                  final next =
                                                                      c.myReaction ==
                                                                              'Like'
                                                                          ? ''
                                                                          : 'Like';
                                                                  _reactOnComment(
                                                                      c, next);
                                                                },
                                                                onLongPress:
                                                                    () {
                                                                  final overlay =
                                                                      Overlay.of(
                                                                          reactCtx);
                                                                  if (overlay ==
                                                                      null)
                                                                    return;
                                                                  final overlayBox = overlay
                                                                          .context
                                                                          .findRenderObject()
                                                                      as RenderBox;
                                                                  final box = reactCtx
                                                                          .findRenderObject()
                                                                      as RenderBox?;
                                                                  final Offset centerGlobal = box !=
                                                                          null
                                                                      ? box.localToGlobal(
                                                                          box.size.center(Offset
                                                                              .zero),
                                                                          ancestor:
                                                                              overlayBox)
                                                                      : overlayBox
                                                                          .size
                                                                          .center(
                                                                              Offset.zero);

                                                                  _showReactionsOverlay(
                                                                    reactCtx,
                                                                    centerGlobal,
                                                                    onSelect: (val) =>
                                                                        _reactOnComment(
                                                                            c,
                                                                            val),
                                                                  );
                                                                },
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    _reactionIcon(
                                                                        c.myReaction,
                                                                        size: 18),
                                                                    const SizedBox(
                                                                        width:
                                                                            6),
                                                                    // Text(
                                                                    //   // nhãn của nút reaction (giống postcard)
                                                                    //   c.myReaction
                                                                    //           .isNotEmpty
                                                                    //       ? c
                                                                    //           .myReaction
                                                                    //       : (getTranslated(
                                                                    //               'like',
                                                                    //               context) ??
                                                                    //           'Like'),
                                                                    //   style: style,
                                                                    // ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    _RepliesLazy(
                                                      comment: c,
                                                      service: svc,
                                                      currentUserId:
                                                          currentUserId,
                                                      onRequestReply: (target) {
                                                        setState(() {
                                                          _replyingTo = target;
                                                          _showInput = true;
                                                          _commentImagePath =
                                                              null;
                                                          _commentImageUrl =
                                                              null;
                                                          _clearCommentAudioAttachment();
                                                        });
                                                        unawaited(
                                                            _commentPreviewPlayer
                                                                .stop());
                                                        FocusScope.of(context)
                                                            .requestFocus(
                                                                _commentFocus);
                                                      },
                                                      onShowReactions: (target,
                                                              {bool isReply =
                                                                  false,
                                                              BuildContext?
                                                                  context}) =>
                                                          _openCommentReactionsSheet(
                                                        target,
                                                        isReply: isReply,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (_loadingComments) ...[
                                        const SizedBox(height: 8),
                                        const Center(
                                            child: CircularProgressIndicator()),
                                      ] else if (_hasMore) ...[
                                        const SizedBox(height: 8),
                                        Center(
                                          child: TextButton(
                                            onPressed: _loadMoreComments,
                                            child: Text(
                                              getTranslated(
                                                      'load_more_comments',
                                                      context) ??
                                                  'Load more comments',
                                            ),
                                          ),
                                        )
                                      ],
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // ==== input bình luận ====
          _showInput
              ? SafeArea(
                  top: false,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        top: BorderSide(color: onSurface.withOpacity(.1)),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_replyingTo != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${getTranslated('reply', context) ?? 'Reply'} '
                                    '"${_replyingTo!.userName ?? (getTranslated('user', context) ?? 'User')}"',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _replyingTo = null),
                                  child: Text(
                                      getTranslated('cancel', context) ??
                                          'Cancel'),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            _buildCommentActionIcon(
                              context,
                              icon: Icons.camera_alt_outlined,
                              tooltip:
                                  getTranslated('image', context) ?? 'Image',
                              onTap: _handleImageAttachment,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceVariant
                                      .withOpacity(.65),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(.1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _commentController,
                                        focusNode: _commentFocus,
                                        decoration: InputDecoration(
                                          hintText: getTranslated(
                                                  'enter_comment', context) ??
                                              'Enter comment',
                                          border: InputBorder.none,
                                          isCollapsed: true,
                                        ),
                                        keyboardType: TextInputType.multiline,
                                        minLines: 1,
                                        maxLines: 3,
                                        textInputAction:
                                            TextInputAction.newline,
                                        onTap: () {
                                          if (_showGifKeyboard ||
                                              _showEmojiKeyboard) {
                                            setState(() {
                                              _showGifKeyboard = false;
                                              _showEmojiKeyboard = false;
                                            });
                                          }
                                        },
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    _buildCommentActionIcon(
                                      context,
                                      icon: Icons.mic_none_outlined,
                                      tooltip: _recordingComment
                                          ? getTranslated(
                                                  'stop_recording', context) ??
                                              'Stop recording'
                                          : getTranslated(
                                                  'record_audio', context) ??
                                              'Record audio',
                                      onTap: _toggleAudioRecording,
                                      highlighted: _recordingComment,
                                    ),
                                    const SizedBox(width: 2),
                                    _buildCommentActionIcon(
                                      context,
                                      icon: Icons.gif_box_outlined,
                                      tooltip: getTranslated('gif', context) ??
                                          'GIF',
                                      onTap: _toggleGifKeyboard,
                                      highlighted: _showGifKeyboard,
                                    ),
                                    const SizedBox(width: 2),
                                    _buildCommentActionIcon(
                                      context,
                                      icon: Icons.emoji_emotions_outlined,
                                      tooltip:
                                          getTranslated('emoji', context) ??
                                              'Emoji',
                                      onTap: _toggleEmojiKeyboard,
                                      highlighted: _showEmojiKeyboard,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_hasCommentPayload) ...[
                              const SizedBox(width: 8),
                              _buildCommentActionIcon(
                                context,
                                icon: Icons.send,
                                tooltip: getTranslated('submit', context) ??
                                    'Submit',
                                onTap: _sendingComment ? null : _submitComment,
                              ),
                            ]
                          ],
                        ),
                        if (_recordingComment)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.fiber_manual_record,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${getTranslated('recording', context) ?? 'Recording'} ${_formatDuration(_recordingElapsed)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        if (_commentImagePath != null ||
                            _commentImageUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                if (_commentImagePath != null)
                                  _ImageThumbPreview(
                                    image: Image.file(
                                      io.File(_commentImagePath!),
                                      fit: BoxFit.cover,
                                    ),
                                    onRemove: () => setState(
                                        () => _commentImagePath = null),
                                  ),
                                if (_commentImageUrl != null)
                                  _ImageThumbPreview(
                                    image: Image.network(
                                      _commentImageUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                    onRemove: () =>
                                        setState(() => _commentImageUrl = null),
                                  ),
                              ],
                            ),
                          ),
                        if (_commentAudioPath != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: _buildRecordedAudioPreview(context),
                          ),
                        if (_showGifKeyboard || _showEmojiKeyboard)
                          const SizedBox(height: 6),
                        if (_showGifKeyboard) _buildGifKeyboard(context),
                        if (_showEmojiKeyboard) _buildEmojiKeyboard(context),
                      ],
                    ),
                  ),
                )
              : SafeArea(
                  top: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showInput = true;
                            _replyingTo = null;
                          });
                          FocusScope.of(context).requestFocus(_commentFocus);
                        },
                        icon: const Icon(Icons.mode_comment_outlined),
                        label: Text(getTranslated('write_comment', context) ??
                            'Write a comment'),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _submitComment() async {
    final txt = _commentController.text.trim();
    if (txt.isEmpty &&
        _commentImagePath == null &&
        _commentImageUrl == null &&
        _commentAudioPath == null) return;
    if (_sendingComment) return;
    setState(() => _sendingComment = true);
    try {
      // String payloadText = txt;
      // if (payloadText.isEmpty &&
      //     (_commentImagePath != null ||
      //         _commentImageUrl != null ||
      //         _commentAudioPath != null)) {
      //   payloadText = '.';
      // }
      final svc = sl<SocialServiceInterface>();
      if (_replyingTo == null) {
        await svc.createComment(
          postId: widget.post.id,
          text: txt,
          imagePath: _commentImagePath,
          audioPath: _commentAudioPath,
          imageUrl: _commentImageUrl,
        );
      } else {
        await svc.createReply(
          commentId: _replyingTo!.id,
          text: txt,
          imagePath: _commentImagePath,
          audioPath: _commentAudioPath,
          imageUrl: _commentImageUrl,
        );
      }
      _commentController.clear();
      setState(() {
        _commentImagePath = null;
        _commentImageUrl = null;
        _clearCommentAudioAttachment();
        _replyingTo = null;
        _showGifKeyboard = false;
        _showEmojiKeyboard = false;
      });
      unawaited(_commentPreviewPlayer.stop());
      await _refreshAll();
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(e.toString(), context, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _sendingComment = false);
      }
    }
  }

    Widget _buildCommentActionIcon(
    BuildContext context, {
    required IconData icon,
    VoidCallback? onTap,
    String? tooltip,
    bool highlighted = false,
  }) {
    final bool enabled = onTap != null;
    final theme = Theme.of(context);
    final Color color = theme.colorScheme.onSurfaceVariant.withOpacity(
      enabled ? (highlighted ? 1 : .85) : .4,
    );
    final button = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          decoration: highlighted
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(.12),
                )
              : null,
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
      ),
    );
    if (tooltip == null) {
      return button;
    }
    return Tooltip(message: tooltip, child: button);
  }

  Widget _buildRecordedAudioPreview(BuildContext context) {
    final theme = Theme.of(context);
    final Color border = theme.colorScheme.onSurface.withOpacity(.08);
    final Duration effectiveDur =
        _previewDur > Duration.zero ? _previewDur : _lastRecordingDuration;
    final String subtitle = effectiveDur > Duration.zero
        ? _formatDuration(effectiveDur)
        : (_commentAudioPath != null ? _basename(_commentAudioPath!) : '');
    final Color onSurface = theme.colorScheme.onSurface;
    final double progress = (effectiveDur.inMilliseconds > 0)
        ? (_previewPos.inMilliseconds.clamp(
                0, effectiveDur.inMilliseconds) /
            effectiveDur.inMilliseconds)
        : 0;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            iconSize: 30,
            onPressed: _togglePreviewPlayback,
            icon: Icon(
              _previewPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _WaveformSeekBar(
                  progress: progress,
                  activeColor: onSurface,
                  inactiveColor: onSurface.withOpacity(0.25),
                  maxHeight: 30,
                  samples: _generateWaveform(_commentAudioPath ?? 'preview'),
                  onSeekPercent: (p) async {
                    if (effectiveDur.inMilliseconds > 0) {
                      final int targetMs =
                          (p * effectiveDur.inMilliseconds).toInt();
                      await _commentPreviewPlayer
                          .seek(Duration(milliseconds: targetMs));
                    }
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: getTranslated('remove', context) ?? 'Remove',
            onPressed: () {
              setState(() => _clearCommentAudioAttachment());
              unawaited(_commentPreviewPlayer.stop());
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
}

Widget _buildGifKeyboard(BuildContext context) {
    final theme = Theme.of(context);
    final Color divider = theme.colorScheme.onSurface.withOpacity(.08);
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: divider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Text(
                  getTranslated('gif', context) ?? 'GIF',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  tooltip: getTranslated('hide_keyboard', context) ??
                      'Hide keyboard',
                  onPressed: () {
                    setState(() => _showGifKeyboard = false);
                    FocusScope.of(context).requestFocus(_commentFocus);
                  },
                  icon: const Icon(Icons.keyboard_hide_outlined),
                ),
              ],
            ),
          ),
          Divider(color: divider, height: 1),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(
                    getTranslated('pick_gif_from_file', context) ??
                        'Pick GIF from file',
                  ),
                  onTap: _pickGifFromFile,
                ),
                ListTile(
                  leading: const Icon(Icons.link_outlined),
                  title: Text(
                    getTranslated('paste_gif_url', context) ?? 'Paste GIF URL',
                  ),
                  onTap: _promptGifUrlSelection,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiKeyboard(BuildContext context) {
    final theme = Theme.of(context);
    final Color divider = theme.colorScheme.onSurface.withOpacity(.08);
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: divider),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Text(
                  getTranslated('emoji', context) ?? 'Emoji',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  tooltip: getTranslated('hide_keyboard', context) ??
                      'Hide keyboard',
                  onPressed: () {
                    setState(() => _showEmojiKeyboard = false);
                    FocusScope.of(context).requestFocus(_commentFocus);
                  },
                  icon: const Icon(Icons.keyboard_hide_outlined),
                ),
              ],
            ),
          ),
          Divider(color: divider, height: 1),
          Expanded(
            child: EmojiPicker(
              onEmojiSelected: (_, __) => setState(() {}),
              onBackspacePressed: () => setState(() {}),
              textEditingController: _commentController,
              config: Config(
                height: 256,
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(
                  emojiSizeMax: 28 *
                      (foundation.defaultTargetPlatform == TargetPlatform.iOS
                          ? 1.2
                          : 1.0),
                ),
                skinToneConfig: const SkinToneConfig(),
                categoryViewConfig: const CategoryViewConfig(),
                bottomActionBarConfig: const BottomActionBarConfig(),
                searchViewConfig: const SearchViewConfig(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_recordingComment) {
      _commentRecorder.stopRecorder();
    }
    _commentRecorder.closeRecorder();
    _recordingTimer?.cancel();
    _previewCompleteSub?.cancel();
    _commentPreviewPlayer.dispose();
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }
}

class _ImageThumbPreview extends StatelessWidget {
  final Image image;
  final VoidCallback onRemove;

  const _ImageThumbPreview({
    required this.image,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color border = cs.outlineVariant.withOpacity(0.3);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: cs.surfaceVariant.withOpacity(0.35),
              border: Border.all(color: border),
            ),
            child: _ProgressiveImage(child: image),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: cs.surface.withOpacity(0.8),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: cs.onSurface),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressiveImage extends StatelessWidget {
  final Image child;
  const _ProgressiveImage({required this.child});

  @override
  Widget build(BuildContext context) {
    final Color shimmer =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.08);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Image(
        key: ValueKey(child.image),
        image: child.image,
        fit: child.fit ?? BoxFit.cover,
        frameBuilder: (ctx, widget, frame, _) {
          if (frame == null) {
            return Container(
              color: shimmer,
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return widget;
        },
        errorBuilder: (ctx, err, stack) => Container(
          color: shimmer,
          child: Icon(Icons.image_not_supported_outlined,
              color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.5)),
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
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final bool enabled = onTap != null && !loading;
    final Color iconColor = onSurface.withOpacity(enabled ? .8 : .4);
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
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: iconColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductBlock extends StatelessWidget {
  final String? title;
  final List<String> images;
  final double? price;
  final String? currency;
  final String? description;
  final int? productId;
  final String? slug;
  const _ProductBlock({
    this.title,
    required this.images,
    this.price,
    this.currency,
    this.description,
    this.productId,
    this.slug,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final String? priceText = _formatPrice(context);
    final String descriptionText = _plainText(description);
    final bool canNavigate = productId != null && productId! > 0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: onSurface.withOpacity(.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: (images.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: images.first,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 72,
                    height: 72,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image, size: 28),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((title ?? '').isNotEmpty)
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                if (priceText != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    priceText,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
                if (descriptionText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    descriptionText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: onSurface.withOpacity(.8),
                        ),
                  ),
                ],
                if (canNavigate) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () =>
                          _openProduct(context, _sanitizeSlug(slug)),
                      child: Text(getTranslated('view_detail', context) ??
                          'View detail'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openProduct(
    BuildContext context,
    String? initialSlug,
  ) async {
    if (productId == null || productId! <= 0) {
      showCustomSnackBar(
          getTranslated('product_not_found', context) ?? 'Product unavailable',
          context);
      return;
    }
    String? slugValue = initialSlug;
    final controller = context.read<ProductDetailsController>();
    slugValue ??=
        await controller.resolveSlugByProductId(productId!, silent: true);
    if (!context.mounted) return;
    if (slugValue == null) {
      showCustomSnackBar(
          getTranslated('product_not_found', context) ?? 'Product unavailable',
          context);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetails(
          productId: productId,
          slug: slugValue,
        ),
      ),
    );
  }

  String? _formatPrice(BuildContext context) {
    if (price == null) return null;
    if (currency != null && currency!.isNotEmpty) {
      return '${price!.toStringAsFixed(2)} $currency';
    }
    return PriceConverter.convertPrice(context, price!);
  }

  String _plainText(String? source) {
    if (source == null || source.trim().isEmpty) return '';
    final withoutTags = source.replaceAll(RegExp(r'<[^>]*>'), ' ');
    final decoded = withoutTags.replaceAll('&nbsp;', ' ');
    return decoded.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String? _sanitizeSlug(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    if (lower == 'null' || lower == 'undefined') return null;
    return trimmed;
  }
}

String _sharedSubtitleText(BuildContext context, SocialPost parent) {
  final SocialPost? shared = parent.sharedPost;
  if (shared == null) return '';
  final String original =
      shared.userName ?? (getTranslated('user', context) ?? 'User');
  final String verb =
      getTranslated('shared_post_from', context) ?? 'shared a post from';
  return '$verb $original';
}

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

String _reactionActionLabel(BuildContext context, String reaction) {
  final String defaultLabel = getTranslated('like', context) ?? 'Like';
  if (reaction.isEmpty || reaction == 'Like') return defaultLabel;
  switch (reaction) {
    case 'Love':
      return getTranslated('love', context) ?? 'Love';
    case 'HaHa':
      return 'HaHa';
    case 'Wow':
      return 'Wow';
    case 'Sad':
      return getTranslated('sad', context) ?? 'Sad';
    case 'Angry':
      return getTranslated('angry', context) ?? 'Angry';
    default:
      return reaction;
  }
}

class _PostReactionsSheet extends StatefulWidget {
  final String targetId;
  final String targetType;
  final int totalCount;
  final Map<String, int> breakdown;
  final String? initialReaction;
  final String? sheetTitle;
  _PostReactionsSheet({
    required this.targetId,
    required this.targetType,
    required this.totalCount,
    required Map<String, int> breakdown,
    this.initialReaction,
    this.sheetTitle,
    Key? key,
  })  : breakdown = Map<String, int>.unmodifiable(breakdown),
        super(key: key);

  @override
  State<_PostReactionsSheet> createState() => _PostReactionsSheetState();
}

class _PostReactionsSheetState extends State<_PostReactionsSheet> {
  static const int _pageSize = 30;
  final ScrollController _scrollController = ScrollController();
  final Set<String> _actionLoading = <String>{};
  final Set<String> _loadingReactions = <String>{};
  final Map<String, List<SocialPostReaction>> _buckets =
      <String, List<SocialPostReaction>>{};
  final List<SocialPostReaction> _allEntries = <SocialPostReaction>[];
  final Map<String, String?> _reactionOffsets = <String, String?>{};
  final Map<String, bool> _hasMoreByReaction = <String, bool>{};
  final Set<String> _knownRowKeys = <String>{};
  bool _initialLoaded = false;
  String? _selectedReaction;
  String? _currentUserId;
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    try {
      final SocialController ctrl = context.read<SocialController>();
      _currentUserId = ctrl.currentUser?.id;
      _accessToken = ctrl.accessToken;
    } catch (_) {}
    _selectedReaction = (widget.initialReaction?.isNotEmpty ?? false)
        ? widget.initialReaction
        : null;
    for (final String reaction in _kReactionOrder) {
      _hasMoreByReaction[reaction] = (widget.breakdown[reaction] ?? 0) > 0;
    }
    widget.breakdown.forEach((reaction, count) {
      _hasMoreByReaction[reaction] = count > 0;
    });
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInitial(reset: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 160) return;
    _maybeLoadMoreForCurrentFilter();
  }

  Future<void> _loadInitial({bool reset = false}) async {
    const String loadingKey = '__all__';
    if (_loadingReactions.contains(loadingKey)) return;
    _loadingReactions.add(loadingKey);
    if (reset) {
      _buckets.clear();
      _allEntries.clear();
      _reactionOffsets.clear();
      _knownRowKeys.clear();
      _hasMoreByReaction.clear();
      for (final String reaction in _kReactionOrder) {
        _hasMoreByReaction[reaction] = (widget.breakdown[reaction] ?? 0) > 0;
      }
      _initialLoaded = false;
    }
    setState(() {});
    final svc = sl<SocialServiceInterface>();
    try {
      final reactions = await svc.getReactions(
        targetId: widget.targetId,
        type: widget.targetType,
        reactionFilter: _kAllReactionCodes,
        limit: _pageSize,
        offset: null,
      );
      if (!mounted) return;
      _ingestReactions(reactions);
      setState(() {
        _initialLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(e.toString(), context, isError: true);
      setState(() {
        _initialLoaded = true;
      });
    } finally {
      _loadingReactions.remove(loadingKey);
      if (mounted) setState(() {});
    }
  }

  void _maybeLoadMoreForCurrentFilter() {
    if (_selectedReaction == null) {
      final String? next = _nextReactionNeedingData();
      if (next != null) {
        _loadMoreForReaction(next);
      }
      return;
    }
    final String reaction = _selectedReaction!;
    if (_shouldLoadMore(reaction)) {
      _loadMoreForReaction(reaction);
    }
  }

  bool _shouldLoadMore(String reaction) {
    if (_loadingReactions.contains(reaction)) return false;
    return _hasMoreByReaction[reaction] ?? false;
  }

  String? _nextReactionNeedingData() {
    for (final String reaction in _kReactionOrder) {
      if (_shouldLoadMore(reaction)) return reaction;
    }
    return null;
  }

  Future<void> _loadMoreForReaction(String reaction) async {
    if (_loadingReactions.contains(reaction)) return;
    _loadingReactions.add(reaction);
    setState(() {});
    final svc = sl<SocialServiceInterface>();
    try {
      final reactions = await svc.getReactions(
        targetId: widget.targetId,
        type: widget.targetType,
        reactionFilter: _reactionCodeForLabel(reaction) ?? '1',
        limit: _pageSize,
        offset: _reactionOffsets[reaction],
      );
      if (!mounted) return;
      final List<SocialPostReaction> filtered =
          reactions.where((e) => e.reaction == reaction).toList();
      _ingestReactions(filtered);
      if (filtered.isEmpty ||
          (_buckets[reaction]?.length ?? 0) >=
              (widget.breakdown[reaction] ?? 0)) {
        _hasMoreByReaction[reaction] = false;
      }
      if (filtered.isNotEmpty) {
        final SocialPostReaction? last = filtered.lastWhere(
          (e) => e.reaction == reaction && e.rowId != null,
          orElse: () => filtered.last,
        );
        _reactionOffsets[reaction] = last?.rowId;
      }
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(e.toString(), context, isError: true);
      setState(() {});
    } finally {
      _loadingReactions.remove(reaction);
      if (mounted) setState(() {});
    }
  }

  void _ingestReactions(List<SocialPostReaction> reactions) {
    if (reactions.isEmpty) return;
    bool updated = false;
    final Set<String> touchedReactions = <String>{};
    for (final SocialPostReaction reaction in reactions) {
      final String label =
          reaction.reaction.isNotEmpty ? reaction.reaction : 'Like';
      touchedReactions.add(label);
      final String rowKey =
          '${label}_${reaction.rowId ?? '${reaction.user.id}_${reaction.user.userName ?? ''}'}';
      if (_knownRowKeys.contains(rowKey)) continue;
      _knownRowKeys.add(rowKey);
      _buckets.putIfAbsent(label, () => <SocialPostReaction>[]).add(reaction);
      _allEntries.add(reaction);
      _hasMoreByReaction.putIfAbsent(label, () => true);
      if (reaction.rowId != null) {
        final int? current = int.tryParse(_reactionOffsets[label] ?? '');
        final int? incoming = int.tryParse(reaction.rowId!);
        if (incoming != null && (current == null || incoming > current)) {
          _reactionOffsets[label] = reaction.rowId;
        }
      }
      updated = true;
    }
    if (!updated) return;

    int orderKey(SocialPostReaction r) {
      final int? id = int.tryParse(r.rowId ?? '');
      return id ?? (_allEntries.indexOf(r) + 1);
    }

    _allEntries.sort((a, b) => orderKey(a).compareTo(orderKey(b)));
    for (final List<SocialPostReaction> bucket in _buckets.values) {
      bucket.sort((a, b) => orderKey(a).compareTo(orderKey(b)));
    }
    for (final String reaction in touchedReactions) {
      final int have = _buckets[reaction]?.length ?? 0;
      final int total = widget.breakdown[reaction] ?? have;
      _hasMoreByReaction[reaction] = have < total;
    }
  }

  List<_ReactionFilterOption> _buildFilterOptions(BuildContext context) {
    final List<_ReactionFilterOption> items = <_ReactionFilterOption>[
      _ReactionFilterOption(
        value: null,
        label: getTranslated('all', context) ?? 'All',
        count: _effectiveReactionCount(null),
      ),
    ];
    for (final String reaction in _kReactionOrder) {
      final int count = _effectiveReactionCount(reaction);
      if (count <= 0) continue;
      items.add(
        _ReactionFilterOption(
          value: reaction,
          label: _reactionActionLabel(context, reaction),
          count: count,
        ),
      );
    }
    return items;
  }

  int _effectiveReactionCount(String? reaction) {
    if (reaction == null) {
      final int loaded = _allEntries.length;
      if (loaded > 0) return loaded;
      return widget.totalCount;
    }
    final int loaded = _buckets[reaction]?.length ?? 0;
    final int expected = widget.breakdown[reaction] ?? 0;
    return loaded > expected ? loaded : expected;
  }

  void _onSelectFilter(String? reaction) {
    if (_selectedReaction == reaction) return;
    setState(() {
      _selectedReaction = reaction;
    });
    if (reaction != null && (_buckets[reaction]?.isEmpty ?? true)) {
      _loadMoreForReaction(reaction);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color surface = theme.colorScheme.surface;
    final Color onSurface = theme.colorScheme.onSurface;
    final filters = _buildFilterOptions(context);
    final Widget filterBar = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((option) {
          final bool selected = option.value == _selectedReaction ||
              (option.value == null && _selectedReaction == null);
          final theme = Theme.of(context);
          final bool isLight = theme.brightness == Brightness.light;
          final Color textColor = selected
              ? (isLight ? Colors.black : Colors.white)
              : theme.colorScheme.onSurface.withOpacity(0.7);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () => _onSelectFilter(option.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (option.value != null) ...[
                          _reactionIcon(option.value!, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            _formatSocialCount(option.count),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ] else ...[
                          Text(
                            (getTranslated('all', context) ?? 'All'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatSocialCount(option.count),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: textColor.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      height: 2,
                      width: selected ? 36 : 0,
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );

    final Widget listSection = Expanded(
      child: _buildList(context, onSurface),
    );

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: surface,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.sheetTitle ??
                      (getTranslated('reactions', context) ?? 'Reactions'),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatSocialCount(widget.totalCount)} ${getTranslated('reactions', context) ?? 'reactions'}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: onSurface.withOpacity(0.7)),
                ),
                const SizedBox(height: 12),
                if (filters.length > 1 || widget.totalCount > 0) filterBar,
                const SizedBox(height: 12),
                listSection,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, Color onSurface) {
    final List<SocialPostReaction> entries = _currentEntries;
    final bool isLoadingCurrent = _isLoadingCurrentFilter;
    if (!_initialLoaded && isLoadingCurrent) {
      return const Center(child: CircularProgressIndicator());
    }
    final bool hasEntries = entries.isNotEmpty;
    if (!hasEntries) {
      return RefreshIndicator(
        onRefresh: () => _loadInitial(reset: true),
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 120),
            Icon(Icons.emoji_emotions_outlined,
                size: 36, color: onSurface.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              getTranslated('no_reactions', context) ?? 'Chưa có cảm xúc nào.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 120),
          ],
        ),
      );
    }
    final bool showTailLoader = _isLoadingCurrentFilter ||
        (_selectedReaction == null && _loadingReactions.isNotEmpty);
    return RefreshIndicator(
      onRefresh: () => _loadInitial(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: entries.length + (showTailLoader ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= entries.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final SocialPostReaction entry = entries[index];
          final bool isCurrentUser =
              _currentUserId != null && _currentUserId == entry.user.id;
          final Widget? actionButton = _buildActionButton(context, entry);
          return _ReactionUserTile(
            reaction: entry,
            isCurrentUser: isCurrentUser,
            actionButton: actionButton,
          );
        },
      ),
    );
  }

  Widget? _buildActionButton(
      BuildContext context, SocialPostReaction reaction) {
    final _ReactionActionType type = _resolveActionType(reaction);
    if (type == _ReactionActionType.none) return null;
    final bool loading = _actionLoading.contains(reaction.user.id);
    final theme = Theme.of(context);
    final Color buttonColor = theme.colorScheme.primary;
    final Color textColor = theme.colorScheme.onPrimary;
    final String label = switch (type) {
      _ReactionActionType.follow =>
        getTranslated('follow', context) ?? 'Follow',
      _ReactionActionType.message =>
        getTranslated('message', context) ?? 'Message',
      _ReactionActionType.none => '',
    };

    Widget buildChild() {
      if (loading) {
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }
      return Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final VoidCallback? handler = (type == _ReactionActionType.none || loading)
        ? null
        : () => _handleAction(type, reaction);

    final ButtonStyleButton button = ElevatedButton(
      onPressed: handler,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: buildChild(),
    );

    return SizedBox(
      height: 34,
      child: button,
    );
  }

  _ReactionActionType _resolveActionType(SocialPostReaction reaction) {
    final String userId = reaction.user.id;
    if (userId.isEmpty) return _ReactionActionType.none;
    if (_currentUserId != null && _currentUserId == userId) {
      return _ReactionActionType.none;
    }
    if (reaction.user.isFollowing) {
      return _ReactionActionType.message;
    }
    return _ReactionActionType.follow;
  }

  Future<void> _handleAction(
      _ReactionActionType type, SocialPostReaction reaction) async {
    switch (type) {
      case _ReactionActionType.follow:
        await _handleFollowAction(reaction);
        break;
      case _ReactionActionType.message:
        await _handleMessageAction(reaction);
        break;
      case _ReactionActionType.none:
        break;
    }
  }

  Future<void> _handleFollowAction(SocialPostReaction reaction) async {
    final String userId = reaction.user.id;
    if (userId.isEmpty) return;
    if (_actionLoading.contains(userId)) return;
    setState(() {
      _actionLoading.add(userId);
    });
    try {
      final svc = sl<SocialServiceInterface>();
      final bool followed = await svc.toggleFollow(targetUserId: userId);
      if (!mounted) return;
      setState(() {
        _actionLoading.remove(userId);
        if (followed) {
          _updateEntryUser(userId, (user) => user.copyWith(isFollowing: true));
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _actionLoading.remove(userId);
      });
      showCustomSnackBar(e.toString(), context, isError: true);
    }
  }

  Future<void> _handleMessageAction(SocialPostReaction reaction) async {
    final String? token = _accessToken;
    if (token == null || token.isEmpty) {
      showCustomSnackBar(
        getTranslated('login_required', context) ?? 'Please login to continue',
        context,
        isError: true,
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          accessToken: token,
          peerUserId: reaction.user.id,
          peerName: reaction.user.displayName ?? reaction.user.userName,
          peerAvatar: reaction.user.avatarUrl,
        ),
      ),
    );
  }

  void _updateEntryUser(
    String userId,
    SocialUser Function(SocialUser current) mapper,
  ) {
    void updateList(List<SocialPostReaction> list) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].user.id == userId) {
          list[i] = list[i].copyWith(user: mapper(list[i].user));
        }
      }
    }

    updateList(_allEntries);
    for (final List<SocialPostReaction> bucket in _buckets.values) {
      updateList(bucket);
    }
  }

  List<SocialPostReaction> get _currentEntries {
    if (_selectedReaction == null) return _allEntries;
    return _buckets[_selectedReaction] ?? const <SocialPostReaction>[];
  }

  bool get _isLoadingCurrentFilter {
    if (_selectedReaction == null) {
      return !_initialLoaded && _loadingReactions.contains('__all__');
    }
    return _loadingReactions.contains(_selectedReaction);
  }
}

class _ReactionFilterOption {
  final String? value;
  final String label;
  final int count;
  const _ReactionFilterOption({
    required this.value,
    required this.label,
    required this.count,
  });
}

enum _ReactionActionType { none, follow, message }

class _ReactionUserTile extends StatelessWidget {
  final SocialPostReaction reaction;
  final bool isCurrentUser;
  final Widget? actionButton;
  const _ReactionUserTile({
    required this.reaction,
    required this.isCurrentUser,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    final SocialUser user = reaction.user;
    final String displayName = user.displayName ??
        user.userName ??
        (getTranslated('user', context) ?? 'User');
    final bool showMutual =
        !isCurrentUser && (reaction.mutualFriendsCount ?? 0) > 0;
    final String? subtitle = showMutual
        ? '${reaction.mutualFriendsCount} ${getTranslated('mutual_friends', context) ?? 'bạn chung'}'
        : null;

    return ListTile(
      onTap: () => _navigateToProfile(context, user.id),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: _AvatarWithReaction(
        reaction: reaction.reaction,
        avatarUrl: user.avatarUrl,
      ),
      title: Text(
        displayName,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).hintColor),
            )
          : null,
      trailing: actionButton != null
          ? SizedBox(
              width: 124,
              child: Align(
                alignment: Alignment.centerRight,
                child: actionButton,
              ),
            )
          : null,
    );
  }
}

class _AvatarWithReaction extends StatelessWidget {
  final String reaction;
  final String? avatarUrl;
  const _AvatarWithReaction({required this.reaction, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final ImageProvider? avatarProvider =
        (avatarUrl != null && avatarUrl!.isNotEmpty)
            ? CachedNetworkImageProvider(avatarUrl!)
            : null;
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CircleAvatar(
              backgroundImage: avatarProvider,
              child: avatarProvider == null
                  ? const Icon(Icons.person, size: 24)
                  : null,
            ),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: _reactionIcon(reaction, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
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

void _navigateToProfile(BuildContext context, String? userId,
    {String? pageId}) {
  final String? pageIdStr = pageId?.trim();
  if (pageIdStr != null && pageIdStr.isNotEmpty) {
    try {
      final pageCtrl = context.read<page_ctrl.SocialPageController>();
      final page_models.SocialGetPage? page =
          pageCtrl.findPageByIdString(pageIdStr);
      if (page != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => page_screens.SocialPageDetailScreen(page: page),
          ),
        );
        return;
      }
    } catch (_) {
      // Page controller not available; fall back to profile
    }

    // fallback: dựng stub page để vẫn mở Page detail
    final int id = int.tryParse(pageIdStr) ?? 0;
    final page_models.SocialGetPage stub = page_models.SocialGetPage(
      pageId: id,
      ownerUserId: 0,
      username: pageIdStr,
      name: pageIdStr,
      pageName: pageIdStr,
      description: null,
      avatarUrl: '',
      coverUrl: '',
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => page_screens.SocialPageDetailScreen(page: stub),
      ),
    );
    return;
  }

  if (userId == null || userId.isEmpty) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ProfileScreen(targetUserId: userId),
    ),
  );
}

String _formatSocialCount(int value) {
  if (value <= 0) return '0';
  if (value < 1000) return value.toString();
  const units = [
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

String _trimTrailingZeros(String input) {
  if (!input.contains('.')) return input;
  return input.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
}

class _CountUnit {
  final int threshold;
  final String suffix;
  const _CountUnit({required this.threshold, required this.suffix});
}

class _RepliesLazy extends StatefulWidget {
  final SocialComment comment;
  final SocialServiceInterface service;
  final void Function(SocialComment) onRequestReply;
  final void Function(SocialComment comment,
      {bool isReply, BuildContext? context})? onShowReactions;
  final String? currentUserId;
  const _RepliesLazy({
    required this.comment,
    required this.service,
    required this.onRequestReply,
    this.onShowReactions,
    this.currentUserId,
  });
  @override
  State<_RepliesLazy> createState() => _RepliesLazyState();
}

class _RepliesLazyState extends State<_RepliesLazy> {
  bool _expanded = false;
  bool _loading = false;
  List<SocialComment> _replies = const [];
  final Set<String> _replyReactionLoading = <String>{};
  final TextEditingController _replyController = TextEditingController();
  bool _sending = false;

  void _sortReplies() {
    int comparison(SocialComment a, SocialComment b) {
      final DateTime? aTime = a.createdAt;
      final DateTime? bTime = b.createdAt;
      if (aTime != null && bTime != null) {
        final cmp = aTime.compareTo(bTime);
        if (cmp != 0) return -cmp;
      } else if (aTime != null) {
        return -1;
      } else if (bTime != null) {
        return 1;
      }
      final int aId = int.tryParse(a.id) ?? 0;
      final int bId = int.tryParse(b.id) ?? 0;
      return bId.compareTo(aId);
    }

    _replies = [..._replies]..sort(comparison);
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final list =
          await widget.service.getCommentReplies(commentId: widget.comment.id);
      setState(() {
        _replies = list;
        _expanded = true;
        _sortReplies();
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _reactOnReply(SocialComment reply, String reaction) async {
    final idx = _replies.indexWhere((e) => e.id == reply.id);
    if (idx == -1) return;
    if (_replyReactionLoading.contains(reply.id)) return;
    final previous = _replies[idx];
    final was = previous.myReaction;
    final now = reaction;
    int delta = 0;
    if (was.isEmpty && now.isNotEmpty) {
      delta = 1;
    } else if (was.isNotEmpty && now.isEmpty) {
      delta = -1;
    }
    final optimistic = previous.copyWith(
      myReaction: now,
      reactionCount: (previous.reactionCount + delta).clamp(0, 1 << 31).toInt(),
    );
    setState(() {
      _replies = [
        ..._replies.sublist(0, idx),
        optimistic,
        ..._replies.sublist(idx + 1),
      ];
    });
    _replyReactionLoading.add(reply.id);
    try {
      await widget.service.reactToReply(
        replyId: reply.id,
        reaction: now,
      );
    } catch (e) {
      setState(() {
        _replies = [
          ..._replies.sublist(0, idx),
          previous,
          ..._replies.sublist(idx + 1),
        ];
      });
      showCustomSnackBar(e.toString(), context, isError: true);
    } finally {
      _replyReactionLoading.remove(reply.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final replyActionStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: onSurface.withOpacity(.6));
    String? currentUserId;
    try {
      final socialCtrl = context.read<SocialController>();
      currentUserId = socialCtrl.currentUser?.id;
    } catch (_) {
      currentUserId = null;
    }
    if (!_expanded) {
      final repliesCount = widget.comment.repliesCount ?? 0;
      if (repliesCount == 0) {
        return const SizedBox.shrink();
      }
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: _load,
          child: Text(
            '${getTranslated('view_replies', context) ?? 'View replies'} ($repliesCount)',
            style: replyActionStyle,
          ),
        ),
      );
    }
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 6),
        child: CircularProgressIndicator(),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        for (final r in _replies)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _navigateToProfile(context, r.userId),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundImage:
                        (r.userAvatar != null && r.userAvatar!.isNotEmpty)
                            ? NetworkImage(r.userAvatar!)
                            : null,
                    child: (r.userAvatar == null || r.userAvatar!.isEmpty)
                        ? const Icon(Icons.person, size: 14)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  _navigateToProfile(context, r.userId),
                              child: Text(
                                r.userName ??
                                    (getTranslated('user', context) ?? 'User'),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: onSurface,
                                    ),
                              ),
                            ),
                          ),
                          if ((r.timeText ?? '').isNotEmpty)
                            Text(
                              _formatTimeText(context, r.timeText),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: onSurface.withOpacity(.6)),
                            ),
                          // 🔹 Ẩn nút báo cáo nếu là reply của chính user login
                          if (currentUserId != null && currentUserId != r.userId)
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.more_vert, size: 18),
                              onSelected: (value) async {
                                if (value == 'report') {
                                  await showReportCommentDialog(
                                  context: context,
                                  comment: r,
                                  );
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem<String>(
                                  value: 'report',
                                  child: Text(
                                    getTranslated('report_comment', ctx) ?? 'Report comment',
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                        if ((r.text ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              r.text!,
                              style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: onSurface) ??
                                  TextStyle(color: onSurface),
                            ),
                          ),
                      if ((r.imageUrl ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: _CommentImagePreview(url: r.imageUrl!),
                        ),
                      if ((r.audioUrl ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: _AudioPlayerBox(
                              url: r.audioUrl!, autoplay: false),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            // TRÁI: nút Reply + (icon Like cố định + reactionCount)
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () =>
                                        widget.onRequestReply(widget.comment),
                                    // Nếu muốn reply trực tiếp vào reply hiện tại:
                                    // onPressed: () => widget.onRequestReply(r),
                                    child: Text(
                                      getTranslated('reply', context) ??
                                          'Reply',
                                      style: replyActionStyle,
                                    ),
                                  ),

                                  // Chỉ chèn khoảng cách & cụm (👍 + count) khi count > 0
                                  if (r.reactionCount > 0) ...[
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: () => widget.onShowReactions
                                          ?.call(r, isReply: true),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _reactionIcon('Like', size: 18),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatSocialCount(r.reactionCount),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      onSurface.withOpacity(.6),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // PHẢI: nút Reaction (icon theo myReaction + NHÃN), tap/long-press
                            Builder(
                              builder: (reactCtx) {
                                final reacted = r.myReaction.isNotEmpty;
                                final style = Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: reacted
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : onSurface.withOpacity(.6),
                                      fontWeight:
                                          reacted ? FontWeight.w600 : null,
                                    );

                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    final next =
                                        r.myReaction == 'Like' ? '' : 'Like';
                                    _reactOnReply(r, next);
                                  },
                                  onLongPress: () {
                                    final overlay = Overlay.of(reactCtx);
                                    if (overlay == null) return;
                                    final overlayBox = overlay.context
                                        .findRenderObject() as RenderBox;
                                    final box = reactCtx.findRenderObject()
                                        as RenderBox?;
                                    final Offset centerGlobal = box != null
                                        ? box.localToGlobal(
                                            box.size.center(Offset.zero),
                                            ancestor: overlayBox,
                                          )
                                        : overlayBox.size.center(Offset.zero);

                                    _showReactionsOverlay(
                                      reactCtx,
                                      centerGlobal,
                                      onSelect: (val) => _reactOnReply(r, val),
                                    );
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _reactionIcon(r.myReaction, size: 18),
                                      const SizedBox(width: 6),
                                    ],
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
              ],
            ),
          ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 4,
            children: [
              TextButton(
                onPressed: () => setState(() => _expanded = false),
                child: Text(
                    getTranslated('collapse_replies', context) ??
                        'Collapse replies',
                    style: replyActionStyle),
              ),
              // TextButton(
              //   onPressed: () => widget.onRequestReply(widget.comment),
              //   child: Text(getTranslated('reply', context) ?? 'Reply',
              //       style: replyActionStyle),
              // ),
            ],
          ),
        ),
        // form reply inline (đang tắt)
        if (false)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  decoration: InputDecoration(
                    hintText: getTranslated('write_reply', context) ??
                        'Write a reply...',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: getTranslated('send', context) ?? 'Send',
                onPressed: _sending
                    ? null
                    : () async {
                        final txt = _replyController.text.trim();
                        if (txt.isEmpty) return;
                        setState(() => _sending = true);
                        try {
                          await widget.service.createReply(
                              commentId: widget.comment.id, text: txt);
                          _replyController.clear();
                          await _load();
                        } catch (e) {
                          showCustomSnackBar(e.toString(), context,
                              isError: true);
                        } finally {
                          if (mounted) setState(() => _sending = false);
                        }
                      },
                icon: const Icon(Icons.send),
              ),
            ],
          ),
      ],
    );
  }
}

class _CommentImagePreview extends StatelessWidget {
  final String url;
  const _CommentImagePreview({required this.url});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImageViewer(context, url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 140,
          width: 140,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.open_in_full,
                      size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showImageViewer(BuildContext context, String url) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: getTranslated('close', context) ?? 'Close',
    barrierColor: Colors.black87,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(),
                  child: Container(color: Colors.transparent),
                ),
              ),
              Center(
                  child: InteractiveViewer(
                      child: CachedNetworkImage(imageUrl: url))),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
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
    const double popupWidth = 300;
    const double popupHeight = 56;
    return Stack(
      children: [
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

const List<String> _kReactionOrder = <String>[
  'Like',
  'Love',
  'HaHa',
  'Wow',
  'Sad',
  'Angry',
];

const Map<String, String> _kReactionCodeLookup = <String, String>{
  'Like': '1',
  'Love': '2',
  'HaHa': '3',
  'Wow': '4',
  'Sad': '5',
  'Angry': '6',
};

const String _kAllReactionCodes = '1,2,3,4,5,6';

String? _reactionCodeForLabel(String? label) {
  if (label == null || label.isEmpty) return null;
  return _kReactionCodeLookup[label];
}

String _basename(String path) {
  final parts = path.split(RegExp(r'[\\/]'));
  return parts.isNotEmpty ? parts.last : path;
}

String _formatTimeText(BuildContext context, String? raw) {
  if (raw == null) return '';
  final s = raw.trim();
  if (s.isEmpty) return '';
  final intVal = int.tryParse(s);
  if (intVal == null) {
    return s;
  }
  int ms;
  if (intVal >= 1000000000000) {
    ms = intVal;
  } else if (intVal >= 1000000000) {
    ms = intVal * 1000;
  } else {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    ms = nowMs - (intVal * 1000);
  }
  final dt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: false);
  final now = DateTime.now();
  Duration diff = now.difference(dt);
  if (diff.isNegative) diff = -diff;

  if (diff.inSeconds < 60) {
    return '${diff.inSeconds} ${getTranslated('seconds_ago', context) ?? 'seconds ago'}';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} ${getTranslated('minutes_ago', context) ?? 'minutes ago'}';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} ${getTranslated('hours_ago', context) ?? 'hours ago'}';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays} ${getTranslated('days_ago', context) ?? 'days ago'}';
  }
  if (diff.inDays < 30) {
    return '${(diff.inDays / 7).floor()} ${getTranslated('weeks_ago', context) ?? 'weeks ago'}';
  }
  if (diff.inDays < 365) {
    return '${(diff.inDays / 30).floor()} ${getTranslated('months_ago', context) ?? 'months ago'}';
  }
  return '${(diff.inDays / 365).floor()} ${getTranslated('years_ago', context) ?? 'years ago'}';
}

class _AudioPlayerBox extends StatefulWidget {
  final String url;
  final bool autoplay;
  final String? title;
  const _AudioPlayerBox({required this.url, this.autoplay = false, this.title});
  @override
  State<_AudioPlayerBox> createState() => _AudioPlayerBoxState();
}

class _AudioPlayerBoxState extends State<_AudioPlayerBox> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;
  Duration _pos = Duration.zero;
  Duration _dur = const Duration(seconds: 1);
  @override
  void initState() {
    super.initState();
    _player.onPositionChanged.listen((d) => setState(() => _pos = d));
    _player.onDurationChanged.listen((d) => setState(() => _dur = d));
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playing = false;
          _pos = Duration.zero;
        });
      } else {
        _playing = false;
        _pos = Duration.zero;
      }
    });
    if (widget.autoplay) {
      _player.play(UrlSource(widget.url));
      _playing = true;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(_playing
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_fill),
              onPressed: () async {
                if (_playing) {
                  await _player.pause();
                } else {
                  await _player.play(UrlSource(widget.url));
                }
                setState(() => _playing = !_playing);
              },
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  final Color onSurface = Theme.of(context).colorScheme.onSurface;
                  final totalMs = _dur.inMilliseconds;
                  final posMs = _pos.inMilliseconds;
                  final double progress = totalMs <= 0
                      ? 0
                      : (posMs.clamp(0, totalMs)) / totalMs;
                  return _WaveformSeekBar(
                    progress: progress,
                    activeColor: onSurface,
                    inactiveColor: onSurface.withOpacity(0.25),
                    maxHeight: 36,
                    samples: _generateWaveform(widget.url),
                    onSeekPercent: (p) async {
                      if (totalMs > 0) {
                        await _player
                            .seek(Duration(milliseconds: (p * totalMs).toInt()));
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
        if ((widget.title ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(widget.title!),
          ),
      ],
    );
  }
}

List<double> _generateWaveform(String key, {int count = 32}) {
  final rnd = Random(key.hashCode);
  final List<double> values = [];
  for (int i = 0; i < count; i++) {
    final double base = 0.25 + rnd.nextDouble() * 0.75; // 0.25..1.0
    values.add(base);
  }
  // mirror to keep symmetrical feel similar to reference image
  final List<double> mirrored = [
    ...values.take(count ~/ 2),
    ...(values.take(count - count ~/ 2).toList().reversed),
  ];
  return mirrored;
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
    this.maxHeight = 36,
    this.samples,
  });

  static const List<double> _basePattern = [
    0.25, 0.35, 0.45, 0.6, 0.75, 0.9, 1.0, 0.9, 0.8, 1.0, 0.9, 0.75, 0.6, 0.45,
    0.35, 0.25
  ];
  static const double _barWidth = 5;
  static const double _barSpacing = 6;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final List<double> pattern = samples ?? _basePattern;
        final double totalWidth = (_barWidth * pattern.length) +
            _barSpacing * (pattern.length - 1);
        final double available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : totalWidth;
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
              if (i != pattern.length - 1)
                SizedBox(width: _barSpacing * scale),
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
