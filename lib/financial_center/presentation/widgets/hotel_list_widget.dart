import 'package:flutter/material.dart';
import '../services/hotel_service.dart';

class HotelListWidget extends StatefulWidget {
  const HotelListWidget({super.key});

  @override
  State<HotelListWidget> createState() => _HotelListWidgetState();
}

class _HotelListWidgetState extends State<HotelListWidget> {
  final HotelService _hotelService = HotelService();
  bool _isLoading = true;
  List<dynamic> _hotels = [];

  @override
  void initState() {
    super.initState();
    _loadHotels();
  }

  Future<void> _loadHotels() async {
    try {
      final hotels = await _hotelService.fetchHotels(limit: 10);
      setState(() {
        _hotels = hotels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading hotels: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hotels.isEmpty) {
      return const Center(child: Text('Không có khách sạn nào.'));
    }

    return ListView.builder(
      itemCount: _hotels.length,
      itemBuilder: (context, index) {
        final hotel = _hotels[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                hotel['thumbnail'] ?? '',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.hotel, size: 40),
              ),
            ),
            title: Text(
              hotel['title'] ?? 'No title',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              hotel['location'] ?? '',
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: Text(
              "${hotel['price'] ?? ''} ₫",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/hotel-detail',
                arguments: hotel['slug'],
              );
            },
          ),
        );
      },
    );
  }
}
