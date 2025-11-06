import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/mention_formatter.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/post_background_presets.dart';

class SocialPostTextBlock extends StatelessWidget {
  final SocialPost post;
  final EdgeInsetsGeometry padding;
  final bool compact;

  const SocialPostTextBlock({
    super.key,
    required this.post,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.compact = false,
  });

  bool get _hasText => (post.text ?? '').trim().isNotEmpty;

  bool get _hasBackground =>
      PostBackgroundPresets.findById(post.backgroundColorId) != null &&
      post.imageUrls.isEmpty &&
      (post.videoUrl == null || post.videoUrl!.isEmpty) &&
      (post.fileUrl == null || post.fileUrl!.isEmpty) &&
      (post.audioUrl == null || post.audioUrl!.isEmpty) &&
      post.pollOptions == null &&
      post.sharedPost == null &&
      post.hasProduct == false;

  @override
  Widget build(BuildContext context) {
    if (!_hasText) return const SizedBox.shrink();
    final SocialController controller = context.read<SocialController>();
    final String formatted = MentionFormatter.decorate(
      post.text!,
      controller,
      mentions: post.mentions,
    );
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Widget richText = _hasBackground
        ? _buildBackgroundText(context, formatted)
        : _buildPlainText(context, formatted, onSurface, TextAlign.start);
    return Padding(
      padding: padding,
      child: richText,
    );
  }

  Widget _buildPlainText(
    BuildContext context,
    String data,
    Color textColor,
    TextAlign align,
  ) {
    final double fontSize = compact ? 14 : 15;
    return Html(
      data: data,
      style: {
        'body': Style(
          color: textColor,
          fontSize: FontSize(fontSize),
          lineHeight: LineHeight(1.35),
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          textAlign: align,
        ),
        'a.tagged-user': Style(
          color: textColor,
          fontWeight: FontWeight.w600,
          textDecoration: TextDecoration.none,
        ),
      },
      onLinkTap: (String? url, _, __) async {
        if (url == null) return;
        if (MentionFormatter.isMentionLink(url)) {
          await MentionFormatter.handleMentionTap(
            context,
            url,
          );
          return;
        }
        final Uri uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
    );
  }

  Widget _buildBackgroundText(BuildContext context, String data) {
    final PostBackgroundPreset preset =
        PostBackgroundPresets.findById(post.backgroundColorId)!;
    final int textLength = post.text!.trim().length;
    final bool dense = textLength > 240;
    final double fontSize = dense
        ? (compact ? 16 : 18)
        : (compact ? 18 : 22);
    final double verticalPadding = dense ? 28 : 36;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        gradient: preset.gradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Html(
        data: data,
        style: {
          'body': Style(
            color: preset.textColor,
            fontSize: FontSize(fontSize),
            lineHeight: LineHeight(1.4),
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            textAlign: TextAlign.center,
            fontWeight: FontWeight.w600,
          ),
          'a.tagged-user': Style(
            color: preset.textColor,
            fontWeight: FontWeight.w700,
            textDecoration: TextDecoration.none,
          ),
        },
        onLinkTap: (String? url, _, __) async {
          if (url == null) return;
          if (MentionFormatter.isMentionLink(url)) {
            await MentionFormatter.handleMentionTap(
              context,
              url,
            );
            return;
          }
          final Uri uri = Uri.parse(url);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
      ),
    );
  }
}
