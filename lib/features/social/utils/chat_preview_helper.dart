import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

String normalizeChatPreview(String raw, BuildContext context) {
  if (raw.isEmpty) return raw;

  final decoded = raw
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&amp;', '&');

  try {
    final data = jsonDecode(decoded);

    if (data is Map<String, dynamic>) {
      final type = data['type'];
      final callType = data['call_type'];

      if (type == 'call_invite') {
        return callType == 'video'
            ? '🎥 ${getTranslated('call_video', context) ?? 'Video call'}'
            : '📞 ${getTranslated('call_audio', context) ?? 'Voice call'}';
      }

      if (type == 'call_end') {
        return callType == 'video'
            ? '🎥 ${getTranslated('call_video_ended', context) ?? 'Video call ended'}'
            : '📞 ${getTranslated('call_audio_ended', context) ?? 'Voice call ended'}';
      }

      if (type == 'call_missed') {
        return '📞 ${getTranslated('call_missed', context) ?? 'Missed call'}';
      }
    }
  } catch (_) {

  }

  return raw;
}