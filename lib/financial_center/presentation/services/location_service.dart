import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationModel {
  final int id;
  final String name;
  final String slug;
  final String imageUrl;
  final int toursCount;

  LocationModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.imageUrl,
    required this.toursCount,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'],
      name: json['name'],
      slug: json['slug'] ?? '',
      imageUrl: json['image_url'] ?? '',
      toursCount: json['tours_count'] ?? 0,
    );
  }
}

class LocationService {
  static const String apiUrl = "https://vietnamtoure.com/api/locations";

  static Future<List<LocationModel>> fetchLocations() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == true) {
        List<dynamic> list = data['data'];
        return list.map((json) => LocationModel.fromJson(json)).toList();
      } else {
        throw Exception("API trả về lỗi");
      }
    } else {
      throw Exception("Không thể tải dữ liệu: ${response.statusCode}");
    }
  }
}
