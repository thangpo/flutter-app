import 'package:flutter/material.dart';

class TourDetailScreen extends StatelessWidget {
  final Map<String, dynamic> tour;

  const TourDetailScreen({super.key, required this.tour});

  // Ocean blue color scheme
  static const Color oceanBlue = Color(0xFF006D9C);
  static const Color lightOceanBlue = Color(0xFF4DA8DA);
  static const Color paleOceanBlue = Color(0xFFE3F2FD);
  static const Color accentOcean = Color(0xFF0097D3);

  String _formatMoney(String amount) {
    try {
      final value = double.tryParse(amount) ?? 0;
      return "${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}₫";
    } catch (_) {
      return "$amount₫";
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (_) {
      return dateStr;
    }
  }

  String _getStatusLabel(String status) {
    final statusMap = {
      'draft': 'Nháp',
      'unpaid': 'Chưa thanh toán',
      'processing': 'Đang xử lý',
      'confirmed': 'Đã xác nhận',
      'completed': 'Hoàn thành',
      'paid': 'Đã thanh toán',
      'partial_payment': 'Thanh toán một phần',
      'cancelled': 'Đã hủy',
    };
    return statusMap[status] ?? status;
  }

  Color _getStatusColor(String status) {
    final colorMap = {
      'draft': Colors.grey.shade600,
      'unpaid': Colors.orange.shade700,
      'processing': lightOceanBlue,
      'confirmed': Colors.teal.shade600,
      'completed': Colors.green.shade600,
      'paid': Colors.green.shade700,
      'partial_payment': Colors.purple.shade600,
      'cancelled': Colors.red.shade600,
    };
    return colorMap[status] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final service = tour['service'] ?? {};
    final status = tour['status'] ?? 'unknown';
    final statusColor = _getStatusColor(status);

    return Scaffold(
      backgroundColor: paleOceanBlue,
      appBar: AppBar(
        title: Text(
          service['title'] ?? 'Chi tiết tour',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: oceanBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [oceanBlue, lightOceanBlue],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header card with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [oceanBlue, lightOceanBlue],
                ),
                boxShadow: [
                  BoxShadow(
                    color: oceanBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.confirmation_number_outlined,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tour['code'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusLabel(status),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Tour Information Card
                  _buildSectionCard(
                    context,
                    icon: Icons.explore_outlined,
                    title: 'Thông tin tour',
                    iconColor: oceanBlue,
                    children: [
                      _buildInfoRow(
                        icon: Icons.badge_outlined,
                        label: 'Tên tour',
                        value: service['title'],
                      ),
                      _buildInfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Ngày bắt đầu',
                        value: _formatDate(tour['start_date'] ?? ''),
                      ),
                      _buildInfoRow(
                        icon: Icons.event_outlined,
                        label: 'Ngày kết thúc',
                        value: _formatDate(tour['end_date'] ?? ''),
                      ),
                      _buildInfoRow(
                        icon: Icons.payments_outlined,
                        label: 'Tổng tiền',
                        value: _formatMoney(tour['total']?.toString() ?? '0'),
                        valueStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: oceanBlue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Customer Information Card
                  _buildSectionCard(
                    context,
                    icon: Icons.person_outline,
                    title: 'Thông tin khách hàng',
                    iconColor: accentOcean,
                    children: [
                      _buildInfoRow(
                        icon: Icons.person,
                        label: 'Họ và tên',
                        value: '${tour['first_name'] ?? ''} ${tour['last_name'] ?? ''}'.trim(),
                      ),
                      _buildInfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: tour['email'],
                      ),
                      _buildInfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Điện thoại',
                        value: tour['phone'],
                      ),
                      _buildInfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Địa chỉ',
                        value: '${tour['address'] ?? ''}, ${tour['city'] ?? ''}'.trim(),
                      ),
                      _buildInfoRow(
                        icon: Icons.public_outlined,
                        label: 'Quốc gia',
                        value: tour['country'],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Notes Card
                  _buildSectionCard(
                    context,
                    icon: Icons.note_outlined,
                    title: 'Ghi chú / Yêu cầu đặc biệt',
                    iconColor: Colors.teal.shade600,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: paleOceanBlue.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: lightOceanBlue.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          tour['customer_notes']?.toString().isNotEmpty == true
                              ? tour['customer_notes']
                              : 'Không có ghi chú',
                          style: TextStyle(
                            fontSize: 15,
                            color: tour['customer_notes']?.toString().isNotEmpty == true
                                ? Colors.grey.shade800
                                : Colors.grey.shade500,
                            fontStyle: tour['customer_notes']?.toString().isNotEmpty == true
                                ? FontStyle.normal
                                : FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required List<Widget> children,
        required Color iconColor,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: oceanBlue.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: paleOceanBlue.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: oceanBlue,
                  ),
                ),
              ],
            ),
          ),
          // Section content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    dynamic value,
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? '-',
              style: valueStyle ??
                  const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}