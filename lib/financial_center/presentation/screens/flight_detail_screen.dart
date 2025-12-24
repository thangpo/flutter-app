import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../services/flight_service.dart';
import '../models/flight_data_models.dart';
import '../widgets/flight_route_header_map.dart';
import '../widgets/flight_booking_cta.dart';
import '../widgets/modern_boarding_pass_card.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

class FlightDetailScreen extends StatelessWidget {
  final String flightId;
  const FlightDetailScreen({super.key, required this.flightId});

  DateTime? _parseIso(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _hhmm(DateTime? dt) => dt == null ? '--:--' : DateFormat('HH:mm', 'vi_VN').format(dt);
  String _dateLine(DateTime? dt) => dt == null ? '' : DateFormat('EEE, dd/MM/yyyy', 'vi_VN').format(dt);
  String _formatVnd(String? raw) {
    final s = (raw ?? '').toString();
    if (s.trim().isEmpty) return '-';
    try {
      final value = double.parse(s);
      return NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(value.round());
    } catch (_) {
      return s;
    }
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: FlightService.getFlightDetail(flightId),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Lỗi tải chi tiết: ${snap.error}'),
              ),
            );
          }

          final raw = snap.data ?? <String, dynamic>{};
          final detailRes = FlightDetailResponse.fromJson(raw);

          if (detailRes.status != 1) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(detailRes.message.isNotEmpty ? detailRes.message : 'Không thể tải dữ liệu.'),
              ),
            );
          }

          final flight = detailRes.flight;
          if (flight == null) {
            return const Center(child: Text('Không có dữ liệu.'));
          }
          final dep = _parseIso(flight.departureTimeIso ?? flight.departureTime);
          final arr = _parseIso(flight.arrivalTimeIso ?? flight.arrivalTime);
          final from = flight.airportFrom;
          final to = flight.airportTo;
          final fromCode = (from?.code?.trim().isNotEmpty ?? false) ? from!.code!.trim() : '---';
          final toCode = (to?.code?.trim().isNotEmpty ?? false) ? to!.code!.trim() : '---';
          final fromName = from?.name ?? '-';
          final toName = to?.name ?? '-';
          final airlineName = flight.airline?.name ?? 'Airline';
          final coverUrl = (flight.airline?.imageUrl?.trim().isNotEmpty ?? false) ? flight.airline!.imageUrl!.trim() : null;
          final mainSeat = flight.flightSeat.isNotEmpty ? flight.flightSeat.first : null;
          final seatClass = mainSeat?.seatType?.name ?? '—';
          final fromLat = _toDouble(from?.mapLat);
          final fromLng = _toDouble(from?.mapLng);
          final toLat = _toDouble(to?.mapLat);
          final toLng = _toDouble(to?.mapLng);
          final canShowMap = fromLat != null && fromLng != null && toLat != null && toLng != null;
          final bool isDark = Provider.of<ThemeController>(context, listen: true).darkTheme;
          final canBook = (flight.canBook == true) && flight.flightSeat.isNotEmpty;
          final minPriceText = _formatVnd(flight.minPrice);
          final departText = flight.departureTimeHtml ?? _hhmm(dep);
          final arriveText = flight.arrivalTimeHtml ?? _hhmm(arr);


          ll.LatLng? fromPos;
          ll.LatLng? toPos;

          if (canShowMap) {
            fromPos = ll.LatLng(fromLat!, fromLng!);
            toPos = ll.LatLng(toLat!, toLng!);
          }

          return Scaffold(
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  stretch: true,
                  expandedHeight: 220,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: canShowMap
                        ? FlightRouteHeaderMap(
                      height: 220,
                      borderRadius: 0,
                      from: fromPos!,
                      to: toPos!,
                      fromCode: fromCode,
                      fromName: fromName,
                      toCode: toCode,
                      toName: toName,
                    )
                        : const SizedBox.shrink(),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ModernBoardingPassCard(
                          isDark: isDark,
                          coverUrl: coverUrl,
                          dateLeft: _dateLine(dep),
                          timeRight: departText,
                          fromCode: fromCode,
                          fromName: fromName,
                          toCode: toCode,
                          toName: toName,
                          airlineName: airlineName,
                          durationText: (flight.duration ?? '').trim().isEmpty ? null : '${flight.duration}h',
                          flightCode: flight.code ?? 'N/A',
                          boarding: departText,
                          depart: departText,
                          arrive: arriveText,
                          gate: 'G${flight.id}',
                          seat: mainSeat?.id != null ? 'S${mainSeat!.id}' : '--',
                          seatClass: seatClass,
                          passenger: '—',
                          priceText: minPriceText,
                        ),

                        const SizedBox(height: 14),

                        if (flight.flightSeat.isNotEmpty) ...[
                          const Text(
                            'Seat classes',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          ...flight.flightSeat.map(
                                (s) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _SeatRow(
                                title: s.seatType?.name ?? 'Seat',
                                price: s.priceHtml ?? _formatVnd(s.price),
                                sub: _seatSubLine(s),
                                right: 'Còn: ${s.maxPassengers ?? 0}',
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            bottomNavigationBar: FlightBookingCTA(
              enabled: canBook,
              priceText: minPriceText,
              onTap: () async {
                final selected = await showSeatClassPickerSheet(
                  context: context,
                  seats: flight.flightSeat,
                  airlineName: airlineName,
                  fromCode: fromCode,
                  toCode: toCode,
                  departTimeText: departText,
                  arriveTimeText: arriveText,
                  flightCode: flight.code ?? 'N/A',
                );

                if (selected == null) return;
              },
            ),
          );
        },
      ),
    );
  }

  static String _seatSubLine(FlightSeat s) {
    final parts = <String>[];
    if ((s.person ?? '').trim().isNotEmpty) parts.add('Person: ${s.person}');
    if (s.baggageCabin != null) parts.add('Cabin: ${s.baggageCabin}kg');
    if (s.baggageCheckIn != null) parts.add('Check-in: ${s.baggageCheckIn}kg');
    return parts.join(' • ');
  }
}

class _SeatRow extends StatelessWidget {
  final String title;
  final String price;
  final String sub;
  final String right;

  const _SeatRow({
    required this.title,
    required this.price,
    required this.sub,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                if (sub.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(sub, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class FlightRouteMapOsm extends StatelessWidget {
  final ll.LatLng center;
  final double zoom;
  final ll.LatLng? from;
  final ll.LatLng? to;
  final String fromLabel;
  final String toLabel;

  const FlightRouteMapOsm({
    super.key,
    required this.center,
    required this.zoom,
    required this.from,
    required this.to,
    required this.fromLabel,
    required this.toLabel,
  });

  @override
  Widget build(BuildContext context) {
    final hasPoints = from != null && to != null;

    final markers = <Marker>[
      if (from != null)
        Marker(
          point: from!,
          width: 44,
          height: 44,
          child: const Icon(Icons.location_on, size: 36, color: Colors.red),
        ),
      if (to != null)
        Marker(
          point: to!,
          width: 44,
          height: 44,
          child: const Icon(Icons.location_on, size: 36, color: Colors.green),
        ),
    ];

    final lines = <Polyline>[
      if (hasPoints)
        Polyline(
          points: [from!, to!],
          strokeWidth: 4,
          color: Colors.blueAccent,
        ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: zoom,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.your.app',
          ),
          PolylineLayer(polylines: lines),
          MarkerLayer(markers: markers),
          Positioned(
            right: 10,
            bottom: 10,
            child: _OpenExternalMapButton(
              from: from,
              to: to,
              fromLabel: fromLabel,
              toLabel: toLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenExternalMapButton extends StatelessWidget {
  final ll.LatLng? from;
  final ll.LatLng? to;
  final String fromLabel;
  final String toLabel;

  const _OpenExternalMapButton({
    required this.from,
    required this.to,
    required this.fromLabel,
    required this.toLabel,
  });

  Future<void> _openExternal() async {
    if (from == null || to == null) return;

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
          '&origin=${from!.latitude},${from!.longitude}'
          '&destination=${to!.latitude},${to!.longitude}'
          '&travelmode=driving',
    );

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: (from != null && to != null) ? _openExternal : null,
      icon: const Icon(Icons.directions),
      label: const Text('Directions'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}