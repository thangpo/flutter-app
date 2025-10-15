import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/location_service.dart';

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

  List<Map<String, dynamic>> locations = [];
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
      setState(() => locations = data);
    } catch (e) {
      debugPrint('Lỗi khi tải danh sách địa chỉ: $e');
    } finally {
      setState(() => isLoadingLocations = false);
    }
  }

  void _selectDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDateRange: selectedRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: oceanBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
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

    widget.onFilter(
      title: title,
      locationId: locationId,
    );
  }

  void _resetFilter() {
    setState(() {
      titleController.clear();
      selectedRange = null;
      selectedLocationId = null;
    });
    widget.onFilter(title: null, locationId: null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [lightBg, Colors.white],
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Tên tour',
                labelStyle: TextStyle(color: oceanBlue.withOpacity(0.8)),
                prefixIcon: const Icon(Icons.tour, color: oceanBlue),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: lightOceanBlue.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: lightOceanBlue.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: oceanBlue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: lightOceanBlue.withOpacity(0.3)),
              ),
              child: DropdownButtonFormField<int?>(
                initialValue: selectedLocationId,
                decoration: InputDecoration(
                  labelText: 'Chọn địa chỉ',
                  labelStyle: TextStyle(color: oceanBlue.withOpacity(0.8)),
                  prefixIcon: const Icon(Icons.location_on, color: oceanTeal),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                dropdownColor: Colors.white,
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Tất cả địa chỉ'),
                  ),
                  ...locations.map((loc) {
                    return DropdownMenuItem<int?>(
                      value: loc['id'] as int?,
                      child: Text(loc['name'] ?? ''),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => selectedLocationId = value);
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: lightOceanBlue.withOpacity(0.3)),
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
                              ? 'Chọn khoảng thời gian'
                              : '${DateFormat('dd/MM/yyyy').format(selectedRange!.start)} - ${DateFormat('dd/MM/yyyy').format(selectedRange!.end)}',
                          style: TextStyle(
                            fontSize: 15,
                            color: selectedRange == null
                                ? oceanBlue.withOpacity(0.6)
                                : deepOceanBlue,
                            fontWeight: selectedRange == null
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: oceanBlue.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                          color: oceanBlue.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _applyFilter,
                      icon: const Icon(Icons.search_rounded, size: 22),
                      label: const Text(
                        'Tìm kiếm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(double.infinity, 54),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: lightOceanBlue.withOpacity(0.5), width: 2),
                  ),
                  child: IconButton(
                    onPressed: _resetFilter,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Xóa lọc',
                    color: oceanBlue,
                    iconSize: 26,
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