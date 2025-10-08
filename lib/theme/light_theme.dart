import 'package:flutter/material.dart';

Color _primaryColor = const Color(0xFF1455AC);
Color _secondaryColor = const Color(0xFFF58300);


ThemeData light({Color? primaryColor, Color? secondaryColor})=> ThemeData(
  fontFamily: 'TitilliumWeb',
  primaryColor: primaryColor ?? const Color(0xFF1455AC),
  brightness: Brightness.light,
  highlightColor: Colors.white,
  hintColor: const Color(0xFFA7A7A7), //Border Color
  splashColor: Colors.transparent,
  cardColor: Colors.white,

  scaffoldBackgroundColor: const Color(0xFFF7F8FA),

  textTheme: TextTheme(
    bodyLarge: const TextStyle(color: Color(0xFF222324)),  // Text color primary
    bodyMedium: TextStyle(color: _primaryColor), // Text color Secondary
    bodySmall: const TextStyle(color: Color(0xFFA7A7A7)),  // Text color Light grey

    titleMedium: const TextStyle(color: Color(0xFF656566)),

  ),

  colorScheme:  ColorScheme.light(
    primary: _primaryColor,  // Primary Color
    secondary: _secondaryColor,  // Secondary Color
    tertiary: const Color(0xFFFFBB38), // Warning Color
    tertiaryContainer: const Color(0xFFADC9F3),
    onTertiaryContainer: const Color(0xFF04BB7B), // Success Color
    onPrimary: const Color(0xFF7FBBFF),
    surface: const Color(0xFFF4F8FF),
    onSecondary: secondaryColor ?? const Color(0xFFF88030),
    error: const Color(0xFFFF4040), // Danger Color
    onSecondaryContainer: const Color(0xFFF3F9FF),
    outline: const Color(0xff5C8FFC), // Info Color
    onTertiary: const Color(0xFFE9F3FF),
    shadow: const Color(0xFF66717C),

    primaryContainer: const Color(0xFF9AECC6),
    secondaryContainer: const Color(0xFFE9EEF4),
  ),

  pageTransitionsTheme: const PageTransitionsTheme(builders: {
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
    TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
  }),
);
