import 'package:flutter/material.dart';

class FlightBottomMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const FlightBottomMenuItem({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.cyan, size: 28),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}