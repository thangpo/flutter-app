import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

String normalizeChatPreview(String raw, BuildContext context) {
  if (raw.isEmpty) return raw;

  final decoded = raw
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&amp;', '&')
      .trim();

  try {
    final data = jsonDecode(decoded);

    if (data is Map<String, dynamic>) {
      final type = (data['type'] ?? '').toString().toLowerCase();
      final mediaRaw = data['media'];
      final callTypeRaw = data['call_type'] ?? data['callType'] ?? data['call'] ?? data['is_video'];
      final media = (mediaRaw ?? '').toString().toLowerCase();
      final callType = (callTypeRaw ?? '').toString().toLowerCase();

      final isVideo =
          media == 'video' ||
              callType == 'video' ||
              callType == 'video_call' ||
              callType == 'videocall' ||
              callType == '1' ||
              callType == 'true' ||
              callTypeRaw == 1 ||
              callTypeRaw == true;

      switch (type) {
        case 'call_invite':
          return isVideo
              ? '🎥 ${getTranslated('call_video', context) ?? 'Video call'}'
              : '📞 ${getTranslated('call_audio', context) ?? 'Voice call'}';

        case 'call_end':
          return isVideo
              ? '🎥 ${getTranslated('call_video_ended', context) ?? 'Video call ended'}'
              : '📞 ${getTranslated('call_audio_ended', context) ?? 'Voice call ended'}';

        case 'call_missed':
          return isVideo
              ? '🎥 ${getTranslated('call_video_missed', context) ?? 'Missed video call'}'
              : '📞 ${getTranslated('call_missed', context) ?? 'Missed call'}';
      }
    }
  } catch (_) {

  }

  final lower = decoded.toLowerCase();

  if (lower.endsWith('.m4a') ||
      lower.endsWith('.aac') ||
      lower.endsWith('.mp3') ||
      lower.contains('voice_') ||
      lower.contains('audio')) {
    return '🎤 ${getTranslated('voice_message', context) ?? 'Voice message'}';
  }

  if (lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp') ||
      lower.contains('screenshot') ||
      lower.contains('image') ||
      lower.contains('photo')) {
    return '🖼 ${getTranslated('photo', context) ?? 'Photo'}';
  }

  if (lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.avi') ||
      lower.endsWith('.mkv') ||
      lower.contains('video')) {
    return '🎥 ${getTranslated('video', context) ?? 'Video'}';
  }

  if (lower.contains('.pdf') ||
      lower.contains('.doc') ||
      lower.contains('.docx') ||
      lower.contains('.xls') ||
      lower.contains('.zip') ||
      lower.contains('.rar')) {
    return '📎 ${getTranslated('attachment', context) ?? 'File'}';
  }
  return decoded;
}