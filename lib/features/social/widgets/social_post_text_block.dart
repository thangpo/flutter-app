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

  bool _canUseBackground(PostBackgroundPreset? preset) {
    if (preset == null) return false;
    if ((post.videoUrl ?? '').isNotEmpty) return false;
    if ((post.fileUrl ?? '').isNotEmpty) return false;
    if ((post.audioUrl ?? '').isNotEmpty) return false;
    if ((post.pollOptions?.isNotEmpty ?? false)) return false;
    if (post.sharedPost != null) return false;
    if (post.hasProduct) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasText) return const SizedBox.shrink();
    final SocialController controller = context.watch<SocialController>();
    final String formatted = MentionFormatter.decorate(
      post.text!,
      controller,
      mentions: post.mentions,
    );
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final PostBackgroundPreset? preset =
        controller.findBackgroundPreset(post.backgroundColorId);
    final String? bgId = post.backgroundColorId;
    if (preset == null && bgId != null && bgId.isNotEmpty) {
      controller.ensureBackgroundPreset(bgId);
    }
    final bool hasBackground = _canUseBackground(preset);
    final Widget richText = hasBackground
        ? _buildBackgroundText(context, formatted, preset!)
        : _buildPlainText(context, formatted, onSurface, TextAlign.start);
    if (hasBackground) {
      return MediaQuery.removePadding(
        context: context,
        removeLeft: true,
        removeRight: true,
        child: richText,
      );
    } else {
      return Padding(padding: padding, child: richText);
    }
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

  Widget _buildBackgroundText(
    BuildContext context,
    String data,
    PostBackgroundPreset preset,
  ) {
    final int len = post.text!.trim().length;

    // font + padding như bạn đã đặt
    final double fontSize;
    final double verticalPadding;
    if (len <= 80) {
      fontSize = compact ? 20 : 26;
      verticalPadding = compact ? 48 : 64;
    } else if (len <= 180) {
      fontSize = compact ? 18 : 22;
      verticalPadding = compact ? 40 : 52;
    } else if (len <= 300) {
      fontSize = compact ? 16 : 20;
      verticalPadding = compact ? 28 : 40;
    } else {
      fontSize = compact ? 14 : 18;
      verticalPadding = compact ? 24 : 32;
    }

    // Tỉ lệ “như ảnh”
    // - Rất ngắn: vuông 1:1
    // - Trung bình: 4:5 (0.8)
    // - Dài: không ép (chỉ còn padding dọc)
    double aspectFactor = 1.0;
    // if (len <= 80) {
    //   aspectFactor = 1.0; // vuông
    // } else if (len <= 180) {
    //   aspectFactor = 0.8; // 4:5
    // } else {
    //   aspectFactor = 0.0; // không ép minHeight
    // }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double minH = aspectFactor > 0 ? width * aspectFactor : 0;

        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: double.infinity,
            minHeight: minH, // <-- chiều cao mặc định “như ảnh”
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: 0,
              vertical: verticalPadding,
            ),
            decoration: preset.decoration(),
            alignment: Alignment.center, // canh giữa theo chiều dọc
            child: Html(
              data: data,
              style: {
                'body': Style(
                  color: preset.textColor,
                  fontSize: FontSize(fontSize),
                  lineHeight: LineHeight(1.4),
                  margin: Margins.zero,
                  padding: HtmlPaddings.symmetric(horizontal: 20),
                  textAlign: TextAlign.center,
                  fontWeight: FontWeight.w600,
                  // (tuỳ chọn) hạn chế độ rộng nội dung để chữ không quá dài
                  // maxLines: null,
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
                  await MentionFormatter.handleMentionTap(context, url);
                  return;
                }
                final Uri uri = Uri.parse(url);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
          ),
        );
      },
    );
  }
}
