import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/flight_service.dart';

class FlightDetailScreen extends StatefulWidget {
  final String flightId;

  const FlightDetailScreen({
    super.key,
    required this.flightId,
  });

  @override
  State<FlightDetailScreen> createState() => _FlightDetailScreenState();
}

class _FlightDetailScreenState extends State<FlightDetailScreen> {
  Map<String, dynamic>? flightDetail;
  List<dynamic> flightSeatMaps = [];
  List<dynamic> flightOffers = [];
  bool isLoading = true;
  String? error;
  int? selectedFareIndex;

  @override
  void initState() {
    super.initState();
    _loadFlightDetail();
  }

  Future<void> _loadFlightDetail() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final detail = await FlightService.getFlightDetail(widget.flightId);
      final seatMaps = await FlightService.getSeatMaps(widget.flightId);

      // Fix: Check null before accessing offer_request_id
      final data = detail["data"];
      if (data != null && data["offer_request_id"] != null) {
        final offerRequestId = data["offer_request_id"];
        final offers = await FlightService.getOffers();

        setState(() {
          flightDetail = detail;
          flightSeatMaps = seatMaps ?? [];
          flightOffers = offers ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          flightDetail = detail;
          flightSeatMaps = seatMaps ?? [];
          flightOffers = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  String formatPrice(double price) {
    int priceVND = (price * 26000).round();
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(priceVND)}đ';
  }

  String formatTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      return DateFormat('HH:mm').format(dt);
    } catch (e) {
      return dateTime;
    }
  }

  String calculateDuration(String departure, String arrival) {
    try {
      final dep = DateTime.parse(departure);
      final arr = DateTime.parse(arrival);
      final duration = arr.difference(dep);
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      return '${hours}h ${minutes}m';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết chuyến bay'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết chuyến bay'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Lỗi: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadFlightDetail,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    // Fix: Add null checks for all nested data
    if (flightDetail == null || flightDetail!['data'] == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết chuyến bay'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Không có dữ liệu chuyến bay'),
        ),
      );
    }

    final data = flightDetail!['data'];
    final slices = data['slices'] as List?;

    if (slices == null || slices.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết chuyến bay'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Không có thông tin chuyến bay'),
        ),
      );
    }

    final firstSlice = slices[0];
    final segments = firstSlice['segments'] as List?;

    if (segments == null || segments.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết chuyến bay'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Không có thông tin hành trình'),
        ),
      );
    }

    final firstSegment = segments[0];

    // Fix: Safe access with null checks
    final origin = firstSegment['origin'];
    final destination = firstSegment['destination'];
    final departureTime = firstSegment['departing_at'] ?? '';
    final arrivalTime = firstSegment['arriving_at'] ?? '';
    final airline = firstSegment['marketing_carrier']?['name'] ?? 'N/A';
    final airlineLogo = firstSegment['marketing_carrier']?['logo_symbol_url'];
    final totalAmount = double.tryParse(data['total_amount']?.toString() ?? '0') ?? 0.0;
    final baseAmount = double.tryParse((data['base_amount'] ?? data['total_amount'])?.toString() ?? '0') ?? 0.0;

    // Fix: Calculate selected price correctly from flightOffers
    double selectedPrice = baseAmount;
    if (selectedFareIndex != null &&
        selectedFareIndex! >= 0 &&
        selectedFareIndex! < flightOffers.length) {
      final selectedOffer = flightOffers[selectedFareIndex!];
      selectedPrice = double.tryParse(selectedOffer["total_amount"]?.toString() ?? '0') ?? baseAmount;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Nâng hạng vé',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flight_takeoff, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Chuyến đi',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              formatPrice(totalAmount),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            if (airlineLogo != null && airlineLogo.isNotEmpty)
                              Image.network(
                                airlineLogo,
                                width: 40,
                                height: 40,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.amber[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.flight, color: Colors.orange),
                                  );
                                },
                              )
                            else
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.amber[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.flight, color: Colors.orange),
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formatTime(departureTime),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        calculateDuration(departureTime, arrivalTime),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        formatTime(arrivalTime),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: Colors.grey[300],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        origin?['iata_code'] ?? 'N/A',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        'Bay thẳng',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        destination?['iata_code'] ?? 'N/A',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            airline,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Phổ thông tiết kiệm',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () {
                              // Show flight details
                            },
                            child: const Text(
                              'Xem điều kiện vé',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nâng hạng vé (${flightOffers.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Fix: Add empty state
                        if (flightOffers.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'Không có hạng vé nào khác',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          )
                        else
                          ...flightOffers.asMap().entries.map((entry) {
                            final index = entry.key;
                            final offer = entry.value;

                            final cabin = offer["cabin_class_marketing_name"]?.toString() ?? "Không rõ";
                            final amount = double.tryParse(offer["total_amount"]?.toString() ?? '0') ?? 0.0;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildFareOption(
                                title: cabin,
                                status: "Có sẵn",
                                price: formatPrice(amount),
                                isSelected: selectedFareIndex == index,
                                features: [
                                  "Hành lý xách tay 7kg",
                                  "Hành lý ký gửi 20kg",
                                  if (cabin.toLowerCase().contains("business")) "Phòng chờ thương gia",
                                ],
                                onTap: () {
                                  setState(() {
                                    selectedFareIndex = index;
                                  });
                                },
                              ),
                            );
                          }),

                        const SizedBox(height: 20),
                        Text(
                          'Chọn chỗ ngồi',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Fix: Add null check and empty state
                        if (flightSeatMaps.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'Sơ đồ chỗ ngồi chưa có sẵn',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          )
                        else
                          ...flightSeatMaps.expand((seatMap) {
                            final seats = (seatMap["seats"] ?? []) as List<dynamic>;
                            return seats.map((seat) {
                              final available = seat["available"] == true;
                              final seatNumber = seat["designator"]?.toString() ?? "N/A";
                              return ListTile(
                                leading: Icon(
                                  available ? Icons.event_seat : Icons.event_busy,
                                  color: available ? Colors.green : Colors.red,
                                ),
                                title: Text("Ghế $seatNumber"),
                                subtitle: Text(available ? "Có sẵn" : "Đã đặt"),
                                onTap: available
                                    ? () {
                                  print("Chọn ghế $seatNumber");
                                }
                                    : null,
                              );
                            });
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Giá vé',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatPrice(selectedPrice),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '/1 hành khách',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Nhận ${(selectedPrice * 0.01).round()} Xu',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.monetization_on, size: 14, color: Colors.orange[700]),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: selectedFareIndex != null ? () {
                      print('Selected fare index: $selectedFareIndex');
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      selectedFareIndex != null ? 'Tiếp tục' : 'Chọn hạng vé',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: selectedFareIndex != null ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareOption({
    required String title,
    String? status,
    required String price,
    required bool isSelected,
    required List<String> features,
    List<String> restrictions = const [],
    VoidCallback? onTap,
  }) {
    final bool isDisabled = onTap == null;

    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? Colors.blue[50] : Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (status != null)
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDisabled ? Colors.grey : Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                price,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 12),
              ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              ...restrictions.map((restriction) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        restriction,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}