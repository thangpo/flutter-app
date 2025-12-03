import 'dart:ui';
import 'package:flutter/material.dart';

class TourCardSkeleton extends StatelessWidget {
  const TourCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color baseColor =
    isDark ? Colors.white10 : Colors.grey.shade300;
    final Color highlightColor =
    isDark ? Colors.white24 : Colors.grey.shade100;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 300,
          child: Stack(
            children: [
              Positioned.fill(
                child: _ShimmerContainer(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                ),
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(40),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      color: (isDark ? Colors.black : Colors.white)
                          .withOpacity(0.25),
                      padding:
                      const EdgeInsets.fromLTRB(18, 14, 18, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _SkeletonLine(width: 180, height: 16),
                          SizedBox(height: 8),
                          _SkeletonLine(width: 220, height: 12),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              _SkeletonCircle(size: 16),
                              SizedBox(width: 8),
                              _SkeletonLine(width: 120, height: 12),
                            ],
                          ),
                          SizedBox(height: 8),
                          _SkeletonLine(width: 140, height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bookmark_border_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonLine({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color baseColor =
    isDark ? Colors.white10 : Colors.grey.shade300;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  final double size;

  const _SkeletonCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color baseColor =
    isDark ? Colors.white10 : Colors.grey.shade300;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: baseColor,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ShimmerContainer extends StatelessWidget {
  final Color baseColor;
  final Color highlightColor;

  const _ShimmerContainer({
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [baseColor, highlightColor, baseColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}
