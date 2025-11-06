import 'package:flutter/material.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/social_feeling_constants.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

class SocialFeelingCategoryOption {
  final String type;
  final IconData icon;
  final String labelKey;
  final String defaultLabel;

  const SocialFeelingCategoryOption({
    required this.type,
    required this.icon,
    required this.labelKey,
    required this.defaultLabel,
  });
}

class SocialFeelingOption {
  final String value;
  final String label;

  const SocialFeelingOption({
    required this.value,
    required this.label,
  });
}

const List<SocialFeelingCategoryOption> socialFeelingCategories =
    <SocialFeelingCategoryOption>[
  SocialFeelingCategoryOption(
    type: SocialFeelingType.feelings,
    icon: Icons.emoji_emotions_outlined,
    labelKey: 'feeling_category_feelings',
    defaultLabel: 'Feeling',
  ),
  SocialFeelingCategoryOption(
    type: SocialFeelingType.traveling,
    icon: Icons.flight_takeoff,
    labelKey: 'feeling_category_traveling',
    defaultLabel: 'Traveling',
  ),
  SocialFeelingCategoryOption(
    type: SocialFeelingType.watching,
    icon: Icons.tv,
    labelKey: 'feeling_category_watching',
    defaultLabel: 'Watching',
  ),
  SocialFeelingCategoryOption(
    type: SocialFeelingType.playing,
    icon: Icons.sports_esports_outlined,
    labelKey: 'feeling_category_playing',
    defaultLabel: 'Playing',
  ),
  SocialFeelingCategoryOption(
    type: SocialFeelingType.listening,
    icon: Icons.headphones,
    labelKey: 'feeling_category_listening',
    defaultLabel: 'Listening',
  ),
];

const List<String> _orderedFeelingValues = <String>[
  'happy',
  'loved',
  'sad',
  'so_sad',
  'angry',
  'confused',
  'smirk',
  'broke',
  'expressionless',
  'cool',
  'funny',
  'tired',
  'lovely',
  'blessed',
  'shocked',
  'sleepy',
  'pretty',
  'bored',
];

final List<SocialFeelingOption> socialFeelingOptions =
    _orderedFeelingValues.map((String value) {
  final String label = SocialFeelingConstants.labelForFeeling(value) ?? value;
  return SocialFeelingOption(value: value, label: label);
}).toList(growable: false);

class SocialFeelingHelper {
  static bool hasSelection(String? type, String? value) {
    if (type == null || value == null) return false;
    if (!SocialFeelingType.contains(type)) return false;
    return value.trim().isNotEmpty;
  }

  static bool hasFeeling(SocialPost post) {
    return hasSelection(post.feelingType, post.feelingValue);
  }

  static SocialFeelingCategoryOption _categoryOrDefault(String type) {
    return socialFeelingCategories.firstWhere(
      (SocialFeelingCategoryOption option) => option.type == type,
      orElse: () => socialFeelingCategories.first,
    );
  }

  static IconData iconForType(String type) {
    switch (type) {
      case SocialFeelingType.traveling:
        return Icons.flight_takeoff;
      case SocialFeelingType.watching:
        return Icons.tv;
      case SocialFeelingType.playing:
        return Icons.sports_esports_outlined;
      case SocialFeelingType.listening:
        return Icons.headphones;
      case SocialFeelingType.feelings:
      default:
        return Icons.emoji_emotions_outlined;
    }
  }

  static IconData iconForPost(SocialPost post) {
    final String type = post.feelingType ?? SocialFeelingType.feelings;
    return iconForType(type);
  }

  static String? emojiForValue(String? type, String? value) {
    if (type != SocialFeelingType.feelings) return null;
    return SocialFeelingConstants.emojiForFeeling(value);
  }

  static String? emojiForPost(SocialPost post) {
    return emojiForValue(post.feelingType, post.feelingValue);
  }

  static String categoryLabel(BuildContext context, String type) {
    final SocialFeelingCategoryOption option = _categoryOrDefault(type);
    final String? translated = getTranslated(option.labelKey, context);
    if (translated != null && translated.trim().isNotEmpty) {
      return translated.trim();
    }
    return option.defaultLabel;
  }

  static String valueLabel(String type, String value) {
    final String trimmed = value.trim();
    if (type == SocialFeelingType.feelings) {
      return SocialFeelingConstants.labelForFeeling(trimmed) ?? trimmed;
    }
    return trimmed;
  }

  static String buildLabel(
    BuildContext context,
    String type,
    String value,
  ) {
    final String category = categoryLabel(context, type);
    final String display = valueLabel(type, value);
    return '$category - $display';
  }

  static String? labelForPost(BuildContext context, SocialPost post) {
    final String? type = post.feelingType;
    final String? value = post.feelingValue;
    if (!hasSelection(type, value)) return null;
    return buildLabel(context, type!, value!);
  }

  static String? iconNameForPost(SocialPost post) {
    if (post.feelingType != SocialFeelingType.feelings) {
      return null;
    }
    return SocialFeelingConstants.iconNameForFeeling(post.feelingValue);
  }
}
