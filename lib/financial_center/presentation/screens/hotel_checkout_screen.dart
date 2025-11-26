import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/hotel_rooms_section.dart' show HotelSelectedRoom;
import '../services/hotel_service.dart';
import 'hotel_booking_bill_screen.dart';
import 'hotel_sepay_payment_screen.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/logging_interceptor.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/domain/repositories/profile_repository.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class HotelCheckoutData {
  final int hotelId;
  final String hotelSlug;
  final String hotelName;
  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final int adults;
  final int children;
  final List<HotelSelectedRoom> rooms;
  final List<Map<String, dynamic>> selectedExtras;
  final List<Map<String, dynamic>> buyerFees;
  final double roomsTotal;
  final double extrasTotal;
  final double buyerFeesTotal;
  final double grandTotal;

  HotelCheckoutData({
    required this.hotelId,
    required this.hotelSlug,
    required this.hotelName,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.adults,
    required this.children,
    required this.rooms,
    required this.selectedExtras,
    required this.buyerFees,
    required this.roomsTotal,
    required this.extrasTotal,
    required this.buyerFeesTotal,
    required this.grandTotal,
  });
}

class HotelCheckoutScreen extends StatefulWidget {
  final HotelCheckoutData data;

  const HotelCheckoutScreen({super.key, required this.data});

  @override
  State<HotelCheckoutScreen> createState() => _HotelCheckoutScreenState();
}

class _HotelCheckoutScreenState extends State<HotelCheckoutScreen> {
  final HotelService _hotelService = HotelService();

  int _currentStep = 0;
  bool _isLoading = false;
  late ProfileRepository _profileRepository;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController countryController =
  TextEditingController(text: 'Việt Nam');
  final TextEditingController specialRequestController = TextEditingController();
  final TextEditingController couponController = TextEditingController();

  String paymentMethod = 'offline_payment';

  @override
  void initState() {
    super.initState();
    _initProfileRepo();
  }

  Future<void> _initProfileRepo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dio = Dio();
      final loggingInterceptor = LoggingInterceptor();

      final dioClient = DioClient(
        AppConstants.baseUrl,
        dio,
        loggingInterceptor: loggingInterceptor,
        sharedPreferences: prefs,
      );

      _profileRepository = ProfileRepository(
        dioClient: dioClient,
        sharedPreferences: prefs,
      );

      await _loadUserData();
    } catch (_) {
      // nếu lỗi thì thôi, user tự nhập tay
    }
  }

  Future<void> _loadUserData() async {
    final response = await _profileRepository.getProfileInfo();
    if (response.isSuccess) {
      final userData = response.response.data;
      if (!mounted) return;
      setState(() {
        firstNameController.text = userData['f_name'] ?? '';
        lastNameController.text = userData['l_name'] ?? '';
        emailController.text = userData['email'] ?? '';
        countryController.text = userData['country'] ?? 'Việt Nam';
        phoneController.text = userData['phone'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    cityController.dispose();
    countryController.dispose();
    specialRequestController.dispose();
    couponController.dispose();
    super.dispose();
  }

  String _formatVnd(num v) {
    final f = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return f.format(v);
  }

  double _calcRoomLineTotal(HotelSelectedRoom r) {
    final data = widget.data;
    final int qty = r.quantity <= 0 ? 1 : r.quantity;
    final int usedNights =
    data.nights > 0 ? data.nights : (r.nights != null && r.nights! > 0 ? r.nights! : 1);
    final double perNight = r.pricePerNight;
    return perNight * usedNights * qty;
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentStep == 0
              ? 'Thông tin đặt phòng'
              : 'Thông tin người đặt & thanh toán',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _currentStep == 0
            ? _buildStep1(context, dateFmt)
            : _buildStep2(context),
      ),
    );
  }

  // ===================== STEP 1: THÔNG TIN ĐẶT PHÒNG =====================

  Widget _buildStep1(BuildContext context, DateFormat dateFmt) {
    final data = widget.data;

    return ListView(
      children: [
        Text(
          data.hotelName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${dateFmt.format(data.checkIn)} - '
              '${dateFmt.format(data.checkOut)}  •  ${data.nights} đêm',
        ),
        Text(
          '${data.adults} người lớn, ${data.children} trẻ em',
        ),
        const Divider(height: 32),

        const Text(
          'Phòng đã chọn',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...data.rooms.map((r) {
          final int qty = r.quantity <= 0 ? 1 : r.quantity;
          final int usedNights =
          data.nights > 0 ? data.nights : (r.nights != null && r.nights! > 0 ? r.nights! : 1);
          final double perNight = r.pricePerNight;
          final double lineTotal = _calcRoomLineTotal(r);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!),
            ),
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
                      const SizedBox(height: 4),
                      Text(
                        '$qty phòng • $usedNights đêm × ${_formatVnd(perNight)} / đêm',
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
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tạm tính tiền phòng',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              _formatVnd(data.roomsTotal),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),

        const Divider(height: 32),

        const Text(
          'Giá thêm (bạn đã chọn)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (data.selectedExtras.isEmpty)
          Text(
            'Không có mục giá thêm nào.',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          )
        else
          ...data.selectedExtras.map((e) {
            final name = (e['name'] ?? '').toString();
            final priceHtml = (e['price_html'] ?? '').toString();
            final rawPrice = (e['price'] ?? '').toString();

            final displayPrice = priceHtml.isNotEmpty
                ? priceHtml
                : (rawPrice.isNotEmpty ? '$rawPrice ₫' : '0 ₫');

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    displayPrice,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        if (data.extrasTotal > 0) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tổng giá thêm',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                _formatVnd(data.extrasTotal),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],

        const Divider(height: 32),

        const Text(
          'Phí dịch vụ (tự động)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (data.buyerFees.isEmpty)
          Text(
            'Không có phí dịch vụ nào.',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          )
        else
          ...data.buyerFees.map((fee) {
            final name =
            (fee['name'] ?? fee['type_name'] ?? 'Phí dịch vụ').toString();
            final priceHtml = (fee['price_html'] ?? '').toString();
            final rawPrice = (fee['price'] ?? '').toString();

            final displayPrice = priceHtml.isNotEmpty
                ? priceHtml
                : (rawPrice.isNotEmpty ? '$rawPrice ₫' : '0 ₫');

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$name (tự động áp dụng)',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    displayPrice,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        if (data.buyerFeesTotal > 0) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tổng phí dịch vụ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                _formatVnd(data.buyerFeesTotal),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],

        const Divider(height: 32),

        const Text(
          'Tổng kết chi phí',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(child: Text('Tiền phòng')),
            Text(_formatVnd(data.roomsTotal)),
          ],
        ),
        Row(
          children: [
            const Expanded(child: Text('Giá thêm (bạn chọn)')),
            Text(_formatVnd(data.extrasTotal)),
          ],
        ),
        Row(
          children: [
            const Expanded(child: Text('Phí dịch vụ (tự động)')),
            Text(_formatVnd(data.buyerFeesTotal)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tổng thanh toán',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              _formatVnd(data.grandTotal),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Công thức: tiền phòng (giá/đêm × số đêm × số phòng) '
              '+ giá thêm (bạn chọn) + phí dịch vụ (tự động).',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = 1;
              });
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Tiếp theo',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===================== STEP 2: NGƯỜI ĐẶT + THANH TOÁN =====================

  Widget _buildStep2(BuildContext context) {
    final data = widget.data;

    return Form(
      key: _formKey,
      child: ListView(
        children: [
          // Tóm tắt nhanh
          Text(
            data.hotelName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tổng thanh toán: ${_formatVnd(data.grandTotal)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Thông tin người đặt',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: firstNameController,
            label: 'Họ',
            icon: Icons.person_outline,
            validator: (v) =>
            v == null || v.isEmpty ? 'Vui lòng nhập họ' : null,
          ),
          _buildTextField(
            controller: lastNameController,
            label: 'Tên',
            icon: Icons.person,
            validator: (v) =>
            v == null || v.isEmpty ? 'Vui lòng nhập tên' : null,
          ),
          _buildTextField(
            controller: emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
            v == null || v.isEmpty ? 'Vui lòng nhập email' : null,
          ),
          _buildTextField(
            controller: phoneController,
            label: 'Số điện thoại',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          _buildTextField(
            controller: countryController,
            label: 'Quốc gia',
            icon: Icons.flag_outlined,
          ),
          _buildTextField(
            controller: cityController,
            label: 'Thành phố / Tỉnh',
            icon: Icons.location_city_outlined,
          ),
          _buildTextField(
            controller: addressController,
            label: 'Địa chỉ chi tiết',
            icon: Icons.home_outlined,
          ),
          _buildTextField(
            controller: specialRequestController,
            label: 'Yêu cầu đặc biệt',
            icon: Icons.message_outlined,
            maxLines: 3,
          ),

          const SizedBox(height: 16),

          const Text(
            'Phương thức thanh toán',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: paymentMethod,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(
                value: 'offline_payment',
                child: Text('Thanh toán tại khách sạn'),
              ),
              DropdownMenuItem(
                value: 'sepay',
                child: Text('Chuyển khoản qua SePay'),
              ),
            ],
            onChanged: (v) {
              setState(() {
                paymentMethod = v ?? 'offline_payment';
              });
            },
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: couponController,
            label: 'Mã giảm giá (nếu có)',
            icon: Icons.discount_outlined,
            suffixIcon: IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: () {
                // TODO: validate coupon nếu cần
              },
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = 0;
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Quay lại'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _submitBooking(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Đặt phòng',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Future<void> _submitBooking(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = widget.data;
      final dio = Dio();

      final String startDate = DateFormat('yyyy-MM-dd').format(data.checkIn);
      final String endDate   = DateFormat('yyyy-MM-dd').format(data.checkOut);
      final int totalGuests  = data.adults + data.children;

      final List<Map<String, dynamic>> roomsPayload = data.rooms.map((r) {
        final int qty = r.quantity <= 0 ? 1 : r.quantity;
        final int usedNights = data.nights > 0
            ? data.nights
            : (r.nights != null && r.nights! > 0 ? r.nights! : 1);

        return {
          'room_id': r.id,
          'name': r.name,
          'quantity': qty,
          'nights': usedNights,
          'price_per_night': r.pricePerNight,
          'line_total': _calcRoomLineTotal(r),
        };
      }).toList();

      // Body dùng chung cho cả store & sepay
      final body = {
        "object_model": "hotel",
        "object_id": data.hotelId,
        "start_date": startDate,
        "end_date": endDate,
        "total_guests": totalGuests,
        "gateway": paymentMethod,
        "amount": data.grandTotal.round(),
        "nights": data.nights,
        "adults": data.adults,
        "children": data.children,
        "customer_notes": specialRequestController.text,
        "coupon_code":
        couponController.text.isNotEmpty ? couponController.text : null,
        "contact_info": {
          "first_name": firstNameController.text,
          "last_name": lastNameController.text,
          "email": emailController.text,
          "phone": phoneController.text,
          "address": addressController.text,
          "city": cityController.text,
          "country": countryController.text,
        },
        "rooms": roomsPayload,
        "selected_extras": data.selectedExtras,
        "buyer_fees": data.buyerFees,
      };

      // ================== CASE 1: Thanh toán tại khách sạn ==================
      if (paymentMethod == 'offline_payment') {
        final response = await dio.post(
          '${AppConstants.travelBaseUrl}/bookings',
          data: body,
          options: Options(
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        );

        if (response.statusCode == 201 && response.data['success'] == true) {
          final bookingData = response.data['data'];

          final createdAtString = bookingData['created_at']?.toString() ?? '';
          final createdAt =
              DateTime.tryParse(createdAtString) ?? DateTime.now();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đặt phòng thành công'),
              backgroundColor: Colors.green,
            ),
          );

          if (!mounted) return;

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => HotelBookingBillScreen(
                data: data,
                bookingCode: bookingData['code']?.toString() ?? '',
                bookingStatus: bookingData['status']?.toString() ?? 'unpaid',
                paymentMethod: paymentMethod,
                createdAt: createdAt,
                firstName: firstNameController.text,
                lastName: lastNameController.text,
                email: emailController.text,
                phone: phoneController.text,
                address: addressController.text,
                city: cityController.text,
                country: countryController.text,
                specialRequest: specialRequestController.text,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lỗi: ${response.data['message'] ?? 'Không thể đặt phòng'}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }

        return;
      }

      // ================== CASE 2: Thanh toán bằng SePay (QR) ==================
      if (paymentMethod == 'sepay') {
        final response = await dio.post(
          '${AppConstants.travelBaseUrl}/bookings/sepay/payment',
          data: body,
          options: Options(
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        );

        if (response.statusCode == 200 && response.data['status'] == true) {
          final dataRes = response.data['data'];

          final bookingCode  = dataRes['order_code']?.toString() ?? '';
          final paymentId    = dataRes['payment_id'];
          final amount       = (dataRes['amount'] ?? 0) as num;
          final qrLink       = dataRes['qr_link']?.toString() ?? '';
          final bankAccount  = dataRes['bank_account']?.toString() ?? '';
          final bankName     = dataRes['bank_name']?.toString() ?? '';
          final accountName  = dataRes['account_name']?.toString() ?? '';
          final rawContent   = dataRes['content']?.toString() ?? '';
          final content      = Uri.decodeComponent(rawContent);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo QR thanh toán thành công'),
              backgroundColor: Colors.green,
            ),
          );

          if (!mounted) return;

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => HotelSepayPaymentScreen(
                data: data,
                bookingCode: bookingCode,
                paymentId: paymentId?.toString() ?? '',
                amount: amount.toDouble(),
                qrLink: qrLink,
                bankAccount: bankAccount,
                bankName: bankName,
                accountName: accountName,
                transferContent: content,
                firstName: firstNameController.text,
                lastName: lastNameController.text,
                email: emailController.text,
                phone: phoneController.text,
                address: addressController.text,
                city: cityController.text,
                country: countryController.text,
                specialRequest: specialRequestController.text,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lỗi SePay: ${response.data['message'] ?? 'Không thể tạo QR thanh toán'}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }

        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đặt phòng thất bại: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}