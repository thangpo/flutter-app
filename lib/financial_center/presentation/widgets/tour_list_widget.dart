import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/services/tour_service.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import '../screens/tour_detail_screen.dart';


class TourListWidget extends StatefulWidget {
  final int? locationId;
  const TourListWidget({super.key, this.locationId});

  @override
  State<TourListWidget> createState() => _TourListWidgetState();
}

class _TourListWidgetState extends State<TourListWidget> {
  bool _isLoading = true;
  List<dynamic> _tours = [];
  final Map<int, int> _imageIndexes = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadTours();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTours() async {
    try {
      List<dynamic> data;
      if (widget.locationId != null) {
        data = await TourService.fetchToursByLocation(widget.locationId!);
      } else {
        data = await TourService.fetchTours();
      }

      setState(() {
        _tours = data;
        _isLoading = false;
      });

      _startImageRotation();
    } catch (e) {
      debugPrint('Lỗi tải tour: $e');
      setState(() => _isLoading = false);
    }
  }

  void _startImageRotation() {
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      setState(() {
        for (var i = 0; i < _tours.length; i++) {
          final gallery = List<String>.from(_tours[i]['gallery_urls'] ?? []);
          if (gallery.isNotEmpty) {
            final current = _imageIndexes[i] ?? 0;
            _imageIndexes[i] = (current + 1) % gallery.length;
          }
        }
      });
    });
  }

  String formatCurrency(String? priceString) {
    if (priceString == null) return '—';
    try {
      final double price = double.parse(priceString);
      final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
      return format.format(price);
    } catch (_) {
      return '${priceString}₫';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tours.isEmpty) {
      return Center(
        child: Text(getTranslated('no_tours_found', context) ?? 'Không có tour nào.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            getTranslated('recommended_tours', context) ?? 'Tour đề xuất',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.builder(
          itemCount: _tours.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final tour = _tours[index];
            final gallery = List<String>.from(tour['gallery_urls'] ?? []);
            final imageUrl = gallery.isNotEmpty
                ? gallery[_imageIndexes[index] ?? 0]
                : (tour['image_url'] ?? '');
            final title = tour['title'] ?? 'Tour';
            final location = tour['location'] ?? '';
            final price = formatCurrency(tour['price']);

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TourDetailScreen(tourId: tour['id']),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 800),
                        child: Image.network(
                          imageUrl,
                          key: ValueKey(imageUrl),
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 120,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported, size: 40),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              price,
                              style: TextStyle(
                                fontSize: 15,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}