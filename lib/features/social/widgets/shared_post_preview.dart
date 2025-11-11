import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/social_feeling_helper.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/widgets/social_post_media.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/widgets/social_post_text_block.dart';

class SharedPostPreviewCard extends StatelessWidget {
  final SocialPost post;
  final EdgeInsetsGeometry? padding;
  final bool compact;
  final VoidCallback? onTap;
  final String? parentPostId;
  const SharedPostPreviewCard({
    super.key,
    required this.post,
    this.padding,
    this.compact = false,
    this.onTap,
    this.parentPostId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final avatar = post.userAvatar;
    final EdgeInsetsGeometry resolvedPadding =
        padding ?? const EdgeInsets.all(12);
    final String? location = post.postMap?.trim();
    final bool hasLocation = location != null && location.isNotEmpty;
    final SocialPost mediaPost = (parentPostId == null)
        ? post.copyWith(id: '${post.id}_shared_${hashCode}')
        : post.copyWith(id: '${post.id}_shared_${parentPostId!}');
    final Widget? media = buildSocialPostMedia(
      context,
      mediaPost,
      compact: true,
    );

    final BorderRadius borderRadius = BorderRadius.circular(12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(.3),
            borderRadius: borderRadius,
            border: Border.all(color: theme.dividerColor.withOpacity(.4)),
          ),
          padding: resolvedPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: compact ? 16 : 20,
                    backgroundColor: theme.colorScheme.surface,
                    backgroundImage: (avatar != null && avatar.isNotEmpty)
                        ? CachedNetworkImageProvider(avatar)
                        : null,
                    child: (avatar == null || avatar.isEmpty)
                        ? Text(
                            (post.userName?.isNotEmpty ?? false)
                                ? post.userName![0].toUpperCase()
                                : '?',
                            style: TextStyle(color: onSurface),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userName ?? '',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if ((post.timeText ?? '').isNotEmpty)
                          Text(
                            post.timeText!,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: onSurface.withOpacity(.6)),
                          ),
                        if (hasLocation)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.place_outlined,
                                size: compact ? 14 : 16,
                                color: onSurface.withOpacity(.65),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: onSurface.withOpacity(.75),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (SocialFeelingHelper.hasFeeling(post)) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Builder(builder: (context) {
                      final String? emoji =
                          SocialFeelingHelper.emojiForPost(post);
                      if (emoji != null) {
                        return Text(
                          emoji,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontSize: compact ? 18 : 20),
                        );
                      }
                      return Icon(
                        SocialFeelingHelper.iconForPost(post),
                        size: compact ? 16 : 18,
                        color: theme.colorScheme.primary,
                      );
                    }),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        SocialFeelingHelper.labelForPost(context, post) ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: compact ? 13 : 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if ((post.text ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                SocialPostTextBlock(
                  post: post,
                  padding: EdgeInsets.zero,
                  compact: compact,
                ),
              ],
              if (post.pollOptions != null && post.pollOptions!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final opt in post.pollOptions!) ...[
                        Text(opt['text']?.toString() ?? ''),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (((double.tryParse(
                                            (opt['percentage_num'] ?? '0')
                                                .toString()) ??
                                        0.0) /
                                    100.0))
                                .clamp(0, 1),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              if (media != null) ...[
                const SizedBox(height: 4),
                media,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
