import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:provider/provider.dart';
import '../domain/services/social_user_service.dart';
import 'package:flutter_sixvalley_ecommerce/features/ads/services/ads_service.dart';
import 'package:flutter_sixvalley_ecommerce/features/ads/presentation/screens/create_ads_screen.dart';

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
    setState(() => isLoading = true);
    setState(() => isLoadingCampaigns = true);
    setState(() => errorMessage = null);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(getTranslated('withdraw', context) ?? 'Quảng cáo'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: isLoading
            ? _buildLoading()
            : errorMessage != null
            ? _buildError()
            : _buildContent(isDark),
      ),
    );
  }

  Route _createRoute() {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => const CreateAdsScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Lấy kích thước nút gốc
        const begin = 0.0;
        const end = 1.0;
        final tween = Tween(begin: begin, end: end);
        final scaleAnimation = animation.drive(tween);

        return ScaleTransition(
          scale: scaleAnimation,
          child: child,
        );
      },
      // Quan trọng: Đặt fullscreenDialog = false để Hero hoạt động
      fullscreenDialog: false,
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWalletCard(isDark),
        const SizedBox(height: 24),
        _buildCreateCampaignButton(),
        const SizedBox(height: 32),

        Text(
          'Lịch sử chiến dịch',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        isLoadingCampaigns
            ? _buildCampaignsSkeleton()
            : campaigns.isEmpty
            ? _buildEmptyState(isDark)
            : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: campaigns.length,
          itemBuilder: (context, index) {
            final camp = campaigns[index];
            return _buildCampaignCard(camp, isDark);
          },
        ),
      ],
    );
  }

  Widget _buildWalletCard(bool isDark) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.orange.shade900, Colors.orange.shade700]
                : [Colors.orange.shade600, Colors.orange.shade800],
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Số dư quảng cáo',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatMoney(walletBalance)} đ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateCampaignButton() {
    return Hero(
      tag: 'create_ads_button',
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(_createRoute());
          },
          icon: const Icon(Icons.add_circle_outline, size: 20),
          label: const Text(
            'Tạo chiến dịch mới',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 3,
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> camp, bool isDark) {
    final isActive = camp["status"] == "1";
    final statusText = isActive ? "Đang chạy" : "Đã dừng";
    final statusColor = isActive ? Colors.green : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: isDark ? Colors.grey[800] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            camp["ad_media"] ?? '',
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 50,
              height: 50,
              color: Colors.grey[300],
              child: const Icon(Icons.image, color: Colors.grey),
            ),
          ),
        ),
        title: Text(
          camp["headline"] ?? 'Không có tiêu đề',
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${camp["clicks"] ?? 0} clicks • ${camp["views"] ?? 0} views'),
            if (camp["location"] != null) Text(camp["location"]),
          ],
        ),
        trailing: Chip(
          label: Text(statusText, style: TextStyle(fontSize: 11, color: statusColor)),
          backgroundColor: statusColor.withOpacity(0.1),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chi tiết: ${camp["headline"]}')),
          );
        },
      ),
    );
  }

  Widget _buildCampaignsSkeleton() {
    return Column(
      children: List.generate(
        3,
            (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: ListTile(
              leading: Container(width: 50, height: 50, color: Colors.grey[300]),
              title: Container(height: 16, width: double.infinity, color: Colors.grey[300]),
              subtitle: Container(height: 12, width: 150, color: Colors.grey[300], margin: const EdgeInsets.only(top: 8)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Chưa có chiến dịch nào',
            style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(height: 8),
          const Text('Bấm nút trên để tạo chiến dịch đầu tiên'),
        ],
      ),
    );
  }
}