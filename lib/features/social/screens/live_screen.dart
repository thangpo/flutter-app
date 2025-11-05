import 'dart:async';
import 'dart:math';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_sixvalley_ecommerce/di_container.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_comment.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_live_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class LiveScreen extends StatefulWidget {
  final String streamName;
  final String accessToken;
  final int broadcasterUid;
  final String? initialToken;
  final String? postId;
  final bool isHost;
  final String? hostDisplayName;
  final String? hostAvatarUrl;
  final int? initialViewerUid;

  const LiveScreen({
    super.key,
    required this.streamName,
    required this.accessToken,
    required this.broadcasterUid,
    this.initialToken,
    this.postId,
    this.isHost = true,
    this.hostDisplayName,
    this.hostAvatarUrl,
    this.initialViewerUid,
  });

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  static const List<String> _reactionOptions = <String>[
    'Like',
    'Love',
    'HaHa',
    'Wow',
    'Sad',
    'Angry',
  ];

  final SocialLiveRepository _repository = const SocialLiveRepository(
    apiBaseUrl: AppConstants.socialBaseUrl,
    serverKey: AppConstants.socialServerKey,
  );
  bool get _isHost => widget.isHost;

  RtcEngine? _engine;
  String? _token;
  bool _isInitializing = false;
  bool _joined = false;
  String? _errorMessage;
  final List<SocialComment> _comments = <SocialComment>[];
  final Set<String> _commentIds = <String>{};
  String? _commentsOffset;
  Timer? _commentsTimer;
  bool _commentsLoading = false;
  String? _commentsError;
  bool _showComments = true;
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _commentsScrollController = ScrollController();
  bool _sendingComment = false;
  bool _endRequested = false;
  String? _hostName;
  String? _hostAvatar;
  int? _viewerUid;
  int? _remoteUid;
  int _viewerCount = 0;
  int? _reactionTotal;
  int? _commentTotal;
  int? _shareTotal;
  String _currentReaction = '';
  bool _reacting = false;
  Timer? _statsTimer;
  bool _fetchingStats = false;
  bool? _isLiveNow;
  String? _liveWord;

  @override
  void initState() {
    super.initState();
    if (_isHost) {
      _token = widget.initialToken;
    } else {
      _viewerUid = widget.initialViewerUid;
      _token = widget.initialToken;
    }
    _hostName = widget.hostDisplayName ?? _hostName;
    _hostAvatar = widget.hostAvatarUrl ?? _hostAvatar;
    if ((widget.postId ?? '').isNotEmpty) {
      _startCommentsPolling();
      _startStatsPolling();
    }
    if (_isHost) {
      _loadHostProfile();
    }
    _prepareStream();
  }

  Future<void> _prepareStream() async {
    if (_isInitializing) return;
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      if (!_isHost) {
        _viewerUid ??= widget.initialViewerUid ?? _generateViewerUid();
      }
      String? token = _token;
      final String accessToken = widget.accessToken;
      final bool hasAccessToken = accessToken.trim().isNotEmpty;
      final bool shouldGenerateToken =
          token == null || token.isEmpty || !_isHost;
      if (shouldGenerateToken && hasAccessToken) {
        final Map<String, dynamic>? payload =
            await _repository.generateAgoraToken(
          accessToken: accessToken,
          channelName: widget.streamName,
          uid: _isHost ? widget.broadcasterUid : _viewerUid!,
          role: _isHost ? 'publisher' : 'audience',
        );
        token = (payload?['token_agora'] ?? payload?['token'])?.toString();
        if (!_isHost) {
          final int? resolvedUid =
              int.tryParse(payload?['uid']?.toString() ?? '');
          if (resolvedUid != null) {
            _viewerUid = resolvedUid;
          }
        }
      }

      if ((token == null || token.isEmpty) &&
          !_isHost &&
          (widget.initialToken?.isNotEmpty ?? false)) {
        token = widget.initialToken;
      }

      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Unable to fetch livestream token.';
        });
        return;
      }

      if (_isHost) {
        final Map<Permission, PermissionStatus> permissionStatuses = await [
          Permission.camera,
          Permission.microphone,
        ].request();

        final bool permissionsGranted = permissionStatuses.values.every(
          (PermissionStatus status) => status.isGranted,
        );

        if (!permissionsGranted) {
          setState(() {
            _errorMessage =
                'Camera and microphone permissions are required to go live.';
          });
          return;
        }
      }

      _token = token;
      await _initAgora();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialise livestream: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  void _startCommentsPolling() {
    if (_commentsTimer != null) return;
    final String? postId = widget.postId;
    if (postId == null || postId.isEmpty) return;
    _pollComments(initial: true);
    _commentsTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _pollComments(),
    );
  }

  void _startStatsPolling() {
    if (_statsTimer != null) return;
    final String? postId = widget.postId;
    if (postId == null || postId.isEmpty) return;
    _refreshPostStats();
    _statsTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => _refreshPostStats(),
    );
  }

  Future<void> _refreshPostStats() async {
    if (_fetchingStats) return;
    final String? postId = widget.postId;
    if (postId == null || postId.isEmpty) return;
    _fetchingStats = true;
    try {
      final SocialServiceInterface service = sl<SocialServiceInterface>();
      final SocialPost? post = await service.getPostById(postId: postId);
      if (!mounted) return;
      if (post != null) {
        setState(() {
          _reactionTotal = post.reactionCount;
          _commentTotal = post.commentCount;
          _shareTotal = post.shareCount;
          _currentReaction = normalizeSocialReaction(post.myReaction);
          _hostName ??= post.userName;
          _hostAvatar ??= post.userAvatar;
        });
      }
    } catch (_) {
      // ignore stats refresh failures silently
    } finally {
      _fetchingStats = false;
    }
  }

  Future<void> _loadHostProfile() async {
    if (!_isHost) return;
    try {
      final SocialServiceInterface service = sl<SocialServiceInterface>();
      final dynamic user = await service.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _hostName = user?.displayName ?? user?.userName ?? _hostName;
        _hostAvatar = user?.avatarUrl ?? _hostAvatar;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hostName ??= 'Your livestream';
      });
    }
  }

  Widget _buildCommentsPanel() {
    final ThemeData theme = Theme.of(context);
    final bool canComment = (widget.postId ?? '').isNotEmpty;
    final double bottomPadding = MediaQuery.of(context).padding.bottom + 12;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 24, 16, bottomPadding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showComments) _buildCommentsList(theme),
            if (!_showComments)
              const SizedBox(
                height: 12,
              ),
            if (_commentsError != null && _comments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Unable to refresh comments.',
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.redAccent.shade200,
                            ) ??
                            const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: _commentsLoading
                          ? null
                          : () => _pollComments(initial: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            if (canComment) _buildCommentInput(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsList(ThemeData theme) {
    final TextStyle nameStyle = theme.textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(color: Colors.white, fontWeight: FontWeight.w600);
    final TextStyle textStyle = theme.textTheme.bodyMedium?.copyWith(
          color: Colors.white,
        ) ??
        const TextStyle(color: Colors.white);
    final TextStyle timeStyle = theme.textTheme.bodySmall?.copyWith(
          color: Colors.white70,
        ) ??
        const TextStyle(color: Colors.white70, fontSize: 12);

    Widget content;
    if (_comments.isEmpty) {
      if (_commentsLoading) {
        content = const SizedBox.shrink();
      } else if (_commentsError != null) {
        content = Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Text(
            'Unable to load comments at the moment.',
            style: textStyle.copyWith(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        );
      } else {
        content = Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'No comments yet',
            style: textStyle.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        );
      }
    } else {
      content = ListView.builder(
        controller: _commentsScrollController,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        itemCount: _comments.length,
        itemBuilder: (BuildContext context, int index) {
          return _buildCommentTile(
            _comments[index],
            nameStyle,
            textStyle,
            timeStyle,
          );
        },
      );
    }

    return SizedBox(
      height: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.28),
                ),
                child: content,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _formatCommentTime(SocialComment comment) {
    DateTime? timestamp = comment.createdAt;
    if (timestamp == null) {
      final String? raw = comment.timeText?.trim();
      if (raw != null && raw.isNotEmpty) {
        final int? epoch = int.tryParse(raw);
        if (epoch != null) {
          if (epoch > 1000000000000) {
            timestamp = DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: true);
          } else if (epoch > 0) {
            timestamp =
                DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true);
          }
        }
      }
    }
    if (timestamp == null) {
      final String? fallback = comment.timeText;
      return (fallback != null && fallback.isNotEmpty) ? fallback : null;
    }
    timestamp = timestamp.toLocal();
    final DateTime now = DateTime.now();
    final Duration diff = now.difference(timestamp);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(timestamp.day)}/${two(timestamp.month)}/${timestamp.year} '
        '${two(timestamp.hour)}:${two(timestamp.minute)}';
  }

  Widget _buildCommentTile(
    SocialComment comment,
    TextStyle nameStyle,
    TextStyle textStyle,
    TextStyle timeStyle,
  ) {
    final String displayName =
        (comment.userName?.isNotEmpty ?? false) ? comment.userName! : 'User';
    final String? message = comment.text;
    final bool hasAvatar =
        comment.userAvatar != null && comment.userAvatar!.trim().isNotEmpty;

    // ✅ TÍNH TRƯỚC
    final String? formattedTime = _formatCommentTime(comment);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white24,
            backgroundImage:
                hasAvatar ? NetworkImage(comment.userAvatar!) : null,
            child: hasAvatar
                ? null
                : const Icon(Icons.person, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: nameStyle),
                  if (message != null && message.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(message, style: textStyle),
                  ],
                  if (formattedTime != null) ...[
                    const SizedBox(height: 4),
                    Text(formattedTime, style: timeStyle),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(ThemeData theme) {
    final TextStyle hintStyle =
        theme.textTheme.bodyMedium?.copyWith(color: Colors.white70) ??
            const TextStyle(color: Colors.white70);
    final double maxIconsWidth =
        (MediaQuery.of(context).size.width * 0.4).clamp(120.0, 240.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    enabled: !_sendingComment,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: 'Type a comment...',
                      hintStyle: hintStyle,
                      isDense: true,
                      border: InputBorder.none,
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendingComment ? null : _handleSendComment,
                  child: _sendingComment
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxIconsWidth,
            minHeight: 0,
          ),
          child: _buildReactionScroller(),
        ),
      ],
    );
  }

  Future<void> _pollComments({bool initial = false}) async {
    if (!mounted) return;
    if (_commentsLoading) return;
    final String? postId = widget.postId;
    if (postId == null || postId.isEmpty) return;

    setState(() {
      _commentsLoading = true;
      if (initial) {
        _commentsError = null;
      }
    });

    try {
      final page = await _repository.fetchLiveComments(
        accessToken: widget.accessToken,
        postId: postId,
        offset: _commentsOffset,
        page: _isHost ? 'live' : 'story',
      );
      if (!mounted) return;
      bool appended = false;
      final List<SocialComment> systemEvents = <SocialComment>[
        for (final SocialUser user in page.joinedUsers)
          _createLiveEventComment(user, joined: true),
        for (final SocialUser user in page.leftUsers)
          _createLiveEventComment(user, joined: false),
      ];
      final int? viewerCount = page.viewerCount;
      final bool? isLive = page.isLive;
      final String? statusWord = page.statusWord;
      setState(() {
        final List<SocialComment> incoming = <SocialComment>[
          ...page.comments,
          ...systemEvents,
        ];
        for (final SocialComment comment in incoming) {
          if (_commentIds.add(comment.id)) {
            _comments.add(comment);
            appended = true;
          }
        }
        if (appended) {
          _comments.sort((SocialComment a, SocialComment b) {
            final DateTime? at = a.createdAt;
            final DateTime? bt = b.createdAt;
            if (at != null && bt != null) {
              return at.compareTo(bt);
            }
            return a.id.compareTo(b.id);
          });
        }
        if (viewerCount != null) {
          _viewerCount = viewerCount < 0 ? 0 : viewerCount;
        }
        if (isLive != null) {
          _isLiveNow = isLive;
        }
        if (statusWord != null && statusWord.isNotEmpty) {
          _liveWord = statusWord;
        }
        final String? nextOffset = page.nextOffset;
        if (nextOffset != null && nextOffset.isNotEmpty) {
          _commentsOffset = nextOffset;
        } else if (appended && _comments.isNotEmpty) {
          _commentsOffset = _comments.last.id;
        }
        _commentsError = null;
      });
      if (appended) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollCommentsToEnd();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _commentsError ??= e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _commentsLoading = false;
        });
      } else {
        _commentsLoading = false;
      }
    }
  }

  void _scrollCommentsToEnd() {
    if (!_commentsScrollController.hasClients) return;
    final position = _commentsScrollController.position;
    _commentsScrollController.animateTo(
      position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Widget _buildReactionScroller() {
    final bool disabled = (widget.postId ?? '').isEmpty || _reacting;
    final String selected = normalizeSocialReaction(_currentReaction);
    return SizedBox(
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < _reactionOptions.length; i++)
              Padding(
                padding: EdgeInsets.only(
                    right: i == _reactionOptions.length - 1 ? 0 : 8),
                child: _buildReactionButton(
                  reaction: _reactionOptions[i],
                  isSelected: selected == _reactionOptions[i],
                  disabled: disabled,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionButton({
    required String reaction,
    required bool isSelected,
    required bool disabled,
  }) {
    final double size = isSelected ? 30 : 26;
    final Color baseColor =
        isSelected ? Colors.white : Colors.black.withOpacity(0.25);
    final Color borderColor = isSelected ? Colors.white : Colors.white24;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: disabled ? null : () => _handleReactionTap(reaction),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: baseColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Opacity(
          opacity: disabled ? 0.5 : 1,
          child: Image.asset(
            _reactionAssetPath(reaction),
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }

  Future<void> _handleSendComment() async {
    if (_sendingComment) return;
    final String? postId = widget.postId;
    if (postId == null || postId.isEmpty) return;
    final String text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _sendingComment = true;
    });

    try {
      final SocialServiceInterface service = sl<SocialServiceInterface>();
      await service.createComment(postId: postId, text: text);
      if (!mounted) return;
      _commentController.clear();
      setState(() {
        _sendingComment = false;
      });
      await _pollComments(initial: true);
      if (mounted) {
        unawaited(_refreshPostStats());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sendingComment = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send comment: $e'),
        ),
      );
    }
  }

  SocialComment _createLiveEventComment(
    SocialUser user, {
    required bool joined,
  }) {
    String? candidate(String? value) {
      if (value == null) return null;
      final String trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    final String displayName = candidate(user.displayName) ??
        candidate(user.userName) ??
        candidate(user.firstName) ??
        candidate(user.lastName) ??
        user.id;
    final String message =
        joined ? 'joined the livestream' : 'left the livestream';
    final String identifier =
        'system_${joined ? 'join' : 'leave'}_${user.id}_${DateTime.now().microsecondsSinceEpoch}';

    return SocialComment(
      id: identifier,
      text: message,
      userName: displayName,
      userAvatar: candidate(user.avatarUrl),
      createdAt: DateTime.now(),
    );
  }

  Future<void> _endLive({bool silent = false}) async {
    if (!_isHost) return;
    if (_endRequested) return;
    final String? postId = widget.postId;
    if (postId == null || postId.isEmpty) return;
    _endRequested = true;
    try {
      await _repository.endLive(
        accessToken: widget.accessToken,
        postId: postId,
      );
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to end livestream: $e'),
          ),
        );
      }
    }
  }

  Future<void> _handleReactionTap(String reaction) async {
    final String? postId = widget.postId;
    if (postId == null || postId.isEmpty) return;
    if (_reacting) return;
    final String normalized = normalizeSocialReaction(reaction);
    final String previous = normalizeSocialReaction(_currentReaction);
    final bool removing = previous.isNotEmpty && previous == normalized;

    final int currentTotal = _reactionTotal ?? 0;
    final int delta =
        removing ? (currentTotal > 0 ? -1 : 0) : (previous.isEmpty ? 1 : 0);

    setState(() {
      _currentReaction = removing ? '' : normalized;
      _reactionTotal = max(0, currentTotal + delta);
    });

    _reacting = true;
    try {
      final SocialServiceInterface service = sl<SocialServiceInterface>();
      if (removing && previous.isNotEmpty) {
        await service.reactToPost(
          postId: postId,
          reaction: previous,
          action: 'dislike',
        );
      } else {
        await service.reactToPost(
          postId: postId,
          reaction: normalized,
          action: 'reaction',
        );
      }
      if (mounted) {
        unawaited(_refreshPostStats());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentReaction = previous;
        _reactionTotal = currentTotal;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to react: $e')),
      );
    } finally {
      _reacting = false;
    }
  }

  Future<void> _handleClose() async {
    _commentsTimer?.cancel();
    _commentsTimer = null;
    await _disposeEngine();
    if (_isHost) {
      await _endLive();
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _initAgora() async {
    final String? token = _token;
    if (token == null || token.isEmpty) {
      throw Exception('Missing Agora token.');
    }

    final RtcEngine engine = createAgoraRtcEngine();
    _engine = engine;

    await engine.initialize(
      const RtcEngineContext(appId: AppConstants.socialAgoraAppId),
    );

    await engine.setChannelProfile(
      ChannelProfileType.channelProfileLiveBroadcasting,
    );

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          if (!mounted) return;
          setState(() => _joined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          if (!mounted || _isHost) return;
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (
          RtcConnection connection,
          int remoteUid,
          UserOfflineReasonType reason,
        ) {
          if (!mounted || _isHost) return;
          if (_remoteUid == remoteUid) {
            setState(() => _remoteUid = null);
          }
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          if (!mounted) return;
          setState(() {
            _joined = false;
            if (!_isHost) {
              _remoteUid = null;
            }
          });
        },
        onError: (ErrorCodeType code, String message) {
          debugPrint('Agora error: $code - $message');
        },
      ),
    );

    await engine.enableVideo();
    if (_isHost) {
      await engine.enableWebSdkInteroperability(true);
      await engine.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 720, height: 1280),
          frameRate: 30,
          bitrate: 1200,
          orientationMode: OrientationMode.orientationModeFixedPortrait,
        ),
      );
      await engine.setClientRole(
        role: ClientRoleType.clientRoleBroadcaster,
      );
      await engine.startPreview();
      await engine.joinChannel(
        token: token,
        channelId: widget.streamName,
        uid: widget.broadcasterUid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
        ),
      );
    } else {
      final int uid = _viewerUid ?? _generateViewerUid();
      _viewerUid = uid;
      await engine.setClientRole(
        role: ClientRoleType.clientRoleAudience,
      );
      await engine.joinChannel(
        token: token,
        channelId: widget.streamName,
        uid: uid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleAudience,
          publishCameraTrack: false,
          publishMicrophoneTrack: false,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
    }
  }

  Future<void> _retry() async {
    await _disposeEngine();
    setState(() {
      _token = _isHost ? widget.initialToken : null;
      if (!_isHost) {
        _viewerUid = widget.initialViewerUid;
      }
      _joined = false;
    });
    await _prepareStream();
  }

  Future<void> _disposeEngine() async {
    final RtcEngine? engine = _engine;
    _engine = null;
    if (!_isHost) {
      _remoteUid = null;
    }
    if (engine != null) {
      await engine.leaveChannel();
      await engine.release();
    }
  }

  @override
  void dispose() {
    _commentsTimer?.cancel();
    _statsTimer?.cancel();
    _commentController.dispose();
    _commentsScrollController.dispose();
    _disposeEngine();
    if (_isHost) {
      _endLive(silent: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return _buildError();
    }
    if (!_joined) {
      return _buildLoading();
    }
    final ThemeData theme = Theme.of(context);
    return Stack(
      children: [
        Positioned.fill(child: _buildVideo()),
        _buildTopOverlay(theme),
        _buildSideActions(theme),
        _buildCommentsPanel(),
      ],
    );
  }

  Widget _buildTopOverlay(ThemeData theme) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final String hostName = _hostName ?? 'Your livestream';
    final int viewerCount = _viewerCount < 0 ? 0 : _viewerCount;
    final String liveLabel = () {
      if (_liveWord != null && _liveWord!.isNotEmpty) {
        return _liveWord!;
      }
      if (_isLiveNow == false) {
        return 'Ended';
      }
      return 'LIVE';
    }();
    final Color statusColor =
        _isLiveNow == false ? Colors.grey.shade600 : Colors.redAccent;
    final TextStyle titleStyle = theme.textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700);

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.75),
              Colors.black.withOpacity(0.3),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white24,
                  backgroundImage:
                      (_hostAvatar != null && _hostAvatar!.isNotEmpty)
                          ? NetworkImage(_hostAvatar!)
                          : null,
                  child: (_hostAvatar == null || _hostAvatar!.isEmpty)
                      ? const Icon(Icons.person, color: Colors.white, size: 22)
                      : null,
                ),
                const SizedBox(width: 12),
                Flexible(
                  fit: FlexFit.tight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hostName,
                        style: titleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildChip(
                            icon: Icons.circle,
                            iconSize: 8,
                            label: liveLabel,
                            background: statusColor,
                          ),
                          _buildChip(
                            icon: Icons.visibility,
                            label: '$viewerCount watching',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: _buildCircleIconButton(
                    icon: Icons.close,
                    onTap: _handleClose,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAnnouncementBanner(),
            if (!_isHost) ...[
              const SizedBox(height: 12),
              _buildFollowButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    Color background = const Color(0xAA1F1F1F),
    double iconSize = 14,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.pinkAccent.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'Sending gifts - follow to swap sizes for free!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFollowButton() {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: Colors.pinkAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      ),
      onPressed: () {},
      child: const Text(
        '+ Follow',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildCircleIconButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildSideActions(ThemeData theme) {
    final TextStyle labelStyle = theme.textTheme.bodySmall
            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w500) ??
        const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500);
    final int likeCount = (_reactionTotal ?? 0) < 0 ? 0 : (_reactionTotal ?? 0);
    final int commentCount = (_commentTotal ?? _comments.length) < 0
        ? 0
        : (_commentTotal ?? _comments.length);
    final int shareCount = (_shareTotal ?? 0) < 0 ? 0 : (_shareTotal ?? 0);

    return Positioned(
      right: 16,
      bottom: 150,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSideActionButton(
            icon: Icons.favorite_border,
            label: likeCount.toString(),
            style: labelStyle,
          ),
          const SizedBox(height: 18),
          _buildSideActionButton(
            icon: Icons.chat_bubble_outline,
            label: commentCount.toString(),
            style: labelStyle,
            onTap: () {
              setState(() {
                _showComments = !_showComments;
              });
            },
          ),
          // const SizedBox(height: 18),
          // _buildSideActionButton(
          //   icon: Icons.card_giftcard_outlined,
          //   label: 'Gifts',
          // ),
          const SizedBox(height: 18),
          _buildSideActionButton(
            icon: Icons.share_outlined,
            label: shareCount.toString(),
            style: labelStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildSideActionButton({
    required IconData icon,
    required String label,
    TextStyle? style,
    VoidCallback? onTap,
  }) {
    final TextStyle textStyle = style ??
        const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: textStyle),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Preparing livestream...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.report_problem, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred.',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!_isInitializing)
              ElevatedButton(
                onPressed: _retry,
                child: const Text('Retry'),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _handleClose,
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideo() {
    final RtcEngine? engine = _engine;
    if (engine == null) {
      return _buildLoading();
    }
    if (_isHost) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    }
    final int? remoteUid = _remoteUid;
    if (remoteUid == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(color: Colors.white),
            ),
            SizedBox(height: 12),
            Text(
              'Connecting to livestream...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: engine,
        connection: RtcConnection(channelId: widget.streamName),
        canvas: VideoCanvas(uid: remoteUid),
      ),
    );
  }

  String _reactionAssetPath(String reaction) {
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

  int _generateViewerUid() {
    final int millis = DateTime.now().millisecondsSinceEpoch;
    return 100000 + (millis % 900000000);
  }
}
