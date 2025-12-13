import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_story.dart';

/// Renders a media widget with story overlays (text layers) on top.
class StoryOverlayStack extends StatelessWidget {
  final Widget media;
  final List<SocialStoryOverlay> overlays;
  final int? maxLines;
  final double minFontSize;
  final double maxFontSize;

  const StoryOverlayStack({
    super.key,
    required this.media,
    required this.overlays,
    this.maxLines,
    this.minFontSize = 10,
    this.maxFontSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    if (overlays.isEmpty) return media;
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size size = constraints.biggest;
        return Stack(
          fit: StackFit.expand,
          children: [
            media,
            ...overlays.map((o) => _buildOverlay(o, size)),
          ],
        );
      },
    );
  }

  Widget _buildOverlay(SocialStoryOverlay overlay, Size size) {
    final double w = overlay.width * size.width;
    final double h = overlay.height * size.height;
    final double left = overlay.x * size.width - w / 2;
    final double top = overlay.y * size.height - h / 2;
    final Alignment align = _alignmentFromString(overlay.align);
    final TextAlign textAlign = _textAlignFromString(overlay.align);
    final double fontSize =
        (overlay.fontScale * size.width).clamp(minFontSize, maxFontSize);

    return Positioned(
      left: left,
      top: top,
      width: w,
      height: h,
      child: Transform.rotate(
        angle: overlay.rotation,
        child: Container(
          alignment: align,
          padding: overlay.hasBackground
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
              : EdgeInsets.zero,
          decoration: overlay.hasBackground
              ? BoxDecoration(
                  color: overlay.color.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: align,
            child: Text(
              overlay.text,
              textAlign: textAlign,
              maxLines: maxLines,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: fontSize,
                color: overlay.color,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Alignment _alignmentFromString(String align) {
    switch (align.toLowerCase()) {
      case 'left':
        return Alignment.centerLeft;
      case 'right':
        return Alignment.centerRight;
      default:
        return Alignment.center;
    }
  }

  TextAlign _textAlignFromString(String align) {
    switch (align.toLowerCase()) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.center;
    }
  }
}
