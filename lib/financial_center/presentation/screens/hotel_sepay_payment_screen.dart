import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'hotel_checkout_screen.dart';
import 'hotel_booking_bill_screen.dart'; // 👈 THÊM IMPORT NÀY
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class HotelSepayPaymentScreen extends StatefulWidget {
  final HotelCheckoutData data;

  final String bookingCode;
  final String paymentId;
  final double amount;
  final String qrLink;
  final String bankAccount;
  final String bankName;
  final String accountName;
  final String transferContent;

  // thông tin người đặt
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String country;
  final String specialRequest;

  const HotelSepayPaymentScreen({
    super.key,
    required this.data,
    required this.bookingCode,
    required this.paymentId,
    required this.amount,
    required this.qrLink,
    required this.bankAccount,
    required this.bankName,
    required this.accountName,
    required this.transferContent,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.country,
    required this.specialRequest,
  });

  @override
  State<HotelSepayPaymentScreen> createState() =>
      _HotelSepayPaymentScreenState();
}

class _HotelSepayPaymentScreenState extends State<HotelSepayPaymentScreen> {
  bool _checkingStatus = false;
  String? _currentStatus;

  Timer? _timer;
  bool _isPaid = false;

  String _formatVnd(num v) {
    final f = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return f.format(v);
  }

  @override
  void initState() {
    super.initState();
    _startAutoCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ================== AUTO CHECK GIỐNG TOUR ==================

  void _startAutoCheck() {
    final code = widget.bookingCode;

    _timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_isPaid) return;

      try {
        final dio = Dio();
        final response = await dio.get(
          '${AppConstants.travelBaseUrl}/bookings/check/$code',
          options: Options(
            headers: const {'Accept': 'application/json'},
          ),
        );

        if (response.statusCode == 200 && response.data['status'] == true) {
          final status = (response.data['booking_status'] ?? '')
              .toString()
              .toLowerCase();

          if (['paid', 'completed', 'confirmed'].contains(status)) {
            if (!mounted) return;

            setState(() {
              _isPaid = true;
              _currentStatus = status;
            });

            _timer?.cancel();
            _showPaidDialog(status); // 👈 TRUYỀN STATUS VÀO
          }
        }
      } catch (e) {
        // im lặng, tránh spam lỗi – user có thể bấm nút check tay
      }
    });
  }

  // ================== KHI ĐÃ THANH TOÁN THÀNH CÔNG ==================

  void _showPaidDialog(String status) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Thanh toán thành công'),
          ],
        ),
        content: const Text(
          'Cảm ơn bạn! Hệ thống đã ghi nhận thanh toán cho đơn đặt phòng này.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              // đóng dialog
              Navigator.of(dialogCtx).pop();

              // chuyển sang màn BILL, thay thế luôn màn SePay
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => HotelBookingBillScreen(
                    data: widget.data,
                    bookingCode: widget.bookingCode,
                    bookingStatus: status,          // 'paid' / 'completed'
                    paymentMethod: 'sepay',
                    createdAt: DateTime.now(),      // hoặc fetch lại từ API nếu bố muốn chuẩn tuyệt đối

                    firstName: widget.firstName,
                    lastName: widget.lastName,
                    email: widget.email,
                    phone: widget.phone,
                    address: widget.address,
                    city: widget.city,
                    country: widget.country,
                    specialRequest: widget.specialRequest,
                  ),
                ),
              );
            },
            child: const Text('Hoàn tất'),
          ),
        ],
      ),
    );
  }

  // ================== TIỆN ÍCH ==================

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã copy $label'),
      ),
    );
  }

  // ================== CHECK TAY KHI USER BẤM NÚT ==================

  Future<void> _checkPaymentStatus() async {
    setState(() {
      _checkingStatus = true;
    });

    try {
      final dio = Dio();
      final response = await dio.get(
        '${AppConstants.travelBaseUrl}/bookings/check/${widget.bookingCode}',
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        final status =
        (response.data['booking_status'] ?? '').toString().toLowerCase();

        setState(() {
          _currentStatus = status;
        });

        String humanStatus;
        Color color;
        switch (status) {
          case 'completed':
          case 'paid':
          case 'confirmed':
            humanStatus = 'Đã thanh toán';
            color = Colors.green;
            break;
          case 'unpaid':
            humanStatus = 'Chưa thanh toán';
            color = Colors.red;
            break;
          case 'processing':
            humanStatus = 'Đang xử lý';
            color = Colors.orange;
            break;
          default:
            humanStatus = status.isEmpty ? 'Không xác định' : status;
            color = Colors.grey;
        }

        if (['paid', 'completed', 'confirmed'].contains(status)) {
          _timer?.cancel();
          _isPaid = true;
          if (mounted) {
            _showPaidDialog(status); // 👈 TRUYỀN STATUS VÀO
          }
        } else {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Trạng thái thanh toán'),
              content: Text(humanStatus),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không kiểm tra được trạng thái: ${response.data['message'] ?? ''}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi kiểm tra trạng thái: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _checkingStatus = false;
        });
      }
    }
  }

  // ================== UI ==================

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán qua SePay'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tóm tắt đơn
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.hotelName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dateFmt.format(data.checkIn)} - '
                          '${dateFmt.format(data.checkOut)} • ${data.nights} đêm',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.adults} người lớn, ${data.children} trẻ em',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Mã đơn đặt phòng',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _copyToClipboard(
                            widget.bookingCode,
                            'mã đơn',
                          ),
                          child: Row(
                            children: [
                              Text(
                                widget.bookingCode,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.copy,
                                size: 16,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Số tiền cần thanh toán',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          _formatVnd(widget.amount),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // QR thanh toán
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Quét mã QR để thanh toán',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mở app ngân hàng bất kỳ, chọn quét QR VietQR\n'
                          'Sau đó kiểm tra đúng SỐ TIỀN và NỘI DUNG chuyển khoản.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          color: Colors.white,
                          child: widget.qrLink.isNotEmpty
                              ? Image.network(
                            widget.qrLink,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                            const Center(
                              child: Text('Không tải được QR'),
                            ),
                          )
                              : const Center(
                            child: Text('Không có QR'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Thông tin chuyển khoản
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin chuyển khoản',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      label: 'Ngân hàng',
                      value: widget.bankName,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      label: 'Số tài khoản',
                      value: widget.bankAccount,
                      copyLabel: 'số tài khoản',
                      onCopy: () => _copyToClipboard(
                        widget.bankAccount,
                        'số tài khoản',
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      label: 'Chủ tài khoản',
                      value: widget.accountName,
                      copyLabel: 'tên chủ tài khoản',
                      onCopy: () => _copyToClipboard(
                        widget.accountName,
                        'tên chủ tài khoản',
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      label: 'Số tiền',
                      value: _formatVnd(widget.amount),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      label: 'Nội dung chuyển khoản',
                      value: widget.transferContent,
                      copyLabel: 'nội dung chuyển khoản',
                      onCopy: () => _copyToClipboard(
                        widget.transferContent,
                        'nội dung chuyển khoản',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Lưu ý: Vui lòng chuyển đúng SỐ TIỀN và NỘI DUNG để hệ thống tự động ghi nhận thanh toán.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Nút kiểm tra trạng thái
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _checkingStatus ? null : _checkPaymentStatus,
                icon: _checkingStatus
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.refresh),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child:
                  Text('Tôi đã chuyển khoản, kiểm tra trạng thái'),
                ),
              ),
            ),

            if (_currentStatus != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Trạng thái hiện tại: ${_currentStatus!}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    String? copyLabel,
    VoidCallback? onCopy,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onCopy != null)
                IconButton(
                  icon: const Icon(
                    Icons.copy,
                    size: 18,
                  ),
                  onPressed: onCopy,
                  tooltip: 'Copy ${copyLabel ?? ''}',
                ),
            ],
          ),
        ),
      ],
    );
  }
}