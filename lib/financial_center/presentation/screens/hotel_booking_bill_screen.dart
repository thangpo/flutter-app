import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'hotel_checkout_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

class HotelBookingBillScreen extends StatelessWidget {
  final HotelCheckoutData data;

  final String bookingCode;
  final String bookingStatus;
  final String paymentMethod;
  final DateTime createdAt;
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

  String _mapGateway(BuildContext context, String gw) {
    switch (gw) {
      case 'sepay':
        return getTranslated('payment_sepay', context) ??
            'Chuyển khoản SePay';
      case 'offline_payment':
      default:
        return getTranslated('payment_offline', context) ??
            'Thanh toán tại khách sạn';
    }
  }

  String _mapStatus(BuildContext context, String status) {
    switch (status) {
      case 'processing':
        return getTranslated('status_processing', context) ?? 'Đang xử lý';
      case 'completed':
        return getTranslated('status_completed', context) ?? 'Hoàn thành';
      case 'paid':
        return getTranslated('status_paid', context) ?? 'Đã thanh toán';
      case 'unpaid':
      default:
        return getTranslated('status_unpaid', context) ?? 'Chưa thanh toán';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Không dùng AppBar text nữa, back nằm trong hero
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              // ===== HERO THÔNG TIN LƯU TRÚ (ảnh 1) =====
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildStayHero(
                  context: context,
                  dateFmt: dateFmt,
                  createdFmt: createdFmt,
                  isDark: isDark,
                ),
              ),

              // phần dưới cuộn nội dung
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Card: Đặt phòng thành công + mã đơn + ngày đặt
                    _buildSuccessCard(context, createdFmt),

                    const SizedBox(height: 16),

                    // Tổng quan đơn
                    _buildSectionCard(
                      context: context,
                      titleKey: 'booking_overview',
                      fallbackTitle: 'Tổng quan',
                      child: Column(
                        children: [
                          _row(
                            context,
                            getTranslated('status', context) ?? 'Trạng thái',
                            _mapStatus(context, bookingStatus),
                            valueColor: _statusColor(bookingStatus),
                            isBoldValue: true,
                          ),
                          const SizedBox(height: 6),
                          _row(
                            context,
                            getTranslated('payment_method', context) ??
                                'Phương thức thanh toán',
                            _mapGateway(context, paymentMethod),
                          ),
                          const SizedBox(height: 6),
                          _row(
                            context,
                            getTranslated('grand_total', context) ??
                                'Tổng thanh toán',
                            _formatVnd(data.grandTotal),
                            isBoldValue: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // PHÒNG ĐÃ ĐẶT – giao diện giống ảnh 2
                    _buildSectionCard(
                      context: context,
                      titleKey: 'rooms_booked',
                      fallbackTitle: 'Phòng đã đặt',
                      child: Column(
                        children: [
                          ...data.rooms.map(
                                (r) => Padding(
                              padding:
                              const EdgeInsets.symmetric(vertical: 6.0),
                              child: _buildRoomPill(context, r),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 20),
                          _row(
                            context,
                            getTranslated('room_subtotal', context) ??
                                'Tạm tính tiền phòng',
                            _formatVnd(data.roomsTotal),
                            isBoldValue: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // GIÁ THÊM
                    if (data.selectedExtras.isNotEmpty)
                      _buildSectionCard(
                        context: context,
                        titleKey: 'extra_prices',
                        fallbackTitle: 'Giá thêm',
                        child: Column(
                          children: [
                            ...data.selectedExtras.map((e) {
                              final name = (e['name'] ?? '').toString();
                              final priceHtml =
                              (e['price_html'] ?? '').toString();
                              final rawPrice =
                              (e['price'] ?? '').toString();
                              final displayPrice = priceHtml.isNotEmpty
                                  ? priceHtml
                                  : (rawPrice.isNotEmpty
                                  ? '$rawPrice ₫'
                                  : '0 ₫');

                              return Padding(
                                padding:
                                const EdgeInsets.symmetric(vertical: 4),
                                child: _row(context, name, displayPrice),
                              );
                            }),
                            const Divider(height: 20),
                            _row(
                              context,
                              getTranslated('extra_total', context) ??
                                  'Tổng giá thêm',
                              _formatVnd(data.extrasTotal),
                              isBoldValue: true,
                            ),
                          ],
                        ),
                      ),

                    if (data.selectedExtras.isNotEmpty)
                      const SizedBox(height: 16),

                    // PHÍ DỊCH VỤ
                    if (data.buyerFees.isNotEmpty)
                      _buildSectionCard(
                        context: context,
                        titleKey: 'service_fees',
                        fallbackTitle: 'Phí dịch vụ',
                        child: Column(
                          children: [
                            ...data.buyerFees.map((fee) {
                              final name = (fee['name'] ??
                                  fee['type_name'] ??
                                  'Phí dịch vụ')
                                  .toString();
                              final priceHtml =
                              (fee['price_html'] ?? '').toString();
                              final rawPrice =
                              (fee['price'] ?? '').toString();
                              final displayPrice = priceHtml.isNotEmpty
                                  ? priceHtml
                                  : (rawPrice.isNotEmpty
                                  ? '$rawPrice ₫'
                                  : '0 ₫');

                              return Padding(
                                padding:
                                const EdgeInsets.symmetric(vertical: 4),
                                child: _row(context, name, displayPrice),
                              );
                            }),
                            const Divider(height: 20),
                            _row(
                              context,
                              getTranslated('service_fees_total', context) ??
                                  'Tổng phí dịch vụ',
                              _formatVnd(data.buyerFeesTotal),
                              isBoldValue: true,
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // TỔNG THANH TOÁN – card kiểu ảnh 3
                    _buildSectionCard(
                      context: context,
                      titleKey: 'payment_summary',
                      fallbackTitle: 'Tổng thanh toán',
                      child: Column(
                        children: [
                          _row(
                            context,
                            getTranslated('room_cost', context) ??
                                'Tiền phòng',
                            _formatVnd(data.roomsTotal),
                          ),
                          const SizedBox(height: 4),
                          _row(
                            context,
                            getTranslated('extra_cost', context) ??
                                'Giá thêm',
                            _formatVnd(data.extrasTotal),
                          ),
                          const SizedBox(height: 4),
                          _row(
                            context,
                            getTranslated('service_fees_cost', context) ??
                                'Phí dịch vụ',
                            _formatVnd(data.buyerFeesTotal),
                          ),
                          const Divider(height: 20),
                          _row(
                            context,
                            getTranslated('total_amount', context) ??
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
                    _buildSectionCard(
                      context: context,
                      titleKey: 'guest_info',
                      fallbackTitle: 'Thông tin người đặt',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _row(
                            context,
                            getTranslated('full_name', context) ??
                                'Họ và tên',
                            '$firstName $lastName',
                          ),
                          const SizedBox(height: 4),
                          _row(
                            context,
                            getTranslated('email', context) ?? 'Email',
                            email,
                          ),
                          const SizedBox(height: 4),
                          _row(
                            context,
                            getTranslated('phone_number', context) ??
                                'Số điện thoại',
                            phone.isEmpty
                                ? (getTranslated('empty_dash', context) ??
                                '—')
                                : phone,
                          ),
                          const SizedBox(height: 4),
                          _row(
                            context,
                            getTranslated('country', context) ?? 'Quốc gia',
                            country,
                          ),
                          const SizedBox(height: 4),
                          _row(
                            context,
                            getTranslated('city_province', context) ??
                                'Thành phố / Tỉnh',
                            city.isEmpty
                                ? (getTranslated('empty_dash', context) ??
                                '—')
                                : city,
                          ),
                          const SizedBox(height: 4),
                          _row(
                            context,
                            getTranslated('address_detail', context) ??
                                'Địa chỉ',
                            address.isEmpty
                                ? (getTranslated('empty_dash', context) ??
                                '—')
                                : address,
                          ),
                          if (specialRequest.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              getTranslated(
                                  'special_request', context) ??
                                  'Yêu cầu đặc biệt',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
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
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.check),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            getTranslated('finish', context) ?? 'Hoàn tất',
                            style: const TextStyle(fontSize: 16),
                          ),
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
    );
  }

  // ==== HERO ẢNH KHÁCH SẠN (ảnh 1) ====
  Widget _buildStayHero({
    required BuildContext context,
    required DateFormat dateFmt,
    required DateFormat createdFmt,
    required bool isDark,
  }) {
    final data = this.data;

    final String dateRange =
        '${dateFmt.format(data.checkIn)} • ${dateFmt.format(data.checkOut)}';
    final String nightsText =
        '${data.nights} ${getTranslated('nights', context) ?? 'đêm'}';
    final String guestsText =
        '${data.adults} ${getTranslated('adults', context) ?? 'người lớn'}, '
        '${data.children} ${getTranslated('children', context) ?? 'trẻ em'}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: SizedBox(
        height: 260,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (data.hotelImage != null && data.hotelImage!.isNotEmpty)
              Image.network(
                data.hotelImage!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.hotel, size: 60, color: Colors.grey),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF111827), const Color(0xFF020617)]
                        : [const Color(0xFFE0F2FE), const Color(0xFFFFFFFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

            // overlay gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.35),
                    Colors.black.withOpacity(0.75),
                  ],
                ),
              ),
            ),

            // nội dung
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // back button
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (data.hotelLocation != null &&
                      data.hotelLocation!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data.hotelLocation!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    data.hotelName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$dateRange • $nightsText',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    guestsText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${getTranslated('booking_code', context) ?? 'Mã đơn'}: $bookingCode',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${getTranslated('created_at', context) ?? 'Ngày đặt'}: ${createdFmt.format(createdAt)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card “Đặt phòng thành công”
  Widget _buildSuccessCard(BuildContext context, DateFormat createdFmt) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          if (!isDark)
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
              color: Colors.green.withOpacity(0.12),
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
                Text(
                  getTranslated('booking_success', context) ??
                      'Đặt phòng thành công',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color:
                    theme.textTheme.titleMedium?.color ?? Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${getTranslated('booking_code', context) ?? 'Mã đơn'}: $bookingCode',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                    theme.textTheme.titleMedium?.color ?? Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${getTranslated('created_at', context) ?? 'Ngày đặt'}: ${createdFmt.format(createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color ??
                        Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card khung chung kiểu ảnh 3
  Widget _buildSectionCard({
    required BuildContext context,
    required String titleKey,
    required String fallbackTitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
    isDark ? Colors.white12 : Colors.grey.withOpacity(0.25);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTranslated(titleKey, context) ?? fallbackTitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  // Row label / value dùng lại cho nhiều nơi
  Widget _row(
      BuildContext context,
      String label,
      String value, {
        Color? valueColor,
        bool isBoldValue = false,
        double valueSize = 14,
      }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: theme.textTheme.bodySmall?.color ?? Colors.grey[700],
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
              color: valueColor ??
                  theme.textTheme.bodyMedium?.color ??
                  Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // Card phòng đã đặt – style giống ảnh 2
  Widget _buildRoomPill(BuildContext context, HotelSelectedRoom r) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final qty = r.quantity <= 0 ? 1 : r.quantity;
    final usedNights = data.nights > 0
        ? data.nights
        : (r.nights != null && r.nights! > 0 ? r.nights! : 1);
    final lineTotal = r.pricePerNight * usedNights * qty;

    return Container(
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF020617)]
              : [const Color(0xFFFFEDD5), const Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // background image mờ (dùng ảnh khách sạn)
          if (data.hotelImage != null && data.hotelImage!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Opacity(
                opacity: 0.35,
                child: Image.network(
                  data.hotelImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),

          // overlay hơi tối cho dễ đọc chữ
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.4),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.bed_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$qty ${getTranslated('rooms', context) ?? 'phòng'} • '
                            '$usedNights ${getTranslated('nights', context) ?? 'đêm'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_formatVnd(r.pricePerNight)} / ${getTranslated('per_night', context) ?? 'đêm'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatVnd(lineTotal),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      getTranslated('room_total', context) ?? 'Tổng phòng',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}