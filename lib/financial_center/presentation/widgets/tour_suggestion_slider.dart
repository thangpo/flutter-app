import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

class TourSuggestionSlider extends StatefulWidget {
  final List<Map<String, dynamic>> tours;
  final Function(Map<String, dynamic>) onSelect;

  const TourSuggestionSlider({
    super.key,
    required this.tours,
    required this.onSelect,
  });

  @override
  State<TourSuggestionSlider> createState() => _TourSuggestionSliderState();
}

class _TourSuggestionSliderState extends State<TourSuggestionSlider> {
  late List<Map<String, dynamic>> list;
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    list = List.from(widget.tours);
  }

  void _removeAndAnimate(int index) {
    final removedItem = list[index];

    listKey.currentState!.removeItem(
      index,
          (context, animation) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeInBack),
          child: FadeTransition(
            opacity: animation,
            child: _buildItem(removedItem),
          ),
        );
      },
      duration: const Duration(milliseconds: 350),
    );

    setState(() {
      list.removeAt(index);
      if (list.isEmpty) {
        list = List.from(widget.tours);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeController>(context, listen: true).darkTheme;

    return SizedBox(
      height: 170,
      child: AnimatedList(
        key: listKey,
        scrollDirection: Axis.horizontal,
        initialItemCount: list.length,
        itemBuilder: (context, index, animation) {
          final tour = list[index];

          return ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            child: GestureDetector(
              onTap: () {
                widget.onSelect(tour);
                _removeAndAnimate(index);
              },
              child: _buildItem(tour, isDark),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> tour, [bool isDark = false]) {
    return Container(
      width: 240,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(tour['image'], fit: BoxFit.cover),
            ),

            /// DARK OVERLAY
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: isDark
                        ? [
                      Colors.black.withOpacity(0.7),
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

            Positioned(
              left: 12,
              bottom: 12,
              right: 12,
              child: Text(
                tour['title'], // tên tour không dịch
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.5),
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