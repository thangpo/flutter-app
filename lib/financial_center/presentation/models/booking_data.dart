class BookingData {
  final int tourId;
  final String tourName;
  final String tourImage;
  final DateTime startDate;
  final Map<String, int> personCounts;
  final Map<String, bool> extras;
  final double total;
  final int numberOfPeople; // 👈 Thêm dòng này

  BookingData({
    required this.tourId,
    required this.tourName,
    required this.tourImage,
    required this.startDate,
    required this.personCounts,
    required this.extras,
    required this.total,
    required this.numberOfPeople, // 👈 Thêm dòng này
  });

  factory BookingData.fromJson(Map<String, dynamic> json) {
    return BookingData(
      tourId: json['tour_id'],
      tourName: json['tour_name'] ?? '',
      tourImage: json['tour_image'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      personCounts: Map<String, int>.from(json['person_counts'] ?? {}),
      extras: Map<String, bool>.from(json['extras'] ?? {}),
      total: (json['total'] ?? 0).toDouble(),
      numberOfPeople: json['number_of_people'] ?? 1, // 👈 Thêm dòng này
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tour_id': tourId,
      'tour_name': tourName,
      'tour_image': tourImage,
      'start_date': startDate.toIso8601String(),
      'person_counts': personCounts,
      'extras': extras,
      'total': total,
      'number_of_people': numberOfPeople, // 👈 Thêm dòng này
    };
  }
}
