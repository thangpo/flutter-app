import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

class QrPage extends StatefulWidget {
  const QrPage({super.key});

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  late final MobileScannerController _controller;
  final List<Map<String, dynamic>> _bookings = [];
  final List<Map<String, dynamic>> _filteredBookings = [];
  bool _isProcessing = false;
  bool _isCameraActive = true;
  String? _lastScannedCode;
  DateTime? _lastScanTime;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    _filteredBookings.addAll(_bookings);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _scanQrCode(String code) async {
    final now = DateTime.now();
    if (_lastScannedCode == code &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!) < const Duration(seconds: 3)) {
      return;
    }

    if (_bookings.any((b) => b['code'] == code)) {
      _showSnackBar(
        getTranslated('already_scanned', context) ?? 'Mã đã được quét',
        Colors.orange,
      );
      return;
    }

    _lastScannedCode = code;
    _lastScanTime = now;

    setState(() {
      _isProcessing = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://vietnamtoure.com/api/bookings/info/$code'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final bookingData = data['data'] as Map<String, dynamic>;
          setState(() {
            _bookings.insert(0, bookingData);
            _applyFilter();
          });
          _showSnackBar(
            getTranslated('scan_success', context) ?? 'Quét thành công',
            Colors.green,
          );
        } else {
          _showErrorDialog(
            getTranslated('invalid_qr_code', context) ?? 'Mã QR không hợp lệ',
          );
        }
      } else if (response.statusCode == 404) {
        _showErrorDialog(
          getTranslated('booking_not_found', context) ?? 'Không tìm thấy đơn hàng',
        );
      } else {
        _showErrorDialog(
          getTranslated('api_error', context) ?? 'Lỗi từ máy chủ',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(
        getTranslated('network_error', context) ?? 'Lỗi kết nối mạng',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getTranslated('error', context) ?? 'Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(getTranslated('ok', context) ?? 'OK'),
          ),
        ],
      ),
    );
  }

  void _clearBookings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getTranslated('confirm', context) ?? 'Xác nhận'),
        content: Text(
          getTranslated('clear_all_bookings', context) ??
              'Xóa tất cả đơn hàng đã quét?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(getTranslated('cancel', context) ?? 'Hủy'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _bookings.clear();
                _filteredBookings.clear();
                _lastScannedCode = null;
                _lastScanTime = null;
                _selectedFilter = 'all';
              });
              Navigator.pop(context);
            },
            child: Text(
              getTranslated('delete', context) ?? 'Xóa',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleCamera() {
    setState(() {
      _isCameraActive = !_isCameraActive;
    });
  }

  void _applyFilter([String? filter]) {
    setState(() {
      _selectedFilter = filter ?? _selectedFilter;
      if (_selectedFilter == 'all') {
        _filteredBookings.clear();
        _filteredBookings.addAll(_bookings);
      } else {
        _filteredBookings.clear();
        _filteredBookings.addAll(
          _bookings.where((b) {
            final status = b['status']?.toString().toLowerCase() ?? '';
            return status == _selectedFilter;
          }).toList(),
        );
      }
    });
  }

  int _countByStatus(String status) {
    return _bookings.where((b) {
      final s = b['status']?.toString().toLowerCase() ?? '';
      return s == status.toLowerCase();
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final total = _bookings.length;
    final unpaidCount = _countByStatus('unpaid');
    final completedCount = _countByStatus('completed');
    final cancelledCount = _countByStatus('cancelled');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          getTranslated('scan_qr_code', context) ?? 'Quét mã QR đơn hàng',
        ),
        actions: [
          IconButton(
            icon: Icon(_isCameraActive ? Icons.camera_alt : Icons.camera_alt_outlined),
            onPressed: _toggleCamera,
            tooltip: _isCameraActive
                ? (getTranslated('disable_camera', context) ?? 'Tắt camera')
                : (getTranslated('enable_camera', context) ?? 'Bật camera'),
          ),
          if (_bookings.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearBookings,
              tooltip: getTranslated('clear_all', context) ?? 'Xóa tất cả',
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isCameraActive)
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: (BarcodeCapture capture) {
                      if (_isProcessing) return;
                      final barcode = capture.barcodes.first;
                      if (barcode.rawValue != null) {
                        _scanQrCode(barcode.rawValue!.trim());
                      }
                    },
                  ),
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (_isProcessing)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Đang xử lý...'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.grey[200],
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.list_alt, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${getTranslated('scanned_bookings', context) ?? 'Đơn hàng đã quét'}: $total',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tất cả', 'all', total, Colors.blueAccent),
                      _buildFilterChip('Chưa thanh toán', 'unpaid', unpaidCount, Colors.yellow[700]!),
                      _buildFilterChip('Hoàn thành', 'completed', completedCount, Colors.green),
                      _buildFilterChip('Hủy', 'cancelled', cancelledCount, Colors.red),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: _isCameraActive ? 1 : 3,
            child: _filteredBookings.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _bookings.isEmpty
                        ? (getTranslated('no_scanned_bookings', context) ??
                        'Chưa quét được đơn hàng nào')
                        : (getTranslated('no_results', context) ?? 'Không có kết quả'),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _filteredBookings.length,
              itemBuilder: (context, index) {
                final booking = _filteredBookings[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(booking['status']),
                      child: Text(
                        _getInitial(booking['code']),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      '${booking['first_name'] ?? ''} ${booking['last_name'] ?? ''}'.trim(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            Icons.confirmation_number,
                            'Mã: ${booking['code'] ?? ''}',
                          ),
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Ngày: ${booking['start_date'] ?? ''}',
                          ),
                          _buildInfoRow(
                            Icons.info_outline,
                            'Trạng thái: ${booking['status'] ?? ''}',
                          ),
                          _buildInfoRow(
                            Icons.phone,
                            'SĐT: ${booking['phone'] ?? ''}',
                          ),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showBookingDetails(booking);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filter, int count, Color color) {
    final isSelected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: count > 0
            ? (selected) {
          _applyFilter(filter);
        }
            : null,
        selectedColor: color.withOpacity(0.2),
        checkmarkColor: color,
        labelStyle: TextStyle(
          color: isSelected ? color : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.grey[300],
        disabledColor: Colors.grey[400],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitial(dynamic code) {
    if (code == null) return '?';
    final str = code.toString();
    return str.isNotEmpty ? str[0].toUpperCase() : '?';
  }

  Color _getStatusColor(dynamic status) {
    final statusStr = status?.toString().toLowerCase() ?? '';
    switch (statusStr) {
      case 'completed':
        return Colors.green;
      case 'unpaid':
        return Colors.yellow[700]!;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blueAccent;
    }
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              const Center(
                child: Text(
                  'Chi tiết đơn hàng',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 32),
              ...booking.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        '${entry.key}:',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: Text(entry.value?.toString() ?? 'N/A'),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}