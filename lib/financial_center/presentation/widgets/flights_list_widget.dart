import 'dart:ui'; // THÊM import này cho BackdropFilter
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/services/duffel_service.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

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
    final isDark = Provider.of<ThemeController>(context, listen: true).darkTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            const Color(0xFF1A2332),
            const Color(0xFF0D1117),
          ]
              : [
            const Color(0xFF009DFF),
            const Color(0xFF0080D6),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Glass Header Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.04),
                      ]
                          : [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(isDark ? 0.15 : 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(isDark ? 0.15 : 0.3),
                                  Colors.white.withOpacity(isDark ? 0.08 : 0.15),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.flight_takeoff_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  getTranslated("best_flight_deals", context) ?? "Ưu đãi vé máy bay",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  getTranslated("most_popular_routes", context) ?? "Tuyến phổ biến nhất",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
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
          const SizedBox(height: 16),

          // Loading or Content
          _isLoading
              ? _SkeletonFlightList(isDark: isDark)
              : _flights.isEmpty
              ? _buildEmptyState(isDark)
              : _buildFlightList(isDark),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.04),
                ]
                    : [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.15 : 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flight_outlined,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  getTranslated("no_flights", context) ?? "Không có chuyến bay",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlightList(bool isDark) {
    return Column(
      children: _flights.take(6).map((flight) {
        final slices = flight["slices"] as List<dynamic>? ?? [];
        final segment = slices.isNotEmpty ? slices.first : {};
        final origin = segment["origin"]?["iata_code"] ?? "???";
        final destination = segment["destination"]?["iata_code"] ?? "???";
        final departure = segment["segments"]?[0]?["departing_at"] ?? "";
        final airlineName = flight["owner"]?["name"] ?? getTranslated("airline", context) ?? "Hãng bay";
        final totalAmount = flight["total_amount"] ?? "0";
        final originalAmount = (double.parse(totalAmount) * 1.3).toString();
        final discountPercent = ((1 - (double.parse(totalAmount) / double.parse(originalAmount))) * 100).round();

        return _FlightCard(
          origin: origin,
          destination: destination,
          departure: departure,
          airlineName: airlineName,
          totalAmount: totalAmount,
          originalAmount: originalAmount,
          discountPercent: discountPercent,
          formatCurrency: formatCurrency,
          isDark: isDark,
        );
      }).toList(),
    );
  }
}

// Flight Card với Liquid Glass Effect
class _FlightCard extends StatefulWidget {
  final String origin;
  final String destination;
  final String departure;
  final String airlineName;
  final String totalAmount;
  final String originalAmount;
  final int discountPercent;
  final String Function(String?) formatCurrency;
  final bool isDark;

  const _FlightCard({
    required this.origin,
    required this.destination,
    required this.departure,
    required this.airlineName,
    required this.totalAmount,
    required this.originalAmount,
    required this.discountPercent,
    required this.formatCurrency,
    required this.isDark,
  });

  @override
  State<_FlightCard> createState() => _FlightCardState();
}

class _FlightCardState extends State<_FlightCard> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(widget.isDark ? 0.3 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 6),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(widget.isDark ? 0.05 : 0.3),
                blurRadius: 12,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isDark
                        ? [
                      Colors.grey[850]!.withOpacity(0.9),
                      Colors.grey[900]!.withOpacity(0.85),
                    ]
                        : [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(widget.isDark ? 0.15 : 0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    // Header Section
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Route with glass effect
                                Row(
                                  children: [
                                    _GlassCodeBadge(
                                      code: widget.origin,
                                      isDark: widget.isDark,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 20,
                                        color: widget.isDark ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                                    _GlassCodeBadge(
                                      code: widget.destination,
                                      isDark: widget.isDark,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Departure date
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 14,
                                      color: widget.isDark ? Colors.white60 : Colors.black54,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "${getTranslated("departure", context) ?? "Khởi hành"}: ${widget.departure.split('T').first}",
                                      style: TextStyle(
                                        color: widget.isDark ? Colors.white70 : Colors.black54,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Airline
                                Row(
                                  children: [
                                    Icon(
                                      Icons.flight_rounded,
                                      size: 14,
                                      color: widget.isDark ? Colors.white60 : Colors.black54,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        widget.airlineName,
                                        style: TextStyle(
                                          color: widget.isDark ? Colors.white : Colors.black87,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Discount Badge
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFF5252),
                                      Color(0xFFE53935),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  "-${widget.discountPercent}%",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider with gradient
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.isDark
                              ? [
                            Colors.white.withOpacity(0.05),
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.05),
                          ]
                              : [
                            Colors.black.withOpacity(0.05),
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),

                    // Price Section
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.isDark
                                  ? [
                                Colors.white.withOpacity(0.03),
                                Colors.white.withOpacity(0.01),
                              ]
                                  : [
                                Colors.white.withOpacity(0.5),
                                Colors.white.withOpacity(0.3),
                              ],
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Original price
                              Text(
                                NumberFormat.currency(locale: "vi_VN", symbol: "₫").format(double.parse(widget.originalAmount)),
                                style: TextStyle(
                                  color: widget.isDark ? Colors.white38 : Colors.black45,
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 13,
                                  decorationThickness: 2,
                                ),
                              ),
                              // Current prices
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Main price
                                  Text(
                                    widget.formatCurrency(widget.totalAmount),
                                    style: TextStyle(
                                      color: widget.isDark ? Colors.white : Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  // After tax price
                                  Text(
                                    "${getTranslated("after_tax_price", context) ?? "Giá sau thuế"}: ${widget.formatCurrency((double.parse(widget.totalAmount) * 2.96).toString())}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: widget.isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Glass Code Badge Widget
class _GlassCodeBadge extends StatelessWidget {
  final String code;
  final bool isDark;

  const _GlassCodeBadge({
    required this.code,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ]
                  : [
                Theme.of(context).primaryColor.withOpacity(0.15),
                Theme.of(context).primaryColor.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Theme.of(context).primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            code,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Theme.of(context).primaryColor,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

// === SKELETON LOADING với Glass Effect ===
class _SkeletonFlightList extends StatelessWidget {
  final bool isDark;

  const _SkeletonFlightList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(6, (_) => _SkeletonFlightCard(isDark: isDark)).toList(),
    );
  }
}

class _SkeletonFlightCard extends StatelessWidget {
  final bool isDark;

  const _SkeletonFlightCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                  Colors.grey[850]!.withOpacity(0.8),
                  Colors.grey[900]!.withOpacity(0.7),
                ]
                    : [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.15 : 0.5),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ShimmerBox(height: 28, width: 140, borderRadius: 10, isDark: isDark),
                            const SizedBox(height: 10),
                            _ShimmerBox(height: 14, width: 180, borderRadius: 8, isDark: isDark),
                            const SizedBox(height: 8),
                            _ShimmerBox(height: 14, width: 120, borderRadius: 8, isDark: isDark),
                          ],
                        ),
                      ),
                      _ShimmerBox(height: 36, width: 60, borderRadius: 12, isDark: isDark),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300],
                ),
                // Footer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ShimmerBox(height: 14, width: 100, borderRadius: 8, isDark: isDark),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _ShimmerBox(height: 18, width: 120, borderRadius: 8, isDark: isDark),
                          const SizedBox(height: 6),
                          _ShimmerBox(height: 12, width: 140, borderRadius: 8, isDark: isDark),
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
    );
  }
}

// === SHIMMER BOX ===
class _ShimmerBox extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;
  final bool isDark;

  const _ShimmerBox({
    required this.height,
    required this.width,
    required this.borderRadius,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: _Shimmer(isDark: isDark),
    );
  }
}

// === SHIMMER EFFECT ===
class _Shimmer extends StatefulWidget {
  final bool isDark;

  const _Shimmer({required this.isDark});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
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
              colors: widget.isDark
                  ? [
                Colors.transparent,
                Colors.white.withOpacity(0.1),
                Colors.transparent,
              ]
                  : [
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