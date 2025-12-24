import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import '../screens/location_picker_screen.dart';

class FlightBookingForm extends StatelessWidget {
  final String fromCity;
  final String fromCode;
  final String toCity;
  final String toCode;
  final DateTime? departureDate;
  final DateTime? returnDate;
  final int passengers;
  final int adults;
  final int children;
  final int infants;
  final bool isRoundTrip;
  final VoidCallback onSwap;
  final ValueChanged<bool> onRoundTripChanged;

  final Function(Map<String, dynamic>) onFormChanged;
  final VoidCallback onSearch;

  const FlightBookingForm({
    super.key,
    required this.fromCity,
    required this.fromCode,
    required this.toCity,
    required this.toCode,
    required this.departureDate,
    required this.returnDate,
    required this.passengers,
    required this.adults,
    this.children = 0,
    this.infants = 0,
    required this.isRoundTrip,
    required this.onSwap,
    required this.onRoundTripChanged,
    required this.onFormChanged,
    required this.onSearch,
  });

  String _tr(BuildContext context, String key, String fallback) {
    return getTranslated(key, context) ?? fallback;
  }

  String _getPassengerText(BuildContext context) {
    final adultLabel =
    _tr(context, 'flight_passenger_adult', 'người lớn');
    final childLabel =
    _tr(context, 'flight_passenger_child', 'trẻ em');
    final infantLabel =
    _tr(context, 'flight_passenger_infant', 'em bé');

    List<String> parts = [];
    if (adults > 0) {
      parts.add('$adults $adultLabel');
    }
    if (children > 0) {
      parts.add('$children $childLabel');
    }
    if (infants > 0) {
      parts.add('$infants $infantLabel');
    }

    return parts.isEmpty
        ? _tr(context, 'flight_passenger_zero', '0 hành khách')
        : parts.join(', ');
  }

  void _showPassengerSelector(BuildContext context) {
    int adultsCount = adults;
    int childrenCount = children;
    int infantsCount = infants;

    final primary = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        final isDark =
            Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _tr(
                          context,
                          'flight_passenger_title',
                          'Chọn số lượng hành khách',
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color:
                          isDark ? Colors.white70 : Colors.grey[800],
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPassengerRow(
                    context: context,
                    label: _tr(context, 'flight_passenger_adult',
                        'Người lớn'),
                    subtitle: _tr(
                      context,
                      'flight_passenger_sub_adult',
                      'Từ 12 tuổi',
                    ),
                    count: adultsCount,
                    onDecrement: adultsCount > 1
                        ? () =>
                        setState(() => adultsCount--)
                        : null,
                    onIncrement: () =>
                        setState(() => adultsCount++),
                    primary: primary,
                  ),
                  const SizedBox(height: 16),
                  _buildPassengerRow(
                    context: context,
                    label: _tr(context, 'flight_passenger_child',
                        'Trẻ em'),
                    subtitle: _tr(
                      context,
                      'flight_passenger_sub_child',
                      'Từ 2 - 11 tuổi',
                    ),
                    count: childrenCount,
                    onDecrement: childrenCount > 0
                        ? () =>
                        setState(() => childrenCount--)
                        : null,
                    onIncrement: () =>
                        setState(() => childrenCount++),
                    primary: primary,
                  ),
                  const SizedBox(height: 16),
                  _buildPassengerRow(
                    context: context,
                    label: _tr(context, 'flight_passenger_infant',
                        'Em bé'),
                    subtitle: _tr(
                      context,
                      'flight_passenger_sub_infant',
                      'Dưới 2 tuổi',
                    ),
                    count: infantsCount,
                    onDecrement: infantsCount > 0
                        ? () =>
                        setState(() => infantsCount--)
                        : null,
                    onIncrement: () =>
                        setState(() => infantsCount++),
                    primary: primary,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        onFormChanged({
                          "fromCity": fromCity,
                          "fromCode": fromCode,
                          "toCity": toCity,
                          "toCode": toCode,
                          "departureDate": departureDate,
                          "returnDate": returnDate,
                          "passengers": adultsCount +
                              childrenCount +
                              infantsCount,
                          "adults": adultsCount,
                          "children": childrenCount,
                          "infants": infantsCount,
                          "isRoundTrip": isRoundTrip,
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _tr(context, 'flight_confirm', 'Xác nhận'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPassengerRow({
    required BuildContext context,
    required String label,
    required String subtitle,
    required int count,
    required VoidCallback? onDecrement,
    required VoidCallback onIncrement,
    required Color primary,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color borderInactive = isDark
        ? Colors.white24
        : Colors.grey[300]!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white
                    : const Color(0xFF111827),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color:
                isDark ? Colors.white60 : Colors.grey[600],
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: onDecrement == null
                      ? borderInactive
                      : primary,
                  width: 2,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.remove,
                  color: onDecrement == null
                      ? borderInactive
                      : primary,
                  size: 20,
                ),
                onPressed: onDecrement,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 30,
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF111827),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: primary,
                  width: 2,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.add,
                  color: primary,
                  size: 20,
                ),
                onPressed: onIncrement,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectDate(
      BuildContext context,
      bool isDeparture,
      DateTime? initialDate,
      ) async {
    final baseTheme = Theme.of(context);
    final isDark = baseTheme.brightness == Brightness.dark;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        final ColorScheme scheme = isDark
            ? const ColorScheme.dark(
          primary: Color(0xFF06B6D4),
          onPrimary: Colors.white,
          surface: Color(0xFF020617),
          onSurface: Colors.white,
        )
            : const ColorScheme.light(
          primary: Color(0xFF06B6D4),
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
        );

        return Theme(
          data: ThemeData(
            colorScheme: scheme,
            dialogBackgroundColor: scheme.surface,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isDeparture) {
        onFormChanged({
          "fromCity": fromCity,
          "fromCode": fromCode,
          "toCity": toCity,
          "toCode": toCode,
          "departureDate": picked,
          "returnDate": (returnDate != null &&
              returnDate!.isAfter(picked))
              ? returnDate
              : null,
          "passengers": passengers,
          "adults": adults,
          "children": children,
          "infants": infants,
          "isRoundTrip": isRoundTrip,
        });
      } else {
        onFormChanged({
          "fromCity": fromCity,
          "fromCode": fromCode,
          "toCity": toCity,
          "toCode": toCode,
          "departureDate": departureDate,
          "returnDate": picked,
          "passengers": passengers,
          "adults": adults,
          "children": children,
          "infants": infants,
          "isRoundTrip": isRoundTrip,
        });
      }
    }
  }

  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) {
      return _tr(context, 'flight_select_date', 'Chọn ngày');
    }
    final locale =
    Localizations.localeOf(context).toLanguageTag();
    return DateFormat('EEE, dd/MM/yyyy', locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final cardColor =
    isDark ? const Color(0xFF020617) : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LocationPickerScreen(
                    title: _tr(
                        context, 'flight_from_title', 'Chọn điểm đi'),
                    onLocationSelected: (_) {},
                  ),
                ),
              );
              if (result != null) {
                onFormChanged({
                  "fromCity": result["city"],
                  "fromCode": result["code"],
                  "toCity": toCity,
                  "toCode": toCode,
                  "departureDate": departureDate,
                  "returnDate": returnDate,
                  "passengers": passengers,
                  "adults": adults,
                  "children": children,
                  "infants": infants,
                  "isRoundTrip": isRoundTrip,
                });
              }
            },
            child: Row(
              children: [
                Icon(
                  Icons.circle_outlined,
                  size: 20,
                  color:
                  isDark ? Colors.white70 : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$fromCity - $fromCode',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF111827),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white10
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.swap_vert,
                      size: 20,
                      color: primary,
                    ),
                    onPressed: onSwap,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LocationPickerScreen(
                    title: _tr(context, 'flight_to_title',
                        "Chọn điểm đến"),
                    onLocationSelected: (_) {},
                  ),
                ),
              );
              if (result != null) {
                onFormChanged({
                  "fromCity": fromCity,
                  "fromCode": fromCode,
                  "toCity": result["city"],
                  "toCode": result["code"],
                  "departureDate": departureDate,
                  "returnDate": returnDate,
                  "passengers": passengers,
                  "adults": adults,
                  "children": children,
                  "infants": infants,
                  "isRoundTrip": isRoundTrip,
                });
              }
            },
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color:
                  isDark ? Colors.white70 : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$toCity - $toCode',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(
            color: isDark
                ? Colors.white12
                : Colors.grey[200],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color:
                isDark ? Colors.white70 : Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      _selectDate(context, true, departureDate),
                  child: Text(
                    _formatDate(context, departureDate),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF111827),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    _tr(context, 'flight_round_trip', 'Khứ hồi'),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white70
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: isRoundTrip,
                    onChanged: onRoundTripChanged,
                    activeColor: Colors.white,
                    activeTrackColor: primary,
                  ),
                ],
              ),
            ],
          ),

          if (isRoundTrip) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                  color:
                  isDark ? Colors.white70 : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(
                      context,
                      false,
                      returnDate ?? departureDate,
                    ),
                    child: Text(
                      _formatDate(context, returnDate),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF111827),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Divider(
            color: isDark
                ? Colors.white12
                : Colors.grey[200],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showPassengerSelector(context),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 20,
                  color:
                  isDark ? Colors.white70 : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getPassengerText(context),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF111827),
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color:
                  isDark ? Colors.white54 : Colors.grey[600],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _tr(context, 'flight_search', 'Tìm kiếm'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}