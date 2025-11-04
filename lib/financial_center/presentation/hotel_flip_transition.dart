import 'package:flutter/material.dart';
import '../presentation/screens/hotel_detail_screen.dart';

class IOSAppOpenTransition extends PageRouteBuilder {
  final Widget page;
  final Offset? startPosition;
  final Size? startSize;

  IOSAppOpenTransition({
    required this.page,
    this.startPosition,
    this.startSize,
  }) : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
        reverseCurve: Curves.easeInOutCubic,
      );
      final scaleAnimation = Tween<double>(
        begin: 0.85,
        end: 1.0,
      ).animate(curvedAnimation);

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ));

      final radiusAnimation = Tween<double>(
        begin: 30.0,
        end: 0.0,
      ).animate(curvedAnimation);

      return FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radiusAnimation.value),
            child: child,
          ),
        ),
      );
    },
  );
}

class IOSAppOpenFromPositionTransition extends PageRouteBuilder {
  final Widget page;
  final Offset startPosition;
  final Size startSize;

  IOSAppOpenFromPositionTransition({
    required this.page,
    required this.startPosition,
    required this.startSize,
  }) : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final screenSize = MediaQuery.of(page.key as BuildContext).size;

      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      );

      final scaleXAnimation = Tween<double>(
        begin: startSize.width / screenSize.width,
        end: 1.0,
      ).animate(curvedAnimation);

      final scaleYAnimation = Tween<double>(
        begin: startSize.height / screenSize.height,
        end: 1.0,
      ).animate(curvedAnimation);

      final offsetAnimation = Tween<Offset>(
        begin: Offset(
          (startPosition.dx - screenSize.width / 2) / screenSize.width,
          (startPosition.dy - screenSize.height / 2) / screenSize.height,
        ),
        end: Offset.zero,
      ).animate(curvedAnimation);

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ));

      final radiusAnimation = Tween<double>(
        begin: 20.0,
        end: 0.0,
      ).animate(curvedAnimation);

      return FadeTransition(
        opacity: fadeAnimation,
        child: Transform.translate(
          offset: Offset(
            offsetAnimation.value.dx * screenSize.width,
            offsetAnimation.value.dy * screenSize.height,
          ),
          child: Transform.scale(
            scaleX: scaleXAnimation.value,
            scaleY: scaleYAnimation.value,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radiusAnimation.value),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

class ExampleWithPosition extends StatelessWidget {
  final GlobalKey cardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: cardKey,
      onTap: () {
        final RenderBox? renderBox = cardKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;

          Navigator.push(
            context,
            IOSAppOpenFromPositionTransition(
              page: HotelDetailScreen(slug: 'hotel-slug'),
              startPosition: Offset(
                position.dx + size.width / 2,
                position.dy + size.height / 2,
              ),
              startSize: size,
            ),
          );
        }
      },
      child: Container(/* your widget */),
    );
  }
}

class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  IOSAppOpenTransition(
                    page: const DetailPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Open with iOS Effect', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Page'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.purple.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Text(
            'Welcome! 🎉',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}