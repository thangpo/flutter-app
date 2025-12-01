import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/domain/services/auth_service.dart';
import 'package:flutter_sixvalley_ecommerce/di_container.dart' as di;
import '../widgets/tour_detail_body.dart';
import '../widgets/tour_booking_dialog.dart';

class TourDetailScreen extends StatefulWidget {
  final int tourId;
  const TourDetailScreen({super.key, required this.tourId});

  @override
  State<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends State<TourDetailScreen> {
  Map<String, dynamic>? tourData;
  bool isLoading = true;
  static const Color primaryOcean = Color(0xFF0077BE);
  static const Color paleOcean = Color(0xFFE3F2FD);
  static const Color darkPrimary = Color(0xFF64B5F6);
  static final Color darkBackground = Colors.grey[900]!;

  @override
  void initState() {
    super.initState();
    _fetchTourDetail();
  }

  Future<void> _fetchTourDetail() async {
    try {
      final url =
      Uri.parse("https://vietnamtoure.com/api/tours/${widget.tourId}");
      final response =
      await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonRes = json.decode(response.body);
        setState(() {
          tourData = jsonRes['data'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        _showErrorSnack(
          'Không tải được dữ liệu tour (mã ${response.statusCode})',
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnack('Lỗi kết nối, vui lòng thử lại.');
    }
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _bookTour() async {
    if (tourData == null) return;

    final authService = di.sl<AuthService>();
    final isLoggedIn = authService.isLoggedIn();
    final theme = Provider.of<ThemeController>(context, listen: false);
    final isDark = theme.darkTheme;

    if (!isLoggedIn) {
      showDialog(
        context: context,
        builder: (context) => TourLoginRequiredDialog(isDark: isDark),
      );
      return;
    }

    await TourBookingDialog.show(context, tourData!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeController>(context, listen: true);
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
    final title = tour['title'] ??
        (getTranslated('tour_details', context) ?? 'Chi tiết tour');

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? Colors.black : Colors.white,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: const SizedBox.shrink(),
      ),

      body: Stack(
        children: [
          TourDetailBody(
            tour: tour,
            primaryOcean: primaryOcean,
            paleOcean: paleOcean,
            darkBackground: darkBackground,
            darkPrimary: darkPrimary,
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
                        ? Colors.black.withOpacity(0.92)
                        : Colors.white.withOpacity(0.95),
                    border: isDark
                        ? const Border(
                      top: BorderSide(color: Colors.white24, width: 1.2),
                    )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
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
                        shadowColor:
                        isDark ? darkPrimary.withOpacity(0.5) : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.card_travel, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            getTranslated('book_now', context) ?? 'book_now',
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
}

/// Popup yêu cầu đăng nhập – giữ nguyên, chỉ dùng chung cho UI mới
class TourLoginRequiredDialog extends StatelessWidget {
  final bool isDark;
  const TourLoginRequiredDialog({super.key, required this.isDark});

  static const Color primaryOcean = Color(0xFF0077BE);
  static const Color lightOcean = Color(0xFF4DA6D6);
  static const Color darkPrimary = Color(0xFF64B5F6);
  static const Color darkSecondary = Color(0xFF42A5F5);

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
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
                      color: (isDark ? darkPrimary : primaryOcean)
                          .withOpacity(0.1),
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
                    getTranslated('login_required', context) ??
                        'Yêu cầu đăng nhập',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    getTranslated('please_login_to_book', context) ??
                        'Vui lòng đăng nhập để đặt tour.',
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
                            foregroundColor:
                            isDark ? Colors.white70 : Colors.grey[700],
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            getTranslated('cancel', context) ?? 'Hủy',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
                                color: (isDark ? darkPrimary : primaryOcean)
                                    .withOpacity(0.3),
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
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              getTranslated('login', context) ??
                                  'Đăng nhập',
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
    );
  }
}