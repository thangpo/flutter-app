import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../services/hotel_service.dart';
import 'hotel_booking_bill_screen.dart';
import 'package:flutter/material.dart';
import 'hotel_sepay_payment_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/hotel_rooms_section.dart' show HotelSelectedRoom;
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/logging_interceptor.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/domain/repositories/profile_repository.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

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
  final String? hotelImage;
  final double? hotelRating;
  final int? reviewCount;
  final String? hotelLocation;

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
    this.hotelImage,
    this.hotelRating,
    this.reviewCount,
    this.hotelLocation,
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
  final TextEditingController specialRequestController =
  TextEditingController();
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
    } catch (_) {}
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
    final int usedNights = data.nights > 0
        ? data.nights
        : (r.nights != null && r.nights! > 0 ? r.nights! : 1);
    final double perNight = r.pricePerNight;
    return perNight * usedNights * qty;
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String title = _currentStep == 0
        ? (getTranslated('hotel_booking_info', context) ??
        'Thông tin đặt phòng')
        : (getTranslated('guest_and_payment_info', context) ??
        'Thông tin người đặt & thanh toán');

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _currentStep == 0
              ? _buildStep1(context, dateFmt, isDark)
              : _buildStep2(context),
        ),
      ),
    );
  }

  Widget _buildStep1(
      BuildContext context, DateFormat dateFmt, bool isDark) {
    final data = widget.data;

    return ListView(
      children: [
        _buildHotelHeaderCard(context, dateFmt, data, isDark),
        const SizedBox(height: 24),

        // Phòng đã chọn
        Text(
          getTranslated('selected_rooms', context) ?? 'Phòng đã chọn',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        if (data.rooms.isEmpty)
          Text(
            getTranslated('no_room_selected', context) ??
                'Không có phòng nào, vui lòng quay lại chọn phòng.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
          )
        else
          ...data.rooms.map(
                (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildRoomCard(context, r, data, isDark),
            ),
          ),

        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                getTranslated('room_subtotal', context) ??
                    'Tạm tính tiền phòng',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            Text(
              _formatVnd(data.roomsTotal),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),

        const Divider(height: 32),

        // Giá thêm
        Text(
          getTranslated('extra_prices_selected', context) ??
              'Giá thêm (bạn đã chọn)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        if (data.selectedExtras.isEmpty)
          Text(
            getTranslated('no_extra_selected', context) ??
                'Không có mục giá thêm nào.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
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
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    displayPrice,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
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
              Expanded(
                child: Text(
                  getTranslated('extra_total', context) ?? 'Tổng giá thêm',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
              Text(
                _formatVnd(data.extrasTotal),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],

        const Divider(height: 32),

        // Phí dịch vụ
        Text(
          getTranslated('service_fees_auto', context) ??
              'Phí dịch vụ (tự động)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        if (data.buyerFees.isEmpty)
          Text(
            getTranslated('no_service_fees', context) ??
                'Không có phí dịch vụ nào.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
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

            final autoText =
                getTranslated('service_fee_auto_suffix', context) ??
                    '(tự động áp dụng)';

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$name $autoText',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    displayPrice,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
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
              Expanded(
                child: Text(
                  getTranslated('service_fees_total', context) ??
                      'Tổng phí dịch vụ',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
              Text(
                _formatVnd(data.buyerFeesTotal),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],

        const Divider(height: 32),

        // Tổng kết chi phí
        Text(
          getTranslated('cost_summary', context) ?? 'Tổng kết chi phí',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                getTranslated('room_cost', context) ?? 'Tiền phòng',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            Text(_formatVnd(data.roomsTotal)),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                getTranslated('extra_cost', context) ??
                    'Giá thêm (bạn chọn)',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            Text(_formatVnd(data.extrasTotal)),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                getTranslated('service_fees_cost', context) ??
                    'Phí dịch vụ (tự động)',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            Text(_formatVnd(data.buyerFeesTotal)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                getTranslated('grand_total', context) ?? 'Tổng thanh toán',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
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
          getTranslated('cost_formula_note', context) ??
              'Công thức: tiền phòng (giá/đêm × số đêm × số phòng) '
                  '+ giá thêm (bạn chọn) + phí dịch vụ (tự động).',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.grey[700],
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
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                getTranslated('next', context) ?? 'Tiếp theo',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(BuildContext context) {
    final data = widget.data;

    return Form(
      key: _formKey,
      child: ListView(
        children: [
          Text(
            data.hotelName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${getTranslated('grand_total', context) ?? 'Tổng thanh toán'}: ${_formatVnd(data.grandTotal)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            getTranslated('guest_info', context) ?? 'Thông tin người đặt',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: firstNameController,
            label: getTranslated('first_name', context) ?? 'Họ',
            icon: Icons.person_outline,
            validator: (v) => v == null || v.isEmpty
                ? getTranslated('validation_first_name_required', context) ??
                'Vui lòng nhập họ'
                : null,
          ),
          _buildTextField(
            controller: lastNameController,
            label: getTranslated('last_name', context) ?? 'Tên',
            icon: Icons.person,
            validator: (v) => v == null || v.isEmpty
                ? getTranslated('validation_last_name_required', context) ??
                'Vui lòng nhập tên'
                : null,
          ),
          _buildTextField(
            controller: emailController,
            label: getTranslated('email', context) ?? 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v == null || v.isEmpty
                ? getTranslated('validation_email_required', context) ??
                'Vui lòng nhập email'
                : null,
          ),
          _buildTextField(
            controller: phoneController,
            label:
            getTranslated('phone_number', context) ?? 'Số điện thoại',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          _buildTextField(
            controller: countryController,
            label: getTranslated('country', context) ?? 'Quốc gia',
            icon: Icons.flag_outlined,
          ),
          _buildTextField(
            controller: cityController,
            label:
            getTranslated('city_province', context) ?? 'Thành phố / Tỉnh',
            icon: Icons.location_city_outlined,
          ),
          _buildTextField(
            controller: addressController,
            label:
            getTranslated('address_detail', context) ?? 'Địa chỉ chi tiết',
            icon: Icons.home_outlined,
          ),
          _buildTextField(
            controller: specialRequestController,
            label: getTranslated('special_request', context) ??
                'Yêu cầu đặc biệt',
            icon: Icons.message_outlined,
            maxLines: 3,
          ),

          const SizedBox(height: 16),

          Text(
            getTranslated('payment_method', context) ??
                'Phương thức thanh toán',
            style: const TextStyle(
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
            items: [
              DropdownMenuItem(
                value: 'offline_payment',
                child: Text(
                  getTranslated('payment_offline', context) ??
                      'Thanh toán tại khách sạn',
                ),
              ),
              DropdownMenuItem(
                value: 'sepay',
                child: Text(
                  getTranslated('payment_sepay', context) ??
                      'Chuyển khoản qua SePay',
                ),
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
            label: getTranslated('coupon_code_optional', context) ??
                'Mã giảm giá (nếu có)',
            icon: Icons.discount_outlined,
            suffixIcon: IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: () {
                // TODO: validate coupon
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      getTranslated('back', context) ?? 'Quay lại',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                  _isLoading ? null : () => _submitBooking(context),
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
                        : Text(
                      getTranslated('book_now', context) ?? 'Đặt phòng',
                      style: const TextStyle(fontSize: 16),
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

  Widget _buildHotelHeaderCard(
      BuildContext context,
      DateFormat dateFmt,
      HotelCheckoutData data,
      bool isDark,
      ) {
    final String dateRange =
        '${dateFmt.format(data.checkIn)} - ${dateFmt.format(data.checkOut)}';
    final String guestText =
        '${data.adults} ${getTranslated('adults', context) ?? 'người lớn'}, '
        '${data.children} ${getTranslated('children', context) ?? 'trẻ em'}';

    final double radius = 24;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
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
                color: Colors.grey[300],
                child: const Icon(Icons.hotel, size: 60, color: Colors.grey),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.35),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.ios_share_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite_border_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
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
                  Row(
                    children: [
                      if (data.hotelRating != null &&
                          data.hotelRating! > 0) ...[
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          data.hotelRating!.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (data.reviewCount != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${data.reviewCount} ${getTranslated('reviews', context) ?? 'đánh giá'})',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.person, size: 12, color: Colors.white),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            data.reviewCount != null
                                ? '${data.reviewCount} ${getTranslated('reviews', context) ?? 'reviews'}'
                                : '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$dateRange  •  ${data.nights} ${getTranslated('nights', context) ?? 'đêm'}  •  $guestText',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
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

  Widget _buildRoomCard(
      BuildContext context,
      HotelSelectedRoom r,
      HotelCheckoutData data,
      bool isDark,
      ) {
    final int qty = r.quantity <= 0 ? 1 : r.quantity;
    final int usedNights = data.nights > 0
        ? data.nights
        : (r.nights != null && r.nights! > 0 ? r.nights! : 1);
    final double perNight = r.pricePerNight;
    final double lineTotal = _calcRoomLineTotal(r);

    final Color cardBg = isDark ? const Color(0xFF181A1F) : Colors.white;
    final Color borderColor = isDark ? Colors.white10 : Colors.grey[200]!;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 72,
                height: 72,
                child: (r.imageUrl != null && r.imageUrl!.isNotEmpty)
                    ? Image.network(
                  r.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: isDark
                        ? const Color(0xFF262932)
                        : Colors.grey[200],
                    child: const Icon(
                      Icons.bed_rounded,
                      size: 32,
                      color: Colors.grey,
                    ),
                  ),
                )
                    : Container(
                  color: isDark
                      ? const Color(0xFF262932)
                      : Colors.grey[200],
                  child: const Icon(
                    Icons.bed_rounded,
                    size: 32,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getTranslated('default_room_type', context) ??
                        'Deluxe Room',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$qty ${getTranslated('rooms', context) ?? 'phòng'} • '
                        '$usedNights ${getTranslated('nights', context) ?? 'đêm'} × ${_formatVnd(perNight)} / ${getTranslated('per_night', context) ?? 'đêm'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        getTranslated('line_total_label', context) ??
                            'Giá tổng',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                    ],
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
                    fontWeight: FontWeight.w700,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '/${data.nights > 0 ? '${data.nights} ${getTranslated('nights', context) ?? 'đêm'}' : (getTranslated('room_booking', context) ?? 'đặt phòng')}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
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
      final String endDate = DateFormat('yyyy-MM-dd').format(data.checkOut);
      final int totalGuests = data.adults + data.children;

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

        if (response.statusCode == 201 &&
            response.data['success'] == true) {
          final bookingData = response.data['data'];

          final createdAtString =
              bookingData['created_at']?.toString() ?? '';
          final createdAt =
              DateTime.tryParse(createdAtString) ?? DateTime.now();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                getTranslated('booking_success', context) ??
                    'Đặt phòng thành công',
              ),
              backgroundColor: Colors.green,
            ),
          );

          if (!mounted) return;

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => HotelBookingBillScreen(
                data: data,
                bookingCode: bookingData['code']?.toString() ?? '',
                bookingStatus:
                bookingData['status']?.toString() ?? 'unpaid',
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
          final msg = response.data['message'] ??
              (getTranslated('booking_error_generic', context) ??
                  'Không thể đặt phòng');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
              Text('${getTranslated('error_prefix', context) ?? 'Lỗi'}: $msg'),
              backgroundColor: Colors.red,
            ),
          );
        }

        return;
      }

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

        if (response.statusCode == 200 &&
            response.data['status'] == true) {
          final dataRes = response.data['data'];

          final bookingCode = dataRes['order_code']?.toString() ?? '';
          final paymentId = dataRes['payment_id'];
          final amount = (dataRes['amount'] ?? 0) as num;
          final qrLink = dataRes['qr_link']?.toString() ?? '';
          final bankAccount = dataRes['bank_account']?.toString() ?? '';
          final bankName = dataRes['bank_name']?.toString() ?? '';
          final accountName = dataRes['account_name']?.toString() ?? '';
          final rawContent = dataRes['content']?.toString() ?? '';
          final content = Uri.decodeComponent(rawContent);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                getTranslated('sepay_create_qr_success', context) ??
                    'Tạo QR thanh toán thành công',
              ),
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
          final msg = response.data['message'] ??
              (getTranslated('sepay_error_generic', context) ??
                  'Không thể tạo QR thanh toán');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${getTranslated('sepay_error_prefix', context) ?? 'Lỗi SePay'}: $msg',
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
          content: Text(
            '${getTranslated('booking_failed', context) ?? 'Đặt phòng thất bại'}: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}