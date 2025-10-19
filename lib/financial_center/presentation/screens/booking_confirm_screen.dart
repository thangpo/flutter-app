import 'package:flutter/material.dart';
import '../models/booking_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/logging_interceptor.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/domain/repositories/profile_repository.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'sepay_qr_page.dart';
import 'package:dio/dio.dart';
import 'booking_success_page.dart';

class BookingConfirmScreen extends StatefulWidget {
  const BookingConfirmScreen({super.key});

  @override
  State<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends State<BookingConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

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
  late ProfileRepository _profileRepository;

  @override
  void initState() {
    super.initState();
    _initProfileRepo();
  }

  Future<void> _initProfileRepo() async {
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
  }

  Future<void> _loadUserData() async {
    final response = await _profileRepository.getProfileInfo();
    if (response.isSuccess) {
      final userData = response.response.data;
      setState(() {
        firstNameController.text = userData['f_name'] ?? '';
        lastNameController.text = userData['l_name'] ?? '';
        emailController.text = userData['email'] ?? '';
        countryController.text = userData['country'] ?? '';
        phoneController.text = userData['phone'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = ModalRoute.of(context)!.settings.arguments as BookingData;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Xác nhận đặt tour',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade600, Colors.cyan.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_outline,
                          color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Hoàn tất đặt tour',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vui lòng điền thông tin để hoàn tất',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
                      shadowColor: Colors.teal.shade100,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.teal.shade50.withOpacity(0.3)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    booking.tourImage,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.image_not_supported,
                                          size: 40,
                                          color: Colors.teal.shade300),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking.tourName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal.shade900,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            size: 16,
                                            color: Colors.teal.shade600),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year}',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.people,
                                            size: 16,
                                            color: Colors.teal.shade600),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${booking.numberOfPeople} người',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade600,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${booking.total.toStringAsFixed(0)} ₫',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
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
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.person,
                              color: Colors.teal.shade700, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Thông tin người đặt',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: firstNameController,
                      label: 'Họ',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          v?.isEmpty == true ? 'Vui lòng nhập họ' : null,
                    ),
                    _buildTextField(
                      controller: lastNameController,
                      label: 'Tên',
                      icon: Icons.person,
                      validator: (v) =>
                          v?.isEmpty == true ? 'Vui lòng nhập tên' : null,
                    ),
                    _buildTextField(
                      controller: emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v?.isEmpty == true ? 'Vui lòng nhập email' : null,
                    ),
                    _buildTextField(
                      controller: phoneController,
                      label: 'Số điện thoại',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildTextField(
                      controller: addressController,
                      label: 'Địa chỉ',
                      icon: Icons.home_outlined,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: cityController,
                            label: 'Thành phố',
                            icon: Icons.location_city,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: districtController,
                            label: 'Quận/Huyện',
                            icon: Icons.map_outlined,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: wardController,
                            label: 'Xã/Phường',
                            icon: Icons.place_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: postalController,
                            label: 'Mã bưu điện',
                            icon: Icons.markunread_mailbox_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    _buildTextField(
                      controller: countryController,
                      label: 'Quốc gia',
                      icon: Icons.flag_outlined,
                    ),
                    _buildTextField(
                      controller: specialRequestController,
                      label: 'Yêu cầu đặc biệt',
                      icon: Icons.message_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.payment,
                              color: Colors.teal.shade700, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Phương thức thanh toán',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.shade100.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: paymentMethod,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.account_balance_wallet,
                              color: Colors.teal.shade600),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'offline_payment',
                            child: Text('Thanh toán khi nhận tour'),
                          ),
                          DropdownMenuItem(
                            value: 'ONLINE',
                            child: Text('Thanh toán online'),
                          ),
                          DropdownMenuItem(
                            value: 'sepay',
                            child: Text('Chuyển khoản qua SePay'),
                          ),
                        ],
                        onChanged: (v) => setState(() => paymentMethod = v!),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: couponController,
                      label: 'Mã giảm giá (nếu có)',
                      icon: Icons.discount_outlined,
                      suffixIcon: IconButton(
                        icon: Icon(Icons.check_circle,
                            color: Colors.teal.shade600),
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade600, Colors.cyan.shade500],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.shade300.withOpacity(0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _bookTour(booking),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Đang xử lý...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Hoàn tất đặt tour',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward,
                                      color: Colors.white),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.shade100.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey.shade600),
            prefixIcon: Icon(icon, color: Colors.teal.shade600),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.teal.shade100, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }

  Future<void> _bookTour(BookingData booking) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final dio = Dio();
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
          "phone": phoneController.text.isNotEmpty ? phoneController.text : "",
          "address": addressController.text,
          "city": cityController.text,
          "country": countryController.text,
        }
      };

      Response response;

      if (paymentMethod == 'sepay') {
        response = await dio.post(
          'https://vietnamtoure.com/api/bookings/sepay/payment',
          data: data,
          options: Options(headers: {'Accept': 'application/json'}),
        );

        if (response.statusCode == 200 && response.data['status'] == true) {
          final paymentInfo = response.data['data'];
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
                  response.data['message'] ?? 'Không thể tạo QR thanh toán'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      } else {
        response = await dio.post(
          'https://vietnamtoure.com/api/bookings',
          data: data,
          options: Options(
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        );

        if (response.statusCode == 201 && response.data['success'] == true) {
          final bookingData = response.data['data'];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  BookingSuccessPage(bookingInfo: bookingData),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Lỗi: ${response.data['message'] ?? 'Không thể đặt tour'}'),
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
      setState(() => _isLoading = false);
    }
  }
}
