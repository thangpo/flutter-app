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
  late AnimationController _fabController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _refreshHotel();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabController.dispose();
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _refreshHotel,
        color: Colors.blue[700],
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
            return _buildContent(hotel);
          },
        ),
      ),
      floatingActionButton: _buildBookButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.white,
      child: ListView(
        children: [
          Container(height: 350, color: Colors.white),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 250, height: 28, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 12),
                Container(width: 180, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 20),
                Container(width: double.infinity, height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          ),
          const SizedBox(height: 24),
          Text(
            getTranslated("error", context) ?? "Lỗi tải dữ liệu",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(error, style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshHotel,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Thử lại", style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> hotel) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(hotel),
        SliverToBoxAdapter(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final curvedValue = Curves.easeOutCubic.transform(_animationController.value);
              return Opacity(
                opacity: curvedValue,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - curvedValue)),
                  child: _buildHotelInfo(hotel),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(Map<String, dynamic> hotel) {
    return SliverAppBar(
      expandedHeight: 350,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.favorite_border_rounded, color: Colors.black87),
            onPressed: () {},
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildImageCarousel(hotel['gallery']),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentImageIndex + 1}/${hotel['gallery']?.length ?? 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<dynamic>? gallery) {
    if (gallery == null || gallery.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.hotel, size: 80, color: Colors.grey)),
      );
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 350,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 4),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        enlargeCenterPage: false,
        viewportFraction: 1.0,
        onPageChanged: (index, reason) {
          setState(() => _currentImageIndex = index);
        },
      ),
      items: gallery.map<Widget>((img) {
        return Image.network(
          img['large'] ?? img['thumb'] ?? '',
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image_rounded, size: 50, color: Colors.grey),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHotelInfo(Map<String, dynamic> hotel) {
    final score = double.tryParse(hotel['review_score']?.toString() ?? '0') ?? 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Rating
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        hotel['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue[700],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            score.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Location
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.location_on_rounded, size: 18, color: Colors.blue[700]),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hotel['location'] ?? '',
                        style: TextStyle(color: Colors.grey[700], fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Price Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[700]!, Colors.blue[500]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Giá từ",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${hotel['price']} ₫",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.payments_rounded, color: Colors.white, size: 32),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Description Section
          _buildSection(
            title: "Mô tả",
            icon: Icons.description_rounded,
            child: Html(
              data: hotel['content'] ?? '',
              style: {
                "p": Style(
                  fontSize: FontSize(15),
                  lineHeight: LineHeight(1.7),
                  color: Colors.grey[800],
                ),
                "strong": Style(fontWeight: FontWeight.bold, color: Colors.black87),
              },
            ),
          ),

          // Address Section
          _buildSection(
            title: "Địa chỉ",
            icon: Icons.location_city_rounded,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.pin_drop_rounded, color: Colors.blue[700], size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hotel['address'] ?? '',
                      style: TextStyle(color: Colors.grey[800], fontSize: 15, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Map Preview
          _buildMapPreview(hotel['map_lat'], hotel['map_lng']),

          // Attributes Sections
          if (hotel['attributes'] != null)
            ...hotel['attributes'].map<Widget>((attr) {
              return _buildAttributeSection(attr);
            }).toList(),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: Colors.blue[700]),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildMapPreview(String? lat, String? lng) {
    if (lat == null || lng == null) return const SizedBox();

    return _buildSection(
      title: "Vị trí trên bản đồ",
      icon: Icons.map_rounded,
      child: GestureDetector(
        onTap: () => launchUrl(Uri.parse('https://maps.google.com/?q=$lat,$lng')),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.map_rounded, size: 60, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.blue[700]!.withOpacity(0.95),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.near_me_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Nhấn để xem trên Google Maps',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttributeSection(Map<String, dynamic> attr) {
    final terms = attr['terms'] as List<dynamic>? ?? [];
    if (terms.isEmpty) return const SizedBox();

    IconData sectionIcon = Icons.check_circle_outline_rounded;
    String attrName = attr['name'] ?? '';

    if (attrName.toLowerCase().contains('loại') || attrName.toLowerCase().contains('property')) {
      sectionIcon = Icons.apartment_rounded;
    } else if (attrName.toLowerCase().contains('tiện') || attrName.toLowerCase().contains('facilities')) {
      sectionIcon = Icons.spa_rounded;
    } else if (attrName.toLowerCase().contains('dịch vụ') || attrName.toLowerCase().contains('service')) {
      sectionIcon = Icons.room_service_rounded;
    }

    return _buildSection(
      title: attrName,
      icon: sectionIcon,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: terms.asMap().entries.map((entry) {
          final index = entry.key;
          final term = entry.value;
          final name = term['translation']?['name'] ?? term['name'] ?? '';

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.check_rounded, size: 16, color: Colors.blue[700]),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBookButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(child: Text("Chức năng đặt phòng đang phát triển...")),
                  ],
                ),
                backgroundColor: Colors.blue[700],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_rounded, color: Colors.white, size: 22),
                SizedBox(width: 12),
                Text(
                  "Đặt phòng ngay",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}