import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_post.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/mention_formatter.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/utils/post_background_presets.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/social_post_full_with_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

class SocialPostTextBlock extends StatefulWidget {
  final SocialPost post;
  final EdgeInsetsGeometry padding;
  final bool compact;

  const SocialPostTextBlock({
    super.key,
    required this.post,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.compact = false,
  });
  @override
  State<SocialPostTextBlock> createState() => _SocialPostTextBlockState();
}

class _SocialPostTextBlockState extends State<SocialPostTextBlock> {
  static const int _seeMoreCharThreshold = 160;
  static const int _collapsedMaxLines = 6;
  bool _expanded = false;
  bool get _hasText => (widget.post.text ?? '').trim().isNotEmpty;
  int get _imageCount =>
      SocialPostFullViewComposer.normalizeImages(widget.post).length;
  bool get _hasAnyImage => _imageCount >= 1;
  String get _plainTextContent {
    final raw = widget.post.text ?? '';
    if (raw.isEmpty) return raw;
    final withoutTags =
        raw.replaceAll(RegExp(r'<[^>]*>', multiLine: true), ' ');
    return withoutTags.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool get _shouldOfferSeeMore =>
      _plainTextContent.length > _seeMoreCharThreshold;

  @override
  Widget build(BuildContext context) {
    if (!_hasText) return const SizedBox.shrink();
    final controller = context.watch<SocialController>();
    final formatted = MentionFormatter.decorate(
      widget.post.text!,
      controller,
      mentions: widget.post.mentions,
    );
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final preset =
        controller.findBackgroundPreset(widget.post.backgroundColorId);
    final bgId = widget.post.backgroundColorId;
    if (preset == null && bgId != null && bgId.isNotEmpty) {
      controller.ensureBackgroundPreset(bgId);
    }
    final backgroundAllowed =
        SocialPostFullViewComposer.allowsBackground(widget.post);
    final hasBackground = backgroundAllowed && preset != null;
    final enforceCompactBackground =
        hasBackground && _hasAnyImage && !_expanded;
    final showSeeMoreButton = enforceCompactBackground && _shouldOfferSeeMore;
    final Widget richText = hasBackground
        ? _buildBackgroundText(
            context,
            formatted,
            preset!,
            limitHeight: enforceCompactBackground,
          )
        : _buildPlainText(context, formatted, onSurface, TextAlign.start);
    if (hasBackground) {
      final backgroundBlock = MediaQuery.removePadding(
        context: context,
        removeLeft: true,
        removeRight: true,
        child: richText,
      );
      final tappableBackground = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => SocialPostFullWithScreen.open(
          context,
          post: widget.post,
          focus: SocialPostFullItemType.background,
        ),
        child: backgroundBlock,
      );
      if (showSeeMoreButton) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tappableBackground,
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  if (_expanded) return;
                  setState(() => _expanded = true);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(getTranslated('see_more', context) ?? 'Xem thêm'),
              ),
            ),
          ],
        );
      }
      return tappableBackground;
    }
    return Padding(padding: widget.padding, child: richText);
  }

  Widget _buildPlainText(
    BuildContext context,
    String data,
    Color textColor,
    TextAlign align,
  ) {
    final double fontSize = widget.compact ? 14 : 15;
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
          color: Theme.of(context).colorScheme.primary,
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
    PostBackgroundPreset preset, {
    required bool limitHeight,
  }) {
    final int len = widget.post.text!.trim().length;
    final double fontSize;
    final double verticalPadding;
    if (len <= 80) {
      fontSize = widget.compact ? 20 : 26;
      verticalPadding = limitHeight ? 32 : (widget.compact ? 48 : 64);
    } else if (len <= 180) {
      fontSize = widget.compact ? 18 : 22;
      verticalPadding = limitHeight ? 28 : (widget.compact ? 40 : 52);
    } else if (len <= 300) {
      fontSize = widget.compact ? 16 : 20;
      verticalPadding = limitHeight ? 24 : (widget.compact ? 28 : 40);
    } else {
      fontSize = widget.compact ? 14 : 18;
      verticalPadding = limitHeight ? 20 : (widget.compact ? 24 : 32);
    }
    final double aspectFactor = limitHeight ? 0.5 : 1.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double minH = aspectFactor > 0 ? width * aspectFactor : 0;
        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: double.infinity,
            minHeight: minH,
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: 0,
              vertical: verticalPadding,
            ),
            decoration: preset.decoration(),
            alignment: Alignment.center,
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
                  maxLines: limitHeight ? _collapsedMaxLines : null,
                  textOverflow:
                      limitHeight ? TextOverflow.ellipsis : TextOverflow.clip,
                ),
                'a.tagged-user': Style(
                  color: Theme.of(context).colorScheme.primary,
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
