class AirportLocation {
  final int id;
  final String? name;
  final String? slug;
  final double? mapLat;
  final double? mapLng;
  final int? mapZoom;
  final int? imageId;

  const AirportLocation({
    required this.id,
    this.name,
    this.slug,
    this.mapLat,
    this.mapLng,
    this.mapZoom,
    this.imageId,
  });

  factory AirportLocation.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return AirportLocation(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString(),
      slug: json['slug']?.toString(),
      imageId: (json['image_id'] is num) ? (json['image_id'] as num).toInt() : null,
      mapLat: _toDouble(json['map_lat']),
      mapLng: _toDouble(json['map_lng']),
      mapZoom: (json['map_zoom'] is num) ? (json['map_zoom'] as num).toInt() : null,
    );
  }
}

class AirportItem {
  final int id;
  final String name;
  final String code;
  final String? address;
  final String? country;
  final int? locationId;
  final AirportLocation? location;

  const AirportItem({
    required this.id,
    required this.name,
    required this.code,
    this.address,
    this.country,
    this.locationId,
    this.location,
  });

  String get displayTitle => '$name ($code)';
  String get displaySubtitle {
    final locName = location?.name?.trim();
    final addr = address?.trim();
    if ((locName ?? '').isNotEmpty && (addr ?? '').isNotEmpty) return '$locName • $addr';
    if ((locName ?? '').isNotEmpty) return locName!;
    if ((addr ?? '').isNotEmpty) return addr!;
    return '';
  }

  factory AirportItem.fromJson(Map<String, dynamic> json) {
    return AirportItem(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      address: json['address']?.toString(),
      country: json['country']?.toString(),
      locationId: (json['location_id'] is num) ? (json['location_id'] as num).toInt() : null,
      location: (json['location'] is Map<String, dynamic>)
          ? AirportLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
    );
  }
}