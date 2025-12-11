import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

class TourSuggestionSliderPro extends StatefulWidget {
  final List<Map<String, dynamic>> originalTours;
  final Function(Map<String, dynamic>) onSelect;

  const TourSuggestionSliderPro({
    super.key,
    required this.originalTours,
    required this.onSelect,
  });

  @override
  State<TourSuggestionSliderPro> createState() =>
      _TourSuggestionSliderProState();
}

class _TourSuggestionSliderProState extends State<TourSuggestionSliderPro> {
  late List<Map<String, dynamic>> tours;
  int version = 0; // trigger AnimatedSwitcher

  @override
  void initState() {
    super.initState();
    tours = List.from(widget.originalTours);
  }

  void _selectTour(Map<String, dynamic> tour) {
    widget.onSelect(tour);

    setState(() {
      tours.remove(tour);

      final i = widget.originalTours.indexOf(tour);
      final nextTour =
      widget.originalTours[(i + 1) % widget.originalTours.length];

      if (!tours.contains(nextTour)) {
        tours.add(nextTour);
      }

      version++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeController>(context, listen: true).darkTheme;

    return SizedBox(
      height: 170,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeInBack,
        child: ListView.builder(
          key: ValueKey(version),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: tours.length,
          itemBuilder: (_, index) {
            final tour = tours[index];
            return GestureDetector(
              onTap: () => _selectTour(tour),
              child: _buildCard(tour, isDark),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> tour, bool isDark) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            /// Hình ảnh
            Positioned.fill(
              child: Image.network(
                tour['image'] ?? "",
                fit: BoxFit.cover,
              ),
            ),

            /// Overlay tùy vào dark mode
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: isDark
                        ? [
                      Colors.black.withOpacity(0.75),
                      Colors.transparent,
                    ]
                        : [
                      Colors.black.withOpacity(0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            /// Title
            Positioned(
              left: 12,
              bottom: 12,
              right: 12,
              child: Text(
                tour['title'] ?? getTranslated('tour_no_name', context) ?? "Tour",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black.withOpacity(isDark ? 0.9 : 0.6),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}