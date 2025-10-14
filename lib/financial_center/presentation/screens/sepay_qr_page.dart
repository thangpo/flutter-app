import 'package:flutter/material.dart';

class SepayQrPage extends StatelessWidget {
  final Map<String, dynamic> paymentData;
  const SepayQrPage({super.key, required this.paymentData});

  @override
  Widget build(BuildContext context) {
    final qrUrl = paymentData['qr_link'] ?? '';
    final amount = paymentData['amount'] ?? 0;
    final orderCode = paymentData['order_code'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán qua SePay'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Quét mã QR để thanh toán',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            if (qrUrl.isNotEmpty)
              Image.network(
                qrUrl,
                width: 250,
                height: 250,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.qr_code_2,
                  size: 200,
                  color: Colors.grey,
                ),
              )
            else
              const Text('Không thể tải mã QR', style: TextStyle(color: Colors.red)),

            const SizedBox(height: 24),

            Text(
              'Số tiền: ${amount.toString()} ₫',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Mã giao dịch: $orderCode',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text(
                'Quay lại',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
