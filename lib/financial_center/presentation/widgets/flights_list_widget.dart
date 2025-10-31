import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/services/duffel_service.dart';

class FlightListWidget extends StatefulWidget {
  const FlightListWidget({super.key});

  @override
  State<FlightListWidget> createState() => _FlightListWidgetState();
}

class _FlightListWidgetState extends State<FlightListWidget>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _flights = [];

  @override
  void initState() {
    super.initState();
    _loadFlights();
  }

  Future<void> _loadFlights() async {
    try {
      final data = await DuffelService.searchFlights(
        fromCode: "SGN",
        toCode: "HAN",
        departureDate: DateFormat("yyyy-MM-dd").format(DateTime.now().add(const Duration(days: 7))),
        adults: 1,
      );
      setState(() {
        _flights = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Lỗi tải chuyến bay: $e");
      setState(() => _isLoading = false);
    }
  }

  String formatCurrency(String? priceString) {
    if (priceString == null) return "—";
    try {
      final price = double.parse(priceString);
      return NumberFormat.currency(locale: "vi_VN", symbol: "₫").format(price);
    } catch (_) {
      return "$priceString ₫";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF009DFF),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              getTranslated("best_flight_deals", context)!,
              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              getTranslated("most_popular_routes", context)!,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),

          // Loading or Content
          _isLoading
              ? const _SkeletonFlightList()
              : _flights.isEmpty
              ? Center(child: Text(getTranslated("no_flights", context)!, style: const TextStyle(color: Colors.white)))
              : _buildFlightList(),
        ],
      ),
    );
  }

  Widget _buildFlightList() {
    return Column(
      children: _flights.take(6).map((flight) {
        final slices = flight["slices"] as List<dynamic>? ?? [];
        final segment = slices.isNotEmpty ? slices.first : {};
        final origin = segment["origin"]?["iata_code"] ?? "???";
        final destination = segment["destination"]?["iata_code"] ?? "???";
        final departure = segment["segments"]?[0]?["departing_at"] ?? "";
        final airlineName = flight["owner"]?["name"] ?? getTranslated("airline", context)!;
        final totalAmount = flight["total_amount"] ?? "0";
        final originalAmount = (double.parse(totalAmount) * 1.3).toString();
        final discountPercent = ((1 - (double.parse(totalAmount) / double.parse(originalAmount))) * 100).round();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("$origin to $destination", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            "${getTranslated("departure", context)!}: ${departure.split('T').first}",
                            style: const TextStyle(color: Colors.black54, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Row(children: [
                            const SizedBox(width: 6),
                            Text(airlineName, style: const TextStyle(color: Colors.black87, fontSize: 13)),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
                    child: Text("-$discountPercent%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      NumberFormat.currency(locale: "vi_VN", symbol: "").format(double.parse(originalAmount)),
                      style: const TextStyle(color: Colors.black45, decoration: TextDecoration.lineThrough, fontSize: 13),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatCurrency(totalAmount), style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          "${getTranslated("after_tax_price", context)!}: ${formatCurrency((double.parse(totalAmount) * 2.96).toString())}",
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// === SKELETON LOADING ===
class _SkeletonFlightList extends StatelessWidget {
  const _SkeletonFlightList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(6, (_) => const _SkeletonFlightCard()).toList(),
    );
  }
}

class _SkeletonFlightCard extends StatelessWidget {
  const _SkeletonFlightCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(height: 16, width: 120),
                      const SizedBox(height: 8),
                      _ShimmerBox(height: 12, width: 180),
                      const SizedBox(height: 12),
                      _ShimmerBox(height: 12, width: 100),
                    ],
                  ),
                ),
                _ShimmerBox(height: 32, width: 48, borderRadius: 8),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ShimmerBox(height: 14, width: 80),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _ShimmerBox(height: 16, width: 100),
                    const SizedBox(height: 4),
                    _ShimmerBox(height: 12, width: 120),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// === SHIMMER BOX ===
class _ShimmerBox extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;

  const _ShimmerBox({required this.height, required this.width, this.borderRadius = 4});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const _Shimmer(),
    );
  }
}

// === SHIMMER EFFECT ===
class _Shimmer extends StatefulWidget {
  const _Shimmer();

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _controller.value * 3, 0),
              end: Alignment(1.0 + _controller.value * 3, 0),
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.4),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
}