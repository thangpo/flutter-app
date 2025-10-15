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

class _SepayQrPageState extends State<SepayQrPage> {
  Timer? _timer;
  bool _isPaid = false;

  @override
  void initState() {
    super.initState();
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
      } catch (e) {
        debugPrint('Error checking payment: $e');
      }
    });
  }

  void _showPaidDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thanh toán thành công 🎉'),
        content: const Text('Cảm ơn bạn, đơn hàng đã được xác nhận thanh toán.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qrUrl = widget.paymentData['qr_link'] ?? '';
    final orderCode = widget.paymentData['order_code'] ?? '';
    final amount = widget.paymentData['amount'] ?? 0;

    debugPrint('QR URL: $qrUrl');
    debugPrint('Order Code: $orderCode');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán qua SePay'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            const Text('Quét mã QR để thanh toán',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            if (qrUrl.isNotEmpty)
              Image.network(
                Uri.encodeFull(qrUrl),
                width: 250,
                height: 250,
                errorBuilder: (context, error, stackTrace) =>
                const Text('Không thể tải mã QR 😢',
                    style: TextStyle(color: Colors.red)),
              )
            else
              const Text('Không thể tải mã QR', style: TextStyle(color: Colors.red)),

            const SizedBox(height: 24),
            Text('Số tiền: ${amount.toString()} ₫',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.teal)),
            const SizedBox(height: 12),
            Text('Mã giao dịch: $orderCode',
                style: const TextStyle(fontSize: 16, color: Colors.grey)),

            const Spacer(),
            if (!_isPaid)
              const CircularProgressIndicator()
            else
              const Text('✅ Đã thanh toán', style: TextStyle(color: Colors.green, fontSize: 18)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
