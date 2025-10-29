import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/hotel_service.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

class HotelDetailScreen extends StatefulWidget {
  final String slug;

  const HotelDetailScreen({super.key, required this.slug});

  @override
  State<HotelDetailScreen> createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends State<HotelDetailScreen>
    with TickerProviderStateMixin {
  final HotelService _hotelService = HotelService();
  late Future<Map<String, dynamic>> _hotelFuture;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _refreshHotel();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshHotel() async {
    setState(() {
      _hotelFuture = _hotelService.fetchHotelDetail(widget.slug);
    });
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshHotel,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _hotelFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmer();
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return _buildError(snapshot.error?.toString());
            }

            final hotel = snapshot.data!;
            return _buildContent(hotel, isDark);
          },
        ),
      ),
      floatingActionButton: _buildBookButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        children: [
          Container(height: 300, color: Colors.white),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                _ShimmerLine(width: 200, height: 24),
                SizedBox(height: 8),
                _ShimmerLine(width: 150, height: 16),
                SizedBox(height: 16),
                _ShimmerLine(width: double.infinity, height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 80, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            getTranslated("error", context) ?? "Lỗi tải dữ liệu",
            style: const TextStyle(fontSize: 18),
          ),
          if (error != null) Text(error, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshHotel,
            icon: const Icon(Icons.refresh),
            label: const Text("Thử lại"),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> hotel, bool isDark) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              hotel['title'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            background: _buildImageCarousel(hotel['gallery']),
          ),
        ),
        SliverToBoxAdapter(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _animationController.value,
                child: Transform.translate(
                  offset: Offset(0, 50 * (1 - _animationController.value)),
                  child: _buildHotelInfo(hotel, isDark),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageCarousel(List<dynamic>? gallery) {
    if (gallery == null || gallery.isEmpty) {
      return Image.network(
        'https://via.placeholder.com/600',
        fit: BoxFit.cover,
      );
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 300,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 1.0,
      ),
      items: gallery.map<Widget>((img) {
        return Image.network(
          img['large'] ?? img['thumb'] ?? '',
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
        );
      }).toList(),
    );
  }

  Widget _buildHotelInfo(Map<String, dynamic> hotel, bool isDark) {
    final score = double.tryParse(hotel['review_score']?.toString() ?? '0') ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề + sao
          Row(
            children: [
              Expanded(
                child: Text(
                  hotel['title'] ?? '',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              _buildStarRating(score),
              const SizedBox(width: 8),
              Text(
                score.toStringAsFixed(1),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(child: Text(hotel['location'] ?? '', style: const TextStyle(color: Colors.grey))),
            ],
          ),
          const SizedBox(height: 16),

          // Giá
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.blue, Colors.purple]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${hotel['price']} ₫",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: 24),

          // Mô tả
          const Text("Mô tả", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Html(
            data: hotel['content'] ?? '',
            style: {
              "p": Style(fontSize: FontSize(15), lineHeight: LineHeight(1.6)),
              "strong": Style(fontWeight: FontWeight.bold),
            },
          ),
          const SizedBox(height: 24),

          // Địa chỉ
          _buildInfoCard(
            icon: Icons.location_city,
            title: "Địa chỉ",
            content: hotel['address'] ?? '',
          ),
          const SizedBox(height: 16),

          // Bản đồ
          _buildMapPreview(hotel['map_lat'], hotel['map_lng']),
          const SizedBox(height: 24),

          // Tiện ích
          if (hotel['attributes'] != null)
            ...hotel['attributes'].map<Widget>((attr) => _buildAttributeSection(attr)).toList()
        ],
      ),
    );
  }

  Widget _buildStarRating(double score) {
    const maxStars = 5;
    final rounded = (score * 2).round() / 2;
    return Row(
      children: List.generate(maxStars, (i) {
        if (i < rounded) {
          return const Icon(Icons.star, size: 20, color: Colors.amber);
        } else if (i - 0.5 <= rounded) {
          return const Icon(Icons.star_half, size: 20, color: Colors.amber);
        } else {
          return const Icon(Icons.star_border, size: 20, color: Colors.amber);
        }
      }),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String content}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(content, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPreview(String? lat, String? lng) {
    if (lat == null || lng == null) return const SizedBox();
    final url = 'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=15&size=600x300&markers=color:red%7C$lat,$lng&key=YOUR_API_KEY';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Vị trí trên bản đồ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => launchUrl(Uri.parse('https://maps.google.com/?q=$lat,$lng')),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url.replaceAll('YOUR_API_KEY', ''), // Thay bằng key thật nếu có
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.map, size: 50)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttributeSection(Map<String, dynamic> attr) {
    final terms = attr['terms'] as List<dynamic>? ?? [];
    if (terms.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(attr['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: terms.map((term) {
            final name = term['translation']?['name'] ?? term['name'] ?? '';
            final icon = term['icon'] ?? 'icofont-check-circled';
            return Chip(
              avatar: const Icon(Icons.check, size: 16),
              label: Text(name),
              backgroundColor: Colors.blue.withOpacity(0.1),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBookButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // TODO: Navigate to booking screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Chức năng đặt phòng đang phát triển...")),
          );
        },
        icon: const Icon(Icons.calendar_today),
        label: const Text("Đặt ngay", style: TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 8,
        ),
      ),
    );
  }
}

class _ShimmerLine extends StatelessWidget {
  final double width;
  final double height;

  const _ShimmerLine({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(width: width, height: height, color: Colors.white);
  }
}