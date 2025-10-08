import 'package:flutter/material.dart';
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

  // Màu xanh nước biển
  final Color oceanBlue = const Color(0xFF0891B2);

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
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
                  'Đang tìm kiếm chuyến bay...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: oceanBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vui lòng đợi trong giây lát',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tìm vé',
          style: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: const [
          Icon(Icons.star_border, color: Colors.black),
          SizedBox(width: 8),
          Icon(Icons.notifications_outlined, color: Colors.black),
          SizedBox(width: 8),
          Icon(Icons.home_outlined, color: Colors.black),
          SizedBox(width: 8),
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
                          label: 'Máy bay',
                          isSelected: selectedTab == 0,
                          onTap: () => setState(() => selectedTab = 0),
                        ),
                      ),
                      Expanded(
                        child: FlightTabButton(
                          icon: Icons.directions_bus,
                          label: 'Xe khách',
                          isSelected: selectedTab == 1,
                          onTap: () => setState(() => selectedTab = 1),
                        ),
                      ),
                      Expanded(
                        child: FlightTabButton(
                          icon: Icons.train,
                          label: 'Tàu hoả',
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
                      _showWarning("Điểm đi và điểm đến không được trùng nhau!");
                    }
                  },

                  onSearch: () async {
                    if (fromCode == toCode) {
                      _showWarning("Vui lòng chọn điểm đi và điểm đến khác nhau.");
                      return;
                    }
                    if (departureDate == null) {
                      _showWarning("Vui lòng chọn ngày đi.");
                      return;
                    }
                    if (isRoundTrip && returnDate == null) {
                      _showWarning("Vui lòng chọn ngày về.");
                      return;
                    }

                    setState(() {
                      isLoading = true;
                    });

                    // Hiển thị dialog loading
                    _showLoadingDialog();

                    try {
                      final flights = await DuffelService.searchFlights(
                        fromCode: fromCode,
                        toCode: toCode,
                        departureDate:
                        departureDate?.toIso8601String().split("T").first ?? "",
                        returnDate: isRoundTrip
                            ? returnDate?.toIso8601String().split("T").first
                            : null,
                        adults: adults,
                        children: children,
                        infants: infants,
                      );

                      setState(() {
                        searchResults = flights;
                        isLoading = false;
                      });

                      // Đóng dialog loading
                      if (mounted) Navigator.of(context).pop();
                    } catch (e) {
                      setState(() {
                        isLoading = false;
                      });

                      // Đóng dialog loading
                      if (mounted) Navigator.of(context).pop();

                      _showWarning("Lỗi khi tìm chuyến bay: $e");
                    }
                  },
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    FlightSupportItem(
                        icon: Icons.support_agent, label: 'Hỗ trợ 24/7'),
                    FlightSupportItem(
                        icon: Icons.card_giftcard, label: 'Ưu đãi, bảo lộ deal'),
                    FlightSupportItem(
                        icon: Icons.eco, label: 'Du lịch bền vững'),
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
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      FlightBottomMenuItem(icon: Icons.hotel, label: 'Khách sạn'),
                      FlightBottomMenuItem(
                          icon: Icons.confirmation_number_outlined,
                          label: 'Trải nghiệm'),
                      FlightBottomMenuItem(
                          icon: Icons.shield_outlined, label: 'Bảo hiểm'),
                      FlightBottomMenuItem(
                          icon: Icons.expand_more, label: 'Xem thêm'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Overlay loading (backup nếu cần)
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