import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../screens/flight_detail_screen.dart';

class FlightListItem extends StatelessWidget {
  final String flightId;
  final String airline;
  final String from;
  final String to;
  final String departure;
  final String arrival;
  final String price;
  final String cabinClass;
  final String baggage;
  final String availability;
  final String? logoUrl;

  const FlightListItem({
    super.key,
    required this.flightId,
    required this.airline,
    required this.from,
    required this.to,
    required this.departure,
    required this.arrival,
    required this.price,
    required this.cabinClass,
    required this.baggage,
    required this.availability,
    this.logoUrl,
  });

  String formatPrice(String price) {
    try {
      String numericPrice = price.replaceAll(RegExp(r'[^0-9.,]'), '');
      if (numericPrice.isEmpty) return price;
      numericPrice = numericPrice.replaceAll(',', '.');
      double priceUSD = double.parse(numericPrice);
      int priceVND = (priceUSD * 26000).round();
      final formatter = NumberFormat('#,###', 'vi_VN');
      return '${formatter.format(priceVND)} ₫';
    } catch (e) {
      return price;
    }
  }

  String formatDateTime(String dateTime) {
    try {
      DateTime dt;
      if (dateTime.contains('T')) {
        dt = DateTime.parse(dateTime);
      } else if (dateTime.contains('/')) {
        final parts = dateTime.split(' ');
        final dateParts = parts[0].split('/');
        if (dateParts.length == 3) {
          dt = DateTime(
            int.parse(dateParts[2]),
            int.parse(dateParts[1]),
            int.parse(dateParts[0]),
          );
          if (parts.length > 1) {
            final timeParts = parts[1].split(':');
            dt = DateTime(
              dt.year,
              dt.month,
              dt.day,
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
            );
          }
        } else {
          return dateTime;
        }
      } else {
        return dateTime;
      }

      final timeFormat = DateFormat('HH:mm', 'vi_VN');
      final dateFormat = DateFormat('dd/MM/yyyy', 'vi_VN');
      return '${timeFormat.format(dt)}, ${dateFormat.format(dt)}';
    } catch (e) {
      return dateTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlightDetailScreen(flightId: flightId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00BCD4).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        if (logoUrl != null && logoUrl!.endsWith(".svg"))
                          SvgPicture.network(
                            logoUrl!,
                            width: 40,
                            height: 40,
                            placeholderBuilder: (context) =>
                            const Icon(Icons.flight, color: Colors.blue),
                          )
                        else if (logoUrl != null)
                          Image.network(
                            logoUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.flight, color: Colors.blue);
                            },
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.flight_takeoff,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 80,
                          child: Text(
                            airline,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0097A7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    const Spacer(),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE0E0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        formatPrice(price),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            from,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00838F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatDateTime(departure),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F7FA),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: Color(0xFF00BCD4),
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 2,
                            width: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            to,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00838F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatDateTime(arrival),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(Icons.event_seat, availability, const Color(0xFF00838F)),
                      Container(width: 1, height: 20, color: const Color(0xFF00BCD4)),
                      _buildInfoItem(Icons.luggage, baggage, const Color(0xFF00838F)),
                      Container(width: 1, height: 20, color: const Color(0xFF00BCD4)),
                      _buildInfoItem(Icons.business_center, cabinClass, const Color(0xFF00838F)),
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

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}