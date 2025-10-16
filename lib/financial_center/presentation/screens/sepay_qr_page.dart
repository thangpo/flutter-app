import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class SepayQrPage extends StatefulWidget {
  final Map<String, dynamic> paymentData;
  const SepayQrPage({super.key, required this.paymentData});

  @override
  State<SepayQrPage> createState() => _SepayQrPageState();
}

class _SepayQrPageState extends State<SepayQrPage> with SingleTickerProviderStateMixin {
  Timer? _timer;
  bool _isPaid = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _startPolling();
  }

  void _startPolling() {
    final orderCode = widget.paymentData['order_code'];
    _timer = Timer.periodic(const Duration(seconds: 8), (_) async {
      try {
        final response = await Dio().get(
          'https://vietnamtoure.com/api/bookings/check/$orderCode',
          options: Options(headers: {'Accept': 'application/json'}),
        );

        debugPrint('Status code: ${response.statusCode}');
        debugPrint('Response data: ${response.data}');

        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;

        final bookingStatus = (data['booking_status'] ?? '').toString().toLowerCase();

        if (data['status'] == true &&
            ['paid', 'completed', 'confirmed'].contains(bookingStatus)) {
          setState(() => _isPaid = true);
          _timer?.cancel();
          _showPaidDialog();
        }
      } catch (e) {
        debugPrint('Error checking payment: $e');
      }
    });
  }

  Future<void> _cancelBooking() async {
    final orderCode = widget.paymentData['order_code'];
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
          ),
        ),
      );

      final response = await Dio().post(
        'https://vietnamtoure.com/api/bookings/cancel',
        data: {'order_code': orderCode},
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      debugPrint('Cancel response: ${response.data}');

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context, false);
      }
    } catch (e) {
      debugPrint('Error canceling booking: $e');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra khi hủy đơn hàng'),
            backgroundColor: Colors.red,
          ),
        );
        // Vẫn cho phép quay lại dù có lỗi
        Navigator.pop(context, false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_isPaid) {
      return true; // Cho phép quay lại nếu đã thanh toán
    }

    // Hiển thị dialog xác nhận hủy
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFD32F2F),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Hủy thanh toán?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Bạn có chắc chắn muốn hủy giao dịch này?\nĐơn hàng sẽ bị hủy.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF00BCD4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Tiếp tục',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00BCD4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Hủy đơn',
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
      ),
    );

    if (shouldCancel == true) {
      await _cancelBooking();
      return false; // Không cho pop ngay, đợi _cancelBooking xử lý
    }

    return false; // Không cho quay lại nếu người dùng chọn "Tiếp tục"
  }

  void _showPaidDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Thanh toán thành công!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Cảm ơn bạn!\nĐơn hàng đã được xác nhận thanh toán.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF00BCD4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Hoàn tất',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qrUrl = widget.paymentData['qr_link'] ?? '';
    final orderCode = widget.paymentData['order_code'] ?? '';
    final amount = widget.paymentData['amount'] ?? 0;

    debugPrint('QR URL: $qrUrl');
    debugPrint('Order Code: $orderCode');

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F9FA),
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'Thanh toán qua SePay',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF00BCD4),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF00BCD4), Color(0xFFF5F9FA)],
                    stops: [0.0, 0.3],
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    const Icon(
                      Icons.qr_code_scanner,
                      size: 48,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Quét mã QR để thanh toán',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sử dụng ứng dụng ngân hàng của bạn',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isPaid ? 1.0 : _pulseAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00BCD4).withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: qrUrl.isNotEmpty
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                Uri.encodeFull(qrUrl),
                                width: 280,
                                height: 280,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 280,
                                      height: 280,
                                      alignment: Alignment.center,
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.error_outline,
                                              size: 48, color: Colors.red),
                                          SizedBox(height: 12),
                                          Text(
                                            'Không thể tải mã QR',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                              ),
                            )
                                : Container(
                              width: 280,
                              height: 280,
                              alignment: Alignment.center,
                              child: const Text(
                                'Không có mã QR',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00BCD4).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payments, color: Colors.white, size: 28),
                              const SizedBox(width: 12),
                              const Text(
                                'Số tiền thanh toán',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${_formatCurrency(amount)} ₫',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00BCD4).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.receipt_long,
                              color: Color(0xFF00BCD4),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Mã giao dịch',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  orderCode,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF263238),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    if (!_isPaid)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF9E6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFE082)),
                        ),
                        child: Row(
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
                              strokeWidth: 3,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Đang chờ thanh toán...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF263238),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Vui lòng quét mã QR để hoàn tất',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 28),
                            SizedBox(width: 12),
                            Text(
                              'Đã thanh toán thành công',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(dynamic amount) {
    final value = amount is int ? amount : int.tryParse(amount.toString()) ?? 0;
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }
}