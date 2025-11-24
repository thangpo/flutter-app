import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/hotel_room_service.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

class HotelRoomsSection extends StatefulWidget {
  final int hotelId;
  final List<dynamic> rooms;
  final Map<int, String> roomTermNameMap;

  const HotelRoomsSection({
    super.key,
    required this.hotelId,
    required this.rooms,
    required this.roomTermNameMap,
  });

  @override
  State<HotelRoomsSection> createState() => _HotelRoomsSectionState();
}

class _HotelRoomsSectionState extends State<HotelRoomsSection> {
  late List<dynamic> _rooms;

  DateTime? _startDate;
  DateTime? _endDate;
  int _adults = 2;
  int _children = 0;
  bool _loading = false;

  final Map<int, int> _selectedRooms = {};

  @override
  void initState() {
    super.initState();
    _rooms = List<dynamic>.from(widget.rooms);
    _initSelectedRooms(_rooms);
  }

  void _initSelectedRooms(List<dynamic> rooms) {
    _selectedRooms.clear();
    for (final r in rooms) {
      if (r is Map && r['id'] != null) {
        final int id = int.tryParse(r['id'].toString()) ?? 0;
        if (id > 0) {
          _selectedRooms[id] = 0;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rooms.isEmpty && _rooms.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Provider.of<ThemeController>(context, listen: false);
    final isDark = theme.darkTheme;

    return _buildSection(
      context: context,
      title: getTranslated('room_types', context) ?? 'Các loại phòng',
      icon: Icons.meeting_room_rounded,
      isDark: isDark,
      child: Column(
        children: [
          _buildFilterBar(context, isDark),
          const SizedBox(height: 12),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),

          Column(
            children: _rooms.map((r) {
              final room = r as Map<dynamic, dynamic>;
              final int id = int.tryParse(room['id']?.toString() ?? '0') ?? 0;

              final String name =
              (room['title'] ?? room['name'] ?? '').toString();

              final String priceStr =
              (room['price'] ?? room['min_price'] ?? '').toString();
              final double price =
                  double.tryParse(priceStr.toString()) ?? 0.0;

              final int number = int.tryParse(
                  (room['number'] ?? room['tmp_number'] ?? 0)
                      .toString()) ??
                  0;

              final int beds =
                  int.tryParse((room['beds'] ?? '0').toString()) ?? 0;
              final int size =
                  int.tryParse((room['size'] ?? room['room_size'] ?? '0')
                      .toString()) ??
                      0;
              final int? maxGuests = room['max_guests'] != null
                  ? int.tryParse(room['max_guests'].toString())
                  : null;

              final List<dynamic> gallery =
                  (room['gallery'] as List?) ?? [];

              final dynamic termsRaw = room['terms'];
              final List<dynamic> terms = termsRaw is List
                  ? termsRaw
                  : (termsRaw is Map ? [termsRaw] : []);

              final String thumb = gallery.isNotEmpty
                  ? ((gallery.first is Map
                  ? (gallery.first['large'] ??
                  gallery.first['thumb'] ??
                  '')
                  : gallery.first)
                  .toString())
                  : '';

              final int maxRooms = number > 0 ? number : 0;
              final int selectedRooms = _selectedRooms[id] ?? 0;

              final int nights = (_startDate != null && _endDate != null)
                  ? (_endDate!
                  .difference(_startDate!)
                  .inDays)
                  .clamp(1, 365)
                  : 1;

              return _buildRoomCard(
                context: context,
                isDark: isDark,
                id: id,
                name: name,
                pricePerNight: price,
                number: number,
                beds: beds,
                size: size,
                maxGuests: maxGuests,
                thumb: thumb,
                gallery: gallery,
                terms: terms,
                roomTermNameMap: widget.roomTermNameMap,
                maxRooms: maxRooms,
                selectedRooms: selectedRooms,
                nights: nights,
                onSelectedRoomsChanged: (value) {
                  setState(() {
                    _selectedRooms[id] = value;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, bool isDark) {
    final dateFmt = DateFormat('dd/MM/yyyy');

    String startText =
        getTranslated('check_in', context) ?? 'Nhận phòng';
    String endText =
        getTranslated('check_out', context) ?? 'Trả phòng';

    if (_startDate != null) startText = dateFmt.format(_startDate!);
    if (_endDate != null) endText = dateFmt.format(_endDate!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey[200]!,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildFilterDateTile(
                      context: context,
                      isDark: isDark,
                      icon: Icons.login_rounded,
                      label:
                      getTranslated('check_in', context) ??
                          'Nhận phòng',
                      value: startText,
                      onTap: () => _pickDate(context, isStart: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterDateTile(
                      context: context,
                      isDark: isDark,
                      icon: Icons.logout_rounded,
                      label:
                      getTranslated('check_out', context) ??
                          'Trả phòng',
                      value: endText,
                      onTap: () => _pickDate(context, isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildGuestSelector(
                      context: context,
                      isDark: isDark,
                      icon: Icons.person_rounded,
                      label: getTranslated('adults', context) ??
                          'Người lớn',
                      value: _adults,
                      min: 1,
                      onChanged: (v) {
                        setState(() => _adults = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildGuestSelector(
                      context: context,
                      isDark: isDark,
                      icon: Icons.child_care_rounded,
                      label: getTranslated('children', context) ??
                          'Trẻ em',
                      value: _children,
                      min: 0,
                      onChanged: (v) {
                        setState(() => _children = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _checkAvailability,
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: Text(
                    getTranslated(
                        'check_availability', context) ??
                        'Kiểm tra phòng trống',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.blue[600]?.withOpacity(0.9)
                        : Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDateTile({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey[100]?.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.15)
                : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDark ? Colors.blue[300] : Colors.blue[700],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? Colors.grey[300]
                          : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestSelector({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String label,
    required int value,
    required int min,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.grey[100]?.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.15)
              : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? Colors.blue[300] : Colors.blue[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? Colors.grey[200]
                    : Colors.black87,
              ),
            ),
          ),
          IconButton(
            onPressed:
            value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline, size: 20),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          IconButton(
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_circle_outline, size: 20),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context,
      {required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDate ?? now)
        : (_endDate ?? _startDate ?? now);
    final firstDate = now;
    final lastDate = now.add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null &&
              _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
          if (_startDate != null &&
              _endDate!.isBefore(_startDate!)) {
            _startDate = null;
          }
        }
      });
    }
  }
  Future<void> _checkAvailability() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            getTranslated('please_select_dates', context) ??
                'Vui lòng chọn ngày nhận / trả phòng',
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final df = DateFormat('yyyy-MM-dd');

      final rooms = await HotelRoomService.checkAvailability(
        hotelId: widget.hotelId,
        startDate: df.format(_startDate!),
        endDate: df.format(_endDate!),
        adults: _adults,
        children: _children,
      );

      setState(() {
        _rooms = rooms;
        _initSelectedRooms(_rooms);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  Widget _buildRoomCard({
    required BuildContext context,
    required bool isDark,
    required int id,
    required String name,
    required double pricePerNight,
    required int number,
    required int beds,
    required int size,
    required int? maxGuests,
    required String thumb,
    required List<dynamic> gallery,
    required List<dynamic> terms,
    required Map<int, String> roomTermNameMap,
    required int maxRooms,
    required int selectedRooms,
    required int nights,
    required ValueChanged<int> onSelectedRoomsChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                          child: SizedBox(
                            width: 120,
                            height: 140,
                            child: thumb.isNotEmpty
                                ? Image.network(
                              thumb,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildRoomPlaceholder(isDark),
                            )
                                : _buildRoomPlaceholder(isDark),
                          ),
                        ),
                        if (number > 0)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: ClipRRect(
                              borderRadius:
                              BorderRadius.circular(8),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                    sigmaX: 5, sigmaY: 5),
                                child: Container(
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black
                                        .withOpacity(0.5),
                                    borderRadius:
                                    BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$number ${getTranslated('rooms_available', context) ?? 'phòng'}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (gallery.length > 1)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: ClipRRect(
                              borderRadius:
                              BorderRadius.circular(8),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                    sigmaX: 5, sigmaY: 5),
                                child: Container(
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black
                                        .withOpacity(0.5),
                                    borderRadius:
                                    BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize:
                                    MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.photo_library,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${gallery.length}',
                                        style:
                                        const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight:
                                          FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding:
                        const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 4,
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 2,
                              overflow:
                              TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (size > 0)
                                  _buildRoomMiniChip(
                                    context,
                                    isDark,
                                    Icons
                                        .square_foot_rounded,
                                    '$size m²',
                                  ),
                                if (beds > 0)
                                  _buildRoomMiniChip(
                                    context,
                                    isDark,
                                    Icons.bed_rounded,
                                    '$beds ${getTranslated('beds', context) ?? 'giường'}',
                                  ),
                                if (maxGuests != null &&
                                    maxGuests > 0)
                                  _buildRoomMiniChip(
                                    context,
                                    isDark,
                                    Icons.group_rounded,
                                    '${getTranslated('max', context) ?? 'Tối đa'} $maxGuests ${getTranslated('guests', context) ?? 'khách'}',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (pricePerNight > 0)
                              Text(
                                '${_formatVndPrice(pricePerNight)}/${getTranslated('night', context) ?? 'đêm'}',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.blue[300]
                                      : Colors.blue[700],
                                  fontWeight:
                                  FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                if (terms.isNotEmpty)
                  Padding(
                    padding:
                    const EdgeInsets.fromLTRB(
                        12, 0, 12, 8),
                    child: Column(
                      children: [
                        Divider(
                          height: 1,
                          color: isDark
                              ? Colors.white
                              .withOpacity(0.1)
                              : Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children:
                                terms.take(3).map((term) {
                                  if (term is! Map) {
                                    return const SizedBox
                                        .shrink();
                                  }

                                  final int? termId =
                                  int.tryParse(
                                      term['term_id']
                                          ?.toString() ??
                                          '');

                                  String label =
                                  termId != null
                                      ? (roomTermNameMap[
                                  termId] ??
                                      '')
                                      : '';

                                  if (label.isEmpty) {
                                    label = (term['translation']
                                    ?['name'] ??
                                        term['name'] ??
                                        term['display_name'] ??
                                        '')
                                        .toString();
                                  }

                                  if (label.isEmpty) {
                                    return const SizedBox
                                        .shrink();
                                  }

                                  return Container(
                                    padding:
                                    const EdgeInsets
                                        .symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration:
                                    BoxDecoration(
                                      color: isDark
                                          ? Colors.green
                                          .withOpacity(
                                          0.2)
                                          : Colors
                                          .green[50],
                                      borderRadius:
                                      BorderRadius
                                          .circular(6),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.green
                                            .withOpacity(
                                            0.3)
                                            : Colors.green[
                                        200]!,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize:
                                      MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons
                                              .check_circle,
                                          size: 12,
                                          color: isDark
                                              ? Colors
                                              .green[
                                          300]
                                              : Colors
                                              .green[
                                          700],
                                        ),
                                        const SizedBox(
                                            width: 4),
                                        Text(
                                          label,
                                          style:
                                          TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors
                                                .green[
                                            200]
                                                : Colors
                                                .green[
                                            800],
                                            fontWeight:
                                            FontWeight
                                                .w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            if (terms.length > 3)
                              Text(
                                '+${terms.length - 3}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors
                                      .grey[400]
                                      : Colors
                                      .grey[600],
                                  fontWeight:
                                  FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                if (maxRooms > 0)
                  Padding(
                    padding:
                    const EdgeInsets.fromLTRB(
                        12, 0, 12, 8),
                    child: _buildRoomQuantitySelector(
                      context: context,
                      isDark: isDark,
                      maxRooms: maxRooms,
                      selectedRooms: selectedRooms,
                      pricePerNight: pricePerNight,
                      nights: nights,
                      onChanged: onSelectedRoomsChanged,
                    ),
                  ),
                Padding(
                  padding:
                  const EdgeInsets.fromLTRB(
                      12, 4, 12, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius:
                      BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                            sigmaX: 10, sigmaY: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            final rooms =
                                _selectedRooms[id] ?? 0;
                            final msg =
                                '${getTranslated('selected_room', context) ?? 'Đã chọn'}: $name - $rooms ${getTranslated('rooms', context) ?? 'phòng'}';
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: isDark
                                    ? Colors.blue[700]
                                    : Colors.blue[600],
                              ),
                            );
                          },
                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.blue[600]
                                ?.withOpacity(0.8)
                                : Colors.blue[600]
                                ?.withOpacity(0.9),
                            foregroundColor: Colors.white,
                            padding:
                            const EdgeInsets
                                .symmetric(
                                vertical: 14),
                            elevation: 0,
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(
                                  12),
                            ),
                          ),
                          child: Text(
                            getTranslated(
                                'select_room',
                                context) ??
                                'Chọn phòng',
                            style: const TextStyle(
                              fontWeight:
                              FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomQuantitySelector({
    required BuildContext context,
    required bool isDark,
    required int maxRooms,
    required int selectedRooms,
    required double pricePerNight,
    required int nights,
    required ValueChanged<int> onChanged,
  }) {
    final label =
        getTranslated('number_of_rooms', context) ??
            'Số phòng';
    final totalPrice =
        pricePerNight * selectedRooms * nights;
    final nightsLabel =
    nights > 1 ? '$nights đêm' : '1 đêm';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.grey[100]?.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.15)
              : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.grey[300]
                        : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButton<int>(
                  value: selectedRooms,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(
                      Icons.expand_more_rounded),
                  onChanged: (v) {
                    if (v == null) return;
                    onChanged(v);
                  },
                  items: List.generate(
                      maxRooms + 1, (i) {
                    if (i == 0) {
                      return DropdownMenuItem(
                        value: 0,
                        child: Text(
                          '0',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      );
                    }

                    final total = pricePerNight *
                        i *
                        nights;
                    final text =
                        '$i ${getTranslated('rooms', context) ?? 'phòng'} (${_formatVndPrice(total)} / $nightsLabel)';

                    return DropdownMenuItem(
                      value: i,
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          if (selectedRooms > 0 && totalPrice > 0)
            Padding(
              padding:
              const EdgeInsets.only(left: 8),
              child: Text(
                _formatVndPrice(totalPrice),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.blue[300]
                      : Colors.blue[700],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoomPlaceholder(bool isDark) {
    return Container(
      color: isDark
          ? Colors.grey[800]
          : Colors.grey[200],
      child: Icon(
        Icons.bed_rounded,
        color:
        isDark ? Colors.grey[600] : Colors.grey,
        size: 32,
      ),
    );
  }

  String _formatVndPrice(dynamic raw) {
    double value;
    if (raw is num) {
      value = raw.toDouble();
    } else {
      final s = raw.toString();
      value = double.tryParse(
          s.replaceAll(RegExp(r'[^0-9]'), '')) ??
          0;
    }

    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
    required bool isDark,
  }) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
          horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
            BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white
                      .withOpacity(0.5),
                  borderRadius:
                  BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white
                        .withOpacity(0.1)
                        : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding:
                      const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.blue[700]
                            ?.withOpacity(0.3)
                            : Colors.blue[50],
                        borderRadius:
                        BorderRadius.circular(
                            10),
                      ),
                      child: Icon(
                        icon,
                        size: 22,
                        color: isDark
                            ? Colors.blue[300]
                            : Colors.blue[700],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildRoomMiniChip(
      BuildContext context,
      bool isDark,
      IconData icon,
      String label,
      ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter:
        ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey[100]
                ?.withOpacity(0.8),
            borderRadius:
            BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.grey[300]!,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isDark
                    ? Colors.grey[300]
                    : Colors.grey[700],
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? Colors.grey[300]
                      : Colors.grey[800],
                  fontWeight:
                  FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}