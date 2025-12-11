import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:provider/provider.dart';

import 'tour_booking_card.dart';

class PastBookingScreen extends StatelessWidget {
  final List<dynamic> allBookings;

  const PastBookingScreen({super.key, required this.allBookings});

  String _classifyByDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'unknown';
    try {
      final d = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dateOnly = DateTime(d.year, d.month, d.day);

      if (dateOnly.isBefore(today)) return 'past';
      return 'other';
    } catch (_) {
      return 'unknown';
    }
  }

  List<Map<String, dynamic>> _filterPastByType(String type) {
    final List<Map<String, dynamic>> result = [];

    for (final raw in allBookings) {
      final item = raw as Map<String, dynamic>? ?? {};
      final String serviceType =
      (item['service_type'] ?? item['object_model'] ?? '').toString();

      if (serviceType != type) continue;
      final group = _classifyByDate(item['start_date']?.toString());
      if (group != 'past') continue;

      result.add(item);
    }

    // sắp xếp từ mới nhất -> cũ hơn
    result.sort((a, b) {
      final sa = a['start_date']?.toString();
      final sb = b['start_date']?.toString();
      if (sa == null || sb == null) return 0;
      try {
        final da = DateTime.parse(sa);
        final db = DateTime.parse(sb);
        return db.compareTo(da);
      } catch (_) {
        return 0;
      }
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Provider.of<ThemeController>(context).darkTheme;

    final Color appBarColor =
    isDarkMode ? Colors.black : const Color(0xFF37474F);
    final Color appBarColorEnd =
    isDarkMode ? Colors.black : const Color(0xFF607D8B);

    final Color oceanBlue =
    isDarkMode ? Theme.of(context).primaryColorDark : const Color(0xFF37474F);
    final Color lightOceanBlue =
    isDarkMode ? Theme.of(context).primaryColorLight : const Color(0xFF607D8B);
    final Color paleOceanBlue = isDarkMode
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFECEFF1);

    return DefaultTabController(
      length: 2,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: appBarColor,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: paleOceanBlue,
          appBar: AppBar(
            title: Text(
              getTranslated('past_bookings', context) ?? 'Lịch đã qua',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: isDarkMode
                    ? Theme.of(context).colorScheme.onPrimary
                    : Colors.white,
              ),
            ),
            backgroundColor: appBarColor,
            surfaceTintColor: Colors.transparent,
            foregroundColor: isDarkMode
                ? Theme.of(context).colorScheme.onPrimary
                : Colors.white,
            centerTitle: true,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: appBarColor,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness:
              isDarkMode ? Brightness.dark : Brightness.light,
            ),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [appBarColor, appBarColorEnd],
                ),
              ),
            ),
            bottom: TabBar(
              indicatorColor: Colors.white,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(text: getTranslated('tour_only', context) ?? 'Tour'),
                Tab(text: getTranslated('hotel_only', context) ?? 'Hotel'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildPastList(
                context: context,
                bookings: _filterPastByType('tour'),
                isDarkMode: isDarkMode,
                oceanBlue: oceanBlue,
                lightOceanBlue: lightOceanBlue,
                emptyText:
                getTranslated('no_past_tour', context) ??
                    'Không có tour nào đã qua',
              ),
              _buildPastList(
                context: context,
                bookings: _filterPastByType('hotel'),
                isDarkMode: isDarkMode,
                oceanBlue: oceanBlue,
                lightOceanBlue: lightOceanBlue,
                emptyText:
                getTranslated('no_past_hotel', context) ??
                    'Không có khách sạn nào đã qua',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPastList({
    required BuildContext context,
    required List<Map<String, dynamic>> bookings,
    required bool isDarkMode,
    required Color oceanBlue,
    required Color lightOceanBlue,
    required String emptyText,
  }) {
    if (bookings.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode
                ? Theme.of(context).hintColor
                : Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final item = bookings[index];
        return BookingCard(
          item: item,
          isDarkMode: isDarkMode,
          oceanBlue: oceanBlue,
          lightOceanBlue: lightOceanBlue,
        );
      },
    );
  }
}