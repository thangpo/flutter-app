// This is a basic Flutter widgets test.
//
// To perform an interaction with a widgets in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widgets
// tree, read text, and verify that the values of widgets properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Can render placeholder app', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('VNShop247')),
        ),
      ),
    );

    expect(find.text('VNShop247'), findsOneWidget);
  });
}
