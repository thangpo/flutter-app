import 'package:flutter/material.dart';

class PostBackgroundPreset {
  final String id;
  final List<Color> colors;
  final Alignment begin;
  final Alignment end;
  final Color textColor;

  const PostBackgroundPreset({
    required this.id,
    required this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.textColor = Colors.white,
  });

  LinearGradient get gradient => LinearGradient(
        colors: colors,
        begin: begin,
        end: end,
      );
}

class PostBackgroundPresets {
  static const List<PostBackgroundPreset> presets = <PostBackgroundPreset>[
    PostBackgroundPreset(
      id: '1',
      colors: <Color>[
        Color(0xFFFF9A9E),
        Color(0xFFFAD0C4),
      ],
      textColor: Colors.white,
    ),
    PostBackgroundPreset(
      id: '2',
      colors: <Color>[
        Color(0xFFA18CD1),
        Color(0xFFFBC2EB),
      ],
      textColor: Colors.white,
    ),
    PostBackgroundPreset(
      id: '3',
      colors: <Color>[
        Color(0xFFF6D365),
        Color(0xFFFDA085),
      ],
      textColor: Color(0xFF522306),
    ),
    PostBackgroundPreset(
      id: '4',
      colors: <Color>[
        Color(0xFF84FAB0),
        Color(0xFF8FD3F4),
      ],
      textColor: Color(0xFF003E41),
    ),
    PostBackgroundPreset(
      id: '5',
      colors: <Color>[
        Color(0xFF89F7FE),
        Color(0xFF66A6FF),
      ],
      textColor: Color(0xFF012840),
    ),
    PostBackgroundPreset(
      id: '6',
      colors: <Color>[
        Color(0xFFD4FC79),
        Color(0xFF96E6A1),
      ],
      textColor: Color(0xFF1A3A00),
    ),
    PostBackgroundPreset(
      id: '7',
      colors: <Color>[
        Color(0xFFFFE29F),
        Color(0xFFFF719A),
      ],
      textColor: Colors.white,
    ),
    PostBackgroundPreset(
      id: '8',
      colors: <Color>[
        Color(0xFFB8C6DB),
        Color(0xFFF5F7FA),
      ],
      textColor: Color(0xFF1D1D1D),
    ),
    PostBackgroundPreset(
      id: '9',
      colors: <Color>[
        Color(0xFFFBAB7E),
        Color(0xFFF7CE68),
      ],
      textColor: Color(0xFF4B2500),
    ),
    PostBackgroundPreset(
      id: '10',
      colors: <Color>[
        Color(0xFF74EBD5),
        Color(0xFFACB6E5),
      ],
      textColor: Color(0xFF0E2E3C),
    ),
  ];

  static PostBackgroundPreset? findById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final PostBackgroundPreset preset in presets) {
      if (preset.id == id) return preset;
    }
    return null;
  }
}
