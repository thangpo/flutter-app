import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/screens/travel_screen.dart';

class FinancialCenterWidget extends StatelessWidget {
  const FinancialCenterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Danh sách dịch vụ với màu sắc riêng
      final items = [
        {'icon': Icons.send, 'label': 'Chuyển tiền', 'color': Colors.blue},
        {'icon': Icons.account_balance, 'label': 'Chuyển tiền\nNgân hàng', 'color': Colors.indigo},
        {'icon': Icons.receipt_long, 'label': 'Thanh toán\nhóa đơn', 'color': Colors.orange},
        {'icon': Icons.phone_android, 'label': 'Nạp tiền\nđiện thoại', 'color': Colors.green},
        {'icon': Icons.network_cell, 'label': 'Data 4G/5G', 'color': Colors.purple},
        {'icon': Icons.group, 'label': 'Cộng đồng', 'color': Colors.pink},
        {'icon': Icons.attach_money, 'label': 'Vay Nhanh', 'color': Colors.teal},
        {'icon': Icons.account_balance_wallet, 'label': 'Ví Trả Sau', 'color': Colors.amber},
        {'icon': Icons.payments, 'label': 'Thanh toán\nkhoản vay', 'color': Colors.deepOrange},
        {'icon': Icons.movie, 'label': 'Mua vé xem\nphim', 'color': Colors.red},
        {'icon': Icons.flight, 'label': 'Du lịch - Đi lại', 'route': const TravelScreen(), 'color': Colors.cyan},
        {'icon': Icons.more_horiz, 'label': 'Xem thêm\ndịch vụ', 'color': Colors.blueGrey},
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
                            colors: [Colors.blue.shade600, Colors.blue.shade400],
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
                final color = item['color'] as Color;

                return _buildServiceItem(
                  context: context,
                  icon: item['icon'] as IconData,
                  label: item['label'] as String,
                  color: item['color'] as Color,
                  route: item['route'] as Widget?,
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
  }) {
    return InkWell(
      onTap: () {
        if (route != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => route),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: color,
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
                color: Colors.grey.shade800,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}