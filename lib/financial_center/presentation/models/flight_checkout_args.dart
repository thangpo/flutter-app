import 'flight_itinerary.dart';
import 'flight_data_models.dart';

class FlightCheckoutArgs {
  final int flightId;
  final String departDateIso;
  final FlightSeat seat;
  final int passengers;
  final String airlineName;
  final String fromCode;
  final String toCode;
  final String departTimeText;
  final String arriveTimeText;
  final String flightCode;
  final double unitPrice;
  final double totalPrice;
  final FlightItinerary itinerary;
  final String? seatClassName;

  const FlightCheckoutArgs({
    required this.flightId,
    required this.departDateIso,
    required this.seat,
    required this.passengers,
    required this.airlineName,
    required this.fromCode,
    required this.toCode,
    required this.departTimeText,
    required this.arriveTimeText,
    required this.flightCode,
    required this.unitPrice,
    required this.totalPrice,
    required this.itinerary,
    this.seatClassName,
  });
}