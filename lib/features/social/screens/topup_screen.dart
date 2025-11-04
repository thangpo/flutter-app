import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/sepay_service.dart';

class TopUpScreen extends StatefulWidget {
  final double walletBalance;

  const TopUpScreen({
    super.key,
    this.walletBalance = 0.0,
  });

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final TextEditingController _amountController = TextEditingController();
  String selectedAmount = '';
  String selectedPaymentMethod = 'bank';
  bool isProcessing = false;

  final List<int> quickAmounts = [50000, 100000, 200000, 500000];

  String formatCurrency(String value, {bool isStripe = false}) {
    String digits = value.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) return '';

    int amount = int.parse(digits);

    if (isStripe) {
      double usd = amount / 25000;
      return usd.toStringAsFixed(2);
    }

    String formatted = '';
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      if (count == 3) {
        formatted = '.$formatted';
        count = 0;
      }
      formatted = digits[i] + formatted;
      count++;
    }

    return formatted;
  }

  String _formatMoney(double amount, {bool showDecimal = true}) {
    String formatted = amount.toStringAsFixed(2);
    List<String> parts = formatted.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '00';

    integerPart = integerPart.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    );

    return '$integerPart,$decimalPart đ';
  }

  void selectAmount(int amount) {
    setState(() {
      selectedAmount = amount.toString();
      _amountController.text = formatCurrency(amount.toString(), isStripe: selectedPaymentMethod == 'stripe');
    });
  }

  void _onAmountChanged(String value) {
    String formatted = formatCurrency(value, isStripe: selectedPaymentMethod == 'stripe');
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  void _onPaymentMethodChanged(String method) {
    setState(() {
      selectedPaymentMethod = method;
      if (_amountController.text.isNotEmpty) {
        String digits = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
        _amountController.text = formatCurrency(digits, isStripe: method == 'stripe');
      }
      if (selectedAmount.isNotEmpty) {
        selectAmount(int.parse(selectedAmount));
      }
    });
  }

  Future<void> _handlePayment() async {
    String amountText = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (amountText.isEmpty) {
      _showErrorDialog('Vui lòng nhập số tiền cần nạp');
      return;
    }

    int amount = int.parse(amountText);
    if (amount < 10000) {
      _showErrorDialog('Số tiền nạp tối thiểu là 10.000đ');
      return;
    }

    if (selectedPaymentMethod == 'bank') {
      await _processBankTransfer(amount);
    } else if (selectedPaymentMethod == 'stripe') {
      await _processStripePayment(amount);
    }
  }

  Future<void> _processBankTransfer(int amount) async {
    setState(() => isProcessing = true);

    try {
      final sepayService = SepayService();
      final result = await sepayService.createPaymentQR(
        context: context,
        amount: amount,
      );

      if (result != null) {
        setState(() => isProcessing = false);
        if (mounted) {
          _showQRPaymentDialog(result);
        }
      } else {
        setState(() => isProcessing = false);
        _showErrorDialog('Không thể tạo mã QR thanh toán. Vui lòng thử lại!');
      }
    } catch (e) {
      setState(() => isProcessing = false);
      _showErrorDialog('Lỗi: ${e.toString()}');
    }
  }

  Future<void> _processStripePayment(int amount) async {
    setState(() => isProcessing = true);
    await Future.delayed(const Duration(seconds: 1));

    setState(() => isProcessing = false);
    _showErrorDialog('Tính năng thanh toán Stripe đang được phát triển');
  }

  void _showQRPaymentDialog(Map<String, dynamic> paymentData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QRPaymentDialog(
        paymentData: paymentData,
        onSuccess: () {
          Navigator.of(context).pop();
          _showSuccessConfirmationDialog(
            amount: paymentData['amount'],
          );
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Lỗi'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showSuccessConfirmationDialog({
    required int amount,
  }) {
    final formattedAmount = formatCurrency(amount.toString());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Thành công', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          'Bạn đã thanh toán thành công số tiền $formattedAmountđ',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context, rootNavigator: true).pop(true);
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          getTranslated('top_up', context) ?? 'Nạp tiền',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Color(0xFF06B6D4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Ví cá nhân',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Chính',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _formatMoney(widget.walletBalance),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Số dư khả dụng',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Số tiền cần nạp',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _amountController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      onChanged: _onAmountChanged,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '0',
                                        hintStyle: TextStyle(
                                          fontSize: 28,
                                          color: Colors.grey[300],
                                          fontWeight: FontWeight.w400,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      selectedPaymentMethod == 'stripe' ? 'USD' : 'VND',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 2.5,
                              ),
                              itemCount: quickAmounts.length,
                              itemBuilder: (context, index) {
                                final amount = quickAmounts[index];
                                final isSelected = selectedAmount == amount.toString();
                                return _buildQuickAmountButton(amount, isSelected);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Phương thức thanh toán',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildPaymentMethodCard(
                              icon: Icons.account_balance,
                              title: 'Chuyển khoản ngân hàng',
                              subtitle: 'Miễn phí • Xử lý ngay',
                              isSelected: selectedPaymentMethod == 'bank',
                              onTap: () => _onPaymentMethodChanged('bank'),
                            ),
                            const SizedBox(height: 12),
                            _buildPaymentMethodCard(
                              icon: Icons.credit_card,
                              title: 'Stripe',
                              subtitle: 'Thẻ quốc tế • USD',
                              isSelected: selectedPaymentMethod == 'stripe',
                              onTap: () => _onPaymentMethodChanged('stripe'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: isProcessing ? null : _handlePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: isProcessing
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      'Thanh toán',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (isProcessing)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
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
    );
  }

  Widget _buildQuickAmountButton(int amount, bool isSelected) {
    String displayAmount = selectedPaymentMethod == 'stripe'
        ? '\$${(amount / 25000).toStringAsFixed(0)}'
        : '${formatCurrency(amount.toString())}đ';

    return GestureDetector(
      onTap: () => selectAmount(amount),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE0F2FE) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            displayAmount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.blue : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue.withOpacity(0.1)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.blue : const Color(0xFF64748B),
                size: 24,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.blue : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.blue : const Color(0xFFCBD5E1),
                  width: 2,
                ),
                color: isSelected ? Colors.blue : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}

class QRPaymentDialog extends StatefulWidget {
  final Map<String, dynamic> paymentData;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const QRPaymentDialog({
    super.key,
    required this.paymentData,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<QRPaymentDialog> createState() => _QRPaymentDialogState();
}

class _QRPaymentDialogState extends State<QRPaymentDialog> {
  Timer? _checkTimer;
  int _countdown = 300;

  @override
  void initState() {
    super.initState();
    _startChecking();
  }

  void _startChecking() {
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      _countdown -= 3;

      if (_countdown <= 0) {
        timer.cancel();
        widget.onCancel();
        return;
      }

      final sepayService = SepayService();
      final result = await sepayService.checkPaymentStatus(
        context: context,
        orderCode: widget.paymentData['order_code'],
      );

      if (result != null && result['status'] == 'paid') {
        timer.cancel();
        widget.onSuccess();
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatAmount(dynamic amount) {
    final int value = int.tryParse(amount.toString()) ?? 0;
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    );
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mã QR thanh toán',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Image.network(
                widget.paymentData['qr_url'],
                width: 250,
                height: 250,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 250,
                  height: 250,
                  color: Colors.grey[200],
                  child: const Icon(Icons.qr_code, size: 100),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Mã đơn hàng:'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.paymentData['order_code'],
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Số tiền:'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_formatAmount(widget.paymentData['amount'])}đ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, size: 20, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Còn lại: ${_formatTime(_countdown)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Mở app ngân hàng và quét mã QR để thanh toán',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Đang chờ thanh toán...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}