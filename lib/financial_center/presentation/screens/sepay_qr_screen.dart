import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import '../services/flight_service.dart';
import 'flight_invoice_screen.dart';

class SepayQrScreen extends StatefulWidget {
  final String orderCode;
  final String qrLink;
  final double amount;
  final Map<String, dynamic>? booking;
  final Map<String, dynamic> flightInfo;
  final Map<String, dynamic> contactInfo;
  final List<Map<String, dynamic>> passengers;
  final String homeRouteName;

  const SepayQrScreen({
    super.key,
    required this.orderCode,
    required this.qrLink,
    required this.amount,
    this.booking,
    required this.flightInfo,
    required this.contactInfo,
    required this.passengers,
    this.homeRouteName = '/',
  });

  @override
  State<SepayQrScreen> createState() => _SepayQrScreenState();
}

class _SepayQrScreenState extends State<SepayQrScreen>
    with SingleTickerProviderStateMixin {
  static const int _maxSeconds = 600;

  Timer? _pollTimer;
  Timer? _countdownTimer;
  bool _isPaid = false;
  bool _canceling = false;
  bool _navigating = false;
  String _statusText = "Đang chờ thanh toán...";
  int _remainingSeconds = _maxSeconds;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _startPolling();
    _startCountdown();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startPolling() {
    final code = widget.orderCode.trim();
    if (code.isEmpty) return;

    _pollOnce();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) => _pollOnce());
  }

  Future<void> _pollOnce() async {
    if (_isPaid || _navigating) return;

    try {
      final res = await FlightService.checkBookingStatus(widget.orderCode);
      final dynamic dynamicStatus = res["booking_status"] ??
          (res["data"] is Map
              ? (res["data"]["booking_status"] ?? res["data"]["status"])
              : null) ??
          (res["booking"] is Map ? (res["booking"]["status"]) : null);

      final status = (dynamicStatus ?? "").toString().toLowerCase().trim();

      final paidStatuses = <String>{
        "paid",
        "completed",
        "confirmed",
        "success",
        "succeeded",
      };

      if (paidStatuses.contains(status)) {
        await _markPaidAndGoInvoice(res);
      } else {
        if (!mounted) return;
        setState(() {
          final waiting =
              getTranslated('sepay_waiting', context) ?? 'Đang chờ thanh toán...';
          final statusLabel =
              getTranslated('sepay_status', context) ?? 'Trạng thái';
          _statusText = status.isEmpty ? waiting : '$statusLabel: $status';
        });
      }
    } catch (_) {

    }
  }

  Future<void> _markPaidAndGoInvoice(Map<String, dynamic> checkRes) async {
    _isPaid = true;
    _pollTimer?.cancel();
    _countdownTimer?.cancel();

    if (!mounted) return;
    setState(() {
      _statusText = getTranslated('sepay_paid_success', context) ?? 'Thanh toán thành công';
    });
    await _goInvoiceAfterPaid(checkRes);
  }

  Future<void> _goInvoiceAfterPaid(Map<String, dynamic> checkRes) async {
    if (_navigating) return;
    _navigating = true;
    Map<String, dynamic> booking = <String, dynamic>{};

    final fromApiBooking = (checkRes["booking"] is Map)
        ? Map<String, dynamic>.from(checkRes["booking"])
        : (checkRes["data"] is Map && (checkRes["data"]["booking"] is Map))
        ? Map<String, dynamic>.from(checkRes["data"]["booking"])
        : (checkRes["data"] is Map &&
        (checkRes["data"]["id"] != null || checkRes["data"]["code"] != null))
        ? Map<String, dynamic>.from(checkRes["data"])
        : null;

    if (fromApiBooking != null) {
      booking = fromApiBooking;
    } else if (widget.booking != null) {
      booking = Map<String, dynamic>.from(widget.booking!);
    } else {
      booking = {
        "code": widget.orderCode,
        "total": widget.amount,
        "gateway": "sepay",
        "status": "paid",
      };
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => FlightInvoiceScreen(
          booking: booking,
          flightInfo: widget.flightInfo,
          contactInfo: widget.contactInfo,
          passengers: widget.passengers,
          homeRouteName: widget.homeRouteName,
        ),
      ),
    );
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      if (_isPaid || _navigating) return;

      if (_remainingSeconds <= 0) {
        _pollTimer?.cancel();
        setState(() => _statusText =
            getTranslated('sepay_timeout', context) ?? 'Hết thời gian chờ thanh toán');
        return;
      }

      setState(() => _remainingSeconds--);
    });
  }

  String _formatCountdown(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => (_remainingSeconds / _maxSeconds).clamp(0.0, 1.0);

  Future<bool> _onWillPop() async {
    if (_isPaid || _navigating) return true;
    if (_canceling) return false;

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(getTranslated('sepay_cancel_title', context) ?? 'Hủy thanh toán?'),
        content: Text(getTranslated('sepay_cancel_message', context) ??
            'Bạn có chắc muốn hủy giao dịch này? Đơn hàng sẽ bị hủy.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(getTranslated('sepay_continue', context) ?? 'Tiếp tục'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(getTranslated('sepay_cancel_order', context) ?? 'Hủy đơn'),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      await _cancelBooking();
      return false;
    }
    return false;
  }

  Future<void> _cancelBooking() async {
    final code = widget.orderCode.trim();
    if (code.isEmpty) {
      if (mounted) Navigator.pop(context, false);
      return;
    }

    setState(() => _canceling = true);

    try {
      _pollTimer?.cancel();
      _countdownTimer?.cancel();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      final res = await FlightService.cancelBooking(code);

      if (mounted) Navigator.pop(context);

      final ok = (res["status"] == true) || (res["success"] == true) || (res["ok"] == true);

      if (!mounted) return;

      if (ok) {
        Navigator.pop(context, false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res["message"]?.toString() ??
                  (getTranslated('sepay_cancel_failed', context) ?? "Hủy đơn thất bại"),
            ),
          ),
        );
        Navigator.pop(context, false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${getTranslated('sepay_cancel_error', context) ?? 'Có lỗi khi hủy đơn'}: $e",
            ),
          ),
        );
        Navigator.pop(context, false);
      }
    } finally {
      if (mounted) setState(() => _canceling = false);
    }
  }

  String _formatCurrencyVnd(double amount) {
    final v = amount.round().toString();
    return v.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    );
  }

  Color _statusColor(String s, ColorScheme scheme) {
    final t = s.toLowerCase();
    if (_isPaid) return Colors.green;
    if (t.contains('hết') || t.contains('timeout')) return Colors.orange;
    if (t.contains('lỗi') || t.contains('error')) return Colors.red;
    return scheme.primary;
  }

  IconData _statusIcon(String s) {
    final t = s.toLowerCase();
    if (_isPaid) return Icons.check_circle_rounded;
    if (t.contains('hết') || t.contains('timeout')) return Icons.timer_off_rounded;
    if (t.contains('lỗi') || t.contains('error')) return Icons.error_rounded;
    return Icons.hourglass_top_rounded;
  }

  Future<void> _copyOrderCode() async {
    final code = widget.orderCode.trim();
    if (code.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;

    final copied = getTranslated('sepay_copied', context) ?? 'Đã copy mã đơn';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(copied)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final bgTop = scheme.primary.withOpacity(0.22);
    final bgBottom = Colors.black.withOpacity(0.92);
    final statusClr = _statusColor(_statusText, scheme);

    final title = getTranslated('sepay_title', context) ?? 'Thanh toán SePay';
    final orderLabel = getTranslated('sepay_order_code', context) ?? 'Mã đơn';
    final amountLabel = getTranslated('sepay_amount', context) ?? 'Số tiền';
    final autoUpdateLabel =
        getTranslated('sepay_auto_update_after', context) ?? 'Tự động cập nhật sau';
    final qrLoadFail = getTranslated('sepay_qr_load_failed', context) ?? 'Không tải được QR';
    final tipWaiting = getTranslated('sepay_tip_waiting', context) ??
        'Mở app ngân hàng, quét QR và chuyển đúng số tiền. Trạng thái sẽ tự cập nhật.';
    final tipPaid = getTranslated('sepay_tip_paid', context) ??
        'Đã nhận thanh toán. Đang chuyển sang hóa đơn...';
    final cancelBtn = getTranslated('sepay_cancel_order', context) ?? 'Hủy đơn';
    final cancelingBtn = getTranslated('sepay_canceling', context) ?? 'Đang hủy...';
    final copyTooltip = getTranslated('sepay_copy_order_code', context) ?? 'Copy mã đơn';

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(title),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [bgTop, bgBottom],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.10)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: statusClr.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: statusClr.withOpacity(0.35)),
                            ),
                            child: Icon(_statusIcon(_statusText), color: statusClr),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _statusText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$autoUpdateLabel: ${_formatCountdown(_remainingSeconds)}",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.70),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: _progress,
                                    minHeight: 6,
                                    backgroundColor: Colors.white.withOpacity(0.10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 28,
                              offset: const Offset(0, 16),
                              color: Colors.black.withOpacity(0.35),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "$orderLabel: ${widget.orderCode}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: copyTooltip,
                                  onPressed: _copyOrderCode,
                                  icon: Icon(Icons.copy_rounded,
                                      color: Colors.white.withOpacity(0.85)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "$amountLabel: ${_formatCurrencyVnd(widget.amount)} ₫",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Expanded(
                              child: Center(
                                child: AnimatedBuilder(
                                  animation: _pulse,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _isPaid ? 1.0 : _pulse.value,
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              blurRadius: 26,
                                              offset: const Offset(0, 16),
                                              color: Colors.black.withOpacity(0.20),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(14),
                                          child: AspectRatio(
                                            aspectRatio: 1,
                                            child: Image.network(
                                              Uri.encodeFull(widget.qrLink),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Center(child: Text(qrLoadFail)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(16),
                                border:
                                Border.all(color: Colors.white.withOpacity(0.10)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      color: Colors.white.withOpacity(0.80)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _isPaid ? tipPaid : tipWaiting,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.82),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!_isPaid)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _canceling ? null : _cancelBooking,
                          icon: const Icon(Icons.close_rounded),
                          label: Text(_canceling ? cancelingBtn : cancelBtn),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withOpacity(0.25)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}