import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/post_mention.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/profile_screen.dart';

class MentionFormatter {
  static final RegExp _idPattern = RegExp(r'@\[(\d+)\]');
  static final RegExp _usernamePattern =
      RegExp(r'(^|[\s>])@([A-Za-z0-9_.]{3,})');

  // SỬA Ở ĐÂY: dùng raw string với dấu nháy kép
  static final RegExp _userPopoverPattern = RegExp(
    '''<span[^>]*class=["'][^"']*user-popover[^"']*["'][^>]*data-id=["'](\\d+)["'][^>]*>(.*?)</span>''',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _hashSpanPattern = RegExp(
    '''<span[^>]*class=["'][^"']*hash[^"']*["'][^>]*onclick=["'][^"']*user_id[^0-9]*?(\\d+)[^>]*>(.*?)</span>''',
    caseSensitive: false,
    dotAll: true,
  );

  static const HtmlEscape _htmlEscape = HtmlEscape();

  static String decorate(
    String input,
    SocialController controller, {
    List<PostMention> mentions = const <PostMention>[],
  }) {
    if (input.isEmpty ||
        input.contains('mention-id://') ||
        input.contains('mention-name://')) {
      return input;
    }
    final Map<String, PostMention> mentionById = <String, PostMention>{};
    final Map<String, PostMention> mentionByUsername =
        <String, PostMention>{};
    for (final PostMention mention in mentions) {
      if (mention.id.isNotEmpty) {
        mentionById[mention.id] = mention;
      }
      final String? username = mention.username?.toLowerCase();
      if (username != null && username.isNotEmpty) {
        mentionByUsername[username] = mention;
      }
    }

    for (final PostMention mention in mentions) {
      if (mention.id.isEmpty) continue;
      final String? username = mention.username;
      if (username == null || username.isEmpty) continue;
      if (controller.getCachedUserById(mention.id) != null) continue;
      controller.rememberUser(
        SocialUser(
          id: mention.id,
          userName: username,
          displayName: mention.label,
        ),
      );
    }

    String result = _convertMentionSpans(
      input,
      mentionById,
    );

    result = result.replaceAllMapped(_idPattern, (Match match) {
      final String id = match.group(1)!;
      final PostMention? mention = mentionById[id];
      final String? cachedLabel = controller.getCachedMentionLabelById(id);
      final String label = _buildLabel(
        cachedLabel ?? mention?.label,
        fallback: mention?.username ?? 'user$id',
        prependAt: true,
      );
      final String escapedLabel = _htmlEscape.convert(label);
      return '<a class="tagged-user" href="mention-id://$id">$escapedLabel</a>';
    });

    result = result.replaceAllMapped(_usernamePattern, (Match match) {
      final String prefix = match.group(1)!;
      final String username = match.group(2)!;
      final SocialUser? cached = controller.getCachedUserByUsername(username);
      String? label;
      if (cached != null && cached.userName?.isNotEmpty == true) {
        label = '@${cached.userName}';
      } else {
        final PostMention? mention =
            mentionByUsername[username.toLowerCase()];
        label = _buildLabel(
          mention?.label,
          fallback: username,
          prependAt: true,
        );
      }
      final String escapedLabel = _htmlEscape.convert(label);
      final String encodedUsername = Uri.encodeComponent(username);
      return '$prefix<a class="tagged-user" href="mention-name://$encodedUsername">$escapedLabel</a>';
    });

    return result;
  }

  static String _convertMentionSpans(
    String input,
    Map<String, PostMention> mentionById,
  ) {
    String result = input.replaceAllMapped(_userPopoverPattern, (Match match) {
      final String id = match.group(1)!;
      final String inner = match.group(2) ?? '';
      final PostMention? mention = mentionById[id];
      final String label = _buildLabel(
        mention?.label ?? _stripHtml(inner).replaceAll('&nbsp;', ' ').trim(),
        fallback: mention?.username ?? 'user$id',
        prependAt: true,
      );
      final String escapedLabel = _htmlEscape.convert(label);
      return '<a class="tagged-user" href="mention-id://$id">$escapedLabel</a>';
    });

    result = result.replaceAllMapped(_hashSpanPattern, (Match match) {
      final String id = match.group(1)!;
      final String inner = match.group(2) ?? '';
      final PostMention? mention = mentionById[id];
      final String label = _buildLabel(
        mention?.label ?? _stripHtml(inner).replaceAll('&nbsp;', ' ').trim(),
        fallback: mention?.username ?? 'user$id',
        prependAt: true,
      );
      final String escapedLabel = _htmlEscape.convert(label);
      return '<a class="tagged-user" href="mention-id://$id">$escapedLabel</a>';
    });

    return result;
  }

  static String _buildLabel(
    String? preferred, {
    required String fallback,
    bool prependAt = false,
  }) {
    String label = (preferred ?? '').replaceAll('&nbsp;', ' ').trim();
    if (label.isEmpty) {
      label = fallback;
    }
    if (prependAt &&
        !label.startsWith('@') &&
        !label.contains(' ')) {
      label = '@$label';
    }
    return label;
  }

  static String _stripHtml(String source) {
    if (source.isEmpty) return source;
    return source.replaceAll(RegExp(r'<[^>]+>'), '');
  }

  static bool isMentionLink(String url) {
    return url.startsWith('mention-id://') || url.startsWith('mention-name://');
  }

  static Future<void> handleMentionTap(
    BuildContext context,
    String url,
  ) async {
    final SocialController controller = context.read<SocialController>();
    SocialUser? user;

    if (url.startsWith('mention-id://')) {
      final String id = url.substring('mention-id://'.length);
      user = await controller.resolveUserById(id);
    } else if (url.startsWith('mention-name://')) {
      final String encoded = url.substring('mention-name://'.length);
      final String username = Uri.decodeComponent(encoded);
      user = await controller.resolveUserByUsername(username);
    }

    if (user == null) {
      showCustomSnackBar(
        'Unable to open profile at the moment.',
        context,
        isError: true,
      );
      return;
    }

    final SocialUser resolved = user;
    controller.rememberUser(resolved);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(targetUserId: resolved.id),
      ),
    );
  }
}
