import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/event_controller.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_event.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/event_detail_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/widgets/social_event_attachment_card.dart';

/// Loader hiển thị card sự kiện trong post (giống FB)
/// - Tự parse eventId từ link /events/{id}
/// - Gọi API lấy đầy đủ SocialEvent
/// - Khi chưa load xong vẫn hiển thị placeholder
class SocialEventAttachmentLoader extends StatefulWidget {
  final String eventId;
  final SocialEvent? initialEvent;

  const SocialEventAttachmentLoader({
    super.key,
    required this.eventId,
    this.initialEvent,
  });

  @override
  State<SocialEventAttachmentLoader> createState() =>
      _SocialEventAttachmentLoaderState();
}

class _SocialEventAttachmentLoaderState
    extends State<SocialEventAttachmentLoader> {
  SocialEvent? _event;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _event = widget.initialEvent;
    _loadIfNeeded();
  }

  Future<void> _loadIfNeeded() async {
    if (_event != null || _loading) return;
    _loading = true;
    try {
      final evc = context.read<EventController>();

      /// Future<SocialEvent?> getEventById(String id)
      final SocialEvent? ev = await evc.fetchEventById(widget.eventId);

      if (!mounted) return;
      if (ev != null) {
        setState(() => _event = ev);
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nếu chưa load được thì dựng 1 event stub để card có text
    final SocialEvent baseEvent = _event ??
        SocialEvent(
          id: widget.eventId,
          name: _loading ? 'Đang tải sự kiện...' : 'Sự kiện',
          location: null,
          description: null,
          startDate: null,
          startTime: null,
          endDate: null,
          endTime: null,
          posterId: null,
          cover: null,
          user: null,
          isOwner: false,
          isGoing: false,
          isInterested: false,
          isInvited: false,
          isPast: false,
          userId: null,
          startEditDate: null,
          startDateJs: null,
          endEditDate: null,
          url: null,
        );

    return SocialEventAttachmentCard(
      event: baseEvent,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(
              eventId: (baseEvent.id ?? widget.eventId).toString(),
              initialEvent: _event,
            ),
          ),
        );
      },
    );
  }
}

/// Helper parse eventId từ SocialPost (từ rawText/text)
String? extractEventIdFromPost(SocialPost post) {
  final String source = (post.rawText?.isNotEmpty ?? false)
      ? post.rawText!
      : (post.text ?? '');

  if (source.isEmpty) return null;

  final RegExp re = RegExp(r'/events/(\d+)', caseSensitive: false);
  final Match? match = re.firstMatch(source);
  if (match == null) return null;

  return match.group(1); // ví dụ "7"
}
