import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/call_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class CallScreen extends StatefulWidget {
  final bool isCaller;
  final int callId;
  final String mediaType; // 'audio' | 'video'
  final String? peerName;
  final String? peerAvatar;

  const CallScreen({
    super.key,
    required this.isCaller,
    required this.callId,
    required this.mediaType,
    this.peerName,
    this.peerAvatar,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  RtcEngine? _engine;
  AgoraCallSession? _session;
  int? _remoteUid;
  bool _joined = false;
  bool _micOn = true;
  bool _camOn = true;
  String? _error;

  bool get _isVideo => widget.mediaType == 'video';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final call = context.read<CallController>();
    try {
      final AgoraCallSession session = await call.prepareAgoraSession();
      final RtcEngine engine = createAgoraRtcEngine();
      await engine.initialize(
        const RtcEngineContext(appId: AppConstants.socialAgoraAppId),
      );
      await engine.setChannelProfile(
        ChannelProfileType.channelProfileCommunication,
      );
      await engine.setClientRole(
        role: ClientRoleType.clientRoleBroadcaster,
      );
      if (_isVideo) {
        await engine.enableVideo();
        await engine.startPreview();
      } else {
        await engine.disableVideo();
      }

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (!mounted) return;
            setState(() {
              _joined = true;
            });
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
            setState(() {
              _joined = false;
              _remoteUid = null;
            });
          },
          onError: (ErrorCodeType code, String message) {
            debugPrint('Agora call error: $code - $message');
            if (!mounted) return;
            setState(() => _error = 'Agora error: $message');
          },
        ),
      );

      await engine.joinChannel(
        token: session.token,
        channelId: session.channelName,
        uid: session.uid,
        options: ChannelMediaOptions(
          publishCameraTrack: _isVideo,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: _isVideo,
        ),
      );

      if (!mounted) {
        await engine.leaveChannel();
        engine.release();
        return;
      }

      setState(() {
        _engine = engine;
        _session = session;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Không thể khởi tạo cuộc gọi: $e');
    }
  }

  @override
  void dispose() {
    _disposeEngine();
    super.dispose();
  }

  void _disposeEngine() {
    final RtcEngine? engine = _engine;
    _engine = null;
    if (engine != null) {
      engine.stopPreview();
      engine.leaveChannel();
      engine.release();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.peerName ?? 'Cuộc gọi';
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: _isVideo
            ? [
                IconButton(
                  icon: const Icon(Icons.cameraswitch),
                  onPressed: _switchCamera,
                  tooltip: 'Đổi camera',
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: Consumer<CallController>(
          builder: (context, call, _) {
            if (call.callStatus == 'ended' || call.callStatus == 'declined') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              });
            }
            return Stack(
              children: [
                Positioned.fill(
                  child: _isVideo ? _buildVideoContent() : _buildAudioContent(),
                ),
                if (_isVideo)
                  Positioned(
                    right: 16,
                    top: 16,
                    width: 120,
                    height: 180,
                    child: _buildLocalPreview(),
                  ),
                if (_error != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    top: 16,
                    child: _buildErrorBanner(_error!),
                  ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: _buildControls(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    final RtcEngine? engine = _engine;
    final AgoraCallSession? session = _session;
    if (engine == null || session == null) {
      return _buildStatus(
        message: 'Đang chuẩn bị camera...',
      );
    }
    final int? remoteUid = _remoteUid;
    if (remoteUid == null) {
      return _buildStatus(
        message: 'Đang chờ đối phương...',
      );
    }
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: engine,
        connection: RtcConnection(channelId: session.channelName),
        canvas: VideoCanvas(uid: remoteUid),
      ),
    );
  }

  Widget _buildLocalPreview() {
    final RtcEngine? engine = _engine;
    if (engine == null || !_isVideo || !_camOn) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.videocam_off, color: Colors.white70),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      ),
    );
  }

  Widget _buildAudioContent() {
    final String name = widget.peerName ?? 'Cuộc gọi';
    final String subtitle = _error ??
        (_joined ? 'Đang trò chuyện' : 'Đang kết nối với đối phương...');
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 56,
            backgroundImage:
                (widget.peerAvatar != null && widget.peerAvatar!.isNotEmpty)
                    ? NetworkImage(widget.peerAvatar!)
                    : null,
            child: (widget.peerAvatar == null || widget.peerAvatar!.isEmpty)
                ? const Icon(Icons.person, size: 56)
                : null,
          ),
          const SizedBox(height: 16),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatus({required String message}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Material(
      color: Colors.red.shade600.withOpacity(0.9),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleBtn(
          icon: _micOn ? Icons.mic : Icons.mic_off,
          onTap: _toggleMic,
        ),
        const SizedBox(width: 16),
        if (_isVideo)
          _circleBtn(
            icon: _camOn ? Icons.videocam : Icons.videocam_off,
            onTap: _toggleCam,
          ),
        if (_isVideo) const SizedBox(width: 16),
        _circleBtn(
          icon: Icons.call_end,
          bg: Colors.red,
          onTap: _hangup,
        ),
      ],
    );
  }

  Widget _circleBtn({
    required IconData icon,
    Color bg = const Color(0x33FFFFFF),
    required VoidCallback onTap,
  }) {
    return Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Future<void> _toggleMic() async {
    final RtcEngine? engine = _engine;
    if (engine == null) return;
    final bool next = !_micOn;
    await engine.muteLocalAudioStream(!next);
    if (!mounted) return;
    setState(() => _micOn = next);
  }

  Future<void> _toggleCam() async {
    if (!_isVideo) return;
    final RtcEngine? engine = _engine;
    if (engine == null) return;
    final bool next = !_camOn;
    await engine.muteLocalVideoStream(!next);
    await engine.enableLocalVideo(next);
    if (!mounted) return;
    setState(() => _camOn = next);
  }

  Future<void> _switchCamera() async {
    if (!_isVideo) return;
    final RtcEngine? engine = _engine;
    if (engine == null) return;
    await engine.switchCamera();
  }

  Future<void> _hangup() async {
    try {
      await context.read<CallController>().endCall();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
