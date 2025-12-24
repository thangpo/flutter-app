import 'package:flutter/material.dart';

PageRoute<T> fadeRoute<T>(Widget page, {Duration duration = const Duration(milliseconds: 260)}) {
  return PageRouteBuilder<T>(
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}