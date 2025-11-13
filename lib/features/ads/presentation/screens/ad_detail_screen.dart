import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/ads/presentation/screens/update_ad_screen.dart';


class AdDetailScreen extends StatelessWidget {
  final Map<String, dynamic> adData;
  final int adId;
  final String accessToken;

  const AdDetailScreen({
    super.key,
    required this.adData,
    required this.adId,
    required this.accessToken,
  });

  String _formatMoney(String amount) {
    final num = double.tryParse(amount) ?? 0;
    return NumberFormat('#,##0', 'vi_VN').format(num);
  }

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (e) {
      return date;
    }
  }

  String _getGender(String gender, BuildContext context) {
    switch (gender) {
      case 'male':
        return getTranslated('male', context) ?? 'Nam';
      case 'female':
        return getTranslated('female', context) ?? 'Nữ';
      default:
        return getTranslated('all', context) ?? 'Tất cả';
    }
  }

  String _getBidding(String bidding, BuildContext context) {
    return bidding == 'clicks'
        ? (getTranslated('per_click', context) ?? 'Mỗi click')
        : (getTranslated('per_view', context) ?? 'Mỗi lượt xem');
  }

  String _getAppears(String appears, BuildContext context) {
    final map = {
      'post': getTranslated('post', context) ?? 'Bưu kiện',
      'sidebar': getTranslated('sidebar', context) ?? 'Thanh bên',
      'story': getTranslated('story', context) ?? 'Câu chuyện',
      'entire': getTranslated('entire_site', context) ?? 'Toàn bộ trang',
      'jobs': getTranslated('jobs', context) ?? 'Việc làm',
      'forum': getTranslated('forum', context) ?? 'Diễn đàn',
      'movies': getTranslated('movies', context) ?? 'Phim',
      'offer': getTranslated('offer', context) ?? 'Ưu đãi',
      'funding': getTranslated('funding', context) ?? 'Gây quỹ',
    };
    return map[appears] ?? appears;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeController>(context);
    final isDark = theme.darkTheme;
    final data = adData['data'];
    final userData = data['user_data'];
    final isOwner = data['is_owner'] == true;

    final clicks = int.tryParse(data['clicks'] ?? '0') ?? 0;
    final views = int.tryParse(data['views'] ?? '0') ?? 0;
    final spent = double.tryParse(data['spent'] ?? '0') ?? 0.0;
    final budget = double.tryParse(data['budget'] ?? '0') ?? 0.0;
    final remaining = budget - spent;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: isDark ? Colors.white : Colors.black87,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
              ),
              title: Text(
                getTranslated('ad_detail', context) ?? 'Chi tiết chiến dịch',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.3,
                ),
              ),
              centerTitle: true,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              const Color(0xFF1A1A1A),
              const Color(0xFF121212),
              Colors.purple.shade900.withOpacity(0.3),
            ]
                : [
              const Color(0xFFF5F7FA),
              const Color(0xFFE8EDF5),
              Colors.blue.shade50.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 70, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGlassImageCard(data, isDark),
                const SizedBox(height: 20),

                _buildGlassTextCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['headline'] ?? (getTranslated('no_title', context) ?? 'Không có tiêu đề'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['description'] ?? (getTranslated('no_description', context) ?? 'Không có mô tả'),
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  isDark: isDark,
                ),
                const SizedBox(height: 24),

                _buildPerformanceSection(clicks, views, spent, budget, remaining, isDark, context),
                const SizedBox(height: 24),

                _buildInfoCard([
                  _buildInfoRow(context,
                      getTranslated('campaign_name', context) ?? 'Tên chiến dịch',
                      data['name'],
                      isDark: isDark
                  ),
                  _buildInfoRow(context,
                      getTranslated('website', context) ?? 'Website',
                      data['url'],
                      isUrl: true,
                      isDark: isDark
                  ),
                  _buildInfoRow(context,
                      getTranslated('display_position', context) ?? 'Vị trí hiển thị',
                      _getAppears(data['appears'], context),
                      isDark: isDark
                  ),
                  _buildInfoRow(context,
                      getTranslated('gender', context) ?? 'Giới tính',
                      _getGender(data['gender'], context),
                      isDark: isDark
                  ),
                  _buildInfoRow(context,
                      getTranslated('bidding', context) ?? 'Đấu thầu',
                      _getBidding(data['bidding'], context),
                      isDark: isDark
                  ),
                  _buildInfoRow(context,
                      getTranslated('budget', context) ?? 'Ngân sách',
                      '${_formatMoney(data['budget'])} đ',
                      isDark: isDark
                  ),
                  _buildInfoRow(context,
                      getTranslated('spent', context) ?? 'Đã chi',
                      '${_formatMoney(data['spent'])} đ',
                      isDark: isDark
                  ),
                  _buildInfoRow(context, 'Clicks', '$clicks', isDark: isDark),
                  _buildInfoRow(context, 'Views', '$views', isDark: isDark),
                  _buildInfoRow(context,
                      getTranslated('start_date', context) ?? 'Bắt đầu',
                      _formatDate(data['start']),
                      isDark: isDark
                  ),
                  _buildInfoRow(context,
                      getTranslated('end_date', context) ?? 'Kết thúc',
                      _formatDate(data['end']),
                      isDark: isDark
                  ),
                  _buildInfoRow(context,
                      getTranslated('status', context) ?? 'Trạng thái',
                      data['status'] == "1"
                          ? (getTranslated('running', context) ?? 'Đang chạy')
                          : (getTranslated('stopped', context) ?? 'Đã dừng'),
                      valueColor: data['status'] == "1"
                          ? Colors.green.shade400
                          : Colors.red.shade400,
                      isDark: isDark
                  ),
                  _buildInfoRow(context,
                      getTranslated('location', context) ?? 'Vị trí',
                      data['location'] ?? (getTranslated('global', context) ?? 'Toàn cầu'),
                      isDark: isDark
                  ),
                ],
                    getTranslated('campaign_info', context) ?? 'Thông tin chiến dịch',
                    Icons.campaign_rounded,
                    isDark),

                const SizedBox(height: 16),

                if (data['country_ids'] != null && (data['country_ids'] as List).isNotEmpty)
                  _buildInfoCard([
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (data['country_ids'] as List)
                          .map<Widget>((id) => _buildGlassChip('${getTranslated('country', context) ?? 'Quốc gia'} $id', isDark))
                          .toList(),
                    ),
                  ], getTranslated('target_countries', context) ?? 'Quốc gia nhắm đến', Icons.public_rounded, isDark),

                const SizedBox(height: 16),

                _buildInfoCard([
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(isDark ? 0.3 : 0.2),
                            blurRadius: 12,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundImage: NetworkImage(userData['avatar'] ??
                            'https://social.vnshop247.com/upload/photos/d-avatar.jpg?cache=0'),
                      ),
                    ),
                    title: Text(
                      userData['name'] ?? userData['username'],
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      isOwner
                          ? (getTranslated('you_are_owner', context) ?? 'Bạn là chủ sở hữu')
                          : (getTranslated('creator', context) ?? 'Người tạo'),
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    trailing: isOwner
                        ? _buildGlassChip(getTranslated('you', context) ?? 'Bạn', isDark, color: Colors.green)
                        : null,
                  ),
                ], getTranslated('owner', context) ?? 'Chủ sở hữu', Icons.person_rounded, isDark),

                const SizedBox(height: 32),
                _buildEditButton(context, isDark),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditButton(BuildContext context, bool isDark) {
    final data = adData['data'];

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)]
                  : [Colors.white.withOpacity(0.7), Colors.white.withOpacity(0.5)],
            ),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () async {
                HapticFeedback.mediumImpact();
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UpdateAdScreen(
                      adId: adId,
                      accessToken: accessToken,
                      adData: data,
                    ),
                  ),
                );

                if (updated == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Text(getTranslated('update_success', context) ?? 'Cập nhật thành công!'),
                        ],
                      ),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                  Navigator.pop(context, true);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.blue, Colors.purple]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(colors: [Colors.blue, Colors.purple]).createShader(bounds),
                      child: Text(
                        getTranslated('edit_campaign', context) ?? 'Chỉnh sửa chiến dịch',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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

  Widget _buildGlassImageCard(Map<String, dynamic> data, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
                  : [Colors.white.withOpacity(0.7), Colors.white.withOpacity(0.5)],
            ),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.network(
              data['ad_media'] ?? '',
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 240,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.grey.shade800, Colors.grey.shade900]
                        : [Colors.grey.shade200, Colors.grey.shade300],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(Icons.image_not_supported_rounded, size: 60, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextCard({required Widget child, required bool isDark}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
                  : [Colors.white.withOpacity(0.7), Colors.white.withOpacity(0.5)],
            ),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassChip(String label, bool isDark, {Color? color}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                (color ?? Colors.blue).withOpacity(isDark ? 0.2 : 0.3),
                (color ?? Colors.blue).withOpacity(isDark ? 0.1 : 0.2),
              ],
            ),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceSection(int clicks, int views, double spent, double budget, double remaining, bool isDark, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            getTranslated('performance_analysis', context) ?? 'Phân tích hiệu suất',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
        ),

        _buildBarChartCard(clicks, views, isDark, context),
        const SizedBox(height: 16),

        _buildPieChartCard(spent, remaining, budget, isDark, context),
        const SizedBox(height: 16),

        _buildLineChartCard(isDark, context),
      ],
    );
  }

  Widget _buildBarChartCard(int clicks, int views, bool isDark, BuildContext context) {
    final maxValue = [clicks, views].reduce((a, b) => a > b ? a : b).toDouble();
    final barWidth = 50.0;

    return _buildChartCard(
      title: getTranslated('clicks_views', context) ?? 'Clicks & Views',
      icon: Icons.bar_chart_rounded,
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxValue > 0 ? maxValue * 1.3 : 10,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final style = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87);
                    if (value == 0) return Text(getTranslated('clicks', context) ?? 'Clicks', style: style);
                    if (value == 1) return Text(getTranslated('views', context) ?? 'Views', style: style);
                    return const Text('');
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: isDark ? Colors.white24 : Colors.black12, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: clicks.toDouble(),
                    gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.purple.shade400]),
                    width: barWidth,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(
                    toY: views.toDouble(),
                    gradient: LinearGradient(colors: [Colors.pink.shade400, Colors.red.shade400]),
                    width: barWidth,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isDark: isDark,
    );
  }

  Widget _buildPieChartCard(double spent, double remaining, double budget, bool isDark, BuildContext context) {
    if (budget == 0) {
      return _buildChartCard(
        title: getTranslated('budget', context) ?? 'Ngân sách',
        icon: Icons.pie_chart_rounded,
        child: Center(
          child: Text(
            getTranslated('no_budget', context) ?? 'Chưa có ngân sách',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 15),
          ),
        ),
        isDark: isDark,
      );
    }

    return _buildChartCard(
      title: getTranslated('budget', context) ?? 'Ngân sách',
      icon: Icons.pie_chart_rounded,
      child: SizedBox(
        height: 200,
        child: PieChart(
          PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 45,
            sections: [
              PieChartSectionData(
                value: spent,
                color: Colors.red.shade400,
                title: '${((spent / budget) * 100).toStringAsFixed(1)}%',
                titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                radius: 55,
              ),
              PieChartSectionData(
                value: remaining,
                color: Colors.green.shade400,
                title: '${((remaining / budget) * 100).toStringAsFixed(1)}%',
                titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                radius: 55,
              ),
            ],
          ),
        ),
      ),
      isDark: isDark,
    );
  }

  Widget _buildLineChartCard(bool isDark, BuildContext context) {
    final spots = [
      const FlSpot(0, 0),
      const FlSpot(1, 2.5),
      const FlSpot(2, 1.8),
      const FlSpot(3, 3.2),
      const FlSpot(4, 2.9),
      const FlSpot(5, 4.1),
      const FlSpot(6, 3.7),
    ];

    return _buildChartCard(
      title: getTranslated('trend_7_days', context) ?? 'Xu hướng (7 ngày gần nhất)',
      icon: Icons.show_chart_rounded,
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: isDark ? Colors.white24 : Colors.black12, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                    return Text(
                      days[value.toInt()],
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.purple.shade400]),
                barWidth: 4,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 5,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: Colors.blue.shade400,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade400.withOpacity(0.3),
                      Colors.purple.shade400.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isDark: isDark,
    );
  }

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Widget child,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
                  : [Colors.white.withOpacity(0.7), Colors.white.withOpacity(0.5)],
            ),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.deepOrange.shade400]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children, String title, IconData icon, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
                  : [Colors.white.withOpacity(0.7), Colors.white.withOpacity(0.5)],
            ),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.deepOrange.shade400]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.white24, Colors.white12, Colors.white24]
                        : [Colors.black12, Colors.black26, Colors.black12],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context,
      String label,
      dynamic value, {
        bool isUrl = false,
        Color? valueColor,
        required bool isDark,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: isUrl
                ? InkWell(
              onTap: () {
                // url_launcher.launchUrl(Uri.parse(value));
              },
              child: Text(
                value ?? (getTranslated('none', context) ?? 'Không có'),
                style: const TextStyle(
                  color: Color(0xFF007AFF),
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            )
                : Text(
              value?.toString() ??
                  (getTranslated('none', context) ?? 'Không có'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor ??
                    (isDark ? Colors.white : Colors.black87),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}