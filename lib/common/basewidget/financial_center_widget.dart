import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/screens/travel_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/topup/screens/topup_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/topup/screens/data_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/topup/screens/movie_screen.dart';

class FinancialCenterWidget extends StatefulWidget {
  const FinancialCenterWidget({super.key});

  @override
  State<FinancialCenterWidget> createState() => _FinancialCenterWidgetState();
}

class _FinancialCenterWidgetState extends State<FinancialCenterWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _itemAnimations;

  @override
  void initState() {
    super.initState();

    _itemAnimations = List.generate(
      12,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    Future.delayed(Duration.zero, () {
      for (int i = 0; i < _itemAnimations.length; i++) {
        Future.delayed(Duration(milliseconds: i * 50), () {
          if (mounted) {
            _itemAnimations[i].forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _itemAnimations) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showComingSoonDialog(
      BuildContext context, String featureName, Color color) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    size: 48,
                    color: color,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sắp Ra Mắt!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tính năng "$featureName" đang được phát triển',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chúng tôi sẽ thông báo khi tính năng này sẵn sàng',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Đóng',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Đã hiểu',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.send, 'label': 'Chuyển tiền', 'color': Colors.blue},
      {
        'icon': Icons.account_balance,
        'label': 'Chuyển tiền\nNgân hàng',
        'color': Colors.indigo
      },
      {
        'icon': Icons.receipt_long,
        'label': 'Thanh toán\nhóa đơn',
        'color': Colors.orange
      },
      {
        'icon': Icons.phone_android,
        'label': 'Nạp tiền\nđiện thoại',
        'route': const TopUpScreen(),
        'color': Colors.green
      },
      {
        'icon': Icons.network_cell,
        'label': 'Data 4G/5G',
        'route': const DataScreen(),
        'color': Colors.purple
      },
      {'icon': Icons.group, 'label': 'Cộng đồng', 'color': Colors.pink},
      {'icon': Icons.attach_money, 'label': 'Vay Nhanh', 'color': Colors.teal},
      {
        'icon': Icons.account_balance_wallet,
        'label': 'Ví Trả Sau',
        'color': Colors.amber
      },
      {
        'icon': Icons.payments,
        'label': 'Thanh toán\nkhoản vay',
        'color': Colors.deepOrange
      },
      {
        'icon': Icons.movie,
        'label': 'Mua vé xem\nphim',
        'route': const MovieScreen(),
        'color': Colors.red
      },
      {
        'icon': Icons.flight,
        'label': 'Du lịch - Đi lại',
        'route': const TravelScreen(),
        'color': Colors.cyan
      },
      {
        'icon': Icons.restaurant_menu,
        'label': 'Đặt đồ ăn',
        'color': Colors.deepOrange
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.blue.shade50.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade600,
                              Colors.blue.shade400
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Trung Tâm Tài Chính",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 18,
                crossAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                final hasRoute =
                    item.containsKey('route') && item['route'] != null;

                return ScaleTransition(
                  scale: Tween<double>(begin: 0, end: 1).animate(
                    CurvedAnimation(
                        parent: _itemAnimations[index],
                        curve: Curves.elasticOut),
                  ),
                  child: _buildServiceItem(
                    context: context,
                    icon: item['icon'] as IconData,
                    label: item['label'] as String,
                    color: item['color'] as Color,
                    route: item['route'] as Widget?,
                    isActive: hasRoute,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    Widget? route,
    required bool isActive,
  }) {
    return InkWell(
      onTap: () {
        if (route != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => route),
          );
        } else {
          _showComingSoonDialog(context, label, color);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isActive
                          ? [color.withOpacity(0.2), color.withOpacity(0.1)]
                          : [
                              color.withOpacity(0.1),
                              color.withOpacity(0.05),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive
                          ? color.withOpacity(0.3)
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isActive ? color : Colors.grey.shade400,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color:
                        isActive ? Colors.grey.shade800 : Colors.grey.shade500,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Coming soon badge
          if (!isActive)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Soon',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
