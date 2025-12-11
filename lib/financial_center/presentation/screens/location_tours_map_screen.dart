import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../widgets/tour_suggestion_slider_pro.dart';
import '../widgets/tour_expanded_card.dart';

// THEME + I18N
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

class LocationToursMapScreen extends StatefulWidget {
  final String locationName;
  final String imageUrl;
  final double centerLat;
  final double centerLng;
  final double mapZoom;
  final List<Map<String, dynamic>> tours;

  const LocationToursMapScreen({
    super.key,
    required this.locationName,
    required this.imageUrl,
    required this.centerLat,
    required this.centerLng,
    required this.mapZoom,
    required this.tours,
  });

  @override
  State<LocationToursMapScreen> createState() =>
      _LocationToursMapScreenState();
}

class _LocationToursMapScreenState extends State<LocationToursMapScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? selectedTour;

  late final MapController mapController = MapController();

  bool searchActive = false;
  String searchText = "";
  late List<Map<String, dynamic>> filteredTours;

  late final TextEditingController searchController;
  late final FocusNode searchFocusNode;

  late final AnimationController popupController;
  late final Animation<double> popupScale;
  late final Animation<double> popupOpacity;

  @override
  void initState() {
    super.initState();

    filteredTours = List.from(widget.tours);

    searchController = TextEditingController();
    searchFocusNode = FocusNode();

    popupController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    popupScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: popupController, curve: Curves.easeOutBack),
    );

    popupOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: popupController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    popupController.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  // SEARCH LOGIC
  void _onSearchChanged(String value) {
    setState(() {
      searchText = value;

      if (value.isEmpty) {
        filteredTours = List.from(widget.tours);
      } else {
        filteredTours = widget.tours
            .where((t) =>
            t['title'].toString().toLowerCase().contains(value.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // DARK MODE from ThemeController
    final bool isDark =
        Provider.of<ThemeController>(context, listen: true).darkTheme;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Stack(
        children: [
          _buildMap(isDark),

          /// BACK BUTTON
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: _circleButton(Icons.arrow_back, () {
              Navigator.pop(context);
            }, isDark),
          ),

          /// SEARCH BUTTON
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: _circleButton(Icons.search, () {
              setState(() {
                searchActive = !searchActive;
                searchText = "";
                searchController.clear();
                filteredTours = List.from(widget.tours);
              });

              if (searchActive) {
                Future.delayed(const Duration(milliseconds: 150), () {
                  searchFocusNode.requestFocus();
                });
              } else {
                searchFocusNode.unfocus();
              }
            }, isDark),
          ),

          /// SEARCH BAR
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: searchActive
                ? MediaQuery.of(context).padding.top + 60
                : -100,
            left: 16,
            right: 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: searchActive ? 1 : 0,
              child: _buildSearchBar(isDark),
            ),
          ),

          /// SEARCH SUGGESTIONS
          if (searchActive && searchText.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 120,
              left: 16,
              right: 16,
              child: _buildSearchSuggestions(isDark),
            ),

          /// SLIDER
          if (!searchActive)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: TourSuggestionSliderPro(
                originalTours: filteredTours,
                onSelect: (tour) async {
                  popupController.reset();
                  setState(() => selectedTour = tour);

                  await Future.delayed(const Duration(milliseconds: 120));

                  mapController.move(
                    LatLng(tour['lat'], tour['lng']),
                    16,
                  );

                  popupController.forward();
                },
              ),
            ),

          /// POPUP
          if (selectedTour != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedBuilder(
                animation: popupController,
                builder: (_, child) {
                  return Transform.scale(
                    scale: popupScale.value,
                    child: Opacity(opacity: popupOpacity.value, child: child),
                  );
                },
                child: TourExpandedCard(
                  tour: selectedTour!,
                  onClose: () {
                    popupController.reverse();
                    Future.delayed(const Duration(milliseconds: 280), () {
                      setState(() => selectedTour = null);
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// SEARCH BAR
  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: TextField(
        controller: searchController,
        focusNode: searchFocusNode,
        autofocus: false,
        onChanged: _onSearchChanged,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: getTranslated("search_tour", context) ?? "Tìm kiếm tour...",
          hintStyle: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ),
    );
  }

  /// SEARCH SUGGESTIONS LIST
  Widget _buildSearchSuggestions(bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: filteredTours
            .map((t) => ListTile(
          title: Text(
            t['title'],
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          onTap: () {
            searchFocusNode.unfocus();
            setState(() {
              searchActive = false;
              selectedTour = t;
            });

            mapController.move(LatLng(t['lat'], t['lng']), 16);
            popupController.forward();
          },
        ))
            .toList(),
      ),
    );
  }

  /// CIRCLE BUTTON
  Widget _circleButton(IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  /// MAP + MARKERS
  Widget _buildMap(bool isDark) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: LatLng(widget.centerLat, widget.centerLng),
        initialZoom: widget.mapZoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: isDark
              ? 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
              : 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.vnshop.vietnamtoure',
        ),

        MarkerLayer(
          markers: filteredTours.map((tour) {
            final isSelected =
                selectedTour != null && selectedTour!['id'] == tour['id'];

            return Marker(
              point: LatLng(tour['lat'], tour['lng']),
              width: isSelected ? 120 : 90,
              height: isSelected ? 120 : 90,
              child: GestureDetector(
                onTap: () {
                  popupController.reset();
                  setState(() => selectedTour = tour);
                  popupController.forward();
                },
                child: _buildMarker(tour, isSelected, isDark), // ✅ FIXED
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// MARKER
  Widget _buildMarker(Map<String, dynamic> tour, bool active, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
          ),
          child: Text(
            tour['title'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: active ? 60 : 48,
          height: active ? 60 : 48,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(tour['image'], fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }
}