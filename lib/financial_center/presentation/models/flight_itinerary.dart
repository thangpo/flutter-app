import 'package:latlong2/latlong.dart' as ll;

class FlightItinerary {
  final String airlineName;
  final String flightCode;
  final String fromCode;
  final String toCode;
  final String departTimeText;
  final String arriveTimeText;
  final DateTime? departureAt;
  final ll.LatLng fromLatLng;
  final ll.LatLng toLatLng;
  final String? flightImage;

  const FlightItinerary({
    required this.airlineName,
    required this.flightCode,
    required this.fromCode,
    required this.toCode,
    required this.departTimeText,
    required this.arriveTimeText,
    required this.departureAt,
    required this.fromLatLng,
    required this.toLatLng,
    this.flightImage,
  });
}