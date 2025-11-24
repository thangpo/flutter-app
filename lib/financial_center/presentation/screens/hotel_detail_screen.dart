import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../services/hotel_service.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

import '../widgets/hotel_detail_app_bar.dart';
import '../widgets/hotel_detail_body.dart';
import '../widgets/hotel_book_button.dart';

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
      floatingActionButton: const HotelBookButton(),
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
                Container(
                  width: 250,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 180,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
              child: Text(
                error,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
        HotelDetailAppBar(
          hotel: hotel,
          currentImageIndex: _currentImageIndex,
          onImageIndexChanged: (index) {
            setState(() => _currentImageIndex = index);
          },
        ),
        SliverToBoxAdapter(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final curvedValue =
              Curves.easeOutCubic.transform(_animationController.value);
              return Opacity(
                opacity: curvedValue,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - curvedValue)),
                  child: HotelDetailBody(hotel: hotel),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}