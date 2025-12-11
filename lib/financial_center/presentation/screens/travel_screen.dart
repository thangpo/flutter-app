import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/menu_widget.dart';
import '../widgets/travel_menu_widget.dart';
import '../widgets/travel_banner_widget.dart';
import '../widgets/travel_map_widget.dart';
import '../widgets/hotel_list_widget.dart';
import '../widgets/location_list_widget.dart';
import '../widgets/tour_list_widget.dart';
import '../widgets/flights_list_widget.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

class TravelScreen extends StatefulWidget {
  final Function(bool)? onScrollToggleNav;
  final bool isBackButtonExist;

  const TravelScreen({
    Key? key,
    this.isBackButtonExist = true,
    this.onScrollToggleNav,
  }) : super(key: key);

  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen> {
  final ScrollController _scrollController = ScrollController();
  double lastOffset = 0;
  bool navVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final offset = _scrollController.offset;

    if (offset > lastOffset + 25 && navVisible) {
      navVisible = false;
      widget.onScrollToggleNav?.call(false);
    } else if (offset < lastOffset - 25 && !navVisible) {
      navVisible = true;
      widget.onScrollToggleNav?.call(true);
    }

    lastOffset = offset;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildFrostedAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 20),
                TravelMenuWidget(),
                SizedBox(height: 26),
                TravelBannerWidget(),
                SizedBox(height: 24),
                TravelMapWidget(),
                SizedBox(height: 24),
                HotelListWidget(),
                SizedBox(height: 30),
                LocationListWidget(),
                SizedBox(height: 25),
                TourListWidget(),
                SizedBox(height: 24),
                FlightListWidget(),
                SizedBox(height: 26),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrostedAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: widget.isBackButtonExist,
      leading: widget.isBackButtonExist
          ? IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: isDark ? Colors.white : Colors.black87,
        ),
        onPressed: () => Navigator.pop(context),
      )
          : null,

      expandedHeight: 70,
      collapsedHeight: 70,

      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withOpacity(0.45)
              : Colors.white.withOpacity(0.85),

          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.25)
                  : Colors.grey.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  Images.logoWithNameImage,
                  height: 46,
                  fit: BoxFit.contain,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: MenuWidget(),
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