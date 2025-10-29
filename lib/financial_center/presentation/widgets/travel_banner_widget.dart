import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/services/tour_service.dart';

class TravelBannerWidget extends StatefulWidget {
  const TravelBannerWidget({super.key});

  @override
  State<TravelBannerWidget> createState() => _TravelBannerWidgetState();
}

class _TravelBannerWidgetState extends State<TravelBannerWidget> {
  List<dynamic> tours = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTours();
  }

  Future<void> _loadTours() async {
    try {
      final data = await TourService.fetchTours();
      setState(() {
        tours = data.take(5).toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Lỗi khi tải tour: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tours.isEmpty) {
      return const Center(child: Text('Không có tour nào để hiển thị'));
    }

    return CarouselSlider.builder(
      itemCount: tours.length,
      itemBuilder: (context, index, realIndex) {
        final tour = tours[index];
        final imageUrl = tour['banner_image_url'];
        final title = tour['title'] ?? 'Tour du lịch';

        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),

            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(blurRadius: 5, color: Colors.black54),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      options: CarouselOptions(
        height: 180,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.9,
        autoPlayInterval: const Duration(seconds: 4),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
      ),
    );
  }
}
