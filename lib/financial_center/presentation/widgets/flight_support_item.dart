import 'package:flutter/material.dart';

class FlightSupportItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const FlightSupportItem({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.cyan.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(icon, color: Colors.cyan, size: 24),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, height: 1.2),
          ),
        ),
      ],
    );
  }
}