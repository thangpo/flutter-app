import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/profile_screen.dart';

class MentionFormatter {
  static final RegExp _idPattern = RegExp(r'@\[(\d+)\]');
  static final RegExp _usernamePattern =
      RegExp(r'(^|[\s>])@([A-Za-z0-9_.]{3,})');
  static const HtmlEscape _htmlEscape = HtmlEscape();

  static String decorate(String input, SocialController controller) {
    if (input.isEmpty ||
        input.contains('mention-id://') ||
        input.contains('mention-name://')) {
      return input;
    }
    String result = input;

    result = result.replaceAllMapped(_idPattern, (Match match) {
      final String id = match.group(1)!;
      final String? cachedLabel = controller.getCachedMentionLabelById(id);
      final String label = cachedLabel != null ? '@$cachedLabel' : '@user$id';
      final String escapedLabel = _htmlEscape.convert(label);
      return '<a href="mention-id://$id">$escapedLabel</a>';
    });

    result = result.replaceAllMapped(_usernamePattern, (Match match) {
      final String prefix = match.group(1)!;
      final String username = match.group(2)!;
      final SocialUser? cached = controller.getCachedUserByUsername(username);
      final String label = cached != null && cached.userName?.isNotEmpty == true
          ? '@${cached.userName}'
          : '@$username';
      final String escapedLabel = _htmlEscape.convert(label);
      final String encodedUsername = Uri.encodeComponent(username);
      return '$prefix<a href="mention-name://$encodedUsername">$escapedLabel</a>';
    });

    return result;
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
