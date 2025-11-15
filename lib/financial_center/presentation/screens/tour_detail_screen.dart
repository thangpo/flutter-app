import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/domain/services/auth_service.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import '../models/booking_data.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/di_container.dart' as di;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';

class TourDetailScreen extends StatefulWidget {
  final int tourId;
  const TourDetailScreen({super.key, required this.tourId});

  @override
  State<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends State<TourDetailScreen> {
  Map<String, dynamic>? tourData;
  bool isLoading = true;

  // Light mode colors
  static const Color primaryOcean = Color(0xFF0077BE);
  static const Color lightOcean = Color(0xFF4DA6D6);
  static const Color paleOcean = Color(0xFFE3F2FD);

  // Dark mode colors
  static const Color darkPrimary = Color(0xFF64B5F6);
  static const Color darkSecondary = Color(0xFF42A5F5);
  static final Color darkBackground = Colors.grey[900]!;
  static final Color darkCard = Colors.grey[850]!;

  @override
  void initState() {
    super.initState();
    fetchTourDetail();
  }

  Future<void> fetchTourDetail() async {
    final url = Uri.parse("https://vietnamtoure.com/api/tours/${widget.tourId}");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonRes = json.decode(response.body);
      setState(() {
        tourData = jsonRes['data'];
        isLoading = false;
      });
    }
  }

  void _bookTour() async {
    final theme = Provider.of<ThemeController>(context, listen: false);
    final isDark = theme.darkTheme;
    final authService = di.sl<AuthService>();
    final isLoggedIn = authService.isLoggedIn();

    if (!isLoggedIn) {
      showDialog(
        context: context,
        builder: (context) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey[900]!.withOpacity(0.7)
                        : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (isDark ? darkPrimary : primaryOcean).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          color: isDark ? darkPrimary : primaryOcean,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        getTranslated('login_required', context) ?? 'Yêu cầu đăng nhập',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        getTranslated('please_login_to_book', context) ?? 'Vui lòng đăng nhập để đặt tour.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: isDark ? Colors.white70 : Colors.grey[700],
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                getTranslated('cancel', context) ?? 'Hủy',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [darkPrimary, darkSecondary]
                                      : [primaryOcean, lightOcean],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark ? darkPrimary : primaryOcean).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/login');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  getTranslated('login', context) ?? 'Đăng nhập',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final bookingData = tourData?['booking_data'];
        final personTypes = bookingData['person_types'] as List<dynamic>;
        final extras = bookingData['extra_price'] as List<dynamic>;

        DateTime? selectedDate;
        Map<String, int> quantities = {
          for (var p in personTypes) p['name']: p['number'],
        };
        Map<String, bool> extrasSelected = {
          for (var e in extras) e['name']: e['enable'] == 1,
        };

        double calculateTotal() {
          double total = double.tryParse(tourData?['sale_price']?.toString() ??
              tourData?['price']?.toString() ?? '0') ?? 0.0;

          for (var p in personTypes) {
            final name = p['name'];
            final price = double.parse(p['price']);
            total += (quantities[name] ?? 0) * price;
          }

          for (var e in extras) {
            final name = e['name'];
            if (extrasSelected[name] == true) {
              total += double.parse(e['price']);
            }
          }
          return total;
        }

        return StatefulBuilder(
          builder: (context, setState) {
            final theme = Provider.of<ThemeController>(context);
            final isDark = theme.darkTheme;
            final total = calculateTotal();

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Dialog(
                backgroundColor: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey[900]!.withOpacity(0.8)
                            : Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [darkPrimary, darkSecondary]
                                    : [primaryOcean, lightOcean],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(28),
                                topRight: Radius.circular(28),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.tour, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        getTranslated('book_tour', context) ?? 'Đặt tour',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        tourData?['title'] ?? 'Tour',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Content
                          Flexible(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Ngày bắt đầu
                                  _buildGlassCard(
                                    isDark,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              color: isDark ? darkPrimary : primaryOcean,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              getTranslated('start_date', context) ?? 'Ngày bắt đầu',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        InkWell(
                                          onTap: () async {
                                            final date = await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.now(),
                                              firstDate: DateTime.now(),
                                              lastDate: DateTime(2030),
                                              builder: (context, child) {
                                                return Theme(
                                                  data: Theme.of(context).copyWith(
                                                    colorScheme: ColorScheme.light(
                                                      primary: isDark ? darkPrimary : primaryOcean,
                                                      onPrimary: Colors.white,
                                                    ),
                                                  ),
                                                  child: child!,
                                                );
                                              },
                                            );
                                            if (date != null) setState(() => selectedDate = date);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.grey[800]!.withOpacity(0.5)
                                                  : paleOcean.withOpacity(0.5),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isDark
                                                    ? Colors.white.withOpacity(0.1)
                                                    : lightOcean.withOpacity(0.2),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  selectedDate == null
                                                      ? bookingData['start_date_html']
                                                      : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color: isDark ? Colors.white : Colors.black87,
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.arrow_drop_down,
                                                  color: isDark ? Colors.white70 : primaryOcean,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  Text(
                                    getTranslated('number_of_guests', context) ?? 'Số lượng khách',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  for (var p in personTypes) ...[
                                    _buildGlassCard(
                                      isDark,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p['name'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            p['desc'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isDark ? Colors.white60 : Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? Colors.grey[800]!.withOpacity(0.5)
                                                      : paleOcean.withOpacity(0.5),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.remove,
                                                        color: isDark ? darkPrimary : primaryOcean,
                                                      ),
                                                      onPressed: () {
                                                        if (quantities[p['name']]! > (p['min'] ?? 0)) {
                                                          setState(() => quantities[p['name']] = quantities[p['name']]! - 1);
                                                        }
                                                      },
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                                      child: Text(
                                                        '${quantities[p['name']]}',
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                          color: isDark ? Colors.white : Colors.black87,
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.add,
                                                        color: isDark ? darkPrimary : primaryOcean,
                                                      ),
                                                      onPressed: () {
                                                        if (quantities[p['name']]! < (p['max'] ?? 10)) {
                                                          setState(() => quantities[p['name']] = quantities[p['name']]! + 1);
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                p['display_price'],
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? darkPrimary : primaryOcean,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  if (extras.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      getTranslated('extra_services', context) ?? 'Dịch vụ thêm',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    for (var e in extras)
                                      _buildGlassCard(
                                        isDark,
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: CheckboxListTile(
                                          value: extrasSelected[e['name']],
                                          title: Text(
                                            e['name'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                          subtitle: Text(
                                            e['price_html'],
                                            style: TextStyle(
                                              color: isDark ? darkPrimary : primaryOcean,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          onChanged: (val) => setState(() => extrasSelected[e['name']] = val!),
                                          activeColor: isDark ? darkPrimary : primaryOcean,
                                          controlAffinity: ListTileControlAffinity.leading,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Footer
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[850]!.withOpacity(0.5)
                                  : Colors.grey[50]!.withOpacity(0.5),
                              border: Border(
                                top: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.05),
                                ),
                              ),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(28),
                                bottomRight: Radius.circular(28),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated('total', context) ?? 'Tổng cộng:',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white70 : Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      '${total.toStringAsFixed(0)} ₫',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? darkPrimary : primaryOcean,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: isDark ? Colors.white70 : Colors.grey[700],
                                          side: BorderSide(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.2)
                                                : Colors.grey.shade300,
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: Text(
                                          getTranslated('close', context) ?? 'Đóng',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: isDark
                                                ? [darkPrimary, darkSecondary]
                                                : [primaryOcean, lightOcean],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(14),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isDark ? darkPrimary : primaryOcean).withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: () {
                                            if (selectedDate == null) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    getTranslated('please_select_start_date', context) ??
                                                        'Vui lòng chọn ngày bắt đầu',
                                                  ),
                                                  backgroundColor: Colors.orange.shade700,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                              );
                                              return;
                                            }

                                            final booking = BookingData(
                                              tourId: tourData?['id'] ?? 0,
                                              tourName: tourData?['title'] ?? 'Không có tên',
                                              tourImage: tourData?['banner_image_url'] ?? '',
                                              startDate: selectedDate!,
                                              personCounts: Map.from(quantities),
                                              extras: Map.from(extrasSelected),
                                              total: calculateTotal(),
                                              numberOfPeople: quantities.values.fold(0, (sum, val) => sum + val),
                                            );

                                            Navigator.pop(context);
                                            Navigator.pushNamed(
                                              context,
                                              '/booking-confirm',
                                              arguments: booking,
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                getTranslated('confirm_booking', context) ?? 'Xác nhận đặt tour',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGlassCard(bool isDark, {required Widget child, EdgeInsets? margin}) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey[800]!.withOpacity(0.3)
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : lightOcean.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : primaryOcean.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeController>(context);
    final isDark = theme.darkTheme;

    if (isLoading) {
      return Scaffold(
        backgroundColor: isDark ? darkBackground : paleOcean,
        body: Center(
          child: CircularProgressIndicator(
            color: isDark ? darkPrimary : primaryOcean,
          ),
        ),
      );
    }

    final tour = tourData!;
    final gallery = List<String>.from(tour['gallery_urls'] ?? []);
    final bookingData = tour['booking_data'] ?? {};
    final reviews = tour['review_list']?['data'] ?? [];

    return Scaffold(
      backgroundColor: isDark ? darkBackground : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? darkPrimary : primaryOcean,
        foregroundColor: Colors.white,
        title: Text(
          tour['title'] ?? (getTranslated('tour_details', context) ?? "Chi tiết tour"),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Image.network(
                      tour['banner_image_url'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 250,
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              (isDark ? darkBackground : Colors.grey[50]!).withOpacity(0.9),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? darkCard.withOpacity(0.5)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isDark
                        ? Border.all(color: Colors.white.withOpacity(0.1), width: 1.5)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.3)
                            : primaryOcean.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tour['title'],
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? darkPrimary : primaryOcean,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          isDark,
                          Icons.location_on,
                          getTranslated('location', context) ?? "Địa điểm",
                          tour['location'],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          isDark,
                          Icons.access_time,
                          getTranslated('duration', context) ?? "Thời lượng",
                          "${tour['duration']} ${getTranslated('days', context) ?? 'ngày'}",
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          isDark,
                          Icons.payments,
                          getTranslated('price', context) ?? "Giá",
                          "${tour['price']} VND",
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? darkCard.withOpacity(0.3)
                        : paleOcean,
                    borderRadius: BorderRadius.circular(16),
                    border: isDark
                        ? Border.all(color: Colors.white.withOpacity(0.1), width: 1.5)
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.description,
                              color: isDark ? darkPrimary : primaryOcean,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              getTranslated('description', context) ?? "Mô tả",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? darkPrimary : primaryOcean,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        HtmlWidget(
                          tour['description'] ?? "",
                          textStyle: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                if (gallery.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.photo_library,
                              color: isDark ? darkPrimary : primaryOcean,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              getTranslated('gallery', context) ?? "Hình ảnh",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? darkPrimary : primaryOcean,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 220,
                          autoPlay: true,
                          enlargeCenterPage: true,
                          viewportFraction: 0.85,
                        ),
                        items: gallery.map((url) {
                          return Builder(
                            builder: (context) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                if (bookingData.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? darkCard.withOpacity(0.5)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : lightOcean.withOpacity(0.3),
                        width: isDark ? 1.5 : 1,
                      ),
                      boxShadow: isDark ? null : [
                        BoxShadow(
                          color: primaryOcean.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                color: isDark ? darkPrimary : primaryOcean,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                getTranslated('price_by_person', context) ?? "Giá theo đối tượng",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: isDark ? darkPrimary : primaryOcean,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...List.from(bookingData['person_types'] ?? []).map((p) =>
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey[800]!.withOpacity(0.3)
                                      : paleOcean,
                                  borderRadius: BorderRadius.circular(8),
                                  border: isDark
                                      ? Border.all(color: Colors.white.withOpacity(0.1))
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p['name'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            p['desc'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? Colors.white60 : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      p['display_price'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? darkPrimary : primaryOcean,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ),
                          if (bookingData['extra_price'] != null && bookingData['extra_price'].isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  color: isDark ? darkPrimary : primaryOcean,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  getTranslated('extra_fees', context) ?? "Phụ phí",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDark ? darkPrimary : primaryOcean,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...List.from(bookingData['extra_price']).map((e) =>
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        e['name'],
                                        style: TextStyle(
                                          color: isDark ? Colors.white70 : Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        e['price_html'],
                                        style: TextStyle(
                                          color: isDark ? darkPrimary : primaryOcean,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                if (reviews.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              getTranslated('reviews', context) ?? "Đánh giá",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isDark ? darkPrimary : primaryOcean,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...reviews.map<Widget>((r) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? darkCard.withOpacity(0.5)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: isDark
                                ? Border.all(color: Colors.white.withOpacity(0.1), width: 1.5)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        r['title'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            r['rate_number'].toString(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  r['content'],
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? darkCard.withOpacity(0.9)
                        : Colors.white.withOpacity(0.9),
                    border: isDark
                        ? Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.5))
                        : null,
                    boxShadow: isDark ? null : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: ElevatedButton(
                      onPressed: _bookTour,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? darkPrimary : primaryOcean,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: isDark ? 8 : 0,
                        shadowColor: isDark ? darkPrimary.withOpacity(0.5) : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.card_travel, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            getTranslated('book_now', context) ?? "Đặt Tour Ngay",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(bool isDark, IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.grey[800]!.withOpacity(0.5)
                : paleOcean,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDark ? darkPrimary : primaryOcean,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}