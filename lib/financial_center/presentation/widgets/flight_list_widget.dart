import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'flight_list_item.dart';

class FlightListWidget extends StatefulWidget {
  final List<dynamic>? flights;
  final bool isLoading;

  const FlightListWidget({super.key, this.flights, this.isLoading = false});

  @override
  State<FlightListWidget> createState() => _FlightListWidgetState();
}

class _FlightListWidgetState extends State<FlightListWidget> {
  List<dynamic> flights = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    if (widget.flights != null && widget.flights!.isNotEmpty) {
      flights = widget.flights!;
      isLoading = widget.isLoading;
    } else {
      fetchFlights();
    }
  }

  @override
  void didUpdateWidget(covariant FlightListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flights != oldWidget.flights) {
      setState(() {
        flights = widget.flights ?? [];
        isLoading = widget.isLoading;
      });
    }
  }

  Future<void> fetchFlights() async {
    final apiKey =
        "duffel_test_lkVeDLi9UBt6AvHi8BuQ4CwXBj6HEhE5idyn3nz9hrb";
    final now = DateTime.now().add(const Duration(days: 2));
    final departureDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    setState(() {
      isLoading = true;
    });

    try {
      final requestUrl = Uri.parse("https://api.duffel.com/air/offer_requests");
      final requestRes = await http.post(
        requestUrl,
        headers: {
          "Authorization": "Bearer $apiKey",
          "Duffel-Version": "v2",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "data": {
            "slices": [
              {
                "origin": "SGN",
                "destination": "HAN",
                "departure_date": departureDate
              }
            ],
            "passengers": [
              {"type": "adult"}
            ],
            "cabin_class": "economy"
          }
        }),
      );

      if (requestRes.statusCode != 201) {
        throw Exception("Offer request failed: ${requestRes.body}");
      }

      final requestData = jsonDecode(requestRes.body);
      final offerRequestId = requestData["data"]["id"];
      final offersUrl = Uri.parse(
          "https://api.duffel.com/air/offers?offer_request_id=$offerRequestId&limit=20");
      final offersRes = await http.get(
        offersUrl,
        headers: {
          "Authorization": "Bearer $apiKey",
          "Duffel-Version": "v2",
          "Content-Type": "application/json",
        },
      );

      if (offersRes.statusCode != 200) {
        throw Exception("Get offers failed: ${offersRes.body}");
      }

      final offersData = jsonDecode(offersRes.body);
      final offers = offersData["data"] as List;
      final vnAirlines = ["Vietnam Airlines", "VietJet Air", "Bamboo Airways"];
      final filtered = offers
          .where((f) => f["owner"] != null && vnAirlines.contains(f["owner"]["name"]))
          .take(10)
          .toList();

      setState(() {
        flights = filtered;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() {
        flights = [];
        isLoading = false;
      });
    }
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(5, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          height: 100,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoadingSkeleton();

    if (flights.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text("Không tìm thấy chuyến bay nào."),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "Chuyến bay gợi ý",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        ...flights.map((f) {
          final id = f["id"];
          final airline = f["owner"]["name"] ?? "Hãng bay";
          final logoUrl = f["owner"]["logo_symbol_url"];
          final slice = f["slices"][0];
          final from = slice["origin"]["iata_code"];
          final to = slice["destination"]["iata_code"];
          final segment = slice["segments"][0];
          final departure = segment["departing_at"];
          final arrival = segment["arriving_at"];
          final price = "${f["total_amount"]} ${f["total_currency"]}";
          final cabinClass = f["cabin_class"] ?? "Economy";

          String translateBaggageType(String type) {
            switch (type) {
              case "checked":
                return "Ký gửi";
              case "carry_on":
                return "Xách tay";
              default:
                return type;
            }
          }

          final baggage = (segment["passengers"] != null &&
              segment["passengers"].isNotEmpty &&
              segment["passengers"][0]["baggages"] != null)
              ? (segment["passengers"][0]["baggages"] as List)
              .map((b) => "${b["quantity"]} ${translateBaggageType(b["type"])}")
              .join(", ")
              : "Không có";

          final availability = (f["total_amount"] != null &&
              f["total_amount"].toString().isNotEmpty)
              ? "Còn chỗ"
              : "Hết chỗ";

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
        }),
      ],
    );
  }
}