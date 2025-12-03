import 'package:flutter/material.dart';

class ArticleCardSkeleton extends StatefulWidget {
  const ArticleCardSkeleton({super.key});

  @override
  State<ArticleCardSkeleton> createState() => _ArticleCardSkeletonState();
}

class _ArticleCardSkeletonState extends State<ArticleCardSkeleton>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _shimmerBox({
    double? width,
    double? height,
    double radius = 12,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2 * _controller.value, -0.3),
              end: Alignment(1.0 + 2 * _controller.value, 0.3),
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Column(
          children: [
            Expanded(
              child: _shimmerBox(radius: 0),
            ),

            Container(
              margin: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _shimmerBox(width: double.infinity, height: 10, radius: 999),
                  ),
                  const SizedBox(width: 8),
                  _shimmerBox(width: 48, height: 18, radius: 999),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}