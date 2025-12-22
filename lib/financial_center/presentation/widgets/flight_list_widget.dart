import 'dart:async';
import 'flight_list_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/flight_service.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

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

  bool _headerVisible = true;
  double _lastPixels = 0;
  DateTime _lastNotiAt = DateTime.fromMillisecondsSinceEpoch(0);

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

  void _handleScrollNotification(ScrollNotification n) {
    if (!mounted) return;
    if (n.metrics.axis != Axis.vertical) return;

    // throttle nhẹ để tránh setState quá dày
    final now = DateTime.now();
    if (now.difference(_lastNotiAt).inMilliseconds < 50) return;
    _lastNotiAt = now;

    final pixels = n.metrics.pixels;
    final delta = pixels - _lastPixels;

    if (delta > 10 && _headerVisible) {
      setState(() => _headerVisible = false);
    } else if (delta < -10 && !_headerVisible) {
      setState(() => _headerVisible = true);
    }

    _lastPixels = pixels;
  }

  Widget _buildLoadingSkeleton(BuildContext context, {required bool isDark}) {
    final baseColor = isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9);
    final highlightColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);

    return Column(
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
            ),
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
    final isDark = Provider.of<ThemeController>(context, listen: true).darkTheme;

    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub = isDark ? Colors.white70 : Colors.black54;

    final header = AnimatedSlide(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      offset: _headerVisible ? Offset.zero : const Offset(0, -0.25),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: _headerVisible ? 1 : 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  tr(context, 'flight_recommended_title', 'Chuyến bay gợi ý'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: textMain,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.06),
                  ),
                ),
                child: Text(
                  "${flights.length}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: textSub,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Widget body;
    if (isLoading) {
      body = _buildLoadingSkeleton(context, isDark: isDark);
    } else if (flights.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            tr(context, 'flight_no_result', 'Không tìm thấy chuyến bay nào.'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSub,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          ...List.generate(flights.length, (i) {
            final f = flights[i];

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

            return _StaggeredFadeSlide(
              index: i,
              child: FlightListItem(
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
              ),
            );
          }),
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        _handleScrollNotification(n);
        return false;
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: Container(
          key: ValueKey<String>("state_${isLoading}_${flights.length}"),
          child: body,
        ),
      ),
    );
  }
}

class _StaggeredFadeSlide extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredFadeSlide({
    required this.index,
    required this.child,
  });

  @override
  State<_StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<_StaggeredFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _opacity = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

    _timer = Timer(Duration(milliseconds: 45 * widget.index), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}