import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/sepay_service.dart';
import 'package:provider/provider.dart';

class TopUpScreen extends StatefulWidget {
  final double walletBalance;

  const TopUpScreen({
    super.key,
    this.walletBalance = 0.0,
  });

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> with TickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  String selectedAmount = '';
  String selectedPaymentMethod = 'bank';
  bool isProcessing = false;

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final List<int> quickAmounts = [50000, 100000, 200000, 500000];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideController.forward();
    _fadeController.forward();
  }

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
    HapticFeedback.lightImpact();
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
    HapticFeedback.selectionClick();
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
    HapticFeedback.mediumImpact();
    String amountText = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (amountText.isEmpty) {
      _showErrorDialog(getTranslated('enter_topup_amount_prompt', context) ?? 'Vui lòng nhập số tiền cần nạp');
      return;
    }

    int amount = int.parse(amountText);
    if (amount < 10000) {
      _showErrorDialog(getTranslated('minimum_deposit_amount', context) ?? 'Số tiền nạp tối thiểu là 10.000đ');
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
        _showErrorDialog(getTranslated('qr_generation_failed', context) ?? 'Không thể tạo mã QR thanh toán. Vui lòng thử lại!');
      }
    } catch (e) {
      setState(() => isProcessing = false);
      _showErrorDialog(
          '${getTranslated('error', context)}: ${e.toString()}'
      );
    }
  }

  Future<void> _processStripePayment(int amount) async {
    setState(() => isProcessing = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => isProcessing = false);
    _showErrorDialog(getTranslated('stripe_development_feature', context) ?? 'Tính năng thanh toán Stripe đang được phát triển');
  }

  void _showQRPaymentDialog(Map<String, dynamic> paymentData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QRPaymentDialog(
        paymentData: paymentData,
        onSuccess: () {
          Navigator.of(context).pop();
          _showSuccessConfirmationDialog(amount: paymentData['amount']);
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
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline, color: Colors.red, size: 32),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Lỗi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      getTranslated('close', context) ?? 'Đóng',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessConfirmationDialog({required int amount}) {
    final formattedAmount = formatCurrency(amount.toString());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  getTranslated('success', context) ?? 'Thành công',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (getTranslated('payment_success_message', context) ??
                      'Bạn đã thanh toán thành công số tiền @amountđ')
                      .replaceAll('@amount', formattedAmount),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context, rootNavigator: true).pop(true);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      getTranslated('confirm', context) ?? 'Xác nhận',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeController>(context);
    final isDark = theme.darkTheme;
    final Color backgroundColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final Color cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white.withOpacity(0.9);
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final Color textSecondary = isDark ? Colors.white70 : const Color(0xFF8E8E93);
    final Color textHint = isDark ? Colors.white54 : const Color(0xFFD1D1D6);
    final Color dividerColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final Color primaryColor = const Color(0xFF007AFF);
    final Color successColor = const Color(0xFF34C759);
    final Color primaryDark = const Color(0xFF0051D5);
    final Color disabledColor = const Color(0xFFD1D1D6);
    final Color errorColor = const Color(0xFFFF3B30);
    final Color warningColor = const Color(0xFFFF9500);

    Widget _buildPaymentButton() {
      return ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.7),
              border: Border(
                top: BorderSide(
                  color: dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SafeArea(
              child: GestureDetector(
                onTap: isProcessing
                    ? null
                    : () {
                  HapticFeedback.mediumImpact();
                  _handlePayment();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isProcessing
                          ? [disabledColor, disabledColor]
                          : [primaryColor, primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      if (!isProcessing)
                        BoxShadow(
                          color: primaryColor.withOpacity(isDark ? 0.4 : 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                    ],
                  ),
                  child: Center(
                    child: isProcessing
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : Text(
                      getTranslated('pay', context) ?? 'Thanh toán',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget _buildLoadingOverlay() {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: dividerColor,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          color: primaryColor,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        getTranslated('processing', context) ?? 'Đang xử lý...',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
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
        onTap: () {
          HapticFeedback.selectionClick(); // Hiệu ứng rung iOS
          onTap();
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected
                      ? [
                    primaryColor.withOpacity(0.15),
                    primaryColor.withOpacity(0.08),
                  ]
                      : isDark
                      ? [cardColor, cardColor.withOpacity(0.8)]
                      : [Colors.white.withOpacity(0.8), Colors.white.withOpacity(0.5)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? primaryColor.withOpacity(0.3)
                      : dividerColor,
                  width: isSelected ? 2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withOpacity(0.15)
                          : isDark
                          ? dividerColor
                          : const Color(0xFFF2F2F7).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? primaryColor : textSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? primaryColor : textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Checkmark
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? primaryColor : dividerColor,
                        width: 2,
                      ),
                      color: isSelected ? primaryColor : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget _buildWalletCard() {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [cardColor, cardColor.withOpacity(0.8)]
                      : [Colors.white.withOpacity(0.8), Colors.white.withOpacity(0.5)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: dividerColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 30,
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
                      Text(
                        getTranslated('personal_wallet', context) ?? 'Ví cá nhân',
                        style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.account_balance_wallet_rounded, color: primaryColor, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              getTranslated('main', context) ?? 'Chính',
                              style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatMoney(widget.walletBalance),
                    style: TextStyle(color: textPrimary, fontSize: 34, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.trending_up_rounded, color: successColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        getTranslated('available_balance', context) ?? 'Số dư khả dụng',
                        style: TextStyle(color: textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget _buildQuickAmountButton(int amount, bool isSelected) {
      String displayAmount = selectedPaymentMethod == 'stripe'
          ? '\$${(amount / 25000).toStringAsFixed(0)}'
          : '${formatCurrency(amount.toString())}đ';

      return GestureDetector(
        onTap: () => selectAmount(amount),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withOpacity(0.15)
                : isDark ? dividerColor : const Color(0xFFF2F2F7).withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? primaryColor.withOpacity(0.3)
                  : Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              displayAmount,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? primaryColor : textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
      );
    }

    Widget _buildAmountInput() {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [cardColor, cardColor.withOpacity(0.8)]
                      : [Colors.white.withOpacity(0.8), Colors.white.withOpacity(0.5)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: dividerColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getTranslated('top_up_amount', context) ?? 'Số tiền cần nạp',
                    style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? dividerColor : const Color(0xFFF2F2F7).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: _onAmountChanged,
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: textPrimary),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: TextStyle(fontSize: 28, color: textHint, fontWeight: FontWeight.w400),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            selectedPaymentMethod == 'stripe' ? 'USD' : 'VND',
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
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
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
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
          ),
        ),
      );
    }

    Widget _buildPaymentMethods() {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                getTranslated('payment_method', context) ?? 'Phương thức thanh toán',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            _buildPaymentMethodCard(
              icon: Icons.account_balance_rounded,
              title: getTranslated('bank_transfer', context) ?? 'Chuyển khoản ngân hàng',
              subtitle: getTranslated('free_instant', context) ?? 'Miễn phí • Xử lý ngay',
              isSelected: selectedPaymentMethod == 'bank',
              onTap: () => _onPaymentMethodChanged('bank'),
            ),
            const SizedBox(height: 12),
            _buildPaymentMethodCard(
              icon: Icons.credit_card_rounded,
              title: 'Stripe',
              subtitle: getTranslated('international_card', context) ?? 'Thẻ quốc tế • USD',
              isSelected: selectedPaymentMethod == 'stripe',
              onTap: () => _onPaymentMethodChanged('stripe'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.7),
                border: Border(
                  bottom: BorderSide(
                    color: dividerColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Color(0xFF007AFF),
                            size: 20,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          getTranslated('top_up', context) ?? 'Nạp tiền',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 36),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 100),
                          _buildWalletCard(),
                          const SizedBox(height: 16),
                          _buildAmountInput(),
                          const SizedBox(height: 16),
                          _buildPaymentMethods(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                  _buildPaymentButton(),
                ],
              ),
            ),
          ),
          if (isProcessing) _buildLoadingOverlay(),
        ],
      ),
    );
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

class _QRPaymentDialogState extends State<QRPaymentDialog>
    with SingleTickerProviderStateMixin {
  Timer? _checkTimer;
  int _countdown = 300;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _startChecking();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
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
    _pulseController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeController>(context);
    final isDark = theme.darkTheme;
    final Color backgroundColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final Color cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white.withOpacity(0.9);
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final Color textSecondary = isDark ? Colors.white70 : const Color(0xFF8E8E93);
    final Color textHint = isDark ? Colors.white54 : const Color(0xFFD1D1D6);
    final Color dividerColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final Color primaryColor = const Color(0xFF007AFF);
    final Color warningColor = const Color(0xFFFF9500);
    final Color successColor = const Color(0xFF34C759);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [cardColor, cardColor.withOpacity(0.8)]
                      : [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: dividerColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        getTranslated('qr_payment', context) ?? 'Mã QR thanh toán',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onCancel?.call();
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark ? dividerColor : const Color(0xFFF2F2F7).withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close_rounded, size: 20, color: textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? cardColor : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(isDark ? 0.3 : 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.paymentData['qr_url'],
                          width: 220,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 220,
                            height: 220,
                            color: isDark ? dividerColor : const Color(0xFFF2F2F7),
                            child: Icon(Icons.qr_code_rounded, size: 80, color: textHint),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? dividerColor : const Color(0xFFF2F2F7).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              getTranslated('order_code', context) ?? 'Mã đơn:',
                              style: TextStyle(fontSize: 14, color: textSecondary),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.paymentData['order_code'],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Clipboard.setData(ClipboardData(text: widget.paymentData['order_code']));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(getTranslated('copied', context) ?? 'Đã sao chép!'),
                                    backgroundColor: successColor,
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              },
                              child: Icon(Icons.copy, size: 16, color: primaryColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              getTranslated('amount', context) ?? 'Số tiền:',
                              style: TextStyle(fontSize: 14, color: textSecondary),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_formatAmount(widget.paymentData['amount'])}đ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                  fontSize: 20,
                                  letterSpacing: -0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: warningColor.withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: warningColor.withOpacity(0.2), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 18, color: warningColor),
                        const SizedBox(width: 8),
                        Text(
                          getTranslated('time_remaining', context) ?? 'Còn lại: ${_formatTime(_countdown)}',
                          style: TextStyle(fontWeight: FontWeight.w600, color: warningColor, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    getTranslated('scan_qr_hint', context) ?? 'Mở app ngân hàng và quét mã QR để thanh toán',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor.withOpacity(0.5)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        getTranslated('waiting_payment', context) ?? 'Đang chờ thanh toán...',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}