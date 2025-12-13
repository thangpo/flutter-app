import 'dart:async';
import 'dart:math';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/controllers/product_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/screens/product_details_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_live_repository.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/live_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_post_full_with_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/share_post_screen.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
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
  final String? normalizedType = post.postType?.toLowerCase();
  if (normalizedType == 'live') {
    final bool ended = post.liveEnded;
    final String? replayUrl = post.videoUrl ?? post.fileUrl;
    if (ended && _isVideo(replayUrl)) {
      return _LiveReplayTile(post: post, compact: compact);
    }
    return _LivePostPlayer(post: post, compact: compact);
  }
  final List<String> images = SocialPostFullViewComposer.normalizeImages(post);
  final bool hasMulti = images.length >= 2;
  final bool hasSingle = images.length == 1;
  final String? fileUrl = post.fileUrl;

// 0) Video
  if (_isVideo(fileUrl)) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => SocialPostFullWithScreen.open(
        context,
        post: post,
        focus: SocialPostFullItemType.video,
      ),
      child: _VideoPlayerTile(
        url: fileUrl!,
        post: post,
        maxHeightFactor: compact ? 0.5 : 0.6,
      ),
    );
  }

  // 1) Product
  if (post.hasProduct == true && (post.productImages?.isNotEmpty ?? false)) {
    return _ProductPostTile(post: post, compact: compact);
  }

  // 1.5) Images + Audio overlay
  if (images.isNotEmpty && _isAudio(fileUrl)) {
    return _ImagesWithAutoAudio(
      images: images,
      audioUrl: fileUrl!,
      post: post,
    );
  }

  // 2) Multi image grid
  if (hasMulti) {
    Widget _imageTile(
      String url,
      int imageIndex, {
      int? extraCount,
    }) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => SocialPostFullWithScreen.open(
          context,
          post: post,
          focus: SocialPostFullItemType.image,
          imageIndex: imageIndex,
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(url, fit: BoxFit.cover),
              if (extraCount != null && extraCount > 0)
                Container(
                  alignment: Alignment.center,
                  color: Colors.black45,
                  child: Text(
                    '+$extraCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (images.length == 3) {
      return Row(
        children: [
          Expanded(child: _imageTile(images[0], 0)),
          const SizedBox(width: 4),
          Expanded(child: _imageTile(images[1], 1, extraCount: 1)),
        ],
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _imageTile(images[0], 0)),
            const SizedBox(width: 4),
            Expanded(child: _imageTile(images[1], 1)),
          ],
        ),
        if (images.length > 2) const SizedBox(height: 4),
        if (images.length > 2)
          Row(
            children: [
              Expanded(child: _imageTile(images[2], 2)),
              const SizedBox(width: 4),
              Expanded(
                child: images.length > 3
                    ? _imageTile(
                        images[3],
                        3,
                        extraCount: images.length - 4,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
      ],
    );
  }

  // 3) Single image
  if (hasSingle) {
    final String src = images.first;
    final bool hasBackgroundText =
        SocialPostFullViewComposer.allowsBackground(post);
    final Widget imageWidget = hasBackgroundText
        ? _HalfSquareCoverImage(src)
        : _AutoRatioNetworkImage(
            src,
            maxHeightFactor: compact ? 0.5 : 0.8,
            maxHeightToWidthRatio: 1.5,
          );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => SocialPostFullWithScreen.open(
        context,
        post: post,
        focus: SocialPostFullItemType.image,
        imageIndex: 0,
      ),
      child: imageWidget,
    );
  }

  // 4) File attachments (audio/pdf/others)
  if (fileUrl != null && fileUrl.isNotEmpty) {
    if (_isAudio(fileUrl) && images.isNotEmpty) {
      return _ImagesWithAutoAudio(
        images: images,
        audioUrl: fileUrl,
        post: post,
      );
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

class _LivePostPlayer extends StatefulWidget {
  final SocialPost post;
  final bool compact;

  const _LivePostPlayer({
    required this.post,
    this.compact = false,
  });

  @override
  State<_LivePostPlayer> createState() => _LivePostPlayerState();
}

class _LivePostPlayerState extends State<_LivePostPlayer>
    with AutomaticKeepAliveClientMixin {
  static final Random _random = Random();
  static _LivePostPlayerState? _activePlayer;
  static int _nextInstanceId = 0;
  late final int _instanceId;
  static Future<void> _reserveEngineFor(_LivePostPlayerState requester) async {
    final _LivePostPlayerState? previous = _activePlayer;
    if (previous == requester) return;
    if (previous != null) {
      previous._shouldPlay = false;
      previous._autoPlayEnabled = false;
      await previous._stopPlayback();
    }
    _activePlayer = requester;
  }

  final SocialLiveRepository _liveRepository = const SocialLiveRepository(
    apiBaseUrl: AppConstants.socialBaseUrl,
    serverKey: AppConstants.socialServerKey,
  );

  late final Key _visibilityKey;

  RtcEngine? _engine;
  int? _remoteUid;
  bool _isJoining = false;
  bool _shouldPlay = false;
  bool _autoPlayEnabled = true;
  String? _errorMessage;
  String? _viewerToken;
  int? _viewerUid;
  DateTime? _tokenExpiryUtc;

  @override
  void initState() {
    super.initState();
    _instanceId = _nextInstanceId++;
    _visibilityKey = ValueKey<String>('live-${widget.post.id}#$_instanceId');
  }

  @override
  void didUpdateWidget(covariant _LivePostPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.id != oldWidget.post.id) {
      _errorMessage = null;
      _viewerToken = null;
      _viewerUid = null;
      _tokenExpiryUtc = null;
      _shouldPlay = false;
      unawaited(_stopPlayback());
    } else if (widget.post.liveEnded && !oldWidget.post.liveEnded) {
      _errorMessage = null;
      _shouldPlay = false;
      unawaited(_stopPlayback());
    }
  }

  @override
  bool get wantKeepAlive => true;

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;
    if (widget.post.liveEnded) {
      if (_engine != null) {
        unawaited(_stopPlayback());
      }
      return;
    }
    final double threshold = widget.compact ? 0.75 : 0.6;
    final bool shouldPlayNow =
        info.visibleFraction >= threshold && info.visibleBounds.height > 0;
    if (!_autoPlayEnabled && shouldPlayNow) {
      return;
    }
    if (shouldPlayNow == _shouldPlay) return;
    _shouldPlay = shouldPlayNow;
    if (shouldPlayNow) {
      _startPlayback();
    } else {
      // Reset autoplay once card is no longer prominently visible
      _autoPlayEnabled = true;
      unawaited(_stopPlayback());
    }
  }

  Future<void> _startPlayback() async {
    if (!mounted || _isJoining || _engine != null) return;
    final String? streamName = widget.post.liveStreamName;
    if (streamName == null || streamName.isEmpty) {
      setState(() {
        _errorMessage = getTranslated('live_stream_unavailable', context) ??
            'Không thể phát livestream.';
      });
      return;
    }
    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });
    try {
      await _reserveEngineFor(this);
      await _ensureViewerToken(streamName);
      if (!mounted) return;
      await _initializeEngine(streamName);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _errorDescription(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _ensureViewerToken(String streamName) async {
    final DateTime now = DateTime.now().toUtc();
    if (_viewerToken != null) {
      if (_tokenExpiryUtc == null || now.isBefore(_tokenExpiryUtc!)) {
        return;
      }
    }

    SocialController? controller;
    try {
      controller = context.read<SocialController>();
    } on ProviderNotFoundException {
      controller = null;
    }
    final int uid = _viewerUid ?? _generateViewerUid();
    final String? accessToken = controller?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      final String? fallback = widget.post.liveAgoraToken;
      if (fallback == null || fallback.isEmpty) {
        throw Exception(
          getTranslated('live_token_missing', context) ??
              'Không thể lấy token livestream.',
        );
      }
      _viewerToken = fallback;
      _viewerUid = uid;
      _tokenExpiryUtc = null;
      return;
    }

    final Map<String, dynamic>? payload =
        await _liveRepository.generateAgoraToken(
      accessToken: accessToken,
      channelName: streamName,
      uid: uid,
      role: 'audience',
    );
    if (!mounted) return;

    final String token =
        (payload?['token_agora'] ?? payload?['token'])?.toString() ?? '';
    if (token.isEmpty) {
      throw Exception(
        getTranslated('live_token_missing', context) ??
            'Không thể lấy token livestream.',
      );
    }
    final int resolvedUid =
        int.tryParse(payload?['uid']?.toString() ?? '') ?? uid;
    final DateTime? expiry = _parseEpochSeconds(
      payload?['expire_timestamp'] ?? payload?['expire_ts'],
    );

    _viewerToken = token;
    _viewerUid = resolvedUid;
    _tokenExpiryUtc = expiry;
  }

  Future<void> _initializeEngine(String streamName) async {
    final String? token = _viewerToken;
    if (token == null || token.isEmpty) {
      throw Exception(
        getTranslated('live_token_missing', context) ??
            'Không thể lấy token livestream.',
      );
    }

    final int uid = _viewerUid ?? _generateViewerUid();
    _viewerUid = uid;

    final RtcEngine engine = createAgoraRtcEngine();
    await engine.initialize(
      const RtcEngineContext(appId: AppConstants.socialAgoraAppId),
    );
    await engine.setChannelProfile(
      ChannelProfileType.channelProfileLiveBroadcasting,
    );
    await engine.setClientRole(role: ClientRoleType.clientRoleAudience);

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          if (!mounted) return;
          setState(() {});
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          if (!mounted) return;
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (
          RtcConnection connection,
          int remoteUid,
          UserOfflineReasonType reason,
        ) {
          if (!mounted) return;
          if (_remoteUid == remoteUid) {
            setState(() => _remoteUid = null);
          }
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          if (!mounted) return;
          setState(() {});
        },
        onError: (ErrorCodeType code, String message) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'Agora error ($code): $message';
          });
        },
      ),
    );

    await engine.enableVideo();
    await engine.muteLocalAudioStream(true);

    await engine.joinChannel(
      token: token,
      channelId: streamName,
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

    if (!mounted) {
      await engine.leaveChannel();
      await engine.release();
      return;
    }

    setState(() {
      _engine = engine;
    });
    _activePlayer = this;
  }

  Future<void> _stopPlayback() async {
    final RtcEngine? engine = _engine;
    if (mounted) {
      setState(() {
        _engine = null;
        _remoteUid = null;
      });
    } else {
      _engine = null;
      _remoteUid = null;
    }
    if (engine != null) {
      try {
        await engine.leaveChannel();
      } catch (_) {}
      try {
        await engine.release();
      } catch (_) {}
    }
    if (_activePlayer == this) {
      _activePlayer = null;
    }
  }

  void _retryPlayback() {
    if (!mounted) return;
    setState(() {
      _errorMessage = null;
      _autoPlayEnabled = true;
    });
    _startPlayback();
  }

  @override
  void dispose() {
    if (_activePlayer == this) {
      _activePlayer = null;
    }
    unawaited(_stopPlayback());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool ended = widget.post.liveEnded;
    final double aspectRatio = widget.compact ? 3 / 4 : 9 / 16;
    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: _onVisibilityChanged,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildContent(context, ended),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool ended) {
    final bool hasRemoteVideo = _engine != null && _remoteUid != null && !ended;
    final Widget background = hasRemoteVideo
        ? AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: _engine!,
              canvas: VideoCanvas(uid: _remoteUid),
              connection: RtcConnection(
                channelId: widget.post.liveStreamName ?? '',
              ),
            ),
          )
        : _buildThumbnail();

    return Stack(
      fit: StackFit.expand,
      children: [
        background,
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (ended || _isJoining || _errorMessage != null)
                  ? null
                  : () => _openFullScreen(context),
            ),
          ),
        ),
        if (!hasRemoteVideo)
          Container(
            color: Colors.black.withOpacity(0.35),
          ),
        _buildLiveBadge(context, ended: ended),
        _buildBottomInfo(context),
        if (_isJoining && !ended)
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        if (_errorMessage != null && !ended) _buildErrorOverlay(context),
        if (ended) _buildEndedOverlay(context),
      ],
    );
  }

  Widget _buildThumbnail() {
    final String? thumb = widget.post.thumbnailUrl ?? widget.post.imageUrl;
    if (thumb != null && thumb.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: thumb,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            Container(color: Colors.black.withOpacity(0.15)),
        errorWidget: (context, url, error) =>
            Container(color: Colors.black.withOpacity(0.3)),
      );
    }
    return Container(color: Colors.black.withOpacity(0.15));
  }

  Widget _buildLiveBadge(BuildContext context, {required bool ended}) {
    final Color bgColor = ended ? Colors.grey : Colors.redAccent;
    final String text = ended
        ? (getTranslated('live_has_ended', context) ?? 'Live ended')
        : 'LIVE';
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fiber_manual_record,
              color: Colors.white,
              size: ended ? 12 : 10,
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInfo(BuildContext context) {
    final String? host = widget.post.userName;
    if (host == null || host.isEmpty) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          host,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(BuildContext context) {
    final String message = _errorMessage ??
        (getTranslated('live_stream_unavailable', context) ??
            'Unable to play livestream.');
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.55),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sync_problem, color: Colors.white70, size: 32),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _retryPlayback,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
              ),
              child: Text(getTranslated('retry', context) ?? 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndedOverlay(BuildContext context) {
    final String message =
        getTranslated('live_has_ended', context) ?? 'Livestream has ended';
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.55),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _openFullScreen(BuildContext context) async {
    if (!mounted) return;
    final String? streamName = widget.post.liveStreamName;
    if (streamName == null || streamName.isEmpty) {
      _showSnack(
        context,
        getTranslated('live_stream_unavailable', context) ??
            'Livestream unavailable right now.',
      );
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
    final String? preparedToken =
        (_viewerToken != null && _viewerToken!.isNotEmpty)
            ? _viewerToken
            : widget.post.liveAgoraToken;

    if (!hasAccessToken && (preparedToken == null || preparedToken.isEmpty)) {
      _showSnack(
        context,
        getTranslated('live_token_missing', context) ??
            'Unable to join livestream right now.',
      );
      return;
    }

    await _stopPlayback();
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveScreen(
          streamName: streamName,
          accessToken: accessToken ?? '',
          broadcasterUid: 0,
          initialToken: preparedToken,
          initialViewerUid: _viewerUid,
          postId: widget.post.id,
          isHost: false,
          hostDisplayName: widget.post.userName,
          hostAvatarUrl: widget.post.userAvatar,
        ),
      ),
    );

    if (!context.mounted) return;
    if (_shouldPlay) {
      _startPlayback();
    }
  }

  void _showSnack(BuildContext context, String message) {
    final ScaffoldMessengerState? messenger =
        ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } else {
      showCustomSnackBar(message, context, isError: true);
    }
  }

  int _generateViewerUid() {
    return 100000 + _random.nextInt(900000000);
  }

  DateTime? _parseEpochSeconds(dynamic value) {
    final int? seconds = _coerceInt(value);
    if (seconds == null || seconds <= 0) return null;
    if (seconds > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(seconds, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  }

  int? _coerceInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final String trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return int.tryParse(trimmed);
    }
    return null;
  }

  String _errorDescription(Object error) {
    final String raw = error.toString();
    const String prefix = 'Exception: ';
    if (raw.startsWith(prefix)) {
      return raw.substring(prefix.length);
    }
    return raw;
  }
}

class _AutoRatioNetworkImage extends StatefulWidget {
  final String url;
  final double maxHeightFactor;
  final double? maxHeightToWidthRatio;
  const _AutoRatioNetworkImage(
    this.url, {
    this.maxHeightFactor = 0.8,
    this.maxHeightToWidthRatio,
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
        final double screenMaxHeight =
            MediaQuery.of(ctx).size.height * widget.maxHeightFactor;
        final double resolvedWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(ctx).size.width;
        final double naturalHeight = resolvedWidth / ratio;
        final double ratioMaxHeight = widget.maxHeightToWidthRatio != null
            ? resolvedWidth * widget.maxHeightToWidthRatio!
            : double.infinity;
        final double allowedHeight =
            min(naturalHeight, min(screenMaxHeight, ratioMaxHeight));
        final bool shouldClip = allowedHeight < naturalHeight;
        final Widget image = CachedNetworkImage(
          imageUrl: widget.url,
          fit: BoxFit.cover,
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

class _HalfSquareCoverImage extends StatelessWidget {
  final String url;
  const _HalfSquareCoverImage(this.url);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final double fallbackWidth = MediaQuery.of(ctx).size.width;
        final double resolvedWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : fallbackWidth;
        final double height = resolvedWidth * (2 / 3);
        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: resolvedWidth,
            height: height,
            child: CachedNetworkImage(
              imageUrl: url,
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
  final SocialPost post;
  const _ImagesWithAutoAudio({
    required this.images,
    required this.audioUrl,
    required this.post,
  });

  @override
  State<_ImagesWithAutoAudio> createState() => _ImagesWithAutoAudioState();
}

class _ImagesWithAutoAudioState extends State<_ImagesWithAutoAudio>
    with AutomaticKeepAliveClientMixin {
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
    super.build(context);
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
              itemBuilder: (_, i) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => SocialPostFullWithScreen.open(
                  context,
                  post: widget.post,
                  focus: SocialPostFullItemType.image,
                  imageIndex: i,
                ),
                child: Image.network(widget.images[i], fit: BoxFit.cover),
              ),
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

  @override
  bool get wantKeepAlive => true;
}

class _LiveReplayTile extends StatelessWidget {
  final SocialPost post;
  final bool compact;
  const _LiveReplayTile({
    required this.post,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final String? resolvedUrl = post.videoUrl ?? post.fileUrl;
    assert(resolvedUrl != null && resolvedUrl != '');
    final Widget video = _VideoPlayerTile(
      url: resolvedUrl!,
      post: post,
      maxHeightFactor: compact ? 0.5 : 0.6,
    );
    final String badge = getTranslated('live_replay', context) ??
        getTranslated('live_has_ended', context) ??
        'Live replay';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => SocialPostFullWithScreen.open(
        context,
        post: post,
        focus: SocialPostFullItemType.video,
      ),
      child: Stack(
        children: [
          video,
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPlayerTile extends StatefulWidget {
  final String url;
  final double maxHeightFactor;
  final SocialPost post;
  const _VideoPlayerTile({
    required this.url,
    required this.post,
    this.maxHeightFactor = 0.6,
  });

  @override
  State<_VideoPlayerTile> createState() => _VideoPlayerTileState();
}

/// Điều phối phát video: chỉ cho 1 video trong feed phát tại một thời điểm
class _InlineVideoCoordinator {
  _InlineVideoCoordinator._();
  static final _InlineVideoCoordinator instance = _InlineVideoCoordinator._();

  VideoPlayerController? _current;
  bool _globalMuted = true;

  bool get globalMuted => _globalMuted;

  void setGlobalMuted(bool muted) {
    _globalMuted = muted;
    if (_current != null) {
      _current!.setVolume(_globalMuted ? 0 : 1);
    }
  }

  void requestPlay(VideoPlayerController controller) {
    if (_current != controller) {
      _current?.pause();
      _current = controller;
    }
    controller.setVolume(_globalMuted ? 0 : 1);
    if (!controller.value.isPlaying) {
      controller.play();
    }
  }

  void pauseIfCurrent(VideoPlayerController controller) {
    if (_current == controller && controller.value.isPlaying) {
      controller.pause();
    }
    if (_current == controller) {
      _current = null;
    }
  }
}

class _OverlayPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OverlayPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
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

class _VideoPlayerTileState extends State<_VideoPlayerTile>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  bool _visible = false;
  bool _initialized = false;
  late bool _muted;
  bool _ended = false;
  final _InlineVideoCoordinator _coordinator =
      _InlineVideoCoordinator.instance;

  @override
  void initState() {
    super.initState();
    _muted = _coordinator.globalMuted;
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        _initialized = true;
        _controller?.setVolume(_muted ? 0 : 1);
        setState(() {});
        if (_visible && _controller != null) {
          _coordinator.requestPlay(_controller!);
        }
      });
    _controller?.addListener(_handleControllerTick);
  }

  @override
  void dispose() {
    if (_controller != null) {
      _coordinator.pauseIfCurrent(_controller!);
    }
    _controller?.removeListener(_handleControllerTick);
    _controller?.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final nowVisible = info.visibleFraction > 0.6;
    if (nowVisible == _visible) return;
    _visible = nowVisible;
    if (!_initialized || _controller == null || _ended) return;

    if (_visible) {
      _coordinator.requestPlay(_controller!);
    } else {
      _coordinator.pauseIfCurrent(_controller!);
    }
  }

  void _toggleMute() {
    final c = _controller;
    if (c == null || !_initialized) return;
    _muted = !_muted;
    c.setVolume(_muted ? 0 : 1);
    _coordinator.setGlobalMuted(_muted);
    setState(() {});
  }

  void _handleControllerTick() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final v = c.value;
    final bool endedNow = v.duration.inMilliseconds > 0 &&
        v.position.inMilliseconds >= v.duration.inMilliseconds - 250;
    if (endedNow != _ended) {
      setState(() {
        _ended = endedNow;
      });
      if (endedNow) {
        _coordinator.pauseIfCurrent(c);
      }
    } else if (_ended && v.position.inMilliseconds < v.duration.inMilliseconds - 500) {
      // Reset ended flag when user seeks back
      setState(() {
        _ended = false;
      });
    }
  }

  Future<void> _replay() async {
    final c = _controller;
    if (c == null) return;
    await c.seekTo(Duration.zero);
    setState(() {
      _ended = false;
    });
    _coordinator.requestPlay(c);
  }

  Future<void> _share() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SharePostScreen(post: widget.post),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!(_controller?.value.isInitialized ?? false)) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final double rawRatio = _controller!.value.aspectRatio;
    final double ratio = rawRatio == 0 ? (16 / 9) : rawRatio;
    return VisibilityDetector(
      key: ValueKey('video_${widget.url.hashCode}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double screenLimit =
              MediaQuery.of(context).size.height * widget.maxHeightFactor;
          final double width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;
          final double naturalHeight = width / ratio;
          final double portraitLimit = width * 1.5;
          final double allowedHeight =
              min(naturalHeight, min(screenLimit, portraitLimit));

          return SizedBox(
            width: width,
            height: allowedHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRect(
                  child: SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: width,
                        height: naturalHeight,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  ),
                ),
                if (_ended)
                  Positioned.fill(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.28),
                          ),
                        ),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _OverlayPillButton(
                                  icon: Icons.replay,
                                  label: 'Xem lại',
                                  onTap: _replay,
                                ),
                                const SizedBox(width: 10),
                                _OverlayPillButton(
                                  icon: Icons.share_outlined,
                                  label: 'Chia sẻ',
                                  onTap: _share,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: IconButton(
                    icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
                    iconSize: 16,
                    color: Colors.white,
                    onPressed: _toggleMute,
                    style: IconButton.styleFrom(
                      fixedSize: const Size(28, 28),                 // kích thước nút (và vòng tròn)
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                      backgroundColor: Colors.black.withOpacity(0.36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap, // bỏ mở rộng vùng chạm mặc định
                      minimumSize: Size.zero,                           // tránh min 48x48
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
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
                  productId: productId,
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
