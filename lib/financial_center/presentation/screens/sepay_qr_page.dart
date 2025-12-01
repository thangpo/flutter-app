import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sepay_payment_service.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

class SepayQrPage extends StatefulWidget {
  final Map<String, dynamic> paymentData;
  const SepayQrPage({super.key, required this.paymentData});

  @override
  State<SepayQrPage> createState() => _SepayQrPageState();
}

class _SepayQrPageState extends State<SepayQrPage>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  Timer? _countdownTimer;
  bool _isPaid = false;
  int _remainingSeconds = 600;

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  late final SepayPaymentService _sepayService;

  @override
  void initState() {
    super.initState();

    _sepayService = SepayPaymentService();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _startPolling();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (Timer timer) {
          if (!mounted) return;
          setState(() {
            if (_remainingSeconds > 0) {
              _remainingSeconds--;
            } else {
              _remainingSeconds = 600;
            }
          });
        });
  }

  String _formatCountdown(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _startPolling() {
    final orderCode = widget.paymentData['order_code'];
    if (orderCode == null || orderCode.toString().isEmpty) return;

    _timer = Timer.periodic(const Duration(seconds: 8), (_) async {
      try {
        final result =
        await _sepayService.checkBookingStatus(orderCode.toString());

        debugPrint('Status code: ${result['http_status']}');
        debugPrint('Response data: ${result['raw']}');

        final String bookingStatus = result['booking_status'] as String;

        if (result['status'] == true &&
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
    if (orderCode == null || orderCode.toString().isEmpty) {
      Navigator.pop(context, false);
      return;
    }

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

      final Response response =
      await _sepayService.cancelBooking(orderCode.toString());

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
        Navigator.pop(context, false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_isPaid) {
      return true;
    }

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
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFD32F2F),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                getTranslated('cancel_payment_title', context) ??
                    'Hủy thanh toán?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                getTranslated('cancel_payment_message', context) ??
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
                      child: Text(
                        getTranslated('continue', context) ?? 'Tiếp tục',
                        style: const TextStyle(
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
                      child: Text(
                        getTranslated('cancel_order', context) ?? 'Hủy đơn',
                        style: const TextStyle(
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
      return false;
    }

    return false;
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
              Text(
                getTranslated('payment_success', context) ??
                    'Thanh toán thành công!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                getTranslated('payment_success_desc', context) ??
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
                  child: Text(
                    getTranslated('done', context) ?? 'Hoàn tất',
                    style: const TextStyle(
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
    _countdownTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Provider.of<ThemeController>(context, listen: true);
    final isDark = themeCtrl.darkTheme;

    final qrUrl = widget.paymentData['qr_link'] ?? '';
    final orderCode = widget.paymentData['order_code'] ?? '';
    final amount = widget.paymentData['amount'] ?? 0;

    final storeName = widget.paymentData['store_name'] ??
        widget.paymentData['merchant_name'] ??
        '';
    final customerName = widget.paymentData['customer_name'] ??
        widget.paymentData['customer'] ??
        '';
    final phone = widget.paymentData['phone'] ?? '';

    final tourImage = widget.paymentData['tour_image'] ??
        widget.paymentData['image'] ??
        '';

    final Color primaryBlue = const Color(0xFF007BFF);
    final Color cardColor =
    isDark ? const Color(0xFF111827) : Colors.white.withOpacity(0.98);

    debugPrint('QR URL: $qrUrl');
    debugPrint('Order Code: $orderCode');

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.black,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Text(
            getTranslated('sepay_payment', context) ??
                'Thanh toán qua SePay',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: tourImage.toString().isNotEmpty
                  ? Image.network(
                tourImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.red.shade700,
                ),
              )
                  : Container(color: Colors.red.shade700),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(isDark ? 0.6 : 0.45),
              ),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                getTranslated('scan_this_qr', context) ??
                                    'Quý khách vui lòng quét mã này',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF212121),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${getTranslated('auto_update_after', context) ?? 'Tự động cập nhật sau'}  ${_formatCountdown(_remainingSeconds)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 16),

                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale:
                                    _isPaid ? 1.0 : _pulseAnimation.value,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                        BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withOpacity(0.08),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: qrUrl.toString().isNotEmpty
                                          ? ClipRRect(
                                        borderRadius:
                                        BorderRadius.circular(12),
                                        child: Image.network(
                                          Uri.encodeFull(
                                              qrUrl.toString()),
                                          width: 220,
                                          height: 220,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error,
                                              stackTrace) =>
                                              SizedBox(
                                                width: 220,
                                                height: 220,
                                                child: Column(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .center,
                                                  children: const [
                                                    Icon(
                                                      Icons.error_outline,
                                                      size: 48,
                                                      color: Colors.red,
                                                    ),
                                                    SizedBox(height: 8),
                                                    Text(
                                                      'Không thể tải mã QR',
                                                      style: TextStyle(
                                                          color:
                                                          Colors.red),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                        ),
                                      )
                                          : SizedBox(
                                        width: 220,
                                        height: 220,
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment
                                              .center,
                                          children: const [
                                            Icon(
                                              Icons.qr_code_2_outlined,
                                              size: 56,
                                              color: Colors.grey,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Không có mã QR',
                                              style: TextStyle(
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 20),
                              const Divider(height: 1),
                              const SizedBox(height: 12),

                              if (storeName.toString().isNotEmpty)
                                _buildInfoRow(
                                  label: getTranslated('store', context) ??
                                      'Cửa hàng',
                                  value: storeName.toString(),
                                  isDark: isDark,
                                ),
                              if (customerName.toString().isNotEmpty)
                                _buildInfoRow(
                                  label:
                                  getTranslated('customer', context) ??
                                      'Khách hàng',
                                  value: customerName.toString(),
                                  isDark: isDark,
                                ),
                              if (phone.toString().isNotEmpty)
                                _buildInfoRow(
                                  label:
                                  getTranslated('phone', context) ??
                                      'SĐT',
                                  value: phone.toString(),
                                  isDark: isDark,
                                ),
                              _buildInfoRow(
                                label:
                                getTranslated('transfer_amount', context) ??
                                    'Số tiền chuyển khoản',
                                value: '${_formatCurrency(amount)} ₫',
                                isDark: isDark,
                                highlight: true,
                                highlightColor: primaryBlue,
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                label: getTranslated('transaction_code',
                                    context) ??
                                    'Mã giao dịch',
                                value: orderCode.toString(),
                                isDark: isDark,
                              ),

                              const SizedBox(height: 20),
                              Container(
                                padding:
                                const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.grey.shade100,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet_outlined,
                                      color: primaryBlue,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'SePay',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        if (!_isPaid)
                          Text(
                            getTranslated(
                                'waiting_for_payment', context) ??
                                'Đang chờ thanh toán... Vui lòng quét mã bằng ứng dụng ngân hàng.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.85),
                            ),
                            textAlign: TextAlign.center,
                          )
                        else
                          Text(
                            getTranslated(
                                'paid_status_label', context) ??
                                'Đã nhận thanh toán, bạn có thể quay lại ứng dụng.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.greenAccent.shade100,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required bool isDark,
    bool highlight = false,
    Color? highlightColor,
  }) {
    final Color labelColor =
    isDark ? Colors.white70 : Colors.grey.shade600;
    final Color valueColor = highlight
        ? (highlightColor ?? const Color(0xFF007BFF))
        : (isDark ? Colors.white : const Color(0xFF212121));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: labelColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic amount) {
    final value =
    amount is int ? amount : int.tryParse(amount.toString()) ?? 0;
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }
}