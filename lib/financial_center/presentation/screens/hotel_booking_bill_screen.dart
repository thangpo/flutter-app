import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'hotel_checkout_screen.dart'; // để dùng lại HotelCheckoutData

class HotelBookingBillScreen extends StatelessWidget {
  final HotelCheckoutData data;

  final String bookingCode;
  final String bookingStatus;
  final String paymentMethod;
  final DateTime createdAt;

  // info người đặt
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String country;
  final String specialRequest;

  const HotelBookingBillScreen({
    Key? key,
    required this.data,
    required this.bookingCode,
    required this.bookingStatus,
    required this.paymentMethod,
    required this.createdAt,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.country,
    required this.specialRequest,
  }) : super(key: key);

  String _formatVnd(num v) {
    final f = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return f.format(v);
  }

  String _mapGateway(String gw) {
    switch (gw) {
      case 'sepay':
        return 'Chuyển khoản SePay';
      case 'offline_payment':
      default:
        return 'Thanh toán tại khách sạn';
    }
  }

  String _mapStatus(String status) {
    switch (status) {
      case 'processing':
        return 'Đang xử lý';
      case 'completed':
        return 'Hoàn thành';
      case 'paid':
        return 'Đã thanh toán';
      case 'unpaid':
      default:
        return 'Chưa thanh toán';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'processing':
        return Colors.orange;
      case 'completed':
      case 'paid':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final createdFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đặt phòng'),
      ),
      backgroundColor: Colors.grey[100],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // HEADER SUCCESS
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đặt phòng thành công',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mã đơn: $bookingCode',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ngày đặt: ${createdFmt.format(createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // TỔNG QUAN
          _buildCard(
            title: 'Tổng quan',
            child: Column(
              children: [
                _row(
                  'Trạng thái',
                  _mapStatus(bookingStatus),
                  valueColor: _statusColor(bookingStatus),
                  isBoldValue: true,
                ),
                const SizedBox(height: 6),
                _row('Phương thức thanh toán', _mapGateway(paymentMethod)),
                const SizedBox(height: 6),
                _row('Tổng thanh toán', _formatVnd(data.grandTotal),
                    isBoldValue: true),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // KHÁCH SẠN & LƯU TRÚ
          _buildCard(
            title: 'Thông tin lưu trú',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.hotelName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _row(
                  'Check-in',
                  dateFmt.format(data.checkIn),
                ),
                const SizedBox(height: 6),
                _row(
                  'Check-out',
                  dateFmt.format(data.checkOut),
                ),
                const SizedBox(height: 6),
                _row(
                  'Số đêm',
                  '${data.nights}',
                ),
                const SizedBox(height: 6),
                _row(
                  'Khách',
                  '${data.adults} người lớn, ${data.children} trẻ em',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // PHÒNG ĐÃ ĐẶT
          _buildCard(
            title: 'Phòng đã đặt',
            child: Column(
              children: [
                ...data.rooms.map((r) {
                  final qty = r.quantity <= 0 ? 1 : r.quantity;
                  final usedNights = data.nights > 0
                      ? data.nights
                      : (r.nights != null && r.nights! > 0 ? r.nights! : 1);
                  final lineTotal =
                      r.pricePerNight * usedNights * qty;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$qty phòng • $usedNights đêm × ${_formatVnd(r.pricePerNight)} / đêm',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatVnd(lineTotal),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const Divider(height: 20),
                _row('Tạm tính tiền phòng', _formatVnd(data.roomsTotal),
                    isBoldValue: true),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // GIÁ THÊM
          if (data.selectedExtras.isNotEmpty)
            _buildCard(
              title: 'Giá thêm',
              child: Column(
                children: [
                  ...data.selectedExtras.map((e) {
                    final name = (e['name'] ?? '').toString();
                    final priceHtml = (e['price_html'] ?? '').toString();
                    final rawPrice = (e['price'] ?? '').toString();
                    final displayPrice = priceHtml.isNotEmpty
                        ? priceHtml
                        : (rawPrice.isNotEmpty ? '$rawPrice ₫' : '0 ₫');

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _row(name, displayPrice),
                    );
                  }),
                  const Divider(height: 20),
                  _row('Tổng giá thêm', _formatVnd(data.extrasTotal),
                      isBoldValue: true),
                ],
              ),
            ),

          if (data.selectedExtras.isNotEmpty) const SizedBox(height: 16),

          // PHÍ DỊCH VỤ
          if (data.buyerFees.isNotEmpty)
            _buildCard(
              title: 'Phí dịch vụ',
              child: Column(
                children: [
                  ...data.buyerFees.map((fee) {
                    final name =
                    (fee['name'] ?? fee['type_name'] ?? 'Phí dịch vụ')
                        .toString();
                    final priceHtml = (fee['price_html'] ?? '').toString();
                    final rawPrice = (fee['price'] ?? '').toString();
                    final displayPrice = priceHtml.isNotEmpty
                        ? priceHtml
                        : (rawPrice.isNotEmpty ? '$rawPrice ₫' : '0 ₫');

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _row(name, displayPrice),
                    );
                  }),
                  const Divider(height: 20),
                  _row(
                    'Tổng phí dịch vụ',
                    _formatVnd(data.buyerFeesTotal),
                    isBoldValue: true,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // TỔNG THANH TOÁN
          _buildCard(
            title: 'Tổng thanh toán',
            child: Column(
              children: [
                _row('Tiền phòng', _formatVnd(data.roomsTotal)),
                const SizedBox(height: 4),
                _row('Giá thêm', _formatVnd(data.extrasTotal)),
                const SizedBox(height: 4),
                _row('Phí dịch vụ', _formatVnd(data.buyerFeesTotal)),
                const Divider(height: 20),
                _row(
                  'Tổng cộng',
                  _formatVnd(data.grandTotal),
                  isBoldValue: true,
                  valueSize: 18,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // THÔNG TIN NGƯỜI ĐẶT
          _buildCard(
            title: 'Thông tin người đặt',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Họ và tên', '$firstName $lastName'),
                const SizedBox(height: 4),
                _row('Email', email),
                const SizedBox(height: 4),
                _row('Số điện thoại', phone.isEmpty ? '—' : phone),
                const SizedBox(height: 4),
                _row('Quốc gia', country),
                const SizedBox(height: 4),
                _row('Thành phố / Tỉnh', city.isEmpty ? '—' : city),
                const SizedBox(height: 4),
                _row('Địa chỉ', address.isEmpty ? '—' : address),
                if (specialRequest.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Yêu cầu đặc biệt',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    specialRequest,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // hoặc push đến lịch sử đặt phòng
              },
              icon: const Icon(Icons.check),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Hoàn tất',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _row(
      String label,
      String value, {
        Color? valueColor,
        bool isBoldValue = false,
        double valueSize = 14,
      }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: isBoldValue ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}