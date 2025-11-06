class SocialFeelingType {
  static const String feelings = 'feelings';
  static const String traveling = 'traveling';
  static const String watching = 'watching';
  static const String playing = 'playing';
  static const String listening = 'listening';

  static const List<String> values = <String>[
    feelings,
    traveling,
    watching,
    playing,
    listening,
  ];

  static bool contains(String? type) {
    if (type == null || type.isEmpty) return false;
    return values.contains(type);
  }
}

class SocialFeelingConstants {
  static const Map<String, String> feelingIconNames = <String, String>{
    'happy': 'smile',
    'loved': 'heart-eyes',
    'sad': 'disappointed',
    'so_sad': 'sob',
    'angry': 'angry',
    'confused': 'confused',
    'smirk': 'smirk',
    'broke': 'broken-heart',
    'expressionless': 'expressionless',
    'cool': 'sunglasses',
    'funny': 'joy',
    'tired': 'tired-face',
    'lovely': 'heart',
    'blessed': 'innocent',
    'shocked': 'scream',
    'sleepy': 'sleeping',
    'pretty': 'relaxed',
    'bored': 'unamused',
  };

  static const Map<String, String> feelingEmoji = <String, String>{
    'happy': '😊',
    'loved': '😍',
    'sad': '😢',
    'so_sad': '😭',
    'angry': '😠',
    'confused': '😕',
    'smirk': '😏',
    'broke': '💔',
    'expressionless': '😑',
    'cool': '😎',
    'funny': '😂',
    'tired': '😫',
    'lovely': '🥰',
    'blessed': '😇',
    'shocked': '😱',
    'sleepy': '😴',
    'pretty': '😊',
    'bored': '😒',
  };

  static const Map<String, String> feelingDefaultLabels = <String, String>{
    'happy': 'Happy',
    'loved': 'Loved',
    'sad': 'Sad',
    'so_sad': 'So Sad',
    'angry': 'Angry',
    'confused': 'Confused',
    'smirk': 'Smirk',
    'broke': 'Broke',
    'expressionless': 'Expressionless',
    'cool': 'Cool',
    'funny': 'Funny',
    'tired': 'Tired',
    'lovely': 'Lovely',
    'blessed': 'Blessed',
    'shocked': 'Shocked',
    'sleepy': 'Sleepy',
    'pretty': 'Pretty',
    'bored': 'Bored',
  };

  static String? labelForFeeling(String? value) {
    final String? normalized = _normalizeValue(value);
    if (normalized == null) return null;
    final String? mapped = feelingDefaultLabels[normalized];
    if (mapped != null && mapped.isNotEmpty) {
      return mapped;
    }
    return _humanize(normalized);
  }

  static String? iconNameForFeeling(String? value) {
    final String? normalized = _normalizeValue(value);
    if (normalized == null) return null;
    final String? mapped = feelingIconNames[normalized];
    if (mapped != null && mapped.isNotEmpty) {
      return mapped;
    }
    return null;
  }

  static String? emojiForFeeling(String? value) {
    final String? normalized = _normalizeValue(value);
    if (normalized == null) return null;
    final String? emoji = feelingEmoji[normalized];
    if (emoji != null && emoji.isNotEmpty) {
      return emoji;
    }
    return null;
  }

  static String? _normalizeValue(String? raw) {
    if (raw == null) return null;
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.toLowerCase();
  }

  static String _humanize(String value) {
    final String cleaned =
        value.replaceAll(RegExp(r'[_\-\s]+'), ' ').trim().toLowerCase();
    if (cleaned.isEmpty) return value;
    final List<String> parts = cleaned
        .split(' ')
        .where((String part) => part.isNotEmpty)
        .map((String word) =>
            word[0].toUpperCase() + (word.length > 1 ? word.substring(1) : ''))
        .toList();
    if (parts.isEmpty) return value;
    return parts.join(' ');
  }
}
