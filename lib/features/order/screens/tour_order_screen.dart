import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/domain/services/tour_order_service.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'tour_detail_screen.dart';
import 'package:provider/provider.dart';
import 'qr_page.dart';

class TourOrderScreen extends StatefulWidget {
  const TourOrderScreen({super.key});

  @override
  State<TourOrderScreen> createState() => _TourOrderScreenState();
}

class _TourOrderScreenState extends State<TourOrderScreen> {
  bool _isLoading = true;
  List<dynamic> _tourOrders = [];
  String? _error;
  String? _selectedStatus;

  final TourOrderService _tourService = TourOrderService();

  final List<Map<String, String>> _statuses = [
    {"label": "all", "value": ""},
    {"label": "draft", "value": "draft"},
    {"label": "unpaid", "value": "unpaid"},
    {"label": "processing", "value": "processing"},
    {"label": "confirmed", "value": "confirmed"},
    {"label": "completed", "value": "completed"},
    {"label": "paid", "value": "paid"},
    {"label": "partial_payment", "value": "partial_payment"},
    {"label": "cancelled", "value": "cancelled"},
  ];

  @override
  void initState() {
    super.initState();
    _initAndFetchData();
  }

  Future<void> _initAndFetchData({String? status}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _tourService.init();
      final tours = await _tourService.fetchTourOrders(status: status);
      setState(() {
        _tourOrders = tours;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = getTranslated('error_loading_tours', context) ?? e.toString();
        _isLoading = false;
      });
    }
  }

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
      'draft': getTranslated('draft', context) ?? 'Nháp',
      'unpaid': getTranslated('unpaid', context) ?? 'Chưa thanh toán',
      'processing': getTranslated('processing', context) ?? 'Đang xử lý',
      'confirmed': getTranslated('confirmed', context) ?? 'Đã xác nhận',
      'completed': getTranslated('completed', context) ?? 'Hoàn thành',
      'paid': getTranslated('paid', context) ?? 'Đã thanh toán',
      'partial_payment': getTranslated('partial_payment', context) ?? 'Thanh toán một phần',
      'cancelled': getTranslated('cancelled', context) ?? 'Đã hủy',
    };
    return statusMap[status] ?? status.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeController>(context).darkTheme;
    final oceanBlue = isDarkMode ? Theme.of(context).primaryColorDark : const Color(0xFF006D9C);
    final lightOceanBlue = isDarkMode ? Theme.of(context).primaryColorLight : const Color(0xFF4DA8DA);
    final paleOceanBlue = isDarkMode ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFE3F2FD);
    final accentOcean = isDarkMode ? Theme.of(context).primaryColor : const Color(0xFF0097D3);

    return Scaffold(
      backgroundColor: paleOceanBlue,
      appBar: AppBar(
        title: Text(
          getTranslated('tour_order_history', context) ?? 'Lịch sử đặt tour',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: isDarkMode ? Theme.of(context).colorScheme.onPrimary : Colors.white,
          ),
        ),
        backgroundColor: oceanBlue,
        foregroundColor: isDarkMode ? Theme.of(context).colorScheme.onPrimary : Colors.white,
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
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Theme.of(context).cardColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: oceanBlue.withOpacity(isDarkMode ? 0.2 : 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDarkMode ? oceanBlue.withOpacity(0.3) : paleOceanBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.filter_list_rounded,
                    color: isDarkMode
                        ? Theme.of(context).colorScheme.onPrimary
                        : oceanBlue,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus ?? "",
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: lightOceanBlue),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: lightOceanBlue.withOpacity(isDarkMode ? 0.3 : 0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: oceanBlue, width: 2),
                      ),
                      labelText:
                      getTranslated('filter_by_status', context) ?? "Lọc theo trạng thái",
                      labelStyle: TextStyle(
                        color: isDarkMode
                            ? Theme.of(context).hintColor
                            : oceanBlue,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor:
                      paleOceanBlue.withOpacity(isDarkMode ? 0.5 : 0.3),
                    ),
                    dropdownColor:
                    isDarkMode ? Theme.of(context).cardColor : Colors.white,
                    items: _statuses.map((status) {
                      return DropdownMenuItem<String>(
                        value: status["value"]!,
                        child: Text(
                          getTranslated(status["label"]!, context) ?? status["label"]!,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? Theme.of(context).colorScheme.onPrimary
                                : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedStatus = value ?? "");
                      _initAndFetchData(status: value);
                    },
                  ),
                ),

                const SizedBox(width: 12),

                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QrPage(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDarkMode ? oceanBlue.withOpacity(0.3) : paleOceanBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      color: isDarkMode
                          ? Theme.of(context).colorScheme.onPrimary
                          : oceanBlue,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(oceanBlue),
                strokeWidth: 3,
              ),
            )
                : _error != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : _tourOrders.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sailing_outlined,
                      size: 80, color: isDarkMode ? Theme.of(context).hintColor : lightOceanBlue),
                  const SizedBox(height: 16),
                  Text(
                    getTranslated('no_orders_found', context) ?? "Không có đơn hàng nào",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Theme.of(context).hintColor : Colors.grey,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _tourOrders.length,
              itemBuilder: (context, index) {
                final item = _tourOrders[index];
                final service = item['service'] ?? {};
                final title = service['title'] ?? getTranslated('undefined_tour', context) ?? 'Tour không xác định';
                final startDate = item['start_date'] ?? '';
                final total = item['total'] ?? '0';
                final status = item['status'] ?? 'unknown';

                final colorMap = {
                  'draft': isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  'unpaid': isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700,
                  'processing': lightOceanBlue,
                  'confirmed': isDarkMode ? Colors.teal.shade300 : Colors.teal.shade600,
                  'completed': isDarkMode ? Colors.green.shade300 : Colors.green.shade600,
                  'paid': isDarkMode ? Colors.green.shade300 : Colors.green.shade700,
                  'partial_payment': isDarkMode ? Colors.purple.shade300 : Colors.purple.shade600,
                  'cancelled': isDarkMode ? Colors.red.shade300 : Colors.red.shade600,
                };

                final statusColor = colorMap[status] ?? Colors.grey;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Theme.of(context).cardColor : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: oceanBlue.withOpacity(isDarkMode ? 0.2 : 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TourDetailScreen(tour: item),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [oceanBlue, lightOceanBlue],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: oceanBlue.withOpacity(isDarkMode ? 0.4 : 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.beach_access_rounded,
                                color: isDarkMode ? Theme.of(context).colorScheme.onPrimary : Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isDarkMode ? Theme.of(context).colorScheme.onPrimary : oceanBlue,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_outlined,
                                          size: 14,
                                          color: isDarkMode
                                              ? Theme.of(context).hintColor
                                              : Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(startDate),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDarkMode
                                              ? Theme.of(context).hintColor
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.payments_outlined,
                                          size: 14,
                                          color: isDarkMode
                                              ? Theme.of(context).hintColor
                                              : Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatMoney(total),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDarkMode
                                              ? Theme.of(context).colorScheme.onPrimary
                                              : oceanBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(isDarkMode ? 0.3 : 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: statusColor.withOpacity(isDarkMode ? 0.5 : 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _getStatusLabel(status),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}