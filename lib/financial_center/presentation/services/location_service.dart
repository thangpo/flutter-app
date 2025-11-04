import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      slug: json['slug'] ?? '',
      imageUrl: json['image_url'] ?? '',
      toursCount: json['tours_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'image_url': imageUrl,
      'tours_count': toursCount,
    };
  }
}

class LocationService {
  LocationService._privateConstructor();
  static final LocationService _instance = LocationService._privateConstructor();
  factory LocationService() => _instance;

  static const String _apiUrl = "https://vietnamtoure.com/api/locations";
  static const String _cacheKey = 'cached_locations';
  static const String _cacheTimestampKey = 'cached_locations_timestamp';
  static const Duration _cacheDuration = Duration(days: 1);

  static Future<List<LocationModel>> fetchLocations({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      final cachedData = prefs.getString(_cacheKey);
      final timestamp = prefs.getInt(_cacheTimestampKey);

      if (cachedData != null && timestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (cacheAge < _cacheDuration.inMilliseconds) {
          try {
            final List<dynamic> jsonList = jsonDecode(cachedData);
            return jsonList.map((e) => LocationModel.fromJson(e)).toList();
          } catch (e) {
            //debugPrint('Lỗi parse cache: $e');
          }
        }
      }
    }

    try {
      final response = await http.get(Uri.parse(_apiUrl)).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception("Timeout khi tải dữ liệu"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == true) {
          final List<dynamic> list = data['data'];
          final locations = list.map((json) => LocationModel.fromJson(json)).toList();

          await prefs.setString(_cacheKey, jsonEncode(locations.map((e) => e.toJson()).toList()));
          await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);

          return locations;
        } else {
          throw Exception(data['message'] ?? "API trả về lỗi");
        }
      } else {
        throw Exception("Lỗi mạng: ${response.statusCode}");
      }
    } catch (e) {
      final cachedData = prefs.getString(_cacheKey);
      if (cachedData != null) {
        try {
          final List<dynamic> jsonList = jsonDecode(cachedData);
          return jsonList.map((e) => LocationModel.fromJson(e)).toList();
        } catch (_) {}
      }
      rethrow;
    }
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimestampKey);
  }
}