import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/src/app_shell.dart';
import '../lib/src/models/profile.dart';

void main() {
  testWidgets('AppShell builds (owner)', (tester) async {
    const translations = {
      "en": {"app": {"title": "FoodLabel AI"}},
    };
    await tester.pumpWidget(const MaterialApp(
      home: AppShell(isOwner: true, translations: translations, onLocaleChange: _noop),
    ));
    expect(find.byType(AppShell), findsOneWidget);
  });
}

void _noop(Locale _) {}
