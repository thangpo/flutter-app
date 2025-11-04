import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom page route với hiệu ứng lật trang sách
class BookFlipPageRoute extends PageRouteBuilder {
  final Widget page;

  BookFlipPageRoute({required this.page})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 800),
    reverseTransitionDuration: const Duration(milliseconds: 600),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return BookFlipTransition(
        animation: animation,
        child: child,
      );
    },
  );
}

/// Widget tạo hiệu ứng lật trang sách
class BookFlipTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const BookFlipTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Chia animation thành 2 phần: lật trang cũ và hiện trang mới
        final firstHalfAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
          ),
        );

        final secondHalfAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
          ),
        );

        // Góc xoay cho hiệu ứng 3D
        final rotationAngle = firstHalfAnimation.value * math.pi;
        final isFirstHalf = animation.value < 0.5;

        return Transform(
          alignment: Alignment.centerLeft,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..rotateY(isFirstHalf ? -rotationAngle : math.pi - (secondHalfAnimation.value * math.pi)),
          child: Stack(
            children: [
              // Trang mới (hiển thị trong nửa sau)
              if (!isFirstHalf)
                child!,
              // Shadow effect để tạo độ sâu
              if (isFirstHalf)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(firstHalfAnimation.value * 0.5),
                        ],
                      ),
                    ),
                  ),
                ),
              // Hiệu ứng sáng khi lật
              if (!isFirstHalf)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withOpacity((1 - secondHalfAnimation.value) * 0.3),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      child: child,
    );
  }
}

/// Hiệu ứng lật trang nâng cao hơn với curl effect
class AdvancedBookFlipPageRoute extends PageRouteBuilder {
  final Widget page;

  AdvancedBookFlipPageRoute({required this.page})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 1000),
    reverseTransitionDuration: const Duration(milliseconds: 800),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return AdvancedBookFlipTransition(
        animation: animation,
        child: child,
      );
    },
  );
}

class AdvancedBookFlipTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const AdvancedBookFlipTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        );

        final progress = curvedAnimation.value;
        final rotationAngle = progress * math.pi;

        // Tính toán scale để tạo hiệu ứng zoom nhẹ
        final scale = 1.0 - (math.sin(progress * math.pi) * 0.1);

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002) // Perspective mạnh hơn
            ..scale(scale)
            ..rotateY(-rotationAngle),
          child: Stack(
            children: [
              // Nền trang cũ (mờ dần)
              if (progress < 0.5)
                Opacity(
                  opacity: 1.0 - (progress * 2),
                  child: Container(
                    color: Colors.white,
                  ),
                ),
              // Trang mới
              if (progress >= 0.5)
                Opacity(
                  opacity: (progress - 0.5) * 2,
                  child: child!,
                )
              else
                Container(color: Colors.white),
              // Shadow gradient
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(
                            math.sin(progress * math.pi) * 0.4,
                          ),
                          Colors.black.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              // Hiệu ứng sáng viền
              if (progress > 0.1 && progress < 0.9)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(math.sin(progress * math.pi) * 0.8),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      child: child,
    );
  }
}