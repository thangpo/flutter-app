import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TourDetailScreen extends StatelessWidget {
  final Map<String, dynamic> tour;

  const TourDetailScreen({super.key, required this.tour});

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

  String _getStatusLabel(BuildContext context, String status) {
    final statusMap = {
      'draft': getTranslated('draft', context) ?? 'Nháp',
      'unpaid': getTranslated('unpaid', context) ?? 'Chưa thanh toán',
      'processing': getTranslated('processing', context) ?? 'Đang xử lý',
      'confirmed': getTranslated('confirmed', context) ?? 'Đã xác nhận',
      'completed': getTranslated('completed', context) ?? 'Hoàn thành',
      'paid': getTranslated('paid', context) ?? 'Đã thanh toán',
      'partial_payment': getTranslated('partial_payment', context) ?? 'Thanh toán một phần',
      'cancelled': getTranslated('cancelled', context) ?? 'Đã hủy',
    };
    return statusMap[status] ?? status;
  }

  Color _getStatusColor(String status, bool isDarkMode) {
    final colorMap = {
      'draft': isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
      'unpaid': isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700,
      'processing': isDarkMode ? Colors.blue.shade300 : const Color(0xFF2196F3),
      'confirmed': isDarkMode ? Colors.teal.shade300 : Colors.teal.shade600,
      'completed': isDarkMode ? Colors.green.shade300 : Colors.green.shade600,
      'paid': isDarkMode ? Colors.green.shade300 : Colors.green.shade700,
      'partial_payment': isDarkMode ? Colors.purple.shade300 : Colors.purple.shade600,
      'cancelled': isDarkMode ? Colors.red.shade300 : Colors.red.shade600,
    };
    return colorMap[status] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeController>(context).darkTheme;
    final primaryBlue = isDarkMode ? Theme.of(context).primaryColorDark : const Color(0xFF1976D2);
    final lightBlue = isDarkMode ? Theme.of(context).primaryColorLight : const Color(0xFF2196F3);
    final paleBlue = isDarkMode ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFE3F2FD);
    final accentBlue = isDarkMode ? Theme.of(context).primaryColor : const Color(0xFF1E88E5);

    final service = tour['service'] ?? {};
    final status = tour['status'] ?? 'unknown';
    final statusColor = _getStatusColor(status, isDarkMode);

    return Scaffold(
      backgroundColor: paleBlue,
      appBar: AppBar(
        title: Text(
          service['title'] ?? getTranslated('tour_details', context) ?? 'Chi tiết tour',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: isDarkMode ? Theme.of(context).colorScheme.onPrimary : Colors.white,
          ),
        ),
        backgroundColor: primaryBlue,
        foregroundColor: isDarkMode ? Theme.of(context).colorScheme.onPrimary : Colors.white,
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryBlue, lightBlue],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryBlue, lightBlue],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(isDarkMode ? 0.4 : 0.3),
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
                      color: isDarkMode
                          ? Theme.of(context).cardColor.withOpacity(0.3)
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: tour['code'] ?? 'N/A',
                      version: QrVersions.auto,
                      size: 100.0,
                      backgroundColor: isDarkMode ? Theme.of(context).cardColor : Colors.white,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: isDarkMode ? Theme.of(context).colorScheme.onSurface : Colors.black,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: isDarkMode ? Theme.of(context).colorScheme.onSurface : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tour['code'] ?? 'N/A',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Theme.of(context).colorScheme.onPrimary : Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Theme.of(context).cardColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusLabel(context, status),
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
                  _buildSectionCard(
                    context,
                    icon: Icons.explore_outlined,
                    title: getTranslated('tour_information', context) ?? 'Thông tin tour',
                    iconColor: primaryBlue,
                    isDarkMode: isDarkMode,
                    paleBlue: paleBlue,
                    primaryBlue: primaryBlue,
                    lightBlue: lightBlue,
                    children: [
                      _buildInfoRow(
                        context: context,
                        icon: Icons.badge_outlined,
                        label: getTranslated('tour_name', context) ?? 'Tên tour',
                        value: service['title'],
                        isDarkMode: isDarkMode,
                        primaryBlue: primaryBlue,
                      ),
                      _buildInfoRow(
                        context: context,
                        icon: Icons.calendar_today_outlined,
                        label: getTranslated('start_date', context) ?? 'Ngày bắt đầu',
                        value: _formatDate(tour['start_date'] ?? ''),
                        isDarkMode: isDarkMode,
                        primaryBlue: primaryBlue,
                      ),
                      _buildInfoRow(
                        context: context,
                        icon: Icons.event_outlined,
                        label: getTranslated('end_date', context) ?? 'Ngày kết thúc',
                        value: _formatDate(tour['end_date'] ?? ''),
                        isDarkMode: isDarkMode,
                        primaryBlue: primaryBlue,
                      ),
                      _buildInfoRow(
                        context: context,
                        icon: Icons.payments_outlined,
                        label: getTranslated('total_amount', context) ?? 'Tổng tiền',
                        value: _formatMoney(tour['total']?.toString() ?? '0'),
                        valueStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Theme.of(context).colorScheme.onPrimary : primaryBlue,
                        ),
                        isDarkMode: isDarkMode,
                        primaryBlue: primaryBlue,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildSectionCard(
                    context,
                    icon: Icons.person_outline,
                    title: getTranslated('customer_information', context) ?? 'Thông tin khách hàng',
                    iconColor: accentBlue,
                    isDarkMode: isDarkMode,
                    paleBlue: paleBlue,
                    primaryBlue: primaryBlue,
                    lightBlue: lightBlue,
                    children: [
                      _buildInfoRow(
                        context: context,
                        icon: Icons.person,
                        label: getTranslated('full_name', context) ?? 'Họ và tên',
                        value: '${tour['first_name'] ?? ''} ${tour['last_name'] ?? ''}'.trim(),
                        isDarkMode: isDarkMode,
                        primaryBlue: primaryBlue,
                      ),
                      _buildInfoRow(
                        context: context,
                        icon: Icons.email_outlined,
                        label: getTranslated('email', context) ?? 'Email',
                        value: tour['email'],
                        isDarkMode: isDarkMode,
                        primaryBlue: primaryBlue,
                      ),
                      _buildInfoRow(
                        context: context,
                        icon: Icons.phone_outlined,
                        label: getTranslated('phone', context) ?? 'Điện thoại',
                        value: tour['phone'],
                        isDarkMode: isDarkMode,
                        primaryBlue: primaryBlue,
                      ),
                      _buildInfoRow(
                        context: context,
                        icon: Icons.location_on_outlined,
                        label: getTranslated('address', context) ?? 'Địa chỉ',
                        value: '${tour['address'] ?? ''}, ${tour['city'] ?? ''}'.trim(),
                        isDarkMode: isDarkMode,
                        primaryBlue: primaryBlue,
                      ),
                      _buildInfoRow(
                        context: context,
                        icon: Icons.public_outlined,
                        label: getTranslated('country', context) ?? 'Quốc gia',
                        value: tour['country'],
                        isDarkMode: isDarkMode,
                        primaryBlue: primaryBlue,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildSectionCard(
                    context,
                    icon: Icons.note_outlined,
                    title: getTranslated('notes_special_requests', context) ?? 'Ghi chú / Yêu cầu đặc biệt',
                    iconColor: isDarkMode ? Colors.teal.shade300 : Colors.teal.shade600,
                    isDarkMode: isDarkMode,
                    paleBlue: paleBlue,
                    primaryBlue: primaryBlue,
                    lightBlue: lightBlue,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Theme.of(context).cardColor.withOpacity(0.7)
                              : paleBlue.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode
                                ? lightBlue.withOpacity(0.5)
                                : lightBlue.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          tour['customer_notes']?.toString().isNotEmpty == true
                              ? tour['customer_notes']
                              : getTranslated('no_notes', context) ?? 'Không có ghi chú',
                          style: TextStyle(
                            fontSize: 15,
                            color: tour['customer_notes']?.toString().isNotEmpty == true
                                ? (isDarkMode ? Theme.of(context).colorScheme.onPrimary : Colors.grey.shade800)
                                : (isDarkMode ? Theme.of(context).hintColor : Colors.grey.shade500),
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
        required bool isDarkMode,
        required Color paleBlue,
        required Color primaryBlue,
        required Color lightBlue,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Theme.of(context).primaryColorDark.withOpacity(0.2)
                : primaryBlue.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Theme.of(context).primaryColorDark.withOpacity(0.3)
                  : paleBlue.withOpacity(0.5),
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
                    color: iconColor.withOpacity(isDarkMode ? 0.3 : 0.15),
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
                    color: isDarkMode ? Theme.of(context).colorScheme.onPrimary : primaryBlue,
                  ),
                ),
              ],
            ),
          ),
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
    required BuildContext context,
    required IconData icon,
    required String label,
    dynamic value,
    TextStyle? valueStyle,
    required bool isDarkMode,
    required Color primaryBlue,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: isDarkMode ? Theme.of(context).hintColor : Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Theme.of(context).hintColor : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? '-',
              style: valueStyle ??
                  TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Theme.of(context).colorScheme.onPrimary : Colors.black87,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}