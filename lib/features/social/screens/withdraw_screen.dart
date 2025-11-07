import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:provider/provider.dart';
import '../domain/services/social_user_service.dart';
import 'package:flutter_sixvalley_ecommerce/features/ads/services/ads_service.dart';
import 'package:flutter_sixvalley_ecommerce/features/ads/presentation/screens/create_ads_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/ads/presentation/screens/ad_detail_screen.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  double walletBalance = 0.0;
  List<Map<String, dynamic>> campaigns = [];
  bool isLoading = true;
  bool isLoadingCampaigns = true;
  String? errorMessage;
  final Map<int, bool> _deletingItems = {};
  final Map<int, bool> _loadingItems = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim()) ?? 0.0;
  }

  String _formatMoney(double amount) {
    final formatted = amount.toStringAsFixed(0);
    return formatted.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    );
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      isLoadingCampaigns = true;
      errorMessage = null;
    });

    try {
      final auth = Provider.of<AuthController>(context, listen: false);
      final accessToken = await auth.authServiceInterface.getSocialAccessToken();
      final userIdStr = await auth.authServiceInterface.getSocialUserId();
      final userId = int.tryParse(userIdStr ?? '') ?? 0;

      if (accessToken == null) throw Exception("Chưa đăng nhập");

      final walletData = await SocialUserService().getWalletBalance(
        accessToken: accessToken,
        userId: userId,
      );
      walletBalance = _toDouble(walletData["wallet"]);

      final adsData = await AdsService().fetchMyCampaigns(
        accessToken: accessToken,
        limit: 20,
        offset: 0,
      );
      campaigns = adsData;

      setState(() {
        isLoading = false;
        isLoadingCampaigns = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        isLoadingCampaigns = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          getTranslated('withdraw', context) ?? 'Quảng cáo',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: const Color(0xFFF2F2F7),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: Colors.blue,
        backgroundColor: Colors.white,
        child: isLoading
            ? _buildLoading()
            : errorMessage != null
            ? _buildError()
            : _buildContent(),
      ),
    );
  }

  Route _createRoute() {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => const CreateAdsScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      fullscreenDialog: true,
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Đang tải...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.error_outline, size: 40, color: Colors.red),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildGlassButton(
            onPressed: _loadData,
            icon: Icons.refresh,
            text: 'Thử lại',
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWalletCard(),
        const SizedBox(height: 24),
        _buildCreateCampaignButton(),
        const SizedBox(height: 32),

        // Header với style iOS
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Lịch sử chiến dịch',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black.withOpacity(0.9),
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),

        isLoadingCampaigns
            ? _buildCampaignsSkeleton()
            : campaigns.isEmpty
            ? _buildEmptyState()
            : _buildCampaignsList(),
      ],
    );
  }

  Widget _buildWalletCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Số dư quảng cáo',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatMoney(walletBalance)} đ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateCampaignButton() {
    return _buildGlassButton(
      onPressed: () async {
        final result = await Navigator.of(context).push(_createRoute());
        if (result == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Đang tải chiến dịch mới...'),
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          await _loadData();
        }
      },
      icon: Icons.add_circle_outline,
      text: 'Tạo chiến dịch mới',
      color: Colors.green,
      isLarge: true,
    );
  }

  Widget _buildGlassButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String text,
    required Color color,
    bool isLarge = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: isLarge ? 18 : 14,
              horizontal: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: isLarge ? 20 : 18),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: isLarge ? 17 : 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: campaigns.length,
      itemBuilder: (context, index) {
        final camp = campaigns[index];
        final adId = int.tryParse(camp['id']?.toString() ?? '');
        final isDeleting = adId != null && (_deletingItems[adId] ?? false);
        final isLoading = adId != null && (_loadingItems[adId] ?? false);

        return AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: isDeleting ? 0.0 : 1.0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              offset: isDeleting ? const Offset(0.3, 0) : Offset.zero,
              curve: Curves.easeInOutCubic,
              child: isDeleting
                  ? const SizedBox.shrink()
                  : _buildCampaignCard(camp, adId, isLoading),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> camp, int? adId, bool isLoading) {
    final isActive = camp["status"] == "1";
    final statusText = isActive ? "Đang chạy" : "Đã dừng";
    final statusColor = isActive ? Colors.green : Colors.grey;
    final headline = camp["headline"] ?? 'Không có tiêu đề';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading ? null : () => _handleCampaignTap(adId, camp),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // Loading overlay
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.black.withOpacity(0.1),
                      ),
                      child: Center(
                        child: Container(
                          width: 30,
                          height: 30,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                      ),
                    ),
                  ),

                Row(
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        camp["ad_media"] ?? '',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: const Color(0xFFF2F2F7),
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headline,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${camp["clicks"] ?? 0} clicks • ${camp["views"] ?? 0} views',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (camp["location"] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              camp["location"],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Status and actions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: isActive ? Colors.grey.shade400 : Colors.red,
                            size: 20,
                          ),
                          tooltip: isActive ? 'Dừng chiến dịch trước khi xóa' : 'Xóa chiến dịch',
                          onPressed: isLoading
                              ? null
                              : (adId == null)
                              ? null
                              : () => _handleDeleteRequest(context, adId, headline, isActive),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCampaignTap(int? adId, Map<String, dynamic> camp) async {
    if (adId == null) {
      _showSnackBar('ID quảng cáo không hợp lệ');
      return;
    }

    // Set loading state for this specific item
    setState(() {
      _loadingItems[adId] = true;
    });

    try {
      final auth = Provider.of<AuthController>(context, listen: false);
      final accessToken = await auth.authServiceInterface.getSocialAccessToken();
      if (accessToken == null) throw Exception("Chưa đăng nhập");

      final adDetail = await AdsService().fetchAdById(
        accessToken: accessToken,
        adId: adId,
      );

      if (!context.mounted) return;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdDetailScreen(
            adData: adDetail,
            adId: adId,
            accessToken: accessToken,
          ),
        ),
      );

      if (result == true && context.mounted) {
        _loadData();
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar('Lỗi: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingItems.remove(adId);
        });
      }
    }
  }

  void _handleDeleteRequest(BuildContext context, int adId, String headline, bool isActive) {
    if (isActive) {
      _showStopBeforeDeleteDialog(context, adId, headline);
    } else {
      _showDeleteConfirmation(context, adId, headline);
    }
  }

  void _showStopBeforeDeleteDialog(BuildContext context, int adId, String headline) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.pause_circle_outline, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'Chiến dịch đang chạy',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Text(
          'Chiến dịch "$headline" đang hoạt động.\n\nBạn có muốn dừng và xóa chiến dịch này không?',
          style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9500), Color(0xFFFF5E3A)],
              ),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _stopAndDeleteCampaign(adId, headline);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Dừng & Xóa',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int adId, String headline) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Xóa chiến dịch?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn xóa chiến dịch:\n\n"$headline"\n\nHành động này không thể hoàn tác.',
          style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFFFF3B30), Color(0xFFFF2D55)],
              ),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _deleteCampaign(adId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Xóa',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _stopAndDeleteCampaign(int adId, String headline) async {
    try {
      final auth = Provider.of<AuthController>(context, listen: false);
      final accessToken = await auth.authServiceInterface.getSocialAccessToken();
      if (accessToken == null) throw Exception("Chưa đăng nhập");
      _showSnackBar('Đang dừng chiến dịch...', isError: false);
      await Future.delayed(const Duration(milliseconds: 500));

      _deleteCampaign(adId);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Lỗi khi dừng: ${e.toString().replaceFirst('Exception: ', '')}', isError: true);
      }
    }
  }

  Future<void> _deleteCampaign(int adId) async {
    setState(() {
      _deletingItems[adId] = true;
    });
    await Future.delayed(const Duration(milliseconds: 350));

    try {
      final auth = Provider.of<AuthController>(context, listen: false);
      final accessToken = await auth.authServiceInterface.getSocialAccessToken();
      if (accessToken == null) throw Exception("Chưa đăng nhập");

      await AdsService().deleteCampaign(
        accessToken: accessToken,
        adId: adId,
      );

      if (!mounted) return;

      _showSnackBar('Xóa chiến dịch thành công!', isError: false);

      setState(() {
        campaigns.removeWhere((c) => int.tryParse(c['id']?.toString() ?? '') == adId);
        _deletingItems.remove(adId);
      });

      _loadData();
    } catch (e) {
      setState(() {
        _deletingItems.remove(adId);
      });

      if (mounted) {
        _showSnackBar('Xóa thất bại: ${e.toString().replaceFirst('Exception: ', '')}', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildCampaignsSkeleton() {
    return Column(
      children: List.generate(
        3,
            (_) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.history, size: 40, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chưa có chiến dịch nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bấm nút trên để tạo chiến dịch đầu tiên',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}