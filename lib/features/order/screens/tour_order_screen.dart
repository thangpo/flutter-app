import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/domain/services/tour_order_service.dart';
import 'tour_detail_screen.dart';

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

  static const Color oceanBlue = Color(0xFF006D9C);
  static const Color lightOceanBlue = Color(0xFF4DA8DA);
  static const Color paleOceanBlue = Color(0xFFE3F2FD);
  static const Color accentOcean = Color(0xFF0097D3);

  final List<Map<String, String>> _statuses = [
    {"label": "Tất cả", "value": ""},
    {"label": "Nháp", "value": "draft"},
    {"label": "Chưa thanh toán", "value": "unpaid"},
    {"label": "Đang xử lý", "value": "processing"},
    {"label": "Đã xác nhận", "value": "confirmed"},
    {"label": "Hoàn thành", "value": "completed"},
    {"label": "Đã thanh toán", "value": "paid"},
    {"label": "Thanh toán một phần", "value": "partial_payment"},
    {"label": "Đã hủy", "value": "cancelled"},
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
        _error = e.toString();
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
      'draft': 'Nháp',
      'unpaid': 'Chưa thanh toán',
      'processing': 'Đang xử lý',
      'confirmed': 'Đã xác nhận',
      'completed': 'Hoàn thành',
      'paid': 'Đã thanh toán',
      'partial_payment': 'Thanh toán 1 phần',
      'cancelled': 'Đã hủy',
    };
    return statusMap[status] ?? status.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paleOceanBlue,
      appBar: AppBar(
        title: const Text(
          'Lịch sử đặt tour',
          style: TextStyle(
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
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: oceanBlue.withOpacity(0.1),
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
                    color: paleOceanBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.filter_list_rounded,
                      color: oceanBlue, size: 24),
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
                        borderSide:
                            BorderSide(color: lightOceanBlue.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: oceanBlue, width: 2),
                      ),
                      labelText: "Lọc theo trạng thái",
                      labelStyle: TextStyle(color: oceanBlue),
                      isDense: true,
                      filled: true,
                      fillColor: paleOceanBlue.withOpacity(0.3),
                    ),
                    dropdownColor: Colors.white,
                    items: _statuses.map((status) {
                      return DropdownMenuItem<String>(
                        value: status["value"]!,
                        child: Text(
                          status["label"]!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedStatus = value ?? "");
                      _initAndFetchData(status: value);
                    },
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
                                size: 64, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 16),
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
                                    size: 80, color: lightOceanBlue),
                                const SizedBox(height: 16),
                                const Text(
                                  "Không có đơn hàng nào",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
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
                              final title =
                                  service['title'] ?? 'Tour không xác định';
                              final startDate = item['start_date'] ?? '';
                              final total = item['total'] ?? '0';
                              final status = item['status'] ?? 'unknown';

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

                              final statusColor =
                                  colorMap[status] ?? Colors.grey;

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
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
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              TourDetailScreen(tour: item),
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
                                                colors: [
                                                  oceanBlue,
                                                  lightOceanBlue
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: oceanBlue
                                                      .withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.beach_access_rounded,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  title,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: oceanBlue,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                        Icons
                                                            .calendar_today_outlined,
                                                        size: 14,
                                                        color: Colors
                                                            .grey.shade600),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _formatDate(startDate),
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors
                                                            .grey.shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                        Icons.payments_outlined,
                                                        size: 14,
                                                        color: Colors
                                                            .grey.shade600),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _formatMoney(total),
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: oceanBlue,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Status badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  statusColor.withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: statusColor
                                                    .withOpacity(0.3),
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
