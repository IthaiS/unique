// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:foodlabel_ai/src/pages/home_page.dart';

void main() {
  testWidgets('App title renders with injected translations', (WidgetTester tester) async {
    // Minimal translations just for the test
    final mockTranslations = {
      'en': {
        'app': {'title': 'FoodLabel AI'},
        'action': {'scan_label': 'Scan label'},
        'label': {
          'recognized_text': 'Recognized text',
          'ingredients': 'Ingredients',
          'assessment': 'Assessment'
        },
        'assess': {
          'verdict': {'safe': 'SAFE', 'caution': 'CAUTION', 'avoid': 'AVOID'},
          'score': 'Score: {score}'
        },
        'reason': {
          'UNKNOWN': 'No specific issues found.',
          'ALLERGEN_MATCH': 'Contains allergen {param}.',
          'VEGAN_CONFLICT': 'Non-vegan ingredient.',
          'ADDITIVE_FLAG': 'Contains additive {param}.'
        }
      }
    };

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const [Locale('en'), Locale('nl', 'BE'), Locale('fr', 'BE')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: HomePage(
        onLocaleChange: (_) {},
        translations: mockTranslations,
      ),
    ));

    // Let the first frame settle
    await tester.pumpAndSettle();

    // Assert: title text is present
    expect(find.text('FoodLabel AI'), findsOneWidget);

    // (Optional) button label from translations
    expect(find.text('Scan label'), findsOneWidget);
  });
}
