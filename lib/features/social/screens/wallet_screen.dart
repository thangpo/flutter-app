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

class _WalletScreenState extends State<WalletScreen> {
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
  bool isQREnabled = true; // Trạng thái bật/tắt QR

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  // Hàm hiển thị dialog bật/tắt QR
  void _showQRSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.settings, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text(
              'Cài đặt QR Code',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    isQREnabled ? Icons.qr_code_2 : Icons.qr_code_scanner_outlined,
                    color: Colors.blue.shade700,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tính năng QR Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isQREnabled ? 'Đang bật' : 'Đang tắt',
                          style: TextStyle(
                            fontSize: 14,
                            color: isQREnabled ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
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
                                ? 'Đã bật tính năng QR Code'
                                : 'Đã tắt tính năng QR Code',
                          ),
                          backgroundColor: value ? Colors.green : Colors.red,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    activeColor: Colors.blue.shade700,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isQREnabled
                  ? 'Khi bật, bạn có thể hiển thị và quét mã QR để chia sẻ thông tin.'
                  : 'Khi tắt, tính năng QR sẽ không khả dụng.',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Đóng',
              style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showMyQRCode() async {
    if (!isQREnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tính năng QR đang bị tắt. Vui lòng bật trong cài đặt.'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Cài đặt',
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
        const SnackBar(content: Text('Không tìm thấy người dùng')),
      );
      return;
    }

    final userId = int.tryParse(userIdStr) ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.qr_code_2, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('QR của bạn', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: userId.toString(),
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                    embeddedImage: const AssetImage('assets/icon/icon.png'),
                    embeddedImageStyle: const QrEmbeddedImageStyle(
                      size: Size(40, 40),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ID: $userId',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Người khác có thể quét QR để lấy thông tin của bạn',
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Đóng',
              style: TextStyle(color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
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
      final accessToken =
      await auth.authServiceInterface.getSocialAccessToken();

      if (userIdStr == null || accessToken == null) {
        throw Exception("Chưa đăng nhập vào mạng xã hội");
      }

      final userId = int.tryParse(userIdStr);
      if (userId == null) {
        throw Exception("ID người dùng không hợp lệ");
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
      appBar: AppBar(
        title: Text(getTranslated('wallet', context) ?? 'Ví cá nhân'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isQREnabled ? Icons.qr_code_2 : Icons.qr_code_scanner_outlined),
            onPressed: _showQRSettingsDialog,
            tooltip: "Cài đặt QR",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _loadWallet,
            tooltip: "Làm mới ví",
          ),
        ],
      ),
      backgroundColor: isDark ? Colors.grey[850] : Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _loadWallet,
        color: Colors.blue.shade700,
        child: isLoading
            ? _buildSkeletonLoading(isDark)
            : errorMessage != null
            ? _buildErrorWidget(isDark)
            : _buildWalletContent(isDark),
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
        padding: const EdgeInsets.all(16),
        children: [
          Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16))),
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
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10))),
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
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
    bool isDisabled = false,
  }) {
    return Expanded(
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                      color: color, fontSize: 13, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isDisabled) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Tắt',
                      style: TextStyle(fontSize: 10, color: Colors.red),
                    ),
                  ),
                ],
              ],
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
          icon: Icons.send,
          label: getTranslated('transfer_money', context) ?? 'Chuyển tiền',
          color: Colors.blue.shade700,
          onTap: () async {
            final auth = Provider.of<AuthController>(context, listen: false);
            final userIdStr = await auth.authServiceInterface.getSocialUserId();
            final accessToken = await auth.authServiceInterface.getSocialAccessToken();
            final userId = int.tryParse(userIdStr ?? '') ?? 0;

            if (userId == 0 || accessToken == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng đăng nhập')),
              );
              return;
            }

            // DỪNG TẠI ĐÂY: Dùng Navigator.push để nhận kết quả
            final result = await navigateWithCustomSlide(
              context,
              TransferScreen(
                walletBalance: wallet,
                userId: userId,
                accessToken: accessToken,
              ),
              direction: SlideDirection.fromLeft,
            );

            // NẾU CHUYỂN TIỀN THÀNH CÔNG → RELOAD VÍ
            if (result == true) {
              await _loadWallet(); // TẢI LẠI SỐ DƯ
            }
          },
          isDark: isDark,
        ),
        _buildActionButton(
          icon: Icons.add_circle,
          label: getTranslated('top_up', context) ?? 'Nạp tiền',
          color: Colors.green,
          onTap: _openTopUpScreen,
          isDark: isDark,
        ),
        _buildActionButton(
          icon: Icons.qr_code_2,
          label: 'QR ID',
          color: isQREnabled ? Colors.blue.shade600 : Colors.grey,
          onTap: _showMyQRCode,
          isDark: isDark,
          isDisabled: !isQREnabled,
        ),
        _buildActionButton(
          icon: Icons.money_off,
          label: getTranslated('withdraw', context) ?? 'Rút tiền',
          color: Colors.red,
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
            margin: const EdgeInsets.symmetric(horizontal: 6),
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletContent(bool isDark) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildMainBalanceCard(isDark),
        const SizedBox(height: 20),
        _buildActionButtons(isDark),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            getTranslated('account_details', context) ?? 'Chi tiết tài khoản',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
            icon: Icons.account_circle,
            title: getTranslated('username', context) ?? 'Tên tài khoản',
            value: username,
            color: Colors.blue.shade700,
            isText: true,
            isDark: isDark),
        _buildInfoCard(
            icon: Icons.email,
            title: getTranslated('email', context) ?? 'Email',
            value: email,
            color: Colors.blue.shade600,
            isText: true,
            isDark: isDark),
        _buildInfoCard(
            icon: Icons.account_balance_wallet,
            title: getTranslated('balance_label', context) ?? 'Balance',
            value: '${_formatMoney(balance, showDecimal: true)} ₫',
            color: Colors.blue.shade800,
            isDark: isDark),
        _buildInfoCard(
            icon: Icons.stars,
            title: getTranslated('points', context) ?? 'Points',
            value: _formatMoney(points.toDouble()),
            color: Colors.blue.shade500,
            isDark: isDark),
        _buildInfoCard(
            icon: Icons.calendar_today,
            title: getTranslated('daily_points', context) ?? 'Daily Points',
            value: _formatMoney(dailyPoints.toDouble()),
            color: Colors.lightBlue,
            isDark: isDark),
        _buildInfoCard(
            icon: Icons.swap_horiz,
            title: getTranslated('converted_points', context) ??
                'Converted Points',
            value: _formatMoney(convertedPoints.toDouble()),
            color: Colors.blueAccent,
            isDark: isDark),
        _buildInfoCard(
            icon: Icons.credit_card,
            title: getTranslated('credits', context) ?? 'Credits',
            value: _formatMoney(credits.toDouble()),
            color: Colors.blue.shade400,
            isDark: isDark),
      ],
    );
  }

  Widget _buildMainBalanceCard(bool isDark) {
    return Card(
      elevation: 8,
      color: isDark ? Colors.grey[800] : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.blue.shade900, Colors.blue.shade700]
                : [Colors.blue.shade600, Colors.blue.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet,
                    color: Colors.white.withOpacity(0.9), size: 32),
                const SizedBox(width: 12),
                Text(
                  getTranslated('balance', context) ?? 'Số dư ví',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${_formatMoney(wallet, showDecimal: true)} ₫',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              getTranslated('available_balance', context) ?? 'Số dư khả dụng',
              style:
              TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isText = false,
    required bool isDark,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: isDark ? Colors.grey[800] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title,
            style: TextStyle(
                fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
        trailing: isText
            ? Flexible(
          child: Text(
            value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        )
            : Text(
          value,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(bool isDark) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 50),
        Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
        const SizedBox(height: 20),
        Text(
          errorMessage!,
          style: const TextStyle(fontSize: 16, color: Colors.red),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            onPressed: _loadWallet,
            icon: const Icon(Icons.refresh),
            label: Text(getTranslated('retry', context) ?? "Thử lại"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}