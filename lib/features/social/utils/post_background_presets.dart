import 'package:flutter/material.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post_color.dart';

class PostBackgroundPreset {
  final String id;
  final Color? color1;
  final Color? color2;
  final Alignment begin;
  final Alignment end;
  final Color textColor;
  final String? imageUrl;

  const PostBackgroundPreset({
    required this.id,
    this.color1,
    this.color2,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.textColor = Colors.white,
    this.imageUrl,
  });

  bool get hasGradient => color1 != null && color2 != null;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  LinearGradient? get gradient => hasGradient
      ? LinearGradient(
          colors: <Color>[color1!, color2!],
          begin: begin,
          end: end,
        )
      : null;

  DecorationImage? get decorationImage => hasImage
      ? DecorationImage(
          image: NetworkImage(imageUrl!),
          fit: BoxFit.cover,
        )
      : null;

  BoxDecoration decoration({
    BorderRadius? borderRadius,
    BoxBorder? border,
  }) =>
      BoxDecoration(
        gradient: gradient,
        image: decorationImage,
        borderRadius: borderRadius,
        border: border,
      );

  static Color? _parseColor(String? value) {
    if (value == null) return null;
    final String input = value.trim();
    if (input.isEmpty || input == 'null') return null;
    if (input.startsWith('#')) {
      String hex = input.substring(1);
      if (hex.length == 3) {
        hex = hex.split('').map((String c) => '$c$c').join();
      }
      if (hex.length == 6) hex = 'ff$hex';
      if (hex.length == 8) {
        final int? parsed = int.tryParse(hex, radix: 16);
        if (parsed != null) {
          return Color(parsed);
        }
      }
      return null;
    }
    final RegExp rgbMatcher = RegExp(r'rgba?\(([^)]+)\)');
    final Match? match = rgbMatcher.firstMatch(input);
    if (match != null) {
      final List<String> parts = match.group(1)!.split(',').map((String part) {
        return part.trim();
      }).toList();
      if (parts.length >= 3) {
        final int? r = int.tryParse(parts[0]);
        final int? g = int.tryParse(parts[1]);
        final int? b = int.tryParse(parts[2]);
        double a = 1;
        if (parts.length == 4) {
          a = double.tryParse(parts[3]) ?? 1;
          if (a > 1) {
            a = a / 255;
          }
        }
        if (r != null && g != null && b != null) {
          return Color.fromARGB(
            (a.clamp(0, 1) * 255).round(),
            r.clamp(0, 255),
            g.clamp(0, 255),
            b.clamp(0, 255),
          );
        }
      }
    }
    return null;
  }

  factory PostBackgroundPreset.fromSocialColor(SocialPostColor color) {
    final Color? colorOne = _parseColor(color.color1);
    final Color? colorTwo =
        _parseColor(color.color2) ?? _parseColor(color.color1);
    final Color text = _parseColor(color.textColor) ?? Colors.white;
    final String? image = (color.imageUrl != null &&
            color.imageUrl!.trim().isNotEmpty)
        ? color.imageUrl
        : null;
    return PostBackgroundPreset(
      id: color.id,
      color1: colorOne,
      color2: colorTwo,
      textColor: text,
      imageUrl: image,
    );
  }
}

class PostBackgroundPresets {
  static const List<PostBackgroundPreset> defaults = <PostBackgroundPreset>[
    PostBackgroundPreset(
      id: '1',
      color1: Color(0xFFFF9A9E),
      color2: Color(0xFFFAD0C4),
      textColor: Colors.white,
    ),
    PostBackgroundPreset(
      id: '2',
      color1: Color(0xFFA18CD1),
      color2: Color(0xFFFBC2EB),
      textColor: Colors.white,
    ),
    PostBackgroundPreset(
      id: '3',
      color1: Color(0xFFF6D365),
      color2: Color(0xFFFDA085),
      textColor: Color(0xFF522306),
    ),
    PostBackgroundPreset(
      id: '4',
      color1: Color(0xFF84FAB0),
      color2: Color(0xFF8FD3F4),
      textColor: Color(0xFF003E41),
    ),
    PostBackgroundPreset(
      id: '5',
      color1: Color(0xFF89F7FE),
      color2: Color(0xFF66A6FF),
      textColor: Color(0xFF012840),
    ),
    PostBackgroundPreset(
      id: '6',
      color1: Color(0xFFD4FC79),
      color2: Color(0xFF96E6A1),
      textColor: Color(0xFF1A3A00),
    ),
    PostBackgroundPreset(
      id: '7',
      color1: Color(0xFFFFE29F),
      color2: Color(0xFFFF719A),
      textColor: Colors.white,
    ),
    PostBackgroundPreset(
      id: '8',
      color1: Color(0xFFB8C6DB),
      color2: Color(0xFFF5F7FA),
      textColor: Color(0xFF1D1D1D),
    ),
    PostBackgroundPreset(
      id: '9',
      color1: Color(0xFFFBAB7E),
      color2: Color(0xFFF7CE68),
      textColor: Color(0xFF4B2500),
    ),
    PostBackgroundPreset(
      id: '10',
      color1: Color(0xFF74EBD5),
      color2: Color(0xFFACB6E5),
      textColor: Color(0xFF0E2E3C),
    ),
  ];

  static List<PostBackgroundPreset> fromRemote(
      List<SocialPostColor> colors) {
    final List<PostBackgroundPreset> presets = <PostBackgroundPreset>[];
    for (final SocialPostColor color in colors) {
      if (color.id.isEmpty) continue;
      final PostBackgroundPreset preset =
          PostBackgroundPreset.fromSocialColor(color);
      if (preset.hasGradient || preset.hasImage) {
        presets.add(preset);
      }
    }
    return presets;
  }

  static PostBackgroundPreset? findById(
      List<PostBackgroundPreset> source, String? id) {
    if (id == null || id.isEmpty) return null;
    for (final PostBackgroundPreset preset in source) {
      if (preset.id == id) return preset;
    }
    return null;
  }
}
