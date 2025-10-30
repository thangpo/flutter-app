import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_group.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:intl/intl.dart';

class SocialGroupCard extends StatelessWidget {
  final SocialGroup group;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onManage;
  final bool joining;

  const SocialGroupCard({
    super.key,
    required this.group,
    this.onTap,
    this.onJoin,
    this.onManage,
    this.joining = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final joined = group.isJoined;
    final isAdmin = group.isAdmin;
    final pendingApproval = !joined && group.requiresApproval;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? Color.alphaBlend(
                    Colors.white.withValues(alpha: .02), colorScheme.surface)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withValues(
                alpha: theme.brightness == Brightness.dark ? .3 : .12,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GroupThumbnail(
                  avatarUrl: group.avatarUrl,
                  coverUrl: group.coverUrl,
                  fallbackColor: _randomColorFromName(group.name),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.title ?? group.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _metaDescription(context),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.textTheme.bodySmall?.color?.withValues(
                                    alpha: .7,
                                  ),
                        ),
                      ),
                      if ((group.about ?? group.description)
                              ?.trim()
                              .isNotEmpty ??
                          false) ...[
                        const SizedBox(height: 8),
                        Text(
                          (group.about ?? group.description)!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: .8),
                          ),
                        ),
                      ],
                      if (pendingApproval) ...[
                        const SizedBox(height: 8),
                        Text(
                          getTranslated('join_group_pending', context) ??
                              'Join request pending approval',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.tertiary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _GroupActionButton(
                            isAdmin: isAdmin,
                            joined: joined,
                            joining: joining,
                            onJoin: onJoin,
                            onManage: onManage ?? onTap,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: .4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _metaDescription(BuildContext context) {
    final membersLabel = getTranslated('group_members', context) ?? 'members';
    final postsPerDayLabel =
        getTranslated('posts_per_day', context) ?? 'posts/day';
    final parts = <String>[];

    if (group.privacy != null && group.privacy!.isNotEmpty) {
      parts.add(group.privacy!);
    }
    parts.add('${_formatCount(group.memberCount)} $membersLabel');

    final posts = _postsPerDay();
    if (posts != null) {
      parts.add('$posts $postsPerDayLabel');
    }

    return parts.join(' · ');
  }

  String? _postsPerDay() {
    final dynamic raw = group.customFields['posts_per_day'] ??
        group.customFields['postsPerDay'] ??
        group.customFields['daily_posts'] ??
        group.customFields['dailyPosts'];
    if (raw == null) {
      return null;
    }

    double? value;
    if (raw is num) {
      value = raw.toDouble();
    } else {
      value = double.tryParse(raw.toString());
    }
    if (value == null || value <= 0) {
      return null;
    }

    final formatter = NumberFormat.compact();
    return formatter.format(value);
  }

  Color _randomColorFromName(String input) {
    final seed = input.hashCode;
    final rnd = Random(seed);
    final hue = rnd.nextDouble();
    return HSVColor.fromAHSV(1, hue * 360, .55, .85).toColor();
  }

  String _formatCount(int count) {
    final formatter = NumberFormat.compact();
    return formatter.format(count);
  }
}

class _GroupThumbnail extends StatelessWidget {
  final String? avatarUrl;
  final String? coverUrl;
  final Color fallbackColor;

  const _GroupThumbnail({
    required this.avatarUrl,
    required this.coverUrl,
    required this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl =
        (avatarUrl != null && avatarUrl!.isNotEmpty) ? avatarUrl : coverUrl;

    Widget placeholder() => Container(
          decoration: BoxDecoration(
            color: fallbackColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.groups_rounded,
            color: theme.colorScheme.onPrimary.withValues(alpha: .8),
            size: 32,
          ),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        height: 72,
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => placeholder(),
                errorWidget: (_, __, ___) => placeholder(),
              )
            : placeholder(),
      ),
    );
  }
}

class _GroupActionButton extends StatelessWidget {
  final bool isAdmin;
  final bool joined;
  final bool joining;
  final VoidCallback? onJoin;
  final VoidCallback? onManage;

  const _GroupActionButton({
    required this.isAdmin,
    required this.joined,
    required this.joining,
    required this.onJoin,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(999);

    if (isAdmin && onManage != null) {
      return FilledButton(
        onPressed: onManage,
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
        child:
            Text(getTranslated('manage_group', context) ?? 'Manage'),
      );
    }

    if (joined) {
      return OutlinedButton(
        onPressed: onManage,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          side: BorderSide(
            color: theme.dividerColor.withValues(alpha: .35),
          ),
        ),
        child: Text(getTranslated('view_group', context) ?? 'View group'),
      );
    }

    if (onJoin == null) {
      return const SizedBox.shrink();
    }

    return TextButton(
      onPressed: joining ? null : onJoin,
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      child: joining
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            )
          : Text(getTranslated('join_group', context) ?? 'Join group'),
    );
  }
}
