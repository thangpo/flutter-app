import 'package:flutter/material.dart';

class ColorHelper {
  static Color? hexCodeToColor(String? code){
    int? colorCode = int.tryParse(code?.replaceAll('#', '0xff') ?? '');

    return colorCode == null ? null : Color(colorCode);
  }


  static Color blendColors(Color background, Color foreground, double opacity) {
    return Color.alphaBlend(foreground.withValues(alpha: opacity), background);
  }


  static Color darken(Color color, double amount) {
    assert(amount >= 0 && amount <= 1, "Amount must be between 0 and 1");

    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor();
  }


}