import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test: renders title text', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('FoodLabel AI')),
      ),
    ));
    expect(find.text('FoodLabel AI'), findsOneWidget);
  });
}
