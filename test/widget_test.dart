import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://placeholder.supabase.co',
      anonKey: 'placeholder-anon-key',
    );
  });

  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
