import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_event.dart';

/// Card dùng riêng cho phần đính kèm SỰ KIỆN trong post
class SocialEventAttachmentCard extends StatelessWidget {
  final SocialEvent event;
  final VoidCallback? onTap;

  const SocialEventAttachmentCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // ----- Title -----
    final String title =
    (event.name != null && event.name!.trim().isNotEmpty)
        ? event.name!.trim()
        : 'Sự kiện';

    // ----- Location & time text -----
    final String location = event.location?.trim() ?? '';

    final String dateText = (() {
      final t = event.timeText;
      if (t != null && t.trim().isNotEmpty) return t.trim();
      final raw = '${event.startDate ?? ''} ${event.startTime ?? ''}'.trim();
      return raw;
    })();

    // Subtitle ưu tiên thời gian -> địa điểm -> fallback
    final String subtitle = dateText.isNotEmpty
        ? dateText
        : (location.isNotEmpty ? location : 'Nhấn để xem chi tiết');

    final String? coverUrl = event.cover;

    Widget content = Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cs.surface,
        border: Border.all(
          color: cs.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Ảnh cover bên trái
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
            child: SizedBox(
              width: 80,
              height: 80,
              child: coverUrl != null && coverUrl.isNotEmpty
                  ? Image.network(
                coverUrl,
                fit: BoxFit.cover,
              )
                  : Container(
                color: cs.primary.withOpacity(0.08),
                child: Icon(
                  Icons.event,
                  color: cs.primary,
                ),
              ),
            ),
          ),

          // Thông tin event bên phải
          Expanded(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Subtitle (thời gian hoặc location)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),

                  // Thời gian chi tiết (nếu có và khác subtitle thì vẫn show)
                  if (dateText.isNotEmpty && dateText != subtitle) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dateText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // Bọc InkWell nếu có onTap
    if (onTap != null) {
      content = InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
