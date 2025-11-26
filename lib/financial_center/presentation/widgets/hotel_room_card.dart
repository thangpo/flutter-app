import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

class HotelRoomCard extends StatelessWidget {
  final int id;
  final String name;
  final double pricePerNight;
  final int number;
  final int beds;
  final int size;
  final int? maxGuests;
  final String thumb;
  final List<dynamic> gallery;
  final List<dynamic> terms;
  final Map<int, String> roomTermNameMap;
  final int maxRooms;
  final int? adults;
  final int? children;
  final int selectedRooms;
  final int nights;
  final bool isDark;
  final bool isSelected; // 👈 NEW
  final ValueChanged<int> onSelectedRoomsChanged;

  const HotelRoomCard({
    super.key,
    required this.id,
    required this.name,
    required this.pricePerNight,
    required this.number,
    required this.beds,
    required this.size,
    required this.maxGuests,
    required this.thumb,
    required this.gallery,
    required this.terms,
    required this.roomTermNameMap,
    required this.maxRooms,
    required this.adults,
    required this.children,
    required this.selectedRooms,
    required this.nights,
    required this.isDark,
    required this.isSelected, // 👈 NEW
    required this.onSelectedRoomsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? (isDark ? Colors.blue[300]! : Colors.blue[500]!)
        : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                  ? Colors.blueGrey.withOpacity(0.35)
                  : Colors.blueGrey.withOpacity(0.08))
                  : (isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.white.withOpacity(0.7)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildTopRow(context),
                if (terms.isNotEmpty) _buildTerms(context),
                if (maxRooms > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: _buildRoomQuantitySelector(context),
                  ),
                _buildSelectButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(BuildContext context) {
    return Row(
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
                  errorBuilder: (_, __, ___) => _buildRoomPlaceholder(),
                )
                    : _buildRoomPlaceholder(),
              ),
            ),
            if (gallery.length > 1)
              Positioned(
                bottom: 8,
                right: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${gallery.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (isSelected)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: Colors.greenAccent[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        getTranslated('selected', context) ?? 'Đã chọn',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
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
                        Icons.square_foot_rounded,
                        '$size m²',
                      ),
                    if (beds > 0)
                      _buildRoomMiniChip(
                        context,
                        Icons.bed_rounded,
                        'x$beds ${getTranslated('beds', context) ?? 'giường'}',
                      ),
                    if (adults != null && adults! > 0)
                      _buildRoomMiniChip(
                        context,
                        Icons.person_outline_rounded,
                        'x$adults ${getTranslated('adults', context) ?? 'người lớn'}',
                      ),
                    if (children != null && children! > 0)
                      _buildRoomMiniChip(
                        context,
                        Icons.child_care_rounded,
                        'x$children ${getTranslated('children', context) ?? 'trẻ em'}',
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (pricePerNight > 0)
                  Text(
                    '${_formatVndPrice(pricePerNight)}/${getTranslated('night', context) ?? 'đêm'}',
                    style: TextStyle(
                      color: isDark ? Colors.blue[300] : Colors.blue[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTerms(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        children: [
          Divider(
            height: 1,
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: terms.take(3).map((term) {
                    if (term is! Map) {
                      return const SizedBox.shrink();
                    }

                    final int? termId =
                    int.tryParse(term['term_id']?.toString() ?? '');

                    String label = termId != null
                        ? (roomTermNameMap[termId] ?? '')
                        : '';

                    if (label.isEmpty) {
                      label = (term['translation']?['name'] ??
                          term['name'] ??
                          term['display_name'] ??
                          term['title'] ??
                          '')
                          .toString();
                    }

                    if (label.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.green.withOpacity(0.2)
                            : Colors.green[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark
                              ? Colors.green.withOpacity(0.3)
                              : Colors.green[200]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 12,
                            color: isDark
                                ? Colors.green[300]
                                : Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.green[200]
                                  : Colors.green[800],
                              fontWeight: FontWeight.w500,
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
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomQuantitySelector(BuildContext context) {
    final label = getTranslated('number_of_rooms', context) ?? 'Số phòng';
    final totalPrice = pricePerNight * selectedRooms * nights;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.grey[100]?.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
          isDark ? Colors.white.withOpacity(0.15) : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButton<int>(
                  value: selectedRooms,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.expand_more_rounded),
                  onChanged: (v) {
                    if (v == null) return;
                    onSelectedRoomsChanged(v);
                  },
                  items: List.generate(maxRooms + 1, (i) {
                    if (i == 0) {
                      final zeroLabel =
                          getTranslated('select_room', context) ??
                              'Chọn phòng';

                      return DropdownMenuItem(
                        value: 0,
                        child: Text(
                          zeroLabel,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                            isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      );
                    }

                    final total = pricePerNight * i * nights;
                    final nightsLabel =
                    nights > 1 ? '$nights đêm' : '1 đêm';
                    final text =
                        '$i ${getTranslated('rooms', context) ?? 'phòng'} '
                        '(${_formatVndPrice(total)} / $nightsLabel)';

                    return DropdownMenuItem(
                      value: i,
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                          isDark ? Colors.white : Colors.black87,
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
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                _formatVndPrice(totalPrice),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.blue[300] : Colors.blue[700],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: SizedBox(
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: ElevatedButton(
              onPressed: () {
                if (selectedRooms <= 0) {
                  final msg =
                      getTranslated('please_select_room_qty', context) ??
                          'Vui lòng chọn số phòng ở phía trên.';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
                  return;
                }

                final msg =
                    '${getTranslated('selected_room', context) ?? 'Đã chọn'}: '
                    '$name - $selectedRooms ${getTranslated('rooms', context) ?? 'phòng'}';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(msg),
                    backgroundColor:
                    isDark ? Colors.blue[700] : Colors.blue[600],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? Colors.blue[600]?.withOpacity(0.8)
                    : Colors.blue[600]?.withOpacity(0.9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                getTranslated('select_room', context) ?? 'Chọn phòng',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomPlaceholder() {
    return Container(
      color: isDark ? Colors.grey[800] : Colors.grey[200],
      child: Icon(
        Icons.bed_rounded,
        color: isDark ? Colors.grey[600] : Colors.grey,
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
      value = double.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }

    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  Widget _buildRoomMiniChip(
      BuildContext context,
      IconData icon,
      String label,
      ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey[100]?.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
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
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
