import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/domain/services/tour_order_service.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:provider/provider.dart';

import 'qr_page.dart';
import 'tour_booking_card.dart';
import 'past_booking_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class TourOrderScreen extends StatefulWidget {
  const TourOrderScreen({super.key});

  @override
  State<TourOrderScreen> createState() => _TourOrderScreenState();
}

class _TourOrderScreenState extends State<TourOrderScreen> {
  bool _isLoading = true;
  List<dynamic> _tourOrders = [];
  String? _error;
  String? _selectedStatus;

  final TourOrderService _tourService = TourOrderService();

  final List<Map<String, String>> _statuses = [
    {"label": "all", "value": ""},
    {"label": "draft", "value": "draft"},
    {"label": "unpaid", "value": "unpaid"},
    {"label": "processing", "value": "processing"},
    {"label": "confirmed", "value": "confirmed"},
    {"label": "completed", "value": "completed"},
    {"label": "paid", "value": "paid"},
    {"label": "partial_payment", "value": "partial_payment"},
    {"label": "cancelled", "value": "cancelled"},
  ];

  @override
  void initState() {
    super.initState();
    _initAndFetchData();
  }

  Future<void> _initAndFetchData({String? status}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _tourService.init();
      final tours = await _tourService.fetchTourOrders(status: status);
      setState(() {
        _tourOrders = tours;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = getTranslated('error_loading_tours', context) ?? e.toString();
        _isLoading = false;
      });
    }
  }

  /// Mở Google Maps dẫn đường tới điểm của booking
  Future<void> _openMapForBooking(
      BuildContext context, Map<String, dynamic> booking) async {
    final service = booking['service'] as Map<String, dynamic>? ?? {};
    final latStr = service['lat']?.toString();
    final lngStr = service['lng']?.toString();

    final lat = double.tryParse(latStr ?? '');
    final lng = double.tryParse(lngStr ?? '');

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            getTranslated('location_not_available', context) ??
                'Không có tọa độ cho địa điểm này',
          ),
        ),
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    // Mở app Google Maps nếu có, fallback sang browser
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              getTranslated('cannot_open_map', context) ??
                  'Không thể mở Google Maps',
            ),
          ),
        );
      }
    }
  }

  /// today / upcoming / past / unknown
  String _classifyByDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'unknown';
    try {
      final d = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dateOnly = DateTime(d.year, d.month, d.day);

      if (dateOnly.isAtSameMomentAs(today)) return 'today';
      if (dateOnly.isAfter(today)) return 'upcoming';
      return 'past';
    } catch (_) {
      return 'unknown';
    }
  }

  /// Lấy TOUR/HOTEL từ hôm nay trở đi
  List<Map<String, dynamic>> _filterUpcomingByType(String type) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _tourOrders
        .where((raw) {
      final item = raw as Map<String, dynamic>? ?? {};
      final String serviceType =
      (item['service_type'] ?? item['object_model'] ?? '').toString();

      if (serviceType != type) return false;

      final startStr = item['start_date']?.toString();
      if (startStr == null || startStr.isEmpty) return false;

      try {
        final d = DateTime.parse(startStr);
        final dateOnly = DateTime(d.year, d.month, d.day);
        if (dateOnly.isBefore(today)) return false;
      } catch (_) {
        return false;
      }

      return true;
    })
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Provider.of<ThemeController>(context).darkTheme;

    final Color appBarColor =
    isDarkMode ? Colors.black : const Color(0xFF006D9C);
    final Color appBarColorEnd =
    isDarkMode ? Colors.black : const Color(0xFF4DA8DA);

    final Color oceanBlue =
    isDarkMode ? Theme.of(context).primaryColorDark : const Color(0xFF006D9C);
    final Color lightOceanBlue =
    isDarkMode ? Theme.of(context).primaryColorLight : const Color(0xFF4DA8DA);
    final Color paleOceanBlue = isDarkMode
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFE3F2FD);

    return DefaultTabController(
      length: 2,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: appBarColor,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness:
          isDarkMode ? Brightness.dark : Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: paleOceanBlue,
          appBar: AppBar(
            title: Text(
              getTranslated('tour_order_history', context) ?? 'Lịch sử đặt lịch',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: isDarkMode
                    ? Theme.of(context).colorScheme.onPrimary
                    : Colors.white,
              ),
            ),
            backgroundColor: appBarColor,
            surfaceTintColor: Colors.transparent,
            foregroundColor: isDarkMode
                ? Theme.of(context).colorScheme.onPrimary
                : Colors.white,
            centerTitle: true,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: appBarColor,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness:
              isDarkMode ? Brightness.dark : Brightness.light,
            ),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [appBarColor, appBarColorEnd],
                ),
              ),
            ),
            bottom: TabBar(
              indicatorColor: Colors.white,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(text: getTranslated('tour_only', context) ?? 'Tour'),
                Tab(text: getTranslated('hotel_only', context) ?? 'Hotel'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded),
                tooltip:
                getTranslated('past_bookings', context) ?? 'Lịch đã qua',
                onPressed: () {
                  if (_tourOrders.isEmpty) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PastBookingScreen(allBookings: _tourOrders),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // ========== FILTER + QR ==========
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Theme.of(context).cardColor : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: oceanBlue.withOpacity(isDarkMode ? 0.2 : 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? oceanBlue.withOpacity(0.3)
                            : paleOceanBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.filter_list_rounded,
                        color: isDarkMode
                            ? Theme.of(context).colorScheme.onPrimary
                            : oceanBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus ?? "",
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: lightOceanBlue),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: lightOceanBlue
                                  .withOpacity(isDarkMode ? 0.3 : 0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                            BorderSide(color: oceanBlue, width: 2),
                          ),
                          labelText: getTranslated('filter_by_status', context) ??
                              "Lọc theo trạng thái",
                          labelStyle: TextStyle(
                            color: isDarkMode
                                ? Theme.of(context).hintColor
                                : oceanBlue,
                          ),
                          isDense: true,
                          filled: true,
                          fillColor: paleOceanBlue
                              .withOpacity(isDarkMode ? 0.5 : 0.3),
                        ),
                        dropdownColor: isDarkMode
                            ? Theme.of(context).cardColor
                            : Colors.white,
                        items: _statuses.map((status) {
                          return DropdownMenuItem<String>(
                            value: status["value"]!,
                            child: Text(
                              getTranslated(status["label"]!, context) ??
                                  status["label"]!,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Colors.black,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedStatus = value ?? "");
                          _initAndFetchData(status: value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const QrPage(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? oceanBlue.withOpacity(0.3)
                              : paleOceanBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.qr_code_2_rounded,
                          color: isDarkMode
                              ? Theme.of(context).colorScheme.onPrimary
                              : oceanBlue,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ========== NỘI DUNG 2 TAB (Hôm nay + Sắp tới) ==========
              Expanded(
                child: _isLoading
                    ? Center(
                  child: CircularProgressIndicator(
                    valueColor:
                    AlwaysStoppedAnimation<Color>(oceanBlue),
                    strokeWidth: 3,
                  ),
                )
                    : _error != null
                    ? _buildError(context)
                    : TabBarView(
                  children: [
                    // Tab Tour
                    _buildTabList(
                      context: context,
                      bookings: _filterUpcomingByType('tour'),
                      isDarkMode: isDarkMode,
                      oceanBlue: oceanBlue,
                      lightOceanBlue: lightOceanBlue,
                      emptyText:
                      getTranslated('no_upcoming_tour', context) ??
                          'Không có tour nào từ hôm nay trở đi',
                      serviceTypeTab: 'tour',
                    ),
                    // Tab Hotel
                    _buildTabList(
                      context: context,
                      bookings: _filterUpcomingByType('hotel'),
                      isDarkMode: isDarkMode,
                      oceanBlue: oceanBlue,
                      lightOceanBlue: lightOceanBlue,
                      emptyText: getTranslated(
                          'no_upcoming_hotel', context) ??
                          'Không có khách sạn nào từ hôm nay trở đi',
                      serviceTypeTab: 'hotel',
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

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? '',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Hôm nay / Sắp tới cho từng tab
  Widget _buildTabList({
    required BuildContext context,
    required List<Map<String, dynamic>> bookings,
    required bool isDarkMode,
    required Color oceanBlue,
    required Color lightOceanBlue,
    required String emptyText,
    required String serviceTypeTab, // 'tour' hoặc 'hotel'
  }) {
    if (bookings.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode
                ? Theme.of(context).hintColor
                : Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final List<Map<String, dynamic>> todayList = [];
    final List<Map<String, dynamic>> upcomingList = [];

    for (final b in bookings) {
      final group = _classifyByDate(b['start_date']?.toString());
      if (group == 'today') {
        todayList.add(b);
      } else if (group == 'upcoming') {
        upcomingList.add(b);
      }
    }

    final String todayLabel = serviceTypeTab == 'hotel'
        ? (getTranslated('today_hotel_checkin', context) ??
        'Đã đến ngày nhận phòng')
        : (getTranslated('today_tour_start', context) ??
        'Đã đến ngày tham gia tour');

    final String upcomingLabel = serviceTypeTab == 'hotel'
        ? (getTranslated('upcoming_hotel_checkin', context) ??
        'Các lần nhận phòng sắp tới')
        : (getTranslated('upcoming_tour_start', context) ??
        'Các tour sắp tới');

    final List<Widget> children = [];

    if (todayList.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Text(
            todayLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : oceanBlue,
            ),
          ),
        ),
      );
      children.addAll(
        todayList.map(
              (item) => BookingCard(
            item: item,
            isDarkMode: isDarkMode,
            oceanBlue: oceanBlue,
            lightOceanBlue: lightOceanBlue,
            onNavigate: (booking) => _openMapForBooking(context, booking),
          ),
        ),
      );
    }

    if (upcomingList.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Text(
            upcomingLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : oceanBlue,
            ),
          ),
        ),
      );
      children.addAll(
        upcomingList.map(
              (item) => BookingCard(
            item: item,
            isDarkMode: isDarkMode,
            oceanBlue: oceanBlue,
            lightOceanBlue: lightOceanBlue,
            onNavigate: (booking) => _openMapForBooking(context, booking),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: children,
    );
  }
}