import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  String _getPassengerText() {
    List<String> parts = [];
    if (adults > 0) {
      parts.add('$adults người lớn');
    }
    if (children > 0) {
      parts.add('$children trẻ em');
    }
    if (infants > 0) {
      parts.add('$infants em bé');
    }

    return parts.isEmpty ? '0 hành khách' : parts.join(', ');
  }

  void _showPassengerSelector(BuildContext context) {
    int adultsCount = adults;
    int childrenCount = children;
    int infantsCount = infants;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chọn số lượng hành khách',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPassengerRow(
                    label: 'Người lớn',
                    subtitle: 'Từ 12 tuổi',
                    count: adultsCount,
                    onDecrement: adultsCount > 1
                        ? () => setState(() => adultsCount--)
                        : null,
                    onIncrement: () => setState(() => adultsCount++),
                  ),
                  const SizedBox(height: 16),
                  _buildPassengerRow(
                    label: 'Trẻ em',
                    subtitle: 'Từ 2 - 11 tuổi',
                    count: childrenCount,
                    onDecrement: childrenCount > 0
                        ? () => setState(() => childrenCount--)
                        : null,
                    onIncrement: () => setState(() => childrenCount++),
                  ),
                  const SizedBox(height: 16),
                  _buildPassengerRow(
                    label: 'Em bé',
                    subtitle: 'Dưới 2 tuổi',
                    count: infantsCount,
                    onDecrement: infantsCount > 0
                        ? () => setState(() => infantsCount--)
                        : null,
                    onIncrement: () => setState(() => infantsCount++),
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
                          "passengers": adultsCount + childrenCount + infantsCount,
                          "adults": adultsCount,
                          "children": childrenCount,
                          "infants": infantsCount,
                          "isRoundTrip": isRoundTrip,
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Xác nhận',
                        style: TextStyle(
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
    required String label,
    required String subtitle,
    required int count,
    required VoidCallback? onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
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
                  color: onDecrement == null ? Colors.grey[300]! : Colors.blue,
                  width: 2,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.remove,
                  color: onDecrement == null ? Colors.grey[300] : Colors.blue,
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.blue,
                  width: 2,
                ),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.add,
                  color: Colors.blue,
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
      BuildContext context, bool isDeparture, DateTime? initialDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            primarySwatch: Colors.blue,
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
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
          "returnDate": (returnDate != null && returnDate!.isAfter(picked))
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

  String _formatDate(DateTime? date) {
    if (date == null) return "Chọn ngày";
    return DateFormat('EEE, dd/MM/yyyy', 'vi').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
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
                  builder: (_) =>
                      LocationPickerScreen(title: "Chọn điểm đi", onLocationSelected: (_) {}),
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
                const Icon(Icons.circle_outlined, size: 20, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$fromCity - $fromCode',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.swap_vert, size: 20),
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
                  builder: (_) =>
                      LocationPickerScreen(title: "Chọn điểm đến", onLocationSelected: (_) {}),
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
                const Icon(Icons.location_on_outlined, size: 20, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$toCity - $toCode',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(context, true, departureDate),
                  child: Text(
                    _formatDate(departureDate),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    'Khứ hồi',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: isRoundTrip,
                    onChanged: onRoundTripChanged,
                    activeThumbColor: Colors.cyan,
                  ),
                ],
              ),
            ],
          ),

          if (isRoundTrip) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 20, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context, false, returnDate ?? departureDate),
                    child: Text(
                      _formatDate(returnDate),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: () => _showPassengerSelector(context),
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 20, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getPassengerText(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
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
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Tìm kiếm',
                    style: TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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