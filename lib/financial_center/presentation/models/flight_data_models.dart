class FlightDetailResponse {
  final int status;
  final String message;
  final FlightDetail? flight;

  const FlightDetailResponse({
    required this.status,
    required this.message,
    required this.flight,
  });

  factory FlightDetailResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final flightRaw = (data is Map<String, dynamic>) ? data['flight'] : null;

    return FlightDetailResponse(
      status: (json['status'] as int?) ?? 0,
      message: (json['message'] as String?) ?? '',
      flight: (flightRaw is Map)
          ? FlightDetail.fromJson(Map<String, dynamic>.from(flightRaw))
          : null,
    );
  }
}

class FlightDetail {
  final int id;
  final String title;
  final String code;
  final String? reviewScore;

  final String? departureTime;
  final String? arrivalTime;
  final String? departureTimeIso;
  final String? arrivalTimeIso;

  final String? departureTimeHtml;
  final String? departureDateHtml;
  final String? arrivalTimeHtml;
  final String? arrivalDateHtml;

  final String? duration;
  final String? minPrice;
  final bool? canBook;

  final AirportDetail? airportFrom;
  final AirportDetail? airportTo;

  final AirlineDetail? airline;

  final List<FlightSeat> flightSeat;

  const FlightDetail({
    required this.id,
    required this.title,
    required this.code,
    required this.reviewScore,
    required this.departureTime,
    required this.arrivalTime,
    required this.departureTimeIso,
    required this.arrivalTimeIso,
    required this.departureTimeHtml,
    required this.departureDateHtml,
    required this.arrivalTimeHtml,
    required this.arrivalDateHtml,
    required this.duration,
    required this.minPrice,
    required this.canBook,
    required this.airportFrom,
    required this.airportTo,
    required this.airline,
    required this.flightSeat,
  });

  factory FlightDetail.fromJson(Map<String, dynamic> json) {
    final seatsRaw = json['flight_seat'];

    return FlightDetail(
      id: (json['id'] as int?) ?? 0,
      title: (json['title'] as String?) ?? '',
      code: (json['code'] as String?) ?? '',
      reviewScore: json['review_score']?.toString(),

      departureTime: json['departure_time']?.toString(),
      arrivalTime: json['arrival_time']?.toString(),
      departureTimeIso: json['departure_time_iso']?.toString(),
      arrivalTimeIso: json['arrival_time_iso']?.toString(),

      departureTimeHtml: json['departure_time_html']?.toString(),
      departureDateHtml: json['departure_date_html']?.toString(),
      arrivalTimeHtml: json['arrival_time_html']?.toString(),
      arrivalDateHtml: json['arrival_date_html']?.toString(),

      duration: json['duration']?.toString(),
      minPrice: json['min_price']?.toString(),
      canBook: json['can_book'] as bool?,

      airportFrom: (json['airport_from'] is Map)
          ? AirportDetail.fromJson(Map<String, dynamic>.from(json['airport_from']))
          : null,
      airportTo: (json['airport_to'] is Map)
          ? AirportDetail.fromJson(Map<String, dynamic>.from(json['airport_to']))
          : null,

      airline: (json['airline'] is Map)
          ? AirlineDetail.fromJson(Map<String, dynamic>.from(json['airline']))
          : null,

      flightSeat: (seatsRaw is List)
          ? seatsRaw
          .whereType<Map>()
          .map((e) => FlightSeat.fromJson(Map<String, dynamic>.from(e)))
          .toList()
          : <FlightSeat>[],
    );
  }
}

class AirportDetail {
  final int id;
  final String name;
  final String? code;
  final String? address;

  final String? mapLat;
  final String? mapLng;
  final num? mapZoom;

  const AirportDetail({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    required this.mapLat,
    required this.mapLng,
    required this.mapZoom,
  });

  factory AirportDetail.fromJson(Map<String, dynamic> json) {
    return AirportDetail(
      id: (json['id'] as int?) ?? 0,
      name: (json['name'] as String?) ?? '',
      code: json['code']?.toString(),
      address: json['address']?.toString(),
      mapLat: json['map_lat']?.toString(),
      mapLng: json['map_lng']?.toString(),
      mapZoom: json['map_zoom'] is num ? (json['map_zoom'] as num) : null,
    );
  }
}

class AirlineDetail {
  final int id;
  final String name;
  final String? imageUrl;

  const AirlineDetail({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory AirlineDetail.fromJson(Map<String, dynamic> json) {
    return AirlineDetail(
      id: (json['id'] as int?) ?? 0,
      name: (json['name'] as String?) ?? '',
      imageUrl: json['image_url']?.toString(),
    );
  }
}

class FlightSeat {
  final int id;
  final String? price;
  final int? maxPassengers;
  final int? flightId;

  final SeatType? seatType;

  final String? person;
  final int? baggageCheckIn;
  final int? baggageCabin;

  final String? priceHtml;
  final int? number;

  const FlightSeat({
    required this.id,
    required this.price,
    required this.maxPassengers,
    required this.flightId,
    required this.seatType,
    required this.person,
    required this.baggageCheckIn,
    required this.baggageCabin,
    required this.priceHtml,
    required this.number,
  });

  factory FlightSeat.fromJson(Map<String, dynamic> json) {
    return FlightSeat(
      id: (json['id'] as int?) ?? 0,
      price: json['price']?.toString(),
      maxPassengers: (json['max_passengers'] is int) ? json['max_passengers'] as int : int.tryParse('${json['max_passengers']}'),
      flightId: (json['flight_id'] as int?) ?? int.tryParse('${json['flight_id']}'),
      seatType: (json['seat_type'] is Map)
          ? SeatType.fromJson(Map<String, dynamic>.from(json['seat_type']))
          : null,
      person: json['person']?.toString(),
      baggageCheckIn: (json['baggage_check_in'] as int?) ?? int.tryParse('${json['baggage_check_in']}'),
      baggageCabin: (json['baggage_cabin'] as int?) ?? int.tryParse('${json['baggage_cabin']}'),
      priceHtml: json['price_html']?.toString(),
      number: (json['number'] as int?) ?? int.tryParse('${json['number']}'),
    );
  }
}

class SeatType {
  final int id;
  final String code;
  final String name;

  const SeatType({
    required this.id,
    required this.code,
    required this.name,
  });

  factory SeatType.fromJson(Map<String, dynamic> json) {
    return SeatType(
      id: (json['id'] as int?) ?? 0,
      code: (json['code'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
    );
  }
}