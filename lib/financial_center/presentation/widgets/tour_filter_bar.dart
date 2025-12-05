import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../services/location_service.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';


class TourFilterBar extends StatefulWidget {
  final Function({
  String? title,
  String? location,
  int? locationId,
  String? startDate,
  String? endDate,
  }) onFilter;

  const TourFilterBar({super.key, required this.onFilter});

  @override
  State<TourFilterBar> createState() => _TourFilterBarState();
}

class _TourFilterBarState extends State<TourFilterBar> {
  final TextEditingController titleController = TextEditingController();
  DateTimeRange? selectedRange;

  List<LocationModel> _locations = [];
  int? selectedLocationId;
  bool isLoadingLocations = false;

  static const Color oceanBlue = Color(0xFF0077BE);
  static const Color lightOceanBlue = Color(0xFF4DA8DA);
  static const Color deepOceanBlue = Color(0xFF005A8D);
  static const Color oceanTeal = Color(0xFF00A9A5);
  static const Color lightBg = Color(0xFFE8F4F8);

  @override
  void initState() {
    super.initState();
    fetchLocations();
  }

  Future<void> fetchLocations() async {
    setState(() => isLoadingLocations = true);
    try {
      final data = await LocationService.fetchLocations();
      setState(() {
        _locations = data;
      });
    } catch (e) {
      debugPrint('Lỗi khi tải danh sách địa chỉ: $e');
    } finally {
      setState(() => isLoadingLocations = false);
    }
  }

  void _selectDateRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTimeRange initialRange = selectedRange ??
        DateTimeRange(
          start: today,
          end: today.add(const Duration(days: 3)),
        );
    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: DateTime(now.year + 2),
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
              primary: oceanBlue,
              onPrimary: Colors.white,
              surface: Color(0xFF020617),
              onSurface: Colors.white,
            )
                : const ColorScheme.light(
              primary: oceanBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor:
            isDark ? const Color(0xFF020617) : Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      setState(() => selectedRange = range);
    }
  }

  void _applyFilter() {
    final title = titleController.text.trim().isNotEmpty
        ? titleController.text.trim()
        : null;

    final locationId = selectedLocationId;

    String? startDate;
    String? endDate;
    if (selectedRange != null) {
      startDate = DateFormat('yyyy-MM-dd').format(selectedRange!.start);
      endDate = DateFormat('yyyy-MM-dd').format(selectedRange!.end);
    }

    widget.onFilter(
      title: title,
      locationId: locationId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  void _resetFilter() {
    setState(() {
      titleController.clear();
      selectedRange = null;
      selectedLocationId = null;
    });
    widget.onFilter(
      title: null,
      locationId: null,
      startDate: null,
      endDate: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color cardBg = isDark ? const Color(0xFF0B1120) : Colors.white;
    final Color borderColor =
    isDark ? Colors.white12 : lightOceanBlue.withOpacity(0.25);
    final Color labelColor =
    isDark ? Colors.white70 : deepOceanBlue.withOpacity(0.8);

    String tr(String key, String fallback) =>
        getTranslated(key, context) ?? fallback;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('tour_filter_title', 'Tìm tour phù hợp'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : deepOceanBlue,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
              cursorColor: oceanBlue,
              decoration: InputDecoration(
                labelText: tr('tour_name', 'Tên tour'),
                labelStyle: TextStyle(color: labelColor),
                prefixIcon: const Icon(Icons.tour, color: oceanBlue),
                filled: true,
                fillColor: isDark ? const Color(0xFF020617) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                  borderSide: BorderSide(color: oceanBlue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            isLoadingLocations
                ? Container(
              height: 60,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                color: oceanBlue,
              ),
            )
                : Container(
              decoration: BoxDecoration(
                color:
                isDark ? const Color(0xFF020617) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: borderColor),
              ),
              child: DropdownButtonFormField<int?>(
                value: selectedLocationId,
                style: TextStyle(
                  color:
                  isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  labelText: tr('location', 'Địa điểm'),
                  labelStyle: TextStyle(color: labelColor),
                  prefixIcon: const Icon(Icons.location_on,
                      color: oceanTeal),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                dropdownColor: isDark
                    ? const Color(0xFF020617)
                    : Colors.white,
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child:
                    Text(tr('all_locations', 'Tất cả địa điểm')),
                  ),
                  ..._locations.map((loc) {
                    return DropdownMenuItem<int?>(
                      value: loc.id,
                      child: Text(loc.name ?? ''),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => selectedLocationId = value);
                },
              ),
            ),

            const SizedBox(height: 14),

            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF020617) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: borderColor),
              ),
              child: InkWell(
                onTap: _selectDateRange,
                borderRadius: BorderRadius.circular(15),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: lightBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.calendar_today_rounded,
                          color: oceanBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedRange == null
                              ? tr('select_date_range',
                              'Chọn khoảng thời gian')
                              : '${DateFormat('dd/MM/yyyy').format(selectedRange!.start)} - '
                              '${DateFormat('dd/MM/yyyy').format(selectedRange!.end)}',
                          style: TextStyle(
                            fontSize: 15,
                            color: selectedRange == null
                                ? labelColor
                                : (isDark
                                ? Colors.white
                                : deepOceanBlue),
                            fontWeight: selectedRange == null
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: labelColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [oceanBlue, lightOceanBlue],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: oceanBlue.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _applyFilter,
                      icon:
                      const Icon(Icons.search_rounded, size: 22),
                      label: Text(
                        tr('search_tour', 'Tìm tour'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color:
                    isDark ? const Color(0xFF020617) : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: lightOceanBlue.withOpacity(0.6),
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    onPressed: _resetFilter,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: tr('clear_filter', 'Xóa lọc'),
                    color: oceanBlue,
                    iconSize: 24,
                    padding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}