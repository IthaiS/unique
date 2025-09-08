
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/src/app_shell.dart';

void main() {
  testWidgets('Owner menu navigates to Owner profile and Owner settings', (tester) async {
    await tester.pumpWidget(MaterialApp(
      routes: {
        '/owner/profile': (_) => const Scaffold(body: Text('Owner profile page')),
        '/owner/settings': (_) => const Scaffold(body: Text('Owner settings page')),
        '/login': (_) => const Scaffold(body: Text('Login page')),
      },
      home: MediaQuery(
        data: const MediaQueryData(size: Size(1200, 800)),
        child: const AppShell(isOwner: true, onLocaleChange: _noop, translations: {},),
      ),
    ));

    await tester.tap(find.byTooltip('Owner menu'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Owner profile'));
    await tester.pumpAndSettle();
    expect(find.text('Owner profile page'), findsOneWidget);

    Navigator.of(tester.element(find.text('Owner profile page'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Owner menu'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Owner settings'));
    await tester.pumpAndSettle();
    expect(find.text('Owner settings page'), findsOneWidget);
  });
}

void _noop(Locale _) {}
