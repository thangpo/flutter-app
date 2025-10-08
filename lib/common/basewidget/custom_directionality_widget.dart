import 'package:flutter/material.dart';

class CustomDirectionalityWidget extends StatelessWidget {
  final Widget child;
  const CustomDirectionalityWidget({super.key,  required this.child});

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.ltr, child: child);
  }
}