import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'flight_list_item.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

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

  @override
  void initState() {
    super.initState();

    // Nếu bên ngoài đã truyền kết quả search vào thì dùng luôn
    if (widget.flights != null && widget.flights!.isNotEmpty) {
      flights = widget.flights!;
      isLoading = widget.isLoading;
    } else {
      // Không có dữ liệu truyền vào -> gọi Duffel để load gợi ý
      fetchFlights();
    }
  }

  @override
  void didUpdateWidget(covariant FlightListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Khi parent truyền flights mới hoặc trạng thái loading mới
    if (widget.flights != oldWidget.flights ||
        widget.isLoading != oldWidget.isLoading) {
      setState(() {
        flights = widget.flights ?? [];
        isLoading = widget.isLoading;
      });
    }
  }

  Future<void> fetchFlights() async {
    const apiKey =
        'duffel_test_lkVeDLi9UBt6AvHi8BuQ4CwXBj6HEhE5idyn3nz9hrb';

    final now = DateTime.now().add(const Duration(days: 2));
    final departureDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      // 1. Tạo offer request
      final requestUrl = Uri.parse('https://api.duffel.com/air/offer_requests');
      final requestRes = await http.post(
        requestUrl,
        headers: const {
          'Authorization': 'Bearer $apiKey',
          'Duffel-Version': 'v2',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data': {
            'slices': [
              {
                'origin': 'SGN',
                'destination': 'HAN',
                'departure_date': departureDate,
              }
            ],
            'passengers': [
              {'type': 'adult'}
            ],
            'cabin_class': 'economy',
          }
        }),
      );

      if (requestRes.statusCode != 201) {
        throw Exception('Offer request failed: ${requestRes.body}');
      }

      final requestData = jsonDecode(requestRes.body);
      final offerRequestId = requestData['data']['id'];

      // 2. Lấy danh sách offers từ offer_request_id
      final offersUrl = Uri.parse(
        'https://api.duffel.com/air/offers?offer_request_id=$offerRequestId&limit=20',
      );

      final offersRes = await http.get(
        offersUrl,
        headers: const {
          'Authorization': 'Bearer $apiKey',
          'Duffel-Version': 'v2',
          'Content-Type': 'application/json',
        },
      );

      if (offersRes.statusCode != 200) {
        throw Exception('Get offers failed: ${offersRes.body}');
      }

      final offersData = jsonDecode(offersRes.body);
      final List offers = (offersData['data'] ?? []) as List;

      // Lọc các hãng VN
      const vnAirlines = ['Vietnam Airlines', 'VietJet Air', 'Bamboo Airways'];

      final filtered = offers
          .where((f) =>
      f['owner'] != null &&
          vnAirlines.contains(f['owner']['name'] ?? ''))
          .take(10)
          .toList();

      if (!mounted) return;
      setState(() {
        flights = filtered;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      if (!mounted) return;
      setState(() {
        flights = [];
        isLoading = false;
      });
    }
  }

  // ======= Helpers đa ngôn ngữ =======

  String tr(BuildContext context, String key, String fallback) {
    return getTranslated(key, context) ?? fallback;
  }

  String _translateBaggageType(BuildContext context, String type) {
    switch (type) {
      case 'checked':
        return tr(context, 'flight_baggage_checked', 'Ký gửi');
      case 'carry_on':
        return tr(context, 'flight_baggage_carry_on', 'Xách tay');
      default:
        return type;
    }
  }

  // ======= Skeleton loading =======

  Widget _buildLoadingSkeleton(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor =
    isDark ? const Color(0xFF111827) : Colors.grey.shade200;
    final highlightColor =
    isDark ? const Color(0xFF1F2937) : Colors.grey.shade300;

    return Column(
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              // Avatar hãng bay
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: highlightColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              // Text skeleton
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
              // Chip giá
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

  // ======= Build =======

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
            tr(
              context,
              'flight_no_result',
              'Không tìm thấy chuyến bay nào.',
            ),
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
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          final id = f['id'];
          final airline = f['owner']?['name'] ?? 'Hãng bay';
          final logoUrl = f['owner']?['logo_symbol_url'];

          final slice = (f['slices'] as List).first;
          final from = slice['origin']?['iata_code'] ?? '';
          final to = slice['destination']?['iata_code'] ?? '';

          final segment = (slice['segments'] as List).first;
          final departure = segment['departing_at'];
          final arrival = segment['arriving_at'];

          final price = '${f["total_amount"]} ${f["total_currency"]}';
          final cabinClass = f['cabin_class'] ?? 'Economy';

          final baggage = (segment['passengers'] != null &&
              segment['passengers'].isNotEmpty &&
              segment['passengers'][0]['baggages'] != null)
              ? (segment['passengers'][0]['baggages'] as List)
              .map((b) =>
          '${b["quantity"]} ${_translateBaggageType(context, b["type"])}')
              .join(', ')
              : tr(context, 'flight_baggage_none', 'Không có');

          final availability = (f['total_amount'] != null &&
              f['total_amount'].toString().isNotEmpty)
              ? tr(context, 'flight_seat_available', 'Còn chỗ')
              : tr(context, 'flight_seat_unavailable', 'Hết chỗ');

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