import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_live_repository.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class LiveScreen extends StatefulWidget {
  final String streamName;
  final String accessToken;
  final int broadcasterUid;
  final String? initialToken;
  final String? postId;

  const LiveScreen({
    super.key,
    required this.streamName,
    required this.accessToken,
    required this.broadcasterUid,
    this.initialToken,
    this.postId,
  });

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final SocialLiveRepository _repository = const SocialLiveRepository(
    apiBaseUrl: AppConstants.socialBaseUrl,
    serverKey: AppConstants.socialServerKey,
  );

  RtcEngine? _engine;
  String? _token;
  bool _isInitializing = false;
  bool _joined = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _token = widget.initialToken;
    _prepareStream();
  }

  Future<void> _prepareStream() async {
    if (_isInitializing) return;
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      String? token = _token;
      if (token == null || token.isEmpty) {
        final Map<String, dynamic>? payload =
            await _repository.generateAgoraToken(
          accessToken: widget.accessToken,
          channelName: widget.streamName,
          uid: widget.broadcasterUid,
        );
        token = payload?['token_agora']?.toString();
      }

      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Unable to fetch livestream token.';
        });
        return;
      }

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

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          if (!mounted) return;
          setState(() => _joined = true);
        },
        onError: (ErrorCodeType code, String message) {
          debugPrint('Agora error: $code - $message');
        },
      ),
    );

    await engine.enableVideo();
    await engine.setClientRole(
      role: ClientRoleType.clientRoleBroadcaster,
    );
    await engine.startPreview();
    await engine.joinChannel(
      token: token,
      channelId: widget.streamName,
      uid: widget.broadcasterUid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
      ),
    );
  }

  Future<void> _retry() async {
    await _disposeEngine();
    setState(() {
      _token = widget.initialToken;
      _joined = false;
    });
    await _prepareStream();
  }

  Future<void> _disposeEngine() async {
    final RtcEngine? engine = _engine;
    _engine = null;
    if (engine != null) {
      await engine.leaveChannel();
      await engine.release();
    }
  }

  @override
  void dispose() {
    _disposeEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _buildBody()),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () async {
                await _disposeEngine();
                if (mounted) Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return _buildError();
    }
    if (!_joined) {
      return _buildLoading();
    }
    return _buildVideo();
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
              onPressed: () async {
                await _disposeEngine();
                if (mounted) Navigator.pop(context);
              },
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

    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: engine,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }
}
