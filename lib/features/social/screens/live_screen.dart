import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class LiveScreen extends StatefulWidget {
  final String appId;
  final String channelName;
  final String token;
  final String accessToken;

  const LiveScreen({
    super.key,
    required this.appId,
    required this.channelName,
    required this.token,
    required this.accessToken,
  });

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  RtcEngine? _engine;
  bool _joined = false;
  bool _loading = false;
  String? _currentToken;

  bool get _hasToken => _currentToken?.isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    _currentToken = widget.token;
    if (_hasToken) _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.camera, Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(appId: widget.appId));

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection conn, int elapsed) {
          debugPrint('✅ Join thành công: ${conn.channelId}');
          setState(() => _joined = true);
        },
        onUserJoined: (RtcConnection conn, int uid, int elapsed) {
          debugPrint('👤 Viewer join: $uid');
        },
        onFirstLocalVideoFrame: (conn, width, height, elapsed) {
          debugPrint('📸 Frame đầu tiên: ${width}x$height');
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint('❌ Lỗi Agora: $err - $msg');
        },
      ),
    );

    // ✅ Bật video và đặt vai trò phát sóng
    await _engine!.enableVideo();
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    // ✅ Cấu hình hướng hiển thị (sửa lỗi xoay ngược)
    await _engine!.setVideoEncoderConfiguration(
      const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 720, height: 1280),
        orientationMode: OrientationMode.orientationModeFixedPortrait,
        mirrorMode: VideoMirrorModeType.videoMirrorModeEnabled,
      ),
    );

    // ✅ Thiết lập khung video cục bộ (local)
    await _engine!.setupLocalVideo(const VideoCanvas(
      uid: 0,
      mirrorMode: VideoMirrorModeType.videoMirrorModeEnabled,
      renderMode: RenderModeType.renderModeHidden,
    ));

    await _engine!.startPreview();

    print('🎫 [DEBUG] Token đang dùng joinChannel: $_currentToken');

    await _engine!.joinChannel(
      token: _currentToken ?? '',
      channelId: widget.channelName,
      uid: 316,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
      ),
    );
  }

  Future<void> _generateTokenAndStart() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final url = Uri.parse(
        'https://social.vnshop247.com/api/generate_agora_token?access_token=${widget.accessToken}',
      );

      final res = await http.post(url, body: {
        'server_key':
        'f6e69c898ddd643154c9bd4b152555842e26a868-d195c100005dddb9f1a30a67a5ae42d4-19845955',
        'channelName': widget.channelName,
        'uid': '316',
        'role': 'publisher',
      });

      print('🎫 Channel join: ${widget.channelName}');
      final rawBody = res.body;
      print('🧾 [DEBUG] Raw response from server:\n$rawBody');

      String cleanBody = rawBody
          .replaceAll(RegExp(r'[\r\n]+'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'\}\s*\[\]\s*$'), '}')
          .trim();

      print('🧩 [DEBUG] Cleaned JSON body:\n$cleanBody');

      Map<String, dynamic>? jsonData;
      try {
        jsonData = jsonDecode(cleanBody);
        final token = (jsonData != null && jsonData is Map<String, dynamic>)
            ? jsonData['token_agora']?.toString()
            : null;

        if (token != null && token.isNotEmpty) {
          print('🎫 Token Agora mới: $token');
          setState(() => _currentToken = token);
          await _initAgora();
        } else {
          _showMsg('Không thể lấy token hợp lệ từ server');
        }
      } on FormatException catch (e) {
        print('❌ [DEBUG] FormatException khi parse JSON: $e');
        print('❌ [DEBUG] Raw (lỗi) JSON content:\n$cleanBody');

        final match = RegExp(r'\{.*\}').firstMatch(cleanBody);
        if (match != null) {
          final jsonPart = match.group(0)!;
          print('🛠 [DEBUG] Found valid JSON substring:\n$jsonPart');
          try {
            jsonData = jsonDecode(jsonPart);
            print('✅ [DEBUG] Fixed JSON parsed OK: $jsonData');
          } catch (e2) {
            _showMsg('Không thể phân tích dữ liệu token (JSON lỗi)');
            return;
          }
        } else {
          _showMsg('Phản hồi từ server không hợp lệ');
          return;
        }
      } catch (e) {
        print('❌ [DEBUG] Lỗi khác khi parse JSON: $e');
        _showMsg('Không thể xử lý phản hồi từ server');
        return;
      }
    } catch (e) {
      _showMsg('Lỗi tạo token: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    if (_engine != null) {
      _engine!.leaveChannel();
      _engine!.release();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasToken) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.videocam, color: Colors.white, size: 80),
                const SizedBox(height: 16),
                const Text(
                  'Chuẩn bị Livestream',
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Bạn chưa có token Agora (mới tạo bài post livestream)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: _generateTokenAndStart,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Bắt đầu phát trực tiếp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.grey),
                  label: const Text(
                    'Quay lại',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _joined
                ? AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _engine!,
                canvas: const VideoCanvas(uid: 0),
              ),
            )
                : const CircularProgressIndicator(color: Colors.white),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () async {
                await _engine?.leaveChannel();
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
