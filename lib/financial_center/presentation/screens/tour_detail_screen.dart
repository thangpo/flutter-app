import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TourDetailScreen extends StatefulWidget {
  final int tourId;
  const TourDetailScreen({super.key, required this.tourId});

  @override
  State<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends State<TourDetailScreen> {
  Map<String, dynamic>? tourData;
  bool isLoading = true;
  static const Color primaryOcean = Color(0xFF0077BE);
  static const Color lightOcean = Color(0xFF4DA6D6);
  static const Color paleOcean = Color(0xFFE3F2FD);

  @override
  void initState() {
    super.initState();
    fetchTourDetail();
  }

  Future<void> fetchTourDetail() async {
    final url = Uri.parse("https://vietnamtoure.com/api/tours/${widget.tourId}");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonRes = json.decode(response.body);
      setState(() {
        tourData = jsonRes['data'];
        isLoading = false;
      });
    }
  }

  void _bookTour() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đặt tour'),
        content: const Text('Chức năng đặt tour sẽ được thực hiện tại đây'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: paleOcean,
        body: Center(
          child: CircularProgressIndicator(color: primaryOcean),
        ),
      );
    }

    final tour = tourData!;
    final gallery = List<String>.from(tour['gallery_urls'] ?? []);
    final bookingData = tour['booking_data'] ?? {};
    final reviews = tour['review_list']?['data'] ?? [];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryOcean,
        foregroundColor: Colors.white,
        title: Text(
          tour['title'] ?? "Chi tiết tour",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Image.network(
                      tour['banner_image_url'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 250,
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryOcean.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tour['title'],
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryOcean,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(Icons.location_on, "Địa điểm", tour['location']),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.access_time, "Thời lượng", "${tour['duration']} ngày"),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.payments, "Giá", "${tour['price']} VND"),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: paleOcean,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description, color: primaryOcean, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              "Mô tả",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryOcean,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        HtmlWidget(tour['description'] ?? ""),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                if (gallery.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.photo_library, color: primaryOcean, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              "Hình ảnh",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryOcean,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 220,
                          autoPlay: true,
                          enlargeCenterPage: true,
                          viewportFraction: 0.85,
                        ),
                        items: gallery.map((url) {
                          return Builder(
                            builder: (context) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                if (bookingData.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: lightOcean.withOpacity(0.3), width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.people, color: primaryOcean, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                "Giá theo đối tượng",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: primaryOcean,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...List.from(bookingData['person_types'] ?? []).map((p) =>
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: paleOcean,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p['name'],
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          Text(
                                            p['desc'],
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      p['display_price'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primaryOcean,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ),
                          if (bookingData['extra_price'] != null && bookingData['extra_price'].isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(Icons.add_circle_outline, color: primaryOcean, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "Phụ phí",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: primaryOcean,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...List.from(bookingData['extra_price']).map((e) =>
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(e['name']),
                                      Text(
                                        e['price_html'],
                                        style: TextStyle(color: primaryOcean),
                                      ),
                                    ],
                                  ),
                                ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                // Reviews
                if (reviews.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              "Đánh giá",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: primaryOcean,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...reviews.map<Widget>((r) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        r['title'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            r['rate_number'].toString(),
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  r['content'],
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),

                // Khoảng trống cho nút đặt tour
                const SizedBox(height: 100),
              ],
            ),
          ),

          // Nút đặt tour cố định ở dưới
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: _bookTour,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOcean,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.card_travel, size: 24),
                      SizedBox(width: 8),
                      Text(
                        "Đặt Tour Ngay",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: paleOcean,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryOcean, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}