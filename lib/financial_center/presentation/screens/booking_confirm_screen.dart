import 'sepay_qr_page.dart';
import 'package:intl/intl.dart';
import 'booking_success_page.dart';
import '../models/booking_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/booking_api_service.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

class BookingConfirmScreen extends StatefulWidget {
  const BookingConfirmScreen({super.key});

  @override
  State<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends State<BookingConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _serviceReady = false;

  final PageController _pageController = PageController(initialPage: 0);
  int _currentStep = 0;

  late BookingApiService _bookingApi;

  final NumberFormat _vndFormatter =
  NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController wardController = TextEditingController();
  final TextEditingController postalController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController specialRequestController =
  TextEditingController();
  final TextEditingController couponController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String paymentMethod = 'offline_payment';

  String selectedCountry = 'Việt Nam';
  final List<String> countries = ['Việt Nam'];

  String? selectedProvince;
  String? selectedDistrict;
  String? selectedWard;

  List<dynamic> provinces = [];
  List<dynamic> districts = [];
  List<dynamic> wards = [];

  @override
  void initState() {
    super.initState();
    _initServicesAndData();
  }

  Future<void> _initServicesAndData() async {
    _bookingApi = await BookingApiService.create();
    final userData = await _bookingApi.loadUserProfile();
    if (userData != null) {
      firstNameController.text = userData['f_name'] ?? '';
      lastNameController.text = userData['l_name'] ?? '';
      emailController.text = userData['email'] ?? '';
      countryController.text = userData['country'] ?? '';
      phoneController.text = userData['phone'] ?? '';
    }

    provinces = await _bookingApi.fetchProvinces();

    if (mounted) {
      setState(() {
        _serviceReady = true;
      });
    }
  }

  Future<void> _onProvinceChanged(String provinceId) async {
    districts = await _bookingApi.fetchDistricts(provinceId);
    setState(() {
      selectedProvince = provinceId;
      selectedDistrict = null;
      selectedWard = null;
      wards = [];
      cityController.text = provinces
          .firstWhere(
              (p) => p['ProvinceID'].toString() == provinceId)['ProvinceName']
          .toString();
    });
  }

  Future<void> _onDistrictChanged(String districtId) async {
    wards = await _bookingApi.fetchWards(districtId);
    setState(() {
      selectedDistrict = districtId;
      selectedWard = null;
      districtController.text = districts
          .firstWhere(
              (d) => d['DistrictID'].toString() == districtId)['DistrictName']
          .toString();
    });
  }

  void _onWardChanged(String wardCode) {
    setState(() {
      selectedWard = wardCode;
      wardController.text = wards
          .firstWhere((w) => w['WardCode'].toString() == wardCode)['WardName']
          .toString();
    });
  }

  bool _validateStep(int step) {
    String? message;

    if (step == 0) {
      if (firstNameController.text.trim().isEmpty ||
          lastNameController.text.trim().isEmpty ||
          emailController.text.trim().isEmpty ||
          phoneController.text.trim().isEmpty) {
        message = getTranslated('fill_all_personal_info', context) ??
            'Vui lòng nhập đầy đủ Họ, Tên, Email, Số điện thoại.';
      }
    } else if (step == 1) {
      if (selectedCountry.isEmpty ||
          selectedProvince == null ||
          selectedDistrict == null ||
          selectedWard == null ||
          postalController.text.trim().isEmpty ||
          addressController.text.trim().isEmpty) {
        message = getTranslated('fill_all_address_info', context) ??
            'Vui lòng nhập đầy đủ thông tin địa chỉ.';
      }
    }

    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return false;
    }
    return true;
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = ModalRoute.of(context)!.settings.arguments as BookingData;

    final themeCtrl = Provider.of<ThemeController>(context, listen: true);
    final isDark = themeCtrl.darkTheme;

    final Color primaryColor =
    isDark ? const Color(0xFF64B5F6) : const Color(0xFF0077BE);
    final Color bgColor =
    isDark ? const Color(0xFF050812) : const Color(0xFFF5F7FB);
    final Color cardColor =
    isDark ? const Color(0xFF111827) : Colors.white;
    final Color textPrimary =
    isDark ? Colors.white : const Color(0xFF111827);
    final Color textSecondary =
    isDark ? Colors.white70 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const SizedBox.shrink(),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: !_serviceReady
          ? Center(
        child: CircularProgressIndicator(color: primaryColor),
      )
          : SafeArea(
        top: false,
        bottom: true,
        child: Column(
          children: [
            _buildHeroHeader(
              booking,
              primaryColor: primaryColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),

            Expanded(
              child: Padding(
                padding:
                const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildStepIndicator(
                        isDark: isDark,
                        primaryColor: primaryColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),

                      const SizedBox(height: 12),

                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (i) {
                            setState(() => _currentStep = i);
                          },
                          children: [
                            _buildStep1(
                                cardColor, textPrimary, textSecondary),
                            _buildStep2(
                                cardColor, textPrimary, textSecondary),
                            _buildStep3(cardColor, textPrimary,
                                textSecondary, primaryColor),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      _buildBottomButtons(
                        booking: booking,
                        primaryColor: primaryColor,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(
      BookingData booking, {
        required Color primaryColor,
        required Color textPrimary,
        required Color textSecondary,
      }) {
    const double headerHeight = 320;
    return SizedBox(
      height: headerHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            booking.tourImage,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade300,
              alignment: Alignment.center,
              child: Icon(Icons.image_not_supported,
                  size: 40, color: Colors.grey.shade600),
            ),
          ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.05),
                  Colors.black.withOpacity(0.55),
                ],
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.tourName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            '${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.people,
                              size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            '${booking.numberOfPeople} ${getTranslated('guests', context) ?? 'Guests'}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
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
                      _vndFormatter.format(booking.total),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 12,
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

  Widget _buildStepIndicator({
    required bool isDark,
    required Color primaryColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final steps = [
      getTranslated('booker_info', context) ?? 'booker_info',
      getTranslated('address_info', context) ?? 'address_info',
      getTranslated('payment_info', context) ?? 'payment_info',
    ];

    return Row(
      children: List.generate(3, (index) {
        final bool active = index == _currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: active
                  ? primaryColor
                  : (isDark ? const Color(0xFF111827) : Colors.white),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: active
                    ? primaryColor
                    : (isDark
                    ? Colors.white24
                    : Colors.grey.shade300),
              ),
            ),
            child: Center(
              child: Text(
                steps[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : textSecondary,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStep1(
      Color cardColor, Color textPrimary, Color textSecondary) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildTextField(
              controller: firstNameController,
              label: getTranslated('first_name', context) ?? 'First name',
              icon: Icons.person_outline,
            ),
            _buildTextField(
              controller: lastNameController,
              label: getTranslated('last_name', context) ?? 'Last name',
              icon: Icons.person,
            ),
            _buildTextField(
              controller: emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            _buildTextField(
              controller: phoneController,
              label: getTranslated('phone', context) ?? 'Phone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2(
      Color cardColor, Color textPrimary, Color textSecondary) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildCountryDropdown(),
            const SizedBox(height: 12),
            _buildProvinceDistrict(),
            const SizedBox(height: 12),
            _buildWardPostal(),
            _buildTextField(
              controller: addressController,
              label: getTranslated('address', context) ?? 'Address',
              icon: Icons.home_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3(
      Color cardColor,
      Color textPrimary,
      Color textSecondary,
      Color primaryColor,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildTextField(
              controller: specialRequestController,
              label: getTranslated('special_request', context) ??
                  'Special request (optional)',
              icon: Icons.message_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            _buildPaymentDropdown(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: couponController,
              label: getTranslated('coupon_optional', context) ??
                  'Coupon (optional)',
              icon: Icons.discount_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons({
    required BookingData booking,
    required Color primaryColor,
    required bool isDark,
  }) {
    final Color backBg = isDark ? const Color(0xFF111827) : Colors.white;
    final Color backBorder =
    isDark ? Colors.white24 : Colors.grey.shade300;

    ButtonStyle _primaryStyle = ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );

    if (_currentStep == 0) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading
              ? null
              : () {
            if (_validateStep(0)) {
              _goToStep(1);
            }
          },
          style: _primaryStyle,
          child: Text(
            getTranslated('next', context) ?? 'next',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              final prev = _currentStep == 2 ? 1 : 0;
              _goToStep(prev);
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: backBg,
              foregroundColor:
              isDark ? Colors.white70 : Colors.grey.shade800,
              side: BorderSide(color: backBorder),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              getTranslated('back', context) ?? 'back',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
              if (_currentStep == 1) {
                if (_validateStep(1)) {
                  _goToStep(2);
                }
              } else {
                if (!_validateStep(0)) {
                  _goToStep(0);
                  return;
                }
                if (!_validateStep(1)) {
                  _goToStep(1);
                  return;
                }
                await _bookTour(booking);
              }
            },
            style: _primaryStyle,
            child: _isLoading && _currentStep == 2
                ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
                : Text(
              _currentStep == 1
                  ? (getTranslated('next', context) ?? 'next')
                  : (getTranslated('pay_now', context) ??
                  'Thanh toán'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedCountry,
      decoration: InputDecoration(
        labelText: getTranslated('country', context) ?? 'Country',
        prefixIcon: const Icon(Icons.flag_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      items: countries.map((country) {
        return DropdownMenuItem<String>(
          value: country,
          child: Text(country),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedCountry = value!;
          countryController.text = value;
        });
      },
    );
  }

  Widget _buildProvinceDistrict() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: selectedProvince,
          decoration: InputDecoration(
            labelText: getTranslated('province_city', context) ?? 'Province/City',
            prefixIcon: const Icon(Icons.location_city),
            border: const OutlineInputBorder(),
          ),
          items: provinces.map((item) {
            return DropdownMenuItem<String>(
              value: item['ProvinceID'].toString(),
              child: Text(
                item['ProvinceName'],
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            _onProvinceChanged(value);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: selectedDistrict,
          decoration: InputDecoration(
            labelText: getTranslated('district', context) ?? 'District',
            prefixIcon: const Icon(Icons.map_outlined),
            border: const OutlineInputBorder(),
          ),
          items: districts.map((item) {
            return DropdownMenuItem<String>(
              value: item['DistrictID'].toString(),
              child: Text(
                item['DistrictName'],
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            _onDistrictChanged(value);
          },
        ),
      ],
    );
  }

  Widget _buildWardPostal() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: selectedWard,
          decoration: InputDecoration(
            labelText: getTranslated('ward', context) ?? 'Ward',
            prefixIcon: const Icon(Icons.place_outlined),
            border: const OutlineInputBorder(),
          ),
          items: wards.map((item) {
            return DropdownMenuItem<String>(
              value: item['WardCode'].toString(),
              child: Text(item['WardName']),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            _onWardChanged(value);
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: postalController,
          label:
          getTranslated('postal_code', context) ?? 'Postal code',
          icon: Icons.markunread_mailbox_outlined,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildPaymentDropdown() {
    return DropdownButtonFormField<String>(
      value: paymentMethod,
      decoration: InputDecoration(
        labelText:
        getTranslated('payment_method', context) ?? 'Payment method',
        prefixIcon:
        Icon(Icons.account_balance_wallet, color: Colors.blue.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      items: [
        DropdownMenuItem(
          value: 'offline_payment',
          child: Text(getTranslated('pay_offline', context) ??
              'Thanh toán khi nhận tour'),
        ),
        DropdownMenuItem(
          value: 'sepay',
          child: Text(getTranslated('pay_sepay', context) ??
              'Chuyển khoản qua SePay'),
        ),
      ],
      onChanged: (v) => setState(() => paymentMethod = v!),
    );
  }

  Future<void> _bookTour(BookingData booking) async {
    if (!_serviceReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(getTranslated('please_wait', context) ??
                'Đang khởi tạo, vui lòng thử lại...')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      "object_model": "tour",
      "object_id": booking.tourId,
      "start_date": booking.startDate.toIso8601String().split('T').first,
      "total_guests": booking.numberOfPeople,
      "gateway": paymentMethod,
      "customer_notes": specialRequestController.text,
      "zip_code": postalController.text,
      "coupon_code":
      couponController.text.isNotEmpty ? couponController.text : null,
      "amount": booking.total.toStringAsFixed(0),
      "contact_info": {
        "first_name": firstNameController.text,
        "last_name": lastNameController.text,
        "email": emailController.text,
        "phone":
        phoneController.text.isNotEmpty ? phoneController.text : "",
        "address": addressController.text,
        "city": cityController.text,
        "country": countryController.text,
      }
    };

    try {
      if (paymentMethod == 'sepay') {
        final response = await _bookingApi.createSepayPayment(data);

        if (response.statusCode == 200 && response.data['status'] == true) {
          // dữ liệu gốc từ API
          final Map<String, dynamic> raw =
          Map<String, dynamic>.from(response.data['data'] ?? {});

          // ghép thêm thông tin để màn QR dùng
          final Map<String, dynamic> paymentInfo = {
            ...raw,
            'tour_image': booking.tourImage, // ảnh nền
            'tour_name': booking.tourName,
            // tên shop nếu muốn hiển thị ở dưới QR
            'store_name': getTranslated('app_name', context) ?? 'VietnamToure',
            // thông tin khách
            'customer_name':
            '${firstNameController.text} ${lastNameController.text}'.trim(),
            'phone': phoneController.text,
            // đảm bảo amount có dạng số
            'amount': booking.total.toInt(),
          };

          // sang màn QR
          // ignore: use_build_context_synchronously
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SepayQrPage(paymentData: paymentInfo),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.data['message'] ?? 'Không thể tạo QR thanh toán',
              ),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      } else {
        final response = await _bookingApi.createOfflineBooking(data);

        if (response.statusCode == 201 &&
            response.data['success'] == true) {
          // dữ liệu gốc từ API
          final Map<String, dynamic> raw =
          Map<String, dynamic>.from(response.data['data'] ?? {});

          // GHÉP thêm thông tin tour từ BookingData để màn success dùng làm nền
          final Map<String, dynamic> bookingInfo = {
            ...raw,
            'tour_image': booking.tourImage,   // ảnh nền
            'tour_name' : booking.tourName,    // tên tour
          };

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  BookingSuccessPage(bookingInfo: bookingInfo),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lỗi: ${response.data['message'] ?? 'Không thể đặt tour'}',
              ),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đặt tour thất bại: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}