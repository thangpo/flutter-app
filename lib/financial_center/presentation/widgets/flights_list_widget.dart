import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
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
        departureDate: DateFormat("yyyy-MM-dd")
            .format(DateTime.now().add(const Duration(days: 7))),
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
    final isDark =
        Provider.of<ThemeController>(context, listen: true).darkTheme;

    final Color sectionBg = isDark
        ? const Color(0xFF05070D)
        : Theme.of(context).scaffoldBackgroundColor;

    return Container(
      color: sectionBg,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              getTranslated("best_flight_deals", context) ??
                  "Ưu đãi vé máy bay",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),

          _isLoading
              ? _SkeletonFlightList(isDark: isDark)
              : _flights.isEmpty
              ? _buildEmptyState(isDark)
              : _buildFlightList(isDark, sectionBg),
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
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
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
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.flight_outlined,
                    size: 48,
                    color: isDark ? Colors.white : Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  getTranslated("no_flights", context) ?? "Không có chuyến bay",
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
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

  Widget _buildFlightList(bool isDark, Color sectionBg) {
    return Column(
      children: _flights
          .asMap()
          .entries
          .take(6)
          .map((entry) {
        final index = entry.key;
        final flight = entry.value;

        final slices = flight["slices"] as List<dynamic>? ?? [];
        final slice = slices.isNotEmpty ? slices.first : {};

        final segments = slice["segments"] as List<dynamic>? ?? [];
        final firstSegment = segments.isNotEmpty ? segments.first : {};
        final lastSegment = segments.isNotEmpty ? segments.last : firstSegment;

        final origin = slice["origin"]?["iata_code"] ?? "???";
        final destination = slice["destination"]?["iata_code"] ?? "???";

        final originAirport = slice["origin"]?["name"] ?? "";
        final originCity = slice["origin"]?["city_name"] ?? "";

        final destinationAirport = slice["destination"]?["name"] ?? "";
        final destinationCity = slice["destination"]?["city_name"] ?? "";

        final departure = firstSegment["departing_at"] ?? "";
        final arrival = lastSegment["arriving_at"] ?? "";
        final durationIso = firstSegment["duration"] ?? "";

        final airlineName = flight["owner"]?["name"] ??
            getTranslated("airline", context) ??
            "Hãng bay";
        final totalAmount = flight["total_amount"] ?? "0";

        final cabin = firstSegment["cabin_class"] ?? "Economy";
        final bool isBest = index == 0;
        final String badgeText = isBest ? "Recommended" : cabin.toString();
        final Color badgeColor =
        isBest ? const Color(0xFF22C55E) : const Color(0xFF6366F1);

        final seatsLeft = flight["seats_left"]?.toString() ?? "10";

        return _FlightCard(
          origin: origin,
          destination: destination,
          departure: departure,
          arrival: arrival,
          airlineName: airlineName,
          totalAmount: totalAmount,
          originAirport: originAirport,
          originCity: originCity,
          destinationAirport: destinationAirport,
          destinationCity: destinationCity,
          durationIso: durationIso,
          badgeText: badgeText,
          badgeColor: badgeColor,
          seatsLeft: seatsLeft,
          formatCurrency: formatCurrency,
          isDark: isDark,
          outerBackgroundColor: sectionBg,
        );
      })
          .toList(),
    );
  }
}

class _FlightCard extends StatefulWidget {
  final String origin;
  final String destination;
  final String departure;
  final String arrival;
  final String airlineName;
  final String totalAmount;

  final String originAirport;
  final String originCity;
  final String destinationAirport;
  final String destinationCity;

  final String durationIso;
  final String badgeText;
  final Color badgeColor;
  final String seatsLeft;

  final String Function(String?) formatCurrency;
  final bool isDark;
  final Color outerBackgroundColor;

  const _FlightCard({
    required this.origin,
    required this.destination,
    required this.departure,
    required this.arrival,
    required this.airlineName,
    required this.totalAmount,
    required this.originAirport,
    required this.originCity,
    required this.destinationAirport,
    required this.destinationCity,
    required this.durationIso,
    required this.badgeText,
    required this.badgeColor,
    required this.seatsLeft,
    required this.formatCurrency,
    required this.isDark,
    required this.outerBackgroundColor,
  });

  @override
  State<_FlightCard> createState() => _FlightCardState();
}

class _FlightCardState extends State<_FlightCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  String _formatTime(String raw) {
    if (raw.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('hh:mma').format(dt).toUpperCase();
    } catch (_) {
      return raw;
    }
  }

  String _formatDateLabel(String raw) {
    if (raw.isEmpty) return '--';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('EEE dd MMM').format(dt);
    } catch (_) {
      return raw.split('T').first;
    }
  }

  String _formatDuration(String iso) {
    if (iso.isEmpty) return '';
    final reg = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?');
    final m = reg.firstMatch(iso);
    if (m == null) return '';
    final h = m.group(1);
    final mnt = m.group(2);
    final buf = <String>[];
    if (h != null) buf.add('${h}h');
    if (mnt != null) buf.add('${mnt}m');
    return buf.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final depTime = _formatTime(widget.departure);
    final arrTime = _formatTime(widget.arrival);
    final depDate = _formatDateLabel(widget.departure);
    final arrDate = _formatDateLabel(widget.arrival);
    final durationText = _formatDuration(widget.durationIso);
    final Color cardBg =
    widget.isDark ? const Color(0xFF0B1723) : const Color(0xFFE4F4FA);
    final Color primaryBlue =
    widget.isDark ? const Color(0xFF93C5FD) : const Color(0xFF004976);
    final Color textMain =
    widget.isDark ? Colors.white : const Color(0xFF0F172A);
    final Color textSub =
    widget.isDark ? Colors.white70 : const Color(0xFF4B5563);

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(widget.isDark ? 0.4 : 0.15),
                blurRadius: 18,
                offset: const Offset(0, 6),
                spreadRadius: -4,
              ),
            ],
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFBFDBFE),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.origin,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.originAirport,
                            style: TextStyle(
                              fontSize: 11,
                              color: textSub,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.destination,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.destinationAirport,
                            style: TextStyle(
                              fontSize: 11,
                              color: textSub,
                            ),
                            maxLines: 1,
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            height: 1.5,
                            decoration: BoxDecoration(
                              color: primaryBlue.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Transform.rotate(
                          angle: -0.3,
                          child: Icon(
                            Icons.airplanemode_active,
                            size: 20,
                            color: primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            height: 1.5,
                            decoration: BoxDecoration(
                              color: primaryBlue.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      durationText.isEmpty ? '—' : durationText,
                      style: TextStyle(
                        fontSize: 11,
                        color: textSub,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Non-stop',
                      style: TextStyle(
                        fontSize: 10,
                        color: textSub.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _DateTimeInfo(
                        alignRight: false,
                        label: 'Depart',
                        date: depDate,
                        time: depTime,
                        city: widget.originCity,
                        textMain: textMain,
                        textSub: textSub,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateTimeInfo(
                        alignRight: true,
                        label: 'Arrive',
                        date: arrDate,
                        time: arrTime,
                        city: widget.destinationCity,
                        textMain: textMain,
                        textSub: textSub,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.airlineName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: primaryBlue,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.formatCurrency(widget.totalAmount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Per Adult',
                      style: TextStyle(
                        fontSize: 11,
                        color: textSub,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateTimeInfo extends StatelessWidget {
  final bool alignRight;
  final String label;
  final String date;
  final String time;
  final String city;
  final Color textMain;
  final Color textSub;

  const _DateTimeInfo({
    required this.alignRight,
    required this.label,
    required this.date,
    required this.time,
    required this.city,
    required this.textMain,
    required this.textSub,
  });

  @override
  Widget build(BuildContext context) {
    final TextAlign ta = alignRight ? TextAlign.right : TextAlign.left;
    final CrossAxisAlignment ca =
    alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: ca,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textSub,
          ),
          textAlign: ta,
        ),
        const SizedBox(height: 2),
        Text(
          date,
          style: TextStyle(
            fontSize: 11,
            color: textSub,
          ),
          textAlign: ta,
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textMain,
          ),
          textAlign: ta,
        ),
        const SizedBox(height: 2),
        Text(
          city,
          style: TextStyle(
            fontSize: 11,
            color: textSub,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: ta,
        ),
      ],
    );
  }
}

class _SkeletonFlightList extends StatelessWidget {
  final bool isDark;

  const _SkeletonFlightList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
      List.generate(3, (_) => _SkeletonFlightCard(isDark: isDark)).toList(),
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
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? const Color(0xFF101528) : Colors.grey[300],
      ),
      child: const _ShimmerSkeleton(),
    );
  }
}

class _ShimmerSkeleton extends StatefulWidget {
  const _ShimmerSkeleton();

  @override
  State<_ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<_ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
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
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _controller.value * 3, 0),
              end: Alignment(1.0 + _controller.value * 3, 0),
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.5),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
}