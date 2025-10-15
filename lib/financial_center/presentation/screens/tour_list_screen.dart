import 'package:flutter/material.dart';
import '../services/tour_service.dart';
import '../widgets/tour_card.dart';
import '../widgets/tour_filter_bar.dart';
import '../widgets/article_list_widget.dart';

class TourListScreen extends StatefulWidget {
  const TourListScreen({super.key});

  @override
  State<TourListScreen> createState() => _TourListScreenState();
}

class _TourListScreenState extends State<TourListScreen> {
  List<dynamic> tours = [];
  bool isLoading = false;
  bool isFilterExpanded = true;
  final ScrollController _scrollController = ScrollController();

  static const Color oceanBlue = Color(0xFF0077BE);
  static const Color lightOceanBlue = Color(0xFF4DA8DA);
  static const Color deepOceanBlue = Color(0xFF005A8D);

  @override
  void initState() {
    super.initState();
    _loadTours();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && isFilterExpanded) {
      setState(() => isFilterExpanded = false);
    }
  }

  Future<void> _loadTours({
    String? title,
    int? locationId,
  }) async {
    setState(() => isLoading = true);
    try {
      List<dynamic> data;
      if ((title == null || title.isEmpty) && locationId == null) {
        data = await TourService.fetchTours();
      } else {
        data = await TourService.searchTours(
          title: title,
          locationId: locationId,
        );
      }

      setState(() {
        tours = data;
      });
    } catch (e) {
      debugPrint("❌ Lỗi tải tour: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _toggleFilter() {
    setState(() {
      isFilterExpanded = !isFilterExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Khám phá Tour",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: oceanBlue,
        elevation: 0,
      ),
      body: Column(
        children: [
          GestureDetector(
            onTap: _toggleFilter,
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, const Color(0xFFE8F4F8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: oceanBlue.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [oceanBlue, lightOceanBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.filter_list_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Tìm kiếm tour',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: deepOceanBlue,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isFilterExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: oceanBlue,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isFilterExpanded
                ? TourFilterBar(
              onFilter: ({
                String? title,
                String? location,
                int? locationId,
                String? startDate,
                String? endDate,
              }) {
                _loadTours(
                  title: title,
                  locationId: locationId,
                );
              },
            )
                : const SizedBox.shrink(),
          ),

          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: oceanBlue))
                : RefreshIndicator(
              color: oceanBlue,
              onRefresh: () => _loadTours(),
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                children: [
                  if (tours.isNotEmpty)
                    ...tours.map((tour) => TourCard(tour: tour))
                  else
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "Không tìm thấy tour nào",
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  const ArticleListWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}