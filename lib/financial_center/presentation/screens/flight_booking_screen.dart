import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

import '../services/flight_service.dart';
import '../widgets/flight_list_widget.dart';
import '../widgets/flight_search_form.dart';

class FlightBookingScreen extends StatefulWidget {
  const FlightBookingScreen({super.key});

  @override
  State<FlightBookingScreen> createState() => _FlightBookingScreenState();
}

class _FlightBookingScreenState extends State<FlightBookingScreen> {
  final Color headerBlue = const Color(0xFF2F6FED);

  List<dynamic> searchResults = [];
  bool isLoading = false;

  String tr(String key, String fallback) {
    final v = getTranslated(key, context);
    if (v == null || v.isEmpty || v == key) return fallback;
    return v;
  }

  void _showWarning(String message) {
    final isDark = Provider.of<ThemeController>(context, listen: false).darkTheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isDark ? const Color(0xFFB91C1C) : Colors.red,
      ),
    );
  }

  void _showLoadingDialog() {
    final isDark = Provider.of<ThemeController>(context, listen: false).darkTheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: isDark ? Colors.black54 : Colors.black26,
      builder: (_) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1220) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(headerBlue),
            ),
          ),
        );
      },
    );
  }

  String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return "$y-$m-$day";
  }

  Future<void> _handleSearch(FlightSearchCriteria c) async {
    setState(() {
      searchResults = [];
      isLoading = true;
    });
    _showLoadingDialog();

    try {
      final start = _fmtDate(c.departureDate);
      final end = c.isRoundTrip ? _fmtDate(c.returnDate!) : _fmtDate(c.departureDate);

      final res = await FlightService.getFlights(params: {
        "limit": 20,
        "page": 1,
        "start": start,
        "end": end,
      });

      if (!mounted) return;

      final data = res["data"] as Map<String, dynamic>;
      final rows = (data["rows"] as List<dynamic>?) ?? <dynamic>[];

      setState(() {
        searchResults = rows;
        isLoading = false;
      });

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      Navigator.of(context).pop();
      _showWarning("${tr('flight_error_search', 'Đã xảy ra lỗi khi tìm chuyến bay:')} $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeController>(context, listen: true).darkTheme;
    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF5F7FB);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            child: Container(
              height: 210,
              color: headerBlue,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${tr('flight_hi', 'Hi,')} ${tr('flight_user_name', 'Bố')}",
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr('flight_book_title', 'Book your flight'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  const SizedBox(height: 86),

                  FlightSearchForm(
                    headerBlue: headerBlue,
                    onSearch: _handleSearch,
                  ),

                  const SizedBox(height: 18),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        tr('flight_upcoming', 'Upcoming Flights'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FlightListWidget(
                      flights: searchResults.isNotEmpty ? searchResults : null,
                      isLoading: isLoading,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}