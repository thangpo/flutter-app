import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

import '../widgets/flight_promo_banner.dart';
import '../widgets/flight_tab_button.dart';
import '../widgets/flight_booking_form.dart';
import '../widgets/flight_support_item.dart';
import '../widgets/flight_bottom_menu_item.dart';
import '../widgets/flight_list_widget.dart';
import '../services/duffel_service.dart';

class FlightBookingScreen extends StatefulWidget {
  const FlightBookingScreen({super.key});

  @override
  State<FlightBookingScreen> createState() => _FlightBookingScreenState();
}

class _FlightBookingScreenState extends State<FlightBookingScreen> {
  int selectedTab = 0;
  bool isRoundTrip = false;
  String fromCity = "Hồ Chí Minh";
  String fromCode = "SGN";
  String toCity = "Huế";
  String toCode = "HUI";
  DateTime? departureDate;
  DateTime? returnDate;
  int adults = 1;
  int children = 0;
  int infants = 0;
  int get totalPassengers => adults + children + infants;
  List<dynamic> searchResults = [];
  bool isLoading = false;

  final Color oceanBlue = const Color(0xFF0891B2);

  String tr(String key, String fallback) {
    return getTranslated(key, context) ?? fallback;
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showLoadingDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title =
    tr('flight_loading_title', 'Đang tìm kiếm chuyến bay...');
    final subtitle =
    tr('flight_loading_subtitle', 'Vui lòng đợi trong giây lát');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF020617) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(oceanBlue),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : oceanBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color scaffoldBg =
    isDark ? const Color(0xFF020617) : Colors.grey[50]!;
    final Color appBarBg = isDark ? const Color(0xFF020617) : Colors.white;
    final Color appBarFg = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        iconTheme: IconThemeData(color: appBarFg),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: appBarFg),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tr('flight_search_title', 'Tìm vé'),
          style: TextStyle(
            color: appBarFg,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Icon(Icons.star_border, color: appBarFg),
          const SizedBox(width: 8),
          Icon(Icons.notifications_outlined, color: appBarFg),
          const SizedBox(width: 8),
          Icon(Icons.home_outlined, color: appBarFg),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const FlightPromoBanner(),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: FlightTabButton(
                          icon: Icons.flight,
                          label: tr('flight_tab_plane', 'Máy bay'),
                          isSelected: selectedTab == 0,
                          onTap: () => setState(() => selectedTab = 0),
                        ),
                      ),
                      Expanded(
                        child: FlightTabButton(
                          icon: Icons.directions_bus,
                          label: tr('flight_tab_bus', 'Xe khách'),
                          isSelected: selectedTab == 1,
                          onTap: () => setState(() => selectedTab = 1),
                        ),
                      ),
                      Expanded(
                        child: FlightTabButton(
                          icon: Icons.train,
                          label: tr('flight_tab_train', 'Tàu hoả'),
                          isSelected: selectedTab == 2,
                          onTap: () => setState(() => selectedTab = 2),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                FlightBookingForm(
                  fromCity: fromCity,
                  fromCode: fromCode,
                  toCity: toCity,
                  toCode: toCode,
                  departureDate: departureDate,
                  returnDate: returnDate,
                  passengers: totalPassengers,
                  adults: adults,
                  children: children,
                  infants: infants,
                  isRoundTrip: isRoundTrip,

                  onSwap: () {
                    setState(() {
                      final tmpCity = fromCity;
                      final tmpCode = fromCode;
                      fromCity = toCity;
                      fromCode = toCode;
                      toCity = tmpCity;
                      toCode = tmpCode;
                    });
                  },

                  onRoundTripChanged: (val) {
                    setState(() {
                      isRoundTrip = val;
                      if (!val) returnDate = null;
                    });
                  },

                  onFormChanged: (data) {
                    setState(() {
                      fromCity = data['fromCity'];
                      fromCode = data['fromCode'];
                      toCity = data['toCity'];
                      toCode = data['toCode'];
                      departureDate = data['departureDate'];
                      returnDate = data['returnDate'];
                      isRoundTrip = data['isRoundTrip'];

                      adults = data['adults'] ?? 1;
                      children = data['children'] ?? 0;
                      infants = data['infants'] ?? 0;
                    });

                    if (fromCode == toCode) {
                      _showWarning(tr(
                        'flight_warning_same_airport',
                        'Điểm đi và điểm đến không được trùng nhau!',
                      ));
                    }
                  },

                  onSearch: () async {
                    if (fromCode == toCode) {
                      _showWarning(tr(
                        'flight_warning_diff_airport',
                        'Vui lòng chọn điểm đi và điểm đến khác nhau.',
                      ));
                      return;
                    }
                    if (departureDate == null) {
                      _showWarning(tr(
                        'flight_warning_departure_required',
                        'Vui lòng chọn ngày đi.',
                      ));
                      return;
                    }
                    if (isRoundTrip && returnDate == null) {
                      _showWarning(tr(
                        'flight_warning_return_required',
                        'Vui lòng chọn ngày về.',
                      ));
                      return;
                    }

                    setState(() {
                      isLoading = true;
                    });

                    _showLoadingDialog();

                    try {
                      final flights = await DuffelService.searchFlights(
                        fromCode: fromCode,
                        toCode: toCode,
                        departureDate: departureDate!
                            .toIso8601String()
                            .split("T")
                            .first,
                        returnDate: isRoundTrip
                            ? returnDate!
                            .toIso8601String()
                            .split("T")
                            .first
                            : null,
                        adults: adults,
                        children: children,
                        infants: infants,
                      );

                      if (!mounted) return;

                      setState(() {
                        searchResults = flights;
                        isLoading = false;
                      });

                      Navigator.of(context).pop();
                    } catch (e) {
                      if (!mounted) return;

                      setState(() {
                        isLoading = false;
                      });

                      Navigator.of(context).pop();

                      _showWarning(
                        tr('flight_error_search', 'Đã xảy ra lỗi khi tìm chuyến bay:') +
                            ' $e',
                      );
                    }
                  },
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    FlightSupportItem(
                      icon: Icons.support_agent,
                      label: tr('flight_support_24_7', 'Hỗ trợ 24/7'),
                    ),
                    FlightSupportItem(
                      icon: Icons.card_giftcard,
                      label: tr('flight_support_deals', 'Ưu đãi giá tốt'),
                    ),
                    FlightSupportItem(
                      icon: Icons.eco,
                      label: tr('flight_support_sustainable', 'Du lịch bền vững'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                FlightListWidget(
                  flights: searchResults,
                  isLoading: isLoading,
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: isDark ? const Color(0xFF020617) : Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      FlightBottomMenuItem(
                        icon: Icons.hotel,
                        label: tr('flight_bottom_hotel', 'Khách sạn'),
                      ),
                      FlightBottomMenuItem(
                        icon: Icons.confirmation_number_outlined,
                        label:
                        tr('flight_bottom_experience', 'Trải nghiệm'),
                      ),
                      FlightBottomMenuItem(
                        icon: Icons.shield_outlined,
                        label: tr('flight_bottom_insurance', 'Bảo hiểm'),
                      ),
                      FlightBottomMenuItem(
                        icon: Icons.expand_more,
                        label: tr('flight_bottom_more', 'Xem thêm'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(oceanBlue),
                ),
              ),
            ),
        ],
      ),
    );
  }
}