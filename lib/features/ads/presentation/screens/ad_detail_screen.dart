import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
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

  String _getGender(String gender) {
    switch (gender) {
      case 'male':
        return 'Nam';
      case 'female':
        return 'Nữ';
      default:
        return 'Tất cả';
    }
  }

  String _getBidding(String bidding) {
    return bidding == 'clicks' ? 'Mỗi click' : 'Mỗi lượt xem';
  }

  String _getAppears(String appears) {
    final map = {
      'post': 'Bưu kiện',
      'sidebar': 'Thanh bên',
      'story': 'Câu chuyện',
      'entire': 'Toàn bộ trang',
      'jobs': 'Việc làm',
      'forum': 'Diễn đàn',
      'movies': 'Phim',
      'offer': 'Ưu đãi',
      'funding': 'Gây quỹ',
    };
    return map[appears] ?? appears;
  }

  @override
  Widget build(BuildContext context) {
    final data = adData['data'];
    final userData = data['user_data'];
    final isOwner = data['is_owner'] == true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final clicks = int.tryParse(data['clicks'] ?? '0') ?? 0;
    final views = int.tryParse(data['views'] ?? '0') ?? 0;
    final spent = double.tryParse(data['spent'] ?? '0') ?? 0.0;
    final budget = double.tryParse(data['budget'] ?? '0') ?? 0.0;
    final remaining = budget - spent;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              const Color(0xFF2d2d2d),
              const Color(0xFF1a1a1a),
              const Color(0xFF0d0d0d),
            ]
                : [
              const Color(0xFFf5f5f5),
              const Color(0xFFe8e8e8),
              const Color(0xFFdadada),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildGlassAppBar(context, isDark),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
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
                              data['headline'] ?? 'Không có tiêu đề',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              data['description'] ?? 'Không có mô tả',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white70 : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),

                      _buildPerformanceSection(clicks, views, spent, budget, remaining, isDark),
                      const SizedBox(height: 24),


                      _buildInfoCard([
                        _buildInfoRow('Tên chiến dịch', data['name'], isDark: isDark,),
                        _buildInfoRow('Website', data['url'], isUrl: true, isDark: isDark),
                        _buildInfoRow('Vị trí hiển thị', _getAppears(data['appears']), isDark: isDark,),
                        _buildInfoRow('Giới tính', _getGender(data['gender']), isDark: isDark,),
                        _buildInfoRow('Đấu thầu', _getBidding(data['bidding']), isDark: isDark,),
                        _buildInfoRow('Ngân sách', '${_formatMoney(data['budget'])} đ', isDark: isDark,),
                        _buildInfoRow('Đã chi', '${_formatMoney(data['spent'])} đ', isDark: isDark,),
                        _buildInfoRow('Clicks', '$clicks', isDark: isDark,),
                        _buildInfoRow('Views', '$views', isDark: isDark,),
                        _buildInfoRow('Bắt đầu', _formatDate(data['start']), isDark: isDark,),
                        _buildInfoRow('Kết thúc', _formatDate(data['end']), isDark: isDark,),
                        _buildInfoRow(
                          'Trạng thái',
                          data['status'] == "1" ? 'Đang chạy' : 'Đã dừng',
                          valueColor: data['status'] == "1" ? Colors.green.shade600 : Colors.red.shade600,
                          isDark: isDark,
                        ),
                        _buildInfoRow('Vị trí', data['location'] ?? 'Toàn cầu', isDark: isDark,),
                      ], 'Thông tin chiến dịch', Icons.campaign, isDark),

                      const SizedBox(height: 16),

                      if (data['country_ids'] != null && (data['country_ids'] as List).isNotEmpty)
                        _buildInfoCard([
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (data['country_ids'] as List)
                                .map<Widget>((id) => _buildGlassChip('Quốc gia $id', isDark))
                                .toList(),
                          ),
                        ], 'Quốc gia nhắm đến', Icons.public, isDark),

                      const SizedBox(height: 16),

                      _buildInfoCard([
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundImage: NetworkImage(userData['avatar'] ??
                                  'https://social.vnshop247.com/upload/photos/d-avatar.jpg?cache=0'),
                            ),
                          ),
                          title: Text(
                            userData['name'] ?? userData['username'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            isOwner ? 'Bạn là chủ sở hữu' : 'Người tạo',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                          trailing: isOwner
                              ? _buildGlassChip('Bạn', isDark, color: Colors.green)
                              : null,
                        ),
                      ], 'Chủ sở hữu', Icons.person, isDark),

                      const SizedBox(height: 24),
                      _buildEditButton(context, isDark),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
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
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.4),
                Colors.blue.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: ElevatedButton.icon(
            onPressed: () async {
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
                    content: const Text('Cập nhật thành công!'),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
                Navigator.pop(context, true);
              }
            },
            icon: const Icon(Icons.edit, size: 20),
            label: const Text(
              'Chỉnh sửa chiến dịch',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassAppBar(BuildContext context, bool isDark) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Chi tiết chiến dịch',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassImageCard(Map<String, dynamic> data, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              data['ad_media'] ?? '',
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 240,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.withOpacity(0.3),
                      Colors.grey.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Icon(Icons.image_not_supported, size: 60, color: Colors.white.withOpacity(0.7)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextCard({required Widget child, required bool isDark}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
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
            gradient: LinearGradient(
              colors: [
                (color ?? Colors.blue).withOpacity(0.3),
                (color ?? Colors.blue).withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
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

  Widget _buildPerformanceSection(
      int clicks, int views, double spent, double budget, double remaining, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Phân tích hiệu suất',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),

        _buildBarChartCard(clicks, views, isDark),
        const SizedBox(height: 16),

        _buildPieChartCard(spent, remaining, budget, isDark),
        const SizedBox(height: 16),

        _buildLineChartCard(isDark),
      ],
    );
  }

  Widget _buildBarChartCard(int clicks, int views, bool isDark) {
    final maxValue = [clicks, views].reduce((a, b) => a > b ? a : b).toDouble();
    final barWidth = 40.0;

    return _buildChartCard(
      title: 'Clicks & Views',
      icon: Icons.bar_chart,
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxValue > 0 ? maxValue * 1.3 : 10,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final style = TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87);
                    if (value == 0) return Text('Clicks', style: style);
                    if (value == 1) return Text('Views', style: style);
                    return const Text('');
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: clicks.toDouble(),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    width: barWidth,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(
                    toY: views.toDouble(),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    width: barWidth,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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

  Widget _buildPieChartCard(double spent, double remaining, double budget, bool isDark) {
    if (budget == 0) {
      return _buildChartCard(
        title: 'Ngân sách',
        icon: Icons.pie_chart,
        child: Center(
          child: Text(
            'Chưa có ngân sách',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
        ),
        isDark: isDark,
      );
    }

    return _buildChartCard(
      title: 'Ngân sách',
      icon: Icons.pie_chart,
      child: SizedBox(
        height: 180,
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            sections: [
              PieChartSectionData(
                value: spent,
                color: const Color(0xFFf5576c),
                title: '${((spent / budget) * 100).toStringAsFixed(1)}%',
                titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                radius: 50,
              ),
              PieChartSectionData(
                value: remaining,
                color: const Color(0xFF4facfe),
                title: '${((remaining / budget) * 100).toStringAsFixed(1)}%',
                titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                radius: 50,
              ),
            ],
          ),
        ),
      ),
      isDark: isDark,
    );
  }

  Widget _buildLineChartCard(bool isDark) {
    final spots = [
      const FlSpot(0, 0),
      const FlSpot(1, 2),
      const FlSpot(2, 1.5),
      const FlSpot(3, 3),
      const FlSpot(4, 2.8),
      const FlSpot(5, 4),
      const FlSpot(6, 3.5),
    ];

    return _buildChartCard(
      title: 'Xu hướng (7 ngày gần nhất)',
      icon: Icons.show_chart,
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.white.withOpacity(0.1),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                    return Text(
                      days[value.toInt()],
                      style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black87),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: const Color(0xFF667eea),
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF667eea).withOpacity(0.3),
                      const Color(0xFF764ba2).withOpacity(0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
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
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withOpacity(0.3),
                          Colors.deepOrange.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children, String title, IconData icon, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withOpacity(0.3),
                          Colors.deepOrange.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.3),
                    ],
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

  Widget _buildInfoRow(String label, dynamic value,
      {bool isUrl = false, Color? valueColor, required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
                value ?? 'Không có',
                style: const TextStyle(
                  color: Color(0xFF4facfe),
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            )
                : Text(
              value?.toString() ?? 'Không có',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor ?? (isDark ? Colors.white : Colors.black87),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}