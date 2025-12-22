import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'flight_list_item.dart';
import '../services/flight_service.dart';

class FlightListWidget extends StatefulWidget {
  final List<dynamic>? flights;
  final bool isLoading;

  const FlightListWidget({
    super.key,
    this.flights,
    this.isLoading = false,
  });

  @override
  State<FlightListWidget> createState() => _FlightListWidgetState();
}

class _FlightListWidgetState extends State<FlightListWidget> {
  List<dynamic> flights = [];
  bool isLoading = true;

  bool get _isUsingExternalData => widget.flights != null;

  @override
  void initState() {
    super.initState();
    if (_isUsingExternalData) {
      flights = widget.flights ?? [];
      isLoading = widget.isLoading;
    } else {
      fetchFlights();
    }
  }

  @override
  void didUpdateWidget(covariant FlightListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldUsingExternal = oldWidget.flights != null;
    final newUsingExternal = widget.flights != null;
    if (oldUsingExternal != newUsingExternal) {
      if (newUsingExternal) {
        setState(() {
          flights = widget.flights ?? [];
          isLoading = widget.isLoading;
        });
      } else {
        fetchFlights();
      }
      return;
    }

    if (newUsingExternal) {
      if (widget.flights != oldWidget.flights ||
          widget.isLoading != oldWidget.isLoading) {
        setState(() {
          flights = widget.flights ?? [];
          isLoading = widget.isLoading;
        });
      }
      return;
    }
  }

  String tr(BuildContext context, String key, String fallback) {
    return getTranslated(key, context) ?? fallback;
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark ? const Color(0xFF111827) : Colors.grey.shade200;
    final highlightColor =
    isDark ? const Color(0xFF1F2937) : Colors.grey.shade300;

    return Column(
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: highlightColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                        color: highlightColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 180,
                      decoration: BoxDecoration(
                        color: highlightColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 100,
                      decoration: BoxDecoration(
                        color: highlightColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 18,
                width: 60,
                decoration: BoxDecoration(
                  color: highlightColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> fetchFlights() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final res = await FlightService.getFlights(params: {
        "limit": 20,
        "page": 1,
      });

      final data = (res["data"] as Map<String, dynamic>?);
      final rows = (data?["rows"] as List<dynamic>?) ?? <dynamic>[];

      if (!mounted) return;
      setState(() {
        flights = rows;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('FlightListWidget fetchFlights error: $e');
      if (!mounted) return;
      setState(() {
        flights = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) {
      return _buildLoadingSkeleton(context);
    }

    if (flights.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            tr(context, 'flight_no_result', 'Không tìm thấy chuyến bay nào.'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          child: Text(
            tr(context, 'flight_recommended_title', 'Chuyến bay gợi ý'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
        ),

        ...flights.map((f) {
          final id = (f["id"] ?? "").toString();

          final airline = (f["airline"] is Map)
              ? ((f["airline"]["name"] ?? "Hãng bay").toString())
              : "Hãng bay";

          final logoUrl = (f["image"] ?? "").toString();

          final from = (f["airport_form"] is Map)
              ? ((f["airport_form"]["name"] ?? "").toString())
              : "";

          final to = (f["airport_to"] is Map)
              ? ((f["airport_to"]["name"] ?? "").toString())
              : "";

          final departure = (f["departure_time"] ?? "").toString();
          final arrival = (f["arrival_time"] ?? "").toString();
          final price = (f["price"] ?? f["min_price"] ?? "").toString();
          final cabinClass = "Economy";
          final baggage = tr(context, 'flight_baggage_none', 'Không có');
          final canBook = f["can_book"];
          final availability = (canBook is bool && canBook == false)
              ? tr(context, 'flight_seat_unavailable', 'Hết chỗ')
              : tr(context, 'flight_seat_available', 'Còn chỗ');

          return FlightListItem(
            flightId: id,
            airline: airline,
            from: from,
            to: to,
            departure: departure,
            arrival: arrival,
            price: price,
            cabinClass: cabinClass,
            baggage: baggage,
            availability: availability,
            logoUrl: logoUrl,
          );
        }).toList(),
      ],
    );
  }
}