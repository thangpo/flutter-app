import 'dart:async';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'hotel_checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'hotel_booking_bill_screen.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

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
            _showPaidDialog(status);
          }
        }
      } catch (_) {}
    });
  }

  void _showPaidDialog(String status) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              getTranslated('payment_success', context) ??
                  'Thanh toán thành công',
            ),
          ],
        ),
        content: Text(
          getTranslated('payment_success_message', context) ??
              'Cảm ơn bạn! Hệ thống đã ghi nhận thanh toán cho đơn đặt phòng này.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => HotelBookingBillScreen(
                    data: widget.data,
                    bookingCode: widget.bookingCode,
                    bookingStatus: status,
                    paymentMethod: 'sepay',
                    createdAt: DateTime.now(),
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
            child: Text(
              getTranslated('finish', context) ?? 'Hoàn tất',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          (getTranslated('copied_label', context) ?? 'Đã copy') + ' $label',
        ),
      ),
    );
  }

  Future<void> _checkPaymentStatus() async {
    setState(() {
      _checkingStatus = true;
    });

    try {
      final dio = Dio();
      final response = await dio.get(
        '${AppConstants.travelBaseUrl}/bookings/check/${widget.bookingCode}',
        options: Options(
          headers: {'Accept': 'application/json'},
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
            humanStatus =
                getTranslated('status_paid', context) ?? 'Đã thanh toán';
            color = Colors.green;
            break;
          case 'unpaid':
            humanStatus =
                getTranslated('status_unpaid', context) ?? 'Chưa thanh toán';
            color = Colors.red;
            break;
          case 'processing':
            humanStatus =
                getTranslated('status_processing', context) ?? 'Đang xử lý';
            color = Colors.orange;
            break;
          default:
            humanStatus = status.isEmpty
                ? (getTranslated('status_unknown', context) ?? 'Không xác định')
                : status;
            color = Colors.grey;
        }

        if (['paid', 'completed', 'confirmed'].contains(status)) {
          _timer?.cancel();
          _isPaid = true;
          if (mounted) {
            _showPaidDialog(status);
          }
        } else {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(
                getTranslated('payment_status_title', context) ??
                    'Trạng thái thanh toán',
              ),
              content: Text(
                humanStatus,
                style: TextStyle(color: color),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    getTranslated('close', context) ?? 'Đóng',
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        if (!mounted) return;
        final msg = response.data['message'] ??
            (getTranslated('cannot_check_status', context) ??
                'Không kiểm tra được trạng thái');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (getTranslated('check_status_error', context) ??
                'Lỗi khi kiểm tra trạng thái') +
                ': $e',
          ),
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

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final dateFmt = DateFormat('dd/MM/yyyy');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color cardBg = theme.cardColor;
    final Color subtleText = isDark ? Colors.white70 : Colors.grey[700]!;
    final Color strongText = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      // chỉ giữ nút back, không có title
      appBar: AppBar(
        title: const SizedBox.shrink(),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. QR CARD – lên đầu tiên, giống hình bố gửi
            Card(
              color: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: isDark ? 0 : 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  children: [
                    Text(
                      getTranslated('scan_qr_to_pay', context) ??
                          'Scan QR to pay',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: strongText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      getTranslated('qr_instruction_text', context) ??
                          'Open any banking app, choose VietQR scanner,\nthen verify the AMOUNT and TRANSFER CONTENT.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtleText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          color: Colors.white,
                          child: widget.qrLink.isNotEmpty
                              ? Image.network(
                            widget.qrLink,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                getTranslated('qr_load_failed', context) ??
                                    'Không tải được QR',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                              : Center(
                            child: Text(
                              getTranslated(
                                  'no_qr_available', context) ??
                                  'Không có QR',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. Card khách sạn – đã sửa Booking code 2 dòng, không overflow
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                    const Color(0xFF1E293B),
                    const Color(0xFF020617),
                  ]
                      : [
                    const Color(0xFFE0F2FE),
                    const Color(0xFFFFFFFF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.hotel_rounded,
                        size: 26,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.hotelName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: strongText,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dateFmt.format(data.checkIn)} - '
                                '${dateFmt.format(data.checkOut)} • '
                                '${data.nights} ${getTranslated('nights', context) ?? 'nights'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: subtleText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${data.adults} ${getTranslated('adults', context) ?? 'adults'}, '
                                '${data.children} ${getTranslated('children', context) ?? 'children'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: subtleText,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Booking code: label dòng 1, code + icon dòng 2 (đã ellipsis)
                          Text(
                            getTranslated('booking_code', context) ??
                                'Booking code',
                            style: TextStyle(
                              fontSize: 12,
                              color: subtleText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.bookingCode,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blue,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _copyToClipboard(
                                  widget.bookingCode,
                                  getTranslated('booking_code', context) ??
                                      'mã đơn',
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.copy,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 3. Amount card
            Card(
              color: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: isDark ? 0 : 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        getTranslated('amount_to_pay', context) ??
                            'Amount to pay',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: strongText,
                        ),
                      ),
                    ),
                    Text(
                      _formatVnd(widget.amount),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 4. Bank info card
            Card(
              color: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: isDark ? 0 : 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslated('bank_transfer_info', context) ??
                          'Thông tin chuyển khoản',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: strongText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      label:
                      getTranslated('bank_name', context) ?? 'Ngân hàng',
                      value: widget.bankName,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      label:
                      getTranslated('bank_account_number', context) ??
                          'Số tài khoản',
                      value: widget.bankAccount,
                      copyLabel:
                      getTranslated('bank_account_number', context) ??
                          'số tài khoản',
                      onCopy: () => _copyToClipboard(
                        widget.bankAccount,
                        getTranslated('bank_account_number', context) ??
                            'số tài khoản',
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      label:
                      getTranslated('account_holder_name', context) ??
                          'Chủ tài khoản',
                      value: widget.accountName,
                      copyLabel:
                      getTranslated('account_holder_name', context) ??
                          'tên chủ tài khoản',
                      onCopy: () => _copyToClipboard(
                        widget.accountName,
                        getTranslated('account_holder_name', context) ??
                            'tên chủ tài khoản',
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      label: getTranslated('amount_label', context) ??
                          'Số tiền',
                      value: _formatVnd(widget.amount),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      label:
                      getTranslated('transfer_content', context) ??
                          'Nội dung chuyển khoản',
                      value: widget.transferContent,
                      copyLabel:
                      getTranslated('transfer_content', context) ??
                          'nội dung chuyển khoản',
                      onCopy: () => _copyToClipboard(
                        widget.transferContent,
                        getTranslated('transfer_content', context) ??
                            'nội dung chuyển khoản',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      getTranslated('transfer_note_text', context) ??
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

            // 5. Button check status
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
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    getTranslated('i_paid_check_status', context) ??
                        'Tôi đã chuyển khoản, kiểm tra trạng thái',
                  ),
                ),
              ),
            ),

            if (_currentStatus != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${getTranslated('current_status', context) ?? 'Trạng thái hiện tại'}: ${_currentStatus!}',
                  style: TextStyle(fontSize: 13, color: subtleText),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color labelColor = isDark ? Colors.white70 : Colors.grey[700]!;
    final Color valueColor = isDark ? Colors.white : Colors.black87;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: labelColor,
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
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