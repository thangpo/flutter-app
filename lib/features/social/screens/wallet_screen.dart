import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../domain/services/social_user_service.dart';
import 'transfer_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'topup_screen.dart';
import 'withdraw_screen.dart';
import 'wallet_detail_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

enum SlideDirection { fromLeft, fromRight, fromTop, fromBottom }

Future<dynamic> navigateWithCustomSlide(
    BuildContext context,
    Widget page, {
      required SlideDirection direction,
      Duration duration = const Duration(milliseconds: 300),
      Curve curve = Curves.easeInOut,
    }) {
  Offset begin;
  switch (direction) {
    case SlideDirection.fromLeft:
      begin = const Offset(-1.0, 0.0);
      break;
    case SlideDirection.fromRight:
      begin = const Offset(1.0, 0.0);
      break;
    case SlideDirection.fromTop:
      begin = const Offset(0.0, -1.0);
      break;
    case SlideDirection.fromBottom:
      begin = const Offset(0.0, 1.0);
      break;
  }

  return Navigator.of(context).push<dynamic>(
    PageRouteBuilder(
      transitionDuration: duration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(begin: begin, end: Offset.zero)
            .chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    ),
  );
}

class _WalletScreenState extends State<WalletScreen> with TickerProviderStateMixin {
  double wallet = 0.0;
  double balance = 0.0;
  int points = 0;
  int dailyPoints = 0;
  int convertedPoints = 0;
  int credits = 0;
  String username = "";
  String email = "";
  bool isLoading = true;
  String? errorMessage;
  bool isQREnabled = true;
  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _loadWallet();
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _floatingAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

  void _showQRSettingsDialog() {
    final isDark = Provider.of<ThemeController>(context, listen: true).darkTheme;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.25),
                      Colors.white.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade400, Colors.blue.shade600],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.settings, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          getTranslated('qr_settings', context) ?? 'Cài đặt QR Code',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isQREnabled
                                    ? [Colors.blue.shade400, Colors.blue.shade600]
                                    : [Colors.grey.shade400, Colors.grey.shade600],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isQREnabled ? Icons.qr_code_2 : Icons.qr_code_scanner_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  getTranslated('qr_feature', context) ?? 'Tính năng QR Code',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isQREnabled
                                      ? getTranslated('qr_enabled', context) ?? 'Đang bật'
                                      : getTranslated('qr_disabled', context) ?? 'Đang tắt',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isQREnabled ? Colors.greenAccent : Colors.redAccent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Transform.scale(
                            scale: 0.9,
                            child: Switch(
                              value: isQREnabled,
                              onChanged: (value) {
                                setState(() {
                                  isQREnabled = value;
                                });
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      value
                                          ? getTranslated('qr_enabled_desc', context) ?? 'Khi bật, bạn có thể...'
                                          : getTranslated('qr_disabled_desc', context) ?? 'Khi tắt, tính năng...',
                                    ),
                                    backgroundColor: value ? Colors.green : Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              activeColor: Colors.blue.shade400,
                              activeTrackColor: Colors.blue.shade200,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isQREnabled
                          ? getTranslated('qr_enabled_desc', context) ?? 'Khi bật, bạn có thể...'
                          : getTranslated('qr_disabled_desc', context) ?? 'Khi tắt, tính năng...',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white.withOpacity(0.8) : Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.3),
                          foregroundColor: isDark ? Colors.white : Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          getTranslated('close', context) ?? 'Đóng',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openWalletDetailWithAnimation() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => WalletDetailScreen(
          balance: wallet,
          username: username,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showMyQRCode() async {
    if (!isQREnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTranslated('qr_disabled_snack', context) ?? 'Tính năng QR đang bị tắt...'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: getTranslated('settings', context) ?? 'Cài đặt',
            textColor: Colors.white,
            onPressed: _showQRSettingsDialog,
          ),
        ),
      );
      return;
    }

    final auth = Provider.of<AuthController>(context, listen: false);
    final userIdStr = await auth.authServiceInterface.getSocialUserId();

    if (userIdStr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTranslated('user_not_found', context) ?? 'Không tìm thấy người dùng'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final userId = int.tryParse(userIdStr) ?? 0;
    final isDark = Provider.of<ThemeController>(context, listen: false).darkTheme;


    late AnimationController _controller;
    late Animation<double> _scaleAnimation;
    late Animation<double> _rotateAnimation;
    late Animation<double> _opacityAnimation;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AlertDialog(
                backgroundColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                content: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                            Colors.white.withOpacity(0.25),
                            Colors.white.withOpacity(0.15),
                          ]
                              : [
                            Colors.white.withOpacity(0.9),
                            Colors.white.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.qr_code_2, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'QR của bạn',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Transform.rotate(
                                  angle: _rotateAnimation.value,
                                  child: Opacity(
                                    opacity: _opacityAnimation.value,
                                    child: Container(
                                      width: 240,
                                      height: 240,
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isDark
                                              ? [
                                            Colors.white.withOpacity(0.3),
                                            Colors.white.withOpacity(0.2),
                                          ]
                                              : [
                                            Colors.white.withOpacity(0.95),
                                            Colors.white.withOpacity(0.85),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.4)
                                              : Colors.grey.withOpacity(0.3),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withOpacity(0.3),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: QrImageView(
                                        data: userId.toString(),
                                        version: QrVersions.auto,
                                        size: 200,
                                        backgroundColor: Colors.white,
                                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                                        embeddedImage: const AssetImage('assets/icon/icon.png'),
                                        embeddedImageStyle: const QrEmbeddedImageStyle(
                                          size: Size(40, 40),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.2),
                                ]
                                    : [
                                  Colors.white.withOpacity(0.95),
                                  Colors.white.withOpacity(0.85),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'ID: $userId',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            getTranslated('others_can_scan_the_QR_code_to_get_your_information', context) ?? 'Người khác có thể quét QR để lấy thông tin của bạn',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white.withOpacity(0.8) : Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                _controller.reverse().then((_) => Navigator.pop(context));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.3),
                                foregroundColor: isDark ? Colors.white : Colors.black87,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                getTranslated('close', context) ?? 'Đóng',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _controller.dispose();
    });

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _rotateAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0)),
    );

    _controller.forward();
  }

  void _openTopUpScreen() async {
    final result = await navigateWithCustomSlide(
      context,
      TopUpScreen(walletBalance: wallet),
      direction: SlideDirection.fromTop,
    );

    if (result == true) {
      await _loadWallet();
    }
  }

  Future<void> _loadWallet() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final auth = Provider.of<AuthController>(context, listen: false);
      final userIdStr = await auth.authServiceInterface.getSocialUserId();
      final accessToken = await auth.authServiceInterface.getSocialAccessToken();

      if (userIdStr == null || accessToken == null) {
        throw Exception(getTranslated('not_logged_in_social', context) ?? "Chưa đăng nhập vào mạng xã hội");
      }

      final userId = int.tryParse(userIdStr);
      if (userId == null) {
        throw Exception(getTranslated('invalid_user_id', context) ?? "ID người dùng không hợp lệ");
      }

      final userData = await SocialUserService().getWalletBalance(
        accessToken: accessToken,
        userId: userId,
      );

      setState(() {
        wallet = _parseToDouble(userData["wallet"]);
        balance = _parseToDouble(userData["balance"]);
        points = _parseToInt(userData["points"]);
        dailyPoints = _parseToInt(userData["daily_points"]);
        convertedPoints = _parseToInt(userData["converted_points"]);
        credits = _parseToInt(userData["credits"]);
        username = userData["username"] ?? "";
        email = userData["email"] ?? "";
        isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint("Wallet load error: $e\n$stackTrace");
      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0.0;
    return 0.0;
  }

  int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  String _formatMoney(double amount, {bool showDecimal = true}) {
    String formatted = amount.toStringAsFixed(2);
    List<String> parts = formatted.split('.');
    String integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    );
    return '$integerPart,${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeController>(context);
    final isDark = theme.darkTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.white.withOpacity(0.3),
              elevation: 0,
              title: Text(
                getTranslated('wallet', context) ?? 'Ví cá nhân',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onPressed: isLoading ? null : _loadWallet,
                  tooltip: "Làm mới ví",
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
              const Color(0xFF1a1a1a),
              const Color(0xFF2d2d2d),
              const Color(0xFF1f1f1f),
            ]
                : [
              const Color(0xFFf5f5f5),
              const Color(0xFFe8e8e8),
              const Color(0xFFfafafa),
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _loadWallet,
          color: Colors.blue.shade700,
          child: isLoading
              ? _buildSkeletonLoading(isDark)
              : errorMessage != null
              ? _buildErrorWidget(isDark)
              : _buildWalletContent(isDark),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!,
      period: const Duration(milliseconds: 1200),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          const SizedBox(height: 24),
          _buildActionButtonsSkeleton(isDark),
          const SizedBox(height: 24),
          Container(width: 150, height: 20, color: Colors.white),
          const SizedBox(height: 12),
          ...List.generate(7, (_) => _buildSkeletonInfoCard(isDark)),
        ],
      ),
    );
  }

  Widget _buildSkeletonInfoCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 100, height: 14, color: Colors.white),
                const SizedBox(height: 8),
                Container(width: 80, height: 16, color: Colors.white),
              ],
            ),
          ),
          Container(width: 80, height: 20, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    required bool isDark,
    bool isDisabled = false,
  }) {
    return Expanded(
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: isDisabled ? null : onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDisabled
                        ? [
                      Colors.grey.withOpacity(0.2),
                      Colors.grey.withOpacity(0.1),
                    ]
                        : [
                      Colors.white.withOpacity(0.25),
                      Colors.white.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors[0].withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isDisabled) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Tắt',
                          style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.send_rounded,
          label: getTranslated('transfer_money', context) ?? 'Chuyển',
          gradientColors: [Colors.blue.shade400, Colors.blue.shade700],
          onTap: () async {
            final auth = Provider.of<AuthController>(context, listen: false);
            final userIdStr = await auth.authServiceInterface.getSocialUserId();
            final accessToken = await auth.authServiceInterface.getSocialAccessToken();
            final userId = int.tryParse(userIdStr ?? '') ?? 0;

            if (userId == 0 || accessToken == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(getTranslated('please_login', context) ?? 'Vui lòng đăng nhập'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
              return;
            }

            final result = await navigateWithCustomSlide(
              context,
              TransferScreen(
                walletBalance: wallet,
                userId: userId,
                accessToken: accessToken,
              ),
              direction: SlideDirection.fromLeft,
            );

            if (result == true) {
              await _loadWallet();
            }
          },
          isDark: isDark,
        ),
        _buildActionButton(
          icon: Icons.add_circle_rounded,
          label: getTranslated('top_up', context) ?? 'Nạp',
          gradientColors: [Colors.green.shade400, Colors.green.shade700],
          onTap: _openTopUpScreen,
          isDark: isDark,
        ),
        _buildActionButton(
          icon: Icons.qr_code_2_rounded,
          label: 'QR',
          gradientColors: isQREnabled
              ? [Colors.purple.shade400, Colors.purple.shade700]
              : [Colors.grey.shade400, Colors.grey.shade600],
          onTap: _showMyQRCode,
          isDark: isDark,
          isDisabled: !isQREnabled,
        ),
        _buildActionButton(
          icon: Icons.card_giftcard_rounded,
          label: getTranslated('ADS', context) ?? 'Ads',
          gradientColors: [Colors.orange.shade400, Colors.orange.shade700],
          onTap: () {
            navigateWithCustomSlide(
              context,
              const WithdrawScreen(),
              direction: SlideDirection.fromRight,
            );
          },
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildActionButtonsSkeleton(bool isDark) {
    return Row(
      children: List.generate(
        4,
            (_) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 90,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletContent(bool isDark) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
      children: [
        _buildMainBalanceCard(isDark),
        const SizedBox(height: 24),
        _buildActionButtons(isDark),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            getTranslated('account_details', context) ?? 'Chi tiết tài khoản',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.account_circle_rounded,
          title: getTranslated('username', context) ?? 'Tên tài khoản',
          value: username,
          gradientColors: [Colors.blue.shade400, Colors.blue.shade700],
          isText: true,
          isDark: isDark,
        ),
        _buildInfoCard(
          icon: Icons.email_rounded,
          title: getTranslated('email', context) ?? 'Email',
          value: email,
          gradientColors: [Colors.cyan.shade400, Colors.cyan.shade700],
          isText: true,
          isDark: isDark,
        ),
        _buildInfoCard(
          icon: Icons.account_balance_wallet_rounded,
          title: getTranslated('balance_label', context) ?? 'Balance',
          value: '${_formatMoney(balance, showDecimal: true)} ₫',
          gradientColors: [Colors.indigo.shade400, Colors.indigo.shade700],
          isDark: isDark,
        ),
        _buildInfoCard(
          icon: Icons.stars_rounded,
          title: getTranslated('points', context) ?? 'Points',
          value: _formatMoney(points.toDouble()),
          gradientColors: [Colors.amber.shade400, Colors.amber.shade700],
          isDark: isDark,
        ),
        _buildInfoCard(
          icon: Icons.calendar_today_rounded,
          title: getTranslated('daily_points', context) ?? 'Daily Points',
          value: _formatMoney(dailyPoints.toDouble()),
          gradientColors: [Colors.teal.shade400, Colors.teal.shade700],
          isDark: isDark,
        ),
        _buildInfoCard(
          icon: Icons.swap_horiz_rounded,
          title: getTranslated('converted_points', context) ?? 'Converted Points',
          value: _formatMoney(convertedPoints.toDouble()),
          gradientColors: [Colors.purple.shade400, Colors.purple.shade700],
          isDark: isDark,
        ),
        _buildInfoCard(
          icon: Icons.credit_card_rounded,
          title: getTranslated('credits', context) ?? 'Credits',
          value: _formatMoney(credits.toDouble()),
          gradientColors: [Colors.pink.shade400, Colors.pink.shade700],
          isDark: isDark,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMainBalanceCard(bool isDark) {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value),
          child: GestureDetector(
            onTap: _openWalletDetailWithAnimation,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.15),
                      ]
                          : [
                        Colors.white.withOpacity(0.8),
                        Colors.white.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade400, Colors.blue.shade700],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.5),
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            getTranslated('balance', context) ?? 'Số dư ví',
                            style: TextStyle(
                              color: isDark ? Colors.white.withOpacity(0.9) : Colors.black54,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.touch_app_rounded,
                            color: Colors.white.withOpacity(0.6),
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Hero(
                        tag: 'wallet_balance_hero',
                        flightShuttleBuilder: (
                            BuildContext flightContext,
                            Animation<double> animation,
                            HeroFlightDirection flightDirection,
                            BuildContext fromHeroContext,
                            BuildContext toHeroContext,
                            ) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) {
                              final fall = Tween<double>(begin: 0.0, end: 1.0).evaluate(animation);
                              final scale = 1.0 + (fall * 2.0);

                              return Transform.translate(
                                offset: Offset(0, fall * 300),
                                child: Transform.scale(
                                  scale: scale,
                                  child: Opacity(
                                    opacity: 1.0 - fall,
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                '${_formatMoney(wallet, showDecimal: true)} đ',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          );
                        },
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            '${_formatMoney(wallet, showDecimal: true)} đ',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                      const                       SizedBox(height: 8),
                      Text(
                        getTranslated('available_balance', context) ?? 'Số dư khả dụng',
                        style: TextStyle(
                          color: isDark ? Colors.white.withOpacity(0.8) : Colors.black45,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required List<Color> gradientColors,
    bool isText = false,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ]
                    : [
                  Colors.white.withOpacity(0.85),
                  Colors.white.withOpacity(0.65),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: isText ? 15 : 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(bool isDark) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 150, 32, 32),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ]
                      : [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade700],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    errorMessage!,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loadWallet,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(getTranslated('retry', context) ?? "Thử lại"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.3),
                        foregroundColor: isDark ? Colors.white : Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}