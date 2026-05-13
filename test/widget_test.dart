import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MaterialApp smoke', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Fast-Pos test'),
        ),
      ),
    );
    expect(find.text('Fast-Pos test'), findsOneWidget);
  });
}
