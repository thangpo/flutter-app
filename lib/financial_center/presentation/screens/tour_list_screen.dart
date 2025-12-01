import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

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

  static const Color oceanBlue = Color(0xFF0077BE);
  static const Color lightOceanBlue = Color(0xFF4DA8DA);

  final List<String> _headerImages = [];
  int _currentHeaderIndex = 0;
  Timer? _headerTimer;

  @override
  void initState() {
    super.initState();
    _loadTours();
  }

  @override
  void dispose() {
    _headerTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTours({
    String? title,
    int? locationId,
    String? startDate,
    String? endDate,
  }) async {
    setState(() => isLoading = true);
    try {
      List<dynamic> data;
      if ((title == null || title.isEmpty) &&
          locationId == null &&
          startDate == null &&
          endDate == null) {
        data = await TourService.fetchTours();
      } else {
        data = await TourService.searchTours(
          title: title,
          locationId: locationId,
        );
      }

      setState(() => tours = data);
      _prepareHeaderImages();
    } catch (e) {
      debugPrint("❌ Lỗi tải tour: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _prepareHeaderImages() {
    _headerImages.clear();
    for (final t in tours.take(5)) {
      if (t is Map) {
        final url = (t['image'] ??
            t['banner'] ??
            t['image_url'] ??
            t['thumbnail']) as String?;
        if (url != null && url.isNotEmpty) _headerImages.add(url);
      }
    }
    if (_headerImages.isEmpty) {
      _headerTimer?.cancel();
      _currentHeaderIndex = 0;
    } else {
      _startHeaderTimer();
    }
  }

  void _startHeaderTimer() {
    _headerTimer?.cancel();
    _headerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _headerImages.isEmpty) return;
      setState(() {
        _currentHeaderIndex =
            (_currentHeaderIndex + 1) % _headerImages.length;
      });
    });
  }

  String? _getCurrentHeaderImage() {
    if (_headerImages.isEmpty) return null;
    return _headerImages[_currentHeaderIndex];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleText =
        getTranslated('explore_tours', context) ?? 'Khám phá Tour';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? const Color(0xFF050816) : Colors.grey[100],
      appBar: AppBar(
        title: Text(
          titleText,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        color: oceanBlue,
        onRefresh: () => _loadTours(),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeaderSection(context),
            Transform.translate(
              offset: const Offset(0, -200),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TourFilterBar(
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
                      startDate: startDate,
                      endDate: endDate,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: isLoading
                  ? const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
                  : (tours.isNotEmpty
                  ? Column(
                children: [
                  ...tours.map((tour) => TourCard(tour: tour)),
                ],
              )
                  : Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(
                    Icons.search_off_rounded,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    getTranslated('no_tour_found', context) ??
                        "Không tìm thấy tour nào",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              )),
            ),

            const SizedBox(height: 24),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ArticleListWidget(),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerImage = _getCurrentHeaderImage();

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
              child: headerImage != null && headerImage.isNotEmpty
                  ? Image.network(
                headerImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildHeaderFallbackBg(isDark),
              )
                  : _buildHeaderFallbackBg(isDark),
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.20),
                    Colors.black.withOpacity(0.55),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderFallbackBg(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF020617)]
              : [oceanBlue, lightOceanBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}
