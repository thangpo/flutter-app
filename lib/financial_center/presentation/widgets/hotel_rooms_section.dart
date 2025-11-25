import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/hotel_room_service.dart';
import 'hotel_room_card.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';

class HotelSelectedRoom {
  final int id;
  final String name;
  final int quantity;
  final double pricePerNight;
  final int nights;
  final double totalPrice;
  final int? maxGuests;
  final int? adultsPerRoom;
  final int? childrenPerRoom;

  HotelSelectedRoom({
    required this.id,
    required this.name,
    required this.quantity,
    required this.pricePerNight,
    required this.nights,
    required this.totalPrice,
    this.maxGuests,
    this.adultsPerRoom,
    this.childrenPerRoom,
  });
}

class HotelBookingSummary {
  final List<HotelSelectedRoom> rooms;
  final DateTime? startDate;
  final DateTime? endDate;
  final int adults;
  final int children;
  final bool fromSearch;

  final VoidCallback? clearAllRooms;
  final void Function(int roomId)? removeRoom;

  HotelBookingSummary({
    required this.rooms,
    required this.startDate,
    required this.endDate,
    required this.adults,
    required this.children,
    required this.fromSearch,

    this.clearAllRooms,
    this.removeRoom,
  });

  int get totalRooms =>
      rooms.fold(0, (sum, r) => sum + r.quantity);

  double get totalPrice =>
      rooms.fold(0.0, (sum, r) => sum + r.totalPrice);
}

class HotelRoomsSection extends StatefulWidget {
  final int hotelId;
  final List<dynamic> rooms;
  final Map<int, String> roomTermNameMap;
  final ValueChanged<HotelBookingSummary>? onBookingSummaryChanged;

  const HotelRoomsSection({
    super.key,
    required this.hotelId,
    required this.rooms,
    required this.roomTermNameMap,
    this.onBookingSummaryChanged,
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
  bool _hasSearched = false;

  final Map<int, int> _selectedRooms = {};

  @override
  void initState() {
    super.initState();
    _rooms = List<dynamic>.from(widget.rooms);
    _initSelectedRooms(_rooms);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notifyBookingSummaryChanged();
    });
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

  void _clearAllRooms() {
    setState(() {
      for (final key in _selectedRooms.keys.toList()) {
        _selectedRooms[key] = 0;
      }
    });
    _notifyBookingSummaryChanged();
  }

  void _removeRoomById(int roomId) {
    if (!_selectedRooms.containsKey(roomId)) return;
    setState(() {
      _selectedRooms[roomId] = 0;
    });
    _notifyBookingSummaryChanged();
  }

  int _safeParseFirstInt(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is double) return raw.toInt();
    final s = raw.toString();
    final match = RegExp(r'\d+').firstMatch(s);
    if (match == null) return 0;
    return int.tryParse(match.group(0)!) ?? 0;
  }

  HotelBookingSummary _buildBookingSummary() {
    final List<HotelSelectedRoom> selected = [];
    final int nights = (_startDate != null && _endDate != null)
        ? (_endDate!.difference(_startDate!).inDays).clamp(1, 365)
        : 1;

    for (final r in _rooms) {
      if (r is! Map) continue;
      final room = r as Map;

      final int id = int.tryParse(room['id']?.toString() ?? '0') ?? 0;
      if (id == 0) continue;

      final int quantity = _selectedRooms[id] ?? 0;
      if (quantity <= 0) continue;

      final String name =
      (room['title'] ?? room['name'] ?? '').toString();

      final dynamic priceRaw =
          room['price'] ?? room['min_price'] ?? 0;
      final double priceDouble = priceRaw is num
          ? priceRaw.toDouble()
          : double.tryParse(priceRaw.toString()) ?? 0.0;

      final bool isAvailabilityResult =
          room['price_text'] != null || room['price_html'] != null;

      final double pricePerNight = isAvailabilityResult && nights > 0
          ? priceDouble / nights
          : priceDouble;

      final int? maxGuests = room['max_guests'] != null
          ? int.tryParse(room['max_guests'].toString())
          : null;

      final int? adults = (room.containsKey('adults') ||
          room.containsKey('adults_html'))
          ? _safeParseFirstInt(
        room['adults'] ?? room['adults_html'],
      )
          : null;

      final int? children = (room.containsKey('children') ||
          room.containsKey('children_html'))
          ? _safeParseFirstInt(
        room['children'] ?? room['children_html'],
      )
          : null;

      final double totalPrice =
          pricePerNight * quantity * nights;

      selected.add(
        HotelSelectedRoom(
          id: id,
          name: name,
          quantity: quantity,
          pricePerNight: pricePerNight,
          nights: nights,
          totalPrice: totalPrice,
          maxGuests: maxGuests,
          adultsPerRoom: adults,
          childrenPerRoom: children,
        ),
      );
    }

    return HotelBookingSummary(
      rooms: selected,
      startDate: _startDate,
      endDate: _endDate,
      adults: _adults,
      children: _children,
      fromSearch: _hasSearched,
      clearAllRooms: _clearAllRooms,
      removeRoom: _removeRoomById,
    );
  }

  void _notifyBookingSummaryChanged() {
    if (widget.onBookingSummaryChanged == null) return;
    final summary = _buildBookingSummary();
    widget.onBookingSummaryChanged!(summary);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rooms.isEmpty && _rooms.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme =
    Provider.of<ThemeController>(context, listen: false);
    final isDark = theme.darkTheme;

    return _buildSection(
      context: context,
      title: getTranslated('room_types', context) ??
          'Các loại phòng',
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
              final room =
              r as Map<dynamic, dynamic>;
              final int id =
                  int.tryParse(room['id']?.toString() ?? '0') ??
                      0;

              final String name =
              (room['title'] ?? room['name'] ?? '')
                  .toString();

              final int nights =
              (_startDate != null && _endDate != null)
                  ? (_endDate!
                  .difference(_startDate!)
                  .inDays)
                  .clamp(1, 365)
                  : 1;

              final dynamic priceRaw =
                  room['price'] ?? room['min_price'] ?? 0;
              final double priceDouble = priceRaw is num
                  ? priceRaw.toDouble()
                  : double.tryParse(priceRaw.toString()) ??
                  0.0;

              final bool isAvailabilityResult =
                  room['price_text'] != null ||
                      room['price_html'] != null;

              final double pricePerNight =
              isAvailabilityResult && nights > 0
                  ? priceDouble / nights
                  : priceDouble;

              final int number =
              _safeParseFirstInt(
                room['number'] ?? room['tmp_number'],
              );

              final int size = _safeParseFirstInt(
                room['size'] ??
                    room['room_size'] ??
                    room['size_html'],
              );

              final int beds = _safeParseFirstInt(
                room['beds'] ?? room['beds_html'],
              );

              final int? adults = (room
                  .containsKey('adults') ||
                  room.containsKey('adults_html'))
                  ? _safeParseFirstInt(
                room['adults'] ??
                    room['adults_html'],
              )
                  : null;

              final int? children = (room
                  .containsKey('children') ||
                  room.containsKey('children_html'))
                  ? _safeParseFirstInt(
                room['children'] ??
                    room['children_html'],
              )
                  : null;

              final int? maxGuests =
              room['max_guests'] != null
                  ? int.tryParse(
                room['max_guests'].toString(),
              )
                  : null;

              final List<dynamic> gallery =
                  (room['gallery'] as List?) ??
                      <dynamic>[];

              final String thumb = gallery.isNotEmpty
                  ? ((gallery.first is Map
                  ? (gallery.first['large'] ??
                  gallery.first['thumb'] ??
                  '')
                  : gallery.first)
                  .toString())
                  : (room['image'] ?? '').toString();

              List<dynamic> terms = [];
              final dynamic termsRaw = room['terms'];

              if (room['term_features'] is List) {
                terms = List<dynamic>.from(
                    room['term_features']);
              } else if (termsRaw is List) {
                terms = termsRaw;
              } else if (termsRaw is Map) {
                for (final value in termsRaw.values) {
                  if (value is Map &&
                      value['child'] is List) {
                    for (final c in value['child']) {
                      if (c is Map) terms.add(c);
                    }
                  }
                }
              }

              final int maxRooms =
              number > 0 ? number : 0;
              final int selectedRooms =
                  _selectedRooms[id] ?? 0;

              return HotelRoomCard(
                id: id,
                name: name,
                pricePerNight: pricePerNight,
                number: number,
                beds: beds,
                size: size,
                maxGuests: maxGuests,
                thumb: thumb,
                gallery: gallery,
                terms: terms,
                roomTermNameMap: widget.roomTermNameMap,
                maxRooms: maxRooms,
                adults: adults,
                children: children,
                selectedRooms: selectedRooms,
                nights: nights,
                isDark: isDark,
                isSelected: selectedRooms > 0,
                onSelectedRoomsChanged: (value) {
                  setState(() {
                    _selectedRooms[id] = value;
                  });
                  _notifyBookingSummaryChanged();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
      BuildContext context, bool isDark) {
    final dateFmt = DateFormat('dd/MM/yyyy');

    String startText =
        getTranslated('check_in', context) ??
            'Nhận phòng';
    String endText =
        getTranslated('check_out', context) ??
            'Trả phòng';

    if (_startDate != null) startText = dateFmt.format(_startDate!);
    if (_endDate != null) endText = dateFmt.format(_endDate!);

    final bool showGuests =
        _startDate != null && _endDate != null;

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
                      label: getTranslated(
                          'check_in', context) ??
                          'Nhận phòng',
                      value: startText,
                      onTap: () =>
                          _pickDate(context, isStart: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterDateTile(
                      context: context,
                      isDark: isDark,
                      icon: Icons.logout_rounded,
                      label: getTranslated(
                          'check_out', context) ??
                          'Trả phòng',
                      value: endText,
                      onTap: () =>
                          _pickDate(context, isStart: false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (showGuests) ...[
                _buildGuestSelector(
                  context: context,
                  isDark: isDark,
                  icon: Icons.person_rounded,
                  label:
                  getTranslated('adults', context) ??
                      'Người lớn',
                  value: _adults,
                  min: 1,
                  onChanged: (v) {
                    setState(() => _adults = v);
                    _notifyBookingSummaryChanged();
                  },
                ),
                const SizedBox(height: 8),
                _buildGuestSelector(
                  context: context,
                  isDark: isDark,
                  icon: Icons.child_care_rounded,
                  label:
                  getTranslated('children', context) ??
                      'Trẻ em',
                  value: _children,
                  min: 0,
                  onChanged: (v) {
                    setState(() => _children = v);
                    _notifyBookingSummaryChanged();
                  },
                ),
                const SizedBox(height: 10),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                  _loading ? null : _checkAvailability,
                  icon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                  ),
                  label: Text(
                    getTranslated(
                        'check_availability', context) ??
                        'Kiểm tra phòng trống',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.blue[600]
                        ?.withOpacity(0.9)
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
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 8),
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
              color:
              isDark ? Colors.blue[300] : Colors.blue[700],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
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
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 8),
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
            color:
            isDark ? Colors.blue[300] : Colors.blue[700],
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
            icon: const Icon(
              Icons.remove_circle_outline,
              size: 20,
            ),
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
            icon: const Icon(
              Icons.add_circle_outline,
              size: 20,
            ),
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
      _notifyBookingSummaryChanged();
    }
  }

  Future<void> _checkAvailability() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            getTranslated(
                'please_select_dates', context) ??
                'Vui lòng chọn ngày nhận / trả phòng',
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final df = DateFormat('yyyy-MM-dd');

      final rooms =
      await HotelRoomService.checkAvailability(
        hotelId: widget.hotelId,
        startDate: df.format(_startDate!),
        endDate: df.format(_endDate!),
        adults: _adults,
        children: _children,
      );

      setState(() {
        _rooms = rooms;
        _hasSearched = true;
        _initSelectedRooms(_rooms);
      });
      _notifyBookingSummaryChanged();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.blue[700]
                            ?.withOpacity(0.3)
                            : Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
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
}