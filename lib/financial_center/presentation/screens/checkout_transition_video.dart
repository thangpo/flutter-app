import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

import '../models/flight_data_models.dart';
import 'flight_checkout_screen.dart';

class FlightCheckoutArgs {
  final FlightSeat seat;
  final int passengers;
  final String airlineName;
  final String fromCode;
  final String toCode;
  final String departTimeText;
  final String arriveTimeText;
  final String flightCode;
  final double unitPrice;
  final double totalPrice;

  const FlightCheckoutArgs({
    required this.seat,
    required this.passengers,
    required this.airlineName,
    required this.fromCode,
    required this.toCode,
    required this.departTimeText,
    required this.arriveTimeText,
    required this.flightCode,
    required this.unitPrice,
    required this.totalPrice,
  });
}

class CheckoutTransitionVideoScreen extends StatefulWidget {
  final FlightCheckoutArgs args;

  const CheckoutTransitionVideoScreen({super.key, required this.args});

  @override
  State<CheckoutTransitionVideoScreen> createState() => _CheckoutTransitionVideoScreenState();
}

class _CheckoutTransitionVideoScreenState extends State<CheckoutTransitionVideoScreen> {
  VideoPlayerController? _controller;

  Timer? _fadeTimer;
  Timer? _navTimer;

  // overlay fade-out
  double _fadeOpacity = 0.0;
  bool _navigated = false;

  static const _videos = <String>[
    'assets/videos/checkout_1.mp4',
    'assets/videos/checkout_2.mp4',
  ];

  static const Duration _maxPlay = Duration(seconds: 3); // bố muốn luôn 3s thì giữ
  static const Duration _fadeDuration = Duration(milliseconds: 260);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final pick = _videos[math.Random().nextInt(_videos.length)];
    final controller = VideoPlayerController.asset(pick);

    try {
      await controller.initialize();
      controller.setLooping(false);

      if (!mounted) return;
      setState(() => _controller = controller);

      // play ngay khi đã gắn controller lên UI
      await controller.play();

      // tính thời lượng chạy: min(videoDuration, 3s) để đúng flow 3s -> checkout
      final videoDur = controller.value.duration;
      final playFor = (videoDur == Duration.zero)
          ? _maxPlay
          : (videoDur < _maxPlay ? videoDur : _maxPlay);

      final fadeStart = playFor - _fadeDuration;
      final safeFadeStart = fadeStart.isNegative ? Duration.zero : fadeStart;

      _fadeTimer?.cancel();
      _navTimer?.cancel();

      // bắt đầu fade khi gần hết
      _fadeTimer = Timer(safeFadeStart, _startFadeOut);

      // chuyển trang ngay sau khi fade xong (hoặc sau playFor nếu fadeStart=0)
      _navTimer = Timer(playFor, _goCheckout);

    } catch (e) {
      // nếu video lỗi -> chuyển thẳng
      _goCheckout();
    }
  }

  void _startFadeOut() {
    if (!mounted) return;
    setState(() => _fadeOpacity = 1.0);
  }

  void _goCheckout() {
    if (!mounted || _navigated) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => FlightCheckoutScreen(args: widget.args),
      ),
    );
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _navTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeController>(context, listen: true).darkTheme;
    final bg = isDark ? Colors.black : Colors.white;

    final c = _controller;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // VIDEO FULL SCREEN (cover)
          Positioned.fill(
            child: (c != null && c.value.isInitialized)
                ? FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            )
                : const SizedBox.shrink(),
          ),

          // FADE OUT OVERLAY (mờ dần video rồi mới chuyển trang)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _fadeOpacity,
                duration: _fadeDuration,
                curve: Curves.easeOut,
                child: const ColoredBox(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}